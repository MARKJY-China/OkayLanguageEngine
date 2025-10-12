extends Control

@onready var file_dialog: FileDialog = $"FileDialog"
@onready var c1: CheckBox = $"PanelContainer/Control/VBoxContainer/1"
@onready var c2: CheckBox = $"PanelContainer/Control/VBoxContainer/2"
@onready var c3: CheckBox = $"PanelContainer/Control/VBoxContainer/3"


func _on_back_pressed() -> void:
	hide()


func _on_c1_pressed() -> void:
	c2.button_pressed = false
	c3.button_pressed = false

func _on_c2_pressed() -> void:
	c1.button_pressed = false
	c3.button_pressed = false

func _on_c3_pressed() -> void:
	c1.button_pressed = false
	c2.button_pressed = false


func _on_create_pressed() -> void:
	file_dialog.title = "新建文件到指定位置"
	file_dialog.ok_button_text = "新建"
	file_dialog.file_mode = 4
	if c1.button_pressed:
		file_dialog.add_filter("*.txt ; 纯文本文档")
	elif c2.button_pressed:
		file_dialog.add_filter("*.okpy ; Okay中文Python文件")
	else:
		file_dialog.add_filter("*.okqt ; Okay蓝图脚本+可视化窗口文件")
	file_dialog.show()


func _on_file_dialog_file_selected(path: String) -> void:
	pass # Replace with function body.
