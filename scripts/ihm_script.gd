extends Control

enum RESULT {J1, J2, EQUAL}

@onready var global_var = get_node("/root/GlobalVar")

@onready var chronoPlayer1 = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player1Info/Timer
@onready var chronoPlayer1_label = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player1Info/Label

@onready var chronoPlayer2 = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player2Info/Timer
@onready var chronoPlayer2_label = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player2Info/Label

@onready var board = $HBoxContainer/MarginContainer/Plateau

@onready var symbol1 = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player1Info/HBoxContainer/AspectRatioContainer/Sprite2D
@onready var symbol2 = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player2Info/HBoxContainer/AspectRatioContainer/Sprite2D

@onready var pointeur1 = 	$HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player1Info/HBoxContainer/Pointeur
@onready var pointeur2 = 	$HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/Player2Info/HBoxContainer/Pointeur

@onready var button_undo = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonAnnule

@onready var end_container = $HBoxContainer/MarginContainer/PanelContainer
@onready var end_label = $HBoxContainer/MarginContainer/PanelContainer/MarginContainer/Label

@onready var menu = $HBoxContainer/PanelContainer
@onready var button_cacher = $HBoxContainer/MarginContainer/ButtonCacher

var cube_default_size = preload("res://assets/textures/Cube.png").get_height()


## Initialise l'IHM d'une partie
func _ready():
	# Premier joueur aléatoire
	board.isPlayer1sTurn = (randi_range(0,1) == 0)
	
	if !board.isPlayer1sTurn && global_var.player2isAI:
		board._on_move_played()
	
	if board.isPlayer1sTurn:
		pointeur2.visibility_layer = 0
	else:
		pointeur1.visibility_layer = 0
	
	chronoPlayer1.paused = !board.isPlayer1sTurn
	chronoPlayer2.paused = board.isPlayer1sTurn
	
	symbol1.frame = global_var.player1sSymbol
	symbol2.frame = 2 - global_var.player1sSymbol + 1
	
	symbol1.offset.y = -cube_default_size/2.0
	symbol2.offset.y = -cube_default_size/2.0
	
	board.player1sSymbol = global_var.player1sSymbol
	board.player2sSymbol = 2 - global_var.player1sSymbol + 1
	
	button_cacher.visible = true
	button_cacher.custom_minimum_size.x = button_cacher.size.y


## Incremente le compteur du joueur courant
func time_increase(chrono):
	var time_array = chrono.text.split(":")
	var minu = time_array[0].to_int()
	var sec = time_array[1].to_int()+1
	
	if sec == 60:
		sec = 0
		minu = minu+1
	
	chrono.text = "%02d:%02d" % [minu, sec]


## MAJ des compteurs des joueurs lors de la fin des timers
func _on_timerP1_timeout():
	time_increase(chronoPlayer1_label)
func _on_timerP2_timeout():
	time_increase(chronoPlayer2_label)


## Retourne au menu principal
func _on_button_retour_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


## Recharge la scène (=recommence la partie)
func _on_button_restart_pressed():
	get_tree().reload_current_scene()


## Appelée lors de la détection de l'exécution d'un mouvement de cube
## MAJ des infos des joueurs
func _on_plateau_move_played():
	if !board.ended:
		pointeur2.visibility_layer = pointeur1.visibility_layer
		pointeur1.visibility_layer = 1 - pointeur2.visibility_layer
		chronoPlayer1.paused = !chronoPlayer1.paused
		chronoPlayer2.paused = !chronoPlayer2.paused
		button_undo.disabled = false


## Appelée lors de la détection de l'annulation d'un mouvement
## MAJ des infos des joueurs
func _on_plateau_undid_previous_move(wasLastMove):
	pointeur1.visibility_layer = 1 if board.isPlayer1sTurn else 0
	pointeur2.visibility_layer = 1 if !board.isPlayer1sTurn else 0
	chronoPlayer1.paused = !board.isPlayer1sTurn
	chronoPlayer2.paused = board.isPlayer1sTurn
	button_undo.disabled = wasLastMove
	end_container.visible = false


## MAJ de la taille des cubes représentant les symboles choisis par les joueurs
func _on_aspect_ratio_container_item_rect_changed():
	symbol1.scale.x = symbol1.get_parent().size.x / cube_default_size
	symbol1.scale.y = symbol1.scale.x
	
	symbol2.scale.x = symbol2.get_parent().size.x / cube_default_size
	symbol2.scale.y = symbol2.scale.x


## Appelée lors de la détection de la fin de la partie
## Affiche l'écran de fin
func _on_plateau_game_over(gagnant):
	chronoPlayer1.paused = true
	chronoPlayer2.paused = true
	
	var res = "Fin de la partie\n"
	# Si le gagnant est le joueur 1 OU qu'il y a égalité et que c'est le tour du joueur 2 
	if gagnant == RESULT.J1 || (gagnant == RESULT.EQUAL && !board.isPlayer1sTurn):
		res += "Victoire du Joueur1"
	# Si le gagant est le joueur 2 OU qu'il y a égalité et que c'est le tour du joueur 1
	else:
		res += "Victoire du Joueur2"
	
	end_label.text = res
	end_container.visible = true
	


func _on_button_cacher_pressed():
	menu.visible = !menu.visible
	if menu.visible:
		button_cacher.text = "⤆"
	else:
		button_cacher.text = "⤇"
	
