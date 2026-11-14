class_name LightTest
extends Node2D

const WIDTH : int = 64
const HEIGHT : int = 64
const TILE_SIZE : int = 16

const TEST_SCENE = preload("uid://eocwsab8af3x")

@onready var light_overlay: LightOverlay = %LightOverlay
@onready var camera_2d: Camera2D = %Camera2D

var curr_test : TestScene = null

func _init() -> void:
	pass

func _ready() -> void:
	curr_test = TEST_SCENE.instantiate()
	self.add_child(curr_test)
	curr_test.position = Vector2i(10,0)

	camera_2d.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera_2d.position = Vector2(WIDTH, HEIGHT) * TILE_SIZE / 2.0
	camera_2d.zoom = Vector2(2.0, 2.0)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("PlaceLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		spawn_light(mouse_pos)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("RemoveLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		spawn_light(mouse_pos)
		get_viewport().set_input_as_handled()
	
func update_light_values():
	pass

func spawn_light(mouse_pos: Vector2):
	if (!curr_test):
		print("No test scene")
		return 
	curr_test.draw_tile(Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE)), 0, Vector2i(1,0))

func remove_light(mouse_pos: Vector2):
	pass
