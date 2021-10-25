extends MeshInstance


var cubes := [] # Array of Cube(s)
var layer_images := [] # Array of Images

onready var camera: Camera = $"../Camera"


class Cube extends Reference:
	var start_point: = Vector2.ZERO
	var end_point: = Vector2.ONE
	var faces: = []
	var uvs: = [Vector2.ZERO, Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var uvs_right: = []
	var uvs_left: = []
	var uvs_down: = []
	var uvs_up: = []
	var depth := 1
	var z_back := 0
	var z_front := z_back + depth


	func _init(_z_back := 0, _depth := 1) -> void:
		z_back = _z_back
		depth = _depth
		z_front = z_back + depth


	func generate_faces() -> void:
		end_point += Vector2.RIGHT
		faces.append([Vector3(start_point.x, start_point.y, z_front), Vector3(end_point.x, start_point.y, z_front), Vector3(end_point.x, end_point.y, z_front), Vector3(start_point.x, end_point.y, z_front), Vector3.FORWARD])
		faces.append([Vector3(start_point.x, start_point.y, z_back), Vector3(end_point.x, start_point.y, z_back), Vector3(end_point.x, end_point.y, z_back), Vector3(start_point.x, end_point.y, z_back), Vector3.BACK])
#		faces.append([Vector3(end_point.x, end_point.y, z_front), Vector3(start_point.x, end_point.y, z_front), Vector3(start_point.x, start_point.y, z_front), Vector3(end_point.x, start_point.y, z_front), Vector3.FORWARD])
#		faces.append([Vector3(end_point.x, end_point.y, z_back), Vector3(start_point.x, end_point.y, z_back), Vector3(start_point.x, start_point.y, z_back), Vector3(end_point.x, start_point.y, z_back), Vector3.BACK])

		faces.append([Vector3(start_point.x, end_point.y, z_back), Vector3(start_point.x, end_point.y, z_front), Vector3(end_point.x, end_point.y, z_front), Vector3(end_point.x, end_point.y, z_back), Vector3.UP])
		faces.append([Vector3(start_point.x, start_point.y, z_back), Vector3(start_point.x, start_point.y, z_front), Vector3(end_point.x, start_point.y, z_front), Vector3(end_point.x, start_point.y, z_back), Vector3.DOWN])

		faces.append([Vector3(end_point.x, start_point.y, z_back), Vector3(end_point.x, start_point.y, z_front), Vector3(end_point.x, end_point.y, z_front), Vector3(end_point.x, end_point.y, z_back), Vector3.RIGHT])
		faces.append([Vector3(start_point.x, start_point.y, z_back), Vector3(start_point.x, start_point.y, z_front), Vector3(start_point.x, end_point.y, z_front), Vector3(start_point.x, end_point.y, z_back), Vector3.LEFT])


	func generate_uvs(image_size:Vector2) -> void:
		var start_x := start_point.x / image_size.x
		var start_y := start_point.y / image_size.y
		var end_x := end_point.x / image_size.x
		var end_y := end_point.y / image_size.y

		uvs[0] = Vector2(start_x, start_y)
		uvs[1] = Vector2(end_x, start_y)
		uvs[2] = Vector2(end_x, end_y)
		uvs[3] = Vector2(start_x, end_y)

		uvs_right = [Vector2(end_x, start_y), Vector2(end_x, start_y), Vector2(end_x, end_y), Vector2(end_x, end_y)]
		uvs_left = [Vector2(start_x, start_y), Vector2(start_x, start_y), Vector2(start_x, end_y), Vector2(start_x, end_y)]

		uvs_down = [Vector2(start_x, start_y), Vector2(start_x, start_y), Vector2(end_x, start_y), Vector2(end_x, start_y)]
		uvs_up = [Vector2(start_x, end_y), Vector2(start_x, end_y), Vector2(end_x, end_y), Vector2(end_x, end_y)]


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
			surface_tool.add_uv(_uvs[0]); surface_tool.add_vertex(verts[0])
			surface_tool.add_uv(_uvs[1]); surface_tool.add_vertex(verts[1])
			surface_tool.add_uv(_uvs[2]); surface_tool.add_vertex(verts[2])

			surface_tool.add_uv(_uvs[2]); surface_tool.add_vertex(verts[2])
			surface_tool.add_uv(_uvs[3]); surface_tool.add_vertex(verts[3])
			surface_tool.add_uv(_uvs[0]); surface_tool.add_vertex(verts[0])
		else:
			surface_tool.add_uv(_uvs[2]); surface_tool.add_vertex(verts[2])
			surface_tool.add_uv(_uvs[1]); surface_tool.add_vertex(verts[1])
			surface_tool.add_uv(_uvs[0]); surface_tool.add_vertex(verts[0])

			surface_tool.add_uv(_uvs[0]); surface_tool.add_vertex(verts[0])
			surface_tool.add_uv(_uvs[3]); surface_tool.add_vertex(verts[3])
			surface_tool.add_uv(_uvs[2]); surface_tool.add_vertex(verts[2])

#		var normal:= Vector3.RIGHT
#		surface_tool.add_uv(_uvs[0]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[0])
#		surface_tool.add_uv(_uvs[1]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[1])
#		surface_tool.add_uv(_uvs[2]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[2])
#
#		surface_tool.add_uv(_uvs[2]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[2])
#		surface_tool.add_uv(_uvs[3]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[3])
#		surface_tool.add_uv(_uvs[0]); surface_tool.add_normal(normal); surface_tool.add_vertex(verts[0])


func generate_mesh() -> void:
	var start: = OS.get_ticks_msec()
	var array_mesh := ArrayMesh.new()
	var i := 0
	for image in layer_images:
		image.flip_y()
		camera.translation.y = image.get_size().y / 2
		camera.translation.x = image.get_size().x / 2
		camera.translation.z = max(image.get_size().x, image.get_size().y)

		var current_cube := Cube.new(i)
		current_cube.start_point = Vector2(0, 0)
		current_cube.end_point = Vector2(0, 0)

		image.lock()
		for x in image.get_size().x:
			if current_cube.start_point == current_cube.end_point:
				current_cube = Cube.new(i)
				current_cube.start_point = Vector2(x, 0)
				current_cube.end_point = Vector2(x, 0)

			for y in image.get_size().y:
				var color: Color = image.get_pixel(x, y)
				if color.a <= 0.1:
					if current_cube.start_point != current_cube.end_point:
						cubes.append(current_cube)

					current_cube = Cube.new(i)
					current_cube.start_point = Vector2(x, y+1)
					current_cube.end_point = Vector2(x, y+1)
				else:
					current_cube.end_point = Vector2(x, y+1)

		image.unlock()
		if current_cube.start_point != current_cube.end_point and !cubes.has(current_cube):
			cubes.append(current_cube)

		for cube in cubes:
			cube.generate_faces()
			cube.generate_uvs(image.get_size())

		var st: = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for cube in cubes:
			cube.draw_cube(st)

		st.generate_normals()
#		st.index()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image, 0)
		var mat := SpatialMaterial.new()
		mat.albedo_texture = image_texture
		array_mesh.surface_set_material(i, mat)
		array_mesh.surface_set_name(i, "Layer %s" % i)
		cubes.clear()

		i += 1

	# Commit to a mesh.
	mesh = array_mesh
	var end: = OS.get_ticks_msec()
	print("Cubes: ", cubes.size())
	print("Mesh generated in ", end - start, " ms")


# Thanks to
# https://github.com/lawnjelly/GodotTweaks/blob/master/ObjExport/ObjExport.gd#L33
# and
# https://github.com/mohammedzero43/CSGExport-Godot/blob/master/addons/CSGExport/csgexport.gd#L48
func export_obj(path := "user://test") -> void:
	if !layer_images:
		return
	var start: = OS.get_ticks_msec()
#	path = "user://%s" % image_textures[0].resource_path.get_basename().get_file()
	var file_name: String = path.get_file()
	var objcont = "" #.obj content
	var matcont = "" #.mat content
	var vertices_total := 0

	objcont += "# Voxelorama\n"
#	objcont += "# Number of vertices " + str(nVerts) + "\n"
#	objcont += "# Number of faces " + str(nFaces) + "\n"

	objcont += "mtllib "+ file_name + ".mtl\n"
	objcont += "o " + file_name  + "\n"

	for s in mesh.get_surface_count():
		var mdt: = MeshDataTool.new()
		var err: = mdt.create_from_surface(mesh, s)
		if err != OK:
			printerr("Error code: %s" % err)
			return

		var nVerts = mdt.get_vertex_count()
		if nVerts == 0:
			printerr("ObjExport::export : nVerts is 0, aborting")
			return

		var nFaces = mdt.get_face_count()

		var vertcont := ""
		var uvcont := ""
		var normalcont := ""
		# positions
		for i in range (nVerts):
			var vertex: Vector3 = mdt.get_vertex(i)
			vertcont += str("v ", vertex.x, " ", vertex.y, " ", vertex.z, "\n")

			var uv: Vector2 = mdt.get_vertex_uv(i)
			uvcont += str("vt ", uv.x, " ", uv.y, "\n")

			var norm: Vector3 = mdt.get_vertex_normal(i)
			norm = norm.normalized()
			normalcont += str("vn ", norm.x, " ", norm.y, " ", norm.z, "\n")

		objcont += vertcont + uvcont + normalcont

		objcont += "g surface" + str(s) + "\n"
		var mat: = mesh.surface_get_material(s)
		objcont += "usemtl " + str(mat) + "\n"

		for f in range (nFaces):
			objcont += "f"
			for i in 3:
				# obj expects face vertices in opposite winding order to godot
				var ind: int = mdt.get_face_vertex(f, 2-i)

				# plus one based in obj file
				ind += 1
				# vertex, uv, norm
				objcont += " " + str(ind + vertices_total) + "/" + str(ind + vertices_total)

			objcont += "\n"

		vertices_total += nVerts

		matcont+=str("newmtl "+str(mat))+'\n'
		matcont+=str("Kd ",mat.albedo_color.r," ",mat.albedo_color.g," ",mat.albedo_color.b)+'\n'
		matcont+=str("Ke ",mat.emission.r," ",mat.emission.g," ",mat.emission.b)+'\n'
		matcont+=str("d ",mat.albedo_color.a)+"\n"

		# Export texture taken from https://github.com/Variable-ind/Asset-Maker/blob/master/UI/Scripts/Export.gd
		if mat.albedo_texture != null:
			var img_texture :Image = mat.albedo_texture.get_data()
			img_texture.flip_y()
			var image_filename: String = path + "_%s.png" % s
			var _error = img_texture.save_png(image_filename)
			matcont += "map_Kd " + file_name + "_%s.png\n" % s

	var fi: = File.new()
# warning-ignore:return_value_discarded
	fi.open(path + ".obj", File.WRITE)
	fi.store_string(objcont)
	fi.close()

	var mtlfile: = File.new()
# warning-ignore:return_value_discarded
	mtlfile.open(path + ".mtl", File.WRITE)
	mtlfile.store_string(matcont)
	mtlfile.close()

	#output message
	var end: = OS.get_ticks_msec()
	print("Mesh ", path, " exported in ", end - start, " ms")
