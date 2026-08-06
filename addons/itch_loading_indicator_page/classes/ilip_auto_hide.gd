## Autoload the plugin registers, which takes the overlay down for the
## "after-first-frame-drawn" dismiss mode.
extends Node


func _ready() -> void:
	if ILIP.get_dismiss_mode() != ILIP.DISMISS_AFTER_FIRST_FRAME_DRAWN:
		return

	await RenderingServer.frame_post_draw
	ILIP.hide()
