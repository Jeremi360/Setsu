extends Node

const HISTORY_FILE_PATH: String = "user://history.save"

signal main_is_ready
signal file_selected(path: String)

var main: Main:
	set(value):
		if !value: return
		main = value
		main_is_ready.emit()

var test_path: String
var file_dialog: FileDialog
var no_interactions: ColorRect

func _ready() -> void:
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(800, 600)
	file_dialog.wrap_controls = true
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(_on_file_selected)

func _on_file_selected(path := "") -> void:
	file_selected.emit(path)