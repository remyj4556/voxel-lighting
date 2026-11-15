class_name LightOverlay
extends Sprite2D

var light_img := Image.create(LightTest.WIDTH, LightTest.HEIGHT, false, Image.FORMAT_L8) 
var light_tex := ImageTexture.create_from_image(light_img)

func _ready() -> void:
	self.texture = light_tex
	self.centered = false
	self.scale = Vector2(LightTest.TILE_SIZE, LightTest.TILE_SIZE) 
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	self.material = mat
	
	# move to front so tiles do not cover it
	z_index = 1

func set_light(cell: Vector2i, value: float):
	light_img.set_pixel(cell.x, cell.y, Color(value, value, value))

func push_light():
	light_tex.update(light_img) 
