extends Node

var is_moving = false
var kname: String
var tool_slot = null  # Tools.Slot
var cursor_text := ""

var _last_position := Vector2i(Vector2.INF)
var _depth_slider: TextureProgressBar
var _cursor := Vector2.INF
var _depth_array: Array[PackedFloat32Array] = []
## We're only using one cel so one array is sufficient.
var _depth_undo_data: Array[PackedFloat32Array] = []
var _depth := 1.0
var _canvas_depth := preload("res://src/Extensions/Voxelorama/Tools/CanvasDepth.tscn")
var _canvas_depth_node: Node2D
var _canvas: Node2D


func _ready() -> void:
	_depth_slider = ExtensionsApi.general.create_value_slider()
	_depth_slider.custom_minimum_size.y = 24
	_depth_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_depth_slider.value_changed.connect(_on_depth_slider_value_changed)
	_depth_slider.min_value = 1
	_depth_slider.max_value = 25
	_depth_slider.step = 0.5
	_depth_slider.value = 1
	_depth_slider.prefix = "Depth:"
	_depth_slider.allow_greater = true
	add_child(_depth_slider)
	kname = name.replace(" ", "_").to_lower()
	if tool_slot.name == "Left tool":
		$ColorRect.color = ExtensionsApi.general.get_global().left_tool_color
	else:
		$ColorRect.color = ExtensionsApi.general.get_global().right_tool_color
	load_config()

	_canvas = ExtensionsApi.general.get_canvas()
	for child in _canvas.get_children():
		if child.is_in_group("CanvasDepth"):
			_canvas_depth_node = child
			_canvas_depth_node.users += 1
			# We will share single _canvas_depth_node
			return
	_canvas_depth_node = _canvas_depth.instantiate()
	_canvas.add_child(_canvas_depth_node)


func save_config() -> void:
	var config := get_config()
	ExtensionsApi.general.get_config_file().set_value(tool_slot.kname, kname, config)


func load_config() -> void:
	var value = ExtensionsApi.general.get_config_file().get_value(tool_slot.kname, kname, {})
	set_config(value)
	update_config()


func get_config() -> Dictionary:
	return {"depth": _depth}


func set_config(config: Dictionary) -> void:
	_depth = config.get("depth", _depth)


func update_config() -> void:
	_depth_slider.value = _depth


func draw_start(pos: Vector2) -> void:
	is_moving = true
	_depth_array = []
	var project: RefCounted = ExtensionsApi.project.current_project
	var cel: RefCounted = project.frames[project.current_frame].cels[project.current_layer]
	var image: Image = cel.image
	if cel.has_meta("VoxelDepth"):
		var image_depth_array: Array[PackedFloat32Array] = cel.get_meta("VoxelDepth")
		var n_array_pixels: int = image_depth_array.size() * image_depth_array[0].size()
		var n_image_pixels: int = image.get_width() * image.get_height()

		if n_array_pixels == n_image_pixels:
			_depth_array = image_depth_array
		else:
			_initialize_array(image)
	else:
		_initialize_array(image)
	_depth_undo_data = (cel.get_meta("VoxelDepth", _depth_array)).duplicate(true)
	_update_array(cel, pos)
	_last_position = pos


func draw_move(pos: Vector2) -> void:
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_moving:
		draw_start(pos)
	var project: RefCounted = ExtensionsApi.project.current_project
	var cel: RefCounted = project.frames[project.current_frame].cels[project.current_layer]
	fill_gap(cel, _last_position, pos)
	_last_position = pos


func draw_end(pos: Vector2) -> void:
	is_moving = false
	var project: RefCounted = ExtensionsApi.project.current_project
	var cel: RefCounted = project.frames[project.current_frame].cels[project.current_layer]
	_update_array(cel, pos)
	_commit_undo(cel)


func _commit_undo(cel: RefCounted) -> void:
	var project: RefCounted = ExtensionsApi.project.current_project
	var redo_data = _depth_array.duplicate(true)
	var undo_data = _depth_undo_data.duplicate(true)
	project.undos += 1
	project.undo_redo.create_action("Change Depth")
	project.undo_redo.add_do_method(cel.set_meta.bind("VoxelDepth", redo_data))
	project.undo_redo.add_undo_method(cel.set_meta.bind("VoxelDepth", undo_data))
	var main_nodes = ExtensionsApi.get_main_nodes("Voxelorama")
	if main_nodes.size() > 0:
		project.undo_redo.add_do_method(main_nodes[0].call.bind("update_undo_redo_canvas"))
		project.undo_redo.add_undo_method(main_nodes[0].call.bind("update_undo_redo_canvas"))
	project.undo_redo.add_do_method(ExtensionsApi.general.get_global().general_redo.bind(project))
	project.undo_redo.add_undo_method(ExtensionsApi.general.get_global().general_undo.bind(project))
	project.undo_redo.commit_action()
	_depth_undo_data.clear()


func cursor_move(pos: Vector2) -> void:
	_cursor = pos


# Bresenham's Algorithm
# Thanks to https://godotengine.org/qa/35276/tile-based-line-drawing-algorithm-efficiency
func fill_gap(cel: RefCounted, start: Vector2i, end: Vector2i) -> void:
	var dx := absi(end.x - start.x)
	var dy := -absi(end.y - start.y)
	var err := dx + dy
	var e2 := err << 1
	var sx := 1 if start.x < end.x else -1
	var sy := 1 if start.y < end.y else -1
	var x := start.x
	var y := start.y
	while !(x == end.x && y == end.y):
		e2 = err << 1
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		_update_array(cel, Vector2i(x, y))


func draw_indicator(left: bool) -> void:
	var rect := Rect2(_cursor, Vector2.ONE)
	if _canvas:
		var global: Node = ExtensionsApi.general.get_global()
		var color: Color = global.left_tool_color if left else global.right_tool_color
		_canvas.indicators.draw_rect(rect, color, false)


func draw_preview() -> void:
	pass


func _initialize_array(image: Image) -> void:
	for x in image.get_width():
		_depth_array.append(PackedFloat32Array())
		for y in image.get_height():
			_depth_array[x].append(1)


func _update_array(cel: RefCounted, position: Vector2) -> void:
	_depth_array[position.x][position.y] = _depth
	cel.set_meta("VoxelDepth", _depth_array)
	_canvas_depth_node.queue_redraw()


func _on_depth_slider_value_changed(value: float) -> void:
	_depth = value
	update_config()
	save_config()


func _exit_tree() -> void:
	if _canvas:
		_canvas_depth_node.request_deletion()
		if is_moving:
			draw_end(_canvas.current_pixel.floor())
