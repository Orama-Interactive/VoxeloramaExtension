extends MeshInstance

var cubes := []  # Array of Cube(s)
var layer_images := []  # Array of Images
var transparent_material := false

onready var camera: Camera = $"../../Camera"


class Cube:
	var start_point := Vector2.ZERO
	var end_point := Vector2.ONE
	var faces := []
	var uvs := [Vector2.ZERO, Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var uvs_right := []
	var uvs_left := []
	var uvs_down := []
	var uvs_up := []
	var depth := 1
	var z_back := 0
	var z_front := z_back + depth

	func _init(_z_back := 0, _depth := 1) -> void:
		z_back = _z_back
		depth = _depth
		z_front = z_back + depth

	func generate_faces() -> void:
		faces.append(
			[
				Vector3(start_point.x, start_point.y, z_front),
				Vector3(end_point.x, start_point.y, z_front),
				Vector3(end_point.x, end_point.y, z_front),
				Vector3(start_point.x, end_point.y, z_front),
				Vector3.FORWARD
			]
		)
		faces.append(
			[
				Vector3(start_point.x, start_point.y, z_back),
				Vector3(end_point.x, start_point.y, z_back),
				Vector3(end_point.x, end_point.y, z_back),
				Vector3(start_point.x, end_point.y, z_back),
				Vector3.BACK
			]
		)

		faces.append(
			[
				Vector3(start_point.x, end_point.y, z_back),
				Vector3(start_point.x, end_point.y, z_front),
				Vector3(end_point.x, end_point.y, z_front),
				Vector3(end_point.x, end_point.y, z_back),
				Vector3.UP
			]
		)
		faces.append(
			[
				Vector3(start_point.x, start_point.y, z_back),
				Vector3(start_point.x, start_point.y, z_front),
				Vector3(end_point.x, start_point.y, z_front),
				Vector3(end_point.x, start_point.y, z_back),
				Vector3.DOWN
			]
		)

		faces.append(
			[
				Vector3(end_point.x, start_point.y, z_back),
				Vector3(end_point.x, start_point.y, z_front),
				Vector3(end_point.x, end_point.y, z_front),
				Vector3(end_point.x, end_point.y, z_back),
				Vector3.RIGHT
			]
		)
		faces.append(
			[
				Vector3(start_point.x, start_point.y, z_back),
				Vector3(start_point.x, start_point.y, z_front),
				Vector3(start_point.x, end_point.y, z_front),
				Vector3(start_point.x, end_point.y, z_back),
				Vector3.LEFT
			]
		)

	func generate_uvs(image_size: Vector2) -> void:
		# We add 0.5 because the vertices are offset to the center of the mesh
		var start_x := start_point.x / image_size.x + 0.5
		var start_y := start_point.y / image_size.y + 0.5
		var end_x := end_point.x / image_size.x + 0.5
		var end_y := end_point.y / image_size.y + 0.5
#
#		var start_x := (start_point.x  + (image_size.x / 2)) / image_size.x
#		var start_y := (start_point.y + (image_size.y / 2)) / image_size.y
#		var end_x := (end_point.x + (image_size.x / 2)) / image_size.x
#		var end_y := (end_point.y + (image_size.y / 2)) / image_size.y

		uvs[0] = Vector2(start_x, start_y)
		uvs[1] = Vector2(end_x, start_y)
		uvs[2] = Vector2(end_x, end_y)
		uvs[3] = Vector2(start_x, end_y)

		uvs_right = [
			Vector2(end_x, start_y),
			Vector2(end_x, start_y),
			Vector2(end_x, end_y),
			Vector2(end_x, end_y)
		]
		uvs_left = [
			Vector2(start_x, start_y),
			Vector2(start_x, start_y),
			Vector2(start_x, end_y),
			Vector2(start_x, end_y)
		]

		uvs_down = [
			Vector2(start_x, start_y),
			Vector2(start_x, start_y),
			Vector2(end_x, start_y),
			Vector2(end_x, start_y)
		]
		uvs_up = [
			Vector2(start_x, end_y),
			Vector2(start_x, end_y),
			Vector2(end_x, end_y),
			Vector2(end_x, end_y)
		]

	func draw_cube(st: SurfaceTool) -> void:
		for face in faces:
			var direction: Vector3 = face[4]
			if direction == Vector3.RIGHT:
				draw_block_face(st, face, uvs_right)
			elif direction == Vector3.LEFT:
				draw_block_face(st, face, uvs_left)
			elif direction == Vector3.DOWN:
				draw_block_face(st, face, uvs_down)
			elif direction == Vector3.UP:
				draw_block_face(st, face, uvs_up)
			else:
				draw_block_face(st, face, uvs)

	# https://github.com/godotengine/godot-demo-projects/blob/3.3-f9333dc/3d/voxel/world/chunk.gd#L171
	func draw_block_face(surface_tool: SurfaceTool, verts, _uvs):
		var direction: Vector3 = verts[4]
#		_uvs = [Vector2.ZERO, Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		if direction == Vector3.BACK or direction == Vector3.DOWN or direction == Vector3.RIGHT:
			surface_tool.add_uv(_uvs[0])
			surface_tool.add_vertex(verts[0])
			surface_tool.add_uv(_uvs[1])
			surface_tool.add_vertex(verts[1])
			surface_tool.add_uv(_uvs[2])
			surface_tool.add_vertex(verts[2])

			surface_tool.add_uv(_uvs[2])
			surface_tool.add_vertex(verts[2])
			surface_tool.add_uv(_uvs[3])
			surface_tool.add_vertex(verts[3])
			surface_tool.add_uv(_uvs[0])
			surface_tool.add_vertex(verts[0])
		else:
			surface_tool.add_uv(_uvs[2])
			surface_tool.add_vertex(verts[2])
			surface_tool.add_uv(_uvs[1])
			surface_tool.add_vertex(verts[1])
			surface_tool.add_uv(_uvs[0])
			surface_tool.add_vertex(verts[0])

			surface_tool.add_uv(_uvs[0])
			surface_tool.add_vertex(verts[0])
			surface_tool.add_uv(_uvs[3])
			surface_tool.add_vertex(verts[3])
			surface_tool.add_uv(_uvs[2])
			surface_tool.add_vertex(verts[2])


#func _ready() -> void:
#	layer_images.append(preload("icon.png").get_data())


func generate_mesh() -> void:
	var start := OS.get_ticks_msec()

	if layer_images[0]:
		camera.translation.y = layer_images[0].get_size().y / 8
		camera.translation.x = layer_images[0].get_size().x / 8
		camera.translation.z = max(layer_images[0].get_size().x, layer_images[0].get_size().y)

	var array_mesh := ArrayMesh.new()
	var i := 0
	for imag in layer_images:
		var image := Image.new()
		image.copy_from(imag)
		image.flip_y()
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image)

		var rectangles := find_rectangles_in_bitmap(bitmap)
		for rect in rectangles:
			var cube := Cube.new(i)
			cube.start_point = rect.position - (image.get_size() / 2)
			cube.end_point = rect.end - (image.get_size() / 2)
			cubes.append(cube)

		for cube in cubes:
			cube.generate_faces()
			cube.generate_uvs(image.get_size())

		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for cube in cubes:
			cube.draw_cube(st)

		st.generate_normals()
#		st.index()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image, 0)
		var mat := SpatialMaterial.new()
		mat.flags_transparent = transparent_material
		mat.albedo_texture = image_texture
		array_mesh.surface_set_material(i, mat)
		array_mesh.surface_set_name(i, "Layer %s" % i)
		cubes.clear()

		i += 1

	# Commit to a mesh.
	mesh = array_mesh
	var end := OS.get_ticks_msec()
	print("Mesh generated in ", end - start, " ms")


# Code inspired by user jo_va from https://stackoverflow.com/a/54762668
func find_rectangles_in_bitmap(bitmap: BitMap) -> Array:
	var width := bitmap.get_size().x
	var height := bitmap.get_size().y

	var rectangles := []
	while bitmap.get_true_bit_count() > 0:
		var rect := [0, 0, width - 1, height - 1]

		# Find top left corner
		var found_corner := false
		for i in width:
			for j in height:
				if bitmap.get_bit(Vector2(i, j)):
					rect[0] = i
					rect[1] = j
					found_corner = true
					break
			if found_corner:
				break

		# Find bottom right corner
		for i in range(rect[0], rect[2] + 1):
			if !bitmap.get_bit(Vector2(i, rect[1])):
				rect[2] = i - 1
				break

			for j in range(rect[1], rect[3] + 1):
				if !bitmap.get_bit(Vector2(i, j)):
					rect[3] = j - 1
					break

		# Mark rectangle so it will not be counted again
		var type_rect := Rect2()
		type_rect.position = Vector2(rect[0], rect[1])
		type_rect.end = Vector2(rect[2] + 1, rect[3] + 1)
		bitmap.set_bit_rect(type_rect, false)

		rectangles.append(type_rect)

	return rectangles


# Thanks to
# https://github.com/lawnjelly/GodotTweaks/blob/master/ObjExport/ObjExport.gd#L33
# and
# https://github.com/mohammedzero43/CSGExport-Godot/blob/master/addons/CSGExport/csgexport.gd#L48
func export_obj(path := "user://test.obj") -> void:
	if !layer_images:
		return
	var start := OS.get_ticks_msec()
	var path_no_ext := path.get_basename()
	var file_name: String = path_no_ext.get_file()
	var objcont = ""  #.obj content
	var matcont = ""  #.mat content
	var vertices_total := 0

	objcont += "# Exported from Pixelorama with the Voxelorama plugin, by Orama Interactive\n"
# warning-ignore:integer_division
	objcont += "# Number of triangles: " + str(mesh.get_faces().size() / 3) + "\n"

	objcont += "mtllib " + file_name + ".mtl\n"
	objcont += "o " + file_name + "\n"

	for s in mesh.get_surface_count():
		var mdt := MeshDataTool.new()
		var err := mdt.create_from_surface(mesh, s)
		if err != OK:
			printerr("Error code: %s" % err)
			return

		var n_verts = mdt.get_vertex_count()
		if n_verts == 0:
			printerr("ObjExport::export : n_verts is 0, aborting")
			return

		var n_faces = mdt.get_face_count()

		var vertcont := ""
		var uvcont := ""
		var normalcont := ""
		# positions
		for i in range(n_verts):
			var vertex: Vector3 = mdt.get_vertex(i)
			# str("%.6f" % ) is needed to add extra zeroes in the obj file
			vertcont += str(
				"v ",
				str("%.6f" % vertex.x),
				" ",
				str("%.6f" % vertex.y),
				" ",
				str("%.6f" % vertex.z),
				"\n"
			)

			var uv: Vector2 = mdt.get_vertex_uv(i)
			uvcont += str("vt ", str("%.6f" % uv.x), " ", str("%.6f" % uv.y), "\n")

			var norm: Vector3 = mdt.get_vertex_normal(i)
			norm = norm.normalized()
			normalcont += str(
				"vn ",
				str("%.4f" % norm.x),
				" ",
				str("%.4f" % norm.y),
				" ",
				str("%.4f" % norm.z),
				"\n"
			)

		objcont += vertcont + uvcont + normalcont

		objcont += "g surface" + str(s) + "\n"
		var mat := mesh.surface_get_material(s)
		objcont += "usemtl " + str(mat) + "\n"

		for f in range(n_faces):
			objcont += "f"
			for i in 3:
				# obj expects face vertices in opposite winding order to godot
				var ind: int = mdt.get_face_vertex(f, 2 - i)

				# plus one based in obj file
				ind += 1
				# vertex, uv, norm
				objcont += " " + str(ind + vertices_total) + "/" + str(ind + vertices_total)

			objcont += "\n"

		vertices_total += n_verts

		matcont += str("newmtl " + str(mat)) + "\n"
		matcont += (
			str("Kd ", mat.albedo_color.r, " ", mat.albedo_color.g, " ", mat.albedo_color.b)
			+ "\n"
		)
		matcont += str("Ke ", mat.emission.r, " ", mat.emission.g, " ", mat.emission.b) + "\n"
		matcont += str("d ", mat.albedo_color.a) + "\n"

		# Export texture taken from
		# https://github.com/Variable-ind/Asset-Maker/blob/master/UI/Scripts/Export.gd
		if mat.albedo_texture != null:
			var img_texture: Image = mat.albedo_texture.get_data()
			img_texture.flip_y()
			var image_filename: String = path_no_ext + "_%s.png" % s
			var error_texture = img_texture.save_png(image_filename)
			if error_texture != OK:
				print(error_texture)
			matcont += "map_Kd " + file_name + "_%s.png\n" % s

	var fi := File.new()
# warning-ignore:return_value_discarded
	fi.open(path, File.WRITE)
	fi.store_string(objcont)
	fi.close()

	var mtlfile := File.new()
# warning-ignore:return_value_discarded
	mtlfile.open(path_no_ext + ".mtl", File.WRITE)
	mtlfile.store_string(matcont)
	mtlfile.close()

	#output message
	var end := OS.get_ticks_msec()
	print("Mesh ", path, " exported in ", end - start, " ms")
