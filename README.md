![Framework logo](./eliteui.png)
> ***EliteUI*** A Zig-native GUI framework powered by SDF rendering and SPIR-V shaders

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
[![Zig](https://img.shields.io/badge/Zig-0.15.2-orange.svg)](https://ziglang.org)
![Status](https://img.shields.io/badge/Status-WIP-yellow.svg)

---

## What is EliteUI?

EliteUI is a low-level, high-performance GUI framework written in [Zig](https://ziglang.org), built around **Signed Distance Fields (SDF)** for shape rendering and **SPIR-V** as its core shader target.

Instead of relying on traditional image-based UI or heavyweight widget toolkits, ExtremeUI renders every element using pure SDF math — giving you resolution-independent, GPU-accelerated UI that works across any screen size or pixel density, with no bitmaps and no image assets.

The coordinate system is unified: every screen is treated as a 100x100 unit grid, where `(0,0)` is the bottom-left and `(1000,1000)` is the top-right. One unit expands or contracts automatically based on the actual screen resolution.

---

## Usage

The user defines window settings once:

```zig
const eui = @import("EliteUI");

pub fn main() !void {
    eui.window(.{
        .width  = 1280,
        .height = 720,
        .title  = "My App",
    });
}
```

Then defines UI elements as constants using EUI shapes:

```zig
const my_button = Circle{
    .position = Vec2{ .x = 50, .y = 50 },
    .size     = Size.from(1.0, 1.0),
    .rotation = Rotation.from(0),
    .radius   = 10,
    .color    = Colors.red,
};
```

EliteUI handles everything else: coordinate conversion, SDF evaluation per pixel, SPIR-V compilation, and GPU submission.

---

## Project Structure

```
EliteUI/
│
├── EUI/
│   ├── Shapes/
│   ├── Customizations/
│   └── Transformers/
└── Core/
    ├── main.zig
    ├── Config.zig
    ├── Window.zig
    └──  Platforms/
        ├── Linux_win.zig
        └── Vulkan_pip.zig
        └── SPIR-V/
```

---

## How It Works

```
eui.window()
    └── Core/Window.zig
            └── Core/Config.zig        # screen_width, screen_height, unit_x, unit_y

Circle.sdf(pixel_x, pixel_y)
    └── Transformers/Position.apply()     # pixel -> local space
    └── Transformers/Rotation.apply()     # rotate around center
    └── Transformers/Size.apply()         # scale radius
    └── sqrt(x^2 + y^2) - radius      # signed distance

Core/Platforms/Linux_win.zig            # opens X11 or Wayland window
    └── Core/Platform/Vulkan_pip.zig   # Vulkan pipeline
            └── SPIR-V/Runtime.zig     # SPIR-V bytecode -> GPU
```

---

## Roadmap

| Module | Description |
|---|---|
| `EUI/Shapes/Objects` | Prebuilt UI components |
| `EUI/Systems/Events` | Mouse, keyboard, touch input |
| `EUI/Customizations/Keyfarmes` | Keyframe animation system |
| `EUI/Frames/Medias` | Images and video rendering |
| `EUI/Frames/Interface` | Flexible layout system and sup-layouts |
| `EUI/Customizations/Fonts` | Font rendering via MSDF |
| `Core/Installer` | Comptime auto GPU and screen detection |
| `Core/Platforms/...` | Multi-backend for Multi-OS: WGSL, MSL, GLSL |

---

## Current Status: MVP in Progress

**v0.0.1 Goal:**
- [ ] Open a window via X11 or Wayland
- [ ] Initialize Vulkan pipeline
- [ ] Pass SPIR-V shader to the GPU
- [ ] Render a basic SDF circle on screen

---

## License

Licensed under the **Mozilla Public License**.
You are free to build closed-source applications with ExtremeUI.
Any modifications to ExtremeUI itself must remain open source.

See [LICENSE](./LICENSE) for details.

---

> *"Started small. Thinks big."*
