;constants
.global PPUMASK

; attributes
.globalzp PPU_stack
.globalzp PPU_havePalettesChanged
.globalzp PPU_willVRAMUpdate
.globalzp Scroll_delta

.global PPU_bufferReady

; methods
.global PPU_init
.global PPU_resetClock
.global PPU_advanceClock
.global PPU_resetScroll
.global PPU_setScroll
.global PPU_updateScroll
.global PPU_renderRightScreen
.global PPU_waitForSprite0Hit
.global PPU_waitForSprite0Reset
.global PPU_dimScreen
.global PPU_lightenScreen
.global PPU_renderScore
.global PPU_scoreToBuffer
.global PPU_NMIPlan00
.global PPU_NMIPlan01
.global PPU_NMIPlan02
.global PPU_NMIPlan03
.global enableRendering
.global disableRendering
.global renderAllPalettes
.global PPU_renderScreen
.global PPU_drawPressStart
