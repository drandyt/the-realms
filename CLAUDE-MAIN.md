# The Realms — MAIN Session Manual

## Role
You are the MAIN dev session for The Realms. You write GDScript, build scenes, implement game logic. The project is Godot 4.6 (Forward+ renderer, Jolt physics, Vulkan on Windows).

---

## On Open
1. Read `C:\Dev\TheRealms\STATUS.md` — current state and next priority
2. Read `C:\Dev\TheRealms\CLAUDE.md` — full project reference (architecture, formations, constants)
3. Confirm ready

---

## Key Files
| File | Purpose |
|------|---------|
| `main.gd` | ALL game logic (~900 lines, growing). Procedural scene build. |
| `main.tscn` | Root scene (Node3D + script reference) |
| `project.godot` | Godot project file |
| `CLAUDE.md` | Full project reference — formations, slot layout, architecture |
| `STATUS.md` | Project dashboard — update at close |

---

## Architecture
Everything is in `main.gd` — one procedural script on the root Node3D. No separate scenes or autoloads yet. This is intentional for a prototype. Do not split until the turn system + AI skeleton is in place.

Key state arrays (indexed by player slot 0–7):
- `slot_contents[]` — card data or null
- `slot_plasma_mat[]` — StandardMaterial3D for merge colour tweening
- `slot_plasma_color[]` — current plasma Color
- `connections[]` — `{a, b, stream_mat, bridge}` dicts

Slot layout (player side):
```
[ 0 ][ 1 ][ 2 ][ 3 ]   ← back row (toward opponent)
[ 4 ][ 5 ][ 6 ][ 7 ]   ← front row (toward player)
```
Opponent mirror: slots 8–15.

---

## How to Run
- Godot exe: `C:\Users\andre\OneDrive\Desktop\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`
- Open project → F5 to run
- If crash on launch: open `project.godot`, change `rendering_device/driver.windows` from `"d3d12"` to `"vulkan"`

---

## Coding Standards
- GDScript only (no C# for now — keep it accessible to the co-dev friend)
- Keep functions short and named clearly — this is a co-authored project
- Comment the why, not the what
- `node --check` equivalent: run the game and confirm no red errors in the Godot console before closing

---

## Next Priorities (in order)
1. Turn system — alternating player/opponent turns; CAST locked until your turn
2. Opponent AI — random legal-move AI to make the game testable end-to-end
3. Win/lose screen with restart

---

## Closing Checklist
1. `git -C "C:\Dev\TheRealms" status --short`
2. Commit with explicit pathspecs
3. Push to master
4. Update `STATUS.md` — what changed, last commit hash, next priority
5. Confirm: "Session closed — X files committed, STATUS.md updated."

---

## Co-Dev Context
Being built with a friend. He codes; Andre directs. Claude assists. Keep changes legible — the friend reads this code too. Don't introduce patterns or abstractions the collaborator can't follow.
