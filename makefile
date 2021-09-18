objects = bullets.o enemies.o gamepads.o init.o lib.o main.o oam.o palettes.o playerbullets.o player.o powerup.o ppu.o scenes.o sprites.o tiles.o waves.o
game = neon.nes
source = src/
builddir = build/
configfile = neon.cfg
debugfile = neon.dbg
EMULATOR = ~/programs/fceux/fceux.exe
cleanfiles = *.o *.dbg *.nes

LD = ld65
AS = ca65
WINE = wine

ASflags =-o $(builddir)$@ --debug-info
LDflags =-o $(builddir)$@ -C $(configfile) --dbgfile $(builddir)$(debugfile)

.PHONY all: $(objects) $(game) test

$(objects): %.o: $(source)%.s $(source)%.h
	$(AS) $(ASflags) $<

$(game): $(objects)
	$(LD) $(LDflags) $(builddir)*.o

test: ${game}
	${WINE} ${EMULATOR} ${builddir}${game}

clean:
	-rm $(builddir)*.o
