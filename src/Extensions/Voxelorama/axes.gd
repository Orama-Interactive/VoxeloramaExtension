extends Spatial


func _ready():
	draw_axes()
	draw_grid(100, 10, -1,self, Color(0.560784, 0.560784, 0.560784))
	draw_grid(100, 1, 10,self, Color(0.380392, 0.380392, 0.380392))


func draw_axes():
	var x_axis = ImmediateGeometry.new()
	var y_axis = ImmediateGeometry.new()
	var z_axis = ImmediateGeometry.new()
	x_axis.material_override = SpatialMaterial.new()
	x_axis.material_override.albedo_color = Color(0.788235, 0.305882, 0.305882)
	y_axis.material_override = SpatialMaterial.new()
	y_axis.material_override.albedo_color = Color(0.305882, 0.788235, 0.324724)
	z_axis.material_override = SpatialMaterial.new()
	z_axis.material_override.albedo_color = Color(0.305882, 0.392157, 0.788235)
	add_child(x_axis)
	add_child(y_axis)
	add_child(z_axis)
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


func draw_grid(size, step, breaking :float , parent,color):
	var plane = ImmediateGeometry.new()
	parent.add_child(plane)
	plane.material_override = SpatialMaterial.new()
	plane.material_override.albedo_color = color

	plane.begin(Mesh.PRIMITIVE_LINES)
	var x :float = 0
	while x < size + 1:
		var i :float = x/breaking
		# if i is float or negative
		if "." in str(i) or "-" in str(i):
			plane.add_vertex(Vector3(x-(size/2),0,-(size/2)))
			plane.add_vertex(Vector3(x-(size/2),0,size/2))
			plane.add_vertex(Vector3(-(size/2),0,x-(size/2)))
			plane.add_vertex(Vector3(size/2,0,x-(size/2)))
		x += step
	plane.end()
