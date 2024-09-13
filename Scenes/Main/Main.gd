class_name Main
extends Control

@export var graph_edit_scene: PackedScene

@export_subgroup("Plugins", "plugin_")
@export var plugin_emoji_finder: PackedScene
@export var plugin_icon_finder: PackedScene

@export_subgroup("Nodes Scenes")
@export var init_node: PackedScene
@export var sentence_node: PackedScene
@export var dice_roll_node: PackedScene
@export var choice_node: PackedScene
@export var end_node: PackedScene
@export var bridge_in_node: PackedScene
@export var bridge_out_node: PackedScene
@export var condition_node: PackedScene
@export var action_node: PackedScene
@export var comment_node: PackedScene
@export var event_node: PackedScene

@onready var tab_bar: TabBar = %TabBar
@onready var tabs: TabContainer = %Tabs
@onready var inspector_panel := %Inspector
@onready var graph_node_selecter := %GraphNodeSelector
@onready var save_button: Button = %SaveBtn
@onready var save_progress_bar: ProgressBar = %SaveProgressBar
@onready var saved_notification := %SavedNotification
@onready var test_button: Button = %TestBtn
@onready var edit_conf_btn := %EditConfBtn
@onready var add_menu_bar := %MenuBar/Add

var emoji_finder: Window
var icon_search: Window

var live_dict: Dictionary
var initial_pos := Vector2(40, 40)
var option_index := 0
var node_index := 0
var all_nodes_index := 0
var picker_mode := false
var file_menu := false

var root_node_ref
var root_dict
var picker_from_node
var picker_from_port
var picker_position

func _ready():
	Globals.main = self
	var new_root_node = init_node.instantiate()
	get_current_graph_edit().add_child(new_root_node)
	connect_graph_edit_signal(get_current_graph_edit())
	icon_search = plugin_icon_finder.instantiate()
	icon_search.hide()
	add_child.call_deferred(icon_search)
	
	emoji_finder = plugin_emoji_finder.instantiate()
	emoji_finder.hide()
	add_child.call_deferred(emoji_finder)
	saved_notification.hide()
	save_progress_bar.hide()
	$WelcomeWindow.on_recent_file = file_selected
	$WelcomeWindow.load_recent_files()
	
	$WelcomeWindow.show()
	Globals.no_interactions = $NoInteractions
	$NoInteractions.show()

func _shortcut_input(event):
	if event.is_action_pressed("Save"):
		save(false)

func get_current_graph_edit() -> GraphEdit:
	return tabs.get_child(tabs.current_tab)

func get_graph_nodes() -> Array[Node]:
	return get_current_graph_edit().get_children()

func _to_dict() -> Dictionary:
	var list_nodes := []
	save_progress_bar.max_value = get_graph_nodes().size() + 1
	
	for node in get_graph_nodes():
		if node.is_queued_for_deletion():
			continue
		list_nodes.append(node._to_dict())
		if node.node_type == "NodeChoice":
			for child in node.get_children():
				list_nodes.append(child._to_dict())
		
		save_progress_bar.value = list_nodes.size()
	
	root_dict = get_root_dict(list_nodes)
	root_node_ref = get_root_node_ref()
	
	if get_current_graph_edit().db_file_path:
		save_progress_bar.max_value += 1
		save_progress_bar.value += 1
		get_current_graph_edit().save_db()
		save_progress_bar.value += 1
		var db_file_path: String = get_current_graph_edit().db_file_path

		return {
			"EditorVersion": ProjectSettings.get_setting(
				"application/config/version", "unknown"),
			"RootNodeID": root_dict.get("ID"),
			"ListNodes": list_nodes,
			"DBFile": db_file_path,
		}
	var characters = get_current_graph_edit().speakers
	if get_current_graph_edit().speakers.size() <= 0:
		characters.append({
			"Reference": "_NARRATOR",
			"ID": 0
		})
	
	save_progress_bar.value += 1
	return {
		"EditorVersion": ProjectSettings.get_setting(
			"application/config/version", "unknown"),
		"RootNodeID": root_dict.get("ID"),
		"ListNodes": list_nodes,
		"Characters": characters,
		"Variables": get_current_graph_edit().variables
	}

func file_selected(path, open_mode):
	if not FileAccess.open(path, FileAccess.READ): return
	
	for ge in tabs.get_children():
		if ge is not GraphEdit: continue
		if ge.file_path == path: return
	
	$NoInteractions.hide()
	
	tab_bar.add_tab(path.get_file())
	tab_bar.move_tab(tab_bar.tab_count - 2, tab_bar.tab_count - 1)
	tab_bar.current_tab = tab_bar.tab_count - 2
	
	var graph_edit = get_current_graph_edit()
	graph_edit.control_node = self
	graph_edit.file_path = path
	
	$WelcomeWindow.hide()
	if open_mode == 0: # NEW
		for node in graph_edit.get_children():
			node.queue_free()
		var new_root_node = init_node.instantiate()
		graph_edit.add_child(new_root_node)
		await save(true)

	if not FileAccess.file_exists(Globals.HISTORY_FILE_PATH):
		FileAccess.open(Globals.HISTORY_FILE_PATH, FileAccess.WRITE)
	else:
		var file: FileAccess = FileAccess.open(Globals.HISTORY_FILE_PATH, FileAccess.READ_WRITE)
		var raw_data = file.get_as_text()
		var data: Array
		if raw_data:
			data = JSON.parse_string(raw_data)
			data.erase(path)
			data.insert(0, path)
		else:
			data = [path]
		for p in data:
			if FileAccess.file_exists(p):
				continue
			data.erase(p)
		file = FileAccess.open(Globals.HISTORY_FILE_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(data.slice(0, 10)))
	
	load_project(path)

func get_root_dict(nodes):
	for node in nodes:
		if node.get("$type") == "NodeRoot":
			return node

func get_root_node_ref():
	for node in get_graph_nodes():
		if (!node.is_queued_for_deletion()
			and node.id == root_dict.get("ID")):
			return node

func save(quick: bool = false):
	save_progress_bar.value = 0
	save_progress_bar.show()
	save_button.hide()
	test_button.hide()
	
	var data = JSON.stringify(_to_dict(), "\t", false, true)
	if not data: # Fail to load
		save_progress_bar.hide()
		save_button.show()
		test_button.show()
	
	var file = FileAccess.open(
		get_current_graph_edit().file_path, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	
	saved_notification.show()
	if !quick:
		await get_tree().create_timer(1.5).timeout
	saved_notification.hide()
	save_progress_bar.hide()
	save_button.show()
	test_button.show()

func alert(message: String):
	$AcceptDialog.dialog_text = message
	$AcceptDialog.show()
	await $AcceptDialog.confirmed

func load_project(path):
	if not FileAccess.file_exists(path):
		return
		
	$NoInteractions.hide()
	var graph_edit = get_current_graph_edit()
	
	var file := FileAccess.get_file_as_string(path)
	graph_edit.name = path.get_file().trim_suffix(".json")
	
	var data := {}
	data = JSON.parse_string(file)
	if not data:
		data = _to_dict()
		save(true)
	
	live_dict = data
	if "DBFile" in data:
		var db_file := data["DBFile"] as String
		# alert("DBFile: %s" % db_file)
		get_current_graph_edit().load_db(db_file)
	else:
		# alert("DBFile: null")
		graph_edit.speakers = data.get("Characters")
		graph_edit.variables = data.get("Variables")
	
	# alert("loaded db: %s" % graph_edit_scene.db_to_dict())
	
	for node in graph_edit.get_children():
		node.queue_free()
	
	graph_edit.clear_connections()
	graph_edit.data = data
	
	var node_list = data.get("ListNodes")
	root_dict = get_root_dict(node_list)
	
	for node in node_list:
		var new_node
		match node.get("$type"):
			"NodeRoot":
				new_node = init_node.instantiate()
			"NodeSentence":
				new_node = sentence_node.instantiate()
			"NodeChoice":
				new_node = choice_node.instantiate()
			"NodeDiceRoll":
				new_node = dice_roll_node.instantiate()
			"NodeEndPath":
				new_node = end_node.instantiate()
			"NodeBridgeIn":
				new_node = bridge_in_node.instantiate()
			"NodeBridgeOut":
				new_node = bridge_out_node.instantiate()
			"NodeCondition":
				new_node = condition_node.instantiate()
			"NodeAction":
				new_node = action_node.instantiate()
			"NodeComment":
				new_node = comment_node.instantiate()
			"NodeEvent":
				new_node = event_node.instantiate()
		
		if not new_node:
			continue
		new_node.id = node.get("ID")
		
		graph_edit.add_child(new_node)
		new_node._from_dict(node)
	
	for node in node_list:
		if not node.has("ID"):
			continue
		
		var current_node = get_node_by_id(node.get("ID"))
		match node.get("$type"):
			"NodeRoot", "NodeSentence", "NodeBridgeOut", "NodeAction", "NodeEvent":
				if node.get("NextID") is String:
					var next_node = get_node_by_id(node.get("NextID"))
					graph_edit.connect_node(current_node.name, 0, next_node.name, 0)
			"NodeChoice":
				current_node._update()
			"NodeDiceRoll":
				if node.get("PassID") is String:
					var pass_node = get_node_by_id(node.get("PassID"))
					graph_edit.connect_node(current_node.name, 0, pass_node.name, 0)
				
				if node.get("FailID") is String:
					var fail_node = get_node_by_id(node.get("FailID"))
					graph_edit.connect_node(current_node.name, 1, fail_node.name, 0)
			"NodeCondition":
				if node.get("IfNextID") is String:
					var if_node = get_node_by_id(node.get("IfNextID"))
					graph_edit.connect_node(current_node.name, 0, if_node.name, 0)
				
				if node.get("ElseNextID") is String:
					var else_node = get_node_by_id(node.get("ElseNextID"))
					graph_edit.connect_node(current_node.name, 1, else_node.name, 0)
		
		if not current_node: # OptionNode
			continue
		
		if node.has("EditorPosition"):
			current_node.position_offset.x = node.EditorPosition.get("x")
			current_node.position_offset.y = node.EditorPosition.get("y")
			
	root_node_ref = get_root_node_ref()
	
	if not root_node_ref:
		var new_root_node = init_node.instantiate()
		get_current_graph_edit().add_child(new_root_node)
		
		save(true)
		root_node_ref = get_root_node_ref()

func get_node_by_id(id):
	for node in get_graph_nodes():
		if node is not MonologueGraphNode: continue
		if node.id == id: return node
	return null

func get_options_nodes(node_list, options_id):
	var options = []
	
	for node in node_list:
		if node.get("ID") in options_id:
			options.append(node)
	return options

###############################
#  New node buttons callback  #
###############################
func center_node_in_graph_edit(node):
	var graph_edit = get_current_graph_edit()
	if picker_mode:
		node.position_offset = picker_position
		graph_edit.connect_node(picker_from_node, picker_from_port, node.name, 0)
		disable_picker_mode()
		return
	
	node.position_offset = ((graph_edit.size / 2) + graph_edit.scroll_offset) / graph_edit.zoom

func _on_add_id_pressed(id):
	var node_type = add_menu_bar.get_item_text(id)
	add_node(node_type)

func add_node(node_type):
	if node_type == "Bridge":
		var number = get_current_graph_edit().get_free_bridge_number()
	
		var in_node = bridge_in_node.instantiate()
		var out_node = bridge_out_node.instantiate()
		
		get_current_graph_edit().add_child(in_node)
		get_current_graph_edit().add_child(out_node)
		
		in_node.number_selector.value = number
		out_node.number_selector.value = number
		
		center_node_in_graph_edit(in_node)
		center_node_in_graph_edit(out_node)
		in_node.position_offset.x -= in_node.size.x / 2 + 10
		out_node.position_offset.x += out_node.size.x / 2 + 10
		
	var node
	match node_type:
		"Sentence":
			node = sentence_node
		"Choice":
			node = choice_node
		"DiceRoll":
			node = dice_roll_node
		"Condition":
			node = condition_node
		"Action":
			node = action_node
		"EndPath":
			node = end_node
		"Event":
			node = event_node
		"Comment":
			node = comment_node
	
	if not node:
		return
	
	node = node.instantiate()
	get_current_graph_edit().add_child(node)
	center_node_in_graph_edit(node)
	
func _on_graph_edit_connection_request(from, from_slot, to, to_slot):
	if get_current_graph_edit().get_all_connections_from_slot(from, from_slot).size() <= 0:
		get_current_graph_edit().connect_node(from, from_slot, to, to_slot)

func _on_graph_edit_disconnection_request(from, from_slot, to, to_slot):
	get_current_graph_edit().disconnect_node(from, from_slot, to, to_slot)

func test_project(from_selected_node: bool = false):
	await save(true)
	
	var global_vars = get_node("/root/GlobalVariables")
	global_vars.test_path = get_current_graph_edit().file_path
	
	var test_instance = preload("res://Test/Menu.tscn")
	var test_scene = test_instance.instantiate()
	
	if from_selected_node:
		test_scene._from_node_id = inspector_panel.current_panel.id
	
	get_tree().root.add_child(test_scene)

####################
#  File selection  #
####################
func new_file_select():
	$FileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$FileDialog.title = "Create New File"
	$FileDialog.ok_button_text = "Create"
	$FileDialog.popup_centered()
	var new_file_path = await $FileDialog.file_selected
	if new_file_path:
		FileAccess.open(new_file_path, FileAccess.WRITE)
		return new_file_path
	return null

func open_file_select():
	$FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	$FileDialog.title = "Open File"
	$FileDialog.ok_button_text = "Open"
	$FileDialog.popup_centered()
	var open_file = await $FileDialog.file_selected
	if open_file: return open_file
	return null

func _on_graph_edit_connection_to_empty(from_node, from_port, _release_position):
	graph_node_selecter.position = get_viewport().get_mouse_position()
	graph_node_selecter.show()
	
	picker_from_node = from_node
	picker_from_port = from_port
	picker_position = (get_local_mouse_position() + get_current_graph_edit().scroll_offset) / get_current_graph_edit().zoom
	
	picker_mode = true
	$NoInteractions.show()

func disable_picker_mode():
	graph_node_selecter.hide()
	picker_mode = false
	$NoInteractions.hide()

func _on_graph_node_selecter_focus_exited():
	disable_picker_mode()

func _on_graph_node_selecter_close_requested():
	disable_picker_mode()

func tab_changed(_idx):
	inspector_panel.hide()
	if get_current_tab_name() != "+":
		for ge in tabs.get_children():
			ge.visible = tabs.get_child(
				tab_bar.current_tab) == ge
			
		return
	
	new_graph_edit()
	$WelcomeWindow.show()
	$NoInteractions.show()

func connect_graph_edit_signal(graph_edit: GraphEdit) -> void:
	graph_edit.connect("connection_to_empty", _on_graph_edit_connection_to_empty)
	graph_edit.connect("connection_request", _on_graph_edit_connection_request)
	graph_edit.connect("disconnection_request", _on_graph_edit_disconnection_request)
	graph_edit.connect("node_selected", inspector_panel.on_graph_node_selected)
	graph_edit.connect("node_deselected", inspector_panel.on_graph_node_deselected)

func tab_close_pressed(tab):
	tabs.get_child(tab).queue_free()
	tab_bar.remove_tab(tab)
	tab_changed(tab)

func _on_file_id_pressed(id):
	file_menu = true
	match id:
		0: # Open file
			var new_file_path = await open_file_select()
			if new_file_path == null:
				return
				
			new_graph_edit()
			return await file_selected(new_file_path, 1)
		1: # New file
			var new_file_path = await new_file_select()
			if new_file_path == null:
				return
			
			new_graph_edit()
			return await file_selected(new_file_path, 0)
		
		2: # Save
			save()
			return

func new_graph_edit():
	var graph_edit: GraphEdit = graph_edit_scene.instantiate()
	var new_root_node = init_node.instantiate()
	
	graph_edit.name = "new"
	connect_graph_edit_signal(graph_edit)
	
	tabs.add_child(graph_edit)
	graph_edit.add_child(new_root_node)
	
	for ge in tabs.get_children():
		ge.visible = ge == graph_edit

func _on_new_file_btn_pressed():
	$WelcomeWindow.hide()
	var new_file_path = await new_file_select()
	if new_file_path == null:
		$WelcomeWindow.show()
		return
		
	return await file_selected(new_file_path, 0)

func _on_open_file_btn_pressed():
	$WelcomeWindow.hide()
	var new_file_path = await open_file_select()
	if new_file_path == null:
		$WelcomeWindow.show()
		return
		
	return await file_selected(new_file_path, 1)

func _on_help_id_pressed(id):
	match id:
		0:
			OS.shell_open("https://github.com/atomic-junky/Monologue/wiki")
		1:
			OS.shell_open("https://rakugoteam.github.io/advanced-text-docs/2.0/Markdown/")

func _on_file_dialog_canceled():
	if file_menu:
		file_menu = false
		return
	
	$WelcomeWindow.show()

func _on_cancel_file_btn_pressed():
	$WelcomeWindow.hide()
	$NoInteractions.hide()
	if get_current_tab_name() == "+":
		tab_bar.current_tab -= 1

func _on_emojis_btn_pressed():
	emoji_finder.popup_centered()

func _on_icons_btn_pressed():
	icon_search.popup_centered()

func get_current_tab_name() -> String:
	return tab_bar.get_tab_title(tab_bar.current_tab)

func _on_edit_conf_btn_toggled(toggled_on):
	if toggled_on: inspector_panel.show_config()
	else: inspector_panel.hide()

func _on_node_selected(node):
	edit_conf_btn.button_pressed = (
		node.node_type == "NodeRoot"
	)

func _on_close_node_btn_pressed():
	edit_conf_btn.button_pressed = false
