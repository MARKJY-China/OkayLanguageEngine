extends Control

@onready var console_font_size_spin_box: SpinBox = $PanelContainer/Control/VBoxContainer/ConsoleFontSize/SpinBox
var console_font_size = ""

func _ready() -> void:
	console_font_size = Global.get_uisettings_config("console_font_size")
	if typeof(console_font_size) != TYPE_STRING:
		console_font_size_spin_box.value = console_font_size
	else:
		console_font_size_spin_box.value = 10

func _on_back_pressed() -> void:
	hide()


func _on_okay_pressed() -> void:
	if Global.set_uisettings_config("console_font_size",console_font_size_spin_box.value) == OK:
		Global.send_output.emit("[color=green]✓[/color]修改界面设置选项并保存成功",1)
	else:
		Global.send_output.emit("[color=yellow]‣[/color]修改界面设置选项并保存失败")
	hide()
