@icon("res://Assets/Icons/NodesIcons/Multiple Choice.svg")
class_name ChoiceNode
extends MonologueGraphNode

const arrow_texture01 = preload("res://Assets/Icons/NodesIcons/Arrow01.svg")
const arrow_texture02 = preload("res://Assets/Icons/NodesIcons/Arrow02.svg")

@export var option_reference: PackedScene

var options := []

func _ready():
	node_type = "NodeChoice"
	title = node_type
	
	if options.size() <= 0:
		for _i in 2:
			var opt_ref: OptionReference = option_reference.instantiate()
			add_child(opt_ref)
			options.append(opt_ref._to_dict())
	
	_update()

func _to_dict() -> Dictionary:
	return {
		"$type": node_type,
		"ID": id,
		"OptionsID": get_all_options_id(),
		"EditorPosition": {
			"x": position_offset.x,
			"y": position_offset.y
		}
	}

func _from_dict(dict):
	id = dict.get("ID")
	options.clear()
	
	var nodes = get_parent().data.get("ListNodes")
	for option in dict.get("OptionsID"):
		for node in nodes:
			if node.get("ID") in option:
				options.append(node)
	
	_update()

func get_all_options_id() -> Array:
	var ids := []
	for child in get_children():
		if child is not OptionReference: continue
		if is_instance_of(child, PanelContainer) and child.id != null:
			ids.append(child.id)
	return ids

func get_graph_node(node_id: String) -> MonologueGraphNode:
	for node in get_parent().get_children():
		if node is not MonologueGraphNode: continue
		if node.id == node_id: return node
	
	return null

func _update(panel: ChoiceNodePanel = null):
	if panel != null:
		options.clear()
		for option in panel.options_container.get_children():
			if option is not OptionNode: continue
			if option.is_queued_for_deletion(): continue
			var opt_dict = option._to_dict()
			options.append(opt_dict)
	
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	for option in options:
		var new_ref = option_reference.instantiate()
		new_ref._from_dict(option)
		
		add_child(new_ref)
		new_ref.sentence_preview._text = option.get("Sentence")
		
		var is_first = get_child_count() <= 1
		set_slot(get_child_count() - 1, is_first, 0, Color("ffffff"), true, 0, Color("ffffff"), arrow_texture01, arrow_texture02, false)
		
		var next_node = get_graph_node(str(option.get("NextID")))
		if next_node:
			get_parent().connect_node(name, options.find(option), next_node.name, 0)
