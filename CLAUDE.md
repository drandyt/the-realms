# The Realms — Claude Handover Notes

## What this is
A head-to-head 3D tabletop card battler built in **Godot 4.6** (Forward+ renderer).
Two players face each other across a felt table. Each has 8 slots (2 rows × 4 cols)
shaped like silver cups. You fill slots with element cards, connect them with connector
cards to form named formations, then cast the formation for damage or shields.

Being built with a friend — he's the coder, Andre (the user) is the ideas person.

---

## Project location
```
C:\Dev\TheRealms\    ← SOURCE of truth — edit here, commit here
  project.godot      ← Godot project file (main scene = res://main.tscn)
  main.tscn          ← root scene (just a Node3D + script reference)
  main.gd            ← ALL game logic, ~900 lines, procedural scene build
  icon.svg           ← default Godot icon (placeholder)
  CLAUDE.md          ← this file
```

**OneDrive copy at `C:\Users\andre\OneDrive\Documents\the-realms\` is now stale — do not edit it.**
GitHub is the backup. Work in `C:\Dev\TheRealms\`, push to `github.com/drandyt/the-realms`.

## Git discipline
- Branch: `master` is canonical
- GitHub: `github.com/drandyt/the-realms`
- Always commit before ending a session

## CLOSING A SESSION
When the user says "wrap up", "closing", or "end session":
1. `git -C "C:\Dev\TheRealms" status --short`
2. Commit uncommitted changes with a clear message
3. `git -C "C:\Dev\TheRealms" push origin master`
4. Confirm: "Session closed — X files committed."

---

## How to run
- Godot exe: `C:\Users\andre\OneDrive\Desktop\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`
- Open Godot → Import → select `project.godot` (or it should appear in recent projects)
- Press **F5** to run
- If it crashes on launch, open `project.godot` and change `rendering_device/driver.windows` from `"d3d12"` to `"vulkan"`

---

## What's working (as of handover)

### Table & layout
- Dark green felt table, dark wood border, centre dividing line
- Two mirrored sides: player (positive Z) and opponent (negative Z)

### Slots (cups)
- 2 rows × 4 cols per side = 8 slots each
- Silver tapered cup shape (base disc + tapered walls + dark inner)
- Player slots are clickable (Area3D); opponent slots are visual only

### Cards
- Large cards (0.54 × 0.76 world units), dark body, coloured face panel
- **9 element types**: earth, air, water, fire, time, energy, life, light, rage
- Each has a distinct procedural icon (mountain, cone, sphere, torus ring, hourglass, lightning bolt, cross, star, burst) + element name Label3D
- **Connector card**: dark steel body, glowing cyan spine, two end-node dots, "CONNECTOR" label
- Deck = 24 element cards + 6 connectors, shuffled

### Deck & hand
- Draw 3 button (bottom-right) deals 3 cards into the player hand zone
- Deck count label above the button
- Opponent gets 3 cards auto-dealt at game start (visual only, no AI)

### Playing cards
- Click card → it floats up (selected)
- Click a player slot → card fizzles out (shrinks to zero), glowing plasma sphere pops into the cup with elastic bounce + gentle pulse loop
- Connector: click card → click first slot (adjacent neighbours glow cyan) → click second adjacent slot (including diagonal) → card fizzles, silver channel trough + glowing cyan stream appears between the cups

### Plasma merge
- When two connected slots both have plasma → they flash white then blend to a mixed colour
- The channel stream also shifts to the blended colour

### Formation detection
- After every plasma placement or connection, scans the board
- 10 formation shapes defined (see FORMATIONS const in main.gd)
- A formation is ACTIVE when: all its slots have plasma + at least one connection links two of its slots
- Gold rings appear on active formation slots
- Bottom-centre label shows: spell name · formation name · effect text
- Dominant element determines the spell name (e.g. fire + Arrow = "Inferno Strike")

### Cast system
- CAST button (centre-bottom) is enabled only when a formation is active
- On cast: applies damage or shield to the correct side, clears all player plasmas + connections, formation state resets
- Damage = base damage (per formation) × element multiplier
- Shield formations (Rampart, Bastion) add to player_shield instead
- Opponent shield absorbs damage first
- Floating damage/shield labels appear in 3D (billboard Label3D, float and fade)
- HP labels top-left (opponent) and bottom-left (player)
- Starting HP: 30 each. Victory at opponent HP = 0.

---

## Key constants (main.gd top section)

| Const | Value | Meaning |
|---|---|---|
| COLS / ROWS | 4 / 2 | Slot grid per side |
| SLOT_GAP_X / Z | 0.80 / 0.90 | Spacing between cups |
| HAND_COUNT | 3 | Cards drawn at once |
| CARD_W / CARD_D | 0.54 / 0.76 | Card dimensions |
| DECK_X | 2.9 | X position of deck pile |

---

## Formations defined

| Name | Slot indices | Effect |
|---|---|---|
| Rampart | 4 5 6 7 (front row) | Block damage |
| Volley | 0 1 2 3 (back row) | Hit all enemy front slots |
| Arrow | 4 7 1 2 | Focus strike, bonus vs unshielded |
| Wedge | 0 3 5 6 | Flanking, bypasses shield edge |
| Lance | 1+5 or 2+6 | Pierce, ignores shields |
| Wings | 0 4 3 7 (outer cols) | Hit enemy outer slots |
| Crucible | 1 2 5 6 (centre 2×2) | Double merged element power |
| Crown | 0 3 5 6 | Buff all connected slots |
| Tide | 4 1 6 3 (diagonal) | Damage over time |
| Bastion | 0 4 5 2 3 7 (N-shape) | Full shield |

Slot indices (player side):
```
[ 0 ][ 1 ][ 2 ][ 3 ]   ← back row (toward opponent)
[ 4 ][ 5 ][ 6 ][ 7 ]   ← front row (toward player)
```

---

## What's NOT done yet (next priorities)

1. **Git + GitHub** — no version control yet, do this first
2. **Turn system** — currently player can cast freely with no opponent turn
3. **Opponent AI** — opponent hand is dealt visually but does nothing
4. **Win/lose screen** — victory message is just a label, no restart
5. **Sound effects** — silent
6. **Particle effects** — fizzle and cast are tween-only, no particles
7. **Card hover preview** — no tooltip or zoom on hover
8. **Connector → slot constraints** — connectors can link any adjacent slots (filled or empty); design decision needed: require both slots filled before connecting?
9. **Multiple formations** — currently only first matching formation shown
10. **Damage feedback on opponent side** — no visual on opponent's cups when hit

---

## Architecture notes

Everything is in `main.gd` — one big procedural script attached to the root Node3D.
No separate scenes, no resources, no autoloads. Good for a prototype, will need
splitting as complexity grows.

Key state arrays (all indexed by player slot index 0–7):
- `slot_contents[]` — Dictionary (card data) or null
- `slot_plasma_mat[]` — StandardMaterial3D reference for merge colour tweening
- `slot_plasma_color[]` — current Color of plasma (tracks post-merge colour)
- `connections[]` — Array of `{a, b, stream_mat, bridge}` dicts

Physics picking is enabled on the viewport for 3D click detection.
Cards and slots use `Area3D` + `CollisionShape3D` with `input_event` signal.

---

## Godot version
4.6.2 stable — Forward+ renderer, Jolt physics, Vulkan on Windows
