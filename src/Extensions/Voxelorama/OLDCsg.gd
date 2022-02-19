extends Spatial

var image_tex

#onready var voxel_parent: Spatial = $VoxelParent
onready var csg_combiner: CSGCombiner = $CSGCombiner
onready var camera: Camera = $Camera

#func _ready() -> void:
#	var image: Image = image_tex.get_data()
#	camera.translation.y = max(image.get_size().x, image.get_size().y)
#	camera.translation.x = image.get_size().x / 2
#	camera.translation.z = image.get_size().y / 2
#
#	var mat := SpatialMaterial.new()
#	mat.flags_transparent = true
#	mat.albedo_texture = image_tex
#	var csg_box := CSGBox.new()
#
#	csg_box.width = image.get_size().x
#	csg_box.depth = 1
#	csg_box.height = image.get_size().y
#	csg_box.translation.x = csg_box.width / 2
#	csg_box.translation.y = csg_box.height / 2
#	csg_box.material = mat
#	csg_combiner.add_child(csg_box)


func _generate_mesh() -> void:
	var start := OS.get_ticks_msec()
	var image: Image = image_tex.get_data()
	camera.translation.y = max(image.get_size().x, image.get_size().y)
	camera.translation.x = image.get_size().x / 2
	camera.translation.z = image.get_size().y / 2

	var dict := {}
	image.lock()
	for x in image.get_size().x:
		var prev_color = Color(0)
		var big_width := 1
		var y_start := 1
		for y in image.get_size().y:
			var color: Color = image.get_pixel(x, y)
			if color.a <= 0.01:
				continue

			if !dict.has(color):
				var material := SpatialMaterial.new()
				material.flags_transparent = true
				material.albedo_color = color
				dict[color] = material

			if color.is_equal_approx(prev_color):
				big_width += 1
				if y < image.get_size().y - 1:
					continue
			else:
				print(x, " ", y)
				if dict.has(prev_color) and big_width > 1:
					var csg_box := CSGBox.new()
					csg_box.width = 1
					csg_box.height = 1
					csg_box.depth = big_width
					csg_box.material = dict[prev_color]

					csg_box.translation.x = x + csg_box.width / 2
					csg_box.translation.z = y_start + csg_box.height / 2
					csg_combiner.add_child(csg_box)

				big_width = 1
				prev_color = color
				y_start = y

			var csg_box := CSGBox.new()
			csg_box.width = 1
			csg_box.height = 1
			csg_box.depth = big_width
			csg_box.material = dict[color]

			csg_box.translation.x = x + csg_box.width / 2
			csg_box.translation.z = y_start + csg_box.height / 2
			csg_combiner.add_child(csg_box)

#			var color : Color = image.get_pixel(x, y)
#			var material: = SpatialMaterial.new()
#			material.flags_transparent = true
#			material.albedo_color = color
#			var cube: MeshInstance = cube_scene.instance()
#			cube.translation.x = x
#			cube.translation.z = y
#			cube.set_surface_material(0, material)
#			voxel_parent.add_child(cube)
	image.unlock()

	var end := OS.get_ticks_msec()
	print("CSG Generated in ", end - start, " ms")
	yield(get_tree(), "idle_frame")


#	save_obj_file()


func save_obj_file() -> void:
	var start := OS.get_ticks_msec()
	# Variables
	var path: String = "user://%s" % image_tex.resource_path.get_basename().get_file()
	var objcont = ""  #.obj content
	var matcont = ""  #.mat content
	var vertcount = 0
	var csg_mesh = csg_combiner.get_meshes()

	# OBJ Headers
	objcont += "mtllib " + path.get_file() + ".mtl\n"
	objcont += "o ./" + path.get_file() + "\n"

	# Blank material
#	var blank_material = SpatialMaterial.new()
#	blank_material.resource_name = "BlankMaterial"
	#Get surfaces and mesh info
#	for t in range(voxel_parent.get_child_count()):
	for t in range(csg_mesh[-1].get_surface_count()):
#		var voxel_instance: MeshInstance = voxel_parent.get_child(t)
#		var mat : SpatialMaterial = voxel_instance.get_surface_material(0)
		var mat: SpatialMaterial = csg_mesh[-1].surface_get_material(t)
#		if (mat == null):
#			print("e")
#			mat = blank_material
#		var voxel_mesh: Mesh = voxel_parent.get_child(t).mesh
#		var surface = voxel_mesh.surface_get_arrays(0)
		var surface = csg_mesh[-1].surface_get_arrays(t)
		var verts = surface[0]
		var uvs = surface[4]
		var normals = surface[1]

		var faces = []

		#create_faces_from_verts (Triangles)
		var tempv = 0
		for v in range(verts.size()):
			if tempv % 3 == 0:
				faces.append([])
			faces[-1].append(v + 1)
			tempv += 1
			tempv = tempv % 3

		#add verticies
		var tempvcount = 0
		for ver in verts:
			objcont += str("v ", ver[0], " ", ver[1], " ", ver[2]) + "\n"
			tempvcount += 1

		#add uvs
		for uv in uvs:
			objcont += str("vt ", uv[0], " ", uv[1]) + "\n"
		for norm in normals:
			objcont += str("vn ", norm[0], " ", norm[1], " ", norm[2]) + "\n"

		#add groups and materials
		objcont += "g surface" + str(t) + "\n"

		objcont += "usemtl " + str(mat) + "\n"

		#add faces
		for face in faces:
			objcont += (
				str(
					"f ",
					face[2] + vertcount,
					"/",
					face[2] + vertcount,
					"/",
					face[2] + vertcount,
					" ",
					face[1] + vertcount,
					"/",
					face[1] + vertcount,
					"/",
					face[1] + vertcount,
					" ",
					face[0] + vertcount,
					"/",
					face[0] + vertcount,
					"/",
					face[0] + vertcount
				)
				+ "\n"
			)
		#update verts
		vertcount += tempvcount

		matcont += str("newmtl " + str(mat)) + "\n"
		matcont += (
			str("Kd ", mat.albedo_color.r, " ", mat.albedo_color.g, " ", mat.albedo_color.b)
			+ "\n"
		)
		matcont += str("Ke ", mat.emission.r, " ", mat.emission.g, " ", mat.emission.b) + "\n"
		matcont += str("d ", mat.albedo_color.a) + "\n"

	#Write to files
	var objfile = File.new()
	objfile.open(path + ".obj", File.WRITE)
	objfile.store_string(objcont)
	objfile.close()

	var mtlfile = File.new()
	mtlfile.open(path + ".mtl", File.WRITE)
	mtlfile.store_string(matcont)
	mtlfile.close()

	#output message
	var end := OS.get_ticks_msec()
	print("CSG mesh ", path, " exported in ", end - start, " ms")

#var color : Color = image.get_pixel(x, y)
#			var csg_box := CSGBox.new()
#			csg_box.width = 1
#			csg_box.height = 1
#			csg_box.depth = 1
#			csg_box.material = SpatialMaterial.new()
#			csg_box.material.flags_transparent = true
#			csg_box.material.albedo_color = color
#			csg_box.translation.x = x
#			csg_box.translation.z = y
#			add_child(csg_box)
