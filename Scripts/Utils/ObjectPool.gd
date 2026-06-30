extends Node

var _pools: Dictionary = {}

func get_object(scene_path: String) -> Node:
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	var pool: Array = _pools[scene_path]
	for obj in pool:
		if not obj.visible:
			obj.visible = true
			return obj
	var new_obj = load(scene_path).instantiate()
	pool.append(new_obj)
	add_child(new_obj)
	return new_obj

func return_object(obj: Node) -> void:
	obj.visible = false

func prewarm(scene_path: String, count: int) -> void:
	for i in range(count):
		var obj = load(scene_path).instantiate()
		obj.visible = false
		add_child(obj)
		if not _pools.has(scene_path):
			_pools[scene_path] = []
		_pools[scene_path].append(obj)

func clear_pool(scene_path: String) -> void:
	if _pools.has(scene_path):
		for obj in _pools[scene_path]:
			obj.queue_free()
		_pools.erase(scene_path)

func clear_all() -> void:
	for path in _pools:
		for obj in _pools[path]:
			obj.queue_free()
	_pools.clear()
