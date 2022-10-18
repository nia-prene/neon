objects = apu.o bombs.o bullets.o effects.o enemies.o gamepads.o gamestates.o hud.o lib.o main.o oam.o palettes.o patterns.o shots.o player.o pickups.o ppu.o scenes.o score.o sprites.o tiles.o textbox.o waves.o
game = neon.nes
source = src/
builddir = build/
configfile = neon.cfg
debugfile = neon.dbg
EMULATOR = ~/Programs/Mesen/Mesen.exe
cleanfiles = *.o *.dbg *.nes

LD = ld65
AS = ca65
MONO = mono

ASflags =-o $(builddir)$@ --debug-info
LDflags =-o $(builddir)$@ -C $(configfile) --dbgfile $(builddir)$(debugfile)

.PHONY all: $(objects) $(game)

$(objects): %.o: $(source)%.s $(source)%.h
	$(AS) $(ASflags) $<

$(game): $(objects)
	$(LD) $(LDflags) $(builddir)*.o

test: ${game}
	${MONO} ${EMULATOR} ${builddir}${game} &

clean:
	-rm $(builddir)*.o
