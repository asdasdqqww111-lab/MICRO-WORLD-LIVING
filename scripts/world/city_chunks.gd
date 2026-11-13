func _build_market(node: Node3D, rng: RandomNumberGenerator) -> void:
	# Four fixed market stalls (2x2), jittered per chunk for variety.
	var slots: Array[Vector3] = [Vector3(-8, 0, -8), Vector3(8, 0, -8), Vector3(-8, 0, 8), Vector3(8, 0, 8)]
	for s: Vector3 in slots:
		var p := s + Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-1.5, 1.5))
		_building(node, p,
			Vector3(rng.randf_range(3.5, 4.0), rng.randf_range(3.5, 5.5), rng.randf_range(3.5, 4.0)),
			Color(0.78, 0.68, 0.55), Color(0.55, 0.35, 0.24))
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		_lamp(node, Vector3(cos(a), 0.0, sin(a)) * 14.0, Color(1.0, 0.8, 0.45))
