hl.window_rule({
    name    = "thunar-opacity",
    match   = { class = "^[Tt]hunar$" },
    opacity = "0.92 0.88",
})

hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name       = "fix-xwayland-drags",
    match      = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus   = true,
})
