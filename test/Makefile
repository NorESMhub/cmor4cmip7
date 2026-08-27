# Targets 
TARGET=test_json

# Objects
OBJ=m_jsons.o test_json6.o

# Paths 
JSONF=/diagnostics/CMOR/json-fortran/jsonfortran-gnu-9.2.1

# Fortran compiler
FC=gfortran

# Linker
LD=$(FC)

# Directory list to search for library files
# may need first "module load json-c/0.17-GCCcore-13.2.0"
LIBS=-L$(JSONF)/lib -Wl,-rpath=$(JSONF)/lib -ljson-c -ljsonfortran

# Compiler flags
#FFLAGS=-I$(SRCDIR) -I$(JSONF)/include
FFLAGS=-I$(JSONF)/include
# Linker flags
LDFLAGS=$(LIBS)

.PHONY: all clean

all: $(TARGET)

clean:
	rm -f *.o *.h *.inc *.mod

$(TARGET): $(OBJ)
	$(LD) -o $(TARGET) $(OBJ) $(LIBS)

m_jsons.o: ./m_jsons.F90
	$(FC) $(FFLAGS) -c ./m_jsons.F90

test_json6.o: ./test_json6.F90
	$(FC) $(FFLAGS) -c ./test_json6.F90

