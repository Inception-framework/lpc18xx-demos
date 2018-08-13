LLVM_VERSION=3.6

NAME=TEST_CASE

CFLAGS	?= -emit-llvm -g -S
WARNING_CFLAGS ?= -Wno-deprecated-register -Wno-error=implicit-exception-spec-mismatch -Wno-error=#warnings -Wno-error=gnu-variable-sized-type-not-at-end -Wno-error=implicit-function-declaration -Wno-unused-parameter -Wno-missing-field-initializers -Wno-error=typedef-redefinition -Wno-error=attributes -Wno-error=enum-conversion -Wno-error=shift-count-overflow -Wno-error=incompatible-pointer-types-discards-qualifiers -Wno-error=switch -Wno-error=return-type -Wunknown-attributes
LDFLAGS ?=

# -D__thumb__ -D__arm__
LOCAL_CFLAGS = $(WARNING_CFLAGS) -D__GNUC__ -I../../Boards/ -I../../Core/Device/NXP/LPC18xx/Include -I../../Core/CMSIS/Include -I../../Drivers/include -I../include -I /usr/arm-linux-gnueabihf/include/ -I/usr/include/newlib/
LOCAL_LDFLAGS =

# ifdef DEBUG
LOCAL_CFLAGS += -g3
# endif

CLANG_PATH=
LINKER=llvm-link
AS=llvm-as

CLANG=$(CLANG_PATH)clang -mthumb --target=thumbv7m-eabi -mcpu=cortex-m3 $(LOCAL_CFLAGS) $(CFLAGS) -I/home/inception/analyzer/include/

OUT = lib/mbedtls.a
CC = arm-none-eabi-gcc
ODIR = obj
LLDIR = ll
SDIR = .
INC = -I../include -I./Boards/ -I./Drivers/include -I./Device/NXP/LPC18xx/Include -I./Core/CMSIS/Include

SRCFILES := $(shell find ../../ ./ -type f -name "*.c"  -not -path "../../Examples/*" -printf "%p\n")
SRCFILES_U := $(shell find ../../ ./ -type f -name "*.c"  -not -path "../../Examples/*" -printf "%f\n")
HEADER := $(shell find ../../ -type f -name "*.h" -exec dirname {} \; | sort -u | sed ':a;N;$$!ba;s/\n/ -I/g' | xargs -0 printf "%s")
LLFILES := $(patsubst %.c,%.ll,$(SRCFILES_U))
LLS := $(patsubst %,$(LLDIR)/%,$(LLFILES))

# echo 'Building $(SRCFILES)'

IR:
	@echo '---------------------------------'
	@echo ''
	@echo ''
	@echo ''
	@echo ''
	@echo 'Clang is building files : $(SRCFILES) into $(LLDIR)'
	@echo ''
	@echo ''
	@echo ''
	#@echo '$(CLANG) $(HEADER) $(SRCFILES)'
	$(CLANG) $(HEADER) $(SRCFILES)
	@echo 'LLVM-LINK is linking files : $(LLFILES) into $(NAME)-llvm-$(LLVM_VERSION).ll'
	$(LINKER) -S $(LLFILES)  -o $(NAME)-llvm-$(LLVM_VERSION).ll
	$(AS) $(NAME)-llvm-$(LLVM_VERSION).ll -o $(NAME)-llvm-$(LLVM_VERSION).bc

all: IR

clean:
	rm -rf *.ll
	#rm -rf *.bc
	rm -rf $(ODIR)/*.o
	rm -rf klee-*
