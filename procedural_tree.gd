extends Node2D

# tree parameters
var max_layers = 2
var trunc_range = [ [ 0, 0 ], [ 50, 100 ] ]
var trunc_angle_range = [ -5, 5 ]
var branch_start_range = [ 0.2, 1.0 ]
var branch_angle_range = [ 20.0, 30.0 ]
var branch_size_range = [ 0.3, 0.8 ]
var lines = []


class Line:
	var start = Vector2()
	var end = Vector2()
	func _init( start, end ):
		self.start = start
		self.end = end

func _ready():
	randomize()
	_generate_tree()
	update()


func _generate_tree():
	
	# trunc
	var trunc_height = rand_range( trunc_range[1][0], trunc_range[1][1] )
	var trunc_end = Vector2( 0, -trunc_height )
	trunc_end = trunc_end.rotated( rand_range( trunc_angle_range[0], trunc_angle_range[1] ) * PI / 180 )
	lines.append( Line.new( Vector2( 0, 0 ), trunc_end ) )
	
	# recursive generate branches	
	var ori = 1
	for n in range( ( randi() % 3 ) + 2 ):
		_generate_branch( lines[0], ori, 0 )
		ori = - ori


func _generate_branch( line, angle_orientation, layer = 0 ):
	# select random position along the line
	var t = rand_range( branch_start_range[0], branch_start_range[1] )
	var direction = line.end - line.start
	var branch_start = line.start + t * direction
	# select random angle for branch with respect to original angle
	var branch_angle = -direction
	var random_angle = -angle_orientation * rand_range( branch_angle_range[0], branch_angle_range[1] ) + 180
	branch_angle = branch_angle.rotated( random_angle * PI / 180 )
	# select random size
	branch_angle *= rand_range( branch_size_range[0], branch_size_range[1] )
	# compute new line for the branch
	var branch_end = branch_start + branch_angle
	var new_branch = Line.new( branch_start, branch_end )
	lines.append( new_branch )
	
	if layer < max_layers:
		var ori = 1
		for n in range( ( randi() % 3 ) + 2 ):
			_generate_branch( new_branch, ori, layer + 1 )
			ori = - ori
	pass


func _draw():
	for line in lines:
		draw_line( line.start, line.end, Color( 1, 1, 1 ) )




