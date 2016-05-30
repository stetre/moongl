
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
# Directory where to install DLLs:
D_DIR = $(PREFIX)/bin

ifeq ("$(V)","")
$(error Missing Lua version)
endif

ifeq ("$(PREFIX)","")
$(error Missing base install directory)
endif

ifeq ($(D),1)
DEBUG=1
endif

ifeq ("$(platform)","")
platform=linux
endif
MINGW=
LINUX=


ifeq ("$(platform)","linux")
LINUX=1
INCDIR = -I/usr/include
LIBDIR = -L/usr/lib
LIBS = -lGLEW -lGLU -lGL -lm
endif
ifeq ("$(platform)","mingw")
MINGW=1
INCDIR = -I/usr/local/include
LIBDIR = -L/usr/bin -L/usr/local/bin -L/usr/local/lib
LIBS = -lglew32 -lglu32 -lopengl32 -lm
endif


# Translates 5.3 into 503:
LUAVER=$(shell lua -e "print((string.gsub("$(V)",'%.','0')))")
LUADLL=lua$(shell lua -e "print((string.gsub("$(V)",'%.','')))")

# Check the Lua version of the installed lua interpreter:
INSTLUAVER=$(shell lua -e "print(_VERSION:sub(5))")
ifneq ("$(V)","$(INSTLUAVER)")
#$(info $(V))
$(warning Warning: using Lua $(V) but Lua interpreter version is $(INSTLUAVER))
endif

Tgt	:= moongl
Src := $(wildcard *.c)
Objs := $(Src:.c=.o)

 
COPT	+= -O2
COPT	+= -Wall -Wextra -Wpedantic
COPT    += -std=gnu99
COPT    += -DLUAVER=$(LUAVER)
ifdef LINUX
COPT    += -fpic
COPT	+= -DLINUX
endif
ifdef MINGW
COPT	+= -DMINGW
endif
ifdef DEBUG
COPT	+= -DDEBUG
COPT 	+= -Wshadow -Wsign-compare -Wundef -Wwrite-strings
COPT	+= -Wdisabled-optimization -Wdeclaration-after-statement
COPT    += -Wmissing-prototypes -Wstrict-prototypes -Wnested-externs
COPT    += -Wc++-compat -Wold-style-definition
endif

override CFLAGS = $(COPT) $(INCDIR)

default: build

clean:
	@-rm -f *.so *.dll *.o *.err *.map *.S *~ *.log
	@-rm -f $(Tgt).symbols

install:
	@-mkdir -pv $(H_DIR)
	@-mkdir -pv $(C_DIR)
	@-mkdir -pv $(S_DIR)
	@-mkdir -pv $(L_DIR)
	@-mkdir -pv $(D_DIR)
	@-cp -fpv $(Tgt).h $(H_DIR)
	@-cp -fpvr ../$(Tgt) $(L_DIR)
ifdef LINUX
	@-cp -fpv $(Tgt).so $(C_DIR)
	@-ln -fsv $(C_DIR)/$(Tgt).so $(S_DIR)/lib$(Tgt).so
endif
ifdef MINGW
	@-cp -fpv $(Tgt).dll $(D_DIR)
endif


uninstall:
	@-rm -f $(H_DIR)/$(Tgt).h
	@-rm -f $(C_DIR)/$(Tgt).so
	@-rm -f $(S_DIR)/lib$(Tgt).so
	@-rm -fr $(L_DIR)/$(Tgt)
	@-rm -f $(D_DIR)/$(Tgt).dll

build:	clean $(Tgt) 

symbols: build
	@objdump -T $(Tgt).so > $(Tgt).symbols

$(Tgt):		$(Objs)
ifdef LINUX
	@-$(CC) -shared -o $(Tgt).so $(Objs) $(LIBDIR) $(LIBS)
endif
ifdef MINGW
	@-$(CC) -shared -o $(Tgt).dll $(Objs) $(LIBDIR) $(LIBS) -l$(LUADLL)
endif
	@-rm -f $(Objs)
	@echo


