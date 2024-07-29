class_name Brushes
extends Popup

signal brush_selected(brush)
signal brush_removed(brush)
enum { PIXEL, CIRCLE, FILLED_CIRCLE, FILE, RANDOM_FILE, CUSTOM }

var pixel_image
var circle_image
var circle_filled_image


class Brush:
	var type: int
	var image: Image
	var random := []
	var index: int
