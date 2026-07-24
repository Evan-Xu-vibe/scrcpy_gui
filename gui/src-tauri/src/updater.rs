use reqwest::Client;
use semver::Version;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::{
    fs::{self, File},
    io::{self, Cursor},
    path::{Component, Path, PathBuf},
};
use tauri::{AppHandle, Manager};
use zip::ZipArchive;

const RELEASE_API: &str = "https://api.github.com/repos/Genymobile/scrcpy/releases/latest";
const MAX_ARCHIVE_SIZE: u64 = 100 * 1024 * 1024;
const MAX_EXTRACTED_SIZE: u64 = 300 * 1024 * 1024;
const MAX_ARCHIVE_FILES: usize = 512;

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EngineUpdateInfo {
    pub current_version: String,
    pub latest_version: String,
    pub update_available: bool,
    pub managed: bool,
    pub release_url: String,
    pub published_at: String,
    pub download_size: u64,
}

#[derive(Deserialize)]
struct GithubRelease {
    tag_name: String,
    html_url: String,
    published_at: String,
    assets: Vec<GithubAsset>,
}

#[derive(Deserialize)]
struct GithubAsset {
    name: String,
    browser_download_url: String,
    size: u64,
}

fn client() -> Result<Client, String> {
    Client::builder()
        .user_agent("scrcpy-gui-updater")
        .build()
        .map_err(|error| format!("无法初始化更新客户端：{error}"))
}

async fn fetch_release(client: &Client) -> Result<GithubRelease, String> {
    client
        .get(RELEASE_API)
        .header("Accept", "application/vnd.github+json")
        .send()
        .await
        .map_err(|error| format!("无法连接 GitHub：{error}"))?
        .error_for_status()
        .map_err(|error| format!("GitHub 返回错误：{error}"))?
        .json()
        .await
        .map_err(|error| format!("无法解析 Release 信息：{error}"))
}

fn normalized_version(value: &str) -> Option<Version> {
    let value = value.trim().trim_start_matches(['v', 'V']);
    Version::parse(value).ok().or_else(|| {
        (value.matches('.').count() == 1)
            .then(|| Version::parse(&format!("{value}.0")).ok())
            .flatten()
    })
}

fn update_available(current: &str, latest: &str) -> bool {
    match (normalized_version(current), normalized_version(latest)) {
        (Some(current), Some(latest)) => latest > current,
        _ => {
            current.trim().trim_start_matches(['v', 'V'])
                != latest.trim().trim_start_matches(['v', 'V'])
        }
    }
}

fn release_asset(release: &GithubRelease) -> Result<&GithubAsset, String> {
    #[cfg(all(windows, target_arch = "x86"))]
    let platform = "win32";
    #[cfg(all(windows, not(target_arch = "x86")))]
    let platform = "win64";
    #[cfg(not(windows))]
    return Err("scrcpy 引擎自动更新目前仅支持 Windows".to_string());

    #[cfg(windows)]
    release
        .assets
        .iter()
        .find(|asset| asset.name.contains(platform) && asset.name.ends_with(".zip"))
        .ok_or_else(|| format!("Release {} 中未找到 {platform} 安装包", release.tag_name))
}

fn checksum_asset(release: &GithubRelease) -> Result<&GithubAsset, String> {
    release
        .assets
        .iter()
        .find(|asset| asset.name == "SHA256SUMS.txt")
        .ok_or_else(|| "Release 中缺少 SHA256SUMS.txt，已拒绝安装".to_string())
}

fn build_info(
    release: &GithubRelease,
    current_version: String,
    managed: bool,
) -> Result<EngineUpdateInfo, String> {
    let asset = release_asset(release)?;
    Ok(EngineUpdateInfo {
        update_available: update_available(&current_version, &release.tag_name),
        current_version,
        latest_version: release.tag_name.trim_start_matches(['v', 'V']).to_string(),
        managed,
        release_url: release.html_url.clone(),
        published_at: release.published_at.clone(),
        download_size: asset.size,
    })
}

pub async fn check(
    current_version: Option<String>,
    managed: bool,
) -> Result<EngineUpdateInfo, String> {
    let release = fetch_release(&client()?).await?;
    build_info(
        &release,
        current_version.unwrap_or_else(|| "未知".to_string()),
        managed,
    )
}

fn updater_root(app: &AppHandle) -> Result<PathBuf, String> {
    app.path()
        .app_data_dir()
        .map(|path| path.join("scrcpy-engine"))
        .map_err(|error| format!("无法确定引擎数据目录：{error}"))
}

fn valid_tag(tag: &str) -> bool {
    !tag.is_empty()
        && tag
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || ".-_".contains(character))
}

pub fn active_engine_dir(app: &AppHandle) -> Option<PathBuf> {
    let root = updater_root(app).ok()?;
    if let Ok(tag) = fs::read_to_string(root.join("active-version")) {
        let tag = tag.trim();
        if valid_tag(tag) {
            let directory = root.join("versions").join(tag);
            if engine_is_valid(&directory) {
                return Some(directory);
            }
        }
    }

    let mut installed = fs::read_dir(root.join("versions"))
        .ok()?
        .filter_map(Result::ok)
        .filter(|entry| engine_is_valid(&entry.path()))
        .filter_map(|entry| {
            let tag = entry.file_name().to_string_lossy().into_owned();
            normalized_version(&tag).map(|version| (version, entry.path()))
        })
        .collect::<Vec<_>>();
    installed.sort_by(|left, right| left.0.cmp(&right.0));
    installed.pop().map(|(_, directory)| directory)
}

fn engine_is_valid(directory: &Path) -> bool {
    directory.join("scrcpy.exe").is_file()
        && directory.join("adb.exe").is_file()
        && directory.join("scrcpy-server").is_file()
}

async fn download(client: &Client, asset: &GithubAsset) -> Result<Vec<u8>, String> {
    if asset.size == 0 || asset.size > MAX_ARCHIVE_SIZE {
        return Err(format!("更新包大小异常：{} 字节", asset.size));
    }
    let response = client
        .get(&asset.browser_download_url)
        .send()
        .await
        .map_err(|error| format!("下载 {} 失败：{error}", asset.name))?
        .error_for_status()
        .map_err(|error| format!("下载 {} 失败：{error}", asset.name))?;
    if let Some(length) = response.content_length() {
        if length > MAX_ARCHIVE_SIZE {
            return Err(format!("更新包响应过大：{length} 字节"));
        }
    }
    let bytes = response
        .bytes()
        .await
        .map_err(|error| format!("读取 {} 失败：{error}", asset.name))?;
    if bytes.len() as u64 != asset.size {
        return Err(format!(
            "{} 下载不完整：预期 {} 字节，实际 {} 字节",
            asset.name,
            asset.size,
            bytes.len()
        ));
    }
    Ok(bytes.to_vec())
}

fn expected_checksum(contents: &[u8], asset_name: &str) -> Result<String, String> {
    let contents = std::str::from_utf8(contents)
        .map_err(|_| "SHA256SUMS.txt 不是有效的 UTF-8 文本".to_string())?;
    contents
        .lines()
        .filter_map(|line| {
            let mut fields = line.split_whitespace();
            Some((fields.next()?, fields.next()?.trim_start_matches('*')))
        })
        .find_map(|(checksum, name)| (name == asset_name).then(|| checksum.to_ascii_lowercase()))
        .filter(|checksum| {
            checksum.len() == 64 && checksum.chars().all(|value| value.is_ascii_hexdigit())
        })
        .ok_or_else(|| format!("SHA256SUMS.txt 中没有 {asset_name} 的有效校验值"))
}

fn verify_checksum(contents: &[u8], expected: &str) -> Result<(), String> {
    let actual = format!("{:x}", Sha256::digest(contents));
    if actual == expected {
        Ok(())
    } else {
        Err(format!(
            "更新包 SHA-256 校验失败：预期 {expected}，实际 {actual}"
        ))
    }
}

fn safe_archive_paths(archive: &mut ZipArchive<Cursor<&[u8]>>) -> Result<Vec<PathBuf>, String> {
    if archive.len() > MAX_ARCHIVE_FILES {
        return Err(format!("更新包文件数量异常：{}", archive.len()));
    }
    let mut paths = Vec::with_capacity(archive.len());
    let mut total_size = 0_u64;
    for index in 0..archive.len() {
        let file = archive
            .by_index(index)
            .map_err(|error| format!("无法读取 ZIP 条目：{error}"))?;
        total_size = total_size
            .checked_add(file.size())
            .ok_or_else(|| "更新包展开大小溢出".to_string())?;
        if total_size > MAX_EXTRACTED_SIZE {
            return Err("更新包展开后超过安全大小限制".to_string());
        }
        if file
            .unix_mode()
            .is_some_and(|mode| mode & 0o170000 == 0o120000)
        {
            return Err("更新包包含不支持的符号链接".to_string());
        }
        let path = file
            .enclosed_name()
            .ok_or_else(|| format!("更新包包含不安全路径：{}", file.name()))?;
        paths.push(path.to_path_buf());
    }
    Ok(paths)
}

fn common_root(paths: &[PathBuf]) -> Option<PathBuf> {
    let first = paths.first()?.components().next()?;
    let root = match first {
        Component::Normal(value) => PathBuf::from(value),
        _ => return None,
    };
    paths
        .iter()
        .all(|path| path.components().next() == Some(first))
        .then_some(root)
}

fn extract_archive(contents: &[u8], destination: &Path) -> Result<(), String> {
    let mut archive = ZipArchive::new(Cursor::new(contents))
        .map_err(|error| format!("无法打开更新包：{error}"))?;
    let paths = safe_archive_paths(&mut archive)?;
    let root = common_root(&paths);

    for (index, path) in paths.iter().enumerate() {
        let relative = root
            .as_deref()
            .and_then(|root| path.strip_prefix(root).ok())
            .filter(|path| !path.as_os_str().is_empty())
            .unwrap_or(path);
        if relative.as_os_str().is_empty() {
            continue;
        }
        let output_path = destination.join(relative);
        let mut entry = archive
            .by_index(index)
            .map_err(|error| format!("无法读取 ZIP 条目：{error}"))?;
        if entry.is_dir() {
            fs::create_dir_all(&output_path)
                .map_err(|error| format!("无法创建更新目录：{error}"))?;
            continue;
        }
        if let Some(parent) = output_path.parent() {
            fs::create_dir_all(parent).map_err(|error| format!("无法创建更新目录：{error}"))?;
        }
        let mut output = File::create(&output_path)
            .map_err(|error| format!("无法创建 {}：{error}", output_path.display()))?;
        io::copy(&mut entry, &mut output)
            .map_err(|error| format!("无法解压 {}：{error}", output_path.display()))?;
    }
    Ok(())
}

fn activate(root: &Path, tag: &str) -> Result<(), String> {
    let temporary = root.join("active-version.tmp");
    let active = root.join("active-version");
    fs::write(&temporary, tag).map_err(|error| format!("无法写入版本指针：{error}"))?;
    if active.exists() {
        fs::remove_file(&active).map_err(|error| format!("无法更新版本指针：{error}"))?;
    }
    fs::rename(&temporary, &active).map_err(|error| format!("无法激活新版本：{error}"))
}

fn install_archive_at(root: &Path, tag: &str, contents: &[u8]) -> Result<(), String> {
    if !valid_tag(tag) {
        return Err(format!("Release 版本标记不安全：{tag}"));
    }
    let versions = root.join("versions");
    fs::create_dir_all(&versions).map_err(|error| format!("无法创建引擎目录：{error}"))?;
    let destination = versions.join(tag);
    if !engine_is_valid(&destination) {
        if destination.exists() {
            fs::remove_dir_all(&destination)
                .map_err(|error| format!("无法清理不完整版本：{error}"))?;
        }
        let staging = versions.join(format!(".staging-{tag}"));
        if staging.exists() {
            fs::remove_dir_all(&staging)
                .map_err(|error| format!("无法清理更新暂存目录：{error}"))?;
        }
        fs::create_dir_all(&staging).map_err(|error| format!("无法创建暂存目录：{error}"))?;
        if let Err(error) = extract_archive(contents, &staging) {
            let _ = fs::remove_dir_all(&staging);
            return Err(error);
        }
        if !engine_is_valid(&staging) {
            let _ = fs::remove_dir_all(&staging);
            return Err("官方更新包缺少 scrcpy.exe、adb.exe 或 scrcpy-server".to_string());
        }
        fs::write(staging.join(".version"), tag)
            .map_err(|error| format!("无法写入引擎版本：{error}"))?;
        fs::rename(&staging, &destination).map_err(|error| format!("无法安装新引擎：{error}"))?;
    }
    activate(root, tag)
}

fn install_archive(app: &AppHandle, tag: &str, contents: &[u8]) -> Result<(), String> {
    install_archive_at(&updater_root(app)?, tag, contents)
}

pub async fn install(
    app: AppHandle,
    current_version: Option<String>,
    managed: bool,
) -> Result<EngineUpdateInfo, String> {
    let client = client()?;
    let release = fetch_release(&client).await?;
    let asset = release_asset(&release)?;
    let checksum = checksum_asset(&release)?;
    let current = current_version.unwrap_or_else(|| "未知".to_string());
    if !update_available(&current, &release.tag_name) {
        return build_info(&release, current, managed);
    }

    let archive = download(&client, asset).await?;
    let checksums = download(&client, checksum).await?;
    let expected = expected_checksum(&checksums, &asset.name)?;
    verify_checksum(&archive, &expected)?;
    let tag = release.tag_name.clone();
    tauri::async_runtime::spawn_blocking(move || install_archive(&app, &tag, &archive))
        .await
        .map_err(|error| format!("更新安装任务失败：{error}"))??;

    build_info(
        &release,
        release.tag_name.trim_start_matches(['v', 'V']).to_string(),
        true,
    )
}

#[cfg(test)]
mod tests {
    use super::{
        checksum_asset, client, download, engine_is_valid, expected_checksum, fetch_release,
        install_archive_at, release_asset, update_available, verify_checksum,
    };

    #[test]
    fn compares_scrcpy_two_part_versions() {
        assert!(!update_available("4.1", "v4.1"));
        assert!(update_available("4.0", "v4.1"));
        assert!(!update_available("4.1.0", "v4.1"));
    }

    #[test]
    #[ignore = "requires access to GitHub Releases"]
    fn verifies_and_installs_official_release_in_isolation() {
        tauri::async_runtime::block_on(async {
            let client = client().expect("create update client");
            let release = fetch_release(&client).await.expect("fetch release");
            let asset = release_asset(&release).expect("find Windows asset");
            let checksums = download(&client, checksum_asset(&release).expect("find checksums"))
                .await
                .expect("download checksums");
            let archive = download(&client, asset).await.expect("download archive");
            let expected = expected_checksum(&checksums, &asset.name).expect("read checksum");
            verify_checksum(&archive, &expected).expect("verify checksum");

            let temporary = tempfile::tempdir().expect("create temporary directory");
            install_archive_at(temporary.path(), &release.tag_name, &archive)
                .expect("install archive");
            let installed = temporary.path().join("versions").join(&release.tag_name);
            assert!(engine_is_valid(&installed));
            assert_eq!(
                std::fs::read_to_string(temporary.path().join("active-version"))
                    .expect("read active version"),
                release.tag_name
            );
        });
    }
}
