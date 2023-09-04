extends Node3D

var x_axis := MeshInstance3D.new()
var y_axis := MeshInstance3D.new()
var z_axis := MeshInstance3D.new()
var plane_minor := MeshInstance3D.new()
var plane_major := MeshInstance3D.new()

var _project_size: Vector2
var _grid_size: Vector2


func _ready():
	x_axis.mesh = ImmediateMesh.new()
	y_axis.mesh = ImmediateMesh.new()
	z_axis.mesh = ImmediateMesh.new()
	plane_minor.mesh = ImmediateMesh.new()
	plane_major.mesh = ImmediateMesh.new()
	add_child(x_axis)
	add_child(y_axis)
	add_child(z_axis)
	add_child(plane_minor)
	add_child(plane_major)


func draw_grid_and_axes(project_size: Vector2, grid_size: Vector2):
	if _project_size != project_size or _grid_size != grid_size:
		draw_axes()
		# Pixel Grid (Minor)
		draw_grid(project_size, Vector2.ONE, grid_size, Color(0.380392, 0.380392, 0.380392))
		# Rectangular Grid (Major)
		draw_grid(project_size, grid_size, -Vector2.ONE, Color(0.560784, 0.560784, 0.560784), true)
		_project_size = project_size
		_grid_size = grid_size


func draw_axes():
	x_axis.mesh.clear_surfaces()
	y_axis.mesh.clear_surfaces()
	z_axis.mesh.clear_surfaces()
	x_axis.material_override = StandardMaterial3D.new()
	x_axis.material_override.albedo_color = Color(0.788235, 0.305882, 0.305882)
	y_axis.material_override = StandardMaterial3D.new()
	y_axis.material_override.albedo_color = Color(0.305882, 0.788235, 0.324724)
	z_axis.material_override = StandardMaterial3D.new()
	z_axis.material_override.albedo_color = Color(0.305882, 0.392157, 0.788235)
	x_axis.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	x_axis.mesh.surface_add_vertex(Vector3(-1000000, 0, 0))
	x_axis.mesh.surface_add_vertex(Vector3(10000, 0, 0))
	x_axis.mesh.surface_end()
	y_axis.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	y_axis.mesh.surface_add_vertex(Vector3(0, -10000, 0))
	y_axis.mesh.surface_add_vertex(Vector3(0, 10000, 0))
	y_axis.mesh.surface_end()
	z_axis.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	z_axis.mesh.surface_add_vertex(Vector3(0, 0, -10000))
	z_axis.mesh.surface_add_vertex(Vector3(0, 0, 10000))
	z_axis.mesh.surface_end()


func draw_grid(size: Vector2, step: Vector2, breaking: Vector2, color, major := false):
	# Breaking is the amount of lines after which we should miss 1 line
	var plane := plane_minor
	if major:
		plane = plane_major
	plane.mesh.clear_surfaces()
	plane.material_override = StandardMaterial3D.new()
	plane.material_override.albedo_color = color

	plane.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var x := 0.0
	while x <= size.x:
		var i: float = x / breaking.x
		# if i is float or negative
		if "." in str(i) or "-" in str(i):
			if x == 0:
				x += step.x
				continue
			# Lines parallel to Z-Axis (Blue)
			plane.mesh.surface_add_vertex(Vector3(x, 0, -size.y))
			plane.mesh.surface_add_vertex(Vector3(x, 0, size.y))
			plane.mesh.surface_add_vertex(Vector3(-x, 0, -size.y))
			plane.mesh.surface_add_vertex(Vector3(-x, 0, size.y))
		x += step.x

	var z := 0.0
	while z <= size.y:
		var i := z / breaking.y
		# if i is float or negative
		if "." in str(i) or "-" in str(i):
			if z == 0:
				z += step.y
				continue

			# Lines parallel to X-Axis  (Red)
			plane.mesh.surface_add_vertex(Vector3(-size.x, 0, z))
			plane.mesh.surface_add_vertex(Vector3(size.x, 0, z))
			plane.mesh.surface_add_vertex(Vector3(-size.x, 0, -z))
			plane.mesh.surface_add_vertex(Vector3(size.x, 0, -z))
		z += step.y
	plane.mesh.surface_end()
