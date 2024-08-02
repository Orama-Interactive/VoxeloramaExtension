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
var scale_slider: TextureProgressBar

## Only when used as a Pixelorama extension
var menu_item_index: int

@onready var voxel_art_gen: MeshInstance3D = find_child("VoxelArtGen")
@onready var camera: Camera3D = voxel_art_gen.camera
@onready var file_dialog: FileDialog = find_child("FileDialog")


func _enter_tree() -> void:
	menu_item_index = ExtensionsApi.menu.add_menu_item(ExtensionsApi.menu.IMAGE, "Voxelorama", self)
	ExtensionsApi.tools.add_tool("Depth", "Depth", depth_tool_scene)


func _ready() -> void:
	$FileDialog.use_native_dialog = ExtensionsApi.general.get_global().use_native_file_dialogs
	scale_slider = ExtensionsApi.general.create_value_slider()
	scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_slider.custom_minimum_size.y = 24
	scale_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	scale_slider.value_changed.connect(_on_scale_value_changed)
	scale_slider.min_value = 0.1
	scale_slider.max_value = 10
	scale_slider.step = 0.1
	scale_slider.allow_greater = true
	scale_slider.value = 1
	%ScaleHBox.add_child(scale_slider)


## This method is located here because it is the only place that doesn't get removed when we
## change tools.
func update_undo_redo_canvas():
	var _canvas = ExtensionsApi.general.get_canvas()
	for child in _canvas.get_children():
		if child.is_in_group("CanvasDepth"):
			child.queue_redraw()


func _input(event: InputEvent) -> void:
	if !viewport_has_focus:
		rotate = false
		pan = false
		return

	if event.is_action_pressed("left_mouse"):
		rotate = true
	elif event.is_action_released("left_mouse"):
		rotate = false

	## pan is an action located in pixelorama's inputmap.
	if event.is_action_pressed("middle_mouse") or event.is_action_pressed("pan"):
		pan = true
	elif event.is_action_released("middle_mouse") or event.is_action_released("pan"):
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


func initiate_generation() -> void:
	generate()
	if voxel_art_gen.layer_images.size() == 0:
		return
	var first_layer: Image = voxel_art_gen.layer_images[0].image
	if first_layer:
		camera.position.y = first_layer.get_size().y / 8.0
		camera.position.x = first_layer.get_size().x / 8.0
		camera.position.z = maxf(first_layer.get_size().x, first_layer.get_size().y)

	var project = ExtensionsApi.project.current_project
	var global = ExtensionsApi.general.get_global()
	voxel_art_gen.get_child(0).draw_grid_and_axes(
		project.size * voxel_art_gen.mesh_scale, global.grid_size
	)


func generate() -> void:
	voxel_art_gen.layer_images.clear()
	var project = ExtensionsApi.project.current_project
	var i := 0
	for cel in project.frames[project.current_frame].cels:
		if project.layers[i].visible:
			var image: Image = cel.image
			var depth_data: Array[PackedFloat32Array] = []
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
						depth_data = Array(
							cel.get_meta("VoxelDepth"), TYPE_PACKED_FLOAT32_ARRAY, "", null
						)
			else:
				if cel.has_meta("VoxelDepth"):
					depth_data = Array(
						cel.get_meta("VoxelDepth"), TYPE_PACKED_FLOAT32_ARRAY, "", null
					)
			var depth_image = voxel_art_gen_script.DepthImage.new(image, depth_data)
			voxel_art_gen.layer_images.append(depth_image)
		i += 1
	voxel_art_gen.generate_mesh($"%Status", centered, symmetrical)


func _on_visibility_changed() -> void:
	if not visible:
		ExtensionsApi.dialog.dialog_open(false)


func _on_TransparentMaterials_toggled(button_pressed: bool) -> void:
	voxel_art_gen.transparent_material = button_pressed


func _on_ViewportContainer_mouse_entered() -> void:
	viewport_has_focus = true


func _on_ViewportContainer_mouse_exited() -> void:
	viewport_has_focus = false


func _on_scale_value_changed(value: float) -> void:
	voxel_art_gen.mesh_scale = value


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
