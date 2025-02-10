
# s0: base address of numbers
# t0: # of numbers

.global max_numbers

max_numbers:
    la      s0, numbers          # load base address of numbers
    addi    t0, t0, 5            # t0 = 5
    
