# Starr Xu

############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

.text

load_game:
	# Args: $a0=state,$a1=board_filename
	
	addi, $sp, $sp, -32	# Allocate space on the stack
	# Save all $s registers that are going to be used
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	
	# Save args in $s0 and $s1, respectively
	move $s0, $a0
	move $s1, $a1
	
	# Open file
	li $v0, 13
	move $a0, $a1	# Move address of filename to $a0
	li $a1, 0	# flag = 0 -> read only
	li $a2, 0	# Ignore mode
	syscall
	
	# If operation failed, go to file_nonexistent
	bltz $v0, file_nonexistent
	
	move $s2, $v0	# Save file descriptor in $s2
	
	addi, $sp, $sp, -4	# Allocate 4 bytes on the stack
	addi $t5, $0, 0		# Initialize a counter $t5 to keep track of lines
	addi $t6, $0, 0		# Initialize a helper variable $t6
	addi $s6, $0, 0		# Initialize a variable $s6 for saved results
	addi $t7, $0, 0		# Another helper variable for the last two lines
	addi $s4, $0, 0		# Total number of stones
	addi $s5, $0, 0		# Total number of pockets
	move $s7, $s0		# Helper variable for game_board
	
	# Else read contents of file byte by byte (char by char)
	# and initialize GameState struct
	read_content:
		li $v0, 14
		move $a0, $s2	# Move file descriptor to $a0
				# to store character
		move $a1, $sp	# Store address of output buffer in $a1
		li $a2, 1	# Buffer length = 1
		syscall
	
		# If $v0<=0, go to close_file
		blez $v0, close_file
		
		lbu $s3, 0($sp) 	# Save read character in $s3
		
		# If $s3='\n' or $s3='\r'
		addi $t0, $0, '\n'
		addi $t1, $0, '\r'
		beq $s3, $t0, initialize_state	# Go to initialize_state when $s3='\n'
		beq $s3, $t1, read_content
		# Otherwise, jump to convert_int
		j convert_str_to_int

	# Convert string to int
	convert_str_to_int:
		# If on line 4 or 5, increment $t7
		addi $t0, $0, 3
		blt $t5, $t0, skip_increment
		addi $t7, $t7, 1
		
		skip_increment:
		addi $t0, $s3, -48	# Convert current char to an int and store it in $t0
		beqz $t6, set_it	# If $t6=0 then set $s6=$t0
		addi $t1, $0, 10	# Let $t1=10
		mult $s6, $t1		# Multiply saved integer result $s6 by 10
		mflo $s6		# $s6=$s6*10
		add $s6, $s6, $t0
		j check_this
		set_it:
		addi $s6, $t0, 0 	# Set $s6=$t0
		addi $t6, $0, 1		# $t6=1 after first character
		j check_this
		
		# If on line 4 or 5, go to initialize_state every byte
		# Else go to read_contents
		check_this:
		addi $t0, $0, 3
		blt $t5, $t0, read_content
	
	# Initialize state (stored in $s0)
	initialize_state:
		first_line:
			addi $t0, $0, 0
			bne $t5, $t0, second_line
			add $s4, $s4, $s6	# Update number of stones
			sb $s6, 1($s0)		# Store number of stones in top_mancala
			j increment_line_counter
		second_line:
			addi $t0, $0, 1
			bne $t5, $t0, third_line
			add $s4, $s4, $s6	# Update number of stones
			sb $s6, 0($s0)		# Store number of stones in bot_mancala
			j increment_line_counter
		third_line:
			addi $t0, $0, 2
			bne $t5, $t0, fourth_line
			sll $s5, $s6, 1		# Multiply number of pockets per row by two
						# to get the total number of pockets
			sb $s6, 2($s0)		# Store number of pockets per row in bot_pockets
			sb $s6, 3($s0)		# Store number of pockets per row in top_pockets
			sb $0, 4($s0)		# Store the value of 0 in moves_executed
			addi $t0, $0, 'B'
			sb $t0, 5($s0)		# player_turn starts with P1 'B'
			j increment_line_counter
		fourth_line:
			addi $t0, $0, 3
			bne $t5, $t0, fifth_line
			
			# If character is newline then go to read_contents
			addi $t0, $0, '\n'
			beq $s3, $t0, read_content
			
			sb $s3, 8($s7)		# Store contents of top row in game_board
			addi $s7, $s7, 1	# Increment pointer
			
			# Update number of stones for every two bytes read,
			# i.e., when $t7=2
			addi $t0, $0, 2
			bne $t7, $t0, read_content
			add $s4, $s4, $s6	# Update number of stones
			addi $t6, $0, 0		# Reset $t6=0
			addi $t7, $0, 0		# Reset $t7=0
			
			j read_content
		fifth_line:
			
			# If character is newline then go to read_contents
			addi $t0, $0, '\n'
			beq $s3, $t0, read_content
			
			sb $s3, 8($s7)		# Store contents of bot row in game_board
			addi $s7, $s7, 1	# Increment pointer
			
			# Update number of stones for every two bytes read,
			# i.e., when $t7=2
			addi $t0, $0, 2
			bne $t7, $t0, read_content
			add $s4, $s4, $s6	# Update number of stones
			addi $t6, $0, 0		# Reset $t6=0
			addi $t7, $0, 0		# Reset $t7=0
			
			j read_content		# Loop to read each character
	
	increment_line_counter:
		addi $t5, $t5, 1	# Increment $t5
		addi $t6, $0, 0		# Set $t6=0
		j read_content
	
	close_file:
		addi, $sp, $sp, 4	# Deallocate the 4 bytes
		move $s3, $v0		# Store return value of read operation in $s3
	
		# Close file after done reading
		li $v0, 16
		move $a0, $s2		# Move file descriptor to $a0
		syscall
	
	# If total number of stones exceeds 99, then return $v0=0
	addi $t0, $0, 99
	ble $s4, $t0, stones_not_exceeded
	addi $v0, $0, 0
	j check_pockets
	stones_not_exceeded:
	addi $v0, $0, 1
	
	# If total number of pockets exceeds 98, then return $v1=0
	check_pockets:
	addi $t0, $0, 98
	ble $s5, $t0, pockets_not_exceeded
	addi $v1, $0, 0
	j done_read
	pockets_not_exceeded:
	move $v1, $s5
	
	done_read:
	# Store top and bot mancala in game_board
		lbu $t0, 0($s0)		# $t0 = number of stones in bot_mancala
		lbu $t1, 1($s0)		# $t1 = number of stones in top_mancala
	
		# Convert integer to character and store bot_mancala in game_board according to format
		addi $t2, $0, 10
		div $t0, $t2
		mflo $t3
		mfhi $t4
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		# Store bot_mancala in game_board
		sb $t3, 8($s7)
		addi $s7, $s7, 1
		sb $t4, 8($s7)
		
		# Convert integer to character and store top_mancala in game_board according to format
		addi $t2, $0, 10
		div $t1, $t2
		mflo $t3
		mfhi $t4
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		# Store top_mancala in game_board
		sb $t3, 6($s0)
		sb $t4, 7($s0)

	# If successfully read and initialized, go to done_load_game:
	beqz $s3, done_load_game
	
	# If the file does not exist or there's an error
	# with the open/read operations, return $v0=-1,$v1=-1
	file_nonexistent:
		li $v0, -1
		li $v1, -1
	done_load_game:
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		lw $s4, 16($sp)
		lw $s5, 20($sp)
		lw $s6, 24($sp)
		lw $s7, 28($sp)
		addi, $sp, $sp, 32	# Deallocate stack
		jr $ra
get_pocket:
	# Args: $a0=state,$a1=player (1 byte ASCII),$a2=distance (1 byte unsigned)
	addi $t0, $0, 'B'
	addi $t1, $0, 'T'
	beq $a1, $t0, valid_B
	beq $a1, $t1, valid_T
	j invalid_args
	valid_B:
		# If distance is not valid, return $v0=-1
		bltz $a2, invalid_args	# If distance is negative,
					# branch to invalid_args
		lbu $t0, 2($a0)		# Load bot_pockets in $t0
		bge $a2, $t0, invalid_args	# If distance $a2>=bot_pockets,
						# branch to invalid_args
						
		# Else if valid, return the integer value of the number of stones
		# at the designated pocket
		sll $t0, $t0, 2
		
		sll $t2, $a2, 1
		sub $t1, $t0, $t2
		add $a0, $a0, $t1
		
		# Extract two ASCII bytes (reverse order)
		lbu $t2, 6($a0)
		addi $t2, $t2, -48
		lbu $t3, 7($a0)
		addi $t3, $t3, -48
		addi $t0, $0, 10
		mult $t2, $t0
		mflo $v0
		add $v0, $v0, $t3
		
		j done_get_pocket
	valid_T:
		# If distance is not valid, return $v0=-1
		bltz $a2, invalid_args	# If distance is negative,
					# branch to invalid_args
		lbu $t0, 3($a0)		# Load top_pockets in $t0
		bge $a2, $t0, invalid_args	# If distance $a2>=top_pockets,
						# branch to invalid_args
		# Else if valid, return the integer value of the number of stones
		# at the designated pocket
		
		sll $t1, $a2, 1		# Multiply distance by 2;
					# This is the offset
		add $a0, $a0, $t1
		
		# Extract two ASCII bytes
		lbu $t2, 8($a0)
		addi $t2, $t2, -48
		lbu $t3, 9($a0)
		addi $t3, $t3, -48
		addi $t0, $0, 10
		mult $t2, $t0
		mflo $v0
		add $v0, $v0, $t3

		j done_get_pocket
	invalid_args:
		addi $v0, $0, -1
	done_get_pocket:
		jr $ra
set_pocket:
	# Args: $a0=state, $a1=player, $a2=distance, $a3=size
	
	# Check if player is valid
	addi $t0, $0, 'B'
	addi $t1, $0, 'T'
	beq $a1, $t0, valid_B_2
	beq $a1, $t1, valid_T_2
	j invalid_args_2
	
	valid_B_2:
		# If distance is not valid, return $v0=-1
		bltz $a2, invalid_args_2	# If distance is negative,
						# branch to invalid_args_2
		lbu $t0, 2($a0)		# Load bot_pockets in $t0
		bge $a2, $t0, invalid_args_2	# If distance $a2>=bot_pockets,
						# branch to invalid_args_2
		
		# Check if 0<=size<=99
		bltz $a3, invalid_args_size
		addi $t1, $0, 99
		bgt $a3, $t1, invalid_args_size
		
		lbu $t0, 2($a0)
		sll $t0, $t0, 2
		sll $t2, $a2, 1
		sub $t1, $t0, $t2
		add $a0, $a0, $t1
		
		addi $t0, $0, 10
		div $a3, $t0
		mflo $t3
		mfhi $t4
		
		# Convert to char
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		sb $t3, 6($a0)
		sb $t4, 7($a0)
		
		addi $v0, $a3, 0
		j done_set_pocket
	valid_T_2:
		# If distance is not valid, return $v0=-1
		bltz $a2, invalid_args_2	# If distance is negative,
						# branch to invalid_args_2
		lbu $t0, 3($a0)		# Load top_pockets in $t0
		bge $a2, $t0, invalid_args_2	# If distance $a2>=top_pockets,
						# branch to invalid_args_2
		
		# Check if 0<=size<=99
		bltz $a3, invalid_args_size
		addi $t1, $0, 99
		bgt $a3, $t1, invalid_args_size
		
		# Set pocket
		sll $t1, $a2, 1		# Multiply distance by 2;
					# This is the offset
		add $a0, $a0, $t1
		
		addi $t0, $0, 10
		div $a3, $t0
		mflo $t3
		mfhi $t4
		
		# Convert to char
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		sb $t3, 8($a0)
		sb $t4, 9($a0)
		
		addi $v0, $a3, 0
		j done_set_pocket
	invalid_args_size:
		addi $v0, $0, -2
		j done_set_pocket
	invalid_args_2:
		addi $v0, $0, -1
	done_set_pocket:
		jr $ra
collect_stones:
	# Args: $a0=state, $a1=player, $a2=stones
	
	# Check if player is valid; return $v0=-1, if not
	addi $t0, $0, 'T'
	addi $t1, $0, 'B'
	beq $a1, $t0, valid_top_p
	beq $a1, $t1, valid_bot_p
	j invalid_args_player
	
	valid_top_p:
		# Check if value of stones is valid; return $v0=-2, if not
		blez $a2, invalid_args_stones
		
		# Update top_mancala
		lbu $t0, 1($a0)
		add $t1, $t0, $a2
		sb $t1, 1($a0)
		
		# Convert int to char
		addi $t0, $0, 10
		div $t1, $t0
		mflo $t3
		mfhi $t4
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		# Update game_board
		sb $t3, 6($a0)
		sb $t4, 7($a0)
		
		addi $v0, $a2, 0
		j done_collect_stones
	valid_bot_p:
		# Check if value of stones is valid; return $v0=-2, if not
		blez $a2, invalid_args_stones
		
		# Update bot_mancala
		lbu $t0, 0($a0)
		add $t1, $t0, $a2
		sb $t1, 0($a0)
		
		# Convert int to char
		addi $t0, $0, 10
		div $t1, $t0
		mflo $t3
		mfhi $t4
		addi $t3, $t3, 48
		addi $t4, $t4, 48
		
		# Update game_board
		lbu $t5, 2($a0)
		sll $t5, $t5, 2
		addi $t5, $t5, 2
		add $a0, $a0, $t5
		
		sb $t3, 6($a0)
		sb $t4, 7($a0)
		
		addi $v0, $a2, 0
		j done_collect_stones
	invalid_args_stones:
		addi $v0, $0, -2
		j done_collect_stones
	invalid_args_player:
		addi $v0, $0, -1
	done_collect_stones:
		jr $ra
verify_move:
	# Args: $a0=state, $a1=origin_pocket, $a2=distance
	
	# Special case when $a2=99 (ignore validating origin_pocket
	# and return 2)
	addi $t0, $0, 99
	bne $a2, $t0, validate_origin_pocket
	# If player_turn='B' then update it to 'T' else 'B'
	lbu $t0, 5($a0)		# player_turn
	addi $t1, $0, 'B'
	beq $t0, $t1, update_B_to_T
	# Else update 'T' to 'B'
	addi $t0, $0, 'B'
	sb $t0, 5($a0)
	j special_case
	
	update_B_to_T:
	addi $t0, $0, 'T'
	sb $t0, 5($a0)
	
	special_case:
	# Increment moves_executed by 1 when distance=99
	lbu $t0, 4($a0)
	addi $t0, $t0, 1
	sb $t0, 4($a0)
	addi $v0, $0, 2
	j done_verify_move
	
	validate_origin_pocket:
		lbu $t0, 2($a0)		# $t0=row size
		# Check if origin_pocket is valid (i.e., 0<=$a1<row size); return $v0=-1, if not
		bge $a1, $t0, invalid_args_origin_pocket
		bltz $a1, invalid_args_origin_pocket
	
		lbu $t0, 5($a0)		# $t0=current player's turn; either 'T' or 'B'
		addi $t1, $0, 'T'
		bne $t0, $t1, current_player_B
	
		# Didn't branch; Current player is 'T'
	
		sll $t0, $a1, 1		# Offset
		add $a0, $a0, $t0
	
		lbu $t3, 8($a0)
		lbu $t4, 9($a0)
	
		j continue_validation
		
		# Current player is 'B'
		current_player_B:
		
		lbu $t0, 2($a0)
		sll $t0, $t0, 2
		sll $t1, $a1, 1
		sub $t2, $t0, $t1
		add $a0, $a0, $t2
		
		lbu $t3, 6($a0)
		lbu $t4, 7($a0)
	
		continue_validation:
		# Convert char to int
		addi $t3, $t3, -48
		addi $t4, $t4, -48
	
		addi $t0, $0, 10
		mult $t3, $t0
		mflo $t3
		add $t5, $t3, $t4	# $t5=number of stones in origin_pocket
	
		# Check if origin_pocket has 0 stones; return $v0=0, if true
		beqz $t5, origin_pocket_zero
	
		# Else if $a2=0 or $a2!=number of stones in origin_pocket
		# then return $v0=-2
		beqz $a2, invalid_args_distance
		bne $a2, $t5, invalid_args_distance
		
		# Else it is a legal move so return $v0=1
		addi $v0, $0, 1
		j done_verify_move
		
	invalid_args_distance:
		addi $v0, $0, -2
		j done_verify_move
	origin_pocket_zero:
		addi $v0, $0, 0
		j done_verify_move
	invalid_args_origin_pocket:
		addi $v0, $0, -1
	done_verify_move:
		jr  $ra
execute_move:
	# Args: $a0=state, $a1=origin_pocket (index)
	addi, $sp, $sp, -36	# Allocate space on the stack
	# Save all $s registers that are going to be used
	# Save return address since execute_move is a non-leaf function
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	sw $ra, 32($sp)
	
	# Save the arguments of execute_move in $s registers
	move $s0, $a0
	move $s1, $a1
	
	# Use get_pocket to get the number of stones
	# in the player's origin_pocket
	move $a2, $a1
	lbu $a1, 5($a0)
	jal get_pocket
	move $s2, $v0	# Store number of stones in origin_pocket in $s2
	
	# Set the number of stones in origin_pocket to 0
	move $a0, $s0
	lbu $a1, 5($s0)
	move $a2, $s1
	addi $a3, $0, 0
	jal set_pocket
	
	addi $s3, $0, 0		# $s3 will store the total number of
				# stones to be deposited in the player's mancala
	lbu $t4, 5($s0)		# $t4=player_turn
	lbu $s5, 2($s0)		# $s5=number of pockets per row
	
	# Go to corresponding player's next pocket
	addi $t0, $0, 'T'
	bne $t4, $t0, bottom_row
	
	# Top row
	sll $t1, $s1, 1
	add $s6, $s0, $t1	# $s6=index of current pocket in 2d array
	addi $s4, $s0, 0	# $s4=current player's mancala
	sll $t0, $s5, 2
	addi $t0, $t0, 2
	add $s7, $s0, $t0	# $s7=other player's mancala
	
	j while_depositing
	
	# Bottom row
	bottom_row:
		sll $t0, $s5, 2
		addi $t0, $t0, 2
		add $s4, $s0, $t0	# $s4=current player's mancala
		sll $t1, $s1, 1
		sub $t0, $t0, $t1
		add $s6, $s0, $t0	# $s6=index of current pocket in 2d array
		addi $s7, $s0, 0	# $s7=other player's mancala
		
	while_depositing:
		
		# If current pocket is the current player's mancala
		bne $s6, $s4, other_player_mancala
		
		addi $s3, $s3, 1	# Increment $s3
		addi $s2, $s2, -1	# Decrement #s2
		
		# If $s2=0, then don't update $s6 and return $v1=2
		beqz $s2, last_deposit_in_player_mancala
		
		# If $s6 is the top mancala,
		# then update current pocket by setting $s6=2*(size of row)+2+$s0
		# Else set $s6=2*(size of row)+$s0
		update_current_pocket_mancala:
		bne $s6, $s0, bottom_mancala_case
		sll $t0, $s5, 1
		addi $t0, $t0, 2
		add $s6, $s6, $t0
		j check_stones_to_be_deposited
		
		bottom_mancala_case:
		sll $t0, $s5, 1
		addi $t0, $t0, 2
		sub $s6, $s6, $t0
		j check_stones_to_be_deposited
		
		other_player_mancala:
		bne $s6, $s7, not_mancala
		j update_current_pocket_mancala
		
		not_mancala:
		# Check if in top row or bottom row
		# If $s6>=2*(size of row)+2+$s0, then bottom row
		# Else top row
		sll $t0, $s5, 1
		addi $t0, $t0, 2
		add $t0, $t0, $s0
		bge $s6, $t0, bottom_row_case
		# Top row
		# Call get_pocket and set_pocket to update pocket value
		move $a0, $s0
		li $a1, 'T'
		sub $t1, $s6, $s0
		srl $t1, $t1, 1
		addi $a2, $t1, -1
		jal get_pocket
		
		addi $a3, $v0, 1
		move $a0, $s0
		li $a1, 'T'
		sub $t1, $s6, $s0
		srl $t1, $t1, 1
		addi $a2, $t1, -1
		jal set_pocket
		
		addi $s6, $s6, -2
		addi $s2, $s2, -1
		
		# If current player_turn='T', updated number of stones
		# in the previous pocket is 1, and $s2=0,
		# then return $v1=1
		lbu $t0, 5($s0)
		addi $t1, $0, 'T'
		bne $t0, $t1, check_stones_to_be_deposited
		addi $t0, $0, 1
		bne $v0, $t0, check_stones_to_be_deposited
		bnez $s2, while_depositing
		
		j last_deposit_steal
			
		# Bottom row
		bottom_row_case:
		# Call get_pocket and set_pocket to update pocket value
		move $a0, $s0
		li $a1, 'B'
		sll $t0, $s5, 2
		addi $t0, $t0, 2
		add $t0, $s0, $t0
		sub $t1, $t0, $s6
		srl $t1, $t1, 1
		addi $a2, $t1, -1
		jal get_pocket
		
		addi $a3, $v0, 1
		move $a0, $s0
		li $a1, 'B'
		sll $t0, $s5, 2
		addi $t0, $t0, 2
		add $t0, $s0, $t0
		sub $t1, $t0, $s6
		srl $t1, $t1, 1
		addi $a2, $t1, -1
		jal set_pocket
		
		addi $s6, $s6, 2
		addi $s2, $s2, -1
		
		# If current player_turn='B', updated number of stones
		# in the previous pocket is 1, and $s2=0,
		# then return $v1=1
		lbu $t0, 5($s0)
		addi $t1, $0, 'B'
		bne $t0, $t1, check_stones_to_be_deposited
		addi $t0, $0, 1
		bne $v0, $t0, check_stones_to_be_deposited
		bnez $s2, while_depositing
		
		j last_deposit_steal
		
		j check_stones_to_be_deposited
		
		# Check if there are still stones to be deposited in $s2
		check_stones_to_be_deposited:
		beqz $s2, last_deposit_else
		j while_depositing

	last_deposit_else:
	addi $v1, $0, 0
	j done_execute_move
	
	last_deposit_steal:
	addi $v1, $0, 1
	j done_execute_move
	
	last_deposit_in_player_mancala:
	addi $v1, $0, 2
	
	done_execute_move:
	# Update contents of GameState
	# Update player's mancala using collect_stones function
	move $a0, $s0
	lbu $a1, 5($s0)
	move $a2, $s3
	jal collect_stones
	
	# Update player_turn and increment moves_executed by 1
	# by using verify_move special case with distance = 99
	# (skip if last deposit was in player's mancala)
	addi $t0, $0, 2
	beq $v1, $t0, skip_update_player_turn
	move $a0, $s0
	li $a2, 99
	jal verify_move
	j return_from_execute_move
	
	skip_update_player_turn:
	# Increment moves_executed by 1 (since verify_move was not called)
	# This is the case when last deposit was in player's mancala
	lbu $t0, 4($s0)
	addi $t0, $t0, 1
	sb $t0, 4($s0)
	
	return_from_execute_move:
	move $v0, $s3
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	lw $ra, 32($sp)
	addi $sp, $sp, 36
	jr $ra
steal:
	# Args: $a0=state, $a1=destination_pocket
	
	addi $sp, $sp, -24
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s3, 8($sp)
	sw $s4, 12($sp)
	sw $s5, 16($sp)
	sw $ra, 20($sp)
	
	# Save arguments $a0 and $a1 of steal function in 
	# $s0 and $s1, respectively
	move $s0, $a0
	move $s1, $a1
	
	addi $t0, $0, 'B'
	lbu $s3, 5($s0)		# $s3=current player_turn
	# If current player_turn='B' then
	# set previous player_turn to 'T' else 'B'
	beq $s3, $t0, set_previous_player_turn_T
	addi $s4, $0, 'B'	# $s4=previous player_turn
	j finished_setting_previous_player
	
	set_previous_player_turn_T:
	addi $s4, $0, 'T'	# $s1=previous player_turn
	
	finished_setting_previous_player:
	# Call get_pocket and set_pocket on previous player and
	# save number of stones in a variable
	
	move $a0, $s0
	move $a1, $s4
	move $a2, $s1
	jal get_pocket
	move $s5, $v0	# $s5=number of stones in pocket
	
	move $a0, $s0
	move $a1, $s4
	move $a2, $s1
	addi $a3, $0, 0
	jal set_pocket
	
	move $a0, $s0
	move $a1, $s3
	lbu $t0, 2($s0)
	addi $t0, $t0, -1
	sub $a2, $t0, $s1
	jal get_pocket
	add $s5, $s5, $v0	# Add number of stones to $s5
	
	move $a0, $s0
	move $a1, $s3
	lbu $t0, 2($s0)
	addi $t0, $t0, -1
	sub $a2, $t0, $s1
	addi $a3, $0, 0
	jal set_pocket
	
	move $a0, $s0
	move $a1, $s4
	move $a2, $s5
	jal collect_stones
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	lw $s5, 16($sp)
	lw $ra, 20($sp)
	addi $sp, $sp, 24
	
	jr $ra
check_row:
	# Args: $a0=state
	
	addi $sp, $sp, -28
	sw $s0, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp)
	sw $s4, 12($sp)
	sw $s5, 16($sp)
	sw $s6, 20($sp)
	sw $ra, 24($sp)
	
	move $s0, $a0
	
	# Check if top row is empty
	addi $s3, $0, 0
	lbu $s4, 2($s0)		# $s4=row size
	check_top_row:
	move $a0, $s0
	addi $a1, $0, 'T'
	move $a2, $s3
	jal get_pocket
	bnez $v0, reset_index_variable
	addi $s3, $s3, 1
	beq $s3, $s4, top_is_empty
	j check_top_row
	
	reset_index_variable:
	addi $s3, $0, 0
	
	check_bottom_row:
	move $a0, $s0
	addi $a1, $0, 'B'
	move $a2, $s3
	jal get_pocket
	bnez $v0, both_not_empty
	addi $s3, $s3, 1
	beq $s3, $s4, bottom_is_empty
	j check_bottom_row
	
	top_is_empty:
	li $s6, 'B'
	addi $s2, $0, 0
	addi $s5, $0, 0
	j update_game_board_one_is_empty
	
	bottom_is_empty:
	li $s6, 'T'
	addi $s2, $0, 0
	addi $s5, $0, 0
	
	update_game_board_one_is_empty:
	move $a0, $s0
	move $a1, $s6
	move $a2, $s2
	jal get_pocket
	add $s5, $s5, $v0
	
	move $a0, $s0
	move $a1, $s6
	move $a2, $s2
	addi $a3, $0, 0
	jal set_pocket
	
	addi $s2, $s2, 1
	blt $s2, $s4, update_game_board_one_is_empty
	
	move $a0, $s0
	move $a1, $s6
	move $a2, $s5
	jal collect_stones
	
	addi $t0, $0, 'D'
	sb $t0, 5($s0)
	addi $v0, $0, 1
	j winner
	
	both_not_empty:
	addi $v0, $0, 0
	
	winner:
	lbu $t0, 0($s0)		#$t0=bot_mancala (P1)
	lbu $t1, 1($s0)		#t1=top_mancala (P2)
	bgt $t0, $t1, player_one_wins
	bgt $t1, $t0, player_two_wins
	addi $v1, $0, 0		# Else tie
	j done_check_row
	
	player_one_wins:
	addi $v1, $0, 1
	j done_check_row
	player_two_wins:
	addi $v1, $0, 2
	
	done_check_row:
	lw $s0, 0($sp)
	lw $s2, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	lw $s5, 16($sp)
	lw $s6, 20($sp)
	lw $ra, 24($sp)
	addi $sp, $sp, 28
	jr $ra
	
load_moves:
	# Args: $a0=moves, $a1=filename
	
	addi $sp, $sp, -32
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	
	move $s0, $a0
	move $s1, $a1
	addi $sp, $sp, -4
	
	# Open file
	li $v0, 13
	move $a0, $a1	# Move address of filename to $a0
	li $a1, 0	# flag = 0 -> read only
	li $a2, 0	# Ignore mode
	syscall
	
	# If operation failed, go to error_accessing_file
	bltz $v0, error_accessing_file
	
	move $s2, $v0	# Store file descriptor in $s2
	addi $s4, $0, 0		# $s4=column size
	addi $s5, $0, 0		# $s5=row size
	addi $t4, $0, 0		# Counter variable for column
	addi $t5, $0, 0		# Counter variable for row
	addi $s7, $0, 0		# Total number of moves in file
	
	# Read contents of first line
	read_first_line:
	li $v0, 14
	move $a0, $s2	# Move file descriptor to $a0
			# to store character
	move $a1, $sp	# Store address of output buffer in $a1
	li $a2, 1	# Buffer length = 1
	syscall
	
	# Layout of move file:
	# Quantity of columns in move array
	# Quantity of rows in move array
	# The moves where every two characters is a move
	
	# If it contains a byte not between 48 and 57, inclusive,
	# or not '\n' or '\r', then return $v0=-1 (invalid!)
	blez $v0, error_accessing_file
	lbu $s3, 0($sp)		# Save character into $s3
	
	addi $t0, $0, '\r'
	beq $s3, $t0, read_first_line
	addi $t0, $0, '\n'
	beq $s3, $t0, read_second_line
	
	addi $t0, $0, 48
	addi $t1, $0, 57
	bgt $s3, $t1, error_accessing_file
	blt $s3, $t0, error_accessing_file
	
	# Convert char to int
	addi $s3, $s3, -48
	
	addi $t0, $0, 10
	mult $s4, $t0
	mflo $s4
	add $s4, $s4, $s3
	
	j read_first_line
	
	read_second_line:
	li $v0, 14
	move $a0, $s2	# Move file descriptor to $a0
			# to store character
	move $a1, $sp	# Store address of output buffer in $a1
	li $a2, 1	# Buffer length = 1
	syscall
	
	# If it contains a byte not between 48 and 57, inclusive,
	# or not '\n' or '\r', then return $v0=-1 (invalid!)
	blez $v0, error_accessing_file
	lbu $s3, 0($sp)		# Save character into $s3
	
	addi $t0, $0, '\r'
	beq $s3, $t0, read_second_line
	addi $t0, $0, '\n'
	beq $s3, $t0, read_third_line
	
	addi $t0, $0, 48
	addi $t1, $0, 57
	bgt $s3, $t1, error_accessing_file
	blt $s3, $t0, error_accessing_file
	
	# Convert char to int
	addi $s3, $s3, -48
	
	addi $t0, $0, 10
	mult $s5, $t0
	mflo $s5
	add $s5, $s5, $s3
	
	j read_second_line
	
	read_third_line:
	# Read first character
	li $v0, 14
	move $a0, $s2	# Move file descriptor to $a0
			# to store character
	move $a1, $sp	# Store address of output buffer in $a1
	li $a2, 1	# Buffer length = 1
	syscall
	
	bltz $v0, error_accessing_file
	beqz $v0, return_number_of_moves
	
	lbu $s3, 0($sp)		# 1st char
	
	# Read second character
	li $v0, 14
	move $a0, $s2	# Move file descriptor to $a0
			# to store character
	move $a1, $sp	# Store address of output buffer in $a1
	li $a2, 1	# Buffer length = 1
	syscall
	
	bltz $v0, error_accessing_file
	beqz $v0, return_number_of_moves
	
	lbu $s6, 0($sp)		# 2nd char
	
	addi $s7, $s7, 1	# Increment moves counter
	
	addi $t0, $0, 48
	addi $t1, $0, 57
	bgt $s3, $t1, store_invalid_move
	blt $s3, $t0, store_invalid_move
	bgt $s6, $t1, store_invalid_move
	blt $s6, $t0, store_invalid_move
	
	# Convert to integer
	addi $s3, $s3, -48
	addi $s6, $s6, -48
	
	addi $t0, $0, 10
	mult $s3, $t0
	mflo $t1
	add $t2, $t1, $s6
	sb $t2, 0($s0)		# Store it in byte[] moves
	addi $s0, $s0, 1	# Increment pointer by one
	addi $t4, $t4, 1	# Increment column counter by one
	
	# If $t4=$s4, increment $t5 by one
	# and store a "99" move, except for the last row
	# (i.e., only if $t5<$s5)
	increment_column_row:
	bne $t4, $s4, read_third_line
	addi $t5, $t5, 1	# $t5++
	bge $t5, $s5, return_number_of_moves
	addi $t0, $0, 99
	sb $t0, 0($s0)
	addi $s0, $s0, 1
	addi $t4, $0, 0		# Reset $t4=0
	addi $s7, $s7, 1	# Increment moves counter
	j read_third_line
	
	store_invalid_move:
	addi $t0, $0, -1
	sb $t0, 0($s0)
	addi $s0, $s0, 1
	addi $t4, $t4, 1	# Increment column counter by one
	j increment_column_row
	
	error_accessing_file:
	# Close file after done reading
	addi $sp, $sp, 4	# Deallocate the 4 bytes
	li $v0, 16
	move $a0, $s2		# Move file descriptor to $a0
	syscall
	
	addi $v0, $0, -1
	j done_load_moves
	
	return_number_of_moves:
	# Close file after done reading
	addi $sp, $sp, 4	# Deallocate the 4 bytes
	li $v0, 16
	move $a0, $s2		# Move file descriptor to $a0
	syscall
	
	move $v0, $s7
	
	done_load_moves:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	addi $sp, $sp, 32
	jr $ra
play_game:
	# Args: $a0=moves_filename, $a1=board_filename, $a2=state,
	# $a3=moves (array), 0($sp)=num_moves_to_execute
	
	lw $t0, 0($sp)
	
	addi $sp, $sp, -32
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $ra, 28($sp)
	
	# Save all arguments of play_game to $s registers
	move $s0, $a0	# $s0 = moves_filename
	move $s1, $a1	# $s1 = board_filename
	move $s2, $a2	# $s2 = state
	move $s3, $a3	# $s3 = moves (array)
	move $s4, $t0	# $s4 = num_moves_to_execute
	
	# Call load_game to initialize the GameState
	move $a0, $s2
	move $a1, $s1
	jal load_game
	blez $v0, error_play_game
	blez $v1, error_play_game
	
	# Call load_moves to store moves in moves array
	move $a0, $s3
	move $a1, $s0
	jal load_moves
	bltz $v0, error_play_game
	move $s5, $v0	# Store number of moves (in the file)
	
	# Play the game!
	loop_game:
	# Call check_row to see if a row is empty before each move
	# It returns $v0=1 if a row was found to be empty, else $v0=0
	# It returns $v1=0 if tie, $v1=1 if player 1 won, $v1=2 if player 2 won
	move $a0, $s2
	jal check_row
	bnez $v0, game_over	# $v0!=0 -> $v0=1 -> Game over
	blez $s4, moves_done
	beqz $s5, moves_done
	
	# Check if current move in the moves array ($s3) is invalid
	# i.e., if it's an integer outside of the range [0,48] U {99}
	lbu $t0, 0($s3)
	addi $t1, $0, 99
	beq $t0, $t1, execute_do_nothing_move
	bltz $t0, skip_move
	addi $t1, $0, 48
	bgt $t0, $t1, skip_move
	
	# Call get_pocket to get the number of stones in current move
	move $a0, $s2
	lbu $a1, 5($s2)
	lbu $a2, 0($s3)
	jal get_pocket
	bltz $v0, skip_move	# Move is an invalid row index -> skip it
	move $s6, $v0		# Save number of stones in $s6
	
	# Call verify_move
	move $a2, $v0
	move $a0, $s2
	lbu $a1, 0($s3)
	jal verify_move
	blez $v0, skip_move	# Move is invalid -> skip it
	
	# Call execute_move
	move $a0, $s2
	lbu $a1, 0($s3)
	jal execute_move
	addi $t1, $0, 1
	bne $v1, $t1, execute_move_successful
	
	# Use modulo trick to obtain destination_pocket
	lbu $t0, 2($s2)		# $t0=row size
	lbu $t1, 0($s3)		# $t1=current player's origin_pocket
	# destination_pocket=
	# rowsize-1-[(rowsize-1-origin_pocket+distance) mod (2*rowsize+1)]
	addi $t2, $t0, -1
	sub $t3, $t2, $t1
	add $t3, $t3, $s6
	sll $t1, $t0, 1
	addi $t1, $t1, 1
	div $t3, $t1
	mfhi $t2
	addi $t0, $t0, -1
	sub $a1, $t0, $t2
	move $a0, $s2
	
	# Call steal
	jal steal
	j execute_move_successful
	
	execute_do_nothing_move:
	# Call verify_move with distance=99 to change player_turn
	# and increment moves_executed by one
	move $a0, $s2
	li $a2, 99
	jal verify_move
	
	execute_move_successful:
	addi $s5, $s5, -1
	addi $s4, $s4, -1
	addi $s3, $s3, 1
	j loop_game
	
	skip_move:
	addi $s4, $s4, -1
	addi $s3, $s3, 1
	j loop_game
	
	moves_done:
	addi $v0, $0, 0
	lbu $v1, 4($s2)
	j done_play_game
	
	game_over:
	move $v0, $v1
	lbu $v1, 4($s2)
	j done_play_game
	
	error_play_game:
	addi $v0, $0, -1
	addi $v1, $0, -1
	
	done_play_game:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $ra, 28($sp)
	addi $sp, $sp, 32
	jr $ra
print_board:
	# Arg: $a0=state (valid and instantiated)
	
	# Print top player's mancala
	move $t5, $a0
	lbu $t0, 6($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	lbu $t0, 7($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	
	li $v0, 11
	addi $a0, $0, '\n'
	syscall
	
	# Print bottom player's mancala
	lbu $t1, 2($t5)
	sll $t1, $t1, 2
	addi $t1, $t1, 2
	add $t5, $t5, $t1
	
	lbu $t0, 6($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	lbu $t0, 7($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	
	li $v0, 11
	addi $a0, $0, '\n'
	syscall
	
	# Print top row
	sub $t5, $t5, $t1
	lbu $t1, 2($t5)
	sll $t6, $t1, 1
	
	loop_print_top_row:
	beqz $t6, print_bottom_row
	
	lbu $t0, 8($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	
	addi $t5, $t5, 1
	addi $t6, $t6, -1
	j loop_print_top_row
	
	# Print bottom row
	print_bottom_row:
	li $v0, 11
	addi $a0, $0, '\n'
	syscall
	
	sll $t6, $t1, 1
	
	loop_print_bottom_row:
	beqz $t6, done_print_board
	
	lbu $t0, 8($t5)
	li $v0, 11
	move $a0, $t0
	syscall
	
	addi $t5, $t5, 1
	addi $t6, $t6, -1
	j loop_print_bottom_row
	
	done_print_board:
	li $v0, 11
	addi $a0, $0, '\n'
	syscall
	
	jr $ra
write_board:
	# Arg: #a0=state
	
	move $t6, $a0 	# Save GameState in $t6
	
	# Open file for writing
	addi $sp, $sp, -11
	li $t0, 'o'
	sb $t0, 0($sp)
	li $t0, 'u'
	sb $t0, 1($sp)
	li $t0, 't'
	sb $t0, 2($sp)
	li $t0, 'p'
	sb $t0, 3($sp)
	li $t0, 'u'
	sb $t0, 4($sp)
	li $t0, 't'
	sb $t0, 5($sp)
	li $t0, '.'
	sb $t0, 6($sp)
	li $t0, 't'
	sb $t0, 7($sp)
	li $t0, 'x'
	sb $t0, 8($sp)
	li $t0, 't'
	sb $t0, 9($sp)
	li $t0, 0
	sb $t0, 10($sp)
	
	li $v0, 13
	move $a0, $sp
	li $a1, 1	# flag=1 for writing
	li $a2, 0	# Ignore mode
	syscall
	addi $sp, $sp, 11
	bltz $v0, error_write_board
	move $t5, $v0	# File descriptor in $t5
	
	# Store content to print on the stack
	lbu $t2, 2($t6)
	sll $t2, $t2, 2
	addi $t2, $t2, 8
	sub $sp, $sp, $t2	# Allocate space on the stack
	
	# Store top mancala
	lbu $t0, 6($t6)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	lbu $t0, 7($t6)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	li $t0, '\n'
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	
	# Store bottom mancala
	addi $t3, $t2, -6
	add $t4, $t6, $t3
	lbu $t0, 6($t4)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	lbu $t0, 7($t4)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	li $t0, '\n'
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	
	# Store top row
	lbu $t1, 2($t6)
	sll $t1, $t1, 1
	move $t3, $t6
	
	loop_store_top_row:
	beqz $t1, store_bottom_row
	
	lbu $t0, 8($t3)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	addi $t3, $t3, 1
	addi $t1, $t1, -1
	j loop_store_top_row
	
	# Store bottom row
	store_bottom_row:
	li $t0, '\n'
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	
	lbu $t1, 2($t6)
	sll $t1, $t1, 1
	
	loop_store_bottom_row:
	beqz $t1, write_to_file
	
	lbu $t0, 8($t3)
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	addi $t3, $t3, 1
	addi $t1, $t1, -1
	j loop_store_bottom_row
	
	# Write to file
	write_to_file:
	li $t0, '\n'
	sb $t0, 0($sp)
	addi $sp, $sp, 1
	sub $sp, $sp, $t2
	li $v0, 15
	move $a0, $t5		# Move file descriptor to $a0
	move $a1, $sp		# Address of buffer to $a1
	move $a2, $t2		# Buffer length=4*rowsize+8
	syscall
	add $sp, $sp, $t2	# Deallocate space on the stack
	bltz $v0, error_write_board
	
	# Close file
	li $v0, 16
	move $a0, $t5
	syscall
	addi $v0, $0, 1
	j done_write_board
	
	error_write_board:
	# Close file
	li $v0, 16
	move $a0, $t5
	syscall
	addi $v0, $0, -1
	
	done_write_board:
	jr $ra
	
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
