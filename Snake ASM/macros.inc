
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_object_macro macro color, drawArea, x1, y1, x2, y2
	push y2
	push x2
	push y1
	push x1
	push drawArea
	push color
	call make_object
	add esp, 24
endm


move_snake_macro macro dirX, dirY
	push dirY
	push dirX
	call move_snake
	add esp, 8
endm


check_boundries_macro macro posX, posY
	push posY
	push posX
	call check_boundries
	add esp, 8
endm
