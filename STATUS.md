# THE REALMS — PROJECT STATUS
_Last updated: 2026-05-18 — MAIN session: drag-drop/reclaim fixes, spell-list cast UI, layer tabs + dimming, persistent board. Merged to master (276059b)._

---

## Project
3D tabletop card battler in **Godot 4.6** (Forward+ renderer). Two players face each other across a felt table. Element cards placed into cups form named formations; cast a formation for damage or shields.

**Co-dev:** Andre (ideas/direction) + friend (primary coder). Claude assists both.
**Repo:** `github.com/drandyt/the-realms` — `C:\Dev\TheRealms\`
**Godot exe:** `C:\Users\andre\OneDrive\Desktop\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`

---

## Duty MGR log

### 2026-05-18 — MAIN session (game code, merged to master)
- **Commits:** `08a5954` (spell-list UI, layer tabs, drop-snap & reclaim) + `276059b` (persistent board). Fast-forwarded master `13e2690 → 276059b`, pushed to origin/master. `main.gd` only.
- **Shipped:**
  - Drop targeting: `_earth_slot_at` now snaps to the nearest cup — cards/connectors no longer lost in the gaps between cups. Off-grid release pings card back to hand.
  - Reclaim: click a cup with nothing selected to pull its element **and** connectors back to hand (5-card cap), overflow recycles to deck. Lone connectors reclaimable too.
  - Cast UI reworked: removed CAST/CAST MAGIC/CAST SPIRIT buttons; added a right-side clickable spell list scanning all layers (`_scan_formations`/`_refresh_spells`/`_cast_spell`). One cast per turn per config (`_cast_locked`, greys with ✓), entry vanishes if the formation is broken.
  - Layer tabs (EARTH/MAGIC/SPIRIT) on the right edge; non-active layers dim to 66% transparency and are non-interactive (input gated to `_active_layer`). Magic cups still unlock via enclosure, then are fully usable.
  - **Persistent board:** casting no longer clears cups/connectors, and the board survives turn changes. A formation is recastable each turn until you reclaim its cards to feed upper layers (the core cannibalise decision). `_clear_player_board`/`_clear_layer_board` now unused (kept for a possible future dismantle action).
- **Verified:** headless `--editor --quit` parse clean + boot (`--quit-after`) clean, no SCRIPT ERRORs.
- **NOT runtime-eyeballed (headless can't render):** layer dimming look, right-side tab/panel placement vs deck label & Spellbook button, Magic-cup casting once unlocked. Needs a human in-editor pass.
- **Known asymmetry:** opponent AI still clears + rebuilds its own board each turn (AI logic depends on it). Only the player's side is persistent — making the AI play the persistent/layered game is a larger AI rework, deferred.

### 2026-05-17 — Human MGR engage + close (no game code)
- Human MGR seat engaged, re-synced (git log + STATUS + inbox). Found STATUS already fully reconciled by the audit Duty MGR below — left it intact, no rewrite.
- Git hygiene only: added `.claude/` to `.gitignore` (untracked local harness dir, was the sole working-tree noise). No `.gd`/`.tscn` touched.
- Noted commit `227aa55` "strip Director coupling — The Realms stands alone" — session/clearance model has changed; future sessions should follow current CLAUDE-MGR.md, not the stale Director-inbox protocol.
- Session closed same sitting.

### 2026-05-17 — Full audit-and-reconcile (Director Duty MGR, one-shot)
- **Brief:** docs known to be systematically stale; STATUS under-reporting real progress across multiple commits. Determine TRUE state by reading `main.gd` and rewrite STATUS to match reality exactly. Audit + doc only — no game code touched.
- **Method:** read `main.gd` (~1818 lines) by section + targeted greps. No runtime/in-editor test — findings are from code inspection.
- **Git status (verbatim):** `?? .claude/` — only the untracked harness `.claude/` dir. No tracked changes, no foreign uncommitted work. Not staged/touched.
- **Per-milestone TRUE state vs prior STATUS claim:**
  - **M1 Working prototype** — ✅ Done. Matches claim.
  - **M2 Turn system + basic AI** — ✅ Done. Matches the prior (corrected) claim. Off-turn lock on every input/cast entry; centred turn indicator; `_ai_turn()` (1389) picks a target formation, fills slots, spawns a bridge, scores all formations via `_opp_best_formation()` (1451) and casts the best (`_ai_cast`, 1493).
  - **M3 Full game loop (win/lose, restart)** — ✅ **DONE.** STATUS previously said "Not started" — this was wrong. `_end_game(player_won)` (1540) sets `_game_over`, disables buttons, draws a full-screen overlay with VICTORY/DEFEAT and a "Play Again" button → `_on_restart_pressed()` (1574) → `get_tree().reload_current_scene()`. Win/lose triggers wired: AI cast → `_end_game(false)` on player HP 0; magic/spirit casts → `_end_game(true)` on opponent HP 0; Spirit "Ascendant" is an instant-win.
  - **M4 Polish (sound, particles, hover preview)** — Not started. Confirmed: ZERO audio (no `AudioStreamPlayer`/`.play()`), ZERO particles (no GPU/CPUParticles — all feedback is `create_tween` label/scale animation), NO hover preview (card interaction is click-select only; no `mouse_entered`/`mouse_exited`/hover logic).
- **Magic / Spiritual layer — major doc correction:** STATUS called it a "foundation". It is substantially implemented: `_place_layer_element` with Essence cost (1609), essence banking via Earth casts (`player_essence += geom * ess_mult`, 1237), free-form connectors `_handle_layer_connector` (1636), curved Bézier bridges `_spawn_curved_bridge` (1661), largest-shape formation detection `_check_layer_formation` (1696), magic cast `_on_cast_magic_pressed` (1753) with element multipliers, **Conflux** formation unlocks the spiritual layer (`_unlock_spiritual`, 1793), spirit cast `_on_cast_spirit_pressed` (1772) incl. **Ascendant** instant-win. Always-available Spellbook panel (`_setup_spellbook`, 529).
- **Files touched:** STATUS.md ONLY (this log + state/milestone/priorities below). `main.gd` NOT modified — audit-and-doc task, hard rail respected.
- **Commit:** see git below (STATUS.md-only commit, explicit pathspec).
- **Genuinely NOT done (honest list, no priority call — principal decides):**
  - Sound effects — entirely absent.
  - Particle effects — entirely absent (tween animation only).
  - Hover preview — entirely absent.
  - AI sophistication — `_ai_turn` picks from a fixed target list and never uses the magic/spirit layers; no difficulty scaling. Functional but basic (this is expected scope, noted not as a defect).
  - All findings are code-read only; **a human should verify M3 end-screen + magic/spirit casting in-editor at runtime** before treating "Done" as battle-tested.
- **Open:** prior Duty MGR (turn-system, commit 4d6d9df) correctly flagged the Director's stale premise. This audit confirms the staleness was broader — M3 and the magic/spirit depth were also under-reported. Recommend the Director treat The Realms as "M1–M3 complete in master, M4 polish remaining" going forward.

### 2026-05-17 — Turn system (Director Duty MGR, one-shot)
- **Brief:** implement the turn system (turn state, alternating turns, End Turn affordance, lock placement/cast off-turn, on-screen turn indicator).
- **Finding:** the turn system was **already fully implemented** in `main.gd` (now ~1818 lines, not the ~900 the brief assumed). The repo is further along than the brief's premise. No code changes were made — writing new turn code would have duplicated/regressed working, human-authored logic, against the "legible & reversible / don't invent scope" rails.
- **What is already present (verified by reading, not runtime):**
  - Turn state: `_turn` ("player"/"opponent") + `_game_over` (main.gd:92-93).
  - End Turn: `end_turn_btn` (376-382) → `_on_end_turn_pressed()` (1358) → `_ai_turn()` → `_start_player_turn()` (1326).
  - Off-turn lock via `if _turn != "player" or _game_over: return` at every input/cast entry: card select (693), slot/connector (701), cast (1218), layer placement (1583), magic cast (1754), spirit cast (1773), draw (656), power (502); plus `_set_buttons_enabled(false)` (1317) disables all buttons during opponent turn.
  - Turn indicator: centred top `turn_label` (384-391), "YOUR TURN" / "OPPONENT TURN".
- **Files touched:** STATUS.md only (this log + state lines below). `main.gd` NOT modified.
- **Commit:** see below (STATUS.md-only commit).
- **Design decisions for humans to ratify:** none introduced by this Duty MGR. Note for humans: the existing turn loop recycles the hand and clears the board each turn (`_recycle_hand`/`_clear_player_board`) — that is a pre-existing design choice already in master, not mine.
- **Scope fence (left out, correctly):** no AI written (a working AI `_ai_turn` already exists, beyond the original brief), no win/lose screen authored, no file split, no sound/particles.
- **Open:** the Director's brief described a stale codebase state (~900 lines, no turn system). Recommend the Director re-sync The Realms' actual state before issuing further Duty MGR briefs — Milestone 2 is effectively complete in master.

---

## Current State (as of 2026-05-17)
Single-file game in `main.gd` (~1818 lines). State below verified by code read (not runtime):
- ✅ 3D table, two-player slot grid (2×4 each side)
- ✅ 9 element types with procedural icons
- ✅ Deck / hand / draw / recycle system
- ✅ Card-to-slot placement (plasma spheres)
- ✅ Connector cards linking adjacent slots
- ✅ Plasma merge (colour blending)
- ✅ Formation detection (FORMATIONS table) + cast system, named spells
- ✅ HP / shield tracking, damage / shield 3D labels
- ✅ Turn system — `_turn` state, End Turn button, full off-turn lock on every input/cast, centred turn indicator
- ✅ Opponent AI — `_ai_turn()` builds a target formation, bridges, scores all formations, casts the best (`_ai_cast`)
- ✅ **Win/lose + restart — `_end_game()` full-screen VICTORY/DEFEAT overlay with "Play Again" → `reload_current_scene()`; win/lose triggers fully wired**
- ✅ **Magic / Spiritual layer — NOT just a foundation:** Essence economy + banking, free-form connectors, curved bridges, formation detection, magic & spirit casting with multipliers, Conflux unlocks the spiritual layer, Ascendant instant-win
- ✅ Always-available Spellbook reference panel
- ❌ Sound effects (entirely absent)
- ❌ Particle effects (entirely absent — feedback is tween label/scale animation)
- ❌ Hover preview (entirely absent — click-select only)

**Architecture note:** Everything in `main.gd` (single file by design — do NOT split). Good for prototype; revisit splitting only with the human co-dev's agreement.

**Verification caveat:** all of the above is from reading the code, not running it. A human should confirm the M3 end-screen and magic/spirit casting in-editor at runtime before treating them as battle-tested.

---

## Milestones
| # | Milestone | Status |
|---|-----------|--------|
| 1 | Working prototype (single-file) | ✅ Done |
| 2 | Turn system + basic opponent AI | ✅ Done (verified 2026-05-17 — in master) |
| 3 | Full game loop (win/lose, restart) | ✅ Done (verified 2026-05-17 — `_end_game` + restart in master; STATUS previously said "Not started" — that was wrong) |
| 4 | Polish (sound, particles, hover preview) | Not started (all three confirmed absent in code) |

---

## Sessions
| Session | Role | Prompt |
|---------|------|--------|
| MGR | Manager — coordinates, maintains STATUS, git hygiene | `sessions/MGR.txt` |
| MAIN | Primary dev — Godot 4.6, all game logic | `sessions/MAIN.txt` |

---

## Open Blockers
_None on record yet._

---

## Next Priorities
_M1–M3 complete in master. Remaining work is M4 polish + verification. Priority order is the principal's call — listed here as candidate open items, not a ranking:_
- **Runtime verification (now higher priority)** — in-editor pass on the 2026-05-18 changes: layer dimming/tab placement, right-side spell list, persistent-board feel, Magic-cup casting once unlocked; plus the older M3 end-screen / magic-spirit casting.
- **AI parity with persistent/layered play** — opponent still rebuilds its board each turn and never uses Magic/Spirit. Larger AI rework, deferred but now the main gameplay gap.
- **Sound effects** — none exist.
- **Particle effects** — none exist (currently tween animation only).
- **Hover preview** — none exists (click-select only).
- **AI sophistication** (optional) — `_ai_turn()` uses a fixed target list, never the magic/spirit layers, no difficulty scaling. Functional; enhancement, not a defect.
_(Audit-and-reconcile 2026-05-17: docs were systematically under-reporting; M3 and magic/spirit depth corrected.)_

---

## HOW TO UPDATE THIS FILE
- MGR session → update after any significant session
- MAIN session → update at close (current state, last commit, next priority)
- Note `⬆️ Director:` prefix for any items that need Director-level attention
