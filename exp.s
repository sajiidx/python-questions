.text

main:
    li $v0, 4                       # Print the input prompt
    la $a0, prompt
    syscall

    li $v0, 8                       # Read the input expression
    la $a0, infix
    li $a1, 128                     # Maximum input length
    syscall

    la $a1, infix                   # Load the address of the input expression
    la $a2, postfix
    jal infix_to_postfix            # Convert infix to postfix

    li $v0, 4                       # Print the postfix expression
    la $a0, postfix
    syscall

    li $v0, 4                       # Print " = " on console
    la $a0, output
    syscall

    la $a1, postfix
    jal evaluate_postfix            # Convert infix to postfix

    move $a0, $v0                   # Load the result to be printed
    li $v0, 1                       # Print integer syscall code
    syscall

    li $v0, 10                      # This is to terminate the program
    syscall

isdigit:
    blt $v0, '0', not_digit         # if char < '0' Branch not_digit
    bgt $v0, '9', not_digit         # else if char > '9' Branch not_digit

    li $v0, 1                       # return 1
    j ireturn

    not_digit:
        li $v0, 0                   # return 0
    ireturn:
        jr $ra

precedence:
    beq $v0, '+', return_one
    beq $v0, '-', return_one
    
    li $v0, 0
    j preturn

    return_one:
        li $v0, 1
    preturn:
        jr $ra

infix_to_postfix:
    # Save the return address
    sw $ra, 0($sp)
    addi $sp, $sp, -4

    la $a3, operators
    li $t0, 0                       # Initialize stack top index to 0

    iwhile:
        lb $t1, 0($a1)              # Load the current character
        beq $t1, 10, idone          # End of expression newline character
        beqz $t1, idone             # End of expression null character

        beq $t1, ' ', inext        # ignore if current character is space

        move $v0, $t1
        jal isdigit                 # Check if the character is a digit
        beqz $v0, is_not_digit

        sb $t1, 0($a2)
        addi $a2, $a2, 1            # If it's a digit, append it to the result
        j inext

        is_not_digit:
            beq $t1, '(', is_open_parenthesis
            beq $t1, ')', is_close_parenthesis

        jwhile:
            beqz $t0, push_operator # if stack is empty then branch push_operator

            lb $t2, 0($a3)          # Load the value from the stack into $t2

            move $v0, $t2
            jal precedence
            move $t3, $v0

            move $v0, $t1
            jal precedence
            move $t4, $v0

            blt $t3, $t4, push_operator #if precedence(operators.top()) < precedence(c) then branch push_operator

            addi $a3, $a3, -1       # Adjust the stack pointer by 4 bytes (size of a word)
            lb $t2, 0($a3)          # Load the value from the stack into $t1
            
            addi $t0, $t0, -1       # Decrement the stack top index
            
            sb $t2, 0($a2)          # postfix += stack.pop()
            addi $a2, $a2, 1
            
            j jwhile

        push_operator:
            sb $t1, 0($a3)          # Store the operator on the stack
            addi $a3, $a3, 1       # Adjust the stack pointer by 4 bytes (size of a word)
            addi $t0, $t0, 1        # Increment the stack top index
            j inext

        is_open_parenthesis:
            sb $t1, 0($a3)          # Store the open parenthesis on the stack
            addi $a3, $a3, 1        # Adjust the stack pointer by 4 bytes (size of a word)
            addi $t0, $t0, 1        # Increment the stack top index
            j inext

        is_close_parenthesis:
            # Pop operators from the stack and append them to the result until an open parenthesis is encountered
            beqz $t0, inext         # if stack is empty then branch inext

            addi $a3, $a3, -1       # Adjust the stack pointer by 4 bytes (size of a word)
            lb $t2, 0($a3)          # Load the value from the stack into $t2
            
            addi $t0, $t0, -1       # Decrement the stack top index

            beq $t2, '(', inext     # if stack.top() == '(' then brach inext
            
            sb $t2, 0($a2)          # postfix += stack.pop()
            addi $a2, $a2, 1
            
            j is_close_parenthesis

    inext:
        addi $a1, $a1, 1
        j iwhile

    idone:

        kwhile:
            beqz $t0, done

            lb $t2, 0($a3)          # Load the value from the stack into $t1
            addi $a3, $a3, -1        # Adjust the stack pointer by 4 bytes (size of a word)
            addi $t0, $t0, -1       # Decrement the stack top index
            
            sb $t2, 0($a2)          # postfix += stack.pop()
            addi $a2, $a2, 1

            j kwhile

    done:
        sb $zero, 0($a2)          # postfix += '\0'
        addi $a2, $a2, 1

        # Restore the return address
        lw $ra, 4($sp)
        addi $sp, $sp, 4
        jr $ra

evaluate_postfix:
    # Save the return address
    sw $ra, 0($sp)
    addi $sp, $sp, -4

    li $v0, 0
    la $a2, operands

    ewhile:
        lb $t1, 0($a1)              # Load the current character
        beq $t1, 10, edone          # End of expression newline character
        beqz $t1, edone             # End of expression null character

        move $v0, $t1
        jal isdigit                 # Check if the character is a digit
        beqz $v0, e_is_not_digit

        addi $t1, $t1, -48          # operand = character - 48
        
        sb $t1, 0($a2)
        addi $a2, $a2, 1            # push the operand on stack
        j enext

        e_is_not_digit:
            beq $t1, '+', perform_add
            beq $t1, '-', perform_sub
            j enext

        perform_add:
            addi $a2, $a2, -1
            lb $t2, 0($a2)

            addi $a2, $a2, -1
            lb $t3, 0($a2)

            add $t2, $t2, $t3

            sb $t2, 0($a2)
            addi $a2, $a2, 1            # push the result on stack
        
            j enext

        perform_sub:
            addi $a2, $a2, -1
            lb $t2, 0($a2)

            addi $a2, $a2, -1
            lb $t3, 0($a2)

            not $t2, $t2
            addi $t2, $t2, 1
            add $t2, $t2, $t3

            sb $t2, 0($a2)
            addi $a2, $a2, 1            # push the result on stack

            j enext

    enext:
        addi $a1, $a1, 1
        j ewhile

    edone:
        addi $a2, $a2, -1
        lb $v0, 0($a2)


    # Restore the return address
    lw $ra, 4($sp)
    addi $sp, $sp, 4
    jr $ra

.data
prompt:     .asciiz "Expression to be evaluated: "
output:     .asciiz " = "
infix:      .space 128              # Buffer for input expression
postfix:    .space 128              # Buffer for postfix expression
operators:  .space 128              # Stack for operators
operands:   .space 128              # Stack for operands
