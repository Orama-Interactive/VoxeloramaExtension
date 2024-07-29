extends BaseTool

## This script is not part of extension (it is used in union with the api)

var _brush
var _brush_size := 1
var _brush_size_dynamics := 1
var _cache_limit := 3
var _brush_interpolate := 0
var _brush_image := Image.new()
var _orignal_brush_image := Image.new()  # contains the original _brush_image, without resizing
var _brush_texture := ImageTexture.new()
var _strength := 1.0
var _picking_color := false

var _undo_data := {}
var _drawer := Drawer.new()
var _mask := PackedFloat32Array()
var _mirror_brushes := {}

var _draw_line := false
var _line_start := Vector2i.ZERO
var _line_end := Vector2i.ZERO

var _indicator := BitMap.new()
var _polylines := []
var _line_polylines := []

# Memorize some stuff when doing brush strokes
var _stroke_project: Project
var _stroke_images: Array[Image] = []
var _is_mask_size_zero := true
var _circle_tool_shortcut: Array[Vector2i]


func _prepare_tool() -> void:
	return


func get_config() -> Dictionary:
	return {}


func set_config(config: Dictionary) -> void:
	return


func update_config() -> void:
	return


func save_config():
	return


func _draw_tool(pos: Vector2) -> PackedVector2Array:
	var result: Array[Vector2i] = []
	return result


func _compute_draw_tool_pixel(pos: Vector2) -> PackedVector2Array:
	var result: Array[Vector2i] = []
	return result


func _compute_draw_tool_circle(pos: Vector2i, fill := false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	return result
