extends Node2D

var _voxelorama_root_node: Node
onready var global = get_node("/root/Global")  # Only when used as a Pixelorama plugin


func _ready() -> void:
	if global:
		_voxelorama_root_node = global.control.get_node("Extensions/Voxelorama")


func _draw() -> void:
	if !global:
		return

	var target_rect: Rect2 = global.current_project.get_tile_mode_rect()
	if target_rect.has_no_area():
		return

	var project = global.current_project
	var image: Image = project.frames[project.current_frame].cels[project.current_layer].image
	if !_voxelorama_root_node.depth_per_image.has(image):
		return
	var depth_array: Array = _voxelorama_root_node.depth_per_image[image]

	image.lock()
	for x in range(floor(target_rect.position.x), floor(target_rect.end.x)):
		for y in range(floor(target_rect.position.y), floor(target_rect.end.y)):
			if image.get_pixel(x, y).a == 0:
				continue
			var rect := Rect2(Vector2(x, y), Vector2.ONE)
			var color_value = (depth_array[x][y] - 1) / 25.0
			draw_rect(rect, Color(color_value, 0, 0, 0.5))
	image.unlock()
