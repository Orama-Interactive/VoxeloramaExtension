extends AcceptDialog

var centered := true
var symmetrical := false
var merge_frames := false
var viewport_has_focus := false
var rotate := false
var pan := false
var menu_item_id: int
var depth_per_image := {}
var unshaded_env: Environment = preload("res://assets/environments/unshaded.tres")
var shaded_env: Environment = preload("res://assets/environments/shaded.tres")

# Only when used as a Pixelorama plugin
var global
var tools
var depth_tool

onready var voxel_art_gen: MeshInstance = find_node("VoxelArtGen")
onready var camera: Camera = find_node("Camera")
onready var file_dialog: FileDialog = find_node("FileDialog")


func _enter_tree() -> void:
	global = get_node("/root/Global")
	if global:
		var image_menu: PopupMenu = global.top_menu_container.find_node("ImageMenu").get_popup()
		menu_item_id = image_menu.get_item_count() - 1
		image_menu.add_item("Voxelorama", menu_item_id)
		image_menu.set_item_metadata(menu_item_id, self)

		# Add tool
		tools = get_node("/root/Tools")
		depth_tool = tools.Tool.new(
			"Depth", "Depth", "depth", preload("res://src/Extensions/Voxelorama/Tools/Depth.tscn")
		)
		tools.tools["Depth"] = depth_tool
		tools.add_tool_button(depth_tool)


func _ready() -> void:
	if !global:
		popup_centered()


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
		camera.translation.x -= event.relative.x * 0.1
		camera.translation.y += event.relative.y * 0.1

	if event.is_action("zoom_in"):
		camera.translation.z -= 1
	elif event.is_action("zoom_out"):
		camera.translation.z += 1


func _exit_tree() -> void:
	if global:
		var image_menu: PopupMenu = global.top_menu_container.image_menu_button.get_popup()
		var idx: int = image_menu.get_item_index(menu_item_id)
		image_menu.remove_item(idx)

		tools.remove_tool(depth_tool)


func menu_item_clicked() -> void:
	popup_centered()
	if global:
		global.dialog_open(true)


func generate() -> void:
	if global:
		voxel_art_gen.layer_images.clear()
		var project = global.current_project
		var i := 0
		for cel in project.frames[project.current_frame].cels:
			if project.layers[i].visible:
				var image: Image = cel.image
				if merge_frames:
					image = Image.new()
					image.copy_from(cel.image)
					for j in project.frames.size():
						var frame_image := Image.new()
						frame_image.copy_from(project.frames[j].cels[i].image)
						if j == 0:
							image = frame_image
						else:
							image.blend_rect(
								frame_image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO
							)
				voxel_art_gen.layer_images.append(image)
			i += 1
	else:
		var im: Texture = preload("res://assets/graphics/tools/depth.png")
		voxel_art_gen.layer_images = [im.get_data()]
	voxel_art_gen.generate_mesh(centered, symmetrical, depth_per_image)


func _on_Voxelorama_about_to_show() -> void:
	pass


func _on_Voxelorama_popup_hide() -> void:
	if global:
		global.dialog_open(false)


func _on_TransparentMaterials_toggled(button_pressed: bool) -> void:
	voxel_art_gen.transparent_material = button_pressed


func _on_ViewportContainer_mouse_entered() -> void:
	viewport_has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	viewport_has_focus = false


func _on_Scale_value_changed(value: float) -> void:
	voxel_art_gen.mesh_scale = value
	$VBoxContainer/ScaleHBox/ScaleSlider.value = value
	$VBoxContainer/ScaleHBox/ScaleSpinBox.value = value


func _on_FileDialog_file_selected(path: String) -> void:
	var file_extension := path.get_extension().to_lower()
	if file_extension == "svg":
		voxel_art_gen.export_svg(path)
	else:
		voxel_art_gen.export_obj(path)


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
	generate()
	var first_layer: Image = voxel_art_gen.layer_images[0]
	if first_layer:
		camera.translation.y = first_layer.get_size().y / 8
		camera.translation.x = first_layer.get_size().x / 8
		camera.translation.z = max(first_layer.get_size().x, first_layer.get_size().y)


func _on_ExportButton_pressed() -> void:
	file_dialog.popup_centered()
