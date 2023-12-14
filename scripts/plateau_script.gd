extends Node2D

@onready var global_var = get_node("/root/GlobalVar")

@onready var bg = $Background
@onready var audioPlayer = $AudioStreamPlayer

## enumeration des mouvements possibles pour un cube
enum DIRECTION {BOTTOM, LEFT, TOP, RIGHT}

## enumeration des alignements possibles
enum PLACE {LINE, COLUMN, DIAG_LEFT, DIAG_RIGHT}

## enumeration des resultats de fin de partie possible 
enum RESULT {J1, J2, EQUAL}

########## PARAMETRES DES CUBES DU PLATEAU
var scene_cube = preload("res://scenes/cube.tscn")

var cube_default_size = preload("res://assets/textures/Cube.png").get_height()
var cube_separation = 5
var multiplier = 3

var new_size = cube_default_size * multiplier

var interval = new_size + cube_separation

########## 
var board_size
var board_position = 100

## Tableau des cubes composant le plateau
var cube_array = Array()

## Tableau des cubes servant de placeholder aux mouvements possibles
var possible_moves = Array()

## Cube sélectionné
var selected_cube = null:
	set(new_cube):
		selected_cube = new_cube
		update_possible_moves()

## Historique des états du plateau
var cube_array_history = Array()
var history_max_size = 10

## Paramètres des joueurs
var isPlayer1sTurn = true
var player1sSymbol
var player2sSymbol

var ended = false

########## SIGNAUX DU PLATEAU

## Signal l'action d'un joueur
signal move_played

## Signal le retour à l'etat précédent du plateau
signal undid_previous_move(wasLastMove)

## Signal la fin de la partie
signal game_over(gagnant)


## Initialisation du plateau. Place les cubes et les placeholder (mouvements possibles).
func _ready():
	board_size = global_var.board_size
	player1sSymbol = global_var.player1sSymbol
	player2sSymbol = 2-player1sSymbol+1
	bg.size = Vector2(interval*board_size + cube_separation, interval*board_size + cube_separation)
	bg.position = Vector2(get_parent().size.x/2 - bg.size.x/2,get_parent().size.y/2 - bg.size.y/2)
	# Creayion des cubes
	for i in range(board_size):
		cube_array.append(Array())
		for j in range(board_size):
			var cube = scene_cube.instantiate()
			cube.position = Vector2(bg.position.x + cube_separation + i*interval, bg.position.y + cube_separation + j*interval)
			cube.ind_x = i
			cube.ind_y = j
			cube.scale = Vector2(multiplier,multiplier)
			cube_array[i].append(cube)
			add_child(cube)
	# Creation des mouvements possibles
	for i in range(4):
		possible_moves.append(Array())
	for i in range(board_size):
		for j in range(4):
			var cube = scene_cube.instantiate()
			
			cube.position = cube_array[i][i].position
			
			# Horrible mais fonctionnel
			# On veut placer les mouvement possibles P autour du plateau 5*5 avec les cubes C
			#     P  P  P  P  P
			#  P  C  C  C  C  C  P
			#  P  C  C  C  C  C  P
			#  P  C  C  C  C  C  P
			#  P  C  C  C  C  C  P
			#  P  C  C  C  C  C  P
			#     P  P  P  P  P
			# Seul moyen que j'ai trouvé pour ne pas avoir une méthode trop longue en ayant 4 fois un code quasiment identique
			cube.position.x += (0 if j%2 == 0 else
								- (i + 1) * interval if j == 3 else
								(board_size - i) * interval )
			
			cube.position.y += (0 if j%2 != 0 else
								(board_size - i) * interval if j == 2 else
								- (i + 1) * interval )
			
			cube.ind_x = (cube_array[i][i].ind_x if j%2 == 0 else
						0 if j == 3 else
						board_size-1)
			
			cube.ind_y = (cube_array[i][i].ind_y if j%2 != 0 else
						0 if j == 0 else
						board_size-1)
			
			cube.scale = Vector2(multiplier,multiplier)
			cube.modulate = Color(1,1,1,0.5)
			cube.isPlaceholder = true
			cube.visible = false
			
			possible_moves[j].append(cube)
			add_child(cube)

## Mis-à-jour de l'affichage des mouvements possibles
## Appelée lors de la sélection/déselection d'un cube.
func update_possible_moves():
	## Cache les mouvements possibles
	for i in range(possible_moves.size()):
		for j in range(possible_moves[i].size()):
			possible_moves[i][j].visible = false
	## Affiche les mouvements possibles si un cube est sélectionné
	if selected_cube != null:
		if selected_cube.ind_x != 0:
			possible_moves[3][selected_cube.ind_y].visible = true
			possible_moves[3][selected_cube.ind_y].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
		if selected_cube.ind_x != board_size-1:
			possible_moves[1][selected_cube.ind_y].visible = true
			possible_moves[1][selected_cube.ind_y].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
			
		if selected_cube.ind_y != 0:
			possible_moves[0][selected_cube.ind_x].visible = true
			possible_moves[0][selected_cube.ind_x].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
		if selected_cube.ind_y != board_size-1:
			possible_moves[2][selected_cube.ind_x].visible = true
			possible_moves[2][selected_cube.ind_x].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol


## Joue un mouvement en fonction du cube sélectionné et de la direction souhaité
func play_move(direction):
	# MAJ de l'historique du plateau
	if cube_array_history.size() == 10:
		cube_array_history.pop_front()
	var temp_array = Array()
	for i in range(board_size):
		temp_array.append(Array())
		for j in range(board_size):
			temp_array[i].append(cube_array[i][j].sprite.frame)
	cube_array_history.append(temp_array)
	
	# Déplacement des cubes, à partir du cube sélectionné, vers la direction souhaitée et application du symbole du joueur
	if direction == DIRECTION.TOP:
		for i in range(selected_cube.ind_y, 0, -1):
			cube_array[selected_cube.ind_x][i].sprite.frame = cube_array[selected_cube.ind_x][i-1].sprite.frame
		cube_array[selected_cube.ind_x][0].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
	elif direction == DIRECTION.BOTTOM:
		for i in range(selected_cube.ind_y, board_size-1, 1):
			cube_array[selected_cube.ind_x][i].sprite.frame = cube_array[selected_cube.ind_x][i+1].sprite.frame
		cube_array[selected_cube.ind_x][board_size-1].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
	elif direction == DIRECTION.LEFT:
		for i in range(selected_cube.ind_x, 0, -1):
			cube_array[i][selected_cube.ind_y].sprite.frame = cube_array[i-1][selected_cube.ind_y].sprite.frame
		cube_array[0][selected_cube.ind_y].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
	else:
		for i in range(selected_cube.ind_x, board_size-1, 1):
			cube_array[i][selected_cube.ind_y].sprite.frame = cube_array[i+1][selected_cube.ind_y].sprite.frame
		cube_array[board_size-1][selected_cube.ind_y].sprite.frame = player1sSymbol if isPlayer1sTurn else player2sSymbol
	
	play_piece_soundeffect()
	
	# Vérfie l'état de la partie, y met fin si tab_result n'est pas vide
	var tab_result = check_board_state(direction)
	if(tab_result.size() > 0):
		var winner = null
		for i in range(tab_result.size()-1):
			if tab_result[i][1] != tab_result[i+1][1]:
				# Both player won
				winner = RESULT.EQUAL
		
		if winner != RESULT.EQUAL:
			winner = (RESULT.J1 if tab_result[0][1] == player1sSymbol else RESULT.J2)
		
		highlight_result(tab_result)
		game_over.emit(winner)
		ended = true
		bg.mouse_filter = bg.MOUSE_FILTER_STOP
		
	isPlayer1sTurn = !isPlayer1sTurn


## Colorise les alignements permettant la fin de la partie
func highlight_result(tab):
	for i in range(tab.size()):
		if tab[i][0] == PLACE.LINE:
			var indice_ligne = tab[i][2]
			for k in range(board_size):
				cube_array[indice_ligne][k].sprite.modulate = Color(0.5,1,0.5)
			pass
		if tab[i][0] == PLACE.COLUMN:
			var indice_colonne = tab[i][2]
			for k in range(board_size):
				cube_array[k][indice_colonne].sprite.modulate = Color(0.5,1,0.5)
			pass
		if tab[i][0] == PLACE.DIAG_LEFT:
			for k in range(board_size):
				cube_array[k][k].sprite.modulate = Color(0.5,1,0.5)
			pass
		if tab[i][0] == PLACE.DIAG_RIGHT:
			for k in range(board_size):
				cube_array[k][board_size-k-1].sprite.modulate = Color(0.5,1,0.5)
			pass
	
	pass


## Vérfie si la ligne d'indice donné est composée par des cubes du même symbole
func check_line(indice_ligne):
	var lineOfSameSymbols = true
	for j in range(board_size-1):
		if cube_array[indice_ligne][j].sprite.frame == 0:
			lineOfSameSymbols = false
		lineOfSameSymbols = lineOfSameSymbols && cube_array[indice_ligne][j].sprite.frame == cube_array[indice_ligne][j+1].sprite.frame
	
	if lineOfSameSymbols:
		return [PLACE.LINE, cube_array[indice_ligne][0].sprite.frame, indice_ligne]
	return []


## Vérfie si la colonne d'indice donné est composée par des cubes du même symbole
func check_column(indice_colonne):
	var columnOfSameSymbols = true
	for j in range(board_size-1):
		if cube_array[j][indice_colonne].sprite.frame == 0:
			columnOfSameSymbols = false
		columnOfSameSymbols = columnOfSameSymbols && cube_array[j][indice_colonne].sprite.frame == cube_array[j+1][indice_colonne].sprite.frame
	
	if columnOfSameSymbols:
		return [PLACE.COLUMN, cube_array[0][indice_colonne].sprite.frame, indice_colonne]
	return []


## Vérfie si la diagonale partant du coins haut-gauche est composée par des cubes du même symbole
func check_diagonal_left():
	var diagonalOfSameSymbols = true
	for i in range(board_size-1):
		if cube_array[i][i].sprite.frame == 0:
			diagonalOfSameSymbols = false
		diagonalOfSameSymbols = diagonalOfSameSymbols && cube_array[i][i].sprite.frame == cube_array[i+1][i+1].sprite.frame
		
	if diagonalOfSameSymbols:
		return [PLACE.DIAG_LEFT, cube_array[0][0].sprite.frame]
	return []


## Vérfie si la diagonale partant du coins haut-droit est composée par des cubes du même symbole
func check_diagonal_right():
	var diagonalOfSameSymbols = true
	for i in range(board_size-1):
		if cube_array[i][board_size-i-1].sprite.frame == 0:
			diagonalOfSameSymbols = false
		diagonalOfSameSymbols = diagonalOfSameSymbols && cube_array[i][board_size-i-1].sprite.frame == cube_array[i+1][board_size-i-2].sprite.frame
	
	if diagonalOfSameSymbols:
		return [PLACE.DIAG_RIGHT, cube_array[0][board_size-1].sprite.frame]
	return []

## Vérifie l'état du plateau, et si il est composé par des alignements de même symbole
## Retourne la liste de ces alignements
func check_board_state(last_direction):
	var ret = Array()
	var temp
	
	for i in range(board_size):
		## ne vérifie que la ligne modifiée si mouvement horizontal
		if last_direction != DIRECTION.LEFT && last_direction != DIRECTION.RIGHT || selected_cube.ind_y == i:
			temp = check_column(i)
			if temp.size() > 0:
				ret.push_back(temp)
	
	for i in range(board_size):
		## ne vérifie que la colonne modifiée si mouvement vertical
		if last_direction != DIRECTION.TOP && last_direction != DIRECTION.BOTTOM || selected_cube.ind_x == i:
			temp = check_line(i)
			if temp.size() > 0:
				ret.push_back(temp)
	
	temp = check_diagonal_left()
	if temp.size() > 0:
		ret.push_back(temp)
	
	temp = check_diagonal_right()
	if temp.size() > 0:
		ret.push_back(temp)
	
	return ret


## MAJ de la position et de la taille du plateau lors de la modification de la fenêtre
func _on_margin_container_item_rect_changed():
	scale.x = min(get_parent().size.x, get_parent().size.y)/(bg.size.x + 2*interval)
	scale.y = scale.x
	position = Vector2(get_parent().size.x/2, get_parent().size.y/2)


## Annule le dernier mouvement exécuté
func _on_button_annule_pressed():
	if cube_array_history.size() > 0:
		var previous_state_array = cube_array_history.pop_back()
		if selected_cube != null:
			selected_cube.invert_selected()
		selected_cube = null
		
		for i in range(board_size):
			for j in range(board_size):
				cube_array[i][j].set_state(previous_state_array[i][j])
				cube_array[i][j].sprite.modulate = Color.WHITE
		
		ended = false
		bg.mouse_filter = bg.MOUSE_FILTER_PASS
		
		isPlayer1sTurn = !isPlayer1sTurn
		audioPlayer.stream = load("res://assets/sounds/soundeffect_undo.mp3")
		audioPlayer.play()
		undid_previous_move.emit(cube_array_history.size() == 0)
		_on_move_played()


## Appelée lors de la détc=ection du mouvement d'un cube
## Exécute automatiquement le tour du deuxième joueur si c'est son tour et que l'IA est activée
func _on_move_played():
	if !ended && global_var.player2isAI && !isPlayer1sTurn:
		bg.mouse_filter = bg.MOUSE_FILTER_STOP
		
		# Simulation de la réflexion, permet éventuellement l'annulation du précédent mouvement
		await get_tree().create_timer(randf_range(0.5,1)).timeout
		
		var res = mouvement_IA_lv1()
		selected_cube = res[0]
		var dir = res[1]
		
		# Permet au joueur de voir le cube selectionné par l'IA
		selected_cube.invert_selected()
		await get_tree().create_timer(randf_range(1,2)).timeout
		
		# Vérifie que c'est toujours au tour de l'IA
		# (au cas ou annulation du mouvement précédent durant l'exécution de cette méthode)
		if!isPlayer1sTurn:
			play_move(dir)
		selected_cube.invert_selected()
		selected_cube = null
		bg.mouse_filter = Control.MOUSE_FILTER_PASS
		move_played.emit()


## Retourne le coup à jouer (niveau 1)
## Joue aléatoirement
func mouvement_IA_lv1():
	var temp_cube = null
	# Choix aléatoire du cube
	while temp_cube == null || !temp_cube.can_be_selected(isPlayer1sTurn):
		temp_cube = cube_array[randi_range(0, board_size-1)][randi_range(0, board_size-1)]
	
	var valid_dir = false
	var dir
	# Choix aléatoire de la direction du mouvement
	while !valid_dir:
		valid_dir = true
		dir = randi_range(0,3)
		if temp_cube.ind_x == 0 && dir == DIRECTION.LEFT:
			valid_dir = false
		if temp_cube.ind_x == board_size-1 && dir == DIRECTION.RIGHT:
			valid_dir = valid_dir && false
		if temp_cube.ind_y == 0 && dir == DIRECTION.TOP:
			valid_dir = valid_dir && false
		if temp_cube.ind_y == board_size-1 && dir == DIRECTION.BOTTOM:
			valid_dir = valid_dir && false
	
	return [temp_cube, dir]


## Retourne le coup à jouer (niveau 2)
## Essaie d'aligner le plus de cube possible, ne prend pas en compte les cubes adverses
## WORK IN PROGRESS
func mouvement_IA_lv2():
	var longest_align = Array()
	var max_length = 0
	
#	for i in range(board_size):
#		var length = 0
#		for j in range(board_size):
#			if cube_array[i][j].sprite.frame == player2sSymbol:
#				length = length+1
#		if length > max_length:
#			max_length = length
#			longest_align = Array()
#			longest_align.append([length, PLACE.LINE, i])
#
	
	
	return mouvement_IA_lv1()



## Joue l'un des sons mouvement de cube disponibles
func play_piece_soundeffect():
	audioPlayer.stream = load("res://assets/sounds/soundeffect_piece_"+ str(randi_range(1,5)) +".mp3")
	audioPlayer.play()
