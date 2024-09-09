extends VBoxContainer
class_name Inspector

@onready var line_edit_id = %LineEditID
@onready var panel_container = %PanelContainer
@onready var main := Globals.main

@export_subgroup("Inspector Scenes", "inspector_scene_")
@export var inspector_scene_init: PackedScene
@export var inspector_scene_sentence: PackedScene
@export var inspector_scene_choice: PackedScene
@export var inspector_scene_dice_roll: PackedScene
@export var inspector_scene_end_path: PackedScene
@export var inspector_scene_condition: PackedScene
@export var inspector_scene_action: PackedScene

var selected_node = null
var current_panel = null

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

func clear_current_panel():
	if current_panel:
		current_panel.queue_free()
		current_panel = null

func on_graph_node_selected(node):
	var graph_edit = main.get_current_graph_edit()
	await get_tree().create_timer(0.1).timeout
	
	if graph_edit.selected_nodes != [node]: return
	
	line_edit_id.text = node.id

	var new_panel = null
	match node.node_type:
		"NodeRoot":
			new_panel = inspector_scene_init.instantiate()
		"NodeSentence":
			new_panel = inspector_scene_sentence.instantiate()
		"NodeChoice":
			new_panel = inspector_scene_choice.instantiate()
		"NodeDiceRoll":
			new_panel = inspector_scene_dice_roll.instantiate()
		"NodeEndPath":
			new_panel = inspector_scene_end_path.instantiate()
		"NodeCondition":
			new_panel = inspector_scene_condition.instantiate()
		"NodeAction":
			new_panel = inspector_scene_action.instantiate()
		"NodeEvent":
			new_panel = inspector_scene_condition.instantiate()
	
	if new_panel == null: return
	
	clear_current_panel()
	
	new_panel.graph_node = node
	
	if new_panel:
		current_panel = new_panel
		panel_container.add_child(new_panel)
		new_panel._from_dict(node._to_dict())
		
	show()

func _on_texture_button_pressed():
	hide()

func show_config():
	clear_current_panel()
	
	var root_node = main.root_node_ref
	root_node.selected = true

	var new_panel = inspector_scene_init.instantiate()
	new_panel.graph_node = root_node
	current_panel = new_panel
	
	panel_container.add_child(new_panel)
	new_panel._from_dict(root_node._to_dict())
	
	line_edit_id.text = root_node.id
	
	show()

func _on_graph_edit_child_exiting_tree(_node):
	hide()

func on_graph_node_deselected(_node):
	hide()

func _on_line_edit_id_text_changed(new_id):
	if main.get_node_by_id(new_id):
		line_edit_id.text = current_panel.id
		return
	
	current_panel.id = new_id
	current_panel.change.emit(current_panel)
