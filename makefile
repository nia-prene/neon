Neon: main.s
	ca65 main.s -o ~/nes/neon/dbg/neon.o -I etc --debug-info
	ld65 dbg/neon.o -o ~/nes/neon/dbg/neon.nes -C etc/neon.cfg --dbgfile ~/nes/neon/dbg/neon.dbg
	#fceux dbg/neon.nes
	wine ~/programs/fceux/fceux.exe
