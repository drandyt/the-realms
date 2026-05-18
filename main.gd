extends Node3D

# ── Layout ────────────────────────────────────────────────────
const COLS        = 12
const ROWS        = 4
const SLOT_GAP_X  = 0.58
const SLOT_GAP_Z  = 0.62
const SLOT_NEAR_Z = 0.50

const HAND_COUNT   = 5
const HAND_Z       = 3.55
const HAND_SPACING = 0.74
const DECK_X       = 4.3

const CARD_W = 0.54
const CARD_H = 0.026
const CARD_D = 0.76

# ── Card definitions ──────────────────────────────────────────
const ELEMENTS: Array[Dictionary] = [
	{ "type": "element", "id": "earth",  "color": Color(0.30, 0.55, 0.15), "glow": Color(0.15, 0.40, 0.05), "dark": Color(0.08, 0.14, 0.04) },
	{ "type": "element", "id": "air",    "color": Color(0.75, 0.90, 1.00), "glow": Color(0.50, 0.75, 1.00), "dark": Color(0.18, 0.22, 0.28) },
	{ "type": "element", "id": "water",  "color": Color(0.10, 0.45, 0.85), "glow": Color(0.05, 0.30, 0.70), "dark": Color(0.03, 0.10, 0.20) },
	{ "type": "element", "id": "fire",   "color": Color(0.95, 0.35, 0.05), "glow": Color(0.85, 0.20, 0.00), "dark": Color(0.22, 0.06, 0.01) },
	{ "type": "element", "id": "time",   "color": Color(0.60, 0.25, 0.85), "glow": Color(0.45, 0.10, 0.70), "dark": Color(0.14, 0.05, 0.20) },
	{ "type": "element", "id": "energy", "color": Color(1.00, 0.90, 0.10), "glow": Color(0.90, 0.75, 0.00), "dark": Color(0.20, 0.18, 0.02) },
	{ "type": "element", "id": "life",   "color": Color(0.20, 0.85, 0.35), "glow": Color(0.05, 0.65, 0.20), "dark": Color(0.04, 0.18, 0.08) },
	{ "type": "element", "id": "light",  "color": Color(1.00, 0.98, 0.80), "glow": Color(1.00, 0.95, 0.60), "dark": Color(0.22, 0.20, 0.12) },
	{ "type": "element", "id": "rage",   "color": Color(0.75, 0.05, 0.05), "glow": Color(0.60, 0.00, 0.00), "dark": Color(0.18, 0.01, 0.01) },
]
const CONNECTOR: Dictionary = {
	"type": "connector", "id": "connector",
	"color": Color(0.55, 0.65, 0.75), "glow": Color(0.30, 0.80, 0.90), "dark": Color(0.10, 0.14, 0.18)
}

# ── Formation definitions ─────────────────────────────────────
# slots: which player slot indices must ALL be filled + connected
# Earth shapes are MUNDANE and ORTHOGONAL only (no diagonals — that is
# Magic's domain). idx = row*COLS + col, rows 0..3, built centre-board.
const FORMATIONS: Array[Dictionary] = [
	{ "name": "Bastion",  "slots": [28,29,30,31,40,41,42,43], "effect": "Full shield — absorbs next attack" },
	{ "name": "Tide",     "slots": [27,28,29,30,31,32],       "effect": "Damage over time" },
	{ "name": "Crown",    "slots": [16,17,18,19,29,41],       "effect": "Buff all connected slots next turn" },
	{ "name": "Arrow",    "slots": [5,6,7,18,30,42],          "effect": "Focus strike — bonus vs unshielded" },
	{ "name": "Wedge",    "slots": [16,28,40,41,42],          "effect": "Flanking — bypasses shield edge" },
	{ "name": "Crucible", "slots": [29,30,41,42],             "effect": "Double merged element power" },
	{ "name": "Wings",    "slots": [28,40,33,45],             "effect": "Hit enemy outer slots" },
	{ "name": "Rampart",  "slots": [40,41,42,43],             "effect": "Block incoming damage this round" },
	{ "name": "Volley",   "slots": [4,5,6,7],                 "effect": "Strike all enemy front slots" },
	{ "name": "Lance",    "slots": [6,18,30,42],              "effect": "Pierce — ignores shields" },
]

# Spell name = formation + dominant element
const SPELLS: Dictionary = {
	"Rampart_earth":  "Stone Wall",    "Rampart_water":  "Tidal Barrier",
	"Rampart_life":   "Root Ward",     "Rampart_light":  "Holy Rampart",
	"Arrow_fire":     "Inferno Strike","Arrow_rage":      "Wrath Bolt",
	"Arrow_air":      "Gale Dart",     "Arrow_energy":   "Thunder Arrow",
	"Volley_air":     "Storm Shower",  "Volley_energy":  "Static Burst",
	"Volley_fire":    "Fire Shower",   "Volley_light":   "Radiant Volley",
	"Lance_rage":     "Berserker Spike","Lance_light":    "Judgement Beam",
	"Lance_energy":   "Plasma Lance",  "Lance_fire":     "Flame Lance",
	"Crucible_fire":  "Firestorm",     "Crucible_water": "Mud Lock",
	"Crucible_life":  "Bloom Surge",   "Crucible_energy":"Overcharge",
	"Crown_time":     "Timestop",      "Crown_energy":   "Overcharge Crown",
	"Crown_light":    "Solar Crown",   "Crown_life":     "Life Crown",
	"Wings_air":      "Hurricane Wings","Wings_light":   "Radiant Wings",
	"Wings_fire":     "Phoenix Wings", "Wings_energy":   "Storm Wings",
	"Wedge_rage":     "Fury Wedge",    "Wedge_water":    "Riptide",
	"Tide_water":     "Undertow",      "Tide_time":      "Entropy Flow",
	"Bastion_earth":  "Iron Fortress", "Bastion_light":  "Holy Aegis",
	"Bastion_water":  "Flood Bastion", "Bastion_life":   "Living Fortress",
}

# ── State ─────────────────────────────────────────────────────
var player_slots: Array[Node3D]   = []
var opponent_slots: Array[Node3D] = []
var player_deck: Array[Dictionary]   = []
var opponent_deck: Array[Dictionary] = []
var player_hand: Array[Node3D]   = []
var opponent_hand: Array[Node3D] = []

var slot_contents: Array    = []   # Dictionary or null
var slot_plasma_mat: Array  = []   # StandardMaterial3D or null
var slot_plasma_color: Array = []  # Color or null
var connections: Array       = []  # {a, b, stream_mat}

# Opponent board (AI side) — logical state + visuals
var opp_slot_contents: Array = []  # Dictionary or null
var opp_connections: Array   = []  # {a, b, bridge}

# Turn / game flow
var _turn := "player"               # "player" or "opponent"
var _game_over := false

var _selected_card_node: Node3D     = null
var _selected_card_data: Dictionary = {}
var _has_selection      := false
var _connector_slot1    := -1
var _slot_highlights: Array[Node3D] = []

var _active_formation_highlights: Array[Node3D] = []
var _active_formation: Dictionary = {}   # currently castable formation
var _active_dominant: String      = ""
var _active_spell_name: String    = ""
var _has_active_formation := false

const START_LIFE := 100
var player_hp   := START_LIFE
var opponent_hp := START_LIFE
var player_shield   := 0
var opponent_shield := 0

var _cam: Camera3D
var deck_label: Label
var formation_label: Label
var cast_btn: Button
var draw_btn: Button
var end_turn_btn: Button
var hp_player_label: Label
var hp_opp_label: Label
var turn_label: Label
var canvas: CanvasLayer
var _overlay: Control
var book_btn: Button
var book_panel: Control

# ── Magic / Spiritual layers (foundation) ─────────────────────
const MAGIC_Y       := 0.78
const SPIRIT_Y      := 1.52
const MAGIC_COST     := 6     # essence to place one magic element
const SPIRIT_COST    := 10    # essence to place one spiritual element
const ELEMENT_POOL   := 24    # finite recycling element pool size

var magic_player_slots: Array[Node3D]  = []
var magic_opp_slots: Array[Node3D]     = []
var spirit_player_slots: Array[Node3D] = []
var spirit_opp_slots: Array[Node3D]    = []

var m_slot_contents: Array = []   # player magic cup contents
var m_connections: Array   = []   # {a, b, bridge}
var s_slot_contents: Array = []   # player spiritual cup contents
var s_connections: Array   = []

var player_essence   := 0
var opponent_essence := 0
var spirit_unlocked  := false

# Magic cups are unlocked (permanently) by enclosing Earth areas with
# connectors. magic_unlocked[i] == earth cup i has its magic cup above it.
var magic_unlocked: Array = []
var connector_graph: Dictionary = {}   # earth idx -> Array[int] neighbour idxs

# Cast power dial: 0 Full (100% dmg, 0 build) · 1 Half (50% dmg, +build) · 2 Channel (0 dmg, ++build)
var cast_power := 0
const POWER_NAMES := ["FULL POWER", "HALF / BUILD", "CHANNEL ALL"]

var essence_label: Label
var power_btn: Button
var cast_magic_btn: Button
var cast_spirit_btn: Button
var spirit_label: Label

var _m_connector_slot1 := -1
var _s_connector_slot1 := -1
var _active_m_formation: Dictionary = {}
var _active_s_formation: Dictionary = {}
var _active_m_spell := ""
var _active_s_spell := ""

# Magic formations — index sets over the 8 magic cups (same 0..7 grid)
const MAGIC_FORMATIONS: Array[Dictionary] = [
	{ "name": "Sigil",      "slots": [1,2,5,6],         "dmg": 22, "effect": "Arcane burst" },
	{ "name": "Vortex",     "slots": [0,3,4,7],         "dmg": 26, "effect": "Spiralling ruin" },
	{ "name": "Conflux",    "slots": [0,1,2,3,4,5,6,7], "dmg": 0,  "effect": "Opens the Spiritual layer" },
]
const SPIRIT_FORMATIONS: Array[Dictionary] = [
	{ "name": "Ascendant", "slots": [0,1,2,3,4,5,6,7], "dmg": 999, "effect": "Unmaking — ends the game" },
	{ "name": "Pillar",    "slots": [0,1,2,3],         "dmg": 45,  "effect": "Heaven's spear" },
]


func _ready() -> void:
	get_viewport().physics_object_picking = true
	_setup_environment()
	_cam = _make_camera()
	_setup_table()
	_setup_slots(1,  player_slots)
	_setup_slots(-1, opponent_slots)
	_setup_deck_pile(1)
	_setup_deck_pile(-1)
	_setup_hand_zone(1)
	_setup_hand_zone(-1)
	_setup_ui()
	_build_deck(player_deck)
	_build_deck(opponent_deck)
	_deal_opponent_hand()

	# Magic / Spiritual cups do NOT exist at start — they are unlocked
	# permanently when you enclose an area with connectors on Earth.
	var n := player_slots.size()
	magic_player_slots.resize(n);  magic_player_slots.fill(null)
	magic_opp_slots.resize(n);     magic_opp_slots.fill(null)
	spirit_player_slots.resize(n); spirit_player_slots.fill(null)
	spirit_opp_slots.resize(n);    spirit_opp_slots.fill(null)
	magic_unlocked.resize(n);      magic_unlocked.fill(false)

	slot_contents.resize(n);   slot_contents.fill(null)
	slot_plasma_mat.resize(n);  slot_plasma_mat.fill(null)
	slot_plasma_color.resize(n); slot_plasma_color.fill(null)
	opp_slot_contents.resize(opponent_slots.size()); opp_slot_contents.fill(null)
	m_slot_contents.resize(n); m_slot_contents.fill(null)
	s_slot_contents.resize(n); s_slot_contents.fill(null)

	_start_player_turn()


# ── Environment ───────────────────────────────────────────────

func _setup_environment() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -30, 0)
	key.light_energy = 1.4;  key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0);  fill.light_energy = 0.3
	add_child(fill)
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.05, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.25, 0.22, 0.35)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env;  add_child(world_env)


func _make_camera() -> Camera3D:
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 13.6, 9.2)
	cam.rotation_degrees = Vector3(-57.0, 0.0, 0.0)
	cam.fov = 62.0;  add_child(cam);  return cam


# ── Table ─────────────────────────────────────────────────────

func _setup_table() -> void:
	_table_box(Vector3(8.6, 0.12, 9.6), Vector3(0,-0.06,0), Color(0.10,0.20,0.12), 0.95, 0.0)
	_table_box(Vector3(8.9, 0.06, 9.9), Vector3(0,-0.15,0), Color(0.18,0.10,0.04), 0.65, 0.1)
	_table_box(Vector3(8.4, 0.008, 0.04), Vector3(0,0.004,0), Color(0.22,0.35,0.24), 0.9, 0.0)


func _table_box(sz: Vector3, pos: Vector3, col: Color, rough: float, metal: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new();  bm.size = sz;  mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col;  mat.roughness = rough;  mat.metallic = metal
	mi.set_surface_override_material(0, mat)
	mi.position = pos;  add_child(mi)


# ── Slots ─────────────────────────────────────────────────────

func _setup_slots(side: int, out_slots: Array[Node3D]) -> void:
	var start_x := -(COLS - 1) * SLOT_GAP_X / 2.0
	for row in ROWS:
		for col in COLS:
			var root := Node3D.new()
			root.name = "%s_Slot_R%d_C%d" % ["P" if side > 0 else "O", row, col]
			root.position = Vector3(
				start_x + col * SLOT_GAP_X, 0.0,
				side * (SLOT_NEAR_Z + row * SLOT_GAP_Z))
			if side < 0: root.rotation_degrees.y = 180.0
			add_child(root);  out_slots.append(root)
			_build_cup(root)
			if side > 0: _add_slot_area(root, out_slots.size() - 1)


func _add_slot_area(slot_root: Node3D, idx: int) -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new();  cyl.radius = 0.32;  cyl.height = 0.45
	shape.shape = cyl;  shape.position.y = 0.12
	area.add_child(shape)
	area.input_event.connect(_on_slot_input.bind(idx))
	slot_root.add_child(area)


func _build_cup(parent: Node3D) -> void:
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color(0.80,0.82,0.85);  silver.metallic = 0.95;  silver.roughness = 0.20
	_cup_part(parent, silver, 0.28, 0.28, 0.03, Vector3(0,0.015,0))
	_cup_part(parent, silver, 0.18, 0.26, 0.14, Vector3(0,0.10,0))
	var imat := StandardMaterial3D.new()
	imat.albedo_color = Color(0.05,0.05,0.08);  imat.roughness = 0.9
	_cup_part(parent, imat, 0.15, 0.15, 0.02, Vector3(0,0.175,0))


func _cup_part(p: Node3D, mat: StandardMaterial3D, tr: float, br: float, h: float, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = tr;  cm.bottom_radius = br;  cm.height = h;  cm.radial_segments = 32
	mi.mesh = cm;  mi.set_surface_override_material(0, mat);  mi.position = pos
	p.add_child(mi)


# ── Elevated layer cups (Magic / Spiritual) ───────────────────

func _setup_layer_slots(side: int, out_slots: Array[Node3D], y: float,
		tint: Color, interactive: bool, hidden := false) -> void:
	var start_x := -(COLS - 1) * SLOT_GAP_X / 2.0
	var layer := "spirit" if y > 1.0 else "magic"
	for row in ROWS:
		for col in COLS:
			var root := Node3D.new()
			root.position = Vector3(
				start_x + col * SLOT_GAP_X, y,
				side * (SLOT_NEAR_Z + row * SLOT_GAP_Z))
			if side < 0: root.rotation_degrees.y = 180.0
			if hidden: root.visible = false
			add_child(root);  out_slots.append(root)
			_build_crystal_cup(root, tint)
			if interactive:
				var area := Area3D.new()
				var shape := CollisionShape3D.new()
				var cyl := CylinderShape3D.new();  cyl.radius = 0.30;  cyl.height = 0.40
				shape.shape = cyl;  shape.position.y = 0.10
				area.add_child(shape)
				area.input_event.connect(_on_layer_slot_input.bind(layer, out_slots.size() - 1))
				root.add_child(area)


func _build_crystal_cup(parent: Node3D, tint: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint.darkened(0.3)
	mat.metallic = 0.4;  mat.roughness = 0.15
	mat.emission_enabled = true;  mat.emission = tint;  mat.emission_energy_multiplier = 0.5
	_cup_part(parent, mat, 0.24, 0.10, 0.16, Vector3(0, 0.08, 0))
	var rim := StandardMaterial3D.new()
	rim.albedo_color = tint;  rim.emission_enabled = true
	rim.emission = tint;  rim.emission_energy_multiplier = 1.4;  rim.roughness = 0.2
	_cup_part(parent, rim, 0.25, 0.25, 0.02, Vector3(0, 0.165, 0))


# ── Deck piles ────────────────────────────────────────────────

func _setup_deck_pile(side: int) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10,0.10,0.22) if side > 0 else Color(0.22,0.08,0.08)
	mat.roughness = 0.55
	var dx := DECK_X * side
	var dz := side * (SLOT_NEAR_Z + SLOT_GAP_Z * 0.5)
	for i in 8:
		var c := MeshInstance3D.new();  var m := BoxMesh.new()
		m.size = Vector3(CARD_W, 0.020, CARD_D)
		c.mesh = m;  c.set_surface_override_material(0, mat)
		c.position = Vector3(dx, i * 0.018, dz);  add_child(c)


# ── Hand zones ────────────────────────────────────────────────

func _setup_hand_zone(side: int) -> void:
	var mi := MeshInstance3D.new();  var zm := BoxMesh.new()
	zm.size = Vector3(HAND_COUNT * HAND_SPACING + 0.4, 0.005, CARD_D + 0.10)
	mi.mesh = zm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14,0.26,0.16);  mat.roughness = 0.95
	mi.set_surface_override_material(0, mat)
	mi.position = Vector3(0.0, 0.002, side * HAND_Z);  add_child(mi)


# ── UI ────────────────────────────────────────────────────────

func _setup_ui() -> void:
	canvas = CanvasLayer.new();  add_child(canvas)

	# ── Decorative bottom action bar ──────────────────────────
	var bar := ColorRect.new()
	bar.color = Color(0.04, 0.03, 0.07, 0.78)
	bar.anchor_left = 0.0;  bar.anchor_right = 1.0
	bar.anchor_top = 1.0;   bar.anchor_bottom = 1.0
	bar.offset_top = -118.0;  bar.offset_bottom = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bar)

	var trim := ColorRect.new()
	trim.color = Color(0.85, 0.70, 0.30, 0.55)
	trim.anchor_left = 0.0;  trim.anchor_right = 1.0
	trim.anchor_top = 1.0;   trim.anchor_bottom = 1.0
	trim.offset_top = -120.0;  trim.offset_bottom = -116.0
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(trim)

	# Six evenly-spaced action buttons in one row inside the bar
	var labels := ["Draw Hand", "End Turn", "Cast Power: FULL", "CAST", "CAST MAGIC", "CAST SPIRIT"]
	var btns: Array[Button] = []
	var step := 166.0
	var start := -((6 - 1) * step + 150.0) / 2.0
	for i in 6:
		var b := Button.new()
		b.text = labels[i]
		b.add_theme_font_size_override("font_size", 19)
		b.anchor_left = 0.5;  b.anchor_right = 0.5
		b.anchor_top = 1.0;   b.anchor_bottom = 1.0
		b.offset_left = start + i * step
		b.offset_right = b.offset_left + 150.0
		b.offset_top = -90.0;  b.offset_bottom = -34.0
		canvas.add_child(b);  btns.append(b)
	draw_btn       = btns[0];  draw_btn.pressed.connect(_on_draw_pressed)
	end_turn_btn   = btns[1];  end_turn_btn.pressed.connect(_on_end_turn_pressed)
	power_btn      = btns[2];  power_btn.pressed.connect(_on_power_pressed)
	cast_btn       = btns[3];  cast_btn.pressed.connect(_on_cast_pressed)
	cast_magic_btn = btns[4];  cast_magic_btn.pressed.connect(_on_cast_magic_pressed)
	cast_spirit_btn= btns[5];  cast_spirit_btn.pressed.connect(_on_cast_spirit_pressed)
	cast_btn.disabled = true
	cast_magic_btn.disabled = true
	cast_spirit_btn.disabled = true

	# Big decorative spell / formation banner above the bar
	formation_label = Label.new()
	formation_label.anchor_left = 0.5;  formation_label.anchor_right = 0.5
	formation_label.anchor_top  = 1.0;  formation_label.anchor_bottom = 1.0
	formation_label.offset_left = -460.0;  formation_label.offset_right = 460.0
	formation_label.offset_top  = -182.0;  formation_label.offset_bottom = -124.0
	formation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	formation_label.add_theme_font_size_override("font_size", 30)
	formation_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	canvas.add_child(formation_label)

	# Turn banner — top centre, large
	turn_label = Label.new()
	turn_label.anchor_left = 0.5;  turn_label.anchor_right = 0.5
	turn_label.anchor_top  = 0.0;  turn_label.anchor_bottom = 0.0
	turn_label.offset_left = -380.0;  turn_label.offset_right = 380.0
	turn_label.offset_top  = 14.0;    turn_label.offset_bottom = 64.0
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 34)
	turn_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	canvas.add_child(turn_label)

	deck_label = Label.new()
	deck_label.anchor_left = 1.0;  deck_label.anchor_right = 1.0
	deck_label.offset_left = -210.0;  deck_label.offset_right = -20.0
	deck_label.offset_top  = 66.0;    deck_label.offset_bottom = 96.0
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deck_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(deck_label)

	# HP — big and colour-coded
	hp_opp_label = Label.new()
	hp_opp_label.anchor_left = 0.0;  hp_opp_label.anchor_top = 0.0
	hp_opp_label.offset_left = 26.0; hp_opp_label.offset_top = 16.0
	hp_opp_label.offset_right = 480.0; hp_opp_label.offset_bottom = 58.0
	hp_opp_label.add_theme_font_size_override("font_size", 30)
	hp_opp_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	canvas.add_child(hp_opp_label)

	hp_player_label = Label.new()
	hp_player_label.anchor_left = 0.0;  hp_player_label.anchor_top = 1.0
	hp_player_label.anchor_bottom = 1.0
	hp_player_label.offset_left = 26.0;  hp_player_label.offset_right = 480.0
	hp_player_label.offset_top  = -180.0;  hp_player_label.offset_bottom = -138.0
	hp_player_label.add_theme_font_size_override("font_size", 30)
	hp_player_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
	canvas.add_child(hp_player_label)

	_setup_spellbook()
	_setup_layer_ui()
	_setup_shape_list()
	_refresh_hp_labels()


# Always-visible left panel: every shape + its spell names
func _setup_shape_list() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0;  panel.anchor_right = 0.0
	panel.anchor_top = 0.0;   panel.anchor_bottom = 1.0
	panel.offset_left = 16.0;   panel.offset_right = 372.0
	panel.offset_top = 160.0;   panel.offset_bottom = -132.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.07, 0.74)
	sb.border_color = Color(0.85, 0.70, 0.30, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	canvas.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	vbox.custom_minimum_size = Vector2(326, 0)
	scroll.add_child(vbox)

	_add_shape_section(vbox, "EARTH  ·  orthogonal (mundane)", FORMATIONS,
		Color(0.55, 0.90, 0.55), true)
	_add_shape_section(vbox, "MAGIC  ·  diagonals allowed", MAGIC_FORMATIONS,
		Color(0.78, 0.50, 1.0), false)
	_add_shape_section(vbox, "SPIRIT  ·  3D (later)", SPIRIT_FORMATIONS,
		Color(1.0, 0.86, 0.45), false)


func _add_shape_section(vbox: VBoxContainer, title: String, list: Array,
		tint: Color, earth: bool) -> void:
	var hdr := Label.new()
	hdr.text = title
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", tint)
	vbox.add_child(hdr)

	for f in list:
		var fn: String = f["name"]
		var tag := ""
		if earth:
			var dmg: int = FORMATION_BASE_DAMAGE.get(fn, 0)
			var shd: int = FORMATION_SHIELD.get(fn, 0)
			tag = ("%d dmg" % dmg) if dmg > 0 else \
				("+%d shield" % shd) if shd > 0 else "support"
		else:
			tag = "%d dmg" % int(f["dmg"])

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var thumb := Control.new()
		thumb.custom_minimum_size = Vector2(112, 64)
		var slots: Array = f["slots"]
		thumb.draw.connect(func(): _paint_shape(thumb, slots, tint))
		row.add_child(thumb)

		var lbl := Label.new()
		lbl.text = "%s   (%s)\n%s" % [fn.to_upper(), tag, f["effect"]]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.82))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(190, 0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)
		vbox.add_child(row)


func _paint_shape(ctrl: Control, slots: Array, tint: Color) -> void:
	var cells := {}
	var minr := 99;  var maxr := -1;  var minc := 99;  var maxc := -1
	for i in slots:
		var r: int = i / COLS;  var c: int = i % COLS
		cells[Vector2i(r, c)] = true
		minr = min(minr, r);  maxr = max(maxr, r)
		minc = min(minc, c);  maxc = max(maxc, c)

	var cols := maxc - minc
	var rows := maxr - minr
	var sz := ctrl.size
	var pad := 9.0
	var pitch := min(
		(sz.x - 2 * pad) / max(1.0, float(cols)),
		(sz.y - 2 * pad) / max(1.0, float(rows)))
	pitch = clamp(pitch, 6.0, 22.0)
	var ox := (sz.x - cols * pitch) * 0.5
	var oy := (sz.y - rows * pitch) * 0.5

	var line_col := Color(0.45, 0.82, 0.95)
	var ring_col := tint.darkened(0.55)

	var dirs := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)]
	for key in cells:
		var p := Vector2(ox + (key.y - minc) * pitch, oy + (key.x - minr) * pitch)
		for d in dirs:
			var nb := Vector2i(key.x + d.x, key.y + d.y)
			if cells.has(nb):
				var np := Vector2(ox + (nb.y - minc) * pitch, oy + (nb.x - minr) * pitch)
				ctrl.draw_line(p, np, line_col, 3.0, true)
	for key in cells:
		var p := Vector2(ox + (key.y - minc) * pitch, oy + (key.x - minr) * pitch)
		ctrl.draw_circle(p, 6.0, ring_col)
		ctrl.draw_circle(p, 4.2, tint)


func _setup_layer_ui() -> void:
	essence_label = Label.new()
	essence_label.anchor_left = 0.0;  essence_label.anchor_top = 0.0
	essence_label.offset_left = 26.0; essence_label.offset_top = 96.0
	essence_label.offset_right = 520.0; essence_label.offset_bottom = 124.0
	essence_label.add_theme_font_size_override("font_size", 21)
	essence_label.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0))
	canvas.add_child(essence_label)

	spirit_label = Label.new()
	spirit_label.anchor_left = 0.0;  spirit_label.anchor_top = 0.0
	spirit_label.offset_left = 26.0; spirit_label.offset_top = 126.0
	spirit_label.offset_right = 560.0; spirit_label.offset_bottom = 152.0
	spirit_label.add_theme_font_size_override("font_size", 18)
	spirit_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	canvas.add_child(spirit_label)

	_refresh_essence_label()
	_update_power_btn()


func _update_power_btn() -> void:
	power_btn.text = "Cast Power: %s" % POWER_NAMES[cast_power]


func _on_power_pressed() -> void:
	if _turn != "player" or _game_over: return
	cast_power = (cast_power + 1) % 3
	_update_power_btn()


func _refresh_essence_label() -> void:
	essence_label.text = "✦ ESSENCE  %d   (magic %d · spirit %d)" % [
		player_essence, MAGIC_COST, SPIRIT_COST]
	spirit_label.text = "SPIRITUAL LAYER: %s" % (
		"OPEN" if spirit_unlocked else "sealed — form Conflux on Magic")


func _flash_essence(amt: int) -> void:
	var lbl := Label3D.new()
	lbl.text = "+%d ✦ ESSENCE" % amt
	lbl.font_size = 40;  lbl.pixel_size = 0.005
	lbl.modulate = Color(0.8, 0.55, 1.0)
	lbl.outline_size = 8;  lbl.outline_modulate = Color.BLACK
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(1.4, 1.0, 1.6)
	add_child(lbl)
	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", 2.2, 1.0)
	t.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(lbl.queue_free)


func _setup_spellbook() -> void:
	book_btn = Button.new()
	book_btn.text = "Spellbook"
	book_btn.custom_minimum_size = Vector2(130, 40)
	book_btn.anchor_left = 1.0;  book_btn.anchor_right = 1.0
	book_btn.offset_left = -150.0;  book_btn.offset_right = -20.0
	book_btn.offset_top  = 18.0;    book_btn.offset_bottom = 58.0
	book_btn.pressed.connect(_on_book_pressed)
	canvas.add_child(book_btn)

	book_panel = PanelContainer.new()
	book_panel.anchor_left = 1.0;  book_panel.anchor_right = 1.0
	book_panel.anchor_top  = 0.0;  book_panel.anchor_bottom = 1.0
	book_panel.offset_left = -440.0;  book_panel.offset_right = -16.0
	book_panel.offset_top  = 66.0;    book_panel.offset_bottom = -16.0
	book_panel.visible = false
	canvas.add_child(book_panel)

	var scroll := ScrollContainer.new()
	book_panel.add_child(scroll)

	var text := Label.new()
	text.text = _build_book_text()
	text.add_theme_font_size_override("font_size", 15)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(404, 0)
	scroll.add_child(text)


func _on_book_pressed() -> void:
	book_panel.visible = not book_panel.visible
	book_btn.text = "Close Book" if book_panel.visible else "Spellbook"


func _build_book_text() -> String:
	var s := "THE REALMS — SPELLBOOK\n"
	s += "════════════════════════\n\n"
	s += "HOW TO PLAY\n"
	s += "• %d-wide x %d-deep Earth board per side.\n" % [COLS, ROWS]
	s += "• Click an element card, then a silver cup.\n"
	s += "• Play a CONNECTOR, then two adjacent cups.\n"
	s += "• Fill + connect a formation to arm it, CAST.\n"
	s += "• Click a filled cup with NO card selected to\n"
	s += "  pull it back to hand (if you have space).\n"
	s += "• Draw Hand = shuffle hand back, draw %d fresh.\n" % HAND_COUNT
	s += "• Deck: 25 element (earth/air/water/fire) +\n"
	s += "  25 connectors, a finite reshuffled pool.\n"
	s += "• Start LIFE: %d each.\n\n" % START_LIFE
	s += "THE THREE LAYERS\n"
	s += "────────────────────────\n"
	s += "EARTH (table): attack/defence formations.\n"
	s += "MAGIC (mid, purple): NO cups at start.\n"
	s += "  Enclose an area with connectors on Earth\n"
	s += "  and the whole block (border + inside) of\n"
	s += "  magic cups appears above — PERMANENTLY.\n"
	s += "  Magic connectors CURVE: link ANY 2 cups.\n"
	s += "  (Placing still costs %d Essence/cup.)\n" % MAGIC_COST
	s += "SPIRIT (top, gold): costs %d Essence/cup.\n" % SPIRIT_COST
	s += "  Sealed until you form CONFLUX on Magic.\n\n"
	s += "ESSENCE — feeding the climb\n"
	s += "────────────────────────\n"
	s += "Use the Cast Power dial before an Earth cast:\n"
	s += "• FULL   — full damage, no Essence.\n"
	s += "• HALF   — half damage, Essence = shape size.\n"
	s += "• CHANNEL— no damage, double Essence.\n"
	s += "Bigger / more-connected shapes bank more.\n"
	s += "Deck is a finite pool: replacing a cup or\n"
	s += "casting returns those cards, reshuffled.\n\n"
	s += "MAGIC FORMATIONS\n"
	s += "────────────────────────\n"
	for mf in MAGIC_FORMATIONS:
		s += "%s (cups %s) — %s\n" % [
			mf["name"], str(mf["slots"]).replace(" ", ""), mf["effect"]]
	s += "\nSPIRIT FORMATIONS\n"
	s += "────────────────────────\n"
	for sf in SPIRIT_FORMATIONS:
		s += "%s (cups %s) — %s\n" % [
			sf["name"], str(sf["slots"]).replace(" ", ""), sf["effect"]]
	s += "\n"
	s += "YOUR CUP LAYOUT (indices)\n"
	s += "  [0][1][2][3]   back row (toward foe)\n"
	s += "  [4][5][6][7]   front row (toward you)\n\n"
	s += "FORMATIONS\n"
	s += "────────────────────────\n"
	for f in FORMATIONS:
		var fname: String = f["name"]
		var dmg: int = FORMATION_BASE_DAMAGE.get(fname, 0)
		var shd: int = FORMATION_SHIELD.get(fname, 0)
		var tag := ""
		if dmg > 0: tag = "%d dmg" % dmg
		elif shd > 0: tag = "+%d shield" % shd
		s += "%s  (cups %s)  — %s\n" % [
			fname, str(f["slots"]).replace(" ", ""), tag]
		s += "   %s\n" % f["effect"]
	s += "\nELEMENT POWER MULTIPLIER\n"
	s += "────────────────────────\n"
	for k in ELEMENT_MULTIPLIER:
		s += "  %s ×%s\n" % [str(k).capitalize(), str(ELEMENT_MULTIPLIER[k])]
	s += "\nSPELL NAMES (formation + element)\n"
	s += "────────────────────────\n"
	for key in SPELLS:
		var parts: PackedStringArray = str(key).split("_")
		s += "  %s + %s = %s\n" % [parts[0], parts[1], SPELLS[key]]
	return s


# ── Deck & hand ───────────────────────────────────────────────

func _build_deck(target: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new();  rng.randomize()
	target.clear()
	# Deck = 25 elements (earth/air/water/fire only) + 25 connectors.
	var pool: Array = ELEMENTS.slice(0, 4)   # earth, air, water, fire
	for _i in 25: target.append(pool[rng.randi() % pool.size()])
	for _i in 25: target.append(CONNECTOR)
	_shuffle_deck(target)


func _shuffle_deck(target: Array) -> void:
	var rng := RandomNumberGenerator.new();  rng.randomize()
	for i in target.size():
		var j := rng.randi_range(i, target.size() - 1)
		var tmp = target[i];  target[i] = target[j];  target[j] = tmp


# Recycling pool: a replaced / cleared / unused card returns to the deck,
# which is re-randomised every time something comes back.
func _return_to_deck(data) -> void:
	if data == null: return
	player_deck.append(data)
	_shuffle_deck(player_deck)
	deck_label.text = "Deck: %d" % player_deck.size()


func _on_draw_pressed() -> void:
	if _turn != "player" or _game_over: return
	_deselect_card()
	_recycle_hand()
	if player_deck.size() < HAND_COUNT: _build_deck(player_deck)
	var start_x := -(HAND_COUNT - 1) * HAND_SPACING / 2.0
	for i in HAND_COUNT:
		var data: Dictionary = player_deck.pop_back()
		var card := _make_card(data)
		card.set_meta("data", data)
		card.position = Vector3(start_x + i * HAND_SPACING, 0.025, HAND_Z)
		_add_card_area(card, data);  add_child(card);  player_hand.append(card)
	deck_label.text = "Deck: %d" % player_deck.size()


func _deal_opponent_hand() -> void:
	if opponent_deck.size() < HAND_COUNT: _build_deck(opponent_deck)
	var start_x := -(HAND_COUNT - 1) * HAND_SPACING / 2.0
	for i in HAND_COUNT:
		var data: Dictionary = opponent_deck.pop_back()
		var card := _make_card(data)
		card.rotation_degrees.y = 180.0
		card.position = Vector3(start_x + i * HAND_SPACING, 0.025, -HAND_Z)
		add_child(card);  opponent_hand.append(card)


# ── Click detection ───────────────────────────────────────────

func _add_card_area(card: Node3D, data: Dictionary) -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new();  box.size = Vector3(CARD_W + 0.04, 0.22, CARD_D + 0.04)
	shape.shape = box;  area.add_child(shape)
	area.input_event.connect(_on_card_input.bind(card, data))
	card.add_child(area)


func _on_card_input(_cam2, event, _pos, _normal, _idx, card: Node3D, data: Dictionary) -> void:
	if _turn != "player" or _game_over: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_card(card, data)


func _on_slot_input(_cam2, event, _pos, _normal, _idx, slot_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _turn != "player" or _game_over: return
	if not _has_selection:
		_take_back_from_slot(slot_idx)
		return
	if _selected_card_data.get("type") == "connector":
		_handle_connector_slot_click(slot_idx)
	else:
		_play_to_slot(slot_idx)


# Click a filled cup with an empty-ish hand to pull the element back.
func _take_back_from_slot(idx: int) -> void:
	if slot_contents[idx] == null: return
	if player_hand.size() >= HAND_COUNT:
		formation_label.text = "Hand is full — play or draw before reclaiming"
		return
	var data: Dictionary = slot_contents[idx]
	# Detach any connectors touching this cup; recycle them to the deck.
	var kept: Array = []
	for conn in connections:
		if conn["a"] == idx or conn["b"] == idx:
			var b = conn.get("bridge")
			if b != null and is_instance_valid(b): b.queue_free()
			_return_to_deck(CONNECTOR)
		else:
			kept.append(conn)
	connections = kept
	_rebuild_connector_graph()
	_free_plasma_in(player_slots[idx])
	slot_contents[idx]     = null
	slot_plasma_mat[idx]   = null
	slot_plasma_color[idx] = null
	_add_card_to_hand(data)
	_check_formations()


func _rebuild_connector_graph() -> void:
	connector_graph.clear()
	for conn in connections:
		var a: int = conn["a"];  var b: int = conn["b"]
		if not connector_graph.has(a): connector_graph[a] = []
		if not connector_graph.has(b): connector_graph[b] = []
		if b not in connector_graph[a]: connector_graph[a].append(b)
		if a not in connector_graph[b]: connector_graph[b].append(a)


func _add_card_to_hand(data: Dictionary) -> void:
	var card := _make_card(data)
	card.set_meta("data", data)
	_add_card_area(card, data)
	add_child(card);  player_hand.append(card)
	_layout_hand()


func _layout_hand() -> void:
	var start_x := -(player_hand.size() - 1) * HAND_SPACING / 2.0
	for i in player_hand.size():
		var c: Node3D = player_hand[i]
		if is_instance_valid(c):
			c.position = Vector3(start_x + i * HAND_SPACING, 0.025, HAND_Z)


# ── Selection ─────────────────────────────────────────────────

func _select_card(card: Node3D, data: Dictionary) -> void:
	_deselect_card()
	_selected_card_node = card;  _selected_card_data = data;  _has_selection = true
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(card, "position:y", 0.22, 0.2)


func _deselect_card() -> void:
	if _has_selection and is_instance_valid(_selected_card_node):
		var t := create_tween().set_ease(Tween.EASE_OUT)
		t.tween_property(_selected_card_node, "position:y", 0.025, 0.15)
	_has_selection = false;  _selected_card_node = null;  _selected_card_data = {}
	_connector_slot1 = -1;  _clear_slot_highlights()


# ── Play element card ─────────────────────────────────────────

func _free_plasma_in(slot: Node3D) -> void:
	for child in slot.get_children():
		if child is MeshInstance3D and child.mesh is SphereMesh:
			child.queue_free()


func _play_to_slot(idx: int) -> void:
	var card := _selected_card_node;  var data := _selected_card_data
	_has_selection = false;  _selected_card_node = null;  _selected_card_data = {}
	# Replacing an occupied cup: the displaced card recycles into the deck.
	if slot_contents[idx] != null:
		_return_to_deck(slot_contents[idx])
		_free_plasma_in(player_slots[idx])
		slot_plasma_mat[idx] = null
		slot_plasma_color[idx] = null
	player_hand.erase(card);  slot_contents[idx] = data

	var t := create_tween().set_parallel(true)
	t.tween_property(card, "scale", Vector3(1.5, 1.5, 1.5), 0.10)
	t.chain().tween_property(card, "scale", Vector3.ZERO, 0.20).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(card.queue_free)

	await get_tree().create_timer(0.18).timeout
	_spawn_plasma(player_slots[idx], data, idx)


# ── Plasma ────────────────────────────────────────────────────

func _spawn_plasma(slot: Node3D, data: Dictionary, slot_idx: int = -1) -> void:
	var plasma := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.13;  mesh.height = 0.26
	mesh.radial_segments = 16;  mesh.rings = 8
	plasma.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color               = data["color"]
	mat.emission_enabled           = true
	mat.emission                   = data["glow"]
	mat.emission_energy_multiplier = 3.5
	mat.roughness = 0.1;  mat.metallic = 0.2
	plasma.set_surface_override_material(0, mat)
	plasma.scale = Vector3.ZERO;  plasma.position.y = 0.175
	slot.add_child(plasma)

	if slot_idx >= 0:
		slot_plasma_mat[slot_idx]    = mat
		slot_plasma_color[slot_idx]  = data["color"]
		_check_merges_for_slot(slot_idx)
		_check_formations()

	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	t.tween_property(plasma, "scale", Vector3.ONE, 0.45)
	await t.finished
	var pulse := create_tween().set_loops()
	pulse.tween_property(mat, "emission_energy_multiplier", 5.0, 0.9).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(mat, "emission_energy_multiplier", 2.5, 0.9).set_ease(Tween.EASE_IN_OUT)


# ── Cards — structure ─────────────────────────────────────────

func _make_card(data: Dictionary) -> Node3D:
	if data["type"] == "connector": return _make_connector_card()
	return _make_element_card(data)


func _make_element_card(data: Dictionary) -> Node3D:
	var root := Node3D.new()

	# Card body
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new();  bm.size = Vector3(CARD_W, CARD_H, CARD_D)
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = data["dark"];  bmat.roughness = 0.6
	body.set_surface_override_material(0, bmat)
	root.add_child(body)

	# Coloured face panel (top surface)
	var face := MeshInstance3D.new()
	var fm := BoxMesh.new();  fm.size = Vector3(CARD_W - 0.04, 0.004, CARD_D - 0.04)
	face.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = data["color"].darkened(0.35)
	fmat.roughness = 0.5
	face.set_surface_override_material(0, fmat)
	face.position.y = CARD_H * 0.5 + 0.002
	root.add_child(face)

	# Element icon
	_build_card_icon(root, data)

	# Element name label
	var lbl := Label3D.new()
	lbl.text = data["id"].to_upper()
	lbl.font_size = 28
	lbl.pixel_size = 0.004
	lbl.modulate = data["color"]
	lbl.outline_size = 4
	lbl.outline_modulate = data["dark"]
	lbl.position = Vector3(0.0, CARD_H * 0.5 + 0.006, 0.27)
	lbl.rotation_degrees = Vector3(-90, 0, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl)

	return root


func _build_card_icon(root: Node3D, data: Dictionary) -> void:
	var y := CARD_H * 0.5 + 0.014
	var z := -0.10   # upper area of card

	match data["id"]:
		"earth":
			_icon_disc(root,  Color(0.35, 0.22, 0.08), 0.13, y - 0.005, z)
			_icon_cone(root,  Color(0.30, 0.55, 0.15), 0.09, 0.14, y, z, data["glow"])
		"fire":
			_icon_cone(root,  Color(0.95, 0.35, 0.05), 0.10, 0.20, y, z, data["glow"])
		"water":
			_icon_sphere(root, Color(0.10, 0.45, 0.85), 0.11, y + 0.04, z, data["glow"])
		"air":
			_icon_ring(root,  Color(0.75, 0.90, 1.00), 0.11, 0.035, y, z, data["glow"])
		"time":
			_icon_cone(root,         Color(0.60, 0.25, 0.85), 0.08, 0.10, y,        z, data["glow"])
			_icon_cone_inv(root,     Color(0.60, 0.25, 0.85), 0.08, 0.10, y + 0.11, z, data["glow"])
		"energy":
			_icon_bolt(root,  Color(1.00, 0.90, 0.10), y, z, data["glow"])
		"life":
			_icon_cross(root, Color(0.20, 0.85, 0.35), y, z, data["glow"])
		"light":
			_icon_star(root,  Color(1.00, 0.98, 0.80), y, z, data["glow"])
		"rage":
			_icon_burst(root, Color(0.75, 0.05, 0.05), y, z, data["glow"])


# ── Icon primitives ───────────────────────────────────────────

func _icon_mat(color: Color, glow: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color;  m.emission_enabled = true
	m.emission = glow;  m.emission_energy_multiplier = 1.6
	m.roughness = 0.3;  return m


func _icon_disc(p: Node3D, col: Color, r: float, y: float, z: float) -> void:
	var mi := MeshInstance3D.new();  var cm := CylinderMesh.new()
	cm.top_radius = r;  cm.bottom_radius = r;  cm.height = 0.010;  cm.radial_segments = 24
	mi.mesh = cm;  mi.set_surface_override_material(0, _icon_mat(col, col))
	mi.position = Vector3(0, y, z);  p.add_child(mi)


func _icon_cone(p: Node3D, col: Color, r: float, h: float, y: float, z: float, glow: Color) -> void:
	var mi := MeshInstance3D.new();  var cm := CylinderMesh.new()
	cm.top_radius = 0.0;  cm.bottom_radius = r;  cm.height = h;  cm.radial_segments = 16
	mi.mesh = cm;  mi.set_surface_override_material(0, _icon_mat(col, glow))
	mi.position = Vector3(0, y + h * 0.5, z);  p.add_child(mi)


func _icon_cone_inv(p: Node3D, col: Color, r: float, h: float, y: float, z: float, glow: Color) -> void:
	var mi := MeshInstance3D.new();  var cm := CylinderMesh.new()
	cm.top_radius = r;  cm.bottom_radius = 0.0;  cm.height = h;  cm.radial_segments = 16
	mi.mesh = cm;  mi.set_surface_override_material(0, _icon_mat(col, glow))
	mi.position = Vector3(0, y + h * 0.5, z);  p.add_child(mi)


func _icon_sphere(p: Node3D, col: Color, r: float, y: float, z: float, glow: Color) -> void:
	var mi := MeshInstance3D.new();  var sm := SphereMesh.new()
	sm.radius = r;  sm.height = r * 1.2;  sm.radial_segments = 16;  sm.rings = 8
	mi.mesh = sm;  mi.set_surface_override_material(0, _icon_mat(col, glow))
	mi.position = Vector3(0, y, z);  p.add_child(mi)


func _icon_ring(p: Node3D, col: Color, outer: float, thickness: float, y: float, z: float, glow: Color) -> void:
	var mi := MeshInstance3D.new();  var tm := TorusMesh.new()
	tm.outer_radius = outer;  tm.inner_radius = outer - thickness
	tm.rings = 24;  tm.ring_segments = 12
	mi.mesh = tm;  mi.set_surface_override_material(0, _icon_mat(col, glow))
	mi.position = Vector3(0, y, z);  p.add_child(mi)


func _icon_bolt(p: Node3D, col: Color, y: float, z: float, glow: Color) -> void:
	# Lightning bolt: two angled boxes
	for sign in [-1, 1]:
		var mi := MeshInstance3D.new();  var bm := BoxMesh.new()
		bm.size = Vector3(0.035, 0.010, 0.10);  mi.mesh = bm
		mi.set_surface_override_material(0, _icon_mat(col, glow))
		mi.position = Vector3(sign * 0.028, y, z + sign * 0.04)
		mi.rotation_degrees.y = sign * 25.0;  p.add_child(mi)


func _icon_cross(p: Node3D, col: Color, y: float, z: float, glow: Color) -> void:
	for rot in [0, 90]:
		var mi := MeshInstance3D.new();  var bm := BoxMesh.new()
		bm.size = Vector3(0.045, 0.012, 0.18);  mi.mesh = bm
		mi.set_surface_override_material(0, _icon_mat(col, glow))
		mi.position = Vector3(0, y, z);  mi.rotation_degrees.y = rot;  p.add_child(mi)


func _icon_star(p: Node3D, col: Color, y: float, z: float, glow: Color) -> void:
	for rot in [0, 45, 90, 135]:
		var mi := MeshInstance3D.new();  var bm := BoxMesh.new()
		bm.size = Vector3(0.030, 0.010, 0.20);  mi.mesh = bm
		mi.set_surface_override_material(0, _icon_mat(col, glow))
		mi.position = Vector3(0, y, z);  mi.rotation_degrees.y = rot;  p.add_child(mi)


func _icon_burst(p: Node3D, col: Color, y: float, z: float, glow: Color) -> void:
	for i in 5:
		var mi := MeshInstance3D.new();  var bm := BoxMesh.new()
		bm.size = Vector3(0.028, 0.010, 0.16);  mi.mesh = bm
		mi.set_surface_override_material(0, _icon_mat(col, glow))
		mi.position = Vector3(0, y, z);  mi.rotation_degrees.y = i * 36.0;  p.add_child(mi)


# ── Connector card ────────────────────────────────────────────

func _make_connector_card() -> Node3D:
	var root := Node3D.new()

	var body := MeshInstance3D.new()
	var bm := BoxMesh.new();  bm.size = Vector3(CARD_W, CARD_H, CARD_D)
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.10,0.12,0.16);  bmat.metallic = 0.85;  bmat.roughness = 0.25
	body.set_surface_override_material(0, bmat);  root.add_child(body)

	var face := MeshInstance3D.new()
	var fm := BoxMesh.new();  fm.size = Vector3(CARD_W-0.04, 0.004, CARD_D-0.04)
	face.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12,0.16,0.20);  fmat.roughness = 0.5
	face.set_surface_override_material(0, fmat)
	face.position.y = CARD_H*0.5+0.002;  root.add_child(face)

	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.55,0.65,0.75);  smat.emission_enabled = true
	smat.emission = Color(0.30,0.80,0.90);  smat.emission_energy_multiplier = 1.8
	smat.roughness = 0.2

	var spine := MeshInstance3D.new()
	var sm := BoxMesh.new();  sm.size = Vector3(0.05, 0.008, CARD_D * 0.52)
	spine.mesh = sm;  spine.set_surface_override_material(0, smat)
	spine.position.y = CARD_H*0.5+0.006;  root.add_child(spine)

	for s in [-1, 1]:
		var dot := MeshInstance3D.new();  var dm := CylinderMesh.new()
		dm.top_radius = 0.055;  dm.bottom_radius = 0.055;  dm.height = 0.010;  dm.radial_segments = 16
		dot.mesh = dm
		var dmat := smat.duplicate() as StandardMaterial3D
		dmat.emission_energy_multiplier = 2.8
		dot.set_surface_override_material(0, dmat)
		dot.position = Vector3(0, CARD_H*0.5+0.008, s * CARD_D * 0.28);  root.add_child(dot)

	var lbl := Label3D.new()
	lbl.text = "CONNECTOR";  lbl.font_size = 24;  lbl.pixel_size = 0.004
	lbl.modulate = Color(0.55,0.65,0.75)
	lbl.position = Vector3(0, CARD_H*0.5+0.006, CARD_D*0.35)
	lbl.rotation_degrees = Vector3(-90,0,0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl)

	return root


# ── Connector two-slot flow ───────────────────────────────────

func _slot_rc(idx: int) -> Vector2i:
	return Vector2i(idx / COLS, idx % COLS)


func _is_adjacent(a: int, b: int) -> bool:
	# Earth: ORTHOGONAL neighbours only — no diagonals (mundane).
	if a == b: return false
	var ra := _slot_rc(a);  var rb := _slot_rc(b)
	return abs(ra.x - rb.x) + abs(ra.y - rb.y) == 1


func _handle_connector_slot_click(idx: int) -> void:
	if _connector_slot1 == -1:
		_connector_slot1 = idx;  _highlight_adjacent_slots(idx)
	else:
		if idx == _connector_slot1:
			_connector_slot1 = -1;  _clear_slot_highlights();  return
		if not _is_adjacent(_connector_slot1, idx): return
		_play_connector(_connector_slot1, idx)


func _highlight_adjacent_slots(origin: int) -> void:
	_clear_slot_highlights()
	for i in player_slots.size():
		if not _is_adjacent(origin, i): continue
		var ring := MeshInstance3D.new();  var rm := CylinderMesh.new()
		rm.top_radius = 0.34;  rm.bottom_radius = 0.34;  rm.height = 0.010;  rm.radial_segments = 32
		ring.mesh = rm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.30,0.80,0.90);  mat.emission_enabled = true
		mat.emission = Color(0.30,0.80,0.90);  mat.emission_energy_multiplier = 2.0
		ring.set_surface_override_material(0, mat)
		ring.position = player_slots[i].position + Vector3(0,0.005,0)
		add_child(ring);  _slot_highlights.append(ring)


func _clear_slot_highlights() -> void:
	for h in _slot_highlights:
		if is_instance_valid(h): h.queue_free()
	_slot_highlights.clear()


func _play_connector(idx_a: int, idx_b: int) -> void:
	var card := _selected_card_node
	_has_selection = false;  _connector_slot1 = -1
	_selected_card_node = null;  _selected_card_data = {}
	_clear_slot_highlights();  player_hand.erase(card)
	var t := create_tween().set_parallel(true)
	t.tween_property(card, "scale", Vector3(1.5,1.5,1.5), 0.10)
	t.chain().tween_property(card, "scale", Vector3.ZERO, 0.20).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(card.queue_free)
	await get_tree().create_timer(0.20).timeout
	_draw_connection(idx_a, idx_b)


func _draw_connection(idx_a: int, idx_b: int) -> void:
	var pos_a := player_slots[idx_a].global_position
	var pos_b := player_slots[idx_b].global_position
	var mid   := (pos_a + pos_b) * 0.5
	var dist  := pos_a.distance_to(pos_b)
	var dir   := (pos_b - pos_a).normalized()

	var trough := MeshInstance3D.new();  var tm := BoxMesh.new()
	tm.size = Vector3(0.20, 0.026, dist - 0.18);  trough.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.14,0.16,0.20);  tmat.metallic = 0.8;  tmat.roughness = 0.3
	trough.set_surface_override_material(0, tmat)

	var stream := MeshInstance3D.new();  var sm := BoxMesh.new()
	sm.size = Vector3(0.07, 0.032, dist - 0.20);  stream.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.30,0.80,0.90);  smat.emission_enabled = true
	smat.emission = Color(0.30,0.80,0.90);  smat.emission_energy_multiplier = 3.0;  smat.roughness = 0.1
	stream.set_surface_override_material(0, smat);  stream.position.y = 0.005

	var bridge := Node3D.new()
	bridge.position = Vector3(mid.x, 0.09, mid.z)
	bridge.rotation.y = atan2(dir.x, dir.z)
	add_child(bridge);  bridge.add_child(trough);  bridge.add_child(stream)

	connections.append({"a": idx_a, "b": idx_b, "stream_mat": smat, "bridge": bridge})
	_register_connector_edge(idx_a, idx_b)

	bridge.scale = Vector3(1.0, 0.0, 1.0)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(bridge, "scale", Vector3.ONE, 0.4)
	await t.finished
	_check_merges_for_slot(idx_a)
	_check_formations()
	var pulse := create_tween().set_loops()
	pulse.tween_property(smat, "emission_energy_multiplier", 5.0, 0.7).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(smat, "emission_energy_multiplier", 2.0, 0.7).set_ease(Tween.EASE_IN_OUT)


# ── Merge ─────────────────────────────────────────────────────

func _check_merges_for_slot(idx: int) -> void:
	for conn in connections:
		var other := -1
		if conn["a"] == idx:   other = conn["b"]
		elif conn["b"] == idx: other = conn["a"]
		if other == -1: continue
		if slot_plasma_mat[idx] != null and slot_plasma_mat[other] != null:
			_apply_merge(idx, other, conn["stream_mat"])


func _apply_merge(idx_a: int, idx_b: int, stream_mat: StandardMaterial3D) -> void:
	var ca: Color = slot_plasma_color[idx_a];  var cb: Color = slot_plasma_color[idx_b]
	var mixed := Color((ca.r+cb.r)*0.5, (ca.g+cb.g)*0.5, (ca.b+cb.b)*0.5)
	var glow  := Color(mixed.r*1.4, mixed.g*1.4, mixed.b*1.4)
	for idx in [idx_a, idx_b]:
		var mat: StandardMaterial3D = slot_plasma_mat[idx]
		if mat == null: continue
		slot_plasma_color[idx] = mixed
		var t := create_tween().set_parallel(true)
		t.tween_property(mat, "emission_energy_multiplier", 8.0, 0.15)
		t.tween_property(mat, "albedo_color", Color.WHITE, 0.15)
		t.chain().tween_property(mat, "emission_energy_multiplier", 3.5, 0.4).set_ease(Tween.EASE_OUT)
		t.chain().tween_property(mat, "albedo_color", mixed, 0.4).set_ease(Tween.EASE_OUT)
		t.chain().tween_property(mat, "emission", glow, 0.4).set_ease(Tween.EASE_OUT)
	var st := create_tween().set_parallel(true)
	st.tween_property(stream_mat, "emission_energy_multiplier", 8.0, 0.15)
	st.tween_property(stream_mat, "albedo_color", Color.WHITE, 0.15)
	st.chain().tween_property(stream_mat, "albedo_color", mixed, 0.5).set_ease(Tween.EASE_OUT)
	st.chain().tween_property(stream_mat, "emission", glow, 0.5).set_ease(Tween.EASE_OUT)


# ── Formation detection ───────────────────────────────────────

func _check_formations() -> void:
	for formation in FORMATIONS:
		var fslots: Array = formation["slots"]

		# All slots must have plasma
		var all_filled := true
		for i in fslots:
			if slot_contents[i] == null:
				all_filled = false;  break
		if not all_filled: continue

		# At least one connection must link two slots inside the formation
		var connected := false
		for conn in connections:
			if conn["a"] in fslots and conn["b"] in fslots:
				connected = true;  break
		if not connected: continue

		# Dominant element
		var counts: Dictionary = {}
		for i in fslots:
			if slot_contents[i] != null:
				var eid: String = slot_contents[i]["id"]
				counts[eid] = counts.get(eid, 0) + 1
		var dominant := ""
		var best := 0
		for k in counts:
			if counts[k] > best:  best = counts[k];  dominant = k

		_show_formation(formation, dominant, fslots)
		return   # show first matched formation only

	# No formation — clear display
	_clear_active_formation()
	formation_label.text = ""


func _show_formation(formation: Dictionary, element: String, fslots: Array) -> void:
	var fname: String = formation["name"]
	var spell_key := fname + "_" + element
	var spell: String = SPELLS.get(spell_key, element.capitalize() + " " + fname)

	_active_formation     = formation
	_active_dominant      = element
	_active_spell_name    = spell
	_has_active_formation = true
	cast_btn.disabled     = false

	formation_label.text = "✦ %s  ·  %s\n%s" % [spell.to_upper(), fname, formation["effect"]]

	# Highlight slots in formation with gold rings
	_clear_active_formation_visuals()
	for i in fslots:
		var ring := MeshInstance3D.new();  var rm := CylinderMesh.new()
		rm.top_radius = 0.34;  rm.bottom_radius = 0.34;  rm.height = 0.010;  rm.radial_segments = 32
		ring.mesh = rm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0,0.85,0.2);  mat.emission_enabled = true
		mat.emission = Color(1.0,0.85,0.2);  mat.emission_energy_multiplier = 2.5
		ring.set_surface_override_material(0, mat)
		ring.position = player_slots[i].position + Vector3(0,0.006,0)
		add_child(ring);  _active_formation_highlights.append(ring)


func _clear_active_formation() -> void:
	_active_formation     = {}
	_active_dominant      = ""
	_active_spell_name    = ""
	_has_active_formation = false
	cast_btn.disabled     = true
	_clear_active_formation_visuals()


func _clear_active_formation_visuals() -> void:
	for h in _active_formation_highlights:
		if is_instance_valid(h): h.queue_free()
	_active_formation_highlights.clear()


# ── Cast / damage ─────────────────────────────────────────────

const FORMATION_BASE_DAMAGE: Dictionary = {
	"Lance": 8, "Arrow": 10, "Volley": 12, "Wedge": 10,
	"Wings": 9, "Crucible": 15, "Tide": 7,
	"Crown": 0, "Rampart": 0, "Bastion": 0,
}

const FORMATION_SHIELD: Dictionary = {
	"Rampart": 10, "Bastion": 18,
}

const ELEMENT_MULTIPLIER: Dictionary = {
	"rage": 1.3, "fire": 1.2, "light": 1.15, "energy": 1.1,
	"earth": 1.0, "water": 1.0, "air": 1.0, "life": 0.9, "time": 1.0,
}


func _on_cast_pressed() -> void:
	if _turn != "player" or _game_over: return
	if not _has_active_formation: return
	var fname: String = _active_formation["name"]
	var base_dmg: int = FORMATION_BASE_DAMAGE.get(fname, 0)
	var mult: float   = ELEMENT_MULTIPLIER.get(_active_dominant, 1.0)
	var shield: int   = FORMATION_SHIELD.get(fname, 0)
	var spell_caption := _active_spell_name

	# Power dial: weaker attack → more Essence banked toward the upper layers.
	# Essence scales with the GEOMETRY of what you built (cups + internal links).
	var fslots: Array = _active_formation["slots"]
	var links := 0
	for conn in connections:
		if conn["a"] in fslots and conn["b"] in fslots: links += 1
	var geom: int = fslots.size() + links
	var dmg_mult: float = [1.0, 0.5, 0.0][cast_power]
	var ess_mult: int = [0, 1, 2][cast_power]
	var damage: int = int(round(base_dmg * mult * dmg_mult))
	shield = int(round(shield * dmg_mult))
	player_essence += geom * ess_mult

	if damage > 0:
		var absorbed: int = min(opponent_shield, damage)
		opponent_shield -= absorbed
		var net: int = damage - absorbed
		opponent_hp = max(0, opponent_hp - net)
		_flash_damage_on_opponent(net, spell_caption)
	if shield > 0:
		player_shield += shield
		_flash_shield_on_player(shield, spell_caption)
	if cast_power > 0:
		_flash_essence(geom * ess_mult)

	_refresh_hp_labels()
	_refresh_essence_label()
	_clear_player_board()
	_clear_active_formation()
	formation_label.text = ""

	if opponent_hp <= 0:
		_end_game(true)


func _refresh_hp_labels() -> void:
	hp_opp_label.text    = "OPPONENT  LIFE %d   ⛨ %d" % [opponent_hp, opponent_shield]
	hp_player_label.text = "YOU       LIFE %d   ⛨ %d" % [player_hp,   player_shield]


func _flash_damage_on_opponent(dmg: int, label: String) -> void:
	var lbl := Label3D.new()
	lbl.text = "-%d  %s" % [dmg, label]
	lbl.font_size = 48;  lbl.pixel_size = 0.005
	lbl.modulate = Color(1.0, 0.3, 0.3)
	lbl.outline_size = 8;  lbl.outline_modulate = Color.BLACK
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.2, -1.0)
	add_child(lbl)
	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", 2.2, 1.0)
	t.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(lbl.queue_free)


func _flash_shield_on_player(amt: int, label: String) -> void:
	var lbl := Label3D.new()
	lbl.text = "+%d ⛨  %s" % [amt, label]
	lbl.font_size = 42;  lbl.pixel_size = 0.005
	lbl.modulate = Color(0.4, 0.9, 1.0)
	lbl.outline_size = 8;  lbl.outline_modulate = Color.BLACK
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.0, 2.0)
	add_child(lbl)
	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", 2.0, 1.0)
	t.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(lbl.queue_free)


func _clear_player_board() -> void:
	for slot in player_slots:
		for child in slot.get_children():
			if child is MeshInstance3D and child.mesh is SphereMesh:
				child.queue_free()
	for conn in connections:
		var b = conn.get("bridge")
		if b != null and is_instance_valid(b):
			b.queue_free()
	for conn in connections:
		_return_to_deck(CONNECTOR)
	for i in slot_contents.size():
		_return_to_deck(slot_contents[i])
		slot_contents[i]      = null
		slot_plasma_mat[i]    = null
		slot_plasma_color[i]  = null
	connections.clear()
	connector_graph.clear()   # magic_unlocked persists — unlocks are permanent


# ── Turn flow ─────────────────────────────────────────────────

func _set_buttons_enabled(on: bool) -> void:
	draw_btn.disabled     = not on
	end_turn_btn.disabled = not on
	power_btn.disabled    = not on
	cast_btn.disabled       = (not on) or (not _has_active_formation)
	cast_magic_btn.disabled  = (not on) or _active_m_formation.is_empty()
	cast_spirit_btn.disabled = (not on) or _active_s_formation.is_empty()


func _start_player_turn() -> void:
	if _game_over: return
	_turn = "player"
	_clear_opponent_board()
	_deal_player_hand()
	_set_buttons_enabled(true)
	turn_label.text = "YOUR TURN"


func _recycle_hand() -> void:
	for node in player_hand:
		if is_instance_valid(node) and node.has_meta("data"):
			player_deck.append(node.get_meta("data"))
		if is_instance_valid(node): node.queue_free()
	player_hand.clear()
	_shuffle_deck(player_deck)


func _deal_player_hand() -> void:
	_deselect_card()
	_recycle_hand()
	if player_deck.size() < HAND_COUNT: _build_deck(player_deck)
	var start_x := -(HAND_COUNT - 1) * HAND_SPACING / 2.0
	for i in HAND_COUNT:
		var data: Dictionary = player_deck.pop_back()
		var card := _make_card(data)
		card.set_meta("data", data)
		card.position = Vector3(start_x + i * HAND_SPACING, 0.025, HAND_Z)
		_add_card_area(card, data);  add_child(card);  player_hand.append(card)
	deck_label.text = "Deck: %d" % player_deck.size()


func _on_end_turn_pressed() -> void:
	if _turn != "player" or _game_over: return
	_deselect_card()
	_clear_player_board()
	_clear_active_formation()
	formation_label.text = ""
	_set_buttons_enabled(false)
	_turn = "opponent"
	turn_label.text = "OPPONENT TURN"
	await _ai_turn()
	if _game_over: return
	_start_player_turn()


# ── Simple AI ─────────────────────────────────────────────────

func _draw_opp_element() -> Dictionary:
	for _attempt in 40:
		if opponent_deck.is_empty(): _build_deck(opponent_deck)
		var data: Dictionary = opponent_deck.pop_back()
		if data["type"] == "element": return data
	return ELEMENTS[0]


func _first_adjacent_pair(slots: Array) -> Array:
	for a in slots:
		for b in slots:
			if _is_adjacent(a, b): return [a, b]
	return []


func _ai_turn() -> void:
	_clear_opponent_board()
	await get_tree().create_timer(0.4).timeout

	# Pick a real offensive Earth formation to build.
	var offensive: Array = []
	for f in FORMATIONS:
		if FORMATION_BASE_DAMAGE.get(f["name"], 0) > 0:
			offensive.append(f["slots"])
	var target: Array = offensive[randi() % offensive.size()]

	for i in target:
		if opp_slot_contents[i] != null: continue
		var data := _draw_opp_element()
		opp_slot_contents[i] = data
		_spawn_plasma(opponent_slots[i], data, -1)
		await get_tree().create_timer(0.30).timeout

	var pair := _first_adjacent_pair(target)
	if pair.size() == 2:
		_spawn_opp_bridge(pair[0], pair[1])
		await get_tree().create_timer(0.45).timeout

	var best := _opp_best_formation()
	if not best.is_empty():
		turn_label.text = "OPPONENT CASTS %s" % str(best["spell"]).to_upper()
		await get_tree().create_timer(0.5).timeout
		_ai_cast(best)
	else:
		await get_tree().create_timer(0.3).timeout


func _spawn_opp_bridge(idx_a: int, idx_b: int) -> void:
	var pos_a := opponent_slots[idx_a].global_position
	var pos_b := opponent_slots[idx_b].global_position
	var mid   := (pos_a + pos_b) * 0.5
	var dist  := pos_a.distance_to(pos_b)
	var dir   := (pos_b - pos_a).normalized()

	var trough := MeshInstance3D.new();  var tm := BoxMesh.new()
	tm.size = Vector3(0.20, 0.026, dist - 0.18);  trough.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.20,0.14,0.16);  tmat.metallic = 0.8;  tmat.roughness = 0.3
	trough.set_surface_override_material(0, tmat)

	var stream := MeshInstance3D.new();  var sm := BoxMesh.new()
	sm.size = Vector3(0.07, 0.032, dist - 0.20);  stream.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.95,0.40,0.40);  smat.emission_enabled = true
	smat.emission = Color(0.90,0.25,0.25);  smat.emission_energy_multiplier = 3.0;  smat.roughness = 0.1
	stream.set_surface_override_material(0, smat);  stream.position.y = 0.005

	var bridge := Node3D.new()
	bridge.position = Vector3(mid.x, 0.09, mid.z)
	bridge.rotation.y = atan2(dir.x, dir.z)
	add_child(bridge);  bridge.add_child(trough);  bridge.add_child(stream)

	opp_connections.append({"a": idx_a, "b": idx_b, "bridge": bridge})

	bridge.scale = Vector3(1.0, 0.0, 1.0)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(bridge, "scale", Vector3.ONE, 0.4)
	await t.finished


func _opp_best_formation() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1
	for formation in FORMATIONS:
		var fslots: Array = formation["slots"]
		var all_filled := true
		for i in fslots:
			if opp_slot_contents[i] == null:
				all_filled = false;  break
		if not all_filled: continue
		var connected := false
		for conn in opp_connections:
			if conn["a"] in fslots and conn["b"] in fslots:
				connected = true;  break
		if not connected: continue

		var counts: Dictionary = {}
		for i in fslots:
			var eid: String = opp_slot_contents[i]["id"]
			counts[eid] = counts.get(eid, 0) + 1
		var dominant := ""
		var top := 0
		for k in counts:
			if counts[k] > top:  top = counts[k];  dominant = k

		var fname: String = formation["name"]
		var base_dmg: int = FORMATION_BASE_DAMAGE.get(fname, 0)
		var mult: float   = ELEMENT_MULTIPLIER.get(dominant, 1.0)
		var damage: int   = int(round(base_dmg * mult))
		var shield: int   = FORMATION_SHIELD.get(fname, 0)
		var score: int    = damage if damage > 0 else int(shield * 0.5)
		if score > best_score:
			var spell_key := fname + "_" + dominant
			best_score = score
			best = {
				"formation": formation, "dominant": dominant,
				"damage": damage, "shield": shield,
				"spell": SPELLS.get(spell_key, dominant.capitalize() + " " + fname),
			}
	return best


func _ai_cast(best: Dictionary) -> void:
	var damage: int = best["damage"]
	var shield: int = best["shield"]
	if damage > 0:
		var absorbed: int = min(player_shield, damage)
		player_shield -= absorbed
		var net: int = damage - absorbed
		player_hp = max(0, player_hp - net)
		_flash_damage_on_player(net, best["spell"])
	if shield > 0:
		opponent_shield += shield
	_refresh_hp_labels()
	if player_hp <= 0:
		_end_game(false)


func _flash_damage_on_player(dmg: int, label: String) -> void:
	var lbl := Label3D.new()
	lbl.text = "-%d  %s" % [dmg, label]
	lbl.font_size = 48;  lbl.pixel_size = 0.005
	lbl.modulate = Color(1.0, 0.3, 0.3)
	lbl.outline_size = 8;  lbl.outline_modulate = Color.BLACK
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.2, 1.6)
	add_child(lbl)
	var t := create_tween().set_parallel(true)
	t.tween_property(lbl, "position:y", 2.4, 1.0)
	t.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(lbl.queue_free)


func _clear_opponent_board() -> void:
	for slot in opponent_slots:
		for child in slot.get_children():
			if child is MeshInstance3D and child.mesh is SphereMesh:
				child.queue_free()
	for conn in opp_connections:
		var b = conn.get("bridge")
		if b != null and is_instance_valid(b):
			b.queue_free()
	for i in opp_slot_contents.size():
		opp_slot_contents[i] = null
	opp_connections.clear()


# ── Game over / restart ───────────────────────────────────────

func _end_game(player_won: bool) -> void:
	_game_over = true
	_set_buttons_enabled(false)
	_deselect_card()

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.anchor_right = 1.0;  _overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(_overlay)

	var msg := Label.new()
	msg.text = "★  VICTORY  ★" if player_won else "DEFEAT"
	msg.anchor_left = 0.5;  msg.anchor_right = 0.5
	msg.anchor_top  = 0.5;  msg.anchor_bottom = 0.5
	msg.offset_left = -300.0;  msg.offset_right = 300.0
	msg.offset_top  = -90.0;   msg.offset_bottom = -30.0
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 56)
	msg.add_theme_color_override("font_color",
		Color(1.0, 0.85, 0.2) if player_won else Color(1.0, 0.35, 0.35))
	_overlay.add_child(msg)

	var restart := Button.new()
	restart.text = "Play Again"
	restart.custom_minimum_size = Vector2(200, 56)
	restart.anchor_left = 0.5;  restart.anchor_right = 0.5
	restart.anchor_top  = 0.5;  restart.anchor_bottom = 0.5
	restart.offset_left = -100.0;  restart.offset_right = 100.0
	restart.offset_top  = 20.0;    restart.offset_bottom = 76.0
	restart.pressed.connect(_on_restart_pressed)
	_overlay.add_child(restart)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


# ── Magic / Spiritual layer interaction (foundation) ──────────

func _on_layer_slot_input(_c, event, _p, _n, _i, layer: String, idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _turn != "player" or _game_over: return
	if not _has_selection: return
	if layer == "spirit" and not spirit_unlocked: return

	if _selected_card_data.get("type") == "connector":
		_handle_layer_connector(layer, idx)
	else:
		_place_layer_element(layer, idx)


func _layer_slots(layer: String) -> Array:
	return magic_player_slots if layer == "magic" else spirit_player_slots

func _layer_contents(layer: String) -> Array:
	return m_slot_contents if layer == "magic" else s_slot_contents

func _layer_connections(layer: String) -> Array:
	return m_connections if layer == "magic" else s_connections

func _layer_cost(layer: String) -> int:
	return MAGIC_COST if layer == "magic" else SPIRIT_COST

func _layer_tint(layer: String) -> Color:
	return Color(0.6,0.3,0.95) if layer == "magic" else Color(1.0,0.9,0.5)


func _place_layer_element(layer: String, idx: int) -> void:
	var cost := _layer_cost(layer)
	if player_essence < cost:
		_flash_essence_warn()
		return
	var contents := _layer_contents(layer)
	var slots := _layer_slots(layer)
	var card := _selected_card_node
	var data := _selected_card_data
	_has_selection = false;  _selected_card_node = null;  _selected_card_data = {}

	if contents[idx] != null:
		_return_to_deck(contents[idx])
		_free_plasma_in(slots[idx])
	player_essence -= cost
	contents[idx] = data
	player_hand.erase(card)
	var t := create_tween().set_parallel(true)
	t.tween_property(card, "scale", Vector3(1.4,1.4,1.4), 0.10)
	t.chain().tween_property(card, "scale", Vector3.ZERO, 0.18).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(card.queue_free)
	await get_tree().create_timer(0.16).timeout
	_spawn_plasma(slots[idx], data, -1)
	_refresh_essence_label()
	_check_layer_formation(layer)


func _handle_layer_connector(layer: String, idx: int) -> void:
	var first := _m_connector_slot1 if layer == "magic" else _s_connector_slot1
	if first == -1:
		if layer == "magic": _m_connector_slot1 = idx
		else: _s_connector_slot1 = idx
		return
	if idx == first:
		if layer == "magic": _m_connector_slot1 = -1
		else: _s_connector_slot1 = -1
		return
	# Magic/Spirit links are free-form: any two cups, no grid adjacency.
	var card := _selected_card_node
	_has_selection = false;  _selected_card_node = null;  _selected_card_data = {}
	player_hand.erase(card)
	if layer == "magic": _m_connector_slot1 = -1
	else: _s_connector_slot1 = -1
	var t := create_tween().set_parallel(true)
	t.tween_property(card, "scale", Vector3(1.4,1.4,1.4), 0.10)
	t.chain().tween_property(card, "scale", Vector3.ZERO, 0.18).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(card.queue_free)
	await get_tree().create_timer(0.16).timeout
	_spawn_curved_bridge(layer, first, idx)
	_check_layer_formation(layer)


func _spawn_curved_bridge(layer: String, a: int, b: int) -> void:
	var slots := _layer_slots(layer)
	var pa: Vector3 = slots[a].global_position + Vector3(0, 0.16, 0)
	var pb: Vector3 = slots[b].global_position + Vector3(0, 0.16, 0)
	var tint := _layer_tint(layer)
	var lift := 0.35 + pa.distance_to(pb) * 0.18
	var ctrl := (pa + pb) * 0.5 + Vector3(0, lift, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint;  mat.emission_enabled = true
	mat.emission = tint;  mat.emission_energy_multiplier = 3.0;  mat.roughness = 0.15

	var bridge := Node3D.new();  add_child(bridge)
	var segs := 14
	var prev := pa
	for s in range(1, segs + 1):
		var tt := float(s) / segs
		var omt := 1.0 - tt
		var pt := omt*omt*pa + 2.0*omt*tt*ctrl + tt*tt*pb
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, prev.distance_to(pt))
		seg.mesh = bm
		seg.set_surface_override_material(0, mat)
		seg.position = (prev + pt) * 0.5
		seg.look_at(pt, Vector3.UP)
		bridge.add_child(seg)
		prev = pt

	_layer_connections(layer).append({"a": a, "b": b, "bridge": bridge})
	bridge.scale = Vector3.ZERO
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(bridge, "scale", Vector3.ONE, 0.35)


func _check_layer_formation(layer: String) -> void:
	var contents := _layer_contents(layer)
	var conns := _layer_connections(layer)
	var list: Array = MAGIC_FORMATIONS if layer == "magic" else SPIRIT_FORMATIONS
	# Prefer the LARGEST completed shape — bigger geometry = bigger spell.
	var formation: Dictionary = {}
	var best_size := -1
	for cand in list:
		var cslots: Array = cand["slots"]
		var ok := true
		for i in cslots:
			if contents[i] == null: ok = false; break
		if not ok: continue
		var clinked := false
		for conn in conns:
			if conn["a"] in cslots and conn["b"] in cslots: clinked = true; break
		if not clinked: continue
		if cslots.size() > best_size:
			best_size = cslots.size();  formation = cand
	if not formation.is_empty():
		var fslots: Array = formation["slots"]
		var counts: Dictionary = {}
		for i in fslots:
			var eid: String = contents[i]["id"]
			counts[eid] = counts.get(eid, 0) + 1
		var dom := "";  var top := 0
		for k in counts:
			if counts[k] > top: top = counts[k]; dom = k
		var spell := "%s %s" % [dom.capitalize(), formation["name"]]
		if layer == "magic":
			_active_m_formation = formation;  _active_m_spell = spell
			cast_magic_btn.disabled = (_turn != "player")
			formation_label.text = "✦ MAGIC: %s — %s" % [spell.to_upper(), formation["effect"]]
		else:
			_active_s_formation = formation;  _active_s_spell = spell
			cast_spirit_btn.disabled = (_turn != "player")
			formation_label.text = "✦ SPIRIT: %s — %s" % [spell.to_upper(), formation["effect"]]
		return
	if layer == "magic":
		_active_m_formation = {};  cast_magic_btn.disabled = true
	else:
		_active_s_formation = {};  cast_spirit_btn.disabled = true


func _layer_dominant_mult(layer: String, formation: Dictionary) -> float:
	var contents := _layer_contents(layer)
	var counts: Dictionary = {}
	for i in formation["slots"]:
		if contents[i] != null:
			var eid: String = contents[i]["id"]
			counts[eid] = counts.get(eid, 0) + 1
	var dom := "";  var top := 0
	for k in counts:
		if counts[k] > top: top = counts[k]; dom = k
	return ELEMENT_MULTIPLIER.get(dom, 1.0)


func _on_cast_magic_pressed() -> void:
	if _turn != "player" or _game_over or _active_m_formation.is_empty(): return
	var f := _active_m_formation
	var dmg := int(round(int(f["dmg"]) * _layer_dominant_mult("magic", f)))
	if dmg > 0:
		var absorbed: int = min(opponent_shield, dmg)
		opponent_shield -= absorbed
		var net: int = dmg - absorbed
		opponent_hp = max(0, opponent_hp - net)
		_flash_damage_on_opponent(net, _active_m_spell)
	if f["name"] == "Conflux":
		_unlock_spiritual()
	_clear_layer_board("magic")
	_active_m_formation = {};  cast_magic_btn.disabled = true
	formation_label.text = ""
	_refresh_hp_labels()
	if opponent_hp <= 0: _end_game(true)


func _on_cast_spirit_pressed() -> void:
	if _turn != "player" or _game_over or _active_s_formation.is_empty(): return
	var f := _active_s_formation
	if f["name"] == "Ascendant":
		_flash_damage_on_opponent(opponent_hp, "ASCENDANT")
		opponent_hp = 0
		_refresh_hp_labels()
		_end_game(true)
		return
	var dmg := int(round(int(f["dmg"]) * _layer_dominant_mult("spirit", f)))
	var absorbed: int = min(opponent_shield, dmg)
	opponent_shield -= absorbed
	opponent_hp = max(0, opponent_hp - (dmg - absorbed))
	_flash_damage_on_opponent(dmg - absorbed, _active_s_spell)
	_clear_layer_board("spirit")
	_active_s_formation = {};  cast_spirit_btn.disabled = true
	formation_label.text = ""
	_refresh_hp_labels()
	if opponent_hp <= 0: _end_game(true)


func _unlock_spiritual() -> void:
	spirit_unlocked = true
	for s in spirit_player_slots: s.visible = true
	for s in spirit_opp_slots:    s.visible = true
	_refresh_essence_label()
	turn_label.text = "✦ THE SPIRITUAL LAYER OPENS ✦"


func _clear_layer_board(layer: String) -> void:
	var contents := _layer_contents(layer)
	var conns := _layer_connections(layer)
	var slots := _layer_slots(layer)
	for slot in slots:
		_free_plasma_in(slot)
	for conn in conns:
		var b = conn.get("bridge")
		if b != null and is_instance_valid(b): b.queue_free()
		_return_to_deck(CONNECTOR)
	for i in contents.size():
		_return_to_deck(contents[i])
		contents[i] = null
	conns.clear()


func _flash_essence_warn() -> void:
	formation_label.text = "Not enough ✦ Essence — cast Earth spells (Half/Channel) to bank it"


# ── Enclosure → Magic-cup unlock ──────────────────────────────

func _grid_xy(i: int) -> Vector2:
	return Vector2(i % COLS, i / COLS)


func _register_connector_edge(a: int, b: int) -> void:
	if not connector_graph.has(a): connector_graph[a] = []
	if not connector_graph.has(b): connector_graph[b] = []
	if b not in connector_graph[a]: connector_graph[a].append(b)
	if a not in connector_graph[b]: connector_graph[b].append(a)
	# A new edge that joins two already-connected cups closes a loop.
	var cycle := _find_cycle_path(a, b)
	if cycle.size() >= 3:
		_unlock_enclosed(cycle)


func _find_cycle_path(a: int, b: int) -> Array:
	# BFS shortest path a→b that does NOT use the direct (a,b) edge.
	var prev: Dictionary = {a: -1}
	var queue: Array = [a]
	while not queue.is_empty():
		var u: int = queue.pop_front()
		for v in connector_graph.get(u, []):
			if (u == a and v == b) or (u == b and v == a): continue
			if prev.has(v): continue
			prev[v] = u
			if v == b:
				var path: Array = []
				var c := b
				while c != -1:
					path.append(c);  c = prev[c]
				return path
			queue.append(v)
	return []


func _unlock_enclosed(cycle: Array) -> void:
	var poly: Array = []
	for idx in cycle: poly.append(_grid_xy(idx))
	for j in player_slots.size():
		if magic_unlocked[j]: continue
		if j in cycle or _point_in_poly(_grid_xy(j), poly):
			_unlock_magic_cup(j)


func _point_in_poly(p: Vector2, poly: Array) -> bool:
	var inside := false
	var n := poly.size()
	var k := n - 1
	for i in n:
		var pi: Vector2 = poly[i]
		var pk: Vector2 = poly[k]
		if ((pi.y > p.y) != (pk.y > p.y)) and \
		   (p.x < (pk.x - pi.x) * (p.y - pi.y) / (pk.y - pi.y) + pi.x):
			inside = not inside
		k = i
	return inside


func _unlock_magic_cup(i: int) -> void:
	if magic_unlocked[i]: return
	magic_unlocked[i] = true

	var tint := Color(0.6, 0.3, 0.95)
	var root := Node3D.new()
	root.position = player_slots[i].position;  root.position.y = MAGIC_Y
	add_child(root);  magic_player_slots[i] = root
	_build_crystal_cup(root, tint)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new();  cyl.radius = 0.26;  cyl.height = 0.40
	shape.shape = cyl;  shape.position.y = 0.10
	area.add_child(shape)
	area.input_event.connect(_on_layer_slot_input.bind("magic", i))
	root.add_child(area)

	var oroot := Node3D.new()
	oroot.position = opponent_slots[i].position;  oroot.position.y = MAGIC_Y
	oroot.rotation_degrees.y = 180.0
	add_child(oroot);  magic_opp_slots[i] = oroot
	_build_crystal_cup(oroot, tint)

	root.scale = Vector3.ZERO
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(root, "scale", Vector3.ONE, 0.4)
	if turn_label: turn_label.text = "✦ MAGIC CUPS UNLOCKED ✦"
