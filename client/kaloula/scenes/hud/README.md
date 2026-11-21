# HUD

Match HUD: tug-of-war bar along the top, timer under it, and a dock along the bottom with one
round paint can per player. The paint in a can drains as the frog uses paint; a mini frog in the
can copies what the real frog is doing (sitting, hopping, turning, catching a fly, belly up),
in place.

## Use

Instance `hud.tscn` in the game scene (it's a `CanvasLayer`, so it sits on top of the camera),
then call it from game code:

```gdscript
@onready var hud: HUD = $HUD

# register / refresh a player: the mini frog follows frog.rig, the can takes frog.color
hud.update_frog(player_id, frog, paint_left)        # paint_left: -1 = leave as is

# each player's points: shown on their card, and their share of the total sizes the bar
hud.update_scores({0: 27, 1: 8})

# tiles currently in each player's colour; total = paintable tiles (pools excluded);
# drives the "tiles still unpainted" text
hud.update_points([[0, 19], [1, 8]], total_tiles)

hud.set_timer(seconds_left)                         # red + pulse in the last 10 s, "TIME!" at 0
hud.set_player_name(player_id, "Lily")              # optional, default "Player 1", "Player 2"
```

- Players appear in the order they're first mentioned. The first is docked bottom-left, the last
  bottom-right (mirrored), any others in between. The bar splits by share of the total score
  in the same order, evenly while nobody has scored.
- The mini frog's animation updates by itself every frame; call `update_frog` again only when
  the paint left changes. The can's paint follows the frog's current colour (e.g. after a stomp).
- Calling `update_points` / `set_timer` every frame is fine; the bar and paint level ease to
  new values.
- `paint_max` (3) is how much paint fills a can; more than that shows "lots of paint".
- `controls_hint` is the key help shown in the middle of the dock; edit it in the inspector.

## Files

| File | What |
|---|---|
| `hud.gd`, `hud.tscn` | the HUD and its API |
| `tug_bar.gd` | the bar (`TugBar`) |
| `paint_can.gd` | a can with its paint level and mini frog (`PaintCan`) |
| `player_card.gd` | can + name + points + paint left (`PlayerCard`) |
| `pixel_style_box.gd` | the chunky pixel panel style (`PixelStyleBox`) |

Font: Pixelify Sans (`assets/fonts/`, SIL Open Font License, see `PixelifySans-OFL.txt`).
