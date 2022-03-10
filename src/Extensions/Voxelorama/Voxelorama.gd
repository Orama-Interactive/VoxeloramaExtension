extends AcceptDialog

var centered := true
var symmetrical := false
var viewport_has_focus := false
var rotate := false
var pan := false
var menu_item_id: int
var depth_per_image := {}

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
				voxel_art_gen.layer_images.append(cel.image)
			i += 1
	voxel_art_gen.generate_mesh(centered, symmetrical, depth_per_image)


func _on_Voxelorama_about_to_show() -> void:
	generate()
	var first_layer = voxel_art_gen.layer_images[0]
	if first_layer:
		camera.translation.y = first_layer.get_size().y / 8
		camera.translation.x = first_layer.get_size().x / 8
		camera.translation.z = max(first_layer.get_size().x, first_layer.get_size().y)


func _on_Voxelorama_popup_hide() -> void:
	if global:
		global.dialog_open(false)


func _on_TransparentMaterials_toggled(button_pressed: bool) -> void:
	voxel_art_gen.transparent_material = button_pressed
	generate()


func _on_ViewportContainer_mouse_entered() -> void:
	viewport_has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	viewport_has_focus = false


func _on_SaveButton_pressed() -> void:
	file_dialog.popup_centered()


func _on_FileDialog_file_selected(path: String) -> void:
	var file_extension := path.get_extension().to_lower()
	if file_extension == "svg":
		voxel_art_gen.export_svg(path)
	else:
		voxel_art_gen.export_obj(path)


func _on_Symmetrical_toggled(button_pressed: bool) -> void:
	symmetrical = button_pressed
	generate()


func _on_Centered_toggled(button_pressed: bool) -> void:
	centered = button_pressed
	generate()
