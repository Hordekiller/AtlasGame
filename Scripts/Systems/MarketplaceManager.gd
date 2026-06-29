extends Node

const BASE_MERCHANT_VISIT_INTERVAL: float = 120.0
const MERCHANT_VISIT_VARIANCE: float = 60.0
const PROFIT_MARGIN: float = 0.2

class MerchantNPC:
	var name: String
	var resources_wanted: Array
	var resources_offered: Array
	var quantity_range: Vector2
	var price_modifier: float
	var visit_timer: float
	var is_visiting: bool = false
	var staying_duration: float
	var staying_remaining: float

	func _init(n: String, wanted: Array, offered: Array, qty: Vector2, mod: float):
		name = n
		resources_wanted = wanted
		resources_offered = offered
		quantity_range = qty
		price_modifier = mod
		visit_timer = randf_range(30.0, 120.0)

const MERCHANT_TEMPLATES = [
	{
		"name": "بازرگان چوب",
		"wanted": [Globals.ResourceType.WINE, Globals.ResourceType.GOLD],
		"offered": [Globals.ResourceType.WOOD],
		"qty": Vector2(50, 300),
		"mod": 1.0
	},
	{
		"name": "تاجر مرمر",
		"wanted": [Globals.ResourceType.GOLD, Globals.ResourceType.WOOD],
		"offered": [Globals.ResourceType.MARBLE],
		"qty": Vector2(20, 150),
		"mod": 1.3
	},
	{
		"name": "دلال شیشه",
		"wanted": [Globals.ResourceType.GOLD, Globals.ResourceType.CRYSTAL],
		"offered": [Globals.ResourceType.GLASS],
		"qty": Vector2(15, 100),
		"mod": 1.4
	},
	{
		"name": "بازرگان شراب",
		"wanted": [Globals.ResourceType.GOLD, Globals.ResourceType.WOOD],
		"offered": [Globals.ResourceType.WINE],
		"qty": Vector2(30, 200),
		"mod": 1.1
	},
	{
		"name": "دلال گوگرد",
		"wanted": [Globals.ResourceType.GOLD, Globals.ResourceType.CRYSTAL, Globals.ResourceType.WOOD],
		"offered": [Globals.ResourceType.SULFUR],
		"qty": Vector2(10, 80),
		"mod": 1.5
	},
	{
		"name": "تاجر کریستال",
		"wanted": [Globals.ResourceType.GOLD, Globals.ResourceType.SULFUR],
		"offered": [Globals.ResourceType.CRYSTAL],
		"qty": Vector2(10, 60),
		"mod": 1.6
	},
	{
		"name": "بازرگان عمومی",
		"wanted": [Globals.ResourceType.GOLD],
		"offered": [Globals.ResourceType.WOOD, Globals.ResourceType.STONE, Globals.ResourceType.SULFUR, Globals.ResourceType.CRYSTAL],
		"qty": Vector2(30, 200),
		"mod": 1.2
	}
]

var _active_merchants: Dictionary = {}
var _trade_offers: Array = []
var _merchant_timers: Dictionary = {}

func _ready() -> void:
	for tmpl in MERCHANT_TEMPLATES:
		var city_id = "npc_%s" % tmpl.name
		_merchant_timers[city_id] = randf_range(60.0, 180.0)

func get_trade_contracts(city_id: String) -> int:
	return BuildingManager.get_trade_contracts(city_id)

func can_create_offer(city_id: String, resource_type: int, amount: int, price_per_unit: float) -> Dictionary:
	var contracts = get_trade_contracts(city_id)
	var current = _get_city_offer_count(city_id)
	if current >= contracts:
		return {"success": false, "reason": "تعداد قراردادهای تجاری تکمیل است"}

	var city = GameState.current_cities.get(city_id)
	if not city:
		return {"success": false, "reason": "شهر یافت نشد"}

	var resources = city.get("resources", {})
	if resources.get(resource_type, 0.0) < amount:
		return {"success": false, "reason": "منابع کافی نیست"}

	return {"success": true}

func create_sell_offer(city_id: String, resource_type: int, amount: int, price_per_unit: float) -> bool:
	var check = can_create_offer(city_id, resource_type, amount, price_per_unit)
	if not check.success:
		return false

	var trade_id = "sell_%s_%d_%d" % [city_id, resource_type, GameState.game_time]
	_trade_offers.append({
		"id": trade_id,
		"city_id": city_id,
		"type": "sell",
		"resource_type": resource_type,
		"amount": amount,
		"price_per_unit": price_per_unit,
		"filled": 0,
		"active": true
	})

	EconomyManager.deduct_costs(city_id, {resource_type: amount})
	EventBus.marketplace_trade_created.emit(trade_id, city_id, resource_type, amount, price_per_unit)
	return true

func create_buy_offer(city_id: String, resource_type: int, amount: int, price_per_unit: float) -> bool:
	var check = can_create_offer(city_id, resource_type, amount, price_per_unit)
	if not check.success:
		return false

	var total_cost = price_per_unit * amount
	if not EconomyManager.can_afford(city_id, {Globals.ResourceType.GOLD: total_cost}):
		return false

	EconomyManager.deduct_costs(city_id, {Globals.ResourceType.GOLD: total_cost})

	var trade_id = "buy_%s_%d_%d" % [city_id, resource_type, GameState.game_time]
	_trade_offers.append({
		"id": trade_id,
		"city_id": city_id,
		"type": "buy",
		"resource_type": resource_type,
		"amount": amount,
		"price_per_unit": price_per_unit,
		"filled": 0,
		"active": true
	})

	EventBus.marketplace_trade_created.emit(trade_id, city_id, resource_type, amount, price_per_unit)
	return true

func accept_offer(city_id: String, offer_id: String, fill_amount: int) -> bool:
	var offer = null
	for o in _trade_offers:
		if o.id == offer_id and o.active:
			offer = o
			break

	if not offer:
		return false

	if offer.city_id == city_id:
		return false

	var actual = mini(fill_amount, offer.amount - offer.filled)
	if actual <= 0:
		return false

	if offer.type == "sell":
		var total_cost = actual * offer.price_per_unit
		if not EconomyManager.can_afford(city_id, {Globals.ResourceType.GOLD: total_cost}):
			return false
		EconomyManager.deduct_costs(city_id, {Globals.ResourceType.GOLD: total_cost})
		EconomyManager.add_resources(city_id, offer.resource_type, actual)
		var seller_city = GameState.current_cities.get(offer.city_id)
		if seller_city:
			var resources = seller_city.get("resources", {})
			resources[Globals.ResourceType.GOLD] = resources.get(Globals.ResourceType.GOLD, 0.0) + total_cost
	else:
		if not EconomyManager.can_afford(city_id, {offer.resource_type: actual}):
			return false
		EconomyManager.deduct_costs(city_id, {offer.resource_type: actual})
		EconomyManager.add_resources(city_id, Globals.ResourceType.GOLD, actual * offer.price_per_unit)
		var buyer = GameState.current_cities.get(offer.city_id)
		if buyer:
			buyer["resources"][offer.resource_type] = buyer.get("resources", {}).get(offer.resource_type, 0.0) + actual

	offer.filled += actual
	if offer.filled >= offer.amount:
		offer.active = false
		EventBus.marketplace_trade_completed.emit(offer_id, offer.city_id)

	return true

func process_tick() -> void:
	for city_id in GameState.current_cities:
		if _should_merchant_visit(city_id):
			_spawn_merchant(city_id)

	_process_merchant_visits()

func _should_merchant_visit(city_id: String) -> bool:
	var city = GameState.current_cities.get(city_id)
	if not city:
		return false

	if not _merchant_timers.has(city_id):
		_merchant_timers[city_id] = randf_range(60.0, BASE_MERCHANT_VISIT_INTERVAL)

	_merchant_timers[city_id] -= 1.0

	if _merchant_timers[city_id] <= 0.0:
		var has_marketplace = false
		for pos in city.get("buildings", {}):
			if city["buildings"][pos].get("id") == "marketplace" and city["buildings"][pos].get("constructed", false):
				has_marketplace = true
				break

		if has_marketplace:
			_merchant_timers[city_id] = BASE_MERCHANT_VISIT_INTERVAL + randf_range(-MERCHANT_VISIT_VARIANCE, MERCHANT_VISIT_VARIANCE)
			return true

		_merchant_timers[city_id] = 30.0

	return false

func _spawn_merchant(city_id: String) -> void:
	var tmpl = MERCHANT_TEMPLATES[randi() % MERCHANT_TEMPLATES.size()]
	var merchant_id = "merchant_%s_%d" % [city_id, GameState.game_time]

	var quantity = int(randf_range(tmpl.qty.x, tmpl.qty.y))
	var offered_resource = tmpl.offered[randi() % tmpl.offered.size()]
	var wanted_resource = tmpl.wanted[randi() % tmpl.wanted.size()]

	var gold_price = Globals.MARKETPLACE_RATIOS.get(offered_resource, 1.0) * quantity * tmpl.mod * PROFIT_MARGIN

	_active_merchants[merchant_id] = {
		"id": merchant_id,
		"city_id": city_id,
		"name": tmpl.name,
		"offered_resource": offered_resource,
		"offered_amount": quantity,
		"wanted_resource": wanted_resource,
		"wanted_amount": int(quantity * 0.5),
		"gold_price": gold_price,
		"staying_duration": 60.0 + randf_range(0, 60.0),
		"staying_remaining": 60.0 + randf_range(0, 60.0),
		"expired": false
	}

	EventBus.marketplace_merchant_arrived.emit(city_id, offered_resource, quantity)

func _process_merchant_visits() -> void:
	var expired = []
	for merchant_id in _active_merchants:
		var merchant = _active_merchants[merchant_id]
		merchant.staying_remaining -= 1.0
		if merchant.staying_remaining <= 0.0:
			merchant.expired = true
			expired.append(merchant_id)

	for merchant_id in expired:
		_active_merchants.erase(merchant_id)

func trade_with_merchant(city_id: String, merchant_id: String, use_gold: bool = true) -> bool:
	var merchant = _active_merchants.get(merchant_id)
	if not merchant or merchant.expired:
		return false

	if merchant.city_id != city_id:
		return false

	if use_gold:
		if not EconomyManager.can_afford(city_id, {Globals.ResourceType.GOLD: merchant.gold_price}):
			return false
		EconomyManager.deduct_costs(city_id, {Globals.ResourceType.GOLD: merchant.gold_price})
		EconomyManager.add_resources(city_id, merchant.offered_resource, merchant.offered_amount)
	else:
		if not EconomyManager.can_afford(city_id, {merchant.wanted_resource: merchant.wanted_amount}):
			return false
		EconomyManager.deduct_costs(city_id, {merchant.wanted_resource: merchant.wanted_amount})
		EconomyManager.add_resources(city_id, merchant.offered_resource, merchant.offered_amount)

	merchant.expired = true
	_active_merchants.erase(merchant_id)
	return true

func get_merchants_at_city(city_id: String) -> Array:
	var result = []
	for merchant_id in _active_merchants:
		var merchant = _active_merchants[merchant_id]
		if merchant.city_id == city_id and not merchant.expired:
			result.append(merchant)
	return result

func get_active_offers() -> Array:
	return _trade_offers.filter(func(o): return o.active)

func get_offers_for_resource(resource_type: int) -> Array:
	return _trade_offers.filter(func(o): return o.active and o.resource_type == resource_type)

func _get_city_offer_count(city_id: String) -> int:
	var count = 0
	for offer in _trade_offers:
		if offer.city_id == city_id and offer.active:
			count += 1
	return count

func cancel_offer(offer_id: String) -> bool:
	for offer in _trade_offers:
		if offer.id == offer_id and offer.active:
			offer.active = false
			var remaining = offer.amount - offer.filled
			if remaining > 0 and offer.type == "sell":
				EconomyManager.add_resources(offer.city_id, offer.resource_type, remaining)
			elif remaining > 0 and offer.type == "buy":
				var refund = remaining * offer.price_per_unit
				EconomyManager.add_resources(offer.city_id, Globals.ResourceType.GOLD, refund)
			return true
	return false
