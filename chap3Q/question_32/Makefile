# TARGET = maxNumber

# $(TARGET).objdump: $(TARGET).elf
# 	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).objdump

# $(TARGET).elf: $(TARGET).S Makefile
# 	riscv64-unknown-elf-gcc -o $(TARGET).elf -march=rv32i -mabi=ilp32 -mcmodel=medany \
# 		-nostartfiles -T../../link/link.ld $(TARGET).S

# clean:
# 	rm -f $(TARGET).elf $(TARGET).objdump
TARGET = maxNumber

$(TARGET).objdump: $(TARGET).elf
	riscv64-unknown-elf-objdump -D $(TARGET).elf > $(TARGET).objdump

$(TARGET).elf: $(TARGET).S Makefile
	riscv64-unknown-elf-gcc -o $(TARGET).elf -march=rv32i -mabi=ilp32 -mcmodel=medany \
		-nostartfiles $(TARGET).S

clean:
	rm -f $(TARGET).elf $(TARGET).objdump
