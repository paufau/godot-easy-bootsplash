## Writes the loading screen into a finished web export.
class_name EBSOutput
extends RefCounted

# MinimizeHTMLBuild and friends may run first and strip quotes and optional tags,
# so the anchor has to match a raw shell and a minified one alike
const ANCHORS: PackedStringArray = ["<canvas", "</body>", "</html>"]

## Absolute path of the directory the shell was exported into
var directory := ""


func _init(export_directory: String) -> void:
	directory = export_directory


func copy_tree(source: String, subdirectory: String) -> String:
	var destination := directory.path_join(subdirectory)

	if (destination.simplify_path() + "/").begins_with(source.simplify_path() + "/"):
		push_error("EBS: %s contains the export directory, so no assets were copied." % source)
		return ""

	# Delete everything to remove stale files and re-export new files
	_remove_tree(destination)

	if _copy_tree(source, destination):
		return subdirectory

	return ""


static func _remove_tree(path: String) -> void:
	if not path.is_absolute_path():
		push_error("EBS: refusing to clear %s, which is not an absolute path." % path)
		return

	var dir := DirAccess.open(path)

	if dir == null:
		return

	for name in dir.get_directories():
		_remove_tree(path.path_join(name))

	for name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(name))

	DirAccess.remove_absolute(path)


func _copy_tree(source: String, target: String) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(target)

	if error != OK:
		push_error("EBS: cannot create %s (error %d)." % [target, error])
		return false

	var dir := DirAccess.open(source)

	if dir == null:
		push_error("EBS: cannot read %s." % source)
		return false

	for name in dir.get_directories():
		if name.begins_with("."):
			continue

		if not _copy_tree(source.path_join(name), target.path_join(name)):
			return false

	for name in dir.get_files():
		# Import metadata belongs to the editor, not to the exported page.
		if name.begins_with(".") or name.get_extension().to_lower() == "import":
			continue

		error = DirAccess.copy_absolute(source.path_join(name), target.path_join(name))

		if error != OK:
			push_error("EBS: failed to copy %s (error %d)." % [source.path_join(name), error])
			return false

	return true


func inject(html_path: String, runtime: String, parameters: Dictionary, body: String, mode: String) -> bool:
	var html := FileAccess.get_file_as_string(html_path)

	if html.is_empty():
		push_error("EBS: cannot read %s." % html_path)
		return false

	for anchor in ANCHORS:
		var at := html.find(anchor)

		if at != -1:
			write(html_path, html.insert(at, _get_payload(runtime, parameters, body, mode)))
			return true

	push_error(
		"EBS: none of %s were found in %s, the loading screen was skipped. A custom HTML shell has to keep one of them."
		% [", ".join(ANCHORS), html_path]
	)

	return false


static func write(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		push_error("EBS: cannot write %s." % path)
		return

	file.store_string(content)
	file.close()


## The block that goes into the shell: runtime, parameters, rendered template
func _get_payload(runtime: String, parameters: Dictionary, body: String, mode: String) -> String:
	var config := ""

	if mode != EBS.DISMISS_ON_ENGINE_LOAD:
		config = "window.EBS.mode=%s;" % _get_js_string(mode)

	return "<script>\n%s</script>\n<script>window.EBS.params=JSON.parse(%s);%s</script>\n%s\n" % [
		runtime,
		_get_js_string(JSON.stringify(parameters)),
		config,
		body
	]


## Turns a string into a JS literal. The closing tag is broken up too, or a value
## containing "</script>" would end the surrounding element.
static func _get_js_string(text: String) -> String:
	return JSON.stringify(text).replace("</", "<\\/")
