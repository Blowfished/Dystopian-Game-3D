# LATTICE — Vertical Slice Design Document

## 1. Premise & World
Far in the future, Earth's surface has become toxic and uninhabitable. Humanity did not flee into space; instead, over centuries, they built upward and outward into **the Lattice**—a planet-wide network of colossal, interlinked megastructures rising kilometers above the cloud deck.

Countless walkways, transit tiers, rooftop markets, and steel truss catwalks weave between kilometer-tall arcology towers. Yet the Lattice is not a bleak dystopia. Generations have lived, cooked, gardened, and strung lanterns along its rainy balconies. It is worn, vast, and quiet—a place people have truly made home.

You play as a **stratum courier**, a small figure with a weatherproof messenger bag carrying parcels, letters, and warm meals between tiers of the city.

---

## 2. Tone & Art Direction: Cozy Cyberpunk
> **Cozy first, cyberpunk second.**

- **Emotional Register**: Calm, warm, slightly melancholy, intimate against a breathtaking scale. The comfort of a glowing noodle stall and swaying paper lanterns on a rainy night high above an endless city.
- **Visual Style**: Stylized flat-shaded / painterly 3D with soft value gradients, subtle Fresnel rim lighting, clean silhouettes, and layered atmospheric haze—avoiding noisy photorealism or gritty grime.
- **Color Palette** (centralized in `scripts/core/palette.gd`):
  - **Night Sky & Haze**: Deep navy (`#0B1024`), twilight indigo (`#161D3A`), misty violet-blue horizon (`#262E52`)
  - **Architecture & Shadow**: Cool slate steel (`#1E2740`), wet basalt (`#151B2E`), muted blue-grey structural trusses (`#2B3654`)
  - **Warm Pools (Primary Focus)**: Lantern amber (`#FFB454`), noodle-stall gold (`#FFD38A`), soft cream highlights (`#FFF0CC`)
  - **Restrained Cyberpunk Accents**: Landmark glowing teal (`#24E5D0`), spire magenta beacon (`#FF3FA4`), subtle awning terracotta (`#C85A42`), potted sage foliage (`#467A6E`)
  - **Courier Silhouette**: Warm ochre jacket (`#D89A3C`), dark indigo trousers (`#1B2238`), terracotta scarf (`#C85545`), brown leather messenger bag (`#6E452B`) with a glowing teal tag for instant visual readability.

---

## 3. Gameplay & Feel (Stage 1 Scope)
This first stage is a **single explorable 3D scene** with a playable third-person courier—no quests, combat, or full game loop yet. The goal is to nail the visual mood, spatial scale, and joyous, forgiving traversal feel.

### Movement & Controls
- **Inputs**: Full **Keyboard + Mouse** and **Gamepad** support.
  - Move: `WASD` / Arrow Keys / Left Stick
  - Camera Orbit: Mouse Motion / Right Stick
  - Jump: `Space` / Gamepad South (`A` / `Cross`)
  - Dash: `Shift` / Gamepad East (`B` / `Circle`) or `R1`
  - Quality Preset Cycle: `F1` (Low / Medium / High)
  - Toggle Controls Help: `H` | Release/Capture Cursor: `Esc` / Click
- **Forgiving Platforming Mechanics** (all exposed as `@export` variables on the player):
  - **Variable Jump Height**: Releasing jump early gently cuts upward velocity.
  - **Coyote Time** (`0.14s`): Jump remains valid briefly after stepping off a ledge.
  - **Jump Buffering** (`0.14s`): Pressing jump right before landing triggers immediately on touch.
  - **Air Dash**: Short burst of horizontal speed with slight hang-time, trail burst, and clean cooldown.
  - **Wall-Slide & Wall-Jump**: Sliding smoothly down vertical truss/wall surfaces with reduced fall speed and a forgiving kick-off jump.
  - **Ledge-Grab & Mantle**: Automatically catches nearby platform ledges when airborne and pulls the courier smoothly onto the deck.
- **Third-Person Camera**:
  - `SpringArm3D` with environment collision, damped follow smoothing, pitch clamping, manual orbit, and gentle auto-follow alignment when running without manual camera input.

---

## 4. Scene Plan: `levels/walkway.tscn`
A multi-tier rainy night promenade perched high above a megastructure canyon:

1. **Tier 1 — Main Rainy Promenade (`y = 0m`)**:
   - Wide wet stone walkway with puddle roughness variation, animated rain ripples, and warm reflections.
   - Open vista side lined with modular steel railings looking out over the abyss and skyline.
   - Sheltered facade side housing the centerpiece **lit food stall** (striped terracotta/cream awning, warm glowing counter, menu board, steaming pots, stools), stacked courier crates, **potted plants**, a **parked scooter**, **traffic cones**, a **street lamp**, benches, steam vents, and glowing signs.
   - Overhead **strings of warm paper lanterns** gently swaying in the rain.
2. **Tier 2 — Steel Truss Platforms & Mid Catwalks (`y = 2.4m – 5.5m`)**:
   - Jumpable crate stacks and modular steel truss platforms cantilevered over the walkway edge.
   - A suspended catwalk bridge spanning across the promenade beneath hanging lantern strings, plus a jumpable awning/canopy step above the food stall.
3. **Tier 3 — Upper Overlook Deck (`y = 7.2m – 10.0m`)**:
   - Higher steel truss platforms leading to an elevated quiet balcony with a bench, planter, and hanging lantern—rewarding exploration with an unobstructed panorama of the Lattice skyline.
4. **Distant Skyline & Megastructure Abyss (`scenes/environment/skyline.tscn`)**:
   - Multi-layered `MultiMeshInstance3D` tower clusters at near, mid, far, and colossus depths (extending both high above and far below the walkway), connected by massive distant sky-bridges.
   - Custom procedural window shader rendering thousands of warm lit windows with subtle brightness variation and gentle flicker.
   - **Glowing Teal Landmark Tower**: Tiered architectural silhouette with glowing cyan bands and a pulsing **magenta beacon** spire.
   - **Sweeping Searchlight Beams**: Soft volumetric additive cones cutting upward through the indigo mist.

---

## 5. Technical Architecture & Plan
```text
project/
├── DESIGN.md
├── README.md
├── reference/              # Mood references (.gdignore keeps them out of Godot)
├── assets/                 # Shared resources & palettes
├── shaders/                # Wet walkway, skyline windows, stylized prop, searchlights, post-process
├── scripts/
│   ├── autoload/           # GameState, AudioManager, SceneTransition
│   ├── core/               # Palette & shared material helpers
│   ├── state_machine/      # Reusable State + StateMachine
│   ├── player/             # Courier controller, procedural rig animator, states, camera
│   ├── environment/        # Skyline generator, searchlight animator, quality controller
│   └── props/              # Lantern string builder, swaying foliage/lantern helpers
├── scenes/
│   ├── player/             # courier.tscn, courier_visual.tscn (swappable rig)
│   ├── props/              # Modular reusable prop scenes (swappable with real 3D models)
│   ├── environment/        # skyline.tscn, landmark_tower.tscn
│   └── vfx/                # rain_system.tscn, steam_plume.tscn, ambient_motes.tscn
├── ui/                     # hud.tscn (minimal overlay + quality selector)
└── levels/
    └── walkway.tscn        # Main explorable scene
```

### Rendering & Performance Strategy (60 FPS Target)
- **Global Illumination & Reflections**: ReflectionProbe over the promenade + warm fill lights provide lush reflections and bounce lighting across all tiers; SDFGI and SSR are enabled on higher presets.
- **Quality Presets** (live-switchable via `GameState` and HUD / `F1`):
  - **High**: Volumetric Fog, SSR, SSAO, SDFGI, full light pools, dense rain particles, full post-process.
  - **Medium** *(Default)*: Volumetric Fog, SSR, SSAO, ReflectionProbe + bounce fill lights (SDFGI off), balanced particles, post-process enabled.
  - **Low**: Distance fog + light cones (Volumetric Fog off), ReflectionProbe (SSR/SSAO/SDFGI off), reduced secondary lights, lightweight particles, subtle vignette.
- **Procedural Audio**: `AudioManager` synthesizes seamless ambient rain + distant city hum loops and gentle SFX (footsteps, jump, dash, landing, ledge-grab) at runtime using pure procedural `AudioStreamWAV` generation—zero external downloads, 100% original.

---

## 6. Multi-District City Hub Expansion (Stage 2 Groundwork)
The single balcony promenade has been expanded into a data-driven **4-District City Hub** (~480m × 340m, >12,000 m² of walkable area across 3+ vertical tiers):

### Modular City Kit (`scenes/kit/`) & Data-Driven Layout (`data/city_layout.json`)
- `CityLayoutLoader` (`scripts/world/city_layout_loader.gd`) reads `data/city_layout.json` at startup to assemble streets, plazas, stairs (smooth sloped collision), ramps, bridges, overpasses, facades (with `OccluderInstance3D` + `MultiMeshInstance3D` windows), shopfronts, canopies, balconies, greenhouses, elevators, ladders, ziplines, jump pads, and Maglev stations.
- Districts and props can be added or rearranged purely in `data/city_layout.json` without modifying GDScript.

### The 4 Connected Districts
1. **Noodle Alley (`noodle_alley`)** — West (`y = 0m..11m`): Narrow, steamy warm-amber promenade, food stalls, lanterns, scooter, steam vents, and a zipline east to Market Terraces.
2. **Market Terraces (`market_terraces`)** — Center (`y = 0m..10m`): 3-tier open bazaar plaza with grand stairs, accessible ramps, lifts, colorful fabric canopies, flower stalls, and string lights.
3. **Neon Boulevard (`neon_boulevard`)** — North-East (`y = 0m..14m`): Wide puddle-rich boulevard with bars, arcades, karaoke shopfronts, layered magenta/cyan/teal neon signs, an elevated overpass, and skywalk lifts.
4. **Rooftop Gardens (`rooftop_gardens`)** — South-East High Tier (`y = 14m..24m`): Quiet sky conservatory with glowing glass greenhouses, lanterns, summit pavilion, and a return zipline to Market Terraces.

### Transit, Navigation & Performance
- **Physical Maglev Tram (`scenes/transit/maglev_tram.tscn`)**: 2-car `AnimatableBody3D` train looping continuously between **Noodle Alley West**, **Market Terraces Central**, and **Neon Boulevard South**; players can walk aboard and ride it, or press `F` at any station kiosk for instant fast travel.
- **Minimap & Full Map (`M`)**: Live radar minimap + interactive full-city map displaying districts, stations, POIs, player heading, and live tram position.
- **Streaming & Optimization**: `DistrictStreamer` streams out distant district detail props & local lights (`>215m`), `OccluderInstance3D` culls behind building cores, `MultiMeshInstance3D` batches skyline towers, facade windows, and distant sky-traffic, and `F3` toggles the FPS / Draw Call / Primitives / Active Lights debug overlay.
