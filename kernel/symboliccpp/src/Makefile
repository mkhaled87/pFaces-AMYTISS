LIMITED_CONFIG=yes
PROJECT_ROOT=../../..
include $(PROJECT_ROOT)/Makefile.inc

PROJECT_ROOT=..

#----
# TO DO: check the output of "uname -o" on HPUX and AIX
#----
OS= $(shell uname)

ifeq ($(OS),Gnu/Linux)
OS=Linux
endif
ifeq ($(OS),GNU/Linux)
OS=Linux
endif


LIB_DIR=$(PROJECT_ROOT)/lib
INC_DIR=$(PROJECT_ROOT)/include

LIB_SYMBOLICCPP=libsymboliccpp.a
LINK_WITH_SYMBOLICCPP=-L$(LIB_DIR) -llibsymboliccpp


#--------
# EXE_EXT is ".exe" on Windows, and "" on UNIX-like operating systems.
#--------
ifeq ($(OS),Cygwin)
EXE_EXT=.exe
else
EXE_EXT=
endif


#--------
# Update CXX_FLAGS based on BUILD_TYPE (debug or release)
#--------
ifeq ($(BUILD_TYPE),release)
override CXX_FLAGS+= -I$(PROJECT_ROOT)/include -fPIC -O -DNDEBUG
else
BUILD_TYPE=debug
override CXX_FLAGS+= -I$(PROJECT_ROOT)/include -fPIC -g
endif


LINK_FLAGS=	


#-----
# Determine:
#	- The commands used to build a library
#	- The C++ compiler
#-----
ifeq ($(OS),Linux)
#-----
# Linux
#-----
AR		= ar
AR_FLAGS	= -r
RANLIB		= /bin/true
RANLIB_FLAGS	= 
else ifeq ($(OS),Cygwin)
#-----
# Cygwin: same as Linux
#-----
AR		= ar
AR_FLAGS	= -r
RANLIB		= /bin/true
RANLIB_FLAGS	= 
else ifeq ($(OS),Darwin)
#-----
# MAC OS
#-----
AR		= ar
AR_FLAGS	= rc
RANLIB		= ranlib
RANLIB_FLAGS	= 
else ifeq ($(OS),SunOS)
#-----
# Solaris
#-----
AR		= ar
AR_FLAGS	= cr
RANLIB		= ranlib
RANLIB_FLAGS	= 
else ifeq ($(OS),HPUX)
#-----
# HPUX
#-----
AR		= ar
AR_FLAGS	= cr
RANLIB		= /bin/true
RANLIB_FLAGS	= 
else ifeq ($(OS),Aix)
#-----
# AIX
#-----
AR		= ar
AR_FLAGS	= -r
RANLIB		= ranlib
RANLIB_FLAGS	= 
endif


#--------
# Generic build rules
#--------
.SUFFIXES:		.cpp

.cpp.o:
	$(CXX) -c $(CXX_FLAGS) $<


LIB_HDR_FILES= \
		$(INC_DIR)/symbolic/constants.h \
		$(INC_DIR)/symbolic/equation.h \
		$(INC_DIR)/symbolic/functions.h \
		$(INC_DIR)/symbolic/integrate.h \
		$(INC_DIR)/symbolic/number.h \
		$(INC_DIR)/symbolic/product.h \
		$(INC_DIR)/symbolic/solve.h \
		$(INC_DIR)/symbolic/sum.h \
		$(INC_DIR)/symbolic/symbol.h \
		$(INC_DIR)/symbolic/symbolic.h \
		$(INC_DIR)/symbolic/symbolicc++.h \
		$(INC_DIR)/symbolic/symerror.h \
		$(INC_DIR)/symbolic/symmatrix.h \
		$(INC_DIR)/array.h \
		$(INC_DIR)/cloning.h \
		$(INC_DIR)/derive.h \
		$(INC_DIR)/identity.h \
		$(INC_DIR)/matnorm.h \
		$(INC_DIR)/matrix.h \
		$(INC_DIR)/multinomial.h \
		$(INC_DIR)/polynomial.h \
		$(INC_DIR)/quatern.h \
		$(INC_DIR)/rational.h \
		$(INC_DIR)/symbolicc++.h \
		$(INC_DIR)/vecnorm.h \
		$(INC_DIR)/vector.h \
		$(INC_DIR)/verylong.h

LIB_OBJ_FILES	= \
		array.o \
		cloning.o \
		constants.o \
		derive.o \
		equation.o \
		functions.o \
		identity.o \
		integrate.o \
		matnorm.o \
		matrix.o \
		multinomial.o \
		number.o \
		polynomial.o \
		product.o \
		quatern.o \
		rational.o \
		solve.o \
		sum.o \
		symbol.o \
		symbolic.o \
		symbolicc++.o \
		symerror.o \
		symmatrix.o \
		vecnorm.o \
		vector.o \
		verylong.o

.PHONY: all clean

all: $(LIB_SYMBOLICCPP)

$(LIB_SYMBOLICCPP):	$(LIB_OBJ_FILES)
	$(AR) $(AR_FLAGS) $(LIB_SYMBOLICCPP) $(LIB_OBJ_FILES)
	$(RANLIB) $(RANLIB_FLAGS) $(LIB_SYMBOLICCPP)
	cp $(LIB_SYMBOLICCPP) $(LIB_DIR)
	rm -f $(LIB_SYMBOLICCPP)

$(LIB_OBJ_FILES):	$(LIB_HDR_FILES)

clean:
	rm -f *.o
	rm -f ../lib/*.*
	touch ../lib/.ignore

