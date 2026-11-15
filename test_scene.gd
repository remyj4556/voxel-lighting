class_name TestScene
extends TileMapLayer

const GRASS := Vector2i(1, 0)
const WALL := Vector2i(0, 1)
const LIGHT := Vector2i(0, 0)

func _init() -> void:
	paint_grass()
	draw_single_block_test()

func paint_grass() -> void:
	for i in range(LightTest.WIDTH):
		for j in range(LightTest.HEIGHT):
			draw_tile(Vector2i(j,i), 0, GRASS)
	
func draw_single_block_test() -> void:
	draw_tile(Vector2i(LightTest.WIDTH / 2, LightTest.HEIGHT / 2), 0, WALL)

func draw_tile(grid_coords: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	if (grid_coords.x >= 0 and grid_coords.x < LightTest.WIDTH and grid_coords.y >= 0 and grid_coords.y < LightTest.HEIGHT):
		set_cell(grid_coords, source_id, atlas_coords)
