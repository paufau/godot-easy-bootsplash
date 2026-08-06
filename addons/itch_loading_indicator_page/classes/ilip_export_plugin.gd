@tool
class_name ILIPExportPlugin
extends EditorExportPlugin

# Which files the addon wants; ILIPPaths decides where they live.
const TEMPLATE_NAME := "default_template.html"
const RUNTIME_NAME := "runtime.js"

# Godot names its own web output index.*, so the copy gets a name of its own.
const ASSETS_DIRNAME := "ilip_assets"

const OPTION_ENABLED := "itch_loading_indicator_page/enabled"
const OPTION_DISMISS := "itch_loading_indicator_page/dismiss"
const OPTION_TEMPLATE := "itch_loading_indicator_page/template"
const OPTION_PARAMETERS := "itch_loading_indicator_page/parameters"
const OPTION_ASSETS := "itch_loading_indicator_page/assets"

const BACKGROUND_BASENAME := "background"
const IMAGE_EXTENSIONS: PackedStringArray = ["gif", "png", "webp", "jpg", "jpeg", "avif", "svg"]

const DEFAULT_PARAMETERS := {
	"background_color": "#5F5F5F",
	"fit": "centered",
	"progress_hidden": false,
	"progress_placement": "below",
	"progress_width": "min(50vw, 360px)",
	"progress_height": "10px",
	"progress_color": "#FF244A",
	"track_color": "rgba(255, 255, 255, 0.9)"
}

const HTML_EXTENSIONS: PackedStringArray = ["html", "htm"]

var _html_path := ""


func _get_name() -> String:
	return "Itch Loading Indicator Page"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformWeb


func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
	if not _supports_platform(platform):
		return []

	return [
		{
			"option": {
				"name": OPTION_ENABLED,
				"type": TYPE_BOOL
			},
			"default_value": true
		},
		{
			"option": {
				"name": OPTION_DISMISS,
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "On Engine Load,After First Frame Drawn,Manually"
			},
			"default_value": 1
		},
		{
			"option": {
				"name": OPTION_TEMPLATE,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_FILE,
				"hint_string": "*.html,*.htm"
			},
			"default_value": ILIPPaths.get_public_path(TEMPLATE_NAME)
		},
		{
			"option": {
				"name": OPTION_PARAMETERS,
				"type": TYPE_DICTIONARY
			},
			"default_value": DEFAULT_PARAMETERS.duplicate()
		},
		{
			"option": {
				"name": OPTION_ASSETS,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_DIR
			},
			"default_value": ILIPPaths.get_assets_path()
		}
	]


func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	var exports_shell := HTML_EXTENSIONS.has(path.get_extension().to_lower())
	_html_path = ILIPPaths.get_absolute_path(path) if features.has("web") and exports_shell else ""


func _export_end() -> void:
	var html_path := _html_path
	_html_path = ""

	if html_path.is_empty() or not bool(get_option(OPTION_ENABLED)):
		return

	var runtime := FileAccess.get_file_as_string(ILIPPaths.get_public_absolute_path(RUNTIME_NAME))

	if runtime.is_empty():
		push_error("ILIP: %s is missing, the loading screen was skipped." % RUNTIME_NAME)
		return

	var template_path := _get_template_path()
	var template := FileAccess.get_file_as_string(template_path)

	if template.is_empty():
		push_error("ILIP: cannot read %s, the loading screen was skipped." % template_path)
		return

	var output := ILIPOutput.new(html_path.get_base_dir())
	var parameters := _get_parameters()
	var values := _get_tokens(_copy_assets(output))

	values.merge(parameters, true)

	var body := ILIPTemplateEnricher.render(template, values)

	output.inject(html_path, runtime, parameters, body, _get_dismiss_mode())


func _get_parameters() -> Dictionary:
	var merged := DEFAULT_PARAMETERS.duplicate()
	merged.merge(_get_declared_parameters(), true)

	return merged


func _get_declared_parameters() -> Dictionary:
	var declared: Variant = get_option(OPTION_PARAMETERS)

	if not declared is Dictionary:
		push_warning("ILIP: %s holds no Dictionary, no parameters were passed." % OPTION_PARAMETERS)
		return {}

	return declared


func _get_tokens(assets_dirname: String) -> Dictionary:
	return {
		"IMAGE_SRC": _find_background(assets_dirname),
		"ASSETS_DIR": assets_dirname,
		"PROJECT_NAME": str(ProjectSettings.get_setting("application/config/name", ""))
	}


func _copy_assets(output: ILIPOutput) -> String:
	var source := _get_assets_source()

	if source.is_empty():
		return ""

	if not DirAccess.dir_exists_absolute(source):
		push_warning("ILIP: %s not found, no assets were copied." % source)
		return ""

	return output.copy_tree(source, ASSETS_DIRNAME)


func _find_background(assets_dirname: String) -> String:
	if assets_dirname.is_empty():
		return ""

	var candidates := {}

	for name in DirAccess.get_files_at(_get_assets_source()):
		if name.get_basename().to_lower() == BACKGROUND_BASENAME:
			candidates[name.get_extension().to_lower()] = name

	for extension in IMAGE_EXTENSIONS:
		if candidates.has(extension):
			return assets_dirname.path_join(candidates[extension])

	return ""


func _get_dismiss_mode() -> String:
	var modes := [
		ILIP.DISMISS_ON_ENGINE_LOAD,
		ILIP.DISMISS_AFTER_FIRST_FRAME_DRAWN,
		ILIP.DISMISS_MANUALLY
	]
	var selected := clampi(int(get_option(OPTION_DISMISS)), 0, modes.size() - 1)

	return modes[selected]


func _get_assets_source() -> String:
	var selected := str(get_option(OPTION_ASSETS)).strip_edges()
	return "" if selected.is_empty() else ILIPPaths.get_absolute_path(selected)


func _get_template_path() -> String:
	var selected := str(get_option(OPTION_TEMPLATE)).strip_edges()

	if selected.is_empty():
		return ILIPPaths.get_public_absolute_path(TEMPLATE_NAME)

	var absolute := ILIPPaths.get_absolute_path(selected)

	if not FileAccess.file_exists(absolute):
		push_warning("ILIP: %s not found, the built-in template was used instead." % selected)
		return ILIPPaths.get_public_absolute_path(TEMPLATE_NAME)

	return absolute
