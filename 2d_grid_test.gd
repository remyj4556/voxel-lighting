class_name LightTest
extends Node2D

const WIDTH : int = 64
const HEIGHT : int = 64
const TILE_SIZE : int = 16

const TEST_SCENE = preload("uid://eocwsab8af3x")

@onready var light_overlay: LightOverlay = %LightOverlay
@onready var camera_2d: Camera2D = %Camera2D

var curr_test : TestScene = null
var lights: Dictionary[Vector2i, int] # int is dummy value, acts as hashset

func _ready() -> void:
	curr_test = TEST_SCENE.instantiate()
	self.add_child(curr_test)
	curr_test.position = Vector2i(0,0)

	camera_2d.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera_2d.position = Vector2(WIDTH, HEIGHT) * TILE_SIZE / 2.0
	camera_2d.zoom = Vector2(2.0, 2.0)
	
	reset_light_values()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("PlaceLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		spawn_light(mouse_pos)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("RemoveLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		spawn_light(mouse_pos)
		get_viewport().set_input_as_handled()

func reset_light_values():
	for i in range(WIDTH):
		for j in range(HEIGHT):
			light_overlay.set_light(Vector2i(i,j), 0.0)
	light_overlay.push_light()
			
func update_light_values(update_source: Vector2i):
	if lights.has(update_source):
		var bfs_array : Array[Array]
	
		bfs_array.push_back([update_source, 15])
		while not bfs_array.is_empty():
			var curr : Array = bfs_array.pop_front()
			var coord : Vector2i = curr[0]
			var value : int = curr[1] - 1
			
			if value < 1:
				continue
			
			bfs_array.push_back([coord + Vector2i(1, 0), value - 1])
			bfs_array.push_back([coord + Vector2i(0, 1), value - 1])
			bfs_array.push_back([coord + Vector2i(-1, 0), value - 1])
			bfs_array.push_back([coord + Vector2i(0, -1), value - 1])
			
			light_overlay.set_light(coord, value)
		light_overlay.push_light()

func spawn_light(mouse_pos: Vector2):
	if (!curr_test):
		print("No test scene")
		return 
		
	var tile_coord := Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE))
	curr_test.draw_tile(tile_coord, 0, curr_test.LIGHT)
	lights[tile_coord] = 1
	update_light_values(tile_coord)

func remove_light(mouse_pos: Vector2):
	pass
