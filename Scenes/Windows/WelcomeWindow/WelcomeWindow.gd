extends Window
class_name WelcomeWindow

@export var recent_file_button: PackedScene

var on_recent_file: Callable

func _ready():
	var version: String = ProjectSettings.get("application/config/version")
	%VersionLabel.text = "v%s" % version
	await Globals.main_is_ready
	Globals.main.resized.connect(move_to_center)

func add_recent_file_button(path: String):
	var btn: Button = recent_file_button.instantiate()
	var btn_text = path
	btn_text = path.replace("\\", "/")
	btn_text = btn_text.replace("//", "/")
	btn_text = btn_text.split("/")
	
	if btn_text.size() >= 2:
		btn_text = btn_text.slice(-2, btn_text.size())
		btn_text = btn_text[0].path_join(btn_text[1])
	else:
		btn_text = btn_text.back()

	btn.text = btn_text
	btn.pressed.connect(on_recent_file.bind(path, 1))
	%RecentFilesContainer.add_child(btn)

func load_recent_files():
	%RecentFilesContainer.hide()
	if not FileAccess.file_exists(Globals.HISTORY_FILE_PATH):
		FileAccess.open(Globals.HISTORY_FILE_PATH, FileAccess.WRITE)
		return
	
	var file := FileAccess.open(
		Globals.HISTORY_FILE_PATH, FileAccess.READ)
	var raw_data := file.get_as_text()
	if raw_data:
		var data: Array = JSON.parse_string(raw_data)
		for path in data:
			if FileAccess.file_exists(path): continue
			data.erase(path)
		for path in data.slice(0, 3):
			add_recent_file_button(path)
		%RecentFilesContainer.show()

func _on_new_file_btn_pressed() -> void:
	hide()
	Globals.file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	Globals.file_dialog.title = "Crate New Dialogue File"
	Globals.file_dialog.filters = ["*.json;Old files"]
	Globals.file_dialog.ok_button_text = "Crate"
	Globals.file_dialog.popup_centered()
	var path := await Globals.file_selected as String
	if path: Globals.main.file_selected(path, 0)
	else: show()

func _on_open_file_btn_pressed() -> void:
	hide()
	Globals.file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	Globals.file_dialog.title = "Open Dialogue File"
	Globals.file_dialog.filters = ["*.json;Old files"]
	# Globals.file_dialog.ok_button_text = "Open"
	Globals.file_dialog.popup_centered()
	var path := await Globals.file_selected as String
	if path: Globals.main.file_selected(path, 1)
	else: show()
