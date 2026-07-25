#ifndef SC_TOOLBAR_H
#define SC_TOOLBAR_H

#include "common.h"

#include <stdbool.h>
#include <stdint.h>
#include <SDL3/SDL_events.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_render.h>

enum sc_toolbar_action {
    SC_TOOLBAR_ACTION_NONE,
    SC_TOOLBAR_ACTION_BACK,
    SC_TOOLBAR_ACTION_HOME,
    SC_TOOLBAR_ACTION_APP_SWITCH,
    SC_TOOLBAR_ACTION_ROTATE_DEVICE,
    SC_TOOLBAR_ACTION_POWER,
    SC_TOOLBAR_ACTION_VOLUME_DOWN,
    SC_TOOLBAR_ACTION_VOLUME_UP,
    SC_TOOLBAR_ACTION_EXPAND_NOTIFICATIONS,
};

#define SC_TOOLBAR_BUTTON_COUNT 8

struct sc_toolbar {
    bool enabled;
    uint16_t window_width;
    uint16_t window_height;
    float button_gap;
    SDL_FRect rect;
    SDL_FRect buttons[SC_TOOLBAR_BUTTON_COUNT];
    SDL_Texture *icons;
    int hovered;
    int pressed;
    SDL_FingerID active_finger;
};

void
sc_toolbar_init(struct sc_toolbar *toolbar, bool enabled);

void
sc_toolbar_set_icons(struct sc_toolbar *toolbar, SDL_Texture *icons);

void
sc_toolbar_destroy(struct sc_toolbar *toolbar);

uint16_t
sc_toolbar_get_width(const struct sc_toolbar *toolbar);

void
sc_toolbar_layout(struct sc_toolbar *toolbar, uint16_t window_width,
                  uint16_t window_height);

void
sc_toolbar_render(const struct sc_toolbar *toolbar, SDL_Renderer *renderer,
                  float scale);

// Returns true if the event targets the toolbar. If a button was activated,
// action is set to the requested device action.
bool
sc_toolbar_handle_event(struct sc_toolbar *toolbar, const SDL_Event *event,
                        enum sc_toolbar_action *action);

void
sc_toolbar_clear_state(struct sc_toolbar *toolbar);

#endif
