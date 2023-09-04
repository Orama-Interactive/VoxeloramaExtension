extends AcceptDialog

var centered := true
var symmetrical := false
var merge_frames := false
var viewport_has_focus := false
var rotate := false
var pan := false
var menu_item_id: int
var depth_tool_scene := "res://src/Extensions/Voxelorama/Tools/Depth.tscn"
var unshaded_env := preload("res://assets/environments/unshaded.tres")
var shaded_env := preload("res://assets/environments/shaded.tres")
var voxel_art_gen_script := preload("res://src/Extensions/Voxelorama/VoxelArtGen.gd")

## Only when used as a Pixelorama extension
var menu_item_index: int

@onready var voxel_art_gen: MeshInstance3D = find_child("VoxelArtGen")
@onready var camera: Camera3D = find_child("Camera3D")
@onready var file_dialog: FileDialog = find_child("FileDialog")


func _enter_tree() -> void:
	menu_item_index = ExtensionsApi.menu.add_menu_item(ExtensionsApi.menu.IMAGE, "Voxelorama", self)
	ExtensionsApi.tools.add_tool("Depth", "Depth", "depth", depth_tool_scene)


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
		voxel_art_gen.get_parent().rotation.x += event.relative.y * 0.005
		voxel_art_gen.rotation.y += event.relative.x * 0.005

	if pan and event is InputEventMouseMotion:
		camera.position.x -= event.relative.x * 0.1
		camera.position.y += event.relative.y * 0.1

	if event.is_action("zoom_in"):
		camera.position.z -= 1
	elif event.is_action("zoom_out"):
		camera.position.z += 1


func _exit_tree() -> void:
	ExtensionsApi.menu.remove_menu_item(ExtensionsApi.menu.IMAGE, menu_item_index)
	ExtensionsApi.tools.remove_tool("Depth")


func menu_item_clicked() -> void:
	popup_centered()
	ExtensionsApi.dialog.dialog_open(true)


func _on_Voxelorama_about_to_show():
	initiate_generation()


func initiate_generation():
	generate()
	if voxel_art_gen.layer_images.size() == 0:
		return
	var first_layer: Image = voxel_art_gen.layer_images[0].image
	if first_layer:
		camera.position.y = first_layer.get_size().y / 8
		camera.position.x = first_layer.get_size().x / 8
		camera.position.z = max(first_layer.get_size().x, first_layer.get_size().y)

	var project = ExtensionsApi.project.get_current_project()
	var global = ExtensionsApi.general.get_global()
	voxel_art_gen.get_child(0).draw_grid_and_axes(
		project.size * voxel_art_gen.mesh_scale, global.grid_size
	)


func generate() -> void:
	voxel_art_gen.layer_images.clear()
	var project = ExtensionsApi.project.get_current_project()
	var i := 0
	for cel in project.frames[project.current_frame].cels:
		if project.layers[i].visible:
			var image: Image = cel.image
			var depth_data := []
			if merge_frames:
				image = Image.new()
				for j in project.frames.size():
					var frame_image := Image.new()
					var cel2: RefCounted = project.frames[j].cels[i]
					frame_image.copy_from(cel2.image)
					if j == 0:
						image = frame_image
					else:
						image.blend_rect(
							frame_image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO
						)
					if cel2.has_meta("VoxelDepth"):
						depth_data = cel2.get_meta("VoxelDepth")
			else:
				if cel.has_meta("VoxelDepth"):
					depth_data = cel.get_meta("VoxelDepth")
			var depth_image = voxel_art_gen_script.DepthImage.new(image, depth_data)
			voxel_art_gen.layer_images.append(depth_image)
		i += 1
	voxel_art_gen.generate_mesh($"%Status", centered, symmetrical)


func _on_Voxelorama_popup_hide() -> void:
	ExtensionsApi.dialog.dialog_open(false)


func _on_TransparentMaterials_toggled(button_pressed: bool) -> void:
	voxel_art_gen.transparent_material = button_pressed


func _on_ViewportContainer_mouse_entered() -> void:
	viewport_has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	viewport_has_focus = false


func _on_Scale_value_changed(value: float) -> void:
	voxel_art_gen.mesh_scale = value
	$"%ScaleSlider".value = value
	$"%ScaleSpinBox".value = value


func _on_FileDialog_file_selected(path: String) -> void:
	var file_extension := path.get_extension().to_lower()
	if file_extension == "svg":
		voxel_art_gen.export_svg(path)
	else:
		voxel_art_gen.export_obj($"%Status", path)


func _on_Symmetrical_toggled(button_pressed: bool) -> void:
	symmetrical = button_pressed


func _on_Centered_toggled(button_pressed: bool) -> void:
	centered = button_pressed


func _on_MergeFrames_toggled(button_pressed: bool) -> void:
	merge_frames = button_pressed


func _on_ShadedPreview_toggled(button_pressed: bool) -> void:
	if button_pressed:
		camera.environment = shaded_env
	else:
		camera.environment = unshaded_env


func _on_GenerateButton_pressed() -> void:
	initiate_generation()


func _on_ExportButton_pressed() -> void:
	file_dialog.popup_centered()
