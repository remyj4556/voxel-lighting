class_name LightTest
extends Node2D

const WIDTH : int = 64
const HEIGHT : int = 64
const TILE_SIZE : int = 16
const MAX_LIGHT_INTENSITY : int = 20
const LIGHT_FALLOFF : int = 1

const GRASS : int = 0
const WALL : int = 1
const LIGHT : int = 2

var blocks : Dictionary[int, Vector2i] = {
	GRASS: Vector2i(1,0), 
	WALL: Vector2i(0,1), 
	LIGHT: Vector2i(0,0)
}

enum Corners { TL, TR, BR, BL }

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
	
	#set_room_test(10)
	set_wall_test(10)
	#set_single_block_test()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("PlaceLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		var tile_pos := Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE))
		place_block(tile_pos, LIGHT)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("RemoveLight"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		var tile_pos := Vector2i(floori(mouse_pos.x / TILE_SIZE), floori(mouse_pos.y / TILE_SIZE))
		remove_block(tile_pos)
		get_viewport().set_input_as_handled()
			
func update_light_values(update_source_pos: Vector2i) -> void:
	if block_grid[update_source_pos.y * WIDTH + update_source_pos.x] == LIGHT:
		#flood_fill(update_source_pos, MAX_LIGHT_INTENSITY, LIGHT_FALLOFF)
		shadow_sweep(update_source_pos, MAX_LIGHT_INTENSITY)

func place_block(pos: Vector2i, block_id: int) -> void:
	block_grid[pos.y * WIDTH + pos.x] = block_id
	terrain_tile_map.draw_tile(pos, 0, blocks[block_id])
	
	if block_id == LIGHT:
		update_light_values(pos)

func remove_block(pos: Vector2i) -> void:
	place_block(pos, GRASS)
	remove_light(pos)

func get_corner_pos(pos: Vector2i, corner: Corners) -> Vector2:
	var dx : Array[float] = [0, 1, 1, 0]
	var dy : Array[float] = [0, 0, 1, 1]
	return Vector2(pos.x + dx[corner], pos.y + dy[corner])
	
# Merges arrays A and B, removing duplicates
func merge_arrays(a: Array, b: Array) -> Array:
	for item in b:
		if not a.has(item):
			a.append(item)
	return a

# octant_id: [0,7]
# pos: position of local cell in octant
# light: light source position for shifting coordinates
func oct_pos_to_world(octant_id: int, pos: Vector2i, light_pos: Vector2i) -> Vector2i:
	const OCTANTS : Array[Array] = [
		[ 1,  0,  0,  1],  # 0: ( x,  y)
		[ 0,  1,  1,  0],  # 1: ( y,  x)
		[ 0, -1,  1,  0],  # 2: (-y,  x)
		[-1,  0,  0,  1],  # 3: (-x,  y)
		[-1,  0,  0, -1],  # 4: (-x, -y)
		[ 0, -1, -1,  0],  # 5: (-y, -x)
		[ 0,  1, -1,  0],  # 6: ( y, -x)
		[ 1,  0,  0, -1],  # 7: ( x, -y)
	]
	
	var t: Array = OCTANTS[octant_id]
	
	return light_pos + Vector2i(
		t[0] * pos.x + t[1] * pos.y,
		t[2] * pos.x + t[3] * pos.y
	)
	
# Returns an Array of exactly 2 floats, which represents the 
# interval of slopes covered by the cell at (col, row) in octant space.
# Light is at (0, 0); cell center is (col, row); corners are +-0.5.
# col >= 1, so corner x >= 0.5: no division by zero.
func get_slope_interval(col: int, row: int) -> Array[float]:
	var lo := INF
	var hi := -INF
	for cx: float in [col - 0.5, col + 0.5]:
		for cy: float in [row - 0.5, row + 0.5]:
			var s := cy / cx
			lo = minf(lo, s)
			hi = maxf(hi, s)
	return [lo, hi]
	
func shadow_sweep(light_pos: Vector2i, start_intensity: int) -> void:
	# Handle light source itself separately.
	if start_intensity > get_light_level(light_pos):
		set_light_level(light_pos, start_intensity)
		
	var center_offset := Vector2i(TILE_SIZE / 2, TILE_SIZE / 2)
	var light_pos_center : Vector2i = light_pos + center_offset
	
	# Every octant runs the same calculations with translated coordinates
	# to fit the real location. 
	# The baseline for calculations is octant 0 <= y <= x 
	for octant_id in 8:
		# Contains sorted and merged [low, high] slope intervals.
		# All slopes start from he same origin (light's center),
		# meaning an occluded block is any that itself has a slope
		# greater than or equal to low and less than or equal to high.
		var blocked_ranges : Array[Array] = [] # Array of [low, high] slope pairs
		
		for col in range(1, start_intensity + 1):
			var pending : Array[Array] = [] # [low, high] slope pairs on this column
			
			for row in range(0, col + 1):
				# World position only for grid reads and writes, all geometry
				# done in octant space.
				var cell_pos : Vector2i = oct_pos_to_world(octant_id, Vector2i(col, row), light_pos)
				if cell_pos.x < 0 or cell_pos.x >= WIDTH or cell_pos.y < 0 or cell_pos.y >= HEIGHT:
					continue
					
				# Compute the slope of this cell's center to the light source in octant space.
				var cell_slope : float = float(row) / col
				
				# If coordinate inside any [low, high] interval in blocked_ranges,
				# it is shadowed.
				var shadowed: bool = false
				for interval : Array[float] in blocked_ranges:
					if interval.size() < 2:
						print("malformed interval pair")
						return 
						
					if cell_slope >= interval[0] and cell_slope <= interval[1]:
						shadowed = true
						break
				
				# If cell has an opaque block, add its [low, high] slope interval
				# to pending. 
				if block_grid[cell_pos.y * WIDTH +  cell_pos.x] == WALL:
					pending.push_back(get_slope_interval(col, row))
				
				# Write light to cell if not shadowed
				elif not shadowed:
					var dist : float = Vector2(col, row).length()
					var level := int(start_intensity - dist)
					if level > get_light_level(cell_pos):
						set_light_level(cell_pos, level)
					
			merge_arrays(blocked_ranges, pending)
			light_overlay.push_light()
		
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
			if nx < 0 or nx >= WIDTH: 
				continue
			if ny < 0 or ny >= HEIGHT:
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

func remove_light(pos: Vector2i) -> void:
	# reset light grid and light overlay to 0
	light_grid.fill(0)
	for cell in light_grid.size():
		light_overlay.set_light(Vector2i(cell % WIDTH, cell / WIDTH), 0.0)
	# recompute lights based on block grid
	for cell in block_grid.size():
		if block_grid[cell] == LIGHT:
			update_light_values(Vector2i(cell % WIDTH, cell / WIDTH))
	light_overlay.push_light() 

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

func set_room_test(length: int) -> void:
	set_grass()
	# top and bottom wall
	for i in range(-length/2, length/2):
		place_block(Vector2i(WIDTH / 2 + i, (HEIGHT / 2) - (length / 2)), WALL)
		place_block(Vector2i(WIDTH / 2 + i, (HEIGHT / 2) + (length / 2)), WALL)
	# left and right wall
	for i in range(-length/2, length/2 + 1):
		place_block(Vector2i(WIDTH / 2 - (length / 2), (HEIGHT / 2) - i), WALL)
		place_block(Vector2i(WIDTH / 2 + (length / 2), (HEIGHT / 2) + i), WALL)	
	
