.segment "BULLETS"
;;;;;;;;;;;;;
;;;Bullets;;;
;;;;;;;;;;;;;	
romEnemyBulletType:
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
;type determines all future attributes, so sprites and hitboxes can be reused
romEnemyBulletWidth:
	.byte 8
romEnemyBulletHitboxY1:
	.byte 7
romEnemyBulletHitboxY2:
	.byte 2
romEnemyBulletHitboxX1:
	.byte 3
romEnemyBulletHitboxX2:
	.byte 02
romEnemyBulletMetasprite:
	.byte BULLET_SPRITE_0
;;;;;;;;;;;;;;;;;;
;Bullet Behaviors;
;;;;;;;;;;;;;;;;;;

.macro mainFib quadrant, xPixelsH, xPixelsL, yPixelsH, yPixelsL
	pla
	tax
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sec
	lda enemyBulletYL,x
	sbc yPixelsL
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	clc
	lda enemyBulletYL,x
	adc yPixelsL
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYL,x
	lda enemyBulletYH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 2))
	sbc yPixelsH
	bcc @clearBullet
.elseif (.xmatch ({quadrant}, 3) .or .xmatch ({quadrant}, 4))
	adc yPixelsH
	bcs @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletYH,x
	lda enemyBulletXL,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc xPixelsL
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc xPixelsL
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXL,x
	lda enemyBulletXH,x
.if (.xmatch ({quadrant}, 1) .or .xmatch ({quadrant}, 4))
	adc xPixelsH
	bcs @clearBullet
.elseif (.xmatch ({quadrant}, 2) .or .xmatch ({quadrant}, 3))
	sbc xPixelsH
	bcc @clearBullet
.else
.error "Must Supply Valid Quadrant"
.endif
	sta enemyBulletXH,x
	jsr wasPlayerHit
	bcs @hitDetected
	rts
@hitDetected:
	lda #TRUE
	sta playerStatus
	rts
@clearBullet:
	lda #FALSE
	sta isEnemyBulletActive,x
	rts
.endmacro
bullet00:
	mainFib 3, #2, #0, #0, #0 
bullet01:
	mainFib 3, #1, #255, #0, #25 
bullet02:
	mainFib 3, #1, #254, #0, #50 
bullet03:
	mainFib 3, #1, #250, #0, #75 
bullet04:
	mainFib 3, #1, #246, #0, #100 
bullet05:
	mainFib 3, #1, #241, #0, #124 
bullet06:
	mainFib 3, #1, #234, #0, #149 
bullet07:
	mainFib 3, #1, #226, #0, #172 
bullet08:
	mainFib 3, #1, #217, #0, #196 
bullet09:
	mainFib 3, #1, #207, #0, #219 
bullet0A:
	mainFib 3, #1, #196, #0, #241 
bullet0B:
	mainFib 3, #1, #183, #1, #7 
bullet0C:
	mainFib 3, #1, #170, #1, #28 
bullet0D:
	mainFib 3, #1, #155, #1, #49 
bullet0E:
	mainFib 3, #1, #140, #1, #69 
bullet0F:
	mainFib 3, #1, #123, #1, #88 
bullet10:
	mainFib 3, #1, #106, #1, #106 
bullet11:
	mainFib 3, #1, #88, #1, #123 
bullet12:
	mainFib 3, #1, #69, #1, #140 
bullet13:
	mainFib 3, #1, #49, #1, #155 
bullet14:
	mainFib 3, #1, #28, #1, #170 
bullet15:
	mainFib 3, #1, #7, #1, #183 
bullet16:
	mainFib 3, #0, #241, #1, #196 
bullet17:
	mainFib 3, #0, #219, #1, #207 
bullet18:
	mainFib 3, #0, #196, #1, #217 
bullet19:
	mainFib 3, #0, #172, #1, #226 
bullet1A:
	mainFib 3, #0, #149, #1, #234 
bullet1B:
	mainFib 3, #0, #124, #1, #241 
bullet1C:
	mainFib 3, #0, #100, #1, #246 
bullet1D:
	mainFib 3, #0, #75, #1, #250 
bullet1E:
	mainFib 3, #0, #50, #1, #254 
bullet1F:
	mainFib 3, #0, #25, #1, #255 
bullet20:
	mainFib 4, #0, #0, #2, #0 
bullet21:
	mainFib 4, #0, #25, #1, #255 
bullet22:
	mainFib 4, #0, #50, #1, #254 
bullet23:
	mainFib 4, #0, #75, #1, #250 
bullet24:
	mainFib 4, #0, #100, #1, #246 
bullet25:
	mainFib 4, #0, #124, #1, #241 
bullet26:
	mainFib 4, #0, #149, #1, #234 
bullet27:
	mainFib 4, #0, #172, #1, #226 
bullet28:
	mainFib 4, #0, #196, #1, #217 
bullet29:
	mainFib 4, #0, #219, #1, #207 
bullet2A:
	mainFib 4, #0, #241, #1, #196 
bullet2B:
	mainFib 4, #1, #7, #1, #183 
bullet2C:
	mainFib 4, #1, #28, #1, #170 
bullet2D:
	mainFib 4, #1, #49, #1, #155 
bullet2E:
	mainFib 4, #1, #69, #1, #140 
bullet2F:
	mainFib 4, #1, #88, #1, #123 
bullet30:
	mainFib 4, #1, #106, #1, #106 
bullet31:
	mainFib 4, #1, #123, #1, #88 
bullet32:
	mainFib 4, #1, #140, #1, #69 
bullet33:
	mainFib 4, #1, #155, #1, #49 
bullet34:
	mainFib 4, #1, #170, #1, #28 
bullet35:
	mainFib 4, #1, #183, #1, #7 
bullet36:
	mainFib 4, #1, #196, #0, #241 
bullet37:
	mainFib 4, #1, #207, #0, #219 
bullet38:
	mainFib 4, #1, #217, #0, #196 
bullet39:
	mainFib 4, #1, #226, #0, #172 
bullet3A:
	mainFib 4, #1, #234, #0, #149 
bullet3B:
	mainFib 4, #1, #241, #0, #124 
bullet3C:
	mainFib 4, #1, #246, #0, #100 
bullet3D:
	mainFib 4, #1, #250, #0, #75 
bullet3E:
	mainFib 4, #1, #254, #0, #50 
bullet3F:
	mainFib 4, #1, #255, #0, #25 
bullet40:
	mainFib 1, #2, #0, #0, #0 
bullet41:
	mainFib 1, #1, #255, #0, #25 
bullet42:
	mainFib 1, #1, #254, #0, #50 
bullet43:
	mainFib 1, #1, #250, #0, #75 
bullet44:
	mainFib 1, #1, #246, #0, #100 
bullet45:
	mainFib 1, #1, #241, #0, #124 
bullet46:
	mainFib 1, #1, #234, #0, #149 
bullet47:
	mainFib 1, #1, #226, #0, #172 
bullet48:
	mainFib 1, #1, #217, #0, #196 
bullet49:
	mainFib 1, #1, #207, #0, #219 
bullet4A:
	mainFib 1, #1, #196, #0, #241 
bullet4B:
	mainFib 1, #1, #183, #1, #7 
bullet4C:
	mainFib 1, #1, #170, #1, #28 
bullet4D:
	mainFib 1, #1, #155, #1, #49 
bullet4E:
	mainFib 1, #1, #140, #1, #69 
bullet4F:
	mainFib 1, #1, #123, #1, #88 
bullet50:
	mainFib 1, #1, #106, #1, #106 
bullet51:
	mainFib 1, #1, #88, #1, #123 
bullet52:
	mainFib 1, #1, #69, #1, #140 
bullet53:
	mainFib 1, #1, #49, #1, #155 
bullet54:
	mainFib 1, #1, #28, #1, #170 
bullet55:
	mainFib 1, #1, #7, #1, #183 
bullet56:
	mainFib 1, #0, #241, #1, #196 
bullet57:
	mainFib 1, #0, #219, #1, #207 
bullet58:
	mainFib 1, #0, #196, #1, #217 
bullet59:
	mainFib 1, #0, #172, #1, #226 
bullet5A:
	mainFib 1, #0, #149, #1, #234 
bullet5B:
	mainFib 1, #0, #124, #1, #241 
bullet5C:
	mainFib 1, #0, #100, #1, #246 
bullet5D:
	mainFib 1, #0, #75, #1, #250 
bullet5E:
	mainFib 1, #0, #50, #1, #254 
bullet5F:
	mainFib 1, #0, #25, #1, #255 
bullet60:
	mainFib 2, #0, #0, #2, #0 
bullet61:
	mainFib 2, #0, #25, #1, #255 
bullet62:
	mainFib 2, #0, #50, #1, #254 
bullet63:
	mainFib 2, #0, #75, #1, #250 
bullet64:
	mainFib 2, #0, #100, #1, #246 
bullet65:
	mainFib 2, #0, #124, #1, #241 
bullet66:
	mainFib 2, #0, #149, #1, #234 
bullet67:
	mainFib 2, #0, #172, #1, #226 
bullet68:
	mainFib 2, #0, #196, #1, #217 
bullet69:
	mainFib 2, #0, #219, #1, #207 
bullet6A:
	mainFib 2, #0, #241, #1, #196 
bullet6B:
	mainFib 2, #1, #7, #1, #183 
bullet6C:
	mainFib 2, #1, #28, #1, #170 
bullet6D:
	mainFib 2, #1, #49, #1, #155 
bullet6E:
	mainFib 2, #1, #69, #1, #140 
bullet6F:
	mainFib 2, #1, #88, #1, #123 
bullet70:
	mainFib 2, #1, #106, #1, #106 
bullet71:
	mainFib 2, #1, #123, #1, #88 
bullet72:
	mainFib 2, #1, #140, #1, #69 
bullet73:
	mainFib 2, #1, #155, #1, #49 
bullet74:
	mainFib 2, #1, #170, #1, #28 
bullet75:
	mainFib 2, #1, #183, #1, #7 
bullet76:
	mainFib 2, #1, #196, #0, #241 
bullet77:
	mainFib 2, #1, #207, #0, #219 
bullet78:
	mainFib 2, #1, #217, #0, #196 
bullet79:
	mainFib 2, #1, #226, #0, #172 
bullet7A:
	mainFib 2, #1, #234, #0, #149 
bullet7B:
	mainFib 2, #1, #241, #0, #124 
bullet7C:
	mainFib 2, #1, #246, #0, #100 
bullet7D:
	mainFib 2, #1, #250, #0, #75 
bullet7E:
	mainFib 2, #1, #254, #0, #50 
bullet7F:
	mainFib 2, #1, #255, #0, #25 
bullet80:
	mainFib 3, #2, #128, #0, #0 
bullet81:
	mainFib 3, #2, #125, #0, #63 
bullet82:
	mainFib 3, #2, #116, #0, #125 
bullet83:
	mainFib 3, #2, #100, #0, #186 
bullet84:
	mainFib 3, #2, #79, #0, #245 
bullet85:
	mainFib 3, #2, #52, #1, #46 
bullet86:
	mainFib 3, #2, #20, #1, #100 
bullet87:
	mainFib 3, #1, #239, #1, #150 
bullet88:
	mainFib 3, #1, #197, #1, #197 
bullet89:
	mainFib 3, #1, #150, #1, #239 
bullet8A:
	mainFib 3, #1, #100, #2, #20 
bullet8B:
	mainFib 3, #1, #46, #2, #52 
bullet8C:
	mainFib 3, #0, #245, #2, #79 
bullet8D:
	mainFib 3, #0, #186, #2, #100 
bullet8E:
	mainFib 3, #0, #125, #2, #116 
bullet8F:
	mainFib 3, #0, #63, #2, #125 
bullet90:
	mainFib 4, #0, #0, #2, #128 
bullet91:
	mainFib 4, #0, #63, #2, #125 
bullet92:
	mainFib 4, #0, #125, #2, #116 
bullet93:
	mainFib 4, #0, #186, #2, #100 
bullet94:
	mainFib 4, #0, #245, #2, #79 
bullet95:
	mainFib 4, #1, #46, #2, #52 
bullet96:
	mainFib 4, #1, #100, #2, #20 
bullet97:
	mainFib 4, #1, #150, #1, #239 
bullet98:
	mainFib 4, #1, #197, #1, #197 
bullet99:
	mainFib 4, #1, #239, #1, #150 
bullet9A:
	mainFib 4, #2, #20, #1, #100 
bullet9B:
	mainFib 4, #2, #52, #1, #46 
bullet9C:
	mainFib 4, #2, #79, #0, #245 
bullet9D:
	mainFib 4, #2, #100, #0, #186 
bullet9E:
	mainFib 4, #2, #116, #0, #125 
bullet9F:
	mainFib 4, #2, #125, #0, #63 
bulletA0:
	mainFib 1, #2, #128, #0, #0 
bulletA1:
	mainFib 1, #2, #125, #0, #63 
bulletA2:
	mainFib 1, #2, #116, #0, #125 
bulletA3:
	mainFib 1, #2, #100, #0, #186 
bulletA4:
	mainFib 1, #2, #79, #0, #245 
bulletA5:
	mainFib 1, #2, #52, #1, #46 
bulletA6:
	mainFib 1, #2, #20, #1, #100 
bulletA7:
	mainFib 1, #1, #239, #1, #150 
bulletA8:
	mainFib 1, #1, #197, #1, #197 
bulletA9:
	mainFib 1, #1, #150, #1, #239 
bulletAA:
	mainFib 1, #1, #100, #2, #20 
bulletAB:
	mainFib 1, #1, #46, #2, #52 
bulletAC:
	mainFib 1, #0, #245, #2, #79 
bulletAD:
	mainFib 1, #0, #186, #2, #100 
bulletAE:
	mainFib 1, #0, #125, #2, #116 
bulletAF:
	mainFib 1, #0, #63, #2, #125 
bulletB0:
	mainFib 2, #0, #0, #2, #128 
bulletB1:
	mainFib 2, #0, #63, #2, #125 
bulletB2:
	mainFib 2, #0, #125, #2, #116 
bulletB3:
	mainFib 2, #0, #186, #2, #100 
bulletB4:
	mainFib 2, #0, #245, #2, #79 
bulletB5:
	mainFib 2, #1, #46, #2, #52 
bulletB6:
	mainFib 2, #1, #100, #2, #20 
bulletB7:
	mainFib 2, #1, #150, #1, #239 
bulletB8:
	mainFib 2, #1, #197, #1, #197 
bulletB9:
	mainFib 2, #1, #239, #1, #150 
bulletBA:
	mainFib 2, #2, #20, #1, #100 
bulletBB:
	mainFib 2, #2, #52, #1, #46 
bulletBC:
	mainFib 2, #2, #79, #0, #245 
bulletBD:
	mainFib 2, #2, #100, #0, #186 
bulletBE:
	mainFib 2, #2, #116, #0, #125 
bulletBF:
	mainFib 2, #2, #125, #0, #63 
bulletC0:
	mainFib 3, #3, #0, #0, #0 
bulletC1:
	mainFib 3, #2, #252, #0, #75 
bulletC2:
	mainFib 3, #2, #241, #0, #150 
bulletC3:
	mainFib 3, #2, #223, #0, #223 
bulletC4:
	mainFib 3, #2, #198, #1, #38 
bulletC5:
	mainFib 3, #2, #165, #1, #106 
bulletC6:
	mainFib 3, #2, #127, #1, #171 
bulletC7:
	mainFib 3, #2, #82, #1, #231 
bulletC8:
	mainFib 3, #2, #31, #2, #31 
bulletC9:
	mainFib 3, #1, #231, #2, #82 
bulletCA:
	mainFib 3, #1, #171, #2, #127 
bulletCB:
	mainFib 3, #1, #106, #2, #165 
bulletCC:
	mainFib 3, #1, #38, #2, #198 
bulletCD:
	mainFib 3, #0, #223, #2, #223 
bulletCE:
	mainFib 3, #0, #150, #2, #241 
bulletCF:
	mainFib 3, #0, #75, #2, #252 
bulletD0:
	mainFib 4, #0, #0, #3, #0 
bulletD1:
	mainFib 4, #0, #75, #2, #252 
bulletD2:
	mainFib 4, #0, #150, #2, #241 
bulletD3:
	mainFib 4, #0, #223, #2, #223 
bulletD4:
	mainFib 4, #1, #38, #2, #198 
bulletD5:
	mainFib 4, #1, #106, #2, #165 
bulletD6:
	mainFib 4, #1, #171, #2, #127 
bulletD7:
	mainFib 4, #1, #231, #2, #82 
bulletD8:
	mainFib 4, #2, #31, #2, #31 
bulletD9:
	mainFib 4, #2, #82, #1, #231 
bulletDA:
	mainFib 4, #2, #127, #1, #171 
bulletDB:
	mainFib 4, #2, #165, #1, #106 
bulletDC:
	mainFib 4, #2, #198, #1, #38 
bulletDD:
	mainFib 4, #2, #223, #0, #223 
bulletDE:
	mainFib 4, #2, #241, #0, #150 
bulletDF:
	mainFib 4, #2, #252, #0, #75 
bulletE0:
	mainFib 1, #3, #0, #0, #0 
bulletE1:
	mainFib 1, #2, #252, #0, #75 
bulletE2:
	mainFib 1, #2, #241, #0, #150 
bulletE3:
	mainFib 1, #2, #223, #0, #223 
bulletE4:
	mainFib 1, #2, #198, #1, #38 
bulletE5:
	mainFib 1, #2, #165, #1, #106 
bulletE6:
	mainFib 1, #2, #127, #1, #171 
bulletE7:
	mainFib 1, #2, #82, #1, #231 
bulletE8:
	mainFib 1, #2, #31, #2, #31 
bulletE9:
	mainFib 1, #1, #231, #2, #82 
bulletEA:
	mainFib 1, #1, #171, #2, #127 
bulletEB:
	mainFib 1, #1, #106, #2, #165 
bulletEC:
	mainFib 1, #1, #38, #2, #198 
bulletED:
	mainFib 1, #0, #223, #2, #223 
bulletEE:
	mainFib 1, #0, #150, #2, #241 
bulletEF:
	mainFib 1, #0, #75, #2, #252 
bulletF0:
	mainFib 2, #0, #0, #3, #0 
bulletF1:
	mainFib 2, #0, #75, #2, #252 
bulletF2:
	mainFib 2, #0, #150, #2, #241 
bulletF3:
	mainFib 2, #0, #223, #2, #223 
bulletF4:
	mainFib 2, #1, #38, #2, #198 
bulletF5:
	mainFib 2, #1, #106, #2, #165 
bulletF6:
	mainFib 2, #1, #171, #2, #127 
bulletF7:
	mainFib 2, #1, #231, #2, #82 
bulletF8:
	mainFib 2, #2, #31, #2, #31 
bulletF9:
	mainFib 2, #2, #82, #1, #231 
bulletFA:
	mainFib 2, #2, #127, #1, #171 
bulletFB:
	mainFib 2, #2, #165, #1, #106 
bulletFC:
	mainFib 2, #2, #198, #1, #38 
bulletFD:
	mainFib 2, #2, #223, #0, #223 
bulletFE:
	mainFib 2, #2, #241, #0, #150 
bulletFF:
	mainFib 2, #2, #252, #0, #75 

romEnemyBulletBehaviorH:
	.byte >bullet00
	.byte >bullet01
	.byte >bullet02
	.byte >bullet03
	.byte >bullet04
	.byte >bullet05
	.byte >bullet06
	.byte >bullet07
	.byte >bullet08
	.byte >bullet09
	.byte >bullet0A
	.byte >bullet0B
	.byte >bullet0C
	.byte >bullet0D
	.byte >bullet0E
	.byte >bullet0F
	.byte >bullet10
	.byte >bullet11
	.byte >bullet12
	.byte >bullet13
	.byte >bullet14
	.byte >bullet15
	.byte >bullet16
	.byte >bullet17
	.byte >bullet18
	.byte >bullet19
	.byte >bullet1A
	.byte >bullet1B
	.byte >bullet1C
	.byte >bullet1D
	.byte >bullet1E
	.byte >bullet1F
	.byte >bullet20
	.byte >bullet21
	.byte >bullet22
	.byte >bullet23
	.byte >bullet24
	.byte >bullet25
	.byte >bullet26
	.byte >bullet27
	.byte >bullet28
	.byte >bullet29
	.byte >bullet2A
	.byte >bullet2B
	.byte >bullet2C
	.byte >bullet2D
	.byte >bullet2E
	.byte >bullet2F
	.byte >bullet30
	.byte >bullet31
	.byte >bullet32
	.byte >bullet33
	.byte >bullet34
	.byte >bullet35
	.byte >bullet36
	.byte >bullet37
	.byte >bullet38
	.byte >bullet39
	.byte >bullet3A
	.byte >bullet3B
	.byte >bullet3C
	.byte >bullet3D
	.byte >bullet3E
	.byte >bullet3F
	.byte >bullet40
	.byte >bullet41
	.byte >bullet42
	.byte >bullet43
	.byte >bullet44
	.byte >bullet45
	.byte >bullet46
	.byte >bullet47
	.byte >bullet48
	.byte >bullet49
	.byte >bullet4A
	.byte >bullet4B
	.byte >bullet4C
	.byte >bullet4D
	.byte >bullet4E
	.byte >bullet4F
	.byte >bullet50
	.byte >bullet51
	.byte >bullet52
	.byte >bullet53
	.byte >bullet54
	.byte >bullet55
	.byte >bullet56
	.byte >bullet57
	.byte >bullet58
	.byte >bullet59
	.byte >bullet5A
	.byte >bullet5B
	.byte >bullet5C
	.byte >bullet5D
	.byte >bullet5E
	.byte >bullet5F
	.byte >bullet60
	.byte >bullet61
	.byte >bullet62
	.byte >bullet63
	.byte >bullet64
	.byte >bullet65
	.byte >bullet66
	.byte >bullet67
	.byte >bullet68
	.byte >bullet69
	.byte >bullet6A
	.byte >bullet6B
	.byte >bullet6C
	.byte >bullet6D
	.byte >bullet6E
	.byte >bullet6F
	.byte >bullet70
	.byte >bullet71
	.byte >bullet72
	.byte >bullet73
	.byte >bullet74
	.byte >bullet75
	.byte >bullet76
	.byte >bullet77
	.byte >bullet78
	.byte >bullet79
	.byte >bullet7A
	.byte >bullet7B
	.byte >bullet7C
	.byte >bullet7D
	.byte >bullet7E
	.byte >bullet7F
	.byte >bullet80
	.byte >bullet81
	.byte >bullet82
	.byte >bullet83
	.byte >bullet84
	.byte >bullet85
	.byte >bullet86
	.byte >bullet87
	.byte >bullet88
	.byte >bullet89
	.byte >bullet8A
	.byte >bullet8B
	.byte >bullet8C
	.byte >bullet8D
	.byte >bullet8E
	.byte >bullet8F
	.byte >bullet90
	.byte >bullet91
	.byte >bullet92
	.byte >bullet93
	.byte >bullet94
	.byte >bullet95
	.byte >bullet96
	.byte >bullet97
	.byte >bullet98
	.byte >bullet99
	.byte >bullet9A
	.byte >bullet9B
	.byte >bullet9C
	.byte >bullet9D
	.byte >bullet9E
	.byte >bullet9F
	.byte >bulletA0
	.byte >bulletA1
	.byte >bulletA2
	.byte >bulletA3
	.byte >bulletA4
	.byte >bulletA5
	.byte >bulletA6
	.byte >bulletA7
	.byte >bulletA8
	.byte >bulletA9
	.byte >bulletAA
	.byte >bulletAB
	.byte >bulletAC
	.byte >bulletAD
	.byte >bulletAE
	.byte >bulletAF
	.byte >bulletB0
	.byte >bulletB1
	.byte >bulletB2
	.byte >bulletB3
	.byte >bulletB4
	.byte >bulletB5
	.byte >bulletB6
	.byte >bulletB7
	.byte >bulletB8
	.byte >bulletB9
	.byte >bulletBA
	.byte >bulletBB
	.byte >bulletBC
	.byte >bulletBD
	.byte >bulletBE
	.byte >bulletBF
	.byte >bulletC0
	.byte >bulletC1
	.byte >bulletC2
	.byte >bulletC3
	.byte >bulletC4
	.byte >bulletC5
	.byte >bulletC6
	.byte >bulletC7
	.byte >bulletC8
	.byte >bulletC9
	.byte >bulletCA
	.byte >bulletCB
	.byte >bulletCC
	.byte >bulletCD
	.byte >bulletCE
	.byte >bulletCF
	.byte >bulletD0
	.byte >bulletD1
	.byte >bulletD2
	.byte >bulletD3
	.byte >bulletD4
	.byte >bulletD5
	.byte >bulletD6
	.byte >bulletD7
	.byte >bulletD8
	.byte >bulletD9
	.byte >bulletDA
	.byte >bulletDB
	.byte >bulletDC
	.byte >bulletDD
	.byte >bulletDE
	.byte >bulletDF
	.byte >bulletE0
	.byte >bulletE1
	.byte >bulletE2
	.byte >bulletE3
	.byte >bulletE4
	.byte >bulletE5
	.byte >bulletE6
	.byte >bulletE7
	.byte >bulletE8
	.byte >bulletE9
	.byte >bulletEA
	.byte >bulletEB
	.byte >bulletEC
	.byte >bulletED
	.byte >bulletEE
	.byte >bulletEF
	.byte >bulletF0
	.byte >bulletF1
	.byte >bulletF2
	.byte >bulletF3
	.byte >bulletF4
	.byte >bulletF5
	.byte >bulletF6
	.byte >bulletF7
	.byte >bulletF8
	.byte >bulletF9
	.byte >bulletFA
	.byte >bulletFB
	.byte >bulletFC
	.byte >bulletFD
	.byte >bulletFE
	.byte >bulletFF

romEnemyBulletBehaviorL:
	.byte <bullet00-1
	.byte <bullet01-1
	.byte <bullet02-1
	.byte <bullet03-1
	.byte <bullet04-1
	.byte <bullet05-1
	.byte <bullet06-1
	.byte <bullet07-1
	.byte <bullet08-1
	.byte <bullet09-1
	.byte <bullet0A-1
	.byte <bullet0B-1
	.byte <bullet0C-1
	.byte <bullet0D-1
	.byte <bullet0E-1
	.byte <bullet0F-1
	.byte <bullet10-1
	.byte <bullet11-1
	.byte <bullet12-1
	.byte <bullet13-1
	.byte <bullet14-1
	.byte <bullet15-1
	.byte <bullet16-1
	.byte <bullet17-1
	.byte <bullet18-1
	.byte <bullet19-1
	.byte <bullet1A-1
	.byte <bullet1B-1
	.byte <bullet1C-1
	.byte <bullet1D-1
	.byte <bullet1E-1
	.byte <bullet1F-1
	.byte <bullet20-1
	.byte <bullet21-1
	.byte <bullet22-1
	.byte <bullet23-1
	.byte <bullet24-1
	.byte <bullet25-1
	.byte <bullet26-1
	.byte <bullet27-1
	.byte <bullet28-1
	.byte <bullet29-1
	.byte <bullet2A-1
	.byte <bullet2B-1
	.byte <bullet2C-1
	.byte <bullet2D-1
	.byte <bullet2E-1
	.byte <bullet2F-1
	.byte <bullet30-1
	.byte <bullet31-1
	.byte <bullet32-1
	.byte <bullet33-1
	.byte <bullet34-1
	.byte <bullet35-1
	.byte <bullet36-1
	.byte <bullet37-1
	.byte <bullet38-1
	.byte <bullet39-1
	.byte <bullet3A-1
	.byte <bullet3B-1
	.byte <bullet3C-1
	.byte <bullet3D-1
	.byte <bullet3E-1
	.byte <bullet3F-1
	.byte <bullet40-1
	.byte <bullet41-1
	.byte <bullet42-1
	.byte <bullet43-1
	.byte <bullet44-1
	.byte <bullet45-1
	.byte <bullet46-1
	.byte <bullet47-1
	.byte <bullet48-1
	.byte <bullet49-1
	.byte <bullet4A-1
	.byte <bullet4B-1
	.byte <bullet4C-1
	.byte <bullet4D-1
	.byte <bullet4E-1
	.byte <bullet4F-1
	.byte <bullet50-1
	.byte <bullet51-1
	.byte <bullet52-1
	.byte <bullet53-1
	.byte <bullet54-1
	.byte <bullet55-1
	.byte <bullet56-1
	.byte <bullet57-1
	.byte <bullet58-1
	.byte <bullet59-1
	.byte <bullet5A-1
	.byte <bullet5B-1
	.byte <bullet5C-1
	.byte <bullet5D-1
	.byte <bullet5E-1
	.byte <bullet5F-1
	.byte <bullet60-1
	.byte <bullet61-1
	.byte <bullet62-1
	.byte <bullet63-1
	.byte <bullet64-1
	.byte <bullet65-1
	.byte <bullet66-1
	.byte <bullet67-1
	.byte <bullet68-1
	.byte <bullet69-1
	.byte <bullet6A-1
	.byte <bullet6B-1
	.byte <bullet6C-1
	.byte <bullet6D-1
	.byte <bullet6E-1
	.byte <bullet6F-1
	.byte <bullet70-1
	.byte <bullet71-1
	.byte <bullet72-1
	.byte <bullet73-1
	.byte <bullet74-1
	.byte <bullet75-1
	.byte <bullet76-1
	.byte <bullet77-1
	.byte <bullet78-1
	.byte <bullet79-1
	.byte <bullet7A-1
	.byte <bullet7B-1
	.byte <bullet7C-1
	.byte <bullet7D-1
	.byte <bullet7E-1
	.byte <bullet7F-1
	.byte <bullet80-1
	.byte <bullet81-1
	.byte <bullet82-1
	.byte <bullet83-1
	.byte <bullet84-1
	.byte <bullet85-1
	.byte <bullet86-1
	.byte <bullet87-1
	.byte <bullet88-1
	.byte <bullet89-1
	.byte <bullet8A-1
	.byte <bullet8B-1
	.byte <bullet8C-1
	.byte <bullet8D-1
	.byte <bullet8E-1
	.byte <bullet8F-1
	.byte <bullet90-1
	.byte <bullet91-1
	.byte <bullet92-1
	.byte <bullet93-1
	.byte <bullet94-1
	.byte <bullet95-1
	.byte <bullet96-1
	.byte <bullet97-1
	.byte <bullet98-1
	.byte <bullet99-1
	.byte <bullet9A-1
	.byte <bullet9B-1
	.byte <bullet9C-1
	.byte <bullet9D-1
	.byte <bullet9E-1
	.byte <bullet9F-1
	.byte <bulletA0-1
	.byte <bulletA1-1
	.byte <bulletA2-1
	.byte <bulletA3-1
	.byte <bulletA4-1
	.byte <bulletA5-1
	.byte <bulletA6-1
	.byte <bulletA7-1
	.byte <bulletA8-1
	.byte <bulletA9-1
	.byte <bulletAA-1
	.byte <bulletAB-1
	.byte <bulletAC-1
	.byte <bulletAD-1
	.byte <bulletAE-1
	.byte <bulletAF-1
	.byte <bulletB0-1
	.byte <bulletB1-1
	.byte <bulletB2-1
	.byte <bulletB3-1
	.byte <bulletB4-1
	.byte <bulletB5-1
	.byte <bulletB6-1
	.byte <bulletB7-1
	.byte <bulletB8-1
	.byte <bulletB9-1
	.byte <bulletBA-1
	.byte <bulletBB-1
	.byte <bulletBC-1
	.byte <bulletBD-1
	.byte <bulletBE-1
	.byte <bulletBF-1
	.byte <bulletC0-1
	.byte <bulletC1-1
	.byte <bulletC2-1
	.byte <bulletC3-1
	.byte <bulletC4-1
	.byte <bulletC5-1
	.byte <bulletC6-1
	.byte <bulletC7-1
	.byte <bulletC8-1
	.byte <bulletC9-1
	.byte <bulletCA-1
	.byte <bulletCB-1
	.byte <bulletCC-1
	.byte <bulletCD-1
	.byte <bulletCE-1
	.byte <bulletCF-1
	.byte <bulletD0-1
	.byte <bulletD1-1
	.byte <bulletD2-1
	.byte <bulletD3-1
	.byte <bulletD4-1
	.byte <bulletD5-1
	.byte <bulletD6-1
	.byte <bulletD7-1
	.byte <bulletD8-1
	.byte <bulletD9-1
	.byte <bulletDA-1
	.byte <bulletDB-1
	.byte <bulletDC-1
	.byte <bulletDD-1
	.byte <bulletDE-1
	.byte <bulletDF-1
	.byte <bulletE0-1
	.byte <bulletE1-1
	.byte <bulletE2-1
	.byte <bulletE3-1
	.byte <bulletE4-1
	.byte <bulletE5-1
	.byte <bulletE6-1
	.byte <bulletE7-1
	.byte <bulletE8-1
	.byte <bulletE9-1
	.byte <bulletEA-1
	.byte <bulletEB-1
	.byte <bulletEC-1
	.byte <bulletED-1
	.byte <bulletEE-1
	.byte <bulletEF-1
	.byte <bulletF0-1
	.byte <bulletF1-1
	.byte <bulletF2-1
	.byte <bulletF3-1
	.byte <bulletF4-1
	.byte <bulletF5-1
	.byte <bulletF6-1
	.byte <bulletF7-1
	.byte <bulletF8-1
	.byte <bulletF9-1
	.byte <bulletFA-1
	.byte <bulletFB-1
	.byte <bulletFC-1
	.byte <bulletFD-1
	.byte <bulletFE-1
	.byte <bulletFF-1
