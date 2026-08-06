class_name ILIPPaths
extends RefCounted

const PUBLIC_DIR := "public"
const ASSETS_DIR := "assets"
const ROOT_MARKER := "plugin.cfg"

static var _root := ""


## The addon's own directory, as a res://...
static func get_addon_root() -> String:
	if not _root.is_empty():
		return _root

	var script: Script = ILIPPaths

	_root = script.resource_path.get_base_dir().get_base_dir()

	if not FileAccess.file_exists(_root.path_join(ROOT_MARKER)):
		push_error("ILIP: %s holds no %s, so %s is not where it is expected to be." % [
			_root,
			ROOT_MARKER,
			script.resource_path
		])

	return _root


## A file the addon ships in public/, as a res://...
static func get_public_path(file: String) -> String:
	return get_addon_root().path_join(PUBLIC_DIR).path_join(file)


static func get_public_absolute_path(file: String) -> String:
	return ProjectSettings.globalize_path(get_public_path(file))


static func get_assets_path() -> String:
	return get_addon_root().path_join(ASSETS_DIR)


static func get_absolute_path(path: String) -> String:
	path = ResourceUID.ensure_path(path)

	# An unresolvable uid comes back empty and must not reach the relative branch
	if path.is_empty():
		return ""

	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)

	if path.is_absolute_path():
		return path

	return ProjectSettings.globalize_path("res://").path_join(path)
