
# s0: base address of numbers
# t0: # of numbers

.section .data
numbers:    .byte 0x42, 0x37, 0xFD, 0x83, 0x11
max_value:  .byte 0                            

.global max_numbers
max_numbers:
    la      s0, numbers  # Load base address of number
    la a0, numbers       # Load address of numbers
    lb a1, 0(a0)         # Load first number into a1 (current max)
    li t0, 4            
    addi a0, a0, 1       # Move to the next number

loop:
    lb a2, 0(a0)         # Load next number
    addi a0, a0, 1       # Move to the next number

    bge a1, a2, skip     # If a1 >= a2, skip update
    mv a1, a2           # Update max value

skip:
    addi t0, t0, -1      # Decrement counter
    bnez t0, loop        # Repeat if more numbers left
    la a0, max_value     # Load address of max_value
    sb a1, 0(a0)         # Store max number

# .section .text.init
# .globl rvtest_entry_point

# rvtest_entry_point:
#    la s0, numbers       # s0 = address of numbers
#    lw s1, 0(s0)         # s1 = maximum number so format
#    li t0, 5             # number of numbers
#    li s2, 1             # current number to compare

# loop:
#     slli t1, s2, 2      # t1 = 4*s2 = byte offset of current number
#     add t1, s0, t1      # t1 = address of current number
#     lw t1, 0(t1)        # t1 = current number 
#     ble t1, s1, skip    # if not larger, skip
#     mv s1, t1           # s1 = new biggest number
# skip:
#     addi s2, s2, 1      # go on to next number 
#     blt s2, t0, loop    # repeat until done

# self_loop:
#     j self_loop

# .data
# numbers:
#     .word 0x42, 0x37, 0xFD, 0x83, 0x11
