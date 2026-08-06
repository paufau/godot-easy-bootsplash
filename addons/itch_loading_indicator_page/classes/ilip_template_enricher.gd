## Fills a loading screen template with values.
class_name ILIPTemplateEnricher
extends RefCounted


const TOKEN_PATTERN := "\\{\\{(\\w+)\\}\\}"


## Replaces every {{KEY}} in one left-to-right pass
static func render(text: String, values: Dictionary) -> String:
	var tokens := RegEx.create_from_string(TOKEN_PATTERN)
	var rendered := ""
	var at := 0
	var found := tokens.search(text, at)

	while found != null:
		rendered += text.substr(at, found.get_start() - at)
		rendered += get_text(values.get(found.get_string(1)))
		at = found.get_end()
		found = tokens.search(text, at)

	return rendered + text.substr(at)


static func get_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return ""
		TYPE_FLOAT:
			if value == floor(value) and absf(value) < 1e15:
				return str(int(value))
		TYPE_ARRAY, TYPE_DICTIONARY:
			return JSON.stringify(value)

	return str(value)
