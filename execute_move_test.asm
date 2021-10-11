.data
origin_pocket: .byte 5
.align 2
state:        
    .byte 0         # bot_mancala       	(byte #0)
    .byte 1         # top_mancala       	(byte #1)
    .byte 6         # bot_pockets       	(byte #2)
    .byte 6         # top_pockets        	(byte #3)
    .byte 2         # moves_executed	(byte #4)
    .byte 'B'    # player_turn        		(byte #5)
    # game_board                     		(bytes #6-end)
    .asciiz
    "0108070601000404040404040400"
.text
.globl main
main:
la $a0, state
lb $a1, origin_pocket
jal execute_move
# You must write your own code here to check the correctness of the function implementation.

mult	$t0, $t1			# $t0 * $t1 = Hi and Lo registers
mflo	$t2					# copy Lo to $t2

div		$t0, $t1			# $t0 / $t1
mflo	$t2					# $t2 = floor($t0 / $t1) 
mfhi	$t3					# $t3 = $t0 mod $t1 

li $v0, 10
syscall

.include "hw3.asm"
