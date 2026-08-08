cmake_minimum_required(VERSION 3.21)

project(scrcpy_qt_gui VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.9 REQUIRED COMPONENTS Quick QuickControls2 Test)

qt_standard_project_setup(REQUIRES 6.9)

qt_add_executable(scrcpy-qt-gui
    src/main.cpp
    src/app_controller.cpp
    src/app_controller.h
    src/device_model.cpp
    src/device_model.h
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

target_compile_definitions(scrcpy-qt-gui PRIVATE
    SCRCPY_GUI_SOURCE_ROOT="${CMAKE_CURRENT_SOURCE_DIR}/.."
)

qt_add_qml_module(scrcpy-qt-gui
    URI ScrcpyGui
    VERSION 1.0
    QML_FILES
        qml/Theme.qml
        qml/Main.qml
        qml/components/DeviceSidebar.qml
        qml/components/SettingRow.qml
        qml/components/ToggleRow.qml
        qml/components/LogDrawer.qml
        qml/components/PrimaryButton.qml
        qml/components/Divider.qml
        qml/components/SelectBox.qml
        qml/pages/DisplayPage.qml
        qml/pages/ControlPage.qml
        qml/pages/AudioPage.qml
        qml/pages/RecordingPage.qml
)

target_link_libraries(scrcpy-qt-gui
    PRIVATE Qt6::Quick Qt6::QuickControls2
)

include(GNUInstallDirs)
install(TARGETS scrcpy-qt-gui
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

enable_testing()
qt_add_executable(test-device-model
    tests/test_device_model.cpp
    src/device_model.cpp
    src/device_model.h
)
target_link_libraries(test-device-model PRIVATE Qt6::Test)
target_include_directories(test-device-model PRIVATE src)
add_test(NAME test-device-model COMMAND test-device-model)
set_tests_properties(test-device-model PROPERTIES
    ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:C:/Qt/6.9.1/mingw_64/bin\;PATH=path_list_prepend:C:/Qt/Tools/mingw1310_64/bin"
)
