## Game-side access to the loading overlay and to the parameters that were
## passed to it at export time.
class_name ILIP
extends RefCounted

const DISMISS_ON_ENGINE_LOAD := "on-engine-load"
const DISMISS_AFTER_FIRST_FRAME_DRAWN := "after-first-frame-drawn"
const DISMISS_MANUALLY := "manually"

const _PARAMS_EXPRESSION := "JSON.stringify((window.ILIP && window.ILIP.params) || {})"
const _MODE_EXPRESSION := "(window.ILIP && window.ILIP.mode) || \"on-engine-load\""
const _HIDE_EXPRESSION := "window.ILIP && window.ILIP.hide()"

static var _params: Dictionary = {}
static var _params_loaded := false

static func get_dismiss_mode() -> String:
	var bridge := _get_bridge()

	if bridge == null:
		return DISMISS_ON_ENGINE_LOAD

	var raw: Variant = bridge.call("eval", _MODE_EXPRESSION, true)

	return raw if raw is String else DISMISS_ON_ENGINE_LOAD


static func hide() -> void:
	var bridge := _get_bridge()

	if bridge == null:
		return

	bridge.call("eval", _HIDE_EXPRESSION, true)


static func get_params() -> Dictionary:
	if _params_loaded:
		return _params

	_params_loaded = true

	var bridge := _get_bridge()

	if bridge == null:
		return _params

	var raw: Variant = bridge.call("eval", _PARAMS_EXPRESSION, true)

	if not raw is String:
		return _params

	var parsed: Variant = JSON.parse_string(raw)

	if parsed is Dictionary:
		_params = parsed

	return _params


static func get_param(key: String, default: Variant = null) -> Variant:
	return get_params().get(key, default)


static func _get_bridge() -> Object:
	if not Engine.has_singleton("JavaScriptBridge"):
		return null

	return Engine.get_singleton("JavaScriptBridge")
