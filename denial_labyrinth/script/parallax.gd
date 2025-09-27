extends Node2D

func _ready():
	print("Setting up parallax layers")
	setup_parallax_layers()

func setup_parallax_layers():
	var motion_scales = [
		Vector2(0.1, 0.05),
		Vector2(0.3, 0.2),
		Vector2(0.6, 0.5),
		Vector2(0.85, 0.8)
	]
	
	var layers = get_children()
	print("Found ", layers.size(), " child nodes")
	
	for i in range(min(layers.size(), motion_scales.size())):
		if layers[i] is ParallaxLayer:
			layers[i].motion_scale = motion_scales[i]
			print("Set layer ", i, " motion_scale to ", motion_scales[i])
		else:
			print("Child ", i, " is not ParallaxLayer, it's ", typeof(layers[i]))
