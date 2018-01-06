; *********************************
; * Name:	Isaac McAuley
; * Course:	COMP 2655
; * Assignment:	6
; * Due:	December 11, 2018
; * Instructor: Paul Pospisil
; * File:	a6.s
; *********************************
;

;GAME OF LIFE PROGRAM
; opens a game of life dat file
; runs Conway's game of life from the input file
; gives user the choice to save the output

;File Format:
; every life token is defined by a single line
; format (row) (column)
; row ranges from 'a'-'x'
; column ranges from 1-80
; a final blank line is needed after

;Testing:
; tested and passed on every given file

	include	gemdos.i

; GLOBAL CONSTANTS
GEMDOS		equ	1
TRUE		equ	-1
FALSE		equ	0
NULL		equ	0
CR		equ	$D		; ASCII carriage return
LF		equ	$A		; ASCII line feed
ESC		equ	$1B		; ASCII escape character
SP		equ	' '		; ASCII space
STATUS		equ	24		; status line - really 25 but lines #ed 0 to 24
LIFE		equ	'@'		; ASCII life character
MAX_FILE	equ	51		; maximum filename length
SCREENLINES	equ	24		; lines on screen
SCREENCOLS	equ	80		; columns on screen

RUN_END		equ	-1
RUN_STAG	equ	-2
RUN_EMPTY	equ	-3

LBR		equ	-10		; lower bound row
UBR		equ	-8		; upper bound row
LBC		equ	-6		; lower bound column
UBC		equ	-4		; upper bound column
SIZE		equ	-2		; element size

;1	row
;2	col
;3	array
;use:
; get2D row,col,array*
get2D	MACRO
	sub.l	#4,sp
	pea	\3
	move.w	\2,-(sp)
	move.w	\1,-(sp)
	jsr	access2D
	add.l	#8,sp
	ENDM

getNeighbors	MACRO
	sub.l	#2,sp
	pea	\3
	move.w	\2,-(sp)
	move.w	\1,-(sp)
	jsr	numNeighbors
	add.l	#8,sp
	ENDM

loop	MACRO
\3_start:
	cmp.w	\2,\1
	beq	\3End
	jsr	\3
	addq.w	#1,\1
	jmp	\3_start
\3End:
	ENDM

;Purpose:
; to provide a UI to the user
;Limitations/Bugs:
; only accepts one file
; input is raw ie. no backspace
; no error checking for gen counter
;Input:
; game of life dat file
; generation number
;Output:
; game of life dat file
;
;d0	number of generations
;a1 life count


;;
;;	MAIN PROGRAM
;;
menu_start:
	jsr	introduction

	pea	enterFileText
	jsr	writeString
	add.l	#4,sp

	move.w	#MAX_FILE,-(sp)
	pea	fileName
	jsr	readString
	add.l	#4,sp

	jsr	nextLine

	pea	enterGenText
	jsr	writeString
	add.l	#4,sp

	clr.l	d0
	sub.l	#2,sp
	jsr	readNumber
	move.w	(sp)+,d0

	pea	openSuccess
	pea	lifeCount
	pea	fileName
	pea	gameBoard
	jsr	loadArray
	add.l	#16,sp

	lea	lifeCount,a1
	tst.w	(a1)
	beq	menu_file_error

	jsr	clearScreen

	sub.l	#2,sp
	move.w	d0,-(sp)
	pea	gameBoard
	jsr	runSimulation
	add.l	#6,sp
	move.w	(sp)+,d2

	jsr	nextLine

	cmp.w	#RUN_END,d2
	beq	menu_ended_end

	cmp.w	#RUN_STAG,d2
	beq	menu_ended_stagnent

	pea	clearText
	jsr	writeString
	add.l	#4,sp
	bra	menu_save_file


menu_ended_end:
	pea	endText
	jsr	writeString
	add.l	#4,sp
	bra	menu_save_file

menu_ended_stagnent:
	pea	stagText
	jsr	writeString
	add.l	#4,sp

menu_save_file:
	pea	saveText
	jsr	writeString
	add.l	#4,sp

	;yes or no to save file
	sub.l	#2,sp
	jsr 	readChar
	cmp.w	#'y',(sp)+
	bne	menu_exit

	;saving a file
	jsr	nextLine
	pea	enterFileText
	jsr	writeString
	add.l	#4,sp

	move.w	#MAX_FILE,-(sp)
	pea	fileName
	jsr	readString
	add.l	#4,sp

	pea	fileName
	pea	gameBoard
	jsr	saveFile
	add.l	#8,sp

menu_exit:
	jsr	terminate


menu_file_error:
	pea	file_error_message
	jsr	writeString
	add.l	#4,sp
	bra	menu_exit

; Data Section for main program

fileName	ds.b	52	;(string) open file and saved file

generations	ds.w	1	;(int) number of generations to run through

lifeCount	ds.w	1	;(int) number of lives in the file

openSuccess	ds.b	2	;(boolean) if opening the file worked

	dc.w	'a'
	dc.w	'x'
	dc.w	1
	dc.w	80
	dc.w	1
gameBoard	ds.b	('x'-'a'+1)*(80-1+1)

;STRING CONSTANTS

file_error_message	dc.b	"Error in file",NULL

endText		dc.b	"Simulation reached last generation",CR,LF,NULL
stagText	dc.b	"Simulation has become stagnent",CR,LF,NULL
clearText	dc.b	"There was no life left in simulation",CR,LF,NULL

enterFileText	dc.b	"Enter filename: ",NULL
enterGenText	dc.b	"Enter number of generations: ",NULL

saveText	dc.b	"Do you want to save last generation to file? (y/n): ",NULL
	even


;; GAME SUBROUTINES

; void introduction ()
;
; introduction clears the screen and writes an introductory message
; to the screen, explaining how to use this program.  It then waits
; for the user to press a key before exiting.

; Register Table
;
; d0-d2
; a0-a2	used by GEMDOS function calls

introduction:
	movem.l	d0-d2/a0-a2,-(sp)
	jsr	clearScreen
	pea	i_str
	jsr	writeString
	addq.l	#4,sp
	movem.l	(sp)+,d0-d2/a0-a2
	rts

; Data Section
;
i_str	dc.b	"                        "
	dc.b	"Welcome to the Game of Life",CR,LF,LF

	dc.b	"The game of life is a simulation of biological"
	dc.b	" life.",CR,LF
	dc.b	"The screen is table with 24 rows and 80 columns.",CR,LF
	dc.b	"Row indices range from"
	dc.b	" 'a' to 'x' inclusive.",CR,LF
	dc.b	"Column indices range from"
	dc.b	" 1 to 80 inclusive.",CR,LF,LF

	dc.b	"The initial data to start the simulation is read from a",CR,LF
        dc.b    "file. The file name MUST include the complete drive and path, ",CR,LF
	dc.b	"which has a maximum length of 50 characters.",CR,LF

	dc.b	"The simulation runs for a specified number of generations",CR,LF
	dc.b	"The number of generations can range from 1"
	dc.b	" to 65535, inclusive.",CR,LF,LF,LF,0
	EVEN


;;
;;  ARRAY ACCESSING FUNCTION
;;
; long* access2D(int Row_Index, int Column_Index, void Array[][])
;
; access2D takes two indices and an array with a valid dope vector,
; and if valid indices generates and returns the memory address of the
; specified array element.
; The function performs index checking to ensure that the indices
; are valid. If an invalid index is found a longword error flag is returned
; in the address space, instead of a valid address. If the row index
; is invalid then an error value of -1 is returned. If the column index
; is invalid then an error value of -2 is returned.

;d0	row
;d1	col
;d2	UBC - LBC + 1
;d4	offset
;a0	array

A2D_ROW_ERROR	equ	-1
A2D_COL_ERROR	equ	-2

A2D_RETURN	equ	16
access2D:
	link 	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.l	12(a6),a0
	clr.l	d1
	clr.l	d0
	move.w	8(a6),d0	;row
	move.w	10(a6),d1	;col

	cmp.w	LBR(a0),d0
	blt	a2D_row_error

	cmp.w	UBR(a0),d0
	bhi	a2D_row_error

	cmp.w	LBC(a0),d1
	blt	a2D_col_error

	cmp.w	UBC(a0),d1
	bhi	a2D_col_error

	sub.w 	LBR(a0),d0 ; calc. (row_index - LBR)
	sub.w 	LBC(a0),d1 ; calc. (col_index - LBC)

	move.w 	UBC(a0),d2 ; calc. (UBC - LBC + 1)
	sub.w 	LBC(a0),d2
	addq.w 	#1,d2

	mulu.w 	d0,d2 ; calc. offset from array
	add.w 	d1,d2
	mulu.w 	SIZE(a0),d2

	add.l 	a0,d2 ; calculate address

	move.l	d2,A2D_RETURN(a6)
	bra	a2D_exit
a2D_row_error:
	move.l	#A2D_ROW_ERROR,A2D_RETURN(a6)
	bra	a2D_exit
a2D_col_error:
	move.l	#A2D_COL_ERROR,A2D_RETURN(a6)
a2D_exit:
	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts

;void printBoard(2DArray[][])
;Purpose:
; clears screen and prints game board to screen
;
;Limitations/Bugs:
; takes a long time
;
;Input:
; pointer to game board
;Output:
; none
;
;d0 row counter
;d1 col counter
;d2 printing char
;a0 board
;a1 current char

PB_BOARD	equ	8
printBoard:
	link	a6,#0
	movem.l	d0-d2/a0/a1,-(sp)

	movea.l	PB_BOARD(a6),a0
	move.w	LBR(a0),d1
loop_col:
	move.w	LBC(a0),d0
loop_row:
	get2D	d1,d0,(a0)
	movea.l	(sp)+,a1	;address of char
	move.b	(a1),d2		;char

	cmp.b	#LIFE,d2	;print the current char
	beq	print_char
	move.b	#SP,d2
print_char:
	move.w	d2,-(sp)
	jsr	writeChar
	add.l	#2,sp

	add.w	#1,d0

	cmp.w	UBC(a0),d0
	bls	loop_row

next_row:
	addq.w	#1,d1
	cmp.w	UBR(a0),d1
	bhi	pb_done
	jsr	nextLine
	bra	loop_col
pb_done:
	movem.l (sp)+,d0-d2/a0/a1
	unlk	a6
	rts

;bool checkIfEmpty(board[][])
;Purpose:
; checks if a board has any life in it
;Limitations/Bugs:
;
;Input:
; char board[][] (current board)
;Output:
; boolean (pushed as a word)
;
;d0 current col
;d1 current row
;d2 current char
;a0 board
;a1 pointer to current char

CE_BOARD	equ	8
CE_EMPTY	equ	12
checkIfEmpty:
	link	a6,#0
	movem.l	d0-d7/a0/a1,-(sp)

	movea.l	CE_BOARD(a6),a0
	move.w	LBR(a0),d1
	move.b	#TRUE,CE_EMPTY(a6)

ce_loop_col:
	move.w	LBC(a0),d0
ce_loop_row:
	get2D	d1,d0,(a0)
	movea.l	(sp)+,a1	;address of char

	tst.b	(a1)
	bne	ce_not_empty

	add.w	#1,d0
	cmp.w	UBC(a0),d0
	bls	ce_loop_row
ce_next_row:
	addq.w	#1,d1
	cmp.w	UBR(a0),d1
	bls	ce_loop_col
	bra	ce_exit

ce_not_empty:
	move.b	#FALSE,CE_EMPTY(a6)
ce_exit:
	movem.l (sp)+,d0-d7/a0/a1
	unlk	a6
	rts

;bool boardIsEqual(char board1[][], char board2[][])
;Purpose:
; find if the values at each indicies are the same on each board
;Limitations/Bugs:
;
;Input:
; 2 boards
;Output:
; word with the top end as a boolean
;
BE_BOARD1	equ	8
BE_BOARD2	equ	12
BE_RETURN	equ	16
boardIsEqual:
	link	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.l	BE_BOARD1(a6),a0
	move.l	BE_BOARD2(a6),a1
	move.l	#FALSE,BE_RETURN(a6)

be_loop_col:
	move.w	LBC(a0),d0
be_loop_row:
	get2D	d1,d0,(a0)
	movea.l	(sp)+,a2	;address of char

	get2D	d1,d0,(a1)
	movea.l	(sp)+,a3

	move.b	(a2),d2
	move.b	(a3),d3

	cmp.b	d2,d3
	bne	be_not_equal

	add.w	#1,d0
	cmp.w	UBC(a0),d0
	bls	be_loop_row
be_next_row:
	addq.w	#1,d1
	cmp.w	UBR(a0),d1
	bls	be_loop_col
	bra	be_exit

be_not_equal:
	move.b	#TRUE,BE_RETURN(a6)

be_exit:
	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts

;word numNeighbors(word row, word col, 2DArray[][])
;Purpose:
; finds the number of life tokens around a given index in a board
;Limitations/Bugs:
;
;Input:
; index for token (word row, word col)
; board pointer
;Output:
; number of life tokens (word)
;
;d0	row
;d1	col
;d2	row lc
;d3	col lc
;d7 	life count
;a0	array
;a1	current pos

NN_ROW		equ	8
NN_COL		equ	10
NN_BOARD	equ	12
NN_RETURN	equ	16

numNeighbors:
	link	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.l	NN_BOARD(a6),a0
	move.w	#-1,d2

nn_row:
	move.w	NN_ROW(a6),d0
	add.w	d2,d0

	move.w	#-1,d3
nn_col:
	move.w	NN_COL(a6),d1	;neighborCol = col + offset
	add.w 	d3,d1

	get2D	d0,d1,(a0) 	;get current neighbor
	move.l	(sp)+,a1
	bmi	nn_next

	tst.b	(a1)		;test if its life
	beq	nn_next
	addq.w	#1,d7

nn_next:
	addq.w	#1,d3		;going to next col
	cmp.w	#2,d3
	beq	nn_next_row
	jmp	nn_col

nn_next_row:
	addq.w	#1,d2
	cmp.w	#2,d2
	bne	nn_row

nn_exit:
	move.w	NN_ROW(a6),d0		;testing if theres already life
	move.w	NN_COL(a6),d1
	get2D	d0,d1,(a0)
	move.l	(sp)+,a1

	tst.b	(a1)
	beq	nn_life
	subq.w	#1,d7
nn_life:
	move.w	d7,NN_RETURN(a6)
	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts


;void copyBoard(gameBoard[][], copyBoard[][])
;Purpose:
; deep copy for a board dope vector
; the values of all indicies in the primary board will be compied
;  into the indicies of the secondary board
;Limitations/Bugs:
;
;Input:
; pointer to primary board
; pointer to secondary board
;Output:
;
;d0 col counter
;d1 row counter
;a0 primary board
;a1 secondary board
;a2 current token in primary board
;a3 current token in secondary board

CP_OLD	equ	8
CP_NEW	equ	12
copyBoard:
	link	a6,#0
	movem.l	d0-d6/a0-a5,-(sp)

	move.l	CP_OLD(a6),a0
	move.l	CP_NEW(a6),a1

	move.w	LBR(a0),d1
cb_loop_col:
	move.w	LBC(a0),d0
cb_loop_row:
	get2D	d1,d0,(a0)
	movea.l	(sp)+,a2	;address of char

	get2D	d1,d0,(a1)
	movea.l	(sp)+,a3

	move.b	(a2),(a3)

	add.w	#1,d0
	cmp.w	UBC(a0),d0
	bls	cb_loop_row
cb_next_row:
	addq.w	#1,d1
	cmp.w	UBR(a0),d1
	bls	cb_loop_col

cb_exit:
	movem.l	(sp)+,d0-d6/a0-a5
	unlk	a6
	rts

	dc.w	'a'
	dc.w	'x'
	dc.w	1
	dc.w	80
	dc.w	1
tempBoard	ds.b	('x'-'a'+1)*(80-1+1)

;void evolve(gameBoard[][])
;Purpose:
;	go to the next state of the board following the rules
;	of Conways Game of Life
; Rules:
;  -if a life has 2 or 3 neighors it stays
;  -if a life has less than 2 neighbors it dies
;  -if a life has more than 3 neighbors it dies
;  -if an empty space has exactly 3 neighbors it comes to life
;
;Limitations/Bugs:
;
;Input:
; pointer to a board
;Output:
; boolean if the board has changed
;  FF if the board has changed
;
;d0 col counter
;d1 row counter
;d2 number of neighbors for a given index
;d3 current char for board
;d4 current char for temp board
;d5 return
;a0 board pointer
;a1 secondary board
;a2 current token for secondary board
;a3 current token for primary board

EV_BOARD	equ	8
EV_RETURN 	equ	12
evolve:
	link	a6,#0
	movem.l	d0-d4/a0-a3,-(sp)

	move.l	EV_BOARD(a6),a0
	lea	tempBoard,a1

	move.b	#FALSE,d5

	move.w	LBR(a0),d1
ev_loop_col:
	move.w	LBC(a0),d0
ev_loop_row:
	getNeighbors	d1,d0,(a0)
	move.w	(sp)+,d2

	get2D	d1,d0,(a0)
	move.l	(sp)+,a3

	get2D	d1,d0,(a1)
	move.l	(sp)+,a2

	cmp.b	#1,d2
	bhi	ev_overpop
	move.b	#NULL,(a2)	;underpopulated
	bra	ev_next
ev_overpop:
	cmp.b	#3,d2
	bls	ev_life
	move.b	#NULL,(a2)	;overpopulated
	bra	ev_next
ev_life:
	beq	ev_add_life
	tst.b	(a3)
	beq	ev_next
ev_add_life:
	move.b	#LIFE,(a2)	;birth

ev_next:

	move.b	(a2),d3
	move.b	(a3),d4
	cmp.b	d3,d4
	beq	ev_no_change
	move.b	#TRUE,d5

ev_no_change:
	add.w	#1,d0		;going to next index in row
	cmp.w	UBC(a0),d0
	bls	ev_loop_row
ev_next_row:
	addq.w	#1,d1		;going to next row
	cmp.w	UBR(a0),d1
	bls	ev_loop_col

ev_exit:
	move.b	d5,EV_RETURN(a6)

	pea	(a0)
	pea	(a1)
	jsr	copyBoard
	add.l	#8,sp

	movem.l	(sp)+,d0-d4/a0-a3
	unlk	a6
	rts


;word runSimulation(char board[][], word generations)
;Purpose:
; applys the rules of life to an input board
;Limitations/Bugs:
;
;Input:
; board pointer
; number of generations to run (word)
;Output:
; return word is reason for stop
;   -1 for reaching end of generations
;   -2 for becoming stagnent
;   -3 for board becoming empty
;
;d0 number of generations to run
;d1 reason for exit
;a0 board pointer
RUN_BOARD	equ	8
RUN_GEN		equ	12
RUN_RETURN	equ	14

runSimulation:
	link	a6,#0
	movem.l	d0-d2/a0,-(sp)

	move.l	RUN_BOARD(a6),a0
	move.w	RUN_GEN(a6),d0
	sub.w	#1,d0
	pea	(a0)
	jsr	printBoard
	add.l	#4,sp

	move.w	#RUN_END,d1

run_loop:
	sub.l	#2,sp
	pea	(a0)
	jsr	evolve
	add.l	#4,sp

	tst.b	(sp)+
	beq	run_stagnent

	jsr	clearScreen
	pea	(a0)
	jsr 	printBoard
	add.l	#4,sp

	move.w	d0,-(sp)
	jsr	writeGen
	add.l	#2,sp

run_next:
	sub.l	#2,sp
	pea	(a0)
	jsr	checkIfEmpty
	adda.l	#4,sp
	tst.b	(sp)+
	bne	run_is_empty


	dbra	d0,run_loop
	bra	run_exit

run_is_empty:
	move.w	#RUN_EMPTY,d1
	bra	run_exit
run_stagnent:
	move.w	#RUN_STAG,d1
run_exit:
	move.w	d1,RUN_RETURN(a6)
	movem.l	(sp)+,d0-d2/a0
	unlk	a6
	rts


runNextText	dc.b	"        Press any key to continue (r to run)",NULL
	even
;;
;;  WRAPPER FUNCTIONS FOR INPUT/OUTPUT AND GEMDOS OPERATIONS


; void writeChar (word char)
;Purpose:
; writes a signle ASCII character to the screen
;Limitations/Bugs:
;
;Input:
; ASCII character
;Output:
;
;d0 character to write

even
WC_CHAR		equ	8
writeChar:
	link 	a6,#0
	movem.l	d0/a0,-(sp)

	move.w	WC_CHAR(a6),d0
	and.w	#$00FF,d0

	move.w	d0,-(sp)
	move.w	#c_conout,-(sp)
	trap	#GEMDOS
	add.l	#4,sp

	movem.l	(sp)+,d0/a0
	unlk	a6
	rts


;Purpose:
;
;Limitations/Bugs:
;
;Input:
;
;Output:
;
;d0			a0
;d1			a1
;d2			a2
;d3			a3
;d4			a4
;d5			a5
;d6
;d7

	even
;char readChar()
readChar:
	link 	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.w	#c_conin,-(sp)
	trap	#GEMDOS
	add.l	#2,sp
	and.w	#$FF,d0
	move.w	d0,8(a6)

	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts

;Purpose:
;
;Limitations/Bugs:
;
;Input:
;
;Output:
;
;d0			a0
;d1			a1
;d2			a2
;d3			a3
;d4			a4
;d5			a5
;d6
;d7

WN_MAX		equ	10000
WN_LOOPS	equ	4
WN_NUM		equ	8
WN_ZERO		equ	'0'
; void writeNumber (UWord num)

;d0	number
;d1	multiple of 10 to divide by
;d7	loop control
writeNumber:
	link	a6,#0
	movem.l	d0/d1/d7,-(sp)
	clr.l	d0
	move.w	WN_NUM(a6),d0
	move.w	#WN_LOOPS,d7
	move.w	#WN_MAX,d1

wn_loop:
	divu.w	d1,d0

	add.w	#WN_ZERO,d0
	move.w	d0,-(sp)
	jsr	writeChar
	add.l	#2,sp

	clr.w	d0
	swap	d0
	divu.w	#10,d1
	dbra	d7,wn_loop
wn_exit:
	movem.l	(sp)+,d0/d1/d7
	unlk	a6
	rts
;Purpose:
;
;Limitations/Bugs:
;
;Input:
;
;Output:
;
;d0			a0
;d1			a1
;d2			a2
;d3			a3
;d4			a4
;d5			a5
;d6
;d7

RS_STRING	equ	8
MAX_LENGTH	equ	12

;void readString(char string[],word maxLength)
readString:
	link	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.w	MAX_LENGTH(a6),d7
	move.l	RS_STRING(a6),a0

rs_read_char:
	sub.l	#2,sp
	jsr	readChar

	move.w	(sp)+,d0
	cmp.b	#CR,d0
	beq	rs_done

	move.b	d0,(a0)+

	dbra	d7,rs_read_char
rs_done:
	move.b	#NULL,(a0)+

	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts

;Purpose:
;
;Limitations/Bugs:
;
;Input:
;
;Output:
;
;d0			a0
;d1			a1
;d2			a2
;d3			a3
;d4			a4
;d5			a5
;d6
;d7

RN_START	equ	1
RN_NUMBER	equ	8
RN_ZERO		equ	'0'
;word readNumber()
readNumber:
	link	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.l	#RN_START,d1
	move.w	#0,-(sp)
rn_read:
	sub.l	#2,sp
	jsr	readChar

	cmp.w	#CR,(sp)
	bne	rn_read


	add.l	#2,sp
	clr.l	d0

rn_convert:
	tst.w	(sp)
	beq	rn_exit

	move.w	(sp)+,d2
	sub.w	#RN_ZERO,d2
	mulu.w	d1,d2
	add.w	d2,d0

	clr.l	d2
	mulu.w	#10,d1
	bra	rn_convert
rn_exit:
	add.l	#2,sp
	move.w	d0,RN_NUMBER(a6)
	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6
	rts

rn_number	ds.b	52

;void writeString(char string[])
;Purpose:
;
;Limitations/Bugs:
;
;Input:
;
;Output:
;
;d0			a0
;d1			a1
;d2			a2
;d3			a3
;d4			a4
;d5			a5
;d6
;d7

WS_STRING	equ	8
writeString:
	link	a6,#0
	movem.l	d0/a0,-(sp)

	move.l	WS_STRING(a6),a0
	clr.w	d0

ws_loop:
	move.b	(a0)+,d0
	tst.b	d0
	beq	ws_exit
	move.w	d0,-(sp)
	jsr	writeChar
	add.l	#2,sp
	bra	ws_loop
ws_exit:
	movem.l	(sp)+,d0/a0
	unlk	a6
	rts

;void writeGen
WG_GEN	equ	8
writeGen:
	link	a6,#0

	jsr	nextLine

	pea	WG_TEXT
	jsr	writeString
	add.l	#4,sp

	move.w	WG_GEN(a6),-(sp)
	jsr	writeNumber
	add.l	#2,sp

	unlk	a6
	rts

WG_TEXT	dc.b	"Generations Left: ",NULL
	even

;char pause()
pause:
	link 	a6,#0
	movem.l	d0-d7/a0-a5,-(sp)

	move.w	#c_necin,-(sp)
	trap	#GEMDOS
	add.l	#2,sp
	and.w	#$FF,d0
	move.w	d0,8(a6)

	movem.l	(sp)+,d0-d7/a0-a5
	unlk	a6

	rts

; void terminate()
terminate:
	move.w	#NULL,-(sp)
	move.w	#p_term,-(sp)
	trap	#GEMDOS
	add.l	#2,sp
	rts

;;
;;  WRAPPER FUNCTIONS FOR VT52 OPERATIONS
;;

CLEAR	equ	'E'

; void writeStatusMessage (char string[])
writeStatusMessage:
	rts


; void clearScreen()
clearScreen:
	move.w	#ESC,-(sp)
	jsr	writeChar
	add.l	#2,sp

	move.w	#CLEAR,-(sp)
	jsr	writeChar
	add.l	#2,sp

	rts

;void nextLine()
nextLine:
	move.w	#CR,-(sp)
	jsr	writeChar
	add.l	#2,sp

	move.w	#LF,-(sp)
	jsr	writeChar
	add.l	#2,sp

	rts




;;
;; FILE OPERATIONS - DO NOT MODIFY
;;

; void loadArray (char array2D[][], char filename[], word& lifeCount,
;		  bool& success)
;
; loadArray prompts the user for the name of a file from which to read
; the initial life configuration.  If the file does not exist the user
; will be re-prompted until a valid file is entered or the user types
; CTRL-c, which will terminate the program.
;
; The file will be read line by line, with each line having the format
; row space column CRLF.  Rows are character values between 'a' and 'x'
; inclusive.  Colunms are numeric values between 1 and 80.  Lines not
; having this format will be ignored and an error message output indicating
; the line and the type of error, if it can be determined.
;
; If the information is valid the specified cell will be initialized with
; life and the life count incremented.  Upon reading the entire file
; the life count will be returned.

; Algorithm
;
; success = true
; error = fileopen(filename, filehandle)
; if error
; then
;   success = false
; else
;   linecount = 1
;   count = 0
;   while error neq EOF
;     error = readline(filehandle, row, column)
;     if error
;     then write type of error at linecount
;     else if valid(row, column)
;          then array[row, column] = '@'
;            count++
;          else write index error at linecount
;     linecount++

; Register Table
;
; d0-d2/
; a0-a2	 used by GEMDOS function calls
;
; d0
; d1	holds column index
; d2	reading the filename - the filename length
;	after access2D - the error flag
; d4	readRowCol error flag
; a2	address of the filename
; a3	address of array[row,col]
; a4	address of success while opening the file
;	address of cellCount while processing file
; a6	framepointer

; Constant Section
;
LA_ARRAY	equ	8		; parameter offsets
LA_FILENAME	equ	12
LA_COUNT	equ	16
LA_SUCCESS	equ	20

LA_Row		equ	-4		; resulting user input
LA_Col		equ	-2

loadArray:
	link	a6,#LA_Row
	movem.l	d0-d2/a0-a4,-(sp)

	move.l	LA_SUCCESS(a6),a4
	move.b	#TRUE,(a4)
	subq.l	#4,sp
	move.l	LA_FILENAME(a6),-(sp)
	jsr	openFile		; open the file
	addq.l	#4,sp
	tst.l	(sp)			; file error?
	bpl	la_skip			; no so process
	tst.l	(sp)+			; yes so clean the stack
	move.b	#FALSE,(a4)
	bra	la_done

la_skip:
	move.w	(sp)+,la_handle		; eliminate junk
	move.w	(sp)+,la_handle		; real handle
	move.l	LA_COUNT(a6),a4
	clr.w	(a4)
	clr.w	la_linecount
	pea	la_home			; clear screen for any error messages
	jsr	writeString
	addq.l	#4,sp

la_loop:
	addq.w	#1,la_linecount		; update linecount
	subq.l	#2,sp			; error flag	0 = no error,
					;		1 = non-numeric col,
					;		2 = format error,
					;		-1 = EOF
	subq.l	#4,sp			; result space row, col
	move.w	la_handle,-(sp)
	jsr	readRowCol
	addq.l	#2,sp
	move.l	(sp)+,LA_Row(a6)	; move row and column in one step
	move.w	(sp)+,d4		; if error flag
	bmi	la_close			; 	eq negative then EOF
	bne	la_input_err		;   ne 0 then input error
	subq.l	#4,sp			; index location
	move.l	LA_ARRAY(a6),-(sp)	; array[row,column]
	move.w	LA_Col(a6),-(sp)	; col
	move.w	LA_Row(a6),-(sp)	; row
	jsr	access2D
	addq.l	#8,sp
	move.l	(sp)+,d2
	bmi	la_invalid_range	; then handle error
	move.l	d2,a3
	addq.w	#1,(a4)			; else increment count
	move.b	#LIFE,(a3)		;      load life value
	bra	la_loop

la_invalid_range:
	cmp.l	#-1,d2			; what type of coordinate error?
	beq	la_bad_row
	pea	la_col_err_msg		;   column index error
	bra	la_writeString
la_bad_row:
	pea	la_row_err_msg		;   row index error
	bra	la_writeString

la_input_err:
	cmp.w	#1,d4			; what type of input error?
	bne	la_general_format	;	neq 1 general format error
	pea	la_bad_col_char		;	eq 1 then a non-numeric col
	bra	la_writeString
la_general_format:
	pea	la_err_msg		; write out general error message
la_writeString:
	jsr	writeString
	addq.l	#4,sp
la_write_num:				; write out the line number
	move.w	la_linecount,-(sp)
	jsr	writeNumber
	addq.l	#2,sp

la_next:
	bra	la_loop

la_close:
	move.w	la_handle,-(sp)		; close the file
	jsr	closefile
	addq.l	#2,sp
la_done:
	movem.l	(sp)+,d0-d2/a0-a4
	unlk	a6
	rts

la_linecount	dc.w	0

la_handle	dc.w	0

la_home	dc.b	ESC,"Y",SP+STATUS-1,SP+SCREENCOLS
					; move cursor to 23,80
	dc.b	ESC,'d'			; clear from home to cursor
	dc.b	ESC,'H',0		; move cursor to home
	EVEN

la_err_msg	dc.b	CR,LF,LF,"Error -- general format error in input file at line ",0

la_bad_col_char	dc.b	CR,LF,LF,"Error -- column value contains non-numeric or exceeds a word on line ",0
la_col_err_msg	dc.b	CR,LF,LF,"Error -- column out of range on line ",0
la_row_err_msg	dc.b	CR,LF,LF,"Error -- row out of range on line ",0
		EVEN


; long openFile (char filename[])
;
; This function attempts to open the file specified by the supplied filename.
; The function forces the default drive to be a, if this fails it forces a handle
; error which will cause the user to have to re-enter a filename, if this happens
; too often the user will probably ctrl-c out.
; If opening the file fails the function will return a -1 which guarantees a negative
; handle.

; Registers
; d0-d2
; a0-a2	used by GEMDOS function calls
;

; constant section
;
O_FILE		EQU	8		; parameter offsets
O_HANDLE	EQU	12

openFile:
	link	a6,#0
	movem.l	a0-a2/d0-d2,-(sp)	; save environment

	move.l	O_FILE(a6),a0
	cmpi.b	#':',1(a0)
	beq	o_open
	move.w	#3,-(sp)		; set the current drive to d:
	move.w	#d_setdrv,-(sp)		; set default drive operation
	trap	#GEMDOS
	addq.l	#4,sp
	btst.l	#3,d0			; drive d is bit 3 did it get set?
	bne	o_open
	pea	o_driveError
	jsr	writeString
	addq.l	#4,sp
	jsr	terminate
					; probably should terminate the program
o_open:
	move.w	#0,-(sp)		; open an input file
	move.l	O_FILE(a6),-(sp)
	move.w	#f_open,-(sp)
	trap	#GEMDOS
	addq.l	#8,sp
	move.l	d0,O_HANDLE(a6)		; store the returned filehandle
	bge	o_done
o_error
	move.l	#-1,O_HANDLE(a6)	; guarantee a complete negative filehandle
o_done
	movem.l	(sp)+,a0-a2/d0-d2 	; restore environment
	unlk	a6
	rts

o_driveError:
	dc.b	"No drive specified and drive D:\ could not be opened",CR,LF
	dc.b	"Program terminating",CR,LF,NULL

; void closefile (int filehandle)
;
; This function attempts to close an open the file.  No error checking is done
;

; Registers
; d0-d2
; a0-a2	used by GEMDOS function calls
;

; constant section
;
C_HANDLE	EQU	8		; parameter offsets

closefile
	link	a6,#0
	movem.l	a0-a2/d0-d2,-(sp)	; save environment

	move.w	C_HANDLE(a6),-(sp)
	move.w	#f_close,-(sp)
	trap	#GEMDOS
	addq.l	#8,sp
c_done
	movem.l	(sp)+,a0-a2/d0-d2 	; restore environment
	unlk	a6
	rts

; _FileRead (int filehandle, char& string, long bytestoread)
; This macro read a specified number of bytes from an open file into a string

_FileRead	macro
	pea	\2			; location at which to store the data
	move.l	\3,-(sp)		; max size of storage space
	move.w	\1,-(sp)		; the file handle
	move.w	#f_read,-(sp)
	trap	#1
	add.l	#12,sp
	endm

; int readRowCol (int filehandle, int& row, int& col)
;
; This function reads a single line of the file and parses it into its component parts,
; i.e. the row letter and a column number.  The row must be a single character, if it is
; not immediately followed by a space an error is flagged.  The column can be of any valid
; numeric value that is word sized.  Encountering a non-numeric or a value larger than a word
; will result in an error.  The line must terminate with a CR and LF.  The function expects
; to encounter the EOF at the start of a newline, encountering it any where else will result
; in a error for that component and the EOF will be found on the next read.  Each error has a
; The error flag values are:
;	EOF		-1
;	NO ERROR	0
;	COLUMN ERROR	1
;	GENERAL ERROR	2
;
; CODING TRICK!!!
; The line is read from the file a character at a time.  A local variable is used to store
; the read character.  This variable is allocated on the stack, however, to keep the stack
; word oriented 2 bytes are actually allocated.  This fact is used to eliminate using an
; additional register for the row.  When reading the row the character is read into the
; low order byte - however, a word value must be returned, thus, when storing the entire
; word is used.

; Register Table
;
; d0	error flag/bytes read from f_read
;	current digit in converting a number
; d1	running total for column number
; d2
; a0-a2	used by GEMDOS function calls
;
; a6	framepointer

; CONSTANTS
;
RRC_HANDLE	equ	8		; parameter offsets
RRC_ROW		equ	10
RRC_COL		equ	12
RRC_ERROR	equ	14
RRC_INPUTB	equ	-1		; offset when reading a byte from the file
RRC_INPUTW	equ	-2		; offset when storing the row index

; local value constants
RRC_EOF		equ	-1		; error flag values
RRC_FALSE	equ	0
RRC_COL_ERR	equ	1
RRC_GENERAL	equ	2

RRC_BYTEStoREAD	equ	1		; number of bytes to read
RRC_WORD_OVER	equ	$FFFF		; used to test high order word after multiplication

readRowCol:
	link	a6,#-2
	movem.l	a0-a2/d0-d2,-(sp)	; save environment

	clr.w	RRC_ERROR(a6)		; error = FALSE
	clr.w	RRC_INPUTW(a6)		; clear high order word of local variable
	_FileRead RRC_HANDLE(A6),RRC_INPUTB(a6),#RRC_BYTEStoREAD ; read byte
	cmp.l	#RRC_BYTEStoREAD,d0	; if readbytes eq 1
	beq	rrc_skip		; then valid read
	move.w	#RRC_EOF,RRC_ERROR(a6)	; else error = EOF
	bra	rrc_done
rrc_skip
	move.w	RRC_INPUTW(a6),RRC_ROW(a6); save the valid row

	_FileRead RRC_HANDLE(A6),RRC_INPUTB(a6),#RRC_BYTEStoREAD
	tst.l	d0			; if readbytes <= 0
	bls	rrc_general_error	; then a general error
	move.w	RRC_INPUTW(a6),d0
	cmp.b	#SP,d0			; else if char neq space
	bne	rrc_general_error		; then a general error

	clr.l	d0			; clear high order bytes for math ops
	clr.l	d1			; total = 0

rrc_repeat
	_FileRead RRC_HANDLE(A6),RRC_INPUTB(a6),#RRC_BYTEStoREAD
	tst.l	d0
	bls	rrc_general_error
	move.w	RRC_INPUTW(a6),d0	; while char neq CR
	cmp.b	#CR,d0
	beq	rrc_save
	cmpi.b	#'0',d0			; IF (digit < '0') OR (digit > '9')
	blo	rrc_col_error		; THEN invalid input
	cmpi.b	#'9',d0			; ELSE
	bhi	rrc_col_error
	subi.b	#'0',d0			;   digit = char - '0'
	mulu.w	#10,d1			;   total = total * 10
	swap	d1			;   check for exceeding a word the long way
	andi.w	#RRC_WORD_OVER,d1	;   since mulu DOESN'T set C bit
	bne	rrc_col_error
	swap	d1			;   if valid then restore total
	add.w	d0,d1			;   total += digit
	bcs	rrc_col_error		;   if carry set then error
	bra	rrc_repeat
rrc_save
	move.w	d1,RRC_COL(a6)
	bra	rrc_read_junk
rrc_general_error
	move.w	#RRC_GENERAL,RRC_ERROR(a6)
	bra	rrc_read_junk
rrc_col_error
	move.w	#RRC_COL_ERR,RRC_ERROR(a6)
rrc_read_junk
	cmp.b	#LF,d0
	beq	rrc_done
	_FileRead RRC_HANDLE(A6),RRC_INPUTB(a6),#RRC_BYTEStoREAD
	tst.l	d0			; while char neq LF and not error
	beq	rrc_done
	move.w	RRC_INPUTW(a6),d0
	bra	rrc_read_junk

rrc_done
	movem.l	(sp)+,a0-a2/d0-d2 	; restore environment
	unlk	a6
	rts

; void saveFile(char array[][], char filename[])

; algorithm
;
; error = f_open(filename, writemode)
; if error
; then write "file error - nothing saved"
; else
;   for row = LBR to UBR
;     for col = LBC to UBC
;       if array[row, col] = '@'
;       then
;         string[0] = row
;         string[1] = ' '
;         strlength = 2
;         NumToString (string, col, strlength)
;         string[strlength] = CRLF
;         strlength += 2
;         f_write (string, filehandle, strlength)
;    f_close (filehandle)

; Register Table
;
; d0-d2/
; a0-a2	used by GEMDOS function calls
; d0	GEMDOS file operation return codes
; d1	filename length
; d3	row index
; d4
; d5	column index
; d7	length of the save line, for f_write
;
; a3	array address
; a4	address of filename, excluding c_conrs length info
; a5	address with the save line that is currently being used
;

; constant section
;
SV_ARRAY	equ	8		; parameter offsets
SV_FILE		equ	12

saveFile:
	link	a6,#0
	movem.l	a0-a5/d0-d7,-(sp)	; save environment

	clr.w	-(sp)			; normal file
	move.l	SV_FILE(a6),-(sp)		; filename
	move.w	#f_create,-(sp)
	trap	#GEMDOS
	addq.l	#8,sp
	tst.l	d0			; successful file open?
	bpl	sv_writeout		; no so write error message
	pea	sv_fileerror		; and terminate
	jsr	writeStatusMessage
	addq.l	#4,sp
	bra	sv_exit
sv_writeout				; yes so write array to file
	move.w	d0,sv_handle
	move.l	SV_ARRAY(a6),a3		; life array
	move.w	LBR(a3),d3
sv_row_loop
	cmp.w	UBR(a3),d3		; while row_index <= UBR
	bhi	sv_done
	move.w	LBC(a3),d5		; col_index = LBC
sv_col_loop
	cmp.w	UBC(a3),d5		; while col_index <= UBC
	bhi	sv_next_row

	subq.l	#4,sp			; location of array[row_index, col_index]
	move.l	a3,-(sp)
	move.w	d5,-(sp)
	move.w	d3,-(sp)
	jsr	access2D
	addq.l	#8,sp
	move.l	(sp)+,a4		; no need to error check since row/col must be valid

	cmpi.b	#LIFE,(a4)		; if array[row,col] == '@'
	bne	sv_next_col
	lea	sv_line,a5
	move.l	#5,d7			; line length = 5, at minimum
	move.b	d3,(a5)+		; line[0] = row
	move.b	#SP,(a5)+		; line[1] = ' '

	move.w	d5,d0
	cmpi.w	#10,d0			; if col_index >= 10
	blo	sv_one_digit		; then
	addq.l	#1,d7			;	line length ++
	divu	#10,d0			; split into first and second digit
	move.b	d0,(a5)			; line[2] = first
	add.b	#'0',(a5)+
	swap	d0
sv_one_digit
	move.b	d0,(a5)			; line[3] = second OR line[2] = digit
	add.b	#'0',(a5)+
	move.b	#CR,(a5)+		; add CR and LF to line
	move.b	#LF,(a5)+

	pea	sv_line			; write line to file
	move.l	d7,-(sp)
	move.w	sv_handle,-(sp)
	move.w	#f_write,-(sp)
	trap	#GEMDOS
	add.l	#12,sp

sv_next_col
	addq.l	#1,d5			; col++
	bra	sv_col_loop
sv_next_row
	addq.l	#1,d3			; row++
	bra	sv_row_loop
sv_done
	move.w	sv_handle,-(sp)		; close the file
	jsr	closefile
	addq.l	#2,sp
sv_exit
	movem.l	(sp)+,a0-a5/d0-d7 	; restore environment
	unlk	a6
	rts

sv_handle	dc.w	0
sv_fileerror
			dc.b "Requested file could not be opened - save terminated",0
sv_line		ds.b	7
	even
