tool
extends Node2D

# trying to have
# updates automatically from editor

# tree parameters
export( int ) var max_layers = 2 setget _set_max_layers
export( Color ) var polycolor = Color( 1, 1, 1, 1 ) setget _set_polycolor
export( Vector2 ) var trunc_height_range = Vector2( 130, 200 ) setget _set_trunc_height_range
export( Vector2 ) var trunc_basewidth_range = Vector2( 10, 20 ) setget _set_trunc_basewidth_range
export( Vector2 ) var trunc_topwidth_range = Vector2( 5, 10 ) setget _set_trunc_topwidth_range
export( Vector2 ) var trunc_topangle_range = Vector2( -50, 50 )
export( Vector2 ) var trunc_angle_range = Vector2( -5, 5 )
export( Vector2 ) var trunc_branches_range = Vector2( 2, 4 )
export( bool ) var trunc_branch_on_top = true

export( Vector2 ) var branch_base_range = Vector2( 0.5, 1 )
export( Vector2 ) var branch_angle_range = Vector2( 20, 25 )
export( Vector2 ) var branch_length_range = Vector2( 0.6, 1.0 )
export( Vector2 ) var branch_basewidth_range = Vector2( 1.3, 1.6 )
export( Vector2 ) var branch_topwidth_range = Vector2( 0.3, 0.6 )
export( Vector2 ) var branch_branches_range = Vector2( 2, 4 )
export( int ) var branch_rotation_range = 30
export( bool ) var branch_branch_on_top = true

export( Vector2 ) var mass_ratio = 0.5
export( Vector2 ) var dampenning = 0.999

var trunc = null


var _branch_rotation_range = branch_rotation_range * PI / 180


var wind = -80
var wind_timer = 5







class Branch:
	var parent = null
	var polygon2d = null
	var base = 0
	var top = 0
	var length = 0
	var angle = 0.0
	var rot_vel = 0.0
	var is_trunc = false
	var children = []
	func _init( parent, polygon2d, rest_angle, base, top, length ):
		self.polygon2d = polygon2d
		self.angle = rest_angle
		self.base = base
		self.top = top
		self.length = length
		if parent == null:
			self.is_trunc = true
	
	func add_child( p ):
		children.append( p )


func _ready():
	randomize()
	#print( "starting from ready" )
	_get_new_tree()
	#if not get_tree().is_editor_hint():
	if get_parent().has_method( "get_wind" ):
		print( "starting process" )
		set_fixed_process( true )


func _fixed_process( delta ):
	# apply wind for a few seconds
	wind = get_parent().get_wind()
	# update tree
	_update_tree( delta )
	
	#print( trunc.polygon2d.get_rot() )



func _update_tree( delta ):
	_update_branch( trunc, delta )
	pass

func _update_branch( branch, delta ):
	var out_force = 0
	#print( branch )
	if branch.children.empty():
		out_force = _rotate_branch( branch, wind, delta, true )
	else:
		var rel_wind = 0
		for child in branch.children:
			rel_wind += _update_branch( child, delta )
		rel_wind /= branch.children.size()
		out_force = _rotate_branch( branch, rel_wind, delta )
	return out_force

func _rotate_branch( branch, wind, delta, debug = false ):
	var mass = branch.length
	# compute forces
	var cur_angle = branch.polygon2d.get_rot()
	var angle_delta = branch.angle - cur_angle
	var force = angle_delta * mass * mass_ratio + wind 
	if branch.is_trunc:
		force = angle_delta * 2 * mass * mass_ratio + wind 
	branch.rot_vel += force * delta / mass
	branch.rot_vel *= dampenning # dampening
	cur_angle += branch.rot_vel * delta
	# limit rotation angle
	var angle_delta = cur_angle - branch.angle
	if abs( angle_delta ) > ( _branch_rotation_range / 2 ):
		cur_angle = branch.angle + sign( angle_delta ) * _branch_rotation_range / 2
		branch.rot_vel = 0
	branch.polygon2d.set_rot( cur_angle )
	# output force
	var out_force = -force * angle_delta / ( _branch_rotation_range / 2 )
	return out_force
	


func _set_max_layers( val ):
	max_layers = val
	_get_new_tree()
func _set_trunc_height_range( val ):
	trunc_height_range = val
	_get_new_tree()
func _set_trunc_basewidth_range( val ):
	trunc_basewidth_range = val
	_get_new_tree()
func _set_trunc_topwidth_range( val ):
	trunc_topwidth_range = val
	_get_new_tree()
func _set_polycolor( val ):
	polycolor = val
	_get_new_tree()

func _get_new_tree():
	if get_child_count() > 0:
		for n in get_children():
			_clear_tree( n )
			remove_child( n )
	trunc = null
	_generate_tree()

func _clear_tree( node ):
	if node.get_child_count() > 0:
		for n in node.get_children():
			node.remove_child( n )
			_clear_tree( n )
	#print( "clearing ", node.get_name() )
	node.queue_free()





func _generate_tree():
	# create trunc
	var base = Vector2( 0, 0 )
	var base_width = rand_range( trunc_basewidth_range.x, trunc_basewidth_range.y )
	var top_width = rand_range( trunc_topwidth_range.x, trunc_topwidth_range.y )
	if top_width > base_width: top_width = base_width
	var height = rand_range( trunc_height_range.x, trunc_height_range.y )
	var a = rand_range( trunc_angle_range.x, trunc_angle_range.y ) * PI / 180
	
	var p = _create_polygon2d( base_width, top_width, height )
	p.rotate( a )
	p.set_pos( base )
	add_child( p )
	trunc = Branch.new( null, weakref( p ), a, base_width, top_width, height )
	
	var number_of_branches = ( randi() % int( trunc_branches_range.y - trunc_branches_range.x + 1 ) ) + trunc_branches_range.x
	#print( number_of_branches )
	var orientation = 1
	for n in range( number_of_branches ):
		#print( "trunc( ", p.get_name(), " )  branch ", n )
		if n == 0:
			_recursive_branch( trunc, orientation, 1, trunc_branch_on_top )
		else:
			_recursive_branch( trunc, orientation, 1 )
		orientation = -orientation
	pass








func _recursive_branch( p, orientation, layer, on_top = false ):
	#print( "recursive branch - ", "Layer ", layer, " of ", max_layers )
	var vpos = p.length * rand_range( branch_base_range.x, branch_base_range.y )
	var a = orientation * rand_range( branch_angle_range.x, branch_angle_range.y ) * PI / 180
	if on_top: vpos = p.length - p.top * cos( a + branch_rotation_range / 2 * PI / 180 ) # stupid approximation for small angles
	var base = Vector2( 0, -vpos )
	var max_base_width = -vpos / p.length * ( p.base - p.top ) + p.base
	max_base_width *= cos( a + branch_rotation_range / 2 * PI / 180 ) # stupid approximation for small angles
	
	var length = p.length * rand_range( branch_length_range.x, branch_length_range.y )
	var base_width = p.base * rand_range( branch_basewidth_range.x, branch_basewidth_range.y )
	if base_width > max_base_width: base_width = max_base_width
	var top_width = p.top * rand_range( branch_topwidth_range.x, branch_topwidth_range.y )
	if top_width > base_width: top_width = base_width
	
	var br = _create_polygon2d( base_width, top_width, length )
	br.rotate( a )
	br.set_pos( base )
	p.polygon2d.get_ref().add_child( br )
	#print( "Creating ", br.get_name() )
	
	var branch = Branch.new( weakref( p ), weakref( br ), a, base_width, top_width, length )
	p.add_child( branch )
	
	if layer < max_layers:
		var number_of_branches = ( randi() % int( branch_branches_range.y - branch_branches_range.x + 1 ) ) + branch_branches_range.x + 1
		#print( number_of_branches )
		var orientation = 1
		for n in range( number_of_branches ):
			if n == 0:
				_recursive_branch( branch, orientation, layer + 1, branch_branch_on_top )
			else:
				_recursive_branch( branch, orientation, layer + 1 )
			orientation = -orientation


func _create_polygon2d( base_width, top_width, height ):
	var parray = Vector2Array()
	parray.append( Vector2( -base_width / 2, 0 ) )
	parray.append( Vector2( -top_width / 2, -height ) )
	parray.append( Vector2( top_width / 2, -height ) )
	parray.append( Vector2( base_width / 2, 0 ) )
	var p = Polygon2D.new()
	p.set_polygon( parray )
	p.set_color( polycolor )
	return p








