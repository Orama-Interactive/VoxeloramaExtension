extends Node

var is_moving = false
var kname: String
var tool_slot = null  # Tools.Slot
var cursor_text := ""

var _cursor := Vector2.INF
var _depth_array := []  # 2D array
var _depth := 1.0
var _canvas_depth: PackedScene = preload("res://src/Extensions/Voxelorama/Tools/CanvasDepth.tscn")
var _canvas_depth_node: Node2D

onready var global = get_node("/root/Global")  # Only when used as a Pixelorama plugin


func _ready() -> void:
	kname = name.replace(" ", "_").to_lower()
	load_config()
	if global:
		_canvas_depth_node = _canvas_depth.instance()
		global.canvas.add_child(_canvas_depth_node)


func save_config() -> void:
	if global:
		var config := get_config()
		global.config_cache.set_value(tool_slot.kname, kname, config)


func load_config() -> void:
	if global:
		var value = global.config_cache.get_value(tool_slot.kname, kname, {})
		set_config(value)
		update_config()


func get_config() -> Dictionary:
	return {"depth": _depth}


func set_config(config: Dictionary) -> void:
	_depth = config.get("depth", _depth)


func update_config() -> void:
	$HBoxContainer/DepthHSlider.value = _depth
	$HBoxContainer/DepthSpinBox.value = _depth


func draw_start(position: Vector2) -> void:
	if !global:
		return
	is_moving = true
	_depth_array = []
	var project = global.current_project
	var cel: Reference = project.frames[project.current_frame].cels[project.current_layer]
	var image: Image = cel.image
	print(cel.has_meta("VoxelDepth"))
	if cel.has_meta("VoxelDepth"):
		var image_depth_array: Array = cel.get_meta("VoxelDepth")
		var n_array_pixels: int = image_depth_array.size() * image_depth_array[0].size()
		var n_image_pixels: int = image.get_width() * image.get_height()

		if n_array_pixels == n_image_pixels:
			_depth_array = image_depth_array
		else:
			_initialize_array(image)
	else:
		_initialize_array(image)
	_update_array(cel, position)


func draw_move(position: Vector2) -> void:
	if !global:
		return
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_moving:
		draw_start(position)
	var project = global.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]
	_update_array(cel, position)


func draw_end(position: Vector2) -> void:
	if !global:
		return
	is_moving = false
	var project = global.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]
	_update_array(cel, position)


func cursor_move(position: Vector2) -> void:
	_cursor = position


func draw_indicator() -> void:
	var rect := Rect2(_cursor, Vector2.ONE)
	if global:
		global.canvas.indicators.draw_rect(rect, Color.blue, false)


func draw_preview() -> void:
	pass


func _initialize_array(image: Image) -> void:
	for x in image.get_width():
		_depth_array.append([])
		for y in image.get_height():
			_depth_array[x].append(1)


func _update_array(cel: Reference, position: Vector2) -> void:
	_depth_array[position.x][position.y] = _depth
	cel.set_meta("VoxelDepth", _depth_array)
	_canvas_depth_node.update()


func _on_DepthHSlider_value_changed(value: float) -> void:
	_depth = value
	update_config()
	save_config()


func _exit_tree() -> void:
	if global:
		_canvas_depth_node.queue_free()
		if is_moving:
			draw_end(global.canvas.current_pixel.floor())
