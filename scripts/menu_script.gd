extends Control

@onready var global_var = get_node("/root/GlobalVar")

var player1sSymbol = 1
@onready var player1Symbol_sprite = $VBoxContainer/HBoxContainer/MenuRight/VBoxContainer/Player1Info/HBoxContainer/AspectRatioContainer/Sprite2D
@onready var player2Symbol_sprite = $VBoxContainer/HBoxContainer/MenuRight/VBoxContainer/Player2Info/HBoxContainer/AspectRatioContainer/Sprite2D

var player2isAI = false
@onready var player2isAI_check = $VBoxContainer/HBoxContainer/MenuRight/VBoxContainer/Player2Info/CheckBox

@onready var slider = $VBoxContainer/HBoxContainer/CenterContainer/MenuLeft/MarginContainer/VBoxContainer/MarginContainer/HSlider
@onready var bouton_jouer = $VBoxContainer/HBoxContainer/CenterContainer/MenuLeft/MarginContainer/VBoxContainer/ButtonJouer


@onready var instruction_container = $Instructions

## Initialisation du menu à partir des données globales
func _ready():
	instruction_container.hide()
	
	player1sSymbol = global_var.player1sSymbol
	player1Symbol_sprite.frame = player1sSymbol
	player2Symbol_sprite.frame = 2-player1sSymbol+1
	
	player2isAI_check.button_pressed = global_var.player2isAI
	
	slider.value = global_var.board_size
	slider.tick_count = slider.max_value - slider.min_value + 1
	bouton_jouer.text = "Nouvelle Partie " + str(slider.value) + "*" + str(slider.value)


## Adapte le label au slider
func _on_h_slider_value_changed(value):
	bouton_jouer.text = "Nouvelle Partie " + str(slider.value) + "*" + str(slider.value)

## Echange les symboles des joueurs lors de la détection d'un clique du bouton switch
func _on_button_switch_pressed():
	player2Symbol_sprite.frame = player1sSymbol
	player1sSymbol = 2-player1sSymbol+1
	player1Symbol_sprite.frame = player1sSymbol


## Ferme la fenêtre si le bouton quitter est pressé
func _on_button_quitter_pressed():
	get_tree().quit()


## Créé une nouvelle partie, transmet les données au singleton global
func _on_button_jouer_pressed():
	global_var.board_size = slider.value
	global_var.player1sSymbol = player1sSymbol
	global_var.player2isAI = player2isAI_check.button_pressed
	get_tree().change_scene_to_file("res://scenes/ihm.tscn")


# Affiche les instructions
func _on_button_instructions_pressed():
	instruction_container.show()


# Ferme les instructions
func _on_button_fermer_pressed():
	instruction_container.hide()


## Permet de mettre à l'échelle l'image de fond
## Seule manière trouvée pour avoir l'effet recherché 
func _on_item_rect_changed():
	var val = max(size.y / $TextureRect.size.y, size.x/2  / $TextureRect.size.x)
	$TextureRect.scale = Vector2(val, val)
	$TextureRect.position.y = -($TextureRect.size.y*val - size.y)/2 if $TextureRect.size.y*val > size.y else 0
