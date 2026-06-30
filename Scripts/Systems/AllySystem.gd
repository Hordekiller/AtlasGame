extends Node

signal alliance_requested(from_player: String, target_player: String)
signal alliance_formed(alliance_id: String, member1: String, member2: String)
signal alliance_broken(alliance_id: String)
signal alliance_help_sent(alliance_id: String, from: String, resource_type: int, amount: int)

var _alliances: Dictionary = {}
var _pending_requests: Array = []
var _npc_truce: Dictionary = {}

func create_alliance(alliance_id: String, founder: String) -> bool:
	if _alliances.has(alliance_id):
		return false
	_alliances[alliance_id] = {
		"id": alliance_id,
		"members": [founder],
		"created_day": GameState.current_day,
		"resources_shared": 0
	}
	return true

func disband_alliance(alliance_id: String) -> void:
	if not _alliances.has(alliance_id):
		return
	for member in _alliances[alliance_id]["members"]:
		EventBus.notification_added.emit("اتحاد " + alliance_id + " منحل شد", "warning")
	_alliances.erase(alliance_id)
	alliance_broken.emit(alliance_id)

func get_alliance(alliance_id: String) -> Dictionary:
	return _alliances.get(alliance_id, {})

func get_player_alliance(player_id: String) -> String:
	for aid in _alliances:
		if player_id in _alliances[aid]["members"]:
			return aid
	return ""

func is_in_alliance(player_id: String) -> bool:
	return not get_player_alliance(player_id).is_empty()

func request_alliance(from: String, to: String) -> void:
	_pending_requests.append({"from": from, "to": to})
	alliance_requested.emit(from, to)

func accept_request(from_player: String, to_player: String) -> String:
	var idx = -1
	for i in range(_pending_requests.size()):
		var req = _pending_requests[i]
		if req["from"] == from_player and req["to"] == to_player:
			idx = i
			break
	if idx < 0:
		return ""
	_pending_requests.remove_at(idx)
	var aid = "alliance_" + str(Time.get_unix_time_from_system())
	_alliances[aid] = {
		"id": aid,
		"members": [from_player, to_player],
		"created_day": GameState.current_day,
		"resources_shared": 0
	}
	alliance_formed.emit(aid, from_player, to_player)
	return aid

func decline_request(from_player: String, to_player: String) -> void:
	for i in range(_pending_requests.size() - 1, -1, -1):
		var req = _pending_requests[i]
		if req["from"] == from_player and req["to"] == to_player:
			_pending_requests.remove_at(i)

func send_help(alliance_id: String, from: String, resource_type: int, amount: int) -> bool:
	var alliance = _alliances.get(alliance_id)
	if not alliance or from not in alliance["members"]:
		return false
	alliance["resources_shared"] += amount
	alliance_help_sent.emit(alliance_id, from, resource_type, amount)
	return true

func set_npc_truce(npc_id: String, duration_days: int) -> void:
	_npc_truce[npc_id] = GameState.current_day + duration_days

func has_npc_truce(npc_id: String) -> bool:
	if not _npc_truce.has(npc_id):
		return false
	if GameState.current_day >= _npc_truce[npc_id]:
		_npc_truce.erase(npc_id)
		return false
	return true

func get_pending_requests() -> Array:
	return _pending_requests.duplicate()

func get_save_data() -> Dictionary:
	return {
		"alliances": _alliances.duplicate(true),
		"pending": _pending_requests.duplicate(),
		"truce": _npc_truce.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	_alliances = data.get("alliances", {}).duplicate(true)
	_pending_requests = data.get("pending", []).duplicate()
	_npc_truce = data.get("truce", {}).duplicate()