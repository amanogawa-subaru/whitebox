-- WINDOWS AND WORKSPACES --

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- imv opens floating
hl.window_rule({
    name = "float-imv",
    match = {
        class = "imv",
    },

    float = true,
    center = true,
})

-- Bulky opens floating
hl.window_rule({
    name = "float-bulky",
    match = {
        class = "^\\.bulky-wrapped$",
    },

    float = true,
    center = true,
})

-- Nemo's "open with" window opens floating
hl.window_rule({
    name = "nemo-open-with-center",
    match = {
        class = "^nemo$",
        title = "^Open with$",
    },
    center = true,
    size = { 720, 530 },
})

-- Steam utility windows open floating
hl.window_rule({
    name = "float-steam-utility",
    match = {
        class = "^steam$",
        title = "^(Steam Settings|Friends List)$",
    },

    float = true,
    center = true,
})
