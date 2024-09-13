@tool
class_name Tester
extends Panel

func _on_visibility_changed() -> void:
	$Game/GUI.visible = visible
	# if Engine.is_editor_hint(): return
	# $Game.get_tree().paused = !visible
