extends Node2D

# Reference your camera so we can fit layers to its viewport
@onready var camera: Camera2D = get_viewport().get_camera_2d()

var scroll_scales = [
	Vector2(0.1, 0.05),   # Sky
	Vector2(0.3, 0.2),    # Mountains
	Vector2(0.6, 0.5),    # Hills  
	Vector2(0.85, 0.8)    # Trees
]

func _ready():
	setup_parallax_layers()

func setup_parallax_layers():
	if not camera:
		return
		
	var viewport_size = get_viewport_rect().size / camera.zoom  # visible area in world units
	var layers = get_children()
	
	for i in range(min(layers.size(), scroll_scales.size())):
		if layers[i] is Parallax2D:
			layers[i].scroll_scale = scroll_scales[i]

			if layers[i].get_child_count() > 0 and layers[i].get_child(0) is Sprite2D:
				var sprite := layers[i].get_child(0) as Sprite2D
				if sprite.texture:
					var tex_size = sprite.texture.get_size() * sprite.scale
					
					# Repeat enough to cover the camera viewport
					var repeat_x = max(tex_size.x, viewport_size.x)
					var repeat_y = max(tex_size.y, viewport_size.y)
					layers[i].repeat_size = Vector2(repeat_x, repeat_y)
