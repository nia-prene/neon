TARGET = neon.nes
OBJECTS = neon.o
SOURCE = src/main.s
BUILDDIR = build/
INCLUDE = src
OUTPUT = neon.nes
CONFIGFILE = neon.cfg
DEBUGFILE = neon.dbg
EMULATOR = ~/programs/fceux/fceux.exe
CLEANFILES = *.o *.dbg *.nes

LD = ld65
AS = ca65
WINE = wine

ASFLAGS = -o ${BUILDDIR}${OBJECTS} -I ${INCLUDE} --debug-info

LDFLAGS = -o ${BUILDDIR}${OUTPUT} -C ${CONFIGFILE} --dbgfile ${BUILDDIR}${DEBUGFILE}

all: assemble link test

assemble: ${SOURCE}
	${AS} ${SOURCE} ${ASFLAGS}

link: ${BUILDDIR}${OBJECTS}
	${LD} ${BUILDDIR}${OBJECTS} ${LDFLAGS}

test: ${BUILDDIR}${TARGET}
	${WINE} ${EMULATOR} ${BUILDDIR}${TARGET}

clean:
	rm -r ${BUILDDIR}
	mkdir ${BUILDDIR}
