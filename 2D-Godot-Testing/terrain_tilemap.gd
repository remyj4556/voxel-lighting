class_name TerrainTileMap
extends TileMapLayer

func draw_tile(grid_coords: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	if (grid_coords.x >= 0 and grid_coords.x < LightTest.WIDTH and grid_coords.y >= 0 and grid_coords.y < LightTest.HEIGHT):
		set_cell(grid_coords, source_id, atlas_coords)
