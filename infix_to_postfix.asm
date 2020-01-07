.data
infix: .space 256
postfix: .space 256
stack: .space 256
prompt:	.asciiz "Enter String contain infix expression\n(note) Input expression has number must be integer and positive number:"
newLine: .asciiz "\n"
prompt_postfix: .asciiz "Postfix is: "
prompt_result: .asciiz "Result is: "
prompt_infix: .asciiz "Infix is: "

#####################################Convert from infix to postfix 3######################


.text
	li $v0, 54
	la $a0, prompt	
	la $a1, infix
	la $a2, 256
	syscall 
 
	la $a0, prompt_infix
	li $v0, 4
	syscall
	
	la $a0, infix
	li $v0, 4
	syscall

li $s3, -1      #index inflix
li $s4, -1      #index stack
li $s5, -1	#index postfix

loop:
	la $s0, infix
	la $s1, stack
	la $s2, postfix
	
	li $t6, '+'
	li $t7, '-'
	li $t8, '*'
	li $t9, '/'
	
	addi $s3, $s3, 1
	add $s0, $s0, $s3
	lb $t0, 0($s0)
	
	beq $t0, $t6, operator
	beq $t0, $t7, operator
	beq $t0, $t8, operator
	beq $t0, $t9, operator
	
	beq $t0, 10, n_operator # '\n'

	beq $t0, 32, n_operator # ' '

	beq $t0, $zero, endLoop
	
	
	addi $s5, $s5, 1
	add $s2, $s2, $s5
	sb $t0, 0($s2)
	
	lb $a0, 1($s0)
	
	jal checkNumber
	
	beq $v0, 1, n_operator
	
 	add_space:         #use to tell the difference between digit and integer
	add $t0, $zero, 32
	sb $t0, 1($s2)
	addi $s5, $s5, 1
	
	j loop
  
operator:
	beq $s4, -1, pushStack	

	add $s1, $s1, $s4
	lb $t1, 0($s1)
	
	beq $t0, $t6, pri_1_scanned      #priority of scanned charactaer if is '+' and '-'
	beq $t0, $t7, pri_1_scanned
	
	li $t2, 2	#priority of scanned charactaer if is '*' and '/'
	
	beq $t1, $t6, pri_1_stack	#priority of the first element in stack if is '+' and '-'
	beq $t1, $t7, pri_1_stack
	
	li $t3, 2	#priority of the first element in stack if is '*' and '/'
	
	j compare_priority


pri_1_scanned:
	li $t2, 1        

pri_1_stack:
	li $t3, 1

compare_priority:
	beq $t2, $t3, equal          #if priority of scanned char  >=  priority of the first element in stack. pop 
	slt $s0, $t2, $t3	#else push to stack
	beqz $s0, scannedLarger

	sb $zero, 0($s1)
	addi $s4, $s4, -1
	addi $s1, $s1, -1
	la $s2, postfix
	add $s5, $s5, 1
	add $s2, $s2, $s5
	sb $t1, 0($s2)
	
	j operator
	
	
equal:
	sb $zero, 0($s1)
	addi $s4, $s4, -1
	addi $s1, $s1, -1
	la $s2, postfix
	add $s5, $s5, 1
	add $s2, $s2, $s5
	sb $t1, 0($s2)
	
	j operator	


scannedLarger:
	j pushStack

pushStack:
	la $s1, stack
	addi $s4, $s4, 1
	add $s1, $s1, $s4
	sb $t0, 0($s1)
	
	j loop

checkNumber:
	blt $a0, '0', checkNumberFalse   
	bgt $a0, '9', checkNumberFalse    
	
	li $v0, 1 
	jr $ra
	
	checkNumberFalse:
		li $v0, 0
		jr $ra
		
n_operator:
	j loop
	
endLoop:
	add $s0, $zero, 32
	addi $s5, $s5, 1
	add $s2, $s2, $s5
	la $s1, stack
	add $s1, $s1, $s4
	
popAllStack:
	lb $t2, 0($s1)
	beq $t2, $zero, endScan
	sb $zero, 0($s1)
	addi $s4, $s4, -1
	add $s1, $s1, -1
	
	sb $t2, 0($s2)
	add $s2, $s2, 1
	
	j popAllStack

endScan:
	la $a0, prompt_postfix
	li $v0, 4
	syscall

	la $a0, postfix
	li $v0, 4
	syscall

	la $a0, newLine
	li $v0, 4
	syscall
	

##############################End convert from infix to postfix ######################

##############################Calculate postfix expression ###########################

li $t4, -1       #postfix counter
la $s6, stack	


loop_pf:
	la $s7, postfix
	addi $t4, $t4, 1
	add $s7, $s7, $t4
	lb $t0, 0($s7)

	beq $t0, $zero, end_pf
	beq $t0, 32, continue

	add $a0, $zero, $t0
	
	jal checkNumber
	
	beqz $v0, is_operator
	
	jal push_number_to_stack
	
	j loop_pf
	
is_operator:

	jal pop
	add $a0, $zero, $v0
	
	jal pop
	add $a1, $zero, $v0
	
	add $a2, $zero, $t0
	
	jal calculate

	
	j loop_pf
calculate:
	sw $ra, 0($sp)
	
	beq $t0, '*', multi
	beq $t0, '/', divi
	beq $t0, '+', plus
	beq $t0, '-', minus

multi:
	mul $a0, $a0, $a1
	j push
	lw $ra, 0($sp)
	jr $ra
	
divi:
	div $a0, $a1
	mflo $a0
	j push 
	lw $ra, 0($sp)
	jr $ra
	
plus:
	add $a0, $a0, $a1	
	j push
	lw $ra, 0($sp)
	jr $ra
minus:
	sub $a0, $a0, $a1
	j push
	lw $ra, 0($sp)
	jr $ra


continue:
	j loop_pf
	
push_number_to_stack:
	sw $ra, 0($sp)
	li $t1, 0
	loop_integer :

	
	beq $t0, '0', case0
	beq $t0, '1', case1
	beq $t0, '2', case2
	beq $t0, '3', case3
	beq $t0, '4', case4
	beq $t0, '5', case5
	beq $t0, '6', case6
	beq $t0, '7', case7
	beq $t0, '8', case8
	beq $t0, '9', case9	
	
	case0:
		j handle_integer
		
	case1:
		addi $t1, $t1, 1
		j handle_integer
		
	case2:
		addi $t1, $t1, 2
		j handle_integer
	
	case3:
		addi $t1, $t1, 3
		j handle_integer
	
	case4:
		addi $t1, $t1, 4
		j handle_integer
	
	case5:
		addi $t1, $t1, 5
		j handle_integer
	
	case6:
		addi $t1, $t1, 6
		j handle_integer
	
	case7:
		addi $t1, $t1, 7
		j handle_integer
	
	case8:
		addi $t1, $t1, 8
		j handle_integer
	
	case9:
		addi $t1, $t1, 9
		j handle_integer
	
	
	handle_integer:
		la $s7, postfix
		add $s7, $s7, $t4
		lb $t0, 1($s7)
		
		beq $t0, $zero, end_push_number
		beq $t0, ' ', end_push_number
		
		mul $t1, $t1, 10
		j loop_integer
	
			
end_push_number:
	add $a0, $zero, $t1
	jal push
	lw $ra, 0($sp)
	jr $ra


push:
	sw $a0, 0($s6)
	add $s6, $s6, 4
	jr $ra	
		
pop:
	lw $v0, -4($s6)
	sw $zero, -4($s6)
	addi $s6, $s6, -4
	jr $ra
		
		
end_pf:

# print postfix
la $a0, prompt_result
li $v0, 4
syscall


jal pop
add $a0, $zero, $v0 
li $v0, 1
syscall


la $a0, newLine
li $v0, 4
syscall

