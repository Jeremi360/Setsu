@icon("res://graphics/icons/code-commit-solid.svg")
class_name RakuNode
extends GraphNode

enum {
	Unknown,
	Comment,
	Init,
	Exit,
	Menu,
	Dialogue,
	CharaterDef,
	Say,
	Ask,
	Choice,
	Jump,
	SetVariable,
	# ...
}

@export var type := Unknown

var id := ResourceUID.create_id()
var next_node_id: int


func to_raku() -> String:
	return "# unsported node type %s" % str(type)

func from_raku(expression: String) -> void:
	pass

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": str(type),
		"raku": to_raku(),
		"next_node": next_node_id,
		"pos": position,
	}

func _from_dict(dict: Dictionary) -> void:
	id = dict.id
	next_node_id = dict.next_node
	position = dict.pos
	from_raku(dict.raku)

func _on_node_selected() -> void:
	pass
