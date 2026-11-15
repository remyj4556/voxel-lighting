class_name LightTest
extends Node2D

const WIDTH : int = 64
const HEIGHT : int = 64
const TILE_SIZE : int = 16
const MAX_LIGHT_INTENSITY : int = 15
const LIGHT_FALLOFF : int = 1

const TEST_SCENE = preload("uid://eocwsab8af3x")

@onready var light_overlay: LightOverlay = %LightOverlay
@onready var camera_2d: Camera2D = %Camera2D

var grid_scene : TestScene = null
var light_grid := PackedByteArray()
var lights: Dictionary[Vector2i, int] # int is dummy value, acts as hashset

func _ready() -> void:
	grid_scene = TEST_SCENE.instantiate()
	self.add_child(grid_scene)
	grid_scene.position = Vector2i(0,0)

	camera_2d.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera_2d.position = Vector2(WIDTH, HEIGHT) * TILE_SIZE / 2.0
	camera_2d.zoom = Vector2(2.0, 2.0)
	
	light_grid.resize(LightTest.WIDTH * LightTest.HEIGHT)
	
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

func reset_light_values() -> void:
	for i in range(WIDTH):
		for j in range(HEIGHT):
			light_overlay.set_light(Vector2i(i,j), 0.0)
	light_overlay.push_light()
			
func update_light_values(update_source: Vector2i) -> void:
	if lights.has(update_source):
		flood_fill(update_source, MAX_LIGHT_INTENSITY, LIGHT_FALLOFF)

func spawn_light(mouse_pos: Vector2) -> void:
	if (!grid_scene):
		print("No test scene")
		return 
		
	var tile_coord := Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE))
	grid_scene.draw_tile(tile_coord, 0, grid_scene.LIGHT)
	lights[tile_coord] = 1
	update_light_values(tile_coord)

func remove_light(mouse_pos: Vector2) -> void:
	pass

func flood_fill(position: Vector2i, start_intensity: int, falloff: int) -> void:
	if start_intensity > MAX_LIGHT_INTENSITY:
		return

	var bfs_array : Array[Array]
	bfs_array.push_back([position, start_intensity])
	while not bfs_array.is_empty():
		var curr : Array = bfs_array.pop_front()
		var coord : Vector2i = curr[0]
		var value : int = curr[1]
		
		var dx : Array[int] = [0, 0, 1, -1]
		var dy : Array[int] = [1, -1, 0, 0]
		
		for i in range(4):
			var nx : int = coord.x + dx[i]
			var ny : int = coord.y + dy[i]
			
			# skip if block out of bounds or wall
			if nx < 0 or nx > WIDTH: 
				continue
			if ny < 0 or ny > HEIGHT:
				continue
			
			var next_intensity : int = value - falloff;
			if (next_intensity > get_light_level(Vector2i(nx, ny))):
				set_light_level(Vector2i(nx, ny), next_intensity)
				bfs_array.push_back([Vector2i(nx, ny), next_intensity])
	light_overlay.push_light()
	
func get_light_level(c: Vector2i) -> int:
	return light_grid[c.y * WIDTH + c.x]

func set_light_level(c: Vector2i, v: int) -> void:
	light_grid[c.y * WIDTH + c.x] = v
	light_overlay.set_light(c, float(v) / MAX_LIGHT_INTENSITY)
