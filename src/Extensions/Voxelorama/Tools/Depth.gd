extends "res://src/Tools/BaseDraw.gd"

var _last_position := Vector2i(Vector2.INF)
var _fill_checkbox: CheckBox
var _depth_slider: TextureProgressBar
var _depth_array: Array[PackedFloat32Array] = []
## We're only using one cel so array is sufficient.
var _depth_undo_data: Array[PackedFloat32Array] = []
var _depth := 1.0
var _canvas_depth := preload("res://src/Extensions/Voxelorama/Tools/CanvasDepth.tscn")
var _canvas_depth_node: Node2D
var _canvas: Node2D
var _draw_points: Array[Vector2i] = []
var _fill_inside = false
var _depth_modified = false


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
	_fill_checkbox = CheckBox.new()
	_fill_checkbox.toggled.connect(_on_fill_inside_toggled)
	add_child(_fill_checkbox)

	_canvas = ExtensionsApi.general.get_canvas()
	super._ready()
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
	var config := super.get_config()
	config["depth"] = _depth
	config["fill_inside"] = _fill_inside
	return config


func set_config(config: Dictionary) -> void:
	super.set_config(config)
	_depth = config.get("depth", _depth)
	_fill_inside = config.get("fill_inside", _fill_inside)


func update_config() -> void:
	super.update_config()
	_depth_slider.value = _depth
	_fill_checkbox.button_pressed = _fill_inside


func draw_start(pos: Vector2i) -> void:
	is_moving = true
	_depth_modified = false
	_depth_array = []
	_draw_points = []
	_depth_undo_data = []

	var project = ExtensionsApi.project.current_project
	var cel: RefCounted = project.frames[project.current_frame].cels[project.current_layer]
	var image: Image = cel.image
	if cel.has_meta("VoxelDepth"):
		var image_depth_array: Array[PackedFloat32Array] = Array(
			cel.get_meta("VoxelDepth"), TYPE_PACKED_FLOAT32_ARRAY, "", null
		).duplicate(true)
		var n_array_pixels: int = image_depth_array.size() * image_depth_array[0].size()
		var n_image_pixels: int = image.get_width() * image.get_height()

		if n_array_pixels == n_image_pixels:
			_depth_array = image_depth_array
		else:
			_initialize_array(image)
	else:
		_initialize_array(image)
	var temp_depth_array: Array[PackedFloat32Array] = Array(
		cel.get_meta("VoxelDepth", _depth_array), TYPE_PACKED_FLOAT32_ARRAY, "", null
	)
	_depth_undo_data = temp_depth_array.duplicate(true)

	_draw_line = Input.is_action_pressed("draw_create_line")
	if _draw_line:
		_line_start = pos
		_line_end = pos
		update_line_polylines(_line_start, _line_end)
	else:
		if _fill_inside:
			_draw_points.append(pos)
		_update_array(cel, pos)
		_last_position = pos
	cursor_text = ""
	_update_array(cel, pos)
	_last_position = pos


func draw_move(pos: Vector2i) -> void:
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_moving:
		draw_start(pos)
	var project = ExtensionsApi.project.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]

	if _draw_line:
		var dict := _line_angle_constraint(_line_start, pos)
		if dict.has("position"):
			_line_end = dict.position
		if dict.has("text"):
			cursor_text = dict.text
		update_line_polylines(_line_start, _line_end)
	else:
		fill_gap(cel, _last_position, pos)
		_last_position = pos
		cursor_text = ""
		if _fill_inside:
			_draw_points.append(pos)


func draw_end(pos: Vector2i) -> void:
	is_moving = false
	var project = ExtensionsApi.project.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]
	if _draw_line:
		_update_array(cel, pos)
		fill_gap(cel, _line_start, _line_end)
		_draw_line = false
	else:
		if _fill_inside:
			_draw_points.append(pos)
			if _draw_points.size() > 3:
				var v = Vector2()
				var map_size = ExtensionsApi.project.current_project.size
				for x in map_size.x:
					v.x = x
					for y in map_size.y:
						v.y = y
						if Geometry2D.is_point_in_polygon(v, _draw_points):
							_update_array(cel, v)
	cursor_text = ""
	if _depth_modified:
		_commit_undo(cel)


func _commit_undo(cel: RefCounted) -> void:
	var project = ExtensionsApi.project.current_project
	project.undos += 1
	project.undo_redo.create_action("Change Depth")
	project.undo_redo.add_do_method(cel.set_meta.bind("VoxelDepth", _depth_array.duplicate(true)))
	project.undo_redo.add_undo_method(cel.set_meta.bind("VoxelDepth", _depth_undo_data))
	var main_nodes = ExtensionsApi.get_main_nodes("Voxelorama")
	if main_nodes.size() > 0:
		project.undo_redo.add_do_method(main_nodes[0].call.bind("update_undo_redo_canvas"))
		project.undo_redo.add_undo_method(main_nodes[0].call.bind("update_undo_redo_canvas"))
	project.undo_redo.add_do_method(ExtensionsApi.general.get_global().general_redo.bind(project))
	project.undo_redo.add_undo_method(ExtensionsApi.general.get_global().general_undo.bind(project))
	project.undo_redo.commit_action()


func cursor_move(pos: Vector2i) -> void:
	_cursor = pos


func draw_preview() -> void:
	pass


func _initialize_array(image: Image) -> void:
	for x in image.get_width():
		_depth_array.append(PackedFloat32Array())
		for y in image.get_height():
			_depth_array[x].append(1)


func _update_array(cel: RefCounted, pos: Vector2i) -> void:
	_prepare_tool()
	var coords_to_draw := _get_depth_points(pos)
	for coord in coords_to_draw:
		if ExtensionsApi.project.current_project.can_pixel_get_drawn(coord):
			if _depth_array[coord.x][coord.y] != _depth:
				_depth_array[coord.x][coord.y] = _depth
				_depth_modified = true
	cel.set_meta("VoxelDepth", _depth_array)
	_canvas_depth_node.queue_redraw()


func _on_depth_slider_value_changed(value: float) -> void:
	_depth = value
	update_config()
	save_config()


func _on_fill_inside_toggled(button_pressed: bool) -> void:
	_fill_inside = button_pressed
	update_config()
	save_config()


func _exit_tree() -> void:
	if _canvas:
		_canvas_depth_node.request_deletion()
		if is_moving:
			draw_end(_canvas.current_pixel.floor())


## Make sure to always have invoked _prepare_tool() before this. This computes the coordinates to be
## drawn if it can (except for the generic brush, when it's actually drawing them)
func _get_depth_points(pos: Vector2) -> PackedVector2Array:
	var proj = ExtensionsApi.project.current_project
	if !proj.layers[proj.current_layer].can_layer_get_drawn():
		return PackedVector2Array()  # empty fallback
	match _brush.type:
		Brushes.PIXEL:
			return _compute_draw_tool_pixel(pos)
		Brushes.CIRCLE:
			return _compute_draw_tool_circle(pos, false)
		Brushes.FILLED_CIRCLE:
			return _compute_draw_tool_circle(pos, true)
		_:
			return _compute_draw_tool_brush(pos)


func _compute_draw_tool_brush(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var brush_mask := BitMap.new()
	pos = pos - (_indicator.get_size() / 2)
	brush_mask.create_from_image_alpha(_brush_image, 0.0)
	for x in brush_mask.get_size().x:
		for y in brush_mask.get_size().y:
			if !_draw_points.has(Vector2i(x, y)):
				if brush_mask.get_bitv(Vector2i(x, y)):
					result.append(pos + Vector2i(x, y))
	return result


func _on_color_interpolation_visibility_changed() -> void:
	if $ColorInterpolation.visible:
		$ColorInterpolation.visible = false


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
