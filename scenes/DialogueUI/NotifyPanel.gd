@tool
extends ProcentControl
class_name NotificationPanel

@export var notification_label : AdvancedTextLabel = null

@export_subgroup("Time")
@export var timer : Timer = null
@export var default_notification_time := 0.5

var markup : TextParser

signal notif_ready

func _ready():
	markup = load(VisualNovelKit.default_markup_setting)
	notification_label.parser = markup
	timer.one_shot = true
	visible = Engine.is_editor_hint()

	if !Engine.is_editor_hint():
		Rakugo.add_custom_regex("notification",
			"^notif( +({NUMERIC}) *)? *: *({STRING})$")
		Rakugo.sg_custom_regex.connect(_on_custom_regex)

func _on_custom_regex(key:String, result:RegExMatch):
	match key:
		"notification":
			var text := result.get_string(3)
			text = Rakugo.parser.treat_string(text)
			notification_label._text = text
			var time := default_notification_time
			if result.get_string(2):
				time = float(result.get_string(2))
			
			if !visible: show()
			notif_ready.emit()
			
			timer.start(time)
			await timer.timeout
			hide()



