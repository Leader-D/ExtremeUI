# ExtremeUI
> A Zig-native GUI framework powered by SDF rendering and SPIR-V shaders

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL_v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![Zig](https://img.shields.io/badge/Zig-0.x-orange.svg)](https://ziglang.org)
![Status](https://img.shields.io/badge/Status-WIP-yellow.svg)

---

## What is ExtremeUI?

ExtremeUI is a low-level, high-performance GUI framework written in [Zig](https://ziglang.org), built around **Signed Distance Fields (SDF)** for shape rendering and **SPIR-V** as its core shader target.

Instead of relying on traditional image-based UI or heavyweight widget toolkits, ExtremeUI renders every element using pure SDF math — giving you resolution-independent, GPU-accelerated UI that works across any screen size or pixel density, with no bitmaps and no image assets.

The coordinate system is unified: every screen is treated as a 100x100 unit grid, where `(0,0)` is the bottom-left and `(100,100)` is the top-right. One unit expands or contracts automatically based on the actual screen resolution.

---

## Usage

The user defines window settings once:

```zig
const xui = @import("ExtremeUI");

pub fn main() !void {
    xui.window(.{
        .width  = 1280,
        .height = 720,
        .title  = "My App",
    });
}
```

Then defines UI elements as constants using XUI shapes:

```zig
const my_button = Circle{
    .position = Vec2{ .x = 50, .y = 50 },
    .size     = Size.from(1.0, 1.0),
    .rotation = Rotation.from(0),
    .radius   = 10,
    .color    = Colors.red,
};
```

ExtremeUI handles everything else: coordinate conversion, SDF evaluation per pixel, SPIR-V compilation, and GPU submission.

---

## Project Structure

```
ExtremeUI/
│
├── XUI/                        # User-facing API
│   ├── Shapes/
│   │   └── Circle.zig          # SDF circle, calls Transform internally
│   ├── Colors/
│   │   └── Colors.zig          # RGBA color definitions
│   └── Transform/
│       ├── Position.zig        # Vec2 pull vector from origin to target
│       ├── Size.zig            # Scale factor in unit space
│       └── Rotation.zig        # Rotation around shape center
│
└── Core/                       # Internal engine
    ├── main.zig                # Engine entry point
    ├── Config.zig              # Global screen state and unit conversion
    ├── Window.zig              # User-facing window initializer
    ├── Platform/
    │   ├── Linux_win.zig       # X11 and Wayland window creation (auto-detected)
    │   └── Vulkan_pip.zig      # Vulkan instance, device, and graphics pipeline
    └── Shad-gines/
        └── SPIR-V/
            ├── Runtime/
            │   └── Engine.zig  # Builds SPIR-V bytecode at runtime
            └── Comptime/
                └── Engine.zig  # Planned: compile-time SPIR-V generation
```

---

## How It Works

```
xui.window()
    └── Core/Window.zig
            └── Core/Config.zig        # screen_width, screen_height, unit_x, unit_y

Circle.sdf(pixel_x, pixel_y)
    └── Transform/Position.apply()     # pixel -> local space
    └── Transform/Rotation.apply()     # rotate around center
    └── Transform/Size.apply()         # scale radius
    └── sqrt(x^2 + y^2) - radius      # signed distance

Core/Platform/Linux_win.zig            # opens X11 or Wayland window
    └── Core/Platform/Vulkan_pip.zig   # Vulkan pipeline
            └── Runtime/Engine.zig     # SPIR-V bytecode -> GPU
```

---

## Roadmap

| Module | Description |
|---|---|
| `XUI/Objects` | Prebuilt UI components |
| `XUI/Events` | Mouse, keyboard, touch input |
| `XUI/Keyfarmers` | Keyframe animation system |
| `XUI/Medias` | Images and video rendering |
| `XUI/Fonts` | Font rendering via MSDF |
| `Core/Installer` | Comptime auto GPU and screen detection |
| `Core/Shad-gines` | Multi-backend: WGSL, MSL, GLSL |
| `Core/Platform` | Windows and macOS platform layers |
| `Interface` | Flexible layout system |

---

## Current Status: MVP in Progress

**v0.0.1 Goal:**
- [ ] Open a window via X11 or Wayland
- [ ] Initialize Vulkan pipeline
- [ ] Pass SPIR-V shader to the GPU
- [ ] Render a basic SDF circle on screen

---

## License

Licensed under the **GNU Lesser General Public License v3.0**.
You are free to build closed-source applications with ExtremeUI.
Any modifications to ExtremeUI itself must remain open source.

See [LICENSE](./LICENSE) for details.

---

> *"Started small. Thinks big."*
