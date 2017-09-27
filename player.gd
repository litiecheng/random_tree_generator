extends KinematicBody2D

var input_states = preload( "res://input_states.gd" )
var btn_left = input_states.new( "btn_left" )
var btn_right = input_states.new( "btn_right" )

const GRAVITY = 500
const MAX_VEL = 150
const ACCEL = 5
var vel = Vector2()
var dir = 1
var anim_cur = ""
var anim_nxt = "run"
onready var anim = get_node( "anim" )

onready var rotate = get_node( "rotate" )
var dir_cur = 1
var dir_nxt = 1

func _ready():
	set_fixed_process( true )

func _fixed_process(delta):
	if btn_right.check():
		vel.x = lerp( vel.x, MAX_VEL, ACCEL * delta )
		anim_nxt = "run"
		if vel.x > 0:
			dir_nxt = 1
	elif btn_left.check():
		vel.x = lerp( vel.x, -MAX_VEL, ACCEL * delta )
		anim_nxt = "run"
		if vel.x < 0:
			dir_nxt = -1
	else:
		vel.x = lerp( vel.x, 0, 5 * ACCEL * delta )
		if vel.x < 3:
			vel.x = 0
			anim_nxt = "idle"
	
	if anim_nxt != anim_cur:
		anim_cur = anim_nxt
		if anim_cur == "idle":
			anim.stop( false )
		else:
			anim.play( anim_cur )
	if dir_nxt != dir_cur:
		dir_cur = dir_nxt
		rotate.set_scale( Vector2( dir_cur, 1 ) )
	vel.y += GRAVITY * delta
	vel = move_and_slide( vel )

