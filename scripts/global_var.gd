##
## Permet la transmission des données entre les scenes de l'application
##
extends Node

var player1sSymbol = 1
var player2isAI = false
var board_size = 5

func _ready():
	get_window().min_size = Vector2(475, 300)
