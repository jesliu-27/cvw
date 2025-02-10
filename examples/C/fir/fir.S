# s0: base address of x
# s1: base address of c
# s2: base address of y
# s3: n
# s4: m

# t0 = j
# t1 = i
.global fir
fir:
    sub  t0, a3, a4     # t0 = n - m
    addi t0, t0, 1      # t0 = n - m + 1
    slli t0, t0, 2     
    add  t0, a2, t0     # t0 = &y[n-m+1]


forj:
    bge a2, t0, donej   # Stop when y[j] >= y[n-m+1]
    slli t1, a4, 2      
    add  t1, a1, t1     # t1 = &c[m]
    addi t2, a4, -1     # t2 = m - 1
    slli t2, t2, 2      
    add  t2, a0, t2     # t2 = &x[m-1]
    li t3, 0            # sum = 0
    mv t4, a1           # t4 = &c[0]
    mv t5, t2           # t5 = &x[j+(m-1)]
    

fori:
	
    bge t4, t1, donei   # Stop when c[i] >= c[m]

    lw t6, 0(t4)        # Load c[i]
    lw a5, 0(t5)        # Load x[j-i+(m-1)]
    mul t6, t6, a5      # c[i] * x[j-i+(m-1)]
    srai t6, t6, 31     # Q31 format correction
    addw t3, t3, t6     # sum += product

    addi t4, t4, 4      # Move c[i] pointer (i++)
    addi t5, t5, -4     # Move x[j-i+(m-1)] pointer (decrement)
    j fori              # Repeat i loop

donei:
    sw t3, 0(a2)        # y[j] = sum

    addi a2, a2, 4      # Move y[j] pointer (increment)
    addi t2, t2, 4      # Move x[j+m-1] pointer (increment)
    j forj              # Repeat j loop

donej:
    ret

# .global fir
# fir:
#     sub  t0, a3, a4     # t0 = n - m
#     addi t0, t0, 1      # t0 = n - m + 1
#     slli t0, t0, 2      # Convert from words to bytes
#     add  t0, a2, t0     # t0 = &y[n-m+1]

#     slli t1, a4, 2      # Convert m from words to bytes
#     add  t1, a1, t1     # t1 = &c[m] (end of c array)

#     addi t2, a4, -1     # t2 = m - 1
#     slli t2, t2, 2      # Convert to bytes
#     add  t2, a0, t2     # t2 = &x[m-1] (starting point)

# forj:
#     bge a2, t0, donej   # Stop when y[j] >= y[n-m+1]

#     li t3, 0            # sum = 0
#     mv t4, a1           # t4 = &c[0]
#     mv t5, t2           # t5 = &x[j+(m-1)]

# fori:
#     bge t4, t1, donei   # Stop when c[i] >= c[m]

#     lw t6, 0(t4)        # Load c[i]
#     lw a5, 0(t5)        # Load x[j-i+(m-1)]
#     mul t6, t6, a5      # c[i] * x[j-i+(m-1)]
#     srai t6, t6, 31     # Q31 format correction
#     addw t3, t3, t6     # sum += product

#     addi t4, t4, 4      # Move c[i] pointer (i++)
#     addi t5, t5, -4     # Move x[j-i+(m-1)] pointer (decrement)
#     j fori              # Repeat i loop

# donei:
#     sw t3, 0(a2)        # y[j] = sum

#     addi a2, a2, 4      # Move y[j] pointer (increment)
#     addi t2, t2, 4      # Move x[j+m-1] pointer (increment)
#     j forj              # Repeat j loop

# donej:
#     ret



