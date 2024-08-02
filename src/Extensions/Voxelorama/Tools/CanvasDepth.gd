extends Node2D

var users := 1
var _voxelorama_root_node: Node


func _ready() -> void:
	_voxelorama_root_node = ExtensionsApi.general.get_extensions_node().get_node("Voxelorama")
	# immediately update if another tool is drawing


func _draw() -> void:
	var project = ExtensionsApi.project.current_project
	var size: Vector2i = project.size
	var cel: RefCounted = project.frames[project.current_frame].cels[project.current_layer]
	var image: Image = cel.image
	if !cel.has_meta("VoxelDepth"):
		return
	var depth_array: Array[PackedFloat32Array] = Array(
		cel.get_meta("VoxelDepth"), TYPE_PACKED_FLOAT32_ARRAY, "", null
	)

	var font: Font = ExtensionsApi.theme.get_theme().default_font
	draw_set_transform(position, rotation, Vector2(0.05, 0.05))
	for x in range(size.x):
		for y in range(size.y):
			if image.get_pixel(x, y).a == 0:
				continue
			var depth_str := str(depth_array[x][y])
			draw_string(
				font,
				Vector2(x, y) * 20 + Vector2.DOWN * 16,
				depth_str,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				16,
				get_color(depth_array[x][y])
			)
	draw_set_transform(position, rotation, scale)


func get_color(depth: float) -> Color:
	var weight := 0
	var color_a := Color.RED
	var color_b := Color.WHITE
	if depth > 0 and depth <= 5:
		weight = (depth - 1) / 5.0
		color_a = Color.WHITE
		color_b = Color.BLUE

	if depth > 5 and depth <= 10:
		weight = (depth - 6) / 25.0
		color_a = Color.BLUE
		color_b = Color.GREEN

	if depth > 10 and depth <= 15:
		weight = (depth - 11) / 25.0
		color_a = Color.GREEN
		color_b = Color.YELLOW

	if depth > 15 and depth <= 20:
		weight = (depth - 16) / 25.0
		color_a = Color.YELLOW
		color_b = Color.ORANGE

	if depth > 20 and depth <= 25:
		weight = (depth - 26) / 25.0
		color_a = Color.ORANGE
		color_b = Color.RED

	# values larger than 25 onward are in red
	return color_a.lerp(color_b, weight)


func request_deletion() -> void:
	users -= 1
	if users == 0:  # no one is using this node
		queue_free()
	# Else there are still active tool using this node so DENIED
