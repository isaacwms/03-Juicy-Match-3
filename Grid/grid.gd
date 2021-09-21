extends Node2D

# Board Variables
export (int) var width 
export (int) var height 
export (int) var xStart 
export (int) var yStart 
export (int) var offset

# Timers
var piece = null
var new_position = Vector2(0,0)

# Piece Stuff
var possible_pieces = [
	load("res://Pieces/Red.tscn"),
	load("res://Pieces/Green.tscn"),
	load("res://Pieces/Blue.tscn")
]

var all_pieces

var first_touch
var final_touch
var controlling = false

export (PackedScene) var background

func _ready():
	randomize()
	all_pieces = make_array()
	setup_board()
	generate_pieces()

func make_array():
	var matrix = [ ]
	for x in range(width):
		matrix.append([ ])
		for _y in range(height):
			matrix[x].append(0)
	return matrix

func setup_board():
	for i in width:
		for j in height:
			var b = background.instance()
			add_child(b)
			b.position = Vector2((xStart + (i * offset)), (yStart - (j * offset)))

func generate_pieces():
	for i in width:
		for j in height:
			var piece_to_use = floor(rand_range(0, possible_pieces.size()))
			if piece_to_use == 6:
				piece_to_use = 5
			piece = possible_pieces[piece_to_use].instance()
			
			var loops = 0
			while check_for_matches(i,j, piece.color) && loops < 100:
				piece_to_use = floor(rand_range(0, possible_pieces.size()))
				if piece_to_use == 6:
					piece_to_use = 5
				piece = possible_pieces[piece_to_use].instance()
				loops += 1
			
			add_child(piece)
			piece.position = Vector2(xStart + i * offset, yStart - j * offset)
			all_pieces[i][j] = piece

func check_for_matches(column, row, color):
	#Check Left
	if column > 1 && row <= 1:
		if(all_pieces[column - 1][row].color == color):
			if(all_pieces[column - 2][row].color == color):
				return true
	#Check right
	elif column <= 1 && row > 1:
		if(all_pieces[column][row - 1].color == color):
			if(all_pieces[column][row - 2].color == color):
				return true
	#Check Both
	elif column > 1 && row > 1:
		if((all_pieces[column - 1][row].color == color
		&& all_pieces[column - 2][row].color == color)
		|| (all_pieces[column][row -1].color == color
		&& (all_pieces[column][row - 2].color == color))):
			return true
	return false

func pixel_to_grid(touch_position):
	var column = round((touch_position.x - xStart)/offset)
	var row = round((touch_position.y - yStart)/-offset)
	return Vector2(column, row)

func is_in_grid(touch_position):
	if(touch_position.x >= 0 && touch_position.x < width):
		if(touch_position.y >= 0 && touch_position.y < height):
			return true
	return false

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	all_pieces[column + direction.x][row + direction.y] = first_piece
	all_pieces[column][row] = other_piece
	first_piece.move_piece(Vector2(direction.x * offset, direction.y * -offset))
	other_piece.move_piece(Vector2(direction.x * -offset, direction.y * offset))

func touch_difference(touch_1, touch_2):
	var difference = touch_2 - touch_1
	if(abs(difference.x) > abs(difference.y)):
		if(difference.x > 0):
			swap_pieces(touch_1.x, touch_1.y, Vector2(1, 0))
		elif(difference.x < 0):
			swap_pieces(touch_1.x, touch_1.y, Vector2(-1, 0))
	elif(abs(difference.y) > abs(difference.x)):
		if(difference.y > 0):
			swap_pieces(touch_1.x, touch_1.y, Vector2(0, 1))
		elif(difference.y < 0):
			swap_pieces(touch_1.x, touch_1.y, Vector2(0, -1))

func _process(_delta):
	touch_input()
	find_matches()
	refill_columns()
	

func find_matches():
	for i in width:
		for j in height:
			#Check left and right
			if i > 0 && i < width - 1:
				var color = all_pieces[i][j].color
				if (all_pieces[i - 1][j].color == color 
				&& all_pieces[i + 1][j].color == color):
					all_pieces[i - 1][j].is_matched = true
					all_pieces[i + 1][j].is_matched = true
					all_pieces[i][j].is_matched = true
			if j > 0 && j < height - 1:
				var color = all_pieces[i][j].color
				if (all_pieces[i][j - 1].color == color 
				&& all_pieces[i][j + 1].color == color):
					all_pieces[i][j - 1].is_matched = true
					all_pieces[i][j + 1].is_matched = true
					all_pieces[i][j].is_matched = true
	for i in width:
		for j in height:
			if all_pieces[i][j].is_matched:
				all_pieces[i][j].is_counted = false
			else:
				all_pieces[i][j].is_counted = true
	for i in width:
		for j in height:
			var count_matched = 0
			if all_pieces[i][j].is_matched and not all_pieces[i][j].is_counted:
				count_matched += check_across(i, j, all_pieces[i][j].color);
				mark_across(i,j, all_pieces[i][j].color)
				mark_down(i,j, all_pieces[i][j].color)
				Global.change_score(Global.scores[count_matched])
	destroy_matched()

func check_across(i,j,value):
	if i < 0 or i >= width or j < 0 or j >= height: return 0
	if not all_pieces[i][j].is_matched or all_pieces[i][j].is_counted: return 0
	var count = 0
	if all_pieces[i][j].color != value: return 0
	else: count += 1
	count += check_across(i + 1, j, value)
	count += check_down(i, j + 1, value)
	return count

func check_down(i,j,value):
	if i < 0 or i >= width or j < 0 or j >= height: return 0
	if not all_pieces[i][j].is_matched or all_pieces[i][j].is_counted: return 0
	var count = 0
	if all_pieces[i][j].color != value: return 0
	else: count += 1
	count += check_down(i, j + 1, value)
	return count

func mark_across(i,j,value):
	if i < 0 or i >= width or j < 0 or j >= height: return
	if not all_pieces[i][j].is_matched or all_pieces[i][j].is_counted: return
	if all_pieces[i][j].color != value: return
	all_pieces[i][j].is_counted = true
	mark_across(i + 1, j, value)
	mark_down(i, j + 1, value)

func mark_down(i,j,value):
	if i < 0 or i >= width or j < 0 or j >= height: return
	if not all_pieces[i][j].is_matched or all_pieces[i][j].is_counted: return
	if all_pieces[i][j].color != value: return
	all_pieces[i][j].is_counted = true
	mark_down(i, j + 1, value)

func destroy_matched():
	for i in width:
		for j in height:
			if(all_pieces[i][j].is_matched):
				all_pieces[i][j].die()
				all_pieces[i][j] = null
	collapse_columns()

func collapse_columns():
	for i in width:
		for j in height:
			if(all_pieces[i][j] == null):
				for k in range(j + 1, height):
					if(all_pieces[i][k] != null):
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k].move_piece(Vector2(0, (k-j) * offset))
						all_pieces[i][k] = null
						break

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var piece_to_use = floor(rand_range(0, possible_pieces.size()))
				if piece_to_use == 6:
					piece_to_use = 5
				piece = possible_pieces[piece_to_use].instance()
				
				var loops = 0
				while check_for_matches(i,j, piece.color) && loops < 100:
					piece_to_use = floor(rand_range(0, possible_pieces.size()))
					if piece_to_use == 6:
						piece_to_use = 5
					piece = possible_pieces[piece_to_use].instance()
					loops += 1
				
				add_child(piece)
				piece.position = Vector2(xStart + i * offset, yStart - j * offset)
				all_pieces[i][j] = piece

func touch_input():
	if(Input.is_action_just_pressed("ui_touch")):
		if(is_in_grid(pixel_to_grid(get_global_mouse_position()))):
			controlling = true
			first_touch = pixel_to_grid(get_global_mouse_position())
			all_pieces[first_touch.x][first_touch.y].selected = true
	if(Input.is_action_just_released("ui_touch") && controlling):
		if(is_in_grid(pixel_to_grid(get_global_mouse_position()))):
			controlling = false
			final_touch = pixel_to_grid(get_global_mouse_position())
			all_pieces[first_touch.x][first_touch.y].selected = false
			touch_difference(first_touch, final_touch)

func move_piece(p, position_change):
	p.position += position_change


