;ppu registers

PPUCTRL = $2000;(VPHB SINN) NMI enable (V), PPU master/slave (P), sprite height (H), background tile select (B), sprite tile select (S), increment mode (I), nametable select (NN)
PPUMASK = $2001;(BGRs bMmG)	color emphasis (BGR), sprite enable (s), background enable (b), sprite left column enable (M), background left column enable (m), greyscale (G)
PPUSTATUS = $2002;(VSO- ----) vblank (V), sprite 0 hit (S), sprite overflow (O); read resets write pair for $2005/$2006
OAMADDR = $2003;(aaaa aaaa) OAM read/write address
OAMDATA = $2004;(dddd dddd)	OAM data read/write
PPUSCROLL = $2005;(xxxx xxxx) fine scroll position (two writes: X scroll, Y scroll)
PPUADDR = $2006;(aaaa aaaa)	PPU read/write address (two writes: most significant byte, least significant byte)
PPUDATA = $2007;(dddd dddd)	PPU data read/write
OAMDMA = $4014;(aaaa aaaa)OAM DMA high address

;apu registers

SQ1_VOL = $4000;Duty and volume for square wave 1
SQ1_SWEEP = $4001;Sweep control register for square wave 1
SQ1_LO = $4002;Low byte of period for square wave 1
SQ1_HI = $4003;High byte of period and length counter value for square wave 1
SQ2_VOL = $4004;Duty and volume for square wave 2
SQ2_SWEEP = $4005;Sweep control register for square wave 2
SQ2_LO = $4006;Low byte of period for square wave 2
SQ2_HI = $4007;High byte of period and length counter value for square wave 2
TRI_LINEAR = $4008;Triangle wave linear counter
TRI_LO = $400A;Low byte of period for triangle wave
TRI_HI = $400B;High byte of period and length counter value for triangle wave
NOISE_VOL = $400C;Volume for noise generator
NOISE_LO = $400E;Period and waveform shape for noise generator
NOISE_HI = $400F;Length counter value for noise generator
DMC_FREQ = $4010;Play mode and frequency for DMC samples
DMC_RAW = $4011;7-bit DAC
DMC_START = $4012;Start of DMC waveform is at address $C000 + $40*$xx
DMC_LEN = $4013;Length of DMC waveform is $10*$xx + 1 bytes (128*$xx + 8 samples)
SND_CHN = $4015;Sound channels enable and status
JOY1 = $4016;Joystick 1 data (R) and joystick strobe (W)
JOY2 = $4017;Joystick 2 data (R) and frame counter control (W) 

;Project ppu settings
OAM_LOCATION = 02

BASE_NAMETABLE = 0;this here for ease of change
VRAM_INCREMENT = 1;0: add 1, going across; 1: add 32, going down
SPRITE_TABLE = 0;0: $0000, 1: $1000, ignored in 8x16 mode
BACKGROUND_TABLE = 1;0: $0000 1: $1000
SPRITE_SIZE = 0;0: 8x8 pixels 1: 8x16 pixels
PPU_MASTER_SLAVE = 0;leave this alone
GENERATE_NMI = 1; leave default as on

PPU_SETTINGS = BASE_NAMETABLE | (VRAM_INCREMENT << 2) | (SPRITE_TABLE << 3) | (BACKGROUND_TABLE << 4) | (SPRITE_SIZE << 5) |(PPU_MASTER_SLAVE << 6) | (GENERATE_NMI << 7)

;PPU_SETTINGS options
DISABLE_NMI = %01111111;AND 
INCREMENT_1 = %11111011;AND 
INCREMENT_32 = %00000100;OR
NAMETABLE_0 = %11111100;and
NAMETABLE_1 = %00000001;OR 
NAMETABLE_2 = %00000010;OR
NAMETABLE_3 = %00000011;OR

;project settings for mask
GREYSCALE = 0;0: normal color, 1: produce a greyscale display
LEFT_BACKGROUND = 1;1: Show background in leftmost 8 pixels of screen, 0: Hide
LEFT_SPRITES = 1;1: Show sprites in leftmost 8 pixels of screen, 0: Hide
SHOW_BACKGROUND = 0;1: shows backgrounds, 0: disables backgrounds
SHOW_SPRITES = 0;1: shows sprites, 0: disables sprites
RED_EMPHASIS = 0;1 is on 0 is off
GREEN_EMPHASIS = 0;1 is on 0 is off
BLUE_EMPHASIS = 0;1 is on 0 is off

MASK_SETTINGS = GREYSCALE | (LEFT_BACKGROUND << 1) | (LEFT_SPRITES << 2) | (SHOW_BACKGROUND <<3) | (SHOW_SPRITES << 4) | (RED_EMPHASIS << 5) | (GREEN_EMPHASIS << 6) | (BLUE_EMPHASIS << 7)

;MASK_SETTINGS OPTIONS
;OR these to enable them
STANDARD_COLOR = %00011110; and
EMPHASIZE_RED = %00100000; or
EMPHASIZE_GREEN = %01000000; or
EMPHASIZE_BLUE = %10000000; or
ENABLE_RENDERING = %00011000; or:w
DISABLE_RENDERING = %11100111;and


true = $01 
false = $00
null = $ff



