TARGET = neon.nes
OBJECTS = neon.o
SOURCE = main.s
DEBUGDIR = ~/nes/neon/dbg/
INCLUDE = etc
OUTPUT = neon.nes
CONFIGFILE = ${INCLUDE}/neon.cfg
DEBUGFILE = neon.dbg
EMULATOR = ~/programs/fceux/fceux.exe
CLEANFILES = *.o *.dbg *.nes

LD = ld65
AS = ca65
WINE = wine

ASFLAGS = -o ${DEBUGDIR}${OBJECTS} -I ${INCLUDE} --debug-info

LDFLAGS = -o ${DEBUGDIR}${OUTPUT} -C ${CONFIGFILE} --dbgfile ${DEBUGDIR}${DEBUGFILE}

all: assemble link test

assemble: ${SOURCE}
	${AS} ${SOURCE} ${ASFLAGS}

link: ${DEBUGDIR}${OBJECTS}
	${LD} ${DEBUGDIR}${OBJECTS} ${LDFLAGS}

test: ${DEBUGDIR}${TARGET}
	${WINE} ${EMULATOR} ${DEBUGDIR}${TARGET}

clean:
	rm -r ${DEBUGDIR}
	mkdir ${DEBUGDIR}
