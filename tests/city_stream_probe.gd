extends SceneTree
## Headless probe for the six-district CityChunkStream.
## Exits 0 only if every check passes. Run:
##   godot --headless --path . --script res://tests/city_stream_probe.gd

const CityStream := preload("res://scripts/world/city_chunks.gd")

const CHUNK := 40.0
var failures: int = 0

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS  ", label)
	else:
		failures += 1
		print("FAIL  ", label)

func _init() -> void:
	var stream: Node3D = CityStream.new()
	root.add_child(stream)

	# 1) District table: all six 2x2 blocks mapped, non-overlapping.
	var seen: Dictionary = {}
	var ok_unique := true
	for cx in range(2, 8):
		for cz in range(2, 8):
			var d: int = stream.district_for_chunk(cx, cz)
			if d < 0:
				ok_unique = false
			elif seen.has(d) and seen[d] != Vector2i(cx / 2, cz / 2):
				ok_unique = false
			else:
				seen[d] = Vector2i(cx / 2, cz / 2)
	check(ok_unique and seen.size() == 6, "six districts cover chunks 2..7 (blocks=%d)" % seen.size())
	check(stream.district_for_chunk(0, 0) == -1, "chunks outside city bounds are meadow (-1)")
	check(stream.district_for_chunk(9, 9) == -1, "far chunks are meadow (-1)")

	# 2) Load ring: walking the chunk grid keeps the loaded set within budget.
	var ring_ok := true
	var max_loaded: int = 0
	for step in range(0, 10):
		var gx: int = 2 + (step % 4)
		var gz: int = 2 + (step / 4)
		stream.set_player_position(Vector3((float(gx) + 0.5) * CHUNK, 0.0, (float(gz) + 0.5) * CHUNK))
		max_loaded = maxi(max_loaded, stream.loaded_chunk_count())
		if stream.loaded_chunk_count() == 0:
			ring_ok = false
	check(ring_ok, "stream keeps chunks loaded while walking the city grid")
	check(max_loaded <= 25, "loaded chunk budget respected (max=%d, budget<=25)" % max_loaded)

	# 3) Unload: jumping far away frees the earlier chunks.
	stream.set_player_position(Vector3(2000.0, 0.0, 2000.0))
	stream.set_player_position(Vector3(2400.0, 0.0, 2400.0))
	var far_count: int = 0
	for c in stream.chunks.keys():
		if absi(c.x - 60) > 3 or absi(c.y - 60) > 3:
			far_count += 1
	check(far_count == 0, "no stale chunks remain after jumping 2+ chunks away")
	check(stream.loaded_chunk_count() <= 25, "far load stays within budget (got %d)" % stream.loaded_chunk_count())

	# 4) District coverage of the load window at the city center (3,3).
	stream.set_player_position(Vector3(3.5 * CHUNK, 0.0, 3.5 * CHUNK))
	var by_district: Array = stream.stream_stats()["by_district"]
	var covered: int = 0
	for v in by_district:
		if int(v) > 0:
			covered += 1
	check(covered >= 3, "load window at city center spans >= 3 districts (got %d)" % covered)

	# 5) Road-safe band: every building AABB fully inside |coord| <= 12.
	var band_ok := true
	var worst: float = 0.0
	for c in stream.chunks.keys():
		var node: Node3D = stream.chunks[c]
		var content := node.get_node_or_null("Content")
		if content == null:
			band_ok = false
			continue
		for child in content.get_children():
			if child is StaticBody3D:
				var col := child.get_node_or_null("CollisionShape3D") as CollisionShape3D
				if col != null and col.shape is BoxShape3D:
					var size: Vector3 = (col.shape as BoxShape3D).size
					var pos: Vector3 = child.position
					if absf(pos.x) + size.x * 0.5 > 12.0 or absf(pos.z) + size.z * 0.5 > 12.0:
						band_ok = false
						worst = maxf(worst, maxf(absf(pos.x) + size.x * 0.5, absf(pos.z) + size.z * 0.5))
	check(band_ok, "all building AABBs stay off the border roads (worst overflow=%.2f)" % worst)

	# 6) Residential alley separation: two diagonal houses per residential chunk.
	var alley_ok := true
	var min_gap: float = 999.0
	for c in stream.chunks.keys():
		if stream.district_for_chunk(c.x, c.y) != 0:
			continue
		var content2 := stream.chunks[c].get_node("Content")
		var centers: Array[Vector3] = []
		for child in content2.get_children():
			if child is StaticBody3D:
				centers.append(child.position)
		if centers.size() < 2:
			alley_ok = false
			continue
		var gap: float = centers[0].distance_to(centers[1])
		min_gap = minf(min_gap, gap)
		if gap < 12.0:
			alley_ok = false
	check(alley_ok, "residential alley separation >= 12 m (min=%.1f)" % min_gap)

	# 7) Determinism: two fresh streams produce identical chunk content layouts.
	var layout_of := func(stream_a: Node3D) -> String:
		var parts: Array[String] = []
		var keys := stream_a.chunks.keys()
		keys.sort_custom(func(a, b): return str(a) < str(b))
		for c2 in keys:
			var node2: Node3D = stream_a.chunks[c2]
			var content2b := node2.get_node_or_null("Content")
			var counts := {}
			if content2b != null:
				for child2 in content2b.get_children():
					var key := child2.get_class()
					if child2 is StaticBody3D:
						key = "Building"
					counts[key] = int(counts.get(key, 0)) + 1
			parts.append("%s:%s" % [c2, str(counts)])
		return "|".join(parts)
	var layout_a: String = layout_of.call(stream)
	var stream_b: Node3D = CityStream.new()
	root.add_child(stream_b)
	stream_b.set_player_position(Vector3(3.5 * CHUNK, 0.0, 3.5 * CHUNK))
	var layout_b: String = layout_of.call(stream_b)
	check(layout_a == layout_b, "deterministic generation: two independent streams match")

	# 8) Streaming signals fire on load/unload.
	var loaded_signal_ok := false
	var stream_c: Node3D = CityStream.new()
	stream_c.chunk_loaded.connect(func(_c, _d): loaded_signal_ok = true)
	root.add_child(stream_c)
	stream_c.set_player_position(Vector3(4.5 * CHUNK, 0.0, 4.5 * CHUNK))
	check(loaded_signal_ok, "chunk_loaded signal fires on streaming")

	print("")
	print("city_stream_probe: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
