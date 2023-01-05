extends Spatial

var _project_size :Vector2
var _grid_size :Vector2
var x_axis = ImmediateGeometry.new()
var y_axis = ImmediateGeometry.new()
var z_axis = ImmediateGeometry.new()
var plane_minor = ImmediateGeometry.new()
var plane_major = ImmediateGeometry.new()


func _ready():
	add_child(x_axis)
	add_child(y_axis)
	add_child(z_axis)
	add_child(plane_minor)
	add_child(plane_major)


func draw_grid_and_axes(project_size :Vector2 ,grid_size :Vector2):
	if _project_size != project_size or _grid_size != grid_size:
		draw_axes()
		# Pixel Grid (Minor)
		draw_grid(project_size, Vector2.ONE, grid_size, Color(0.380392, 0.380392, 0.380392))
		# Rectangular Grid (Major)
		draw_grid(project_size, grid_size, -Vector2.ONE, Color(0.560784, 0.560784, 0.560784), true)
		_project_size = project_size
		_grid_size = grid_size


func draw_axes():
	x_axis.clear()
	y_axis.clear()
	z_axis.clear()
	x_axis.material_override = SpatialMaterial.new()
	x_axis.material_override.albedo_color = Color(0.788235, 0.305882, 0.305882)
	y_axis.material_override = SpatialMaterial.new()
	y_axis.material_override.albedo_color = Color(0.305882, 0.788235, 0.324724)
	z_axis.material_override = SpatialMaterial.new()
	z_axis.material_override.albedo_color = Color(0.305882, 0.392157, 0.788235)
	x_axis.begin(Mesh.PRIMITIVE_LINES)
	x_axis.add_vertex(Vector3(-1000000,0,0))
	x_axis.add_vertex(Vector3(10000,0,0))
	x_axis.end()
	y_axis.begin(Mesh.PRIMITIVE_LINES)
	y_axis.add_vertex(Vector3(0,-10000,0))
	y_axis.add_vertex(Vector3(0,10000,0))
	y_axis.end()
	z_axis.begin(Mesh.PRIMITIVE_LINES)
	z_axis.add_vertex(Vector3(0,0,-10000))
	z_axis.add_vertex(Vector3(0,0,10000))
	z_axis.end()


func draw_grid(size :Vector2, step :Vector2, breaking :Vector2 , color, major := false):
	#Breaking is the amount of lines after which we should miss 1 line
	var plane = plane_minor
	if major:
		plane = plane_major
	plane.clear()
	plane.material_override = SpatialMaterial.new()
	plane.material_override.albedo_color = color

	plane.begin(Mesh.PRIMITIVE_LINES)
	var x :float = 0
	while x <= size.x:
		var i :float = x/breaking.x
		# if i is float or negative
		if "." in str(i) or "-" in str(i):
			if x == 0:
				x += step.x
				continue
#			lines parallel to Z-Axis (Blue)
			plane.add_vertex(Vector3(x, 0, -size.y))
			plane.add_vertex(Vector3(x, 0, size.y))
			plane.add_vertex(Vector3(-x, 0, -size.y))
			plane.add_vertex(Vector3(-x, 0, size.y))
		x += step.x

	var z :float = 0
	while z <= size.y:
		var i :float = z/breaking.y
		# if i is float or negative
		if "." in str(i) or "-" in str(i):
			if z == 0:
				z += step.y
				continue

#			lines parallel to X-Axis  (Red)
			plane.add_vertex(Vector3(-size.x, 0, z))
			plane.add_vertex(Vector3(size.x, 0, z))
			plane.add_vertex(Vector3(-size.x, 0, -z))
			plane.add_vertex(Vector3(size.x, 0, -z))
		z += step.y
	plane.end()


