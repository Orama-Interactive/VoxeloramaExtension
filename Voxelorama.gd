extends ConfirmationDialog


var plugin_type: = "ImageEffect"
var viewport_has_focus := false
var rotate := false
var pan := false

onready var voxel_art_gen: MeshInstance = find_node("VoxelArtGen")
onready var camera: Camera = find_node("Camera")


#func _ready() -> void:
#	popup_centered()


func _input(event: InputEvent) -> void:
	if !viewport_has_focus:
		rotate = false
		pan = false
		return

	if event.is_action_pressed("left_mouse"):
		rotate = true
	elif event.is_action_released("left_mouse"):
		rotate = false

	if event.is_action_pressed("middle_mouse"):
		pan = true
	elif event.is_action_released("middle_mouse"):
		pan = false

	if rotate and event is InputEventMouseMotion:
		voxel_art_gen.get_parent().rotation.x += event.relative.y*0.005
		voxel_art_gen.rotation.y += event.relative.x*0.005

	if pan and event is InputEventMouseMotion:
		camera.translation.x -= event.relative.x*0.1
		camera.translation.y += event.relative.y*0.1

	if event.is_action("zoom_in"):
		camera.translation.z -= 1
	elif event.is_action("zoom_out"):
		camera.translation.z += 1


func _on_Voxelorama_about_to_show() -> void:
	generate()


func generate() -> void:
	var global = get_node("/root/Global")
	if global:
		voxel_art_gen.layer_images.clear()
		var project = global.current_project
		var i := 0
		for cel in project.frames[project.current_frame].cels:
			if project.layers[i].visible:
				var image := Image.new()
				image.copy_from(cel.image)
				voxel_art_gen.layer_images.append(image)
			i += 1
	voxel_art_gen.generate_mesh()


func _on_VoxeloramaDialog_confirmed() -> void:
	voxel_art_gen.export_obj()


func _on_Voxelorama_popup_hide() -> void:
	var global = get_node("/root/Global")
	if global:
		global.dialog_open(false)


func _on_TransparentMaterials_toggled(button_pressed: bool) -> void:
	voxel_art_gen.transparent_material = button_pressed
	generate()


func _on_ViewportContainer_resized() -> void:
	$VBoxContainer/ViewportContainer/Viewport.size = $VBoxContainer/ViewportContainer.rect_size


func _on_ViewportContainer_mouse_entered() -> void:
	viewport_has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	viewport_has_focus = false
