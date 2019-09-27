# Define version and name

OUTPUT=bin

# Toolchain Path

LLVM_TOOL_PATH=/home/nasm/Tools/build_debug/Debug+Asserts/bin/
# Toolchain

IR           = $(LLVM_TOOL_PATH)clang
IC           = inception-cl
#CC          = $(LLVM_TOOL_PATH)clang
#CXX         = $(LLVM_TOOL_PATH)clang++
CC           = arm-none-eabi-gcc
CXX          = arm-none-eabi-g++
LLVM_LINK    = $(LLVM_TOOL_PATH)llvm-link
LLVM_AS      = $(LLVM_TOOL_PATH)llvm-as
#AS           = $(LLVM_TOOL_PATH)clang
AS           = arm-none-eabi-as
LD           = arm-none-eabi-gcc
OBJDUMP      = arm-none-eabi-objdump
SIZE         = arm-none-eabi-size

# Arguments

COMMON_ARGS  = -target arm-none-eabi -mcpu=cortex-m3 -O0 -mfloat-abi=soft
GCC_ARGS     = -march=armv7-m -mthumb -mcpu=cortex-m3 -Wa,-mimplicit-it=thumb

CC_FLAGS     = $(GCC_ARGS)
CXX_ARGS     = $(GCC_ARGS)
ASM_FLAGS    = -mcpu=cortex-m3 -mthumb -mfloat-abi=softfp
#ASM_FLAGS    = $(COMMON_ARGS) -nostdlib
LD_FLAGS     =
IR_FLAGS     = $(COMMON_ARGS) -emit-llvm -S -g -DKLEE

# Linker Option

LINKED       =

# Include sub config

-include config.mk

# Linker Option suite

LD_FLAGS     += -T mem.ld -T sections.ld

# Include

#CC_FLAGS     += -I/usr/include/newlib/
#AS_FLAGS      += -I/usr/include/newlib/
#CXX_FLAGS     += -I/usr/include/newlib/
IR_FLAGS     += -I/usr/include/newlib/

# Define sources

C_FILES      := $(shell find ./ -path ./Examples -prune -type f -o -name "*.c" -printf "%p\n")
C_FILES      += $(shell find ./Examples/$(PROJECT) -type f -name "*.c" -printf "%p\n")

CXX_FILES    := $(shell find ./ -path ./Examples -prune -type f -o -name "*.cpp" -printf "%p\n")
ASM_FILES    := ./Core/Device/NXP/LPC18xx/Source/Templates/GCC/startup_LPC18xx.s


#$(shell find ./ -path ./Examples -prune -type f -o -name "*.s" -printf "%p\n")

#HEADER       := $(shell find ./ -type f -o -name "*.h" -exec dirname {} \; | sort -u | sed ':a;N;$$!ba;s/\n/ -I/g' | xargs -0 printf "%s")
#HEADER        = '$(shell find ./ -type f -name "*.h" -exec dirname {} \; | sort -u | sed ':a;N;$!ba;s/\n/ -I/g' | xargs -0 printf "%s\n")'
HEADER        := -I./Boards \
                 -I./Core/CMSIS/Include \
                 -I./Core/Device/NXP/LPC18xx/Include \
                 -I./Drivers/include \
                 -I./Examples/CombinedDemo \
                 -I./Examples/CombinedDemo/easyweb \
                 -I./Examples/CombinedDemo/usbd \
                 -I./Examples/FlashLoader/EWARM/framework2 \
                 -I./Examples/I2C_EEPROM \
                 -I./Examples/SPI_DataFlash \
                 -I./Examples/USB_ROM_HIDmouse \
                 -I./Examples/USB_ROM_HIDmouse/usbd \
                 -I./Examples/Web \
                 -I./Examples/Web/easyweb

C_OBJS        = $(patsubst %.c,%.o,$(C_FILES))
CXX_OBJS      = $(patsubst %.cpp,%.o,$(CXX_FILES))
ASM_OBJS      = $(patsubst %.s,%.o,$(ASM_FILES))

LL_OBJS       = $(patsubst %.c,%.ll,$(C_FILES))
LL_OBJS      += $(patsubst %.cpp,%.ll,$(CXX_FILES))

OBJS          = $(C_OBJS) $(CXX_OBJS) $(ASM_OBJS)

# Verbose

V = 0
ifeq ($V, 0)
        Q = @
        P =
#2>&1 >/dev/null
endif

#################### Rules ###########################
######################################################

all: BIN IR ADAPT_BC_ASM

BIN: $(C_OBJS) $(CXX_OBJS) $(ASM_OBJS) ELF

IR: $(LL_OBJS) BC

# Compilation rules

%.ll : %.cpp
	@echo "[LL]      $(notdir $<)"
	$Q$(IR) $(IR_FLAGS) -I./Boards -I$(HEADER) -o $@ -c $<

%.ll : %.c
	@echo "[LL]      $(notdir $<)"
	$Q$(IR) $(IR_FLAGS) -I./Boards -I$(HEADER) -o $@ -c $<

%.o : %.c
	@echo "[CC]      $(notdir $<)"
	$Q$(CC) $(CC_FLAGS) -I./Boards -I$(HEADER) $(DEBUG) -o $@ -c $<
#        $Q$(CC) $(CC_FLAGS) -I$(HEADER) $(DEBUG) -o $@ -c $<

%.o : %.s
	@echo "[AS]      $(notdir $<)"
	$Q$(AS) $(ASM_FLAGS) -o $@ -c $<

%.o : %.cpp
	@echo "[CXX]      $(notdir $<)"
	$Q$(CXX) $(CXX_FLAGS) -c -o $@ $< -MMD -MF dep/$(*F).d

# Link rules

ELF: $(OBJS)
	@echo "[LD]      $(OUTPUT).elf"
	$Q$(LD) $(LD_FLAGS) $^ -o $(OUTPUT).elf$P
	@echo "[OBJDUMP] $(OUTPUT).lst"
	$Q$(OBJDUMP) -St $(OUTPUT).elf >$(OUTPUT).lst
	@echo "[SIZE]    $(OUTPUT).elf"
	$Q$(SIZE) $(OUTPUT).elf

BC: $(LL_OBJS)
	@echo "[LLVM-LINK]      $(OUTPUT).ll"
	$Q$(LLVM_LINK) -S $^ -o $(OUTPUT).ll
	sed -i 's/ linkonce_odr / /g' $(OUTPUT).ll
	sed -i 's/ internal / /g' $(OUTPUT).ll
	sed -ri 's/external global ([\._%0-9a-zA-Z]*)\*/ global \1\* undef/g' $(OUTPUT).ll
	sed -ri 's/external global ([0-9a-zA-Z]*)/ global \1 0/g' $(OUTPUT).ll
	sed -ri 's/extern_weak global ([0-9a-zA-Z]*)/ global \1 0/g' $(OUTPUT).ll
	echo "[LLVM-AS]       $(OUTPUT).ll"
	$Q$(LLVM_AS) $(OUTPUT).ll -o $(OUTPUT).bc

# Clean rules

clean:
	$Qrm -rf *.o $P
	$Qrm -rf *.ll $P
	$Qrm -rf klee-* $P
	$Qrm -rf *.ll $P
	$Qfind -name "*.o" -exec rm {} \; $P
	$Qfind -name "*.ll" -exec rm {} \; $P
	$Qfind -name "*.bc" -exec rm {} \; $P
	$Qfind -name "*.dis" -exec rm {} \; $P
	$Qfind -name "*.elf" -exec rm {} \; $P
	$Qfind -name "*.lst" -exec rm {} \; $P

ADAPT_BC_ASM:
	@echo "[INCEPTION-COMPILER]      $(OUTPUT).bc"
	$Q$(IC) $(IC_FLAGS) $(OUTPUT).elf $(OUTPUT).bc $P
	@echo "[LLVM-AS]       $(OUTPUT).ll"
	$Q$(LLVM_AS) $(OUTPUT).elf.ll -o $(OUTPUT).bc $P
	#opt -O3 -adce $(OUTPUT)_raw.bc -o $(OUTPUT).bc

