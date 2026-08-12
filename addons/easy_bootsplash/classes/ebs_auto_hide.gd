## Autoload the plugin registers, which takes the overlay down for the
## "after-first-frame-drawn" dismiss mode.
extends Node


func _ready() -> void:
	if EBS.get_dismiss_mode() != EBS.DISMISS_AFTER_FIRST_FRAME_DRAWN:
		return

	await RenderingServer.frame_post_draw
	EBS.hide()
