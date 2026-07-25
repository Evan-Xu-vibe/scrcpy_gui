#include "toolbar.h"

#include <assert.h>

#define SC_TOOLBAR_WIDTH 64.f
#define SC_TOOLBAR_MARGIN 8.f
#define SC_TOOLBAR_BUTTON_SIZE 40.f
#define SC_TOOLBAR_BUTTON_GAP 4.f
#define SC_TOOLBAR_ICON_TILE_SIZE 48.f

static const enum sc_toolbar_action toolbar_actions[] = {
    SC_TOOLBAR_ACTION_BACK,
    SC_TOOLBAR_ACTION_HOME,
    SC_TOOLBAR_ACTION_APP_SWITCH,
    SC_TOOLBAR_ACTION_ROTATE_DEVICE,
    SC_TOOLBAR_ACTION_POWER,
    SC_TOOLBAR_ACTION_VOLUME_DOWN,
    SC_TOOLBAR_ACTION_VOLUME_UP,
    SC_TOOLBAR_ACTION_EXPAND_NOTIFICATIONS,
};

static inline SDL_FRect
scale_rect(SDL_FRect rect, float scale) {
    return (SDL_FRect) {
        .x = rect.x * scale,
        .y = rect.y * scale,
        .w = rect.w * scale,
        .h = rect.h * scale,
    };
}

static inline bool
contains(const SDL_FRect *rect, float x, float y) {
    return x >= rect->x && x < rect->x + rect->w
        && y >= rect->y && y < rect->y + rect->h;
}

static int
button_at(const struct sc_toolbar *toolbar, float x, float y) {
    for (int i = 0; i < SC_TOOLBAR_BUTTON_COUNT; ++i) {
        if (contains(&toolbar->buttons[i], x, y)) {
            return i;
        }
    }
    return -1;
}

void
sc_toolbar_init(struct sc_toolbar *toolbar, bool enabled) {
    toolbar->enabled = enabled;
    toolbar->window_width = 0;
    toolbar->window_height = 0;
    toolbar->button_gap = 0;
    toolbar->rect = (SDL_FRect) {0};
    for (int i = 0; i < SC_TOOLBAR_BUTTON_COUNT; ++i) {
        toolbar->buttons[i] = (SDL_FRect) {0};
    }
    toolbar->hovered = -1;
    toolbar->pressed = -1;
    toolbar->active_finger = 0;
    toolbar->icons = NULL;
}

void
sc_toolbar_set_icons(struct sc_toolbar *toolbar, SDL_Texture *icons) {
    toolbar->icons = icons;
}

void
sc_toolbar_destroy(struct sc_toolbar *toolbar) {
    SDL_DestroyTexture(toolbar->icons);
    toolbar->icons = NULL;
}

uint16_t
sc_toolbar_get_width(const struct sc_toolbar *toolbar) {
    return toolbar->enabled ? (uint16_t) SC_TOOLBAR_WIDTH : 0;
}

void
sc_toolbar_layout(struct sc_toolbar *toolbar, uint16_t window_width,
                  uint16_t window_height) {
    if (!toolbar->enabled) {
        return;
    }

    toolbar->window_width = window_width;
    toolbar->window_height = window_height;
    float width = MIN(SC_TOOLBAR_WIDTH, MAX(0, window_width - 1));
    toolbar->rect = (SDL_FRect) {
        .x = window_width - width,
        .y = 0,
        .w = width,
        .h = window_height,
    };

    float available_height = MAX(0.f, window_height - 2 * SC_TOOLBAR_MARGIN);
    float gap = MIN(SC_TOOLBAR_BUTTON_GAP,
                    available_height / (SC_TOOLBAR_BUTTON_COUNT * 2.f));
    float button_size = MIN(SC_TOOLBAR_BUTTON_SIZE,
                            (available_height - gap
                             * (SC_TOOLBAR_BUTTON_COUNT - 1))
                            / SC_TOOLBAR_BUTTON_COUNT);
    toolbar->button_gap = gap;
    float x = toolbar->rect.x + (toolbar->rect.w - button_size) / 2.f;
    float total_height = button_size * SC_TOOLBAR_BUTTON_COUNT
                       + gap * (SC_TOOLBAR_BUTTON_COUNT - 1);
    float y = (window_height - total_height) / 2.f;
    for (int i = 0; i < SC_TOOLBAR_BUTTON_COUNT; ++i) {
        toolbar->buttons[i] = (SDL_FRect) {
            .x = x,
            .y = y + i * (button_size + gap),
            .w = button_size,
            .h = button_size,
        };
    }
}

static inline void
draw_line(SDL_Renderer *renderer, float x1, float y1, float x2, float y2,
          float scale) {
    SDL_RenderLine(renderer, x1 * scale, y1 * scale, x2 * scale, y2 * scale);
}

static void
draw_rect(SDL_Renderer *renderer, float x, float y, float w, float h,
          float scale) {
    SDL_FRect rect = scale_rect((SDL_FRect) {
        .x = x,
        .y = y,
        .w = w,
        .h = h,
    }, scale);
    SDL_RenderRect(renderer, &rect);
}

static void
draw_chevron(SDL_Renderer *renderer, float x, float y, float size,
             bool right, float scale) {
    float direction = right ? 1 : -1;
    draw_line(renderer, x - direction * size / 2.f, y - size / 2.f,
              x + direction * size / 2.f, y, scale);
    draw_line(renderer, x + direction * size / 2.f, y,
              x - direction * size / 2.f, y + size / 2.f, scale);
}

static void
draw_icon(SDL_Renderer *renderer, enum sc_toolbar_action action,
          const SDL_FRect *button, float scale) {
    float x = button->x;
    float y = button->y;
    float w = button->w;
    float h = button->h;
    float left = x + w * .26f;
    float right = x + w * .74f;
    float top = y + h * .26f;
    float bottom = y + h * .74f;
    float mid_x = x + w / 2.f;
    float mid_y = y + h / 2.f;
    float icon_size = MIN(w, h) * .42f;

    switch (action) {
        case SC_TOOLBAR_ACTION_BACK:
            draw_chevron(renderer, mid_x - w * .06f, mid_y, icon_size, false,
                         scale);
            draw_line(renderer, mid_x - w * .23f, mid_y, right, mid_y, scale);
            break;
        case SC_TOOLBAR_ACTION_HOME:
            draw_line(renderer, left, mid_y - h * .03f, mid_x, top, scale);
            draw_line(renderer, mid_x, top, right, mid_y - h * .03f, scale);
            draw_line(renderer, left + w * .05f, mid_y - h * .01f,
                      left + w * .05f, bottom, scale);
            draw_line(renderer, left + w * .05f, bottom, right - w * .05f,
                      bottom, scale);
            draw_line(renderer, right - w * .05f, bottom,
                      right - w * .05f, mid_y - h * .01f, scale);
            draw_line(renderer, mid_x - w * .06f, bottom,
                      mid_x - w * .06f, mid_y + h * .10f, scale);
            draw_line(renderer, mid_x + w * .06f, bottom,
                      mid_x + w * .06f, mid_y + h * .10f, scale);
            break;
        case SC_TOOLBAR_ACTION_APP_SWITCH:
            draw_rect(renderer, left, top + h * .10f, w * .38f, h * .38f,
                      scale);
            draw_rect(renderer, left + w * .14f, top, w * .38f, h * .38f,
                      scale);
            break;
        case SC_TOOLBAR_ACTION_ROTATE_DEVICE:
            draw_line(renderer, left, top + h * .14f, right - w * .06f,
                      top + h * .14f, scale);
            draw_line(renderer, right - w * .06f, top + h * .14f,
                      right - w * .06f, mid_y, scale);
            draw_chevron(renderer, right - w * .06f, top + h * .14f,
                         icon_size * .54f, true, scale);
            draw_line(renderer, right, bottom - h * .14f, left + w * .06f,
                      bottom - h * .14f, scale);
            draw_line(renderer, left + w * .06f, bottom - h * .14f,
                      left + w * .06f, mid_y, scale);
            draw_chevron(renderer, left + w * .06f, bottom - h * .14f,
                         icon_size * .54f, false, scale);
            break;
        case SC_TOOLBAR_ACTION_POWER:
            draw_line(renderer, mid_x, top - h * .03f, mid_x, mid_y, scale);
            draw_line(renderer, mid_x - w * .13f, top + h * .10f,
                      left + w * .02f, mid_y - h * .02f, scale);
            draw_line(renderer, left + w * .02f, mid_y - h * .02f,
                      left + w * .08f, bottom - h * .02f, scale);
            draw_line(renderer, left + w * .08f, bottom - h * .02f,
                      mid_x, bottom + h * .05f, scale);
            draw_line(renderer, mid_x, bottom + h * .05f,
                      right - w * .08f, bottom - h * .02f, scale);
            draw_line(renderer, right - w * .08f, bottom - h * .02f,
                      right - w * .02f, mid_y - h * .02f, scale);
            draw_line(renderer, right - w * .02f, mid_y - h * .02f,
                      mid_x + w * .13f, top + h * .10f, scale);
            break;
        case SC_TOOLBAR_ACTION_VOLUME_DOWN:
        case SC_TOOLBAR_ACTION_VOLUME_UP:
            draw_line(renderer, left, mid_y - h * .10f, left + w * .12f,
                      mid_y - h * .10f, scale);
            draw_line(renderer, left + w * .12f, mid_y - h * .10f,
                      mid_x - w * .04f, top, scale);
            draw_line(renderer, mid_x - w * .04f, top,
                      mid_x - w * .04f, bottom, scale);
            draw_line(renderer, mid_x - w * .04f, bottom, left + w * .12f,
                      mid_y + h * .10f, scale);
            draw_line(renderer, left + w * .12f, mid_y + h * .10f, left,
                      mid_y + h * .10f, scale);
            draw_line(renderer, right - w * .11f, mid_y,
                      right + w * .08f, mid_y, scale);
            if (action == SC_TOOLBAR_ACTION_VOLUME_UP) {
                draw_line(renderer, right - w * .015f, mid_y - h * .095f,
                          right - w * .015f, mid_y + h * .095f, scale);
            }
            break;
        case SC_TOOLBAR_ACTION_EXPAND_NOTIFICATIONS:
            draw_line(renderer, left, bottom - h * .02f, right,
                      bottom - h * .02f, scale);
            draw_line(renderer, left + w * .10f, bottom - h * .02f,
                      left + w * .15f, mid_y, scale);
            draw_line(renderer, left + w * .15f, mid_y, mid_x, top, scale);
            draw_line(renderer, mid_x, top, right - w * .15f, mid_y, scale);
            draw_line(renderer, right - w * .15f, mid_y, right - w * .10f,
                      bottom - h * .02f, scale);
            draw_line(renderer, mid_x - w * .07f, bottom + h * .07f,
                      mid_x + w * .07f, bottom + h * .07f, scale);
            break;
        case SC_TOOLBAR_ACTION_NONE:
            break;
    }
}

void
sc_toolbar_render(const struct sc_toolbar *toolbar, SDL_Renderer *renderer,
                  float scale) {
    if (!toolbar->enabled) {
        return;
    }

    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 248);
    SDL_FRect background = scale_rect(toolbar->rect, scale);
    SDL_RenderFillRect(renderer, &background);
    SDL_SetRenderDrawColor(renderer, 221, 225, 231, 255);
    draw_line(renderer, toolbar->rect.x, toolbar->rect.y, toolbar->rect.x,
              toolbar->rect.y + toolbar->rect.h, scale);

    for (int i = 0; i < SC_TOOLBAR_BUTTON_COUNT; ++i) {
        SDL_FRect button = scale_rect(toolbar->buttons[i], scale);
        if (i == toolbar->pressed) {
            SDL_SetRenderDrawColor(renderer, 213, 232, 255, 255);
            SDL_RenderFillRect(renderer, &button);
        } else if (i == toolbar->hovered) {
            SDL_SetRenderDrawColor(renderer, 234, 243, 255, 255);
            SDL_RenderFillRect(renderer, &button);
        }

        bool active = i == toolbar->pressed || i == toolbar->hovered;
        uint8_t icon_r;
        uint8_t icon_g;
        uint8_t icon_b;
        if (active) {
            icon_r = 23;
            icon_g = 105;
            icon_b = 219;
        } else {
            icon_r = 32;
            icon_g = 36;
            icon_b = 43;
        }

        if (toolbar->icons) {
            SDL_FRect source = {
                .x = i * SC_TOOLBAR_ICON_TILE_SIZE,
                .y = 0,
                .w = SC_TOOLBAR_ICON_TILE_SIZE,
                .h = SC_TOOLBAR_ICON_TILE_SIZE,
            };
            float icon_size = MIN(toolbar->buttons[i].w,
                                  toolbar->buttons[i].h) * .62f;
            SDL_FRect target = scale_rect((SDL_FRect) {
                .x = toolbar->buttons[i].x
                   + (toolbar->buttons[i].w - icon_size) / 2.f,
                .y = toolbar->buttons[i].y
                   + (toolbar->buttons[i].h - icon_size) / 2.f,
                .w = icon_size,
                .h = icon_size,
            }, scale);
            SDL_SetTextureColorMod(toolbar->icons, icon_r, icon_g, icon_b);
            SDL_RenderTexture(renderer, toolbar->icons, &source, &target);
        } else {
            // Keep the toolbar usable if a packaging error omits the atlas.
            SDL_SetRenderDrawColor(renderer, icon_r, icon_g, icon_b, 255);
            draw_icon(renderer, toolbar_actions[i], &toolbar->buttons[i],
                      scale);
        }

        if (i == 2 || i == 4) {
            float separator_y = toolbar->buttons[i].y + toolbar->buttons[i].h
                              + toolbar->button_gap / 2.f;
            SDL_SetRenderDrawColor(renderer, 221, 225, 231, 255);
            draw_line(renderer, toolbar->rect.x + 14, separator_y,
                      toolbar->rect.x + toolbar->rect.w - 14, separator_y,
                      scale);
        }
    }
}

void
sc_toolbar_clear_state(struct sc_toolbar *toolbar) {
    toolbar->hovered = -1;
    toolbar->pressed = -1;
    toolbar->active_finger = 0;
}

static bool
handle_pointer(struct sc_toolbar *toolbar, float x, float y, bool down,
               bool up, enum sc_toolbar_action *action) {
    int index = button_at(toolbar, x, y);
    toolbar->hovered = index;

    if (down) {
        toolbar->pressed = index;
        return index >= 0;
    }

    if (up) {
        bool handled = toolbar->pressed >= 0 || index >= 0;
        if (toolbar->pressed == index && index >= 0) {
            *action = toolbar_actions[index];
        }
        toolbar->pressed = -1;
        return handled;
    }

    return index >= 0 || toolbar->pressed >= 0;
}

bool
sc_toolbar_handle_event(struct sc_toolbar *toolbar, const SDL_Event *event,
                        enum sc_toolbar_action *action) {
    assert(action);
    *action = SC_TOOLBAR_ACTION_NONE;
    if (!toolbar->enabled) {
        return false;
    }

    switch (event->type) {
        case SDL_EVENT_MOUSE_MOTION:
            if (event->motion.which == SDL_TOUCH_MOUSEID) {
                return false;
            }
            toolbar->hovered = button_at(toolbar, event->motion.x,
                                         event->motion.y);
            return toolbar->hovered >= 0 || toolbar->pressed >= 0;
        case SDL_EVENT_MOUSE_BUTTON_DOWN:
        case SDL_EVENT_MOUSE_BUTTON_UP:
            if (event->button.which == SDL_TOUCH_MOUSEID
                    || event->button.button != SDL_BUTTON_LEFT) {
                return false;
            }
            return handle_pointer(toolbar, event->button.x, event->button.y,
                                  event->type == SDL_EVENT_MOUSE_BUTTON_DOWN,
                                  event->type == SDL_EVENT_MOUSE_BUTTON_UP,
                                  action);
        case SDL_EVENT_FINGER_DOWN: {
            float x = event->tfinger.x * toolbar->window_width;
            float y = event->tfinger.y * toolbar->window_height;
            bool handled = handle_pointer(toolbar, x, y, true, false, action);
            if (handled) {
                toolbar->active_finger = event->tfinger.fingerID;
            }
            return handled;
        }
        case SDL_EVENT_FINGER_MOTION:
            if (toolbar->active_finger != event->tfinger.fingerID) {
                return false;
            }
            return handle_pointer(toolbar,
                                  event->tfinger.x * toolbar->window_width,
                                  event->tfinger.y * toolbar->window_height,
                                  false, false, action);
        case SDL_EVENT_FINGER_UP: {
            if (toolbar->active_finger != event->tfinger.fingerID) {
                return false;
            }
            toolbar->active_finger = 0;
            return handle_pointer(toolbar,
                                  event->tfinger.x * toolbar->window_width,
                                  event->tfinger.y * toolbar->window_height,
                                  false, true, action);
        }
        default:
            return false;
    }
}
