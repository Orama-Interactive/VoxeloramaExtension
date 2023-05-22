extends Node2D

var _voxelorama_root_node: Node

var users :int = 1


func _ready() -> void:
	_voxelorama_root_node = ExtensionsApi.general.get_extensions_node().get_node("Voxelorama")
	# immediately update if another tool is drawing


func _draw() -> void:
	var project = ExtensionsApi.project.get_current_project()
	var size: Vector2 = project.size
	var cel: Reference = project.frames[project.current_frame].cels[project.current_layer]
	var image: Image = cel.image
	if !cel.has_meta("VoxelDepth"):
		return
	var depth_array: Array = cel.get_meta("VoxelDepth")

	var font: Font = ExtensionsApi.theme.get_theme().default_font
	draw_set_transform(position, rotation, Vector2(0.05, 0.05))
	image.lock()
	for x in range(size.x):
		for y in range(size.y):
			if image.get_pixel(x, y).a == 0:
				continue
			var depth_str := str(depth_array[x][y])
			draw_string(
				font, Vector2(x, y) * 20 + Vector2.DOWN * 16, depth_str, get_color(depth_array[x][y])
			)
	image.unlock()
	draw_set_transform(position, rotation, scale)


func get_color(depth: float):
	var weight = 0
	var color_a := Color.red
	var color_b := Color.white
	if depth > 0 and depth <= 5:
		weight = (depth - 1) /5.0
		color_a = Color.white
		color_b = Color.blue

	if depth > 5 and depth <= 10:
		weight = (depth - 6)/25.0
		color_a = Color.blue
		color_b = Color.green

	if depth > 10 and depth <= 15:
		weight = (depth - 11)/25.0
		color_a = Color.green
		color_b = Color.yellow

	if depth > 15 and depth <= 20:
		weight = (depth - 16)/25.0
		color_a = Color.yellow
		color_b = Color.orange

	if depth > 20 and depth <= 25:
		weight = (depth - 26)/25.0
		color_a = Color.orange
		color_b = Color.red

	# values larger than 25 onward are in red
	return color_a.linear_interpolate(color_b, weight)


func request_deletion():
	users -= 1
	if users == 0: # no one is using this node
		queue_free()
	# Else there are still active tool using this node so DENIED
