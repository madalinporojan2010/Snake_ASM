.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern calloc: proc
extern free: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "SNAKE",0
area_width EQU 800 
area_height EQU 600
area DD 0


is_snake_Dead DD 0
speed EQU 10
snake_posX DD 350
snake_posY DD 350
snake_origin_X DD 350
snake_origin_Y DD 350


snake_dirX DD 1
snake_dirY DD 0 

score DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24
arg6 EQU 28
arg7 EQU 32
arg8 EQU 36

symbol_width EQU 10
symbol_height EQU 20


SNAKE DD 1152 dup(0)
HEAD DD 1

include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;;;;;;;;;;;;;;FUNCTII;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
make_object proc
	push ebp
	mov ebp, esp
	pusha
	mov edi, [ebp+arg2]
	;ebx-linia
	;ecx-coloana
	;arg1:color    arg2:area 	arg3:x1		arg4:y1		arg5:x2		arg6:y2
	
	mov edx, 0
	mov eax, [ebp+arg4]
	;;;;; [(y1 - 1) * area_width + x1] * 4
	sub eax, 1
	cmp eax, 0
	jge not_negative
		add eax, 1
	not_negative:

	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3]
	mov ebx, 4
	mul ebx
	cmp eax, 0

	add edi, eax

	mov edx, 0
	mov eax, area_width
	add eax, [ebp+arg3]
	sub eax, [ebp+arg5]
	mov ebx, 4
	mul ebx
	sub eax, 4

	mov ebx, [ebp+arg4]
	mov edx, [ebp+arg1]
	
	w_linii:

	mov ecx, [ebp+arg3]
		w_coloane:
			mov [edi], edx
			add edi, 4
		inc ecx
		cmp ecx, [ebp+arg5]
		jle w_coloane

		add edi, eax
	inc ebx
	cmp ebx, [ebp+arg6]
	jle w_linii

	popa
	mov esp, ebp
	pop ebp
	ret
make_object endp


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


check_boundries proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	
	cmp eax, 750
	jl not_width_border
		mov eax, 0
		mov SNAKE[0], eax
		jmp check_done
	not_width_border:
	
	cmp eax, 0
	jge notz_width_border
		mov eax, area_width
		sub eax, 50
		mov SNAKE[0], eax
		jmp check_done
	notz_width_border:
	
	cmp ebx, 560
	jl not_height_border
		mov ebx, 0
		mov SNAKE[4], ebx
		jmp check_done
	not_height_border:
	
	cmp ebx, 0
	jge notz_height_border
		mov ebx, area_height
		sub ebx, 50
		mov SNAKE[4], ebx
		jmp check_done
	notz_height_border:
	check_done:
	popa
	mov esp, ebp
	pop ebp
	ret
check_boundries endp

check_boundries_macro macro posX, posY
	push posY
	push posX
	call check_boundries
	add esp, 8
endm


check_coordonates proc
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	push edx
	push edi
	push esi

	mov eax, [ebp+arg1] ;posX
	mov ebx, [ebp+arg2]	;posY
	mov ecx, [ebp+arg3] ;obj_X1
	mov edx, [ebp+arg4] ;obj_Y1
	mov edi, [ebp+arg5] ;obj_X2
	mov esi, [ebp+arg6] ;obj_Y2

	cmp eax, ecx
	jle not_good_X
		cmp eax, edi
		jge not_good_X
			mov eax, 1
			jmp good_X
	not_good_X:
	mov eax, 0

	good_X:

	cmp ebx, edx
	jle not_good_Y
		cmp ebx, esi
		jge not_good_Y
			mov ebx, 1
			jmp good_Y
	not_good_Y:
	mov ebx, 0
	good_Y:

	cmp eax, ebx
	jne not_in_range
		cmp eax, 1
		jne not_in_range
			mov eax, 1
			jmp in_range
	not_in_range:
	mov eax, 0
	in_range:
	push esi
	push edi
	push edx
	push ecx
	push ebx
	
	mov esp, ebp
	pop ebp
	ret
check_coordonates endp

check_coordonates_macro macro posX, posY, obj_posX1, obj_posY1, obj_posX2, obj_posY2
	push obj_posY2
	push obj_posX2
	push obj_posY1
	push obj_posX1
	push posY
	push posX
	call check_coordonates
	add esp, 24
endm


check_death_by_object proc
	push ebp
	mov ebp, esp
	pusha

	;;;corners
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 0, 0, 100, 50
	cmp eax, 1
	je snake_Dead

	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 0, 0, 50, 100
	cmp eax, 1
	je snake_Dead

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 0, 500, 100, 600  
	cmp eax, 1
	je snake_Dead
	
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 0, 450, 50, 600
	cmp eax, 1
	je snake_Dead
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	check_coordonates_macro eax, ebx, 650, 0, 800, 50
	cmp eax, 1
	je snake_Dead
	
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 700, 0, 800, 100
	cmp eax, 1
	je snake_Dead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 700, 450, 800, 600
	cmp eax, 1
	je snake_Dead
	
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 650, 500, 800, 600
	cmp eax, 1
	je snake_Dead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	;;;mid obj
	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 50, 200, 150, 350
	cmp eax, 1
	je snake_Dead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2] ;;;;!!!!!
	check_coordonates_macro eax, ebx, 600, 200, 700, 350
	cmp eax, 1
	je snake_Dead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 250, 50, 500 , 150
	cmp eax, 1
	je snake_Dead
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	mov eax, [ebp+arg1]
	mov ebx, [ebp+arg2]
	check_coordonates_macro eax, ebx, 250, 400, 500, 500
	cmp eax, 1
	je snake_Dead
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp snake_not_Dead
	snake_Dead:
		mov is_snake_Dead, 1
		;;stric stiva
	snake_not_Dead:
	popa
	mov esp, ebp
	pop ebp
	ret
check_death_by_object endp

check_death_by_object_macro macro posX, posY
	push posY
	push posX
	call check_death_by_object
	add esp, 8
endm


change_tail_coord proc
	push ebp
	mov ebp, esp 
	pusha

	mov ecx, HEAD
	dec ecx
	bucla:
		dec ecx
		mov eax, SNAKE[ECX*8]
		mov ebx, SNAKE[ECX*8+4]
		inc ecx
		mov SNAKE[ECX*8], eax
		mov SNAKE[ECX*8+4], ebx

		dec ecx
		cmp ecx, 1
		jl over
	jmp bucla
	over:

	popa
	mov esp, ebp
	pop ebp
	ret
change_tail_coord endp


move_snake proc
	push ebp
	mov ebp, esp
	pusha

	mov edx, 0
	;X - direction
	mov eax, [ebp+arg1] 
	mov ebx, [ebp+arg2]
	mul ebx
	mov edx, SNAKE[0]
	add edx, eax
	mov SNAKE[0], edx
	;;;;;???????????????? WTF
	mov edx, 0
	;Y - direction
	mov eax, [ebp+arg1]
	mov ecx, [ebp+arg3]
	mul ecx
	mov edx, SNAKE[4]
	add edx, eax
	mov SNAKE[4], edx


	popa
	mov esp, ebp
	pop ebp
	ret
move_snake endp


move_snake_macro macro spd, dirX, dirY
	push dirY
	push dirX
	push spd
	call move_snake
	add esp, 12
endm


PUSH_HEAD proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, HEAD
	mov ebx, [ebp+arg1]
	mov ecx, [ebp+arg2]
	mov SNAKE[eax*8], ebx
	mov SNAKE[eax*8+4], ecx

	inc eax
	mov HEAD, eax
	popa 
	mov esp, ebp
	pop ebp 
	ret
PUSH_HEAD endp

PUSH_HEAD_MACRO macro X, Y
	push Y
	push X
	call PUSH_HEAD
	add esp, 8
endm



draw_SNAKE proc
	push ebp
	mov ebp, esp
	pusha

	mov ecx, HEAD
	dec ecx
	bucla:

		mov eax, SNAKE[ecx*8]
		mov ebx, SNAKE[ecx*8+4]
		
		add eax, 50
		add ebx, 50
		make_object_macro 55b7c2h, area, SNAKE[ecx*8], SNAKE[ecx*8+4], eax, ebx

	loop bucla
	
		mov eax, SNAKE[ecx*8]
		mov ebx, SNAKE[ecx*8+4]
		
		add eax, 50
		add ebx, 50
		make_object_macro 569ea6h, area, SNAKE[ecx*8], SNAKE[ecx*8+4], eax, ebx
	popa 
	mov esp, ebp
	pop ebp 
	ret
draw_SNAKE endp




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 3
	jz evt_key
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	mov edi, area
	mov ecx, area_height


bucla_linii:

;;;;; eax pastreaza culoarea matricei de pixeli
	mov eax, 000h                                                                              
	push ecx
	mov ecx, area_width
bucla_coloane:
	mov [edi], eax
	add edi, 4
	loop bucla_coloane
	pop ecx
	loop bucla_linii
evt_key:
	
	push eax
	push ebx
	

mov ebx, [ebp+arg2]
cmp ebx, 26h
	jne not_up_arrow
		mov snake_dirX, 0
		mov snake_dirY, -1
	not_up_arrow:

cmp ebx, 28h
	jne not_down_arrow
		mov snake_dirX, 0
		mov snake_dirY, 1
	not_down_arrow:

cmp ebx, 25h
	jne not_left_arrow
		mov snake_dirX, -1
		mov snake_dirY, 0
	not_left_arrow:

cmp ebx, 27h
	jne not_right_arrow
		mov snake_dirX, 1
		mov snake_dirY, 0
	not_right_arrow:
	pop ebx
	pop eax

evt_timer:
	push eax
	push ebx
		mov eax, SNAKE[0]
		mov ebx, SNAKE[4]
		
		cmp SNAKE[0], eax
		jl goodX
			xchg SNAKE[0], eax
			xchg SNAKE[4], ebx
		goodX:
		call change_tail_coord
		move_snake_macro speed, snake_dirX, snake_dirY
		check_boundries_macro SNAKE[0], SNAKE[4]
		check_death_by_object_macro SNAKE[0], SNAKE[4]
		cmp is_snake_Dead, 0
		je is_Alive
			mov ebx, [ebp+arg2]
			cmp ebx, 52h
			jne not_reset
				push eax
				mov eax, 0
				mov score, 0
				mov HEAD, 2
				mov is_snake_Dead, eax
				;;;;;;;;;;;;////TODO
				mov eax, snake_origin_X
				mov SNAKE[0], eax
				mov eax, snake_origin_Y
				mov SNAKE[4], eax	
				pop eax		
		is_Alive:
		
		call draw_SNAKE
	

	not_reset:
	pop ebx
	pop eax


	cmp is_snake_Dead, 0
	jne keep_score
		inc score
	keep_score:
make_objects:
	;;;???make the game for any resolution


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LEVEL LAYOUT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;bug: when drawing at exactly width/height

	;corners
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_object_macro 0d9469h, area, 0, 0, 50, 100
	make_object_macro 0d9469h, area, 0, 0, 100, 50

	make_object_macro 0d9469h, area, area_width-100, 0, area_width-1, 50
	make_object_macro 0d9469h, area, area_width-50, 0, area_width-1, 100

	make_object_macro 0d9469h, area, 0, area_height-100, 50, area_height-1
	make_object_macro 0d9469h, area, 0, area_height-50, 100, area_height-1

	make_object_macro 0d9469h, area, area_width-100, area_height-50, area_width-1, area_height-1
	make_object_macro 0d9469h, area, area_width-50, area_height-100, area_width-1, area_height-1
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;middle objects
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_object_macro 0d9469h, area, 300, 100, 500, 150
	make_object_macro 0d9469h, area, 300, area_height-150, 500, area_height-100

	make_object_macro 0d9469h, area, 100, 250, 150, 350
	make_object_macro 0d9469h, area, area_width-150, 250, area_width-100, 350
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



afisare_litere:
	;afisam valoarea score-ului curent (sute, zeci si unitati)
	make_text_macro 'S', area, 5, 10
	make_text_macro 'C', area, 15, 10
	make_text_macro 'O', area, 25, 10
	make_text_macro 'R', area, 35, 10
	make_text_macro 'E', area, 45, 10

	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 90, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 80, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 10
	;cifra miilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 60, 10
	
	;scriem un mesaj
	death_Message:
	cmp is_snake_Dead, 0
	je no_Message
	make_text_macro 'P', area, 310, 300
	make_text_macro 'R', area, 320, 300
	make_text_macro 'E', area, 330, 300
	make_text_macro 'S', area, 340, 300
	make_text_macro 'S', area, 350, 300
	make_text_macro ' ', area, 360, 300
	make_text_macro 'R', area, 370, 300
	make_text_macro ' ', area, 380, 300
	make_text_macro 'T', area, 390, 300
	make_text_macro 'O', area, 400, 300
	make_text_macro ' ', area, 410, 300
	make_text_macro 'R', area, 420, 300
	make_text_macro 'E', area, 430, 300
	make_text_macro 'S', area, 440, 300
	make_text_macro 'T', area, 450, 300
	make_text_macro 'A', area, 460, 300
	make_text_macro 'R', area, 470, 300
	make_text_macro 'T', area, 480, 300

	make_text_macro 'G', area, 350, 250
	make_text_macro 'A', area, 360, 250
	make_text_macro 'M', area, 370, 250
	make_text_macro 'E', area, 380, 250
	make_text_macro ' ', area, 390, 250
	make_text_macro 'O', area, 400, 250
	make_text_macro 'V', area, 410, 250
	make_text_macro 'E', area, 420, 250
	make_text_macro 'R', area, 430, 250
	no_Message:
final_draw:
	popa 
	mov esp, ebp
	pop ebp 
	ret
draw endp

start:
	mov eax, snake_posX
	mov ebx, snake_posY
	mov SNAKE[0], eax
	mov SNAKE[4], ebx
	mov eax, 300
	mov ebx, 350
	mov SNAKE[8], eax
	mov SNAKE[12], ebx

	PUSH_HEAD_MACRO 320, 350
	; PUSH_HEAD_MACRO 300, 350
	; PUSH_HEAD_MACRO 280, 350
	; PUSH_HEAD_MACRO 260, 350
	; PUSH_HEAD_MACRO 240, 350
	; PUSH_HEAD_MACRO 220, 350


	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20

	
	;terminarea programului
	push 0
	call exit
end start
