extends Control

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
	pass # Replace with function body.
