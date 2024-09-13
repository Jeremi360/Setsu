@icon("res://graphics/icons/circle-play-solid.svg")
extends RakuNode

func from_raku(expression: String) -> void:
	pass

func _on_node_selected() -> void:
	Globals.current_node = self

func update_node() -> void:
	pass
