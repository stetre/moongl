
# To override the defaults, do (for example):
# $ make V=5.4
# $ make install V=5.4 PREFIX=/home/joe/local

# Lua version:
V=5.3
# Base install directory:
PREFIX = /usr/local
# Directory where to install Lua modules:
L_DIR = $(PREFIX)/share/lua/$(V)
# Directory where to install C modules:
C_DIR = $(PREFIX)/lib/lua/$(V)
# Directory where to install C headers:
H_DIR = $(PREFIX)/include
# Directory where to install C libraries:
S_DIR = $(PREFIX)/lib

ifeq ("$(V)","")
$(error Missing Lua version)
endif

ifeq ("$(PREFIX)","")
$(error Missing base install directory)
endif

# Translates 5.3 into 503:
LUAVER=$(shell lua -e "print((string.gsub("$(V)",'%.','0')))")

# Check the Lua version of the installed lua interpreter:
INSTLUAVER=$(shell lua -e "print(_VERSION:sub(5))")
ifneq ("$(V)","$(INSTLUAVER)")
#$(info $(V))
$(warning Warning: using Lua $(V) but Lua interpreter version is $(INSTLUAVER))
endif

Tgt	:= moongl
Src := $(wildcard *.c)
Objs := $(Src:.c=.o)

INCDIR = -I/usr/include
LIBDIR = -L/usr/lib

LIBS := $(LIBDIR)
LIBS += -lGLEW
LIBS += -lGLU
LIBS += -lGL
LIBS += -lm
#LIBS += -llua
 
COPT	+= -O2
#COPT	+= -O0 -g
COPT	+= -Wall -Wextra -Wpedantic
COPT    += -fpic
COPT    += -std=gnu99
COPT    += -DLUAVER=$(LUAVER)
ifeq ($(D),1)
COPT	+= -DDEBUG
COPT 	+= -Wshadow -Wsign-compare -Wundef -Wwrite-strings
COPT	+= -Wdisabled-optimization -Wdeclaration-after-statement
COPT    += -Wmissing-prototypes -Wstrict-prototypes -Wnested-externs
COPT    += -Wc++-compat -Wold-style-definition
endif
COPT	+= $(INCDIR)

override CFLAGS = $(COPT) $(INCDIR)

default: build


clean:
	@-rm -f $(Tgt).so
	@-rm -f $(Tgt).symbols
	@-rm -f *~
	@-rm -f *.log
	@-rm -f *.o *.err *.map *.S

check:
	@-echo $(Tgt)".so will be installed in "$(C_DIR)
	@-echo $(Tgt)"/*.lua will be installed in "$(L_DIR)"/"$(Tgt)
	@-echo $(Tgt)".h will be installed in "$(H_DIR)
	@-echo lib$(Tgt)".so will be installed in "$(S_DIR)
	@-echo

install:
	@-mkdir -pv $(H_DIR)
	@-mkdir -pv $(C_DIR)
	@-mkdir -pv $(S_DIR)
	@-mkdir -pv $(L_DIR)
	@-cp -fpv $(Tgt).h $(H_DIR)
	@-cp -fpv $(Tgt).so $(C_DIR)
	@-ln -fsv $(C_DIR)/$(Tgt).so $(S_DIR)/lib$(Tgt).so
	@-cp -fpvr ../$(Tgt) $(L_DIR)

build:	clean $(Tgt) 

symbols: build
	@objdump -T $(Tgt).so > $(Tgt).symbols

$(Tgt):		$(Objs)
	@-$(CC) -shared -Wl,-soname,$(Tgt).so,$(LIBS) -o $(Tgt).so $(Objs) $(LIBS)
#	@-$(CC) -shared -Wl,-soname,$(Tgt).so -o $(Tgt).so $(LIBS) $(Objs)
	@-rm -f $(Objs)
	@echo

