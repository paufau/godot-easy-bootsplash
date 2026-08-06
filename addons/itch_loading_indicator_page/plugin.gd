@tool
extends EditorPlugin

const AUTOLOAD_NAME := "ILIPAutoHide"
const AUTOLOAD_SCRIPT := "classes/ilip_auto_hide.gd"

var _exporter: ILIPExportPlugin


func _enter_tree() -> void:
	_exporter = ILIPExportPlugin.new()
	add_export_plugin(_exporter)


func _exit_tree() -> void:
	remove_export_plugin(_exporter)
	_exporter = null


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, ILIPPaths.get_addon_root().path_join(AUTOLOAD_SCRIPT))


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
