extends Node3D

# ── Layout ────────────────────────────────────────────────────
const COLS        = 4
const ROWS        = 2
const SLOT_GAP_X  = 0.80
const SLOT_GAP_Z  = 0.90
const SLOT_NEAR_Z = 0.55

const HAND_COUNT   = 3
const HAND_Z       = 2.80
const HAND_SPACING = 0.72
const DECK_X       = 2.9

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
const FORMATIONS: Array[Dictionary] = [
	{ "name": "Rampart",  "slots": [4,5,6,7],     "effect": "Block incoming damage this round" },
	{ "name": "Volley",   "slots": [0,1,2,3],     "effect": "Strike all enemy front slots" },
	{ "name": "Arrow",    "slots": [4,7,1,2],     "effect": "Focus strike — bonus vs unshielded" },
	{ "name": "Wedge",    "slots": [0,3,5,6],     "effect": "Flanking — bypasses shield edge" },
	{ "name": "Lance",    "slots": [1,5],         "effect": "Pierce — ignores shields" },
	{ "name": "Lance",    "slots": [2,6],         "effect": "Pierce — ignores shields" },
	{ "name": "Wings",    "slots": [0,4,3,7],     "effect": "Hit enemy outer slots" },
	{ "name": "Crucible", "slots": [1,2,5,6],     "effect": "Double merged element power" },
	{ "name": "Crown",    "slots": [0,3,5,6],     "effect": "Buff all connected slots next turn" },
	{ "name": "Tide",     "slots": [4,1,6,3],     "effect": "Damage over time" },
	{ "name": "Bastion",  "slots": [0,4,5,2,3,7], "effect": "Full shield — absorbs next attack" },
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

var player_hp   := 30
var opponent_hp := 30
var player_shield   := 0
var opponent_shield := 0

var _cam: Camera3D
var deck_label: Label
var formation_label: Label
var cast_btn: Button
var hp_player_label: Label
var hp_opp_label: Label


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

	slot_contents.resize(player_slots.size());   slot_contents.fill(null)
	slot_plasma_mat.resize(player_slots.size());  slot_plasma_mat.fill(null)
	slot_plasma_color.resize(player_slots.size()); slot_plasma_color.fill(null)


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
	cam.position = Vector3(0.0, 9.5, 7.0)
	cam.rotation_degrees = Vector3(-56.0, 0.0, 0.0)
	cam.fov = 60.0;  add_child(cam);  return cam


# ── Table ─────────────────────────────────────────────────────

func _setup_table() -> void:
	_table_box(Vector3(6.8, 0.12, 7.8), Vector3(0,-0.06,0), Color(0.10,0.20,0.12), 0.95, 0.0)
	_table_box(Vector3(7.0, 0.06, 8.0), Vector3(0,-0.15,0), Color(0.18,0.10,0.04), 0.65, 0.1)
	_table_box(Vector3(6.6, 0.008, 0.04), Vector3(0,0.004,0), Color(0.22,0.35,0.24), 0.9, 0.0)


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
	var canvas := CanvasLayer.new();  add_child(canvas)

	var btn := Button.new()
	btn.text = "Draw 3";  btn.custom_minimum_size = Vector2(130, 48)
	btn.anchor_left = 1.0;  btn.anchor_right  = 1.0
	btn.anchor_top  = 1.0;  btn.anchor_bottom = 1.0
	btn.offset_left = -150.0;  btn.offset_right  = -20.0
	btn.offset_top  = -70.0;   btn.offset_bottom = -22.0
	btn.pressed.connect(_on_draw_pressed);  canvas.add_child(btn)

	deck_label = Label.new()
	deck_label.anchor_left = 1.0;  deck_label.anchor_right  = 1.0
	deck_label.anchor_top  = 1.0;  deck_label.anchor_bottom = 1.0
	deck_label.offset_left = -150.0;  deck_label.offset_right  = -20.0
	deck_label.offset_top  = -100.0;  deck_label.offset_bottom = -72.0
	deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(deck_label)

	# Formation display — centre bottom
	formation_label = Label.new()
	formation_label.anchor_left   = 0.5;  formation_label.anchor_right  = 0.5
	formation_label.anchor_top    = 1.0;  formation_label.anchor_bottom = 1.0
	formation_label.offset_left   = -260.0;  formation_label.offset_right  = 260.0
	formation_label.offset_top    = -130.0;  formation_label.offset_bottom = -70.0
	formation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	formation_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(formation_label)

	# Cast button (centre bottom, below formation label)
	cast_btn = Button.new()
	cast_btn.text = "CAST"
	cast_btn.custom_minimum_size = Vector2(180, 54)
	cast_btn.anchor_left = 0.5;  cast_btn.anchor_right  = 0.5
	cast_btn.anchor_top  = 1.0;  cast_btn.anchor_bottom = 1.0
	cast_btn.offset_left = -90.0;  cast_btn.offset_right  = 90.0
	cast_btn.offset_top  = -64.0;  cast_btn.offset_bottom = -10.0
	cast_btn.disabled = true
	cast_btn.pressed.connect(_on_cast_pressed)
	canvas.add_child(cast_btn)

	# HP labels
	hp_opp_label = Label.new()
	hp_opp_label.anchor_left = 0.0;  hp_opp_label.anchor_top = 0.0
	hp_opp_label.offset_left = 20.0; hp_opp_label.offset_top = 18.0
	hp_opp_label.offset_right = 260.0; hp_opp_label.offset_bottom = 60.0
	hp_opp_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hp_opp_label)

	hp_player_label = Label.new()
	hp_player_label.anchor_left = 0.0;  hp_player_label.anchor_top    = 1.0
	hp_player_label.anchor_bottom = 1.0
	hp_player_label.offset_left = 20.0; hp_player_label.offset_top    = -54.0
	hp_player_label.offset_right = 260.0; hp_player_label.offset_bottom = -18.0
	hp_player_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hp_player_label)

	_refresh_hp_labels()


# ── Deck & hand ───────────────────────────────────────────────

func _build_deck(target: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new();  rng.randomize()
	target.clear()
	for _i in 24: target.append(ELEMENTS[rng.randi() % ELEMENTS.size()])
	for _i in 6:  target.append(CONNECTOR)
	for i in target.size():
		var j := rng.randi_range(i, target.size() - 1)
		var tmp := target[i];  target[i] = target[j];  target[j] = tmp


func _on_draw_pressed() -> void:
	_deselect_card()
	for node in player_hand: node.queue_free()
	player_hand.clear()
	if player_deck.size() < HAND_COUNT: _build_deck(player_deck)
	var start_x := -(HAND_COUNT - 1) * HAND_SPACING / 2.0
	for i in HAND_COUNT:
		var data: Dictionary = player_deck.pop_back()
		var card := _make_card(data)
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_card(card, data)


func _on_slot_input(_cam2, event, _pos, _normal, _idx, slot_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _has_selection: return
	if _selected_card_data.get("type") == "connector":
		_handle_connector_slot_click(slot_idx)
	else:
		_play_to_slot(slot_idx)


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

func _play_to_slot(idx: int) -> void:
	if slot_contents[idx] != null: return
	var card := _selected_card_node;  var data := _selected_card_data
	_has_selection = false;  _selected_card_node = null;  _selected_card_data = {}
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
	if a == b: return false
	var ra := _slot_rc(a);  var rb := _slot_rc(b)
	return abs(ra.x - rb.x) <= 1 and abs(ra.y - rb.y) <= 1


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
	if not _has_active_formation: return
	var fname: String = _active_formation["name"]
	var base_dmg: int = FORMATION_BASE_DAMAGE.get(fname, 0)
	var mult: float   = ELEMENT_MULTIPLIER.get(_active_dominant, 1.0)
	var damage: int   = int(round(base_dmg * mult))
	var shield: int   = FORMATION_SHIELD.get(fname, 0)
	var spell_caption := _active_spell_name

	if damage > 0:
		# Apply opponent shield then HP
		var absorbed: int = min(opponent_shield, damage)
		opponent_shield -= absorbed
		var net: int = damage - absorbed
		opponent_hp = max(0, opponent_hp - net)
		_flash_damage_on_opponent(net, spell_caption)
	if shield > 0:
		player_shield += shield
		_flash_shield_on_player(shield, spell_caption)

	_refresh_hp_labels()
	_clear_player_board()
	_clear_active_formation()
	formation_label.text = ""

	if opponent_hp <= 0:
		formation_label.text = "★  VICTORY  ★"


func _refresh_hp_labels() -> void:
	hp_opp_label.text    = "OPPONENT  HP %d   ⛨ %d" % [opponent_hp, opponent_shield]
	hp_player_label.text = "YOU       HP %d   ⛨ %d" % [player_hp,   player_shield]


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
	for i in slot_contents.size():
		slot_contents[i]      = null
		slot_plasma_mat[i]    = null
		slot_plasma_color[i]  = null
	connections.clear()
