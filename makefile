SHELL := /bin/bash

objects = apu.o bombs.o bullets.o ease.o effects.o enemies.o gamepads.o gamestates.o hud.o lib.o main.o oam.o palettes.o patterns.o shots.o player.o powerups.o ppu.o scenes.o score.o sprites.o tiles.o textbox.o waves.o 
game = neon.nes
source = src/
builddir = obj/
configfile = neon.cfg
debugfile = neon.dbg
EMULATOR = ~/Programs/Mesen/Mesen.exe
cleanfiles = *.o *.dbg *.nes

vpath %.s src
vpath %.h src
vpath %.sh src
vpath %.py src
vpath %.o obj
vpath %.cfg src

src = src/
LD = ld65
AS = ca65
MONO = mono

ASflags =-o $(builddir)$@ --debug-info
LDflags =-o $(builddir)$@ -C $(configfile) --dbgfile $(builddir)$(debugfile)

$(game): $(objects) 
	$(LD) $(LDflags) $(builddir)*.o

$(objects): %.o: $(source)%.s $(source)%.h $(src)metasprites.s $(src)sprites.chr
	$(AS) $(ASflags) $<

$(src)ease.s: ease.sh ease.cfg
	$< > $@

$(src)ease.h: ease_header.sh ease.cfg
	$< > $@

$(src)animations.s: $(src)animations.sh
	$< > $@

$(src)metasprites.s $(src)sprites.chr $(src)sprite_palettes.s: sprites.sh animations.s
	$< 

test: ${game}
	${MONO} ${EMULATOR} ${builddir}${game} &

