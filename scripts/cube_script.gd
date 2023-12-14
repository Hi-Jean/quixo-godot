extends Node2D

@onready var global_var = get_node("/root/GlobalVar")
var player1sSymbol
var player2sSymbol

@onready var sprite = $Sprite2D

var ind_x = 0
var ind_y = 0

## enumeration des mouvements possibles pour un cube
enum DIRECTION {BOTTOM, LEFT, TOP, RIGHT}

## Indique si le cube est sélectionné par un joueur ou non
var selected: bool = false

## Indique si le cube est un placeholder ou non (ie : si le cube sert à marqué un mouvement possible)
var isPlaceholder: bool = false

## Plateau auquel appartient le cube
var parent_board
var board_size

var decallage = 10

func _ready():
	parent_board = get_parent()
	board_size = global_var.board_size
	player1sSymbol = global_var.player1sSymbol
	player2sSymbol = 2-player1sSymbol+1


func _to_string():
	return "cube<"+str(ind_x)+","+str(ind_y)+">"

## Retourne vrai si le cube est en périiphérie du plateau, sinon faux
func is_on_border():
	return ind_x == 0 || ind_x == board_size-1 || ind_y == 0 || ind_y == board_size-1


## Retourne vrai si le cube peut être sélectionné par le joueur courant
func can_be_selected(isPlayer1sTurn):
	return is_on_border() && ( sprite.frame == 0 || isPlayer1sTurn && sprite.frame == player1sSymbol || !isPlayer1sTurn && sprite.frame == player2sSymbol )

## Sélectionne / Déselctionne le cube. Ajuste son apparence
func invert_selected():
	selected = !selected
	print(self)
	if selected:
			sprite.modulate = Color(0.5,1,1,1)
	else:
		if sprite.modulate != Color(0.5,1,0.5):
			sprite.modulate = Color.WHITE


## Détecte la sélection/déselction du cube par l'utilisateur
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton) && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		if !(parent_board is Window) && can_be_selected(parent_board.isPlayer1sTurn):
			if isPlaceholder && !(global_var.player2isAI && !parent_board.isPlayer1sTurn): # si clique sur placeholder -> détermine la direction du mouvement et le joue
				var dir = (DIRECTION.TOP if ind_y < parent_board.selected_cube.ind_y else
						DIRECTION.BOTTOM if ind_y > parent_board.selected_cube.ind_y else
						DIRECTION.LEFT if ind_x < parent_board.selected_cube.ind_x else DIRECTION.RIGHT)
				
				parent_board.play_move(dir)
				
				parent_board.selected_cube.invert_selected()
				parent_board.selected_cube = null
				parent_board.move_played.emit()
				pass
			elif !isPlaceholder: # si clqiue sur cube du plateau -> sélectionne/déselecionne le cube
				if parent_board.selected_cube == self:
					parent_board.selected_cube = null
				else:
					if parent_board.selected_cube != null:
						parent_board.selected_cube.invert_selected()
					parent_board.selected_cube = self
				invert_selected()
		else:
			sprite.modulate = Color(1,0.5,0.5,1)
			await get_tree().create_timer(0.15).timeout
			sprite.modulate = Color.WHITE
			

## Modification du sprite du cube
func set_state(sprite_frame):
	sprite.frame = sprite_frame


