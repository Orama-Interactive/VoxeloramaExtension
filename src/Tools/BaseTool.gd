class_name BaseTool
extends VBoxContainer

## This script is not part of extension (it is used in union with the api)

var is_moving := false
var kname: String
var tool_slot = null  # Tools.Slot, can't have static typing due to cyclic errors
var cursor_text := ""
var _cursor := Vector2i(Vector2.INF)
var _stabilizer_center := Vector2.ZERO

var _draw_cache: Array[Vector2i] = []  ## For storing already drawn pixels
@warning_ignore("unused_private_class_variable")
var _for_frame := 0  ## Cache for which frame

# Only use _spacing_mode and _spacing variables (the others are set automatically)
# The _spacing_mode and _spacing values are to be CHANGED only in the tool scripts (e.g Pencil.gd)
var _spacing_mode := false  ## Enables spacing (continuous gaps between two strokes)
var _spacing := Vector2i.ZERO  ## Spacing between two strokes
var _stroke_dimensions := Vector2i.ONE  ## 2D vector containing _brush_size from Draw.gd
var _spacing_offset := Vector2i.ZERO  ## The initial error between position and position.snapped()
@onready var color_rect := $ColorRect as ColorRect


func _ready() -> void:
	pass
