extends ConfirmationDialog


var plugin_type: = "ImageEffect"

onready var voxel_art_gen: MeshInstance = $ViewportContainer/Viewport/VoxeloramaPreview/VoxelArtGen


#func _ready() -> void:
#	popup_centered()


func _on_Voxelorama_about_to_show() -> void:
	var global = get_node("/root/Global")
	if global:
		print("yes")
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
