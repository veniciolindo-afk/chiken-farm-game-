extends Node3D

const SAVE_PATH := "user://chicken_farm_v01.json"
var coins := 25.0
var eggs := 0
var chickens := 1
var coops := 1
var egg_clock := 0.0
var chicken_nodes: Array[Node3D] = []
var stats: Label
var notice: Label
var buy_button: Button
var coop_button: Button

func _ready() -> void:
	build_world()
	build_ui()
	load_game()
	refresh_chickens()
	refresh_ui()

func _process(delta: float) -> void:
	egg_clock += delta * chickens / 3.0
	var made := int(egg_clock)
	if made > 0:
		egg_clock -= made
		eggs += made
		refresh_ui()
	for i in chicken_nodes.size():
		chicken_nodes[i].position.y = 0.35 + sin(Time.get_ticks_msec() * 0.004 + i) * 0.025

func build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a9ddf2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(7, 8, 10)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	camera.current = true
	add_child(camera)
	box(Vector3(0, -0.2, 0), Vector3(14, 0.4, 10), Color("79bd63"))
	box(Vector3(0, 0.02, 0), Vector3(2.2, 0.08, 9), Color("e7c57a"))
	box(Vector3(-3.5, 0.65, -1.5), Vector3(3.2, 1.3, 2.5), Color("ed985f"))
	box(Vector3(-3.5, 1.55, -1.5), Vector3(3.7, 0.25, 2.9), Color("b95043"), Vector3(0, 0, 8))
	box(Vector3(-3.5, 0.5, -0.2), Vector3(0.9, 1.0, 0.12), Color("70422f"))

func box(at: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	shape.material = material(color)
	node.mesh = shape
	node.position = at
	node.rotation_degrees = rotation
	add_child(node)
	return node

func material(color: Color) -> StandardMaterial3D:
	var value := StandardMaterial3D.new()
	value.albedo_color = color
	value.roughness = 0.9
	return value

func make_chicken(index: int) -> Node3D:
	var chicken := Node3D.new()
	var angle := index * 2.399
	var radius := 1.1 + (index % 4) * 0.55
	chicken.position = Vector3(cos(angle) * radius + 1.5, 0.35, sin(angle) * radius)
	add_child(chicken)
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.32
	body_mesh.height = 0.58
	body_mesh.radial_segments = 12
	body_mesh.rings = 6
	body.mesh = body_mesh
	body.material_override = material(Color("fff7df"))
	chicken.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.4
	head.mesh = head_mesh
	head.position = Vector3(0, 0.33, -0.18)
	head.material_override = material(Color("fff7df"))
	chicken.add_child(head)
	var beak := MeshInstance3D.new()
	var beak_mesh := BoxMesh.new()
	beak_mesh.size = Vector3(0.16, 0.1, 0.18)
	beak.mesh = beak_mesh
	beak.position = Vector3(0, 0.31, -0.42)
	beak.material_override = material(Color("f5b642"))
	chicken.add_child(beak)
	return chicken

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new()
	title.text = "CHICKEN FARM"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("5b3825"))
	column.add_child(title)
	stats = Label.new()
	stats.add_theme_font_size_override("font_size", 21)
	stats.add_theme_color_override("font_color", Color("4a3426"))
	column.add_child(stats)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	notice = Label.new()
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 18)
	column.add_child(notice)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	buy_button = action(actions, "Comprar galinha", buy_chicken)
	action(actions, "Vender ovos", sell_eggs)
	coop_button = action(actions, "Melhorar galinheiro", buy_coop)

func action(parent: Control, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(215, 64)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func chicken_price() -> float:
	return round(10.0 * pow(1.16, chickens - 1))

func coop_price() -> float:
	return round(100.0 * pow(1.8, coops - 1))

func buy_chicken() -> void:
	if chickens >= coops * 10:
		message("Galinheiro cheio! Faça uma melhoria.")
		return
	if coins < chicken_price():
		message("Moedas insuficientes.")
		return
	coins -= chicken_price()
	chickens += 1
	refresh_chickens()
	save_game()
	refresh_ui()

func sell_eggs() -> void:
	if eggs == 0:
		message("Espere as galinhas botarem ovos.")
		return
	coins += eggs * 2.0
	eggs = 0
	message("Ovos vendidos!")
	save_game()
	refresh_ui()

func buy_coop() -> void:
	if coins < coop_price():
		message("Moedas insuficientes para melhorar.")
		return
	coins -= coop_price()
	coops += 1
	message("Capacidade aumentada!")
	save_game()
	refresh_ui()

func refresh_chickens() -> void:
	for node in chicken_nodes:
		node.queue_free()
	chicken_nodes.clear()
	for i in min(chickens, 35):
		chicken_nodes.append(make_chicken(i))

func refresh_ui() -> void:
	stats.text = "Moedas: %.0f     Ovos: %d     Galinhas: %d/%d     Produção: %.1f ovos/s" % [coins, eggs, chickens, coops * 10, chickens / 3.0]
	buy_button.text = "Comprar galinha\n%.0f moedas" % chicken_price()
	coop_button.text = "Melhorar galinheiro\n%.0f moedas" % coop_price()

func message(text: String) -> void:
	notice.text = text
	get_tree().create_timer(2.5).timeout.connect(func(): notice.text = "")

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"coins": coins, "eggs": eggs, "chickens": chickens, "coops": coops}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		coins = maxf(0.0, float(data.get("coins", coins)))
		eggs = maxi(0, int(data.get("eggs", eggs)))
		chickens = maxi(1, int(data.get("chickens", chickens)))
		coops = maxi(1, int(data.get("coops", coops)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
