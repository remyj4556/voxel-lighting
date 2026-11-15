class_name LightTest
extends Node2D

const WIDTH : int = 64
const HEIGHT : int = 64
const TILE_SIZE : int = 16
const MAX_LIGHT_INTENSITY : int = 15
const LIGHT_FALLOFF : int = 1

const GRASS : int = 0
const WALL : int = 1
const LIGHT : int = 2

var blocks : Dictionary[int, Vector2i] = {
	GRASS: Vector2i(1,0), 
	WALL: Vector2i(0,1), 
	LIGHT: Vector2i(0,0)
}

@onready var terrain_tile_map: TerrainTileMap = %TerrainTileMap
@onready var light_overlay: LightOverlay = %LightOverlay
@onready var camera_2d: Camera2D = %Camera2D

var light_grid := PackedByteArray() # light levels
var block_grid := PackedByteArray() # block placements

func _ready() -> void:
	camera_2d.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera_2d.position = Vector2(WIDTH, HEIGHT) * TILE_SIZE / 2.0
	camera_2d.zoom = Vector2(2.0, 2.0)
	
	light_grid.resize(WIDTH * HEIGHT)
	block_grid.resize(WIDTH * HEIGHT)
	
	set_wall_test(10)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("PlaceLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		var tile_pos := Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE))
		place_block(tile_pos, LIGHT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("RemoveLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		get_viewport().set_input_as_handled()

func reset_light_values() -> void:
	for i in range(WIDTH):
		for j in range(HEIGHT):
			light_overlay.set_light(Vector2i(i,j), 0.0)
	light_overlay.push_light()
			
func update_light_values(update_source_pos: Vector2i) -> void:
	if block_grid[update_source_pos.y * WIDTH + update_source_pos.x] == LIGHT:
		flood_fill(update_source_pos, MAX_LIGHT_INTENSITY, LIGHT_FALLOFF)

func place_block(pos: Vector2i, block_id: int) -> void:
	block_grid[pos.y * WIDTH + pos.x] = block_id
	terrain_tile_map.draw_tile(pos, 0, blocks[block_id])
	
	if block_id == LIGHT:
		update_light_values(pos)

func flood_fill(pos: Vector2i, start_intensity: int, falloff: int) -> void:
	if start_intensity > MAX_LIGHT_INTENSITY:
		return

	var bfs_array : Array[Array]
	bfs_array.push_back([pos, start_intensity])
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
			if block_grid[ny * WIDTH + nx] == WALL:
				continue
			
			var next_intensity : int = value - falloff;
			if (next_intensity > get_light_level(Vector2i(nx, ny))):
				set_light_level(Vector2i(nx, ny), next_intensity)
				bfs_array.push_back([Vector2i(nx, ny), next_intensity])
	light_overlay.push_light()
	
func get_light_level(pos: Vector2i) -> int:
	return light_grid[pos.y * WIDTH + pos.x]

func set_light_level(pos: Vector2i, value: int) -> void:
	light_grid[pos.y * WIDTH + pos.x] = value
	light_overlay.set_light(pos, float(value) / MAX_LIGHT_INTENSITY)

# Test Environment Setups --------------------
func set_grass() -> void:
	for i in range(WIDTH):
		for j in range(HEIGHT):
			place_block(Vector2i(i,j), GRASS)
	
func set_single_block_test() -> void:
	set_grass()
	place_block(Vector2i(WIDTH / 2, HEIGHT / 2), WALL)

func set_wall_test(length: int) -> void:
	set_grass()
	for i in range(-length/2, length/2):
		place_block(Vector2i(WIDTH / 2 + i, HEIGHT / 2), WALL)
