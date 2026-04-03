const std = @import("std");
const Config = @import("../Config.zig");

const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("wayland-client.h");
});

const Platform = enum { x11, wayland };

fn detectPlatform() Platform {
    const wayland_display = std.os.getenv("WAYLAND_DISPLAY");
    if (wayland_display != null) return .wayland;
    return .x11;
}

fn openX11Window() !void {
    const display = c.XOpenDisplay(null) orelse return error.X11DisplayFailed;
    const screen = c.XDefaultScreen(display);
    const root = c.XRootWindow(display, screen);

    const window = c.XCreateSimpleWindow(
        display, root,
        0, 0,
        @intFromFloat(Config.screen_width),
        @intFromFloat(Config.screen_height),
        0, 0,
        c.XBlackPixel(display, screen),
    );

    _ = c.XStoreName(display, window, "ExtremeUI");
    _ = c.XMapWindow(display, window);
    _ = c.XFlush(display);

    var event: c.XEvent = undefined;
    while (true) {
        _ = c.XNextEvent(display, &event);
        if (event.type == c.DestroyNotify) break;
    }

    _ = c.XDestroyWindow(display, window);
    _ = c.XCloseDisplay(display);
}

fn openWaylandWindow() !void {
    const display = c.wl_display_connect(null) orelse return error.WaylandDisplayFailed;
    defer _ = c.wl_display_disconnect(display);

    // TODO: Wayland surface + shell setup
    _ = c.wl_display_dispatch(display);
}

pub fn open() !void {
    switch (detectPlatform()) {
        .x11     => try openX11Window(),
        .wayland => try openWaylandWindow(),
    }
}
