#include "common.h"

#include <assert.h>

#include "toolbar.h"

static void
test_mouse_click(void) {
    struct sc_toolbar toolbar;
    sc_toolbar_init(&toolbar, true);
    sc_toolbar_layout(&toolbar, 600, 600);

    assert(sc_toolbar_get_width(&toolbar) == 72);
    assert(toolbar.rect.x == 528);

    SDL_Event event = {0};
    event.type = SDL_EVENT_MOUSE_BUTTON_DOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.x = 556;
    event.button.y = 80;

    enum sc_toolbar_action action;
    bool handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_NONE);

    event.type = SDL_EVENT_MOUSE_BUTTON_UP;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_BACK);
}

static void
test_mouse_release_outside(void) {
    struct sc_toolbar toolbar;
    sc_toolbar_init(&toolbar, true);
    sc_toolbar_layout(&toolbar, 600, 600);

    SDL_Event event = {0};
    event.type = SDL_EVENT_MOUSE_BUTTON_DOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.x = 556;
    event.button.y = 80;

    enum sc_toolbar_action action;
    bool handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);

    event.type = SDL_EVENT_MOUSE_BUTTON_UP;
    event.button.x = 500;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_NONE);
}

static void
test_touch_click(void) {
    struct sc_toolbar toolbar;
    sc_toolbar_init(&toolbar, true);
    sc_toolbar_layout(&toolbar, 600, 600);

    SDL_Event event = {0};
    event.type = SDL_EVENT_FINGER_DOWN;
    event.tfinger.fingerID = 42;
    event.tfinger.x = 556.f / 600;
    event.tfinger.y = 140.f / 600;

    enum sc_toolbar_action action;
    bool handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_NONE);

    event.type = SDL_EVENT_FINGER_UP;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_HOME);
}

static void
test_volume_order(void) {
    struct sc_toolbar toolbar;
    sc_toolbar_init(&toolbar, true);
    sc_toolbar_layout(&toolbar, 600, 600);

    SDL_Event event = {0};
    event.type = SDL_EVENT_MOUSE_BUTTON_DOWN;
    event.button.button = SDL_BUTTON_LEFT;
    event.button.x = 556;
    event.button.y = 390;

    enum sc_toolbar_action action;
    bool handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);

    event.type = SDL_EVENT_MOUSE_BUTTON_UP;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_VOLUME_UP);

    event.type = SDL_EVENT_MOUSE_BUTTON_DOWN;
    event.button.y = 450;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);

    event.type = SDL_EVENT_MOUSE_BUTTON_UP;
    handled = sc_toolbar_handle_event(&toolbar, &event, &action);
    assert(handled);
    assert(action == SC_TOOLBAR_ACTION_VOLUME_DOWN);
}

int
main(int argc, char *argv[]) {
    (void) argc;
    (void) argv;

    test_mouse_click();
    test_mouse_release_outside();
    test_touch_click();
    test_volume_order();
    return 0;
}
