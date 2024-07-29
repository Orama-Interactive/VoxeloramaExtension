extends "res://src/Tools/BaseDraw.gd"

var _depth_slider: TextureProgressBar
var _depth_array: Array[PackedFloat32Array] = []
var _depth := 1.0
var _canvas_depth := preload("res://src/Extensions/Voxelorama/Tools/CanvasDepth.tscn")
var _canvas_depth_node: Node2D
var _canvas: Node2D
var _draw_points: Array[Vector2i] = []


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
	var config := super.get_config()
	config["depth"] = _depth
	return config


func set_config(config: Dictionary) -> void:
	super.set_config(config)
	_depth = config.get("depth", _depth)


func update_config() -> void:
	super.update_config()
	_depth_slider.value = _depth


func draw_start(pos: Vector2i) -> void:
	is_moving = true
	_depth_array = []
	var project = ExtensionsApi.project.current_project
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
	_update_array(cel, pos)


func draw_move(pos: Vector2i) -> void:
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_moving:
		draw_start(pos)
	var project = ExtensionsApi.project.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]
	_update_array(cel, pos)


func draw_end(pos: Vector2i) -> void:
	is_moving = false
	var project = ExtensionsApi.project.current_project
	var cel = project.frames[project.current_frame].cels[project.current_layer]
	_update_array(cel, pos)


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
			_depth_array[coord.x][coord.y] = _depth
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
	return PackedVector2Array()  # empty fallback


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
