# Lattice — Rainy Walkway (Stage 1 Vertical Slice)

A cozy-cyberpunk third-person 3D exploration prototype built in **Godot 4.7** (Forward+). Explore a multi-tier rainy night walkway perched above the Lattice—a planet-wide megastructure city—as a small courier.

See [DESIGN.md](DESIGN.md) for the premise, art direction, and technical plan.

---

## Controls (Keyboard/Mouse & Gamepad)

| Action | Keyboard / Mouse | Gamepad |
| --- | --- | --- |
| Move | `WASD` or Arrow Keys | Left Stick |
| Camera Orbit | Mouse Move (click viewport to lock) | Right Stick |
| Jump (variable height, coyote time, buffer, wall-jump) | `Space` | South (`A` / `Cross`) |
| Dash (ground or air) | `Shift` or `E` | East (`B` / `Circle`) or `R1` |
| Cycle Quality (Low / Medium / High) | `F1` (or top-right HUD button) | — |
| Toggle Controls Overlay | `H` | — |
| Release / Capture Cursor | `Esc` / Left Click | — |

Ledge-grab & mantle trigger automatically when jumping toward platform edges, and pressing into vertical walls while falling initiates a smooth wall-slide.

---

## Quality Presets

Switch live at any time with **`F1`** or the top-right HUD button:

- **High**: Volumetric fog, SSR, SSAO, SDFGI, full light pools, high rain density, vignette + film grain + split-tone color grading.
- **Medium** *(default, balanced for 60 FPS on modern laptops)*: Volumetric fog, SSR, SSAO, ReflectionProbe + warm bounce fill lights (SDFGI off), medium rain density, post-process enabled.
- **Low**: Distance fog + light cones (Volumetric fog off), ReflectionProbe reflections (SSR/SSAO/SDFGI off), reduced secondary lights, lightweight rain, subtle vignette only.

---

## Project Architecture

- `levels/walkway.tscn` — Main explorable multi-tier promenade scene.
- `scenes/player/` — `courier.tscn` (controller + camera + state machine) and `courier_visual.tscn` (swappable visual rig).
- `scenes/props/` — 14 standalone modular prop scenes (`food_stall`, `scooter`, `traffic_cone`, `potted_plant`, `street_lamp`, `lantern_string`, `railing`, `truss_platform`, `catwalk_bridge`, `crate_stack`, `vent_pipe`, `neon_sign`, `bench`, `truss_pillar`). Replace any prop scene's visuals with real 3D models without changing level or gameplay scripts.
- `scenes/environment/` — `skyline.tscn` (MultiMesh megastructures, sky-bridges, sweeping searchlights) and `landmark_tower.tscn` (glowing teal tower with pulsing magenta beacon).
- `scenes/vfx/` — `rain_system.tscn` and `ambient_motes.tscn`.
- `scripts/core/palette.gd` — Single centralized Cozy Cyberpunk palette & stylized material helpers.
- `scripts/state_machine/` — Reusable `State` and `StateMachine` nodes.
- `scripts/autoload/` — `GameState`, `AudioManager` (procedural ambient + SFX), and `SceneTransition`.
- `shaders/` — Custom `wet_walkway`, `skyline_windows`, `stylized_prop`, `searchlight_beam`, and `post_process` shaders.
- `ui/hud.tscn` — Minimal status, FPS, quality toggle, and controls legend.

---

## Assets & Attribution

All geometry, shaders, textures, and audio in this project are **100% original procedural assets** created specifically for this project (no external or downloaded assets are used):

- **3D Models & Props**: Composed procedurally from Godot primitive meshes inside modular `scenes/props/` and `scenes/player/courier_visual.tscn`.
- **Shaders & Procedural Textures**: Original GLSL/Godot shaders in `shaders/` and procedural soft puff particle texture generated in `scripts/props/prop_utils.gd`.
- **Audio**: Rain ambiance loop, distant megastructure hum loop, and movement SFX (footsteps, jump, dash, landing, ledge-grab) synthesized at runtime as 16-bit PCM `AudioStreamWAV` streams in `scripts/autoload/audio_manager.gd`.
- **Mood References**: Reference images in `reference/` are excluded from Godot via `reference/.gdignore` and are not bundled or used in-game.
