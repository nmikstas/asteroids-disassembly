;None of the work in understanding this file was done by me.  I found
;this info at http://computerarcheology.com/Arcade/Asteroids/VectorROM.html.
;Detailed DVG info can be found at https://www.philpem.me.uk/elec/vecgen.pdf.
;The addresses were wrong so I fixed that and modified the equation for the
;Address calculations. I added a detailed description of how scaling works
;based on my studies of the hardware. Finally, I made the file assemblable.
;Mad props to Lonnie Howell and Mark McDougall.
;This code is fully assemblable using Ophis.
;Last updated 7/28/2018 by Nick Mikstas.

;The following technical data was taken from the websites listed above and is
;posted here for convenience.

;---------------------------------------[ Screen Geometry ]----------------------------------------

;The DVG keeps up with a current (x,y) cursor coordinate. (0,0) is the lower left corner of the
;display. (1023,1023) is the upper right corner of the display. Vectors are defined as a deltaX,
;deltaY, and intensity (0 through 15). The line intensity (brightness) increases with 0 being "off"
;and 15 being the brightest. Intensity 0 can be used to move the (x,y) cursor without drawing a
;line. The deltas can be positive or negative to draw a line in any direction from the current
;cursor location. The deltas are not represented in 2's compliment for negative numbers, but
; instead positive and negative numbers are the same with a separate sign bit. 

;Scaling is a major factor and comes from multiple sources.  There is a global scaling modifier
;that is set with the CUR opcode.  The VEC opcode sets a local scaling factor for the current
;vector being drawn.  The SVEC opcode also has a scaling factor that is different than the VEC
;scaling factor.  The total scaling is a combination of the VEC/SVEC scaling factor and the
;global scaling modifier.  The scaling factor and modifier can be associated with both a number
;and multiplier.  Both will be discussed here.

;It should be noted that a total scaling factor of 9 means that the vector's XY components have
;a range of +/- 1023 units. The display is 1024 units wide and tall, therefore a total scaling
;factor of 9 is equal to screen width(or height)/1-1.  A total scaling factor of 0 is equal to
;screen width/512-1 which means the vector has a range of +/- 1 in the X or Y directions.

;-----------------------
;Global Scaling Modifier
;-----------------------
;The 32-bit CUR command has the following format:
;1010 00yy yyyy yyyy | SSSS 00xx xxxx xxxx
;A detailed explanation of the command can be found in the CUR opcode section.  For this section,
;the SSSS is of interest because it sets the global scaling modifier.  The global scaling number
;is the signed 4-bit SSSS value.  The global scaling number and its associated scaling multiplier
;are listed in the following table:

;     Global Scaling Modifier
;----------------------------------
;  Bits  |  Number  |  Multiplier
;  1000  |    -8    |    1/256
;  1001  |    -7    |    1/128
;  1010  |    -6    |    1/64
;  1011  |    -5    |    1/32
;  1100  |    -4    |    1/16
;  1101  |    -3    |    1/8
;  1110  |    -2    |    1/4
;  1111  |    -1    |    1/2
;  0000  |     0    |    1
;  0001  |     1    |    2
;  0010  |     2    |    4
;  0011  |     3    |    8
;  0100  |     4    |    16
;  0101  |     5    |    32
;  0110  |     6    |    64
;  0111  |     7    |    128

;------------------
;VEC Scaling Factor
;------------------
;The VEC opcode is actually the scaling factor.  The VEC command has the following format:
;SSSS -mYY YYYY YYYY | BBBB -mXX XXXX XXXX
;The scaling number for this reason is limited to 0-9.  The bits of the scaling factor can
;be thought of as an unsigned number.  The VEC scaling number and its associated scaling
;multiplier are listed in the following table:

;     VEC Scaling Factor
;----------------------------------
;  Bits  |  Number  |  Multiplier
;  0000  |    0     |    1/512
;  0001  |    1     |    1/256
;  0010  |    2     |    1/128
;  0011  |    3     |    1/64
;  0100  |    4     |    1/32
;  0101  |    5     |    1/16
;  0110  |    6     |    1/8
;  0111  |    7     |    1/4
;  1001  |    8     |    1/2
;  1001  |    9     |    1

;-------------------
;SVEC Scaling Factor
;-------------------
;The SVEC command has the following format:
;1111 smYY BBBB SmXX
;The scaling factor is Ss.  The 2 Scaling bits get remapped in the hardware to match bits in the
;VEC command.  The 2-bit SVEC scaling number, its remapped bits and its associated scaling
;multiplier are listed in the following table:

;               SVEC Scaling Factor
;--------------------------------------------------
;  Bits  |  Remapped Bits  |  Number  |  Multiplier
;   00   |      0010       |    2     |    1/128
;   01   |      0011       |    3     |    1/64
;   10   |      0100       |    4     |    1/32
;   11   |      0101       |    5     |    1/16

;-------------------
;Total Scaling Value
;-------------------
;The scaling factor and scaling modifier numbers can be added together to form a total scaling
;number:

;Total Scaling Number = VEC(or SVEC) Scaling Number + Global Scaling Number

;The associated total scaling multiplier can be found in the VEC table in the same row as the
;resulting number.  Also, the total scaling factor can be calculated as:

;Total Scaling Multiplier = VEC(or SVEC) Scaling Multiplier * Global Scaling Multiplier

;As with the VEC command, the SVEC scaling number and its associated multiplier are in the same
;table row.  It should be noted that a scaling number outside the range of 0-9 is not valid.  It
;will load the vector timer with all 1s and cause it to expire on the next clock cycle.  The
;easiest way to calculate the scaling number is to add the 4-bit values together and ignore the
;carry.  In the case of SVEC, use the remapped bits.  Then, look up the 4-bit value in the VEC
;scaling factor table.  Here are some examples:

;                       Bits Number Multiplier  
;Global scaling value:  0011    3      8   
;VEC scaling value:    +0101   +5    *1/16
;                      -----  -----  -----
;Total scaling value:   1000    8     1/2

;                       Bits Number Multiplier  
;Global scaling value:  1101   -3     1/8
;SVEC scaling value:   +0100   +4    *1/32
;                      -----  -----  -----
;Total scaling value:   0001    1    1/256

;                       Bits Number Multiplier  
;Global scaling value:  0101    5     32
;SVEC scaling value:   +0101   +5    *1/16 
;                      -----  -----  -----
;Total scaling value:   1010   10      2     INVALID!

;                       Bits Number Multiplier
;Global scaling value:  1000   -8    1/256
;VEC scaling value:    +0100   +4    *1/32
;                      -----  -----  -----
;Total scaling value:   1100   -4    1/8192  INVALID!

;As can be seen from the examples above, A total scaling number outside the range 0 to 9 is
;invalid and a total scaling factor outside the range 1 to 1/512 is invalid.  Also note that the
;numbers wrap around.  That means that 1100 = -4 can also be interpreted as 12.  Both are invalid.
;In terms of hardware, the invalid range occurs because the two values are added together and the
;result is passed into a BCD to decimal decoder.  If the 4-bit BCD value is greater than 9, the
;decoder simply turns on all its output bits, causing the timer to load with its maximum value.

;-------------------------------------[ Vector Specification ]-------------------------------------

;A vector has a deltaX, deltaY, and an intensity. It also has its own "local" scale factor. This
;"local" scale-factor is added to the global scale-factor to make a "total" scale-factor used in
;rendering the vector. Take these two lines for instance. Assume the global scale-factor is 0:

;        dx   dy  int  scale
;LineTo (800,  0,  15,  5)
;LineTo (1600, 0,  15,  4)

;The first line is drawn 50 units to the right since the total scale factor is 0+5 = 5 (divide-
;by-16). 800/16=50. The second line has a total factor of 0+4 = 4 (divide by 32). It is also drawn
;50 units to the right. 1600/32=50. If the global scale-factor were set to 4 then the first line
;would be drawn with a factor of 5+4=9 (divide-by-one). The line would be 800 units long. The
;second line would be drawn with a factor of 4+4=8 (divide-by-two). The line would be 800 units
;long. Thus the added global scale-factor of 4 has made the sequence of lines 16 times larger.

;= DVG Opcodes =

;Most DVG commands are one word (two bytes) long. Some are two words (four bytes). The upper
;nibble of the first word is the command.

;0 - 9 : VEC  -- a full vector command
;    A : CUR  -- set the current (x,y) and global scale-factor
;    B : HALT -- end of commands
;    C : JSR  -- jump to a vector program subroutine
;    D : RTS  -- return from a vector program subroutine
;    E : JMP  -- jump to a location in the vector program
;    F : SVEC -- a short vector command

;------------------------------------------[ VEC Opcode ]------------------------------------------

;Draw a line from the current (x,y) coordinate.

;Example:    
              ;  SSSS -mYY YYYY YYYY | BBBB -mXX XXXX XXXX
;87FE 73FE    ;  1000 0111 1111 1110 | 0111 0011 1111 1110
              ; - SSSS is the local scale 0 .. 9 added to the global scale
              ; - BBBB is the brightness: 0 .. 15
              ; - m is 1 for negative or 0 for positive for the X and Y deltas
              ; - (x,y) is the coordinate delta for the vector
   
;VEC  scale=08(/2)   x=1022    y=-1022 b=07

;------------------------------------------[ CUR Opcode ]------------------------------------------

;Set the current (x,y) and global scale-factor.

;Example:
              ; 1010 00yy yyyy yyyy | SSSS 00xx xxxx xxxx
;A37F 03FF    ; 1010 0011 0111 1111 | 0000 0011 1111 1111
              ; - SSSS is the global scale 0 .. 15
              ; - (x,y) is the new (x,y) coordinate. This is NOT adjusted by SSSS.
   
;CUR  scale=00(/512)  y=895  x=1023

;------------------------------------------[ HALT Opcode ]-----------------------------------------

;End the current drawing list.

;B000         ; 1011 0000 0000 0000

;HALT

;------------------------------------------[ JSR Opcode ]------------------------------------------

;Jump to a vector subroutine. Note that there is room in the internal "stack" for only FOUR levels
;of nested subroutine calls. Be careful. 

;Example:             
;        1100 aaaa_aaaa_aaaa
;             |||| |||| ||||
;          010aaaa_aaaa_aaaa0    

;Address Conversion:        
;$4000 + aaaa_aaaa_aaaa * 2

;------------------------------------------[ RTS Opcode ]------------------------------------------

;Return from current vector subroutine.

;D000         ; 1101 0000 0000 0000

;RTS

;------------------------------------------[ JMP Opcode ]------------------------------------------

;Jump to a new location in the vector program.

;Example:
;        1110 aaaa_aaaa_aaaa
;             |||| |||| ||||
;          010aaaa_aaaa_aaaa0

;Address Conversion:        
;$4000 + aaaa_aaaa_aaaa * 2

;------------------------------------------[ SVEC Opcode ]-----------------------------------------

;Use a "short" notation to draw a vector. This does not mean the vector itself is necessarily
;short. It means that the notation is shorter (fewer bits of resolution).  In the hardware, the
;signal to indicate the SVEC command is being processed is ALPHANUM.  This indicates that the SVEC
;command is particularly useful for drawing numbers and letters on the display.

;Example:
         ; 1111 smYY BBBB SmXX
;FF70    ; 1111 1111 0111 0000
         ; - Ss This is added to the global scale
         ; - BBBB is the brightness: 0 .. 15
         ; - m is 1 for negative and 0 for positive for the X and Y
         ; - (x,y) is the coordinate change for the vector   
   
;SVEC scale=01(/256) x=0     y=-3    b=7

;-----------------------------------------[ Start of ROM ]-----------------------------------------

.org $5000

;-----------------------------------[Test Pattern Vector Data ]------------------------------------

;Test Pattern. Diamond pattern across screen with a parallel line pattern in the center. 
L5000:  .word $A080, $0000      ;CUR  scale=0(/512) x=0     y=128  
L5004:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L5008:  .word $9000, $73FF      ;VEC  scale=9(/1)   x=1023  y=0     b=7
L500C:  .word $92FF, $7000      ;VEC  scale=9(/1)   x=0     y=767   b=7
L5010:  .word $9000, $77FF      ;VEC  scale=9(/1)   x=-1023 y=0     b=7
L5014:  .word $96FF, $7000      ;VEC  scale=9(/1)   x=0     y=-767  b=7

L5018:  .word $92FF, $72FF      ;VEC  scale=9(/1)   x=767   y=767   b=7
L501C:  .word $8600, $7200      ;VEC  scale=8(/2)   x=512   y=-512  b=7
L5020:  .word $87FE, $77FE      ;VEC  scale=8(/2)   x=-1022 y=-1022 b=7
L5024:  .word $9200, $7600      ;VEC  scale=9(/1)   x=-512  y=512   b=7
L5028:  .word $81FE, $7200      ;VEC  scale=8(/2)   x=512   y=510   b=7
L502C:  .word $96FF, $72FF      ;VEC  scale=9(/1)   x=767   y=-767  b=7
L5030:  .word $A37F, $03FF      ;CUR  scale=0(/512) x=1023  y=895  

L5034:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L5038:  .word $96FF, $76FF      ;VEC  scale=9(/1)   x=-767  y=-767  b=7
L503C:  .word $81FE, $7600      ;VEC  scale=8(/2)   x=-512  y=510   b=7
L5040:  .word $9200, $7200      ;VEC  scale=9(/1)   x=512   y=512   b=7
L5044:  .word $87FE, $73FE      ;VEC  scale=8(/2)   x=1022  y=-1022 b=7
L5048:  .word $8600, $7600      ;VEC  scale=8(/2)   x=-512  y=-512  b=7
L504C:  .word $92FF, $76FF      ;VEC  scale=9(/1)   x=-767  y=767   b=7
L5050:  .word $A1FC, $01F4      ;CUR  scale=0(/512) x=500   y=508  

L5054:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L5058:  .word $F0DB             ;SVEC scale=2(/32)  x=3     y=0     b=13
L505A:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L505C:  .word $F0CF             ;SVEC scale=2(/32)  x=-3    y=0     b=12
L505E:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5060:  .word $F0BB             ;SVEC scale=2(/32)  x=3     y=0     b=11
L5062:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5064:  .word $F0AF             ;SVEC scale=2(/32)  x=-3    y=0     b=10
L5066:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5068:  .word $F09B             ;SVEC scale=2(/32)  x=3     y=0     b=9
L506A:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L506C:  .word $F08F             ;SVEC scale=2(/32)  x=-3    y=0     b=8
L506E:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5070:  .word $F07B             ;SVEC scale=2(/32)  x=3     y=0     b=7
L5072:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5074:  .word $F06F             ;SVEC scale=2(/32)  x=-3    y=0     b=6
L5076:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5078:  .word $F05B             ;SVEC scale=2(/32)  x=3     y=0     b=5
L507A:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L507C:  .word $F04F             ;SVEC scale=2(/32)  x=-3    y=0     b=4
L507E:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5080:  .word $F03B             ;SVEC scale=2(/32)  x=3     y=0     b=3
L5082:  .word $F900             ;SVEC scale=1(/64)  x=0     y=1     b=0
L5084:  .word $F02F             ;SVEC scale=2(/32)  x=-3    y=0     b=2
L5086:  .word $D07C             ;RTS 

;------------------------------------[ Bank Error Vector Data ]------------------------------------

;Bank Error. In Revision 1 of this ROM, the text is: "PAGE SELECT ERROR".
;"BANK ERROR"  In this Revision 2.
VecBankErr:
L5088:  .word $A0E4, $115E      ;CUR  scale=1(/256) x=350   y=228  
L508C:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L5090:  .word $CA80             ;JSR  $5500
L5092:  .word $CA78             ;JSR  $54F0
L5094:  .word $CAD8             ;JSR  $55B0
L5096:  .word $CAC7             ;JSR  $558E
L5098:  .word $CB2C             ;JSR  $5658
L509A:  .word $CA9B             ;JSR  $5536
L509C:  .word $CAF3             ;JSR  $55E6
L509E:  .word $CAF3             ;JSR  $55E6
L50A0:  .word $CADD             ;JSR  $55BA
L50A2:  .word $EAF3             ;JMP  $55E6

;----------------------------------[Atari Copyright Vector Data]-----------------------------------

;Credits. In Revision 1 of this ROM the text is "ASTEROIDS BY ATARI".
;"c 1979 ATARI INC" In this Revision 2.
VecCredits:
L50A4:  .word $A080, $0190      ;CUR  scale=0(/512) x=400   y=128  
L50A8:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L50AC:  .word $F573             ;SVEC scale=0(/128) x=3     y=-1    b=7
L50AE:  .word $F173             ;SVEC scale=0(/128) x=3     y=1     b=7
L50B0:  .word $F178             ;SVEC scale=2(/32)  x=0     y=1     b=7
L50B2:  .word $F177             ;SVEC scale=0(/128) x=-3    y=1     b=7
L50B4:  .word $F577             ;SVEC scale=0(/128) x=-3    y=-1    b=7
L50B6:  .word $F578             ;SVEC scale=2(/32)  x=0     y=-1    b=7
L50B8:  .word $3180, $0200      ;VEC  scale=3(/64)  x=512   y=384   b=0
L50BC:  .word $F875             ;SVEC scale=1(/64)  x=-1    y=0     b=7
L50BE:  .word $FD70             ;SVEC scale=1(/64)  x=0     y=-1    b=7
L50C0:  .word $F871             ;SVEC scale=1(/64)  x=1     y=0     b=7
L50C2:  .word $FD02             ;SVEC scale=1(/64)  x=2     y=-1    b=0
L50C4:  .word $CB2E             ;JSR  $565C
L50C6:  .word $CB63             ;JSR  $56C6
L50C8:  .word $CB56             ;JSR  $56AC
L50CA:  .word $CB63             ;JSR  $56C6
L50CC:  .word $CB2C             ;JSR  $5658
L50CE:  .word $CA78             ;JSR  $54F0
L50D0:  .word $CB02             ;JSR  $5604
L50D2:  .word $CA78             ;JSR  $54F0
L50D4:  .word $CAF3             ;JSR  $55E6
L50D6:  .word $CABA             ;JSR  $5574
L50D8:  .word $CB2C             ;JSR  $5658
L50DA:  .word $CABA             ;JSR  $5574
L50DC:  .word $CAD8             ;JSR  $55B0
L50DE:  .word $EA8D             ;JMP  $551A

;----------------------------------[ Ship Explosion Vector Data ]----------------------------------

;Ship Explosion.
ShipExpPtrTbl:
L50E0:  .word $FFC6             ;SVEC scale=1(/64)  x=-2    y=-3    b=12
L50E2:  .word $FEC1             ;SVEC scale=1(/64)  x=1     y=-2    b=12
L50E4:  .word $F1C3             ;SVEC scale=0(/128) x=3     y=1     b=12
L50E6:  .word $F1CD             ;SVEC scale=2(/32)  x=-1    y=1     b=12
L50E8:  .word $F1C7             ;SVEC scale=0(/128) x=-3    y=1     b=12
L50EA:  .word $FDC1             ;SVEC scale=1(/64)  x=1     y=-1    b=12

;Ship explosion pieces velocity (x, y).
ShipExpVelTbl:
L50EC:  .byte $D8, $1E          ;(-40,  30)
L50EE:  .byte $32, $EC          ;( 50, -20)
L50F0:  .byte $00, $C4          ;(  0, -60)
L50F2:  .byte $3C, $14          ;( 60,  20)
L50F4:  .byte $0A, $46          ;( 10,  70)
L50F6:  .byte $D8, $D8          ;(-40, -40)

;--------------------------------[ Shrapnel Patterns Vector Data ]---------------------------------

;Shrapnel Patterns. This is used when the player's shot hits something. Notice that all four 
;patterns are the same just slightly spread out. This is extremely clever. You could use one
;pattern and vary the scale to make it look like it is spreading out. But the scale jumps are
;powers-of-two. These slightly-scaled patterns can be used to take up the gaps in the large
;scaling doubles! 

;Jump table for 4.
ShrapPatPtrTbl:
L50F8:  .word $C8D0             ;JSR  $51A0
L50FA:  .word $C8B5             ;JSR  $516A
L50FC:  .word $C896             ;JSR  $512C
L50FE:  .word $C880             ;JSR  $5100

;Shrapnel pattern 1.
L5100:  .word $F80D             ;SVEC scale=3(/16)  x=-1    y=0     b=0
L5102:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5104:  .word $FD0D             ;SVEC scale=3(/16)  x=-1    y=-1    b=0
L5106:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5108:  .word $FD09             ;SVEC scale=3(/16)  x=1     y=-1    b=0
L510A:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L510C:  .word $F10B             ;SVEC scale=2(/32)  x=3     y=1     b=0
L510E:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5110:  .word $F50A             ;SVEC scale=2(/32)  x=2     y=-1    b=0
L5112:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5114:  .word $F908             ;SVEC scale=3(/16)  x=0     y=1     b=0
L5116:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5118:  .word $F309             ;SVEC scale=2(/32)  x=1     y=3     b=0
L511A:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L511C:  .word $F30D             ;SVEC scale=2(/32)  x=-1    y=3     b=0
L511E:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5120:  .word $5480, $0600      ;VEC  scale=5(/16)  x=-512  y=-128  b=0
L5124:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5126:  .word $F10F             ;SVEC scale=2(/32)  x=-3    y=1     b=0
L5128:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L512A:  .word $D000             ;RTS 

;Shrapnel pattern 2.
L512C:  .word $3000, $0780      ;VEC  scale=3(/64)  x=-896  y=0     b=0
L5130:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5132:  .word $3780, $0780      ;VEC  scale=3(/64)  x=-896  y=-896  b=0
L5136:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5138:  .word $3780, $0380      ;VEC  scale=3(/64)  x=896   y=-896  b=0
L513C:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L513E:  .word $40E0, $02A0      ;VEC  scale=4(/32)  x=672   y=224   b=0
L5142:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5144:  .word $35C0, $0380      ;VEC  scale=3(/64)  x=896   y=-448  b=0
L5148:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L514A:  .word $3380, $0000      ;VEC  scale=3(/64)  x=0     y=896   b=0
L514E:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5150:  .word $42A0, $00E0      ;VEC  scale=4(/32)  x=224   y=672   b=0
L5154:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5156:  .word $42A0, $04E0      ;VEC  scale=4(/32)  x=-224  y=672   b=0
L515A:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L515C:  .word $44E0, $0780      ;VEC  scale=4(/32)  x=-896  y=-224  b=0
L5160:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5162:  .word $40E0, $06A0      ;VEC  scale=4(/32)  x=-672  y=224   b=0
L5166:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5168:  .word $D000             ;RTS 

;Shrapnel pattern 3.
L516A:  .word $F807             ;SVEC scale=1(/64)  x=-3    y=0     b=0
L516C:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L516E:  .word $FF07             ;SVEC scale=1(/64)  x=-3    y=-3    b=0
L5170:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5172:  .word $FF03             ;SVEC scale=1(/64)  x=3     y=-3    b=0
L5174:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5176:  .word $40C0, $0240      ;VEC  scale=4(/32)  x=576   y=192   b=0
L517A:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L517C:  .word $3580, $0300      ;VEC  scale=3(/64)  x=768   y=-384  b=0
L5180:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5182:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L5184:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5186:  .word $4240, $00C0      ;VEC  scale=4(/32)  x=192   y=576   b=0
L518A:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L518C:  .word $4240, $04C0      ;VEC  scale=4(/32)  x=-192  y=576   b=0
L5190:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5192:  .word $44C0, $0700      ;VEC  scale=4(/32)  x=-768  y=-192  b=0
L5196:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L5198:  .word $40C0, $0640      ;VEC  scale=4(/32)  x=-576  y=192   b=0
L519C:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L519E:  .word $D000             ;RTS

;Shrapnel pattern 4.
L51A0:  .word $3000, $0680      ;VEC  scale=3(/64)  x=-640  y=0     b=0
L51A4:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51A6:  .word $3680, $0680      ;VEC  scale=3(/64)  x=-640  y=-640  b=0
L51AA:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51AC:  .word $3680, $0280      ;VEC  scale=3(/64)  x=640   y=-640  b=0
L51B0:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51B2:  .word $3140, $03C0      ;VEC  scale=3(/64)  x=960   y=320   b=0
L51B6:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51B8:  .word $3540, $0280      ;VEC  scale=3(/64)  x=640   y=-320  b=0
L51BC:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51BE:  .word $3280, $0000      ;VEC  scale=3(/64)  x=0     y=640   b=0
L51C2:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51C4:  .word $33C0, $0140      ;VEC  scale=3(/64)  x=320   y=960   b=0
L51C8:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51CA:  .word $33C0, $0540      ;VEC  scale=3(/64)  x=-320  y=960   b=0
L51CE:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51D0:  .word $44A0, $0680      ;VEC  scale=4(/32)  x=-640  y=-160  b=0
L51D4:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51D6:  .word $3140, $07C0      ;VEC  scale=3(/64)  x=-960  y=320   b=0
L51DA:  .word $F878             ;SVEC scale=3(/16)  x=0     y=0     b=7
L51DC:  .word $D000             ;RTS

;--------------------------------[ Asteroids Pattern Vector Data ]---------------------------------

;Asteroid Patterns.
;Jump table for the 4 asteroid patterns.
AstPtrnPtrTbl:
L51DE:  .word $C8F3             ;JSR  $51E6
L51E0:  .word $C8FF             ;JSR  $51FE
L51E2:  .word $C90D             ;JSR  $521A
L51E4:  .word $C91A             ;JSR  $5234 

;Asteroid Pattern 1.
L51E6:  .word $F908             ;SVEC scale=3(/16)  x=0     y=1     b=0
L51E8:  .word $F979             ;SVEC scale=3(/16)  x=1     y=1     b=7
L51EA:  .word $FD79             ;SVEC scale=3(/16)  x=1     y=-1    b=7
L51EC:  .word $F67D             ;SVEC scale=2(/32)  x=-1    y=-2    b=7
L51EE:  .word $F679             ;SVEC scale=2(/32)  x=1     y=-2    b=7
L51F0:  .word $F68F             ;SVEC scale=2(/32)  x=-3    y=-2    b=8
L51F2:  .word $F08F             ;SVEC scale=2(/32)  x=-3    y=0     b=8
L51F4:  .word $F97D             ;SVEC scale=3(/16)  x=-1    y=1     b=7
L51F6:  .word $FA78             ;SVEC scale=3(/16)  x=0     y=2     b=7
L51F8:  .word $F979             ;SVEC scale=3(/16)  x=1     y=1     b=7
L51FA:  .word $FD79             ;SVEC scale=3(/16)  x=1     y=-1    b=7
L51FC:  .word $D000             ;RTS

;Asteroid Pattern 2.
L51FE:  .word $F10A             ;SVEC scale=2(/32)  x=2     y=1     b=0
L5200:  .word $F17A             ;SVEC scale=2(/32)  x=2     y=1     b=7
L5202:  .word $F97D             ;SVEC scale=3(/16)  x=-1    y=1     b=7
L5204:  .word $F57E             ;SVEC scale=2(/32)  x=-2    y=-1    b=7
L5206:  .word $F17E             ;SVEC scale=2(/32)  x=-2    y=1     b=7
L5208:  .word $FD7D             ;SVEC scale=3(/16)  x=-1    y=-1    b=7
L520A:  .word $F679             ;SVEC scale=2(/32)  x=1     y=-2    b=7
L520C:  .word $F67D             ;SVEC scale=2(/32)  x=-1    y=-2    b=7
L520E:  .word $FD79             ;SVEC scale=3(/16)  x=1     y=-1    b=7
L5210:  .word $F179             ;SVEC scale=2(/32)  x=1     y=1     b=7
L5212:  .word $F58B             ;SVEC scale=2(/32)  x=3     y=-1    b=8
L5214:  .word $F38A             ;SVEC scale=2(/32)  x=2     y=3     b=8
L5216:  .word $F97D             ;SVEC scale=3(/16)  x=-1    y=1     b=7
L5218:  .word $D000             ;RTS

;Asteroid Pattern 3.
L521A:  .word $F80D             ;SVEC scale=3(/16)  x=-1    y=0     b=0
L521C:  .word $F57E             ;SVEC scale=2(/32)  x=-2    y=-1    b=7
L521E:  .word $F77A             ;SVEC scale=2(/32)  x=2     y=-3    b=7
L5220:  .word $F37A             ;SVEC scale=2(/32)  x=2     y=3     b=7
L5222:  .word $F778             ;SVEC scale=2(/32)  x=0     y=-3    b=7
L5224:  .word $F879             ;SVEC scale=3(/16)  x=1     y=0     b=7
L5226:  .word $F37A             ;SVEC scale=2(/32)  x=2     y=3     b=7
L5228:  .word $F978             ;SVEC scale=3(/16)  x=0     y=1     b=7
L522A:  .word $F37E             ;SVEC scale=2(/32)  x=-2    y=3     b=7
L522C:  .word $F07F             ;SVEC scale=2(/32)  x=-3    y=0     b=7
L522E:  .word $F77F             ;SVEC scale=2(/32)  x=-3    y=-3    b=7
L5230:  .word $F57A             ;SVEC scale=2(/32)  x=2     y=-1    b=7
L5232:  .word $D000             ;RTS

;Asteroid Pattern 4.
L5234:  .word $F009             ;SVEC scale=2(/32)  x=1     y=0     b=0
L5236:  .word $F17B             ;SVEC scale=2(/32)  x=3     y=1     b=7
L5238:  .word $F168             ;SVEC scale=2(/32)  x=0     y=1     b=6
L523A:  .word $F27F             ;SVEC scale=2(/32)  x=-3    y=2     b=7
L523C:  .word $F07F             ;SVEC scale=2(/32)  x=-3    y=0     b=7
L523E:  .word $F669             ;SVEC scale=2(/32)  x=1     y=-2    b=6
L5240:  .word $F07F             ;SVEC scale=2(/32)  x=-3    y=0     b=7
L5242:  .word $F778             ;SVEC scale=2(/32)  x=0     y=-3    b=7
L5244:  .word $F77A             ;SVEC scale=2(/32)  x=2     y=-3    b=7
L5246:  .word $F17B             ;SVEC scale=2(/32)  x=3     y=1     b=7
L5248:  .word $F569             ;SVEC scale=2(/32)  x=1     y=-1    b=6
L524A:  .word $F969             ;SVEC scale=3(/16)  x=1     y=1     b=6
L524C:  .word $F27F             ;SVEC scale=2(/32)  x=-3    y=2     b=7
L524E:  .word $D000             ;RTS

;----------------------------------[ Saucer Pattern Vector Data ]----------------------------------

;Jump table for Saucer.
ScrPtrnPtrTbl:
L5250:  .word $C929             ;JSR  $5252

L5252:  .word $F10E             ;SVEC scale=2(/32)  x=-2    y=1     b=0
L5254:  .word $F8CA             ;SVEC scale=3(/16)  x=2     y=0     b=12
L5256:  .word $F60B             ;SVEC scale=2(/32)  x=3     y=-2    b=0
L5258:  .word $6000, $D680      ;VEC  scale=6(/8)   x=-640  y=0     b=13
L525C:  .word $F6DB             ;SVEC scale=2(/32)  x=3     y=-2    b=13
L525E:  .word $F8CA             ;SVEC scale=3(/16)  x=2     y=0     b=12
L5260:  .word $F2DB             ;SVEC scale=2(/32)  x=3     y=2     b=13
L5262:  .word $F2DF             ;SVEC scale=2(/32)  x=-3    y=2     b=13
L5264:  .word $F2CD             ;SVEC scale=2(/32)  x=-1    y=2     b=12
L5266:  .word $F8CD             ;SVEC scale=3(/16)  x=-1    y=0     b=12
L5268:  .word $F6CD             ;SVEC scale=2(/32)  x=-1    y=-2    b=12
L526A:  .word $F6DF             ;SVEC scale=2(/32)  x=-3    y=-2    b=13
L526C:  .word $D000             ;RTS

;---------------------------------[ Ship And Thrust Vector Data ]----------------------------------

;Table for ships and thrusts based on player's direction. The addresses are where the ROM appears
;in the main CPU's memory map. The thrust pattern for each ship follows the ship itself. The
;directions below only represent 1/4 of a circle.  The X and/or Y axis are inverted based on the
;actual ship direction.

ShipDirPtrTbl:
L526E:  .word ShipDir0,  ShipDir4,  ShipDir8,  ShipDir12
L5276:  .word ShipDir16, ShipDir20, ShipDir24, ShipDir28
L527E:  .word ShipDir32, ShipDir36, ShipDir40, ShipDir44
L5286:  .word ShipDir48, ShipDir52, ShipDir56, ShipDir60
L528E:  .word ShipDir64

ShipDir0:
L5290:  .word $F60F             ;SVEC scale=2(/32)  x=-3    y=-2    b=0
L5292:  .word $FAC8             ;SVEC scale=3(/16)  x=0     y=2     b=12
L5294:  .word $F9BD             ;SVEC scale=3(/16)  x=-1    y=1     b=11
L5296:  .word $6500, $C300      ;VEC  scale=6(/8)   x=768   y=-256  b=12
L529A:  .word $6500, $C700      ;VEC  scale=6(/8)   x=-768  y=-256  b=12
L529E:  .word $F9B9             ;SVEC scale=3(/16)  x=1     y=1     b=11
L52A0:  .word $D000             ;RTS

ThrustDir0: 
L52A2:  .word $F9CE             ;SVEC scale=3(/16)  x=-2    y=1     b=12
L52A4:  .word $F9CA             ;SVEC scale=3(/16)  x=2     y=1     b=12
L52A6:  .word $D000             ;RTS
 
ShipDir4:
L52A8:  .word $4640, $06C0      ;VEC  scale=4(/32)  x=-704  y=-576  b=0
L52AC:  .word $5200, $C430      ;VEC  scale=5(/16)  x=-48   y=512   b=12
L52B0:  .word $41C0, $C620      ;VEC  scale=4(/32)  x=-544  y=448   b=12
L52B4:  .word $64B0, $C318      ;VEC  scale=6(/8)   x=792   y=-176  b=12
L52B8:  .word $6548, $C6E0      ;VEC  scale=6(/8)   x=-736  y=-328  b=12
L52BC:  .word $4220, $C1C0      ;VEC  scale=4(/32)  x=448   y=544   b=12
L52C0:  .word $D000             ;RTS

ThrustDir4:
L52C2:  .word $50D0, $C610      ;VEC  scale=5(/16)  x=-528  y=208   b=12
L52C6:  .word $4260, $C3C0      ;VEC  scale=4(/32)  x=960   y=608   b=12
L52CA:  .word $D000             ;RTS
 
ShipDir8:
L52CC:  .word $4680, $0680      ;VEC  scale=4(/32)  x=-640  y=-640  b=0
L52D0:  .word $43E0, $C4C0      ;VEC  scale=4(/32)  x=-192  y=992   b=12
L52D4:  .word $41A0, $C660      ;VEC  scale=4(/32)  x=-608  y=416   b=12
L52D8:  .word $6468, $C320      ;VEC  scale=6(/8)   x=800   y=-104  b=12
L52DC:  .word $6590, $C6C0      ;VEC  scale=6(/8)   x=-704  y=-400  b=12
L52E0:  .word $4260, $C1A0      ;VEC  scale=4(/32)  x=416   y=608   b=12
L52E4:  .word $D000             ;RTS

ThrustDir8:
L52E6:  .word $5090, $C630      ;VEC  scale=5(/16)  x=-560  y=144   b=12
L52EA:  .word $42C0, $C380      ;VEC  scale=4(/32)  x=896   y=704   b=12
L52EE:  .word $D000             ;RTS

ShipDir12:
L52F0:  .word $46C0, $0640      ;VEC  scale=4(/32)  x=-576  y=-704  b=0
L52F4:  .word $43E0, $C520      ;VEC  scale=4(/32)  x=-288  y=992   b=12
L52F8:  .word $4160, $C680      ;VEC  scale=4(/32)  x=-640  y=352   b=12
L52FC:  .word $6418, $C328      ;VEC  scale=6(/8)   x=808   y=-24   b=12
L5300:  .word $65D0, $C698      ;VEC  scale=6(/8)   x=-664  y=-464  b=12
L5304:  .word $4280, $C160      ;VEC  scale=4(/32)  x=352   y=640   b=12
L5308:  .word $D000             ;RTS

ThrustDir12:
L530A:  .word $5060, $C630      ;VEC  scale=5(/16)  x=-560  y=96    b=12
L530E:  .word $4320, $C340      ;VEC  scale=4(/32)  x=832   y=800   b=12
L5312:  .word $D000             ;RTS

ShipDir16:
L5314:  .word $F70E             ;SVEC scale=2(/32)  x=-2    y=-3    b=0
L5316:  .word $43C0, $C580      ;VEC  scale=4(/32)  x=-384  y=960   b=12
L531A:  .word $4120, $C6A0      ;VEC  scale=4(/32)  x=-672  y=288   b=12
L531E:  .word $6038, $C328      ;VEC  scale=6(/8)   x=808   y=56    b=12
L5322:  .word $6610, $C660      ;VEC  scale=6(/8)   x=-608  y=-528  b=12
L5326:  .word $42A0, $C120      ;VEC  scale=4(/32)  x=288   y=672   b=12
L532A:  .word $D000             ;RTS 

ThrustDir16:
L532C:  .word $5030, $C640      ;VEC  scale=5(/16)  x=-576  y=48    b=12
L5330:  .word $4360, $C2E0      ;VEC  scale=4(/32)  x=736   y=864   b=12
L5334:  .word $D000             ;RTS

ShipDir20:
L5336:  .word $4720, $05C0      ;VEC  scale=4(/32)  x=-448  y=-800  b=0
L533A:  .word $4380, $C5E0      ;VEC  scale=4(/32)  x=-480  y=896   b=12
L533E:  .word $40E0, $C6C0      ;VEC  scale=4(/32)  x=-704  y=224   b=12
L5342:  .word $6088, $C320      ;VEC  scale=6(/8)   x=800   y=136   b=12
L5346:  .word $6648, $C630      ;VEC  scale=6(/8)   x=-560  y=-584  b=12
L534A:  .word $42C0, $C0E0      ;VEC  scale=4(/32)  x=224   y=704   b=12
L534E:  .word $D000             ;RTS  

ThrustDir20:
L5350:  .word $5410, $C640      ;VEC  scale=5(/16)  x=-576  y=-16   b=12
L5354:  .word $43A0, $C2A0      ;VEC  scale=4(/32)  x=672   y=928   b=12
L5358:  .word $D000             ;RTS

ShipDir24:
L535A:  .word $4760, $0560      ;VEC  scale=4(/32)  x=-352  y=-864  b=0
L535E:  .word $4360, $C640      ;VEC  scale=4(/32)  x=-576  y=864   b=12
L5362:  .word $4080, $C6C0      ;VEC  scale=4(/32)  x=-704  y=128   b=12
L5366:  .word $60D8, $C310      ;VEC  scale=6(/8)   x=784   y=216   b=12
L536A:  .word $6680, $C5F0      ;VEC  scale=6(/8)   x=-496  y=-640  b=12
L536E:  .word $42C0, $C080      ;VEC  scale=4(/32)  x=128   y=704   b=12
L5372:  .word $D000             ;RTS 

ThrustDir24:
L5374:  .word $5440, $C630      ;VEC  scale=5(/16)  x=-560  y=-64   b=12
L5378:  .word $43E0, $C240      ;VEC  scale=4(/32)  x=576   y=992   b=12
L537C:  .word $D000             ;RTS

ShipDir28:
L537E:  .word $4780, $0500      ;VEC  scale=4(/32)  x=-256  y=-896  b=0
L5382:  .word $4320, $C680      ;VEC  scale=4(/32)  x=-640  y=800   b=12
L5386:  .word $4040, $C6E0      ;VEC  scale=4(/32)  x=-736  y=64    b=12
L538A:  .word $6120, $C2F8      ;VEC  scale=6(/8)   x=760   y=288   b=12
L538E:  .word $66B0, $C5B0      ;VEC  scale=6(/8)   x=-432  y=-688  b=12
L5392:  .word $42E0, $C040      ;VEC  scale=4(/32)  x=64    y=736   b=12
L5396:  .word $D000             ;RTS  

ThrustDir28:
L5398:  .word $5480, $C630      ;VEC  scale=5(/16)  x=-560  y=-128  b=12
L539C:  .word $5210, $C0F0      ;VEC  scale=5(/16)  x=240   y=528   b=12
L53A0:  .word $D000             ;RTS

ShipDir32:
L53A2:  .word $4780, $04C0      ;VEC  scale=4(/32)  x=-192  y=-896  b=0
L53A6:  .word $42E0, $C6E0      ;VEC  scale=4(/32)  x=-736  y=736   b=12
L53AA:  .word $4000, $C6E0      ;VEC  scale=4(/32)  x=-736  y=0     b=12
L53AE:  .word $6168, $C2D8      ;VEC  scale=6(/8)   x=728   y=360   b=12
L53B2:  .word $66D8, $C568      ;VEC  scale=6(/8)   x=-360  y=-728  b=12
L53B6:  .word $42E0, $C000      ;VEC  scale=4(/32)  x=0     y=736   b=12
L53BA:  .word $D000             ;RTS 

ThrustDir32:
L53BC:  .word $54B0, $C620      ;VEC  scale=5(/16)  x=-544  y=-176  b=12
L53C0:  .word $5220, $C0B0      ;VEC  scale=5(/16)  x=176   y=544   b=12
L53C4:  .word $D000             ;RTS

ShipDir36:
L53C6:  .word $47A0, $0460      ;VEC  scale=4(/32)  x=-96   y=-928  b=0
L53CA:  .word $4280, $C720      ;VEC  scale=4(/32)  x=-800  y=640   b=12
L53CE:  .word $4440, $C6E0      ;VEC  scale=4(/32)  x=-736  y=-64   b=12
L53D2:  .word $61B0, $C2B0      ;VEC  scale=6(/8)   x=688   y=432   b=12
L53D6:  .word $66F8, $C520      ;VEC  scale=6(/8)   x=-288  y=-760  b=12
L53DA:  .word $42E0, $C440      ;VEC  scale=4(/32)  x=-64   y=736   b=12
L53DE:  .word $D000             ;RTS  

ThrustDir36:
L53E0:  .word $54F0, $C610      ;VEC  scale=5(/16)  x=-528  y=-240  b=12
L53E4:  .word $5230, $C080      ;VEC  scale=5(/16)  x=128   y=560   b=12
L53E8:  .word $D000             ;RTS

ShipDir40:
L53EA:  .word $47A0, $0000      ;VEC  scale=4(/32)  x=0     y=-928  b=0
L53EE:  .word $4240, $C760      ;VEC  scale=4(/32)  x=-864  y=576   b=12
L53F2:  .word $4480, $C6C0      ;VEC  scale=4(/32)  x=-704  y=-128  b=12
L53F6:  .word $61F0, $C280      ;VEC  scale=6(/8)   x=640   y=496   b=12
L53FA:  .word $6710, $C4D8      ;VEC  scale=6(/8)   x=-216  y=-784  b=12
L53FE:  .word $42C0, $C480      ;VEC  scale=4(/32)  x=-128  y=704   b=12
L5402:  .word $D000             ;RTS 

ThrustDir40:
L5404:  .word $4640, $C7E0      ;VEC  scale=4(/32)  x=-992  y=-576  b=12
L5408:  .word $5230, $C040      ;VEC  scale=5(/16)  x=64    y=560   b=12
L540C:  .word $D000             ;RTS

ShipDir44:
L540E:  .word $47A0, $0060      ;VEC  scale=4(/32)  x=96    y=-928  b=0
L5412:  .word $41E0, $C780      ;VEC  scale=4(/32)  x=-896  y=480   b=12
L5416:  .word $44E0, $C6C0      ;VEC  scale=4(/32)  x=-704  y=-224  b=12
L541A:  .word $6230, $C248      ;VEC  scale=6(/8)   x=584   y=560   b=12
L541E:  .word $6720, $C488      ;VEC  scale=6(/8)   x=-136  y=-800  b=12
L5422:  .word $42C0, $C4E0      ;VEC  scale=4(/32)  x=-224  y=704   b=12
L5426:  .word $D000             ;RTS

ThrustDir44:
L5428:  .word $46A0, $C7A0      ;VEC  scale=4(/32)  x=-928  y=-672  b=12
L542C:  .word $5240, $C010      ;VEC  scale=5(/16)  x=16    y=576   b=12
L5430:  .word $D000             ;RTS

ShipDir48:
L5432:  .word $4780, $00C0      ;VEC  scale=4(/32)  x=192   y=-896  b=0
L5436:  .word $4180, $C7C0      ;VEC  scale=4(/32)  x=-960  y=384   b=12
L543A:  .word $4520, $C6A0      ;VEC  scale=4(/32)  x=-672  y=-288  b=12
L543E:  .word $6260, $C210      ;VEC  scale=6(/8)   x=528   y=608   b=12
L5442:  .word $6728, $C438      ;VEC  scale=6(/8)   x=-56   y=-808  b=12
L5446:  .word $42A0, $C520      ;VEC  scale=4(/32)  x=-288  y=672   b=12
L544A:  .word $D000             ;RTS 

ThrustDir48:
L544C:  .word $46E0, $C760      ;VEC  scale=4(/32)  x=-864  y=-736  b=12
L5450:  .word $5240, $C430      ;VEC  scale=5(/16)  x=-48   y=576   b=12
L5454:  .word $D000             ;RTS

ShipDir52:
L5456:  .word $4780, $0100      ;VEC  scale=4(/32)  x=256   y=-896  b=0
L545A:  .word $4120, $C7E0      ;VEC  scale=4(/32)  x=-992  y=288   b=12
L545E:  .word $4560, $C680      ;VEC  scale=4(/32)  x=-640  y=-352  b=12
L5462:  .word $6298, $C1D0      ;VEC  scale=6(/8)   x=464   y=664   b=12
L5466:  .word $6728, $C018      ;VEC  scale=6(/8)   x=24    y=-808  b=12
L546A:  .word $4280, $C560      ;VEC  scale=4(/32)  x=-352  y=640   b=12
L546E:  .word $D000             ;RTS

ThrustDir52:
L5470:  .word $4740, $C720      ;VEC  scale=4(/32)  x=-800  y=-832  b=12
L5474:  .word $5230, $C460      ;VEC  scale=5(/16)  x=-96   y=560   b=12
L5478:  .word $D000             ;RTS

ShipDir56:
L547A:  .word $4760, $0160      ;VEC  scale=4(/32)  x=352   y=-864  b=0
L547E:  .word $40C0, $C7E0      ;VEC  scale=4(/32)  x=-992  y=192   b=12
L5482:  .word $45A0, $C660      ;VEC  scale=4(/32)  x=-608  y=-416  b=12
L5486:  .word $62C0, $C190      ;VEC  scale=6(/8)   x=400   y=704   b=12
L548A:  .word $6720, $C068      ;VEC  scale=6(/8)   x=104   y=-800  b=12
L548E:  .word $4260, $C5A0      ;VEC  scale=4(/32)  x=-416  y=608   b=12
L5492:  .word $D000             ;RTS

ThrustDir56:
L5494:  .word $4780, $C6C0      ;VEC  scale=4(/32)  x=-704  y=-896  b=12
L5498:  .word $5230, $C490      ;VEC  scale=5(/16)  x=-144  y=560   b=12
L549C:  .word $D000             ;RTS

ShipDir60:
L549E:  .word $4720, $01C0      ;VEC  scale=4(/32)  x=448   y=-800  b=0
L54A2:  .word $5030, $C600      ;VEC  scale=5(/16)  x=-512  y=48    b=12
L54A6:  .word $45C0, $C620      ;VEC  scale=4(/32)  x=-544  y=-448  b=12
L54AA:  .word $62E0, $C148      ;VEC  scale=6(/8)   x=328   y=736   b=12
L54AE:  .word $6718, $C0B0      ;VEC  scale=6(/8)   x=176   y=-792  b=12
L54B2:  .word $4220, $C5C0      ;VEC  scale=4(/32)  x=-448  y=544   b=12
L54B6:  .word $D000             ;RTS  

ThrustDir60:
L54B8:  .word $47C0, $C660      ;VEC  scale=4(/32)  x=-608  y=-960  b=12
L54BC:  .word $5210, $C4D0      ;VEC  scale=5(/16)  x=-208  y=528   b=12
L54C0:  .word $D000             ;RTS

ShipDir64:
L54C2:  .word $F70A             ;SVEC scale=2(/32)  x=2     y=-3    b=0
L54C4:  .word $F8CE             ;SVEC scale=3(/16)  x=-2    y=0     b=12
L54C6:  .word $FDCD             ;SVEC scale=3(/16)  x=-1    y=-1    b=12
L54C8:  .word $6300, $C100      ;VEC  scale=6(/8)   x=256   y=768   b=12
L54CC:  .word $6700, $C100      ;VEC  scale=6(/8)   x=256   y=-768  b=12
L54D0:  .word $F9CD             ;SVEC scale=3(/16)  x=-1    y=1     b=12
L54D2:  .word $D000             ;RTS

ThrustDir64:
L54D4:  .word $FECD             ;SVEC scale=3(/16)  x=-1    y=-2    b=12
L54D6:  .word $FACD             ;SVEC scale=3(/16)  x=-1    y=2     b=12
L54D8:  .word $D000             ;RTS

;-----------------------------------[ Extra Lives Vector Data ]------------------------------------

;Ships in reserve.
ExtLivesDat:
L54DA:  .word $F70E             ;SVEC scale=2(/32)  x=-2    y=-3    b=0
L54DC:  .word $F87A             ;SVEC scale=3(/16)  x=2     y=0     b=7
L54DE:  .word $FD79             ;SVEC scale=3(/16)  x=1     y=-1    b=7
L54E0:  .word $6300, $7500      ;VEC  scale=6(/8)   x=-256  y=768   b=7
L54E4:  .word $6700, $7500      ;VEC  scale=6(/8)   x=-256  y=-768  b=7
L54E8:  .word $F979             ;SVEC scale=3(/16)  x=1     y=1     b=7
L54EA:  .word $60C0, $0280      ;VEC  scale=6(/8)   x=640   y=192   b=0
L54EE:  .word $D09F             ;RTS

;-----------------------------------[ Alphanumeric Vector Data ]-----------------------------------

;"A"
L54F0:  .word $FA70             ;SVEC scale=1(/64)  x=0     y=2     b=7
L54F2:  .word $F272             ;SVEC scale=0(/128) x=2     y=2     b=7
L54F4:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L54F6:  .word $FE70             ;SVEC scale=1(/64)  x=0     y=-2    b=7
L54F8:  .word $F906             ;SVEC scale=1(/64)  x=-2    y=1     b=0
L54FA:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L54FC:  .word $F602             ;SVEC scale=0(/128) x=2     y=-2    b=0
L54FE:  .word $D000             ;RTS

;"B"
L5500:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5502:  .word $F073             ;SVEC scale=0(/128) x=3     y=0     b=7
L5504:  .word $F571             ;SVEC scale=0(/128) x=1     y=-1    b=7
L5506:  .word $F570             ;SVEC scale=0(/128) x=0     y=-1    b=7
L5508:  .word $F575             ;SVEC scale=0(/128) x=-1    y=-1    b=7
L550A:  .word $F077             ;SVEC scale=0(/128) x=-3    y=0     b=7
L550C:  .word $F003             ;SVEC scale=0(/128) x=3     y=0     b=0
L550E:  .word $F571             ;SVEC scale=0(/128) x=1     y=-1    b=7
L5510:  .word $F570             ;SVEC scale=0(/128) x=0     y=-1    b=7
L5512:  .word $F575             ;SVEC scale=0(/128) x=-1    y=-1    b=7
L5514:  .word $F077             ;SVEC scale=0(/128) x=-3    y=0     b=7
L5516:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L5518:  .word $D000             ;RTS

;"C"
L551A:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L551C:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L551E:  .word $FF06             ;SVEC scale=1(/64)  x=-2    y=-3    b=0
L5520:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5522:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5524:  .word $D000             ;RTS
 
;"D"
L5526:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5528:  .word $F072             ;SVEC scale=0(/128) x=2     y=0     b=7
L552A:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L552C:  .word $F670             ;SVEC scale=0(/128) x=0     y=-2    b=7
L552E:  .word $F676             ;SVEC scale=0(/128) x=-2    y=-2    b=7
L5530:  .word $F076             ;SVEC scale=0(/128) x=-2    y=0     b=7
L5532:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L5534:  .word $D000             ;RTS

;"E"
L5536:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5538:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L553A:  .word $F705             ;SVEC scale=0(/128) x=-1    y=-3    b=0
L553C:  .word $F077             ;SVEC scale=0(/128) x=-3    y=0     b=7
L553E:  .word $F700             ;SVEC scale=0(/128) x=0     y=-3    b=0
L5540:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5542:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5544:  .word $D000             ;RTS

;"F"
L5546:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5548:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L554A:  .word $F705             ;SVEC scale=0(/128) x=-1    y=-3    b=0
L554C:  .word $F077             ;SVEC scale=0(/128) x=-3    y=0     b=7
L554E:  .word $F700             ;SVEC scale=0(/128) x=0     y=-3    b=0
L5550:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L5552:  .word $D000             ;RTS

;"G"
L5554:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5556:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5558:  .word $F670             ;SVEC scale=0(/128) x=0     y=-2    b=7
L555A:  .word $F606             ;SVEC scale=0(/128) x=-2    y=-2    b=0
L555C:  .word $F072             ;SVEC scale=0(/128) x=2     y=0     b=7
L555E:  .word $F670             ;SVEC scale=0(/128) x=0     y=-2    b=7
L5560:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L5562:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L5564:  .word $D000             ;RTS

;"H"
L5566:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5568:  .word $F700             ;SVEC scale=0(/128) x=0     y=-3    b=0
L556A:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L556C:  .word $F300             ;SVEC scale=0(/128) x=0     y=3     b=0
L556E:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L5570:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5572:  .word $D000             ;RTS

;"I"
L5574:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5576:  .word $F006             ;SVEC scale=0(/128) x=-2    y=0     b=0
L5578:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L557A:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L557C:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L557E:  .word $FF03             ;SVEC scale=1(/64)  x=3     y=-3    b=0
L5580:  .word $D000             ;RTS

;"J"
L5582:  .word $F200             ;SVEC scale=0(/128) x=0     y=2     b=0
L5584:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L5586:  .word $F072             ;SVEC scale=0(/128) x=2     y=0     b=7
L5588:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L558A:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L558C:  .word $D000             ;RTS

;"K"
L558E:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5590:  .word $F003             ;SVEC scale=0(/128) x=3     y=0     b=0
L5592:  .word $F777             ;SVEC scale=0(/128) x=-3    y=-3    b=7
L5594:  .word $F773             ;SVEC scale=0(/128) x=3     y=-3    b=7
L5596:  .word $F003             ;SVEC scale=0(/128) x=3     y=0     b=0
L5598:  .word $D000             ;RTS

;"L"
L559A:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L559C:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L559E:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55A0:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L55A2:  .word $D000             ;RTS

;"M"
L55A4:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55A6:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L55A8:  .word $F272             ;SVEC scale=0(/128) x=2     y=2     b=7
L55AA:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L55AC:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L55AE:  .word $D000             ;RTS

;"N"
L55B0:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55B2:  .word $FF72             ;SVEC scale=1(/64)  x=2     y=-3    b=7
L55B4:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55B6:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L55B8:  .word $D000             ;RTS

;"O"
L55BA:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55BC:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55BE:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L55C0:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L55C2:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L55C4:  .word $D000             ;RTS

;"P"
L55C6:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55C8:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55CA:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L55CC:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L55CE:  .word $F703             ;SVEC scale=0(/128) x=3     y=-3    b=0
L55D0:  .word $F003             ;SVEC scale=0(/128) x=3     y=0     b=0
L55D2:  .word $D000             ;RTS

;"Q"
L55D4:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55D6:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55D8:  .word $FE70             ;SVEC scale=1(/64)  x=0     y=-2    b=7
L55DA:  .word $F676             ;SVEC scale=0(/128) x=-2    y=-2    b=7
L55DC:  .word $F076             ;SVEC scale=0(/128) x=-2    y=0     b=7
L55DE:  .word $F202             ;SVEC scale=0(/128) x=2     y=2     b=0
L55E0:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L55E2:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L55E4:  .word $D000             ;RTS  

;"R"
L55E6:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L55E8:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55EA:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L55EC:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L55EE:  .word $F001             ;SVEC scale=0(/128) x=1     y=0     b=0
L55F0:  .word $F773             ;SVEC scale=0(/128) x=3     y=-3    b=7
L55F2:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L55F4:  .word $D000             ;RTS

;"S"
L55F6:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L55F8:  .word $F370             ;SVEC scale=0(/128) x=0     y=3     b=7
L55FA:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L55FC:  .word $F370             ;SVEC scale=0(/128) x=0     y=3     b=7
L55FE:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5600:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L5602:  .word $D000             ;RTS

;"T"
L5604:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5606:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5608:  .word $F006             ;SVEC scale=0(/128) x=-2    y=0     b=0
L560A:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L560C:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L560E:  .word $D000             ;RTS

;"U"
L5610:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L5612:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L5614:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5616:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5618:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L561A:  .word $D000             ;RTS

;"V"
L561C:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L561E:  .word $FF71             ;SVEC scale=1(/64)  x=1     y=-3    b=7
L5620:  .word $FB71             ;SVEC scale=1(/64)  x=1     y=3     b=7
L5622:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L5624:  .word $D000             ;RTS

;"W"
L5626:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L5628:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L562A:  .word $F272             ;SVEC scale=0(/128) x=2     y=2     b=7
L562C:  .word $F672             ;SVEC scale=0(/128) x=2     y=-2    b=7
L562E:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5630:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L5632:  .word $D000             ;RTS
 
;"X"
L5634:  .word $FB72             ;SVEC scale=1(/64)  x=2     y=3     b=7
L5636:  .word $F806             ;SVEC scale=1(/64)  x=-2    y=0     b=0
L5638:  .word $FF72             ;SVEC scale=1(/64)  x=2     y=-3    b=7
L563A:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L563C:  .word $D000             ;RTS

;"Y"
L563E:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5640:  .word $FA70             ;SVEC scale=1(/64)  x=0     y=2     b=7
L5642:  .word $F276             ;SVEC scale=0(/128) x=-2    y=2     b=7
L5644:  .word $F802             ;SVEC scale=1(/64)  x=2     y=0     b=0
L5646:  .word $F676             ;SVEC scale=0(/128) x=-2    y=-2    b=7
L5648:  .word $FE02             ;SVEC scale=1(/64)  x=2     y=-2    b=0
L564A:  .word $D000             ;RTS

;"Z"
L564C:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L564E:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5650:  .word $FF76             ;SVEC scale=1(/64)  x=-2    y=-3    b=7
L5652:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5654:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5656:  .word $D000             ;RTS

;SPACE
L5658:  .word $F803             ;SVEC scale=1(/64)  x=3     y=0     b=0
L565A:  .word $D000             ;RTS

;"1"
L565C:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L565E:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5660:  .word $FF02             ;SVEC scale=1(/64)  x=2     y=-3    b=0
L5662:  .word $D000             ;RTS

;"2"
L5664:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L5666:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5668:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L566A:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L566C:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L566E:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5670:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L5672:  .word $D000             ;RTS
  
;"3"
L5674:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5676:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L5678:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L567A:  .word $F700             ;SVEC scale=0(/128) x=0     y=-3    b=0
L567C:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L567E:  .word $F702             ;SVEC scale=0(/128) x=2     y=-3    b=0
L5680:  .word $D000             ;RTS
  
;"4"
L5682:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L5684:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L5686:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5688:  .word $F300             ;SVEC scale=0(/128) x=0     y=3     b=0
L568A:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L568C:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L568E:  .word $D000             ;RTS

;"5"
L5690:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L5692:  .word $F370             ;SVEC scale=0(/128) x=0     y=3     b=7
L5694:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L5696:  .word $F370             ;SVEC scale=0(/128) x=0     y=3     b=7
L5698:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L569A:  .word $FF01             ;SVEC scale=1(/64)  x=1     y=-3    b=0
L569C:  .word $D000             ;RTS

;"6"
L569E:  .word $F300             ;SVEC scale=0(/128) x=0     y=3     b=0
L56A0:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L56A2:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L56A4:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L56A6:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L56A8:  .word $FF03             ;SVEC scale=1(/64)  x=3     y=-3    b=0
L56AA:  .word $D000             ;RTS

;"7"
L56AC:  .word $FB00             ;SVEC scale=1(/64)  x=0     y=3     b=0
L56AE:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L56B0:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L56B2:  .word $F002             ;SVEC scale=0(/128) x=2     y=0     b=0
L56B4:  .word $D000             ;RTS

;"8"
L56B6:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L56B8:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L56BA:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L56BC:  .word $FF70             ;SVEC scale=1(/64)  x=0     y=-3    b=7
L56BE:  .word $F300             ;SVEC scale=0(/128) x=0     y=3     b=0
L56C0:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L56C2:  .word $F702             ;SVEC scale=0(/128) x=2     y=-3    b=0
L56C4:  .word $D000             ;RTS 

;"9"
L56C6:  .word $F802             ;SVEC scale=1(/64)  x=2     y=0     b=0
L56C8:  .word $FB70             ;SVEC scale=1(/64)  x=0     y=3     b=7
L56CA:  .word $F876             ;SVEC scale=1(/64)  x=-2    y=0     b=7
L56CC:  .word $F770             ;SVEC scale=0(/128) x=0     y=-3    b=7
L56CE:  .word $F872             ;SVEC scale=1(/64)  x=2     y=0     b=7
L56D0:  .word $F702             ;SVEC scale=0(/128) x=2     y=-3    b=0
L56D2:  .word $D000             ;RTS  

;JSR commands to access the characters above.
CharPtrTbl:
L56D4:  .word $CB2C             ;JSR  $5658. SPACE - Index 01.
L56D6:  .word $CADD             ;JSR  $55BA. 0     - Index 02.
L56D8:  .word $CB2E             ;JSR  $565C. 1     - Index 03.
L56DA:  .word $CB32             ;JSR  $5664. 2     - Index 04.
L56DC:  .word $CB3A             ;JSR  $5674. 3     - Not indexed.
L56DE:  .word $CB41             ;JSR  $5682. 4     - Not indexed.
L56E0:  .word $CB48             ;JSR  $5690. 5     - Not indexed.
L56E2:  .word $CB4F             ;JSR  $569E. 6     - Not indexed.
L56E4:  .word $CB56             ;JSR  $56AC. 7     - Not indexed.
L56E6:  .word $CB5B             ;JSR  $56B6. 8     - Not indexed.
L56E8:  .word $CB63             ;JSR  $56C6. 9     - Not indexed.
L56EA:  .word $CA78             ;JSR  $54F0. A     - Index 05.
L56EC:  .word $CA80             ;JSR  $5500. B     - Index 06.
L56EE:  .word $CA8D             ;JSR  $551A. C     - Index 07.
L56F0:  .word $CA93             ;JSR  $5526. D     - Index 08.
L56F2:  .word $CA9B             ;JSR  $5536. E     - Index 09.
L56F4:  .word $CAA3             ;JSR  $5546. F     - Index 10.
L56F6:  .word $CAAA             ;JSR  $5554. G     - Index 11.
L56F8:  .word $CAB3             ;JSR  $5566. H     - Index 12.
L56FA:  .word $CABA             ;JSR  $5574. I     - Index 13.
L56FC:  .word $CAC1             ;JSR  $5582. J     - Index 14.
L56FE:  .word $CAC7             ;JSR  $558E. K     - Index 15.
L5700:  .word $CACD             ;JSR  $559A. L     - Index 16.
L5702:  .word $CAD2             ;JSR  $55A4. M     - Index 17.
L5704:  .word $CAD8             ;JSR  $55B0. N     - Index 18.
L5706:  .word $CADD             ;JSR  $55BA. O     - Index 19.
L5708:  .word $CAE3             ;JSR  $55C6. P     - Index 20.
L570A:  .word $CAEA             ;JSR  $55D4. Q     - Index 21.
L570C:  .word $CAF3             ;JSR  $55E6. R     - Index 22.
L570E:  .word $CAFB             ;JSR  $55F6. S     - Index 23.
L5710:  .word $CB02             ;JSR  $5604. T     - Index 24.
L5712:  .word $CB08             ;JSR  $5610. U     - Index 25.
L5714:  .word $CB0E             ;JSR  $561C. V     - Index 26.
L5716:  .word $CB13             ;JSR  $5626. W     - Index 27.
L5718:  .word $CB1A             ;JSR  $5634. X     - Index 28.
L571A:  .word $CB1F             ;JSR  $563E. Y     - Index 29.
L571C:  .word $CB26             ;JSR  $564C. Z     - Index 30.

;---------------------------------[ English Message Vector Data ]----------------------------------

;Message offsets
EnglishTextTbl:
L571E: .byte $0B                ;HIGH SCORES 
L571F: .byte $13                ;PLAYER
L5720: .byte $19                ;YOUR SCORE IS ONE OF THE TEN BEST 
L5721: .byte $2F                ;PLEASE ENTER YOUR INITIALS
L5722: .byte $41                ;PUSH ROTATE TO SELECT LETTER 
L5723: .byte $55                ;PUSH HYPERSPACE WHEN LETTER IS CORRECT 
L5724: .byte $6F                ;PUSH START 
L5725: .byte $77                ;GAME OVER
L5726: .byte $7D                ;1 COIN 2 PLAYS 
L5727: .byte $87                ;1 COIN 1 PLAY 
L5728: .byte $91                ;2 COINS 1 PLAY 

;-----------------------------------------[ HIGH SCORES ]------------------------------------------

;               H     I     G        H     _     S        C     O     R        E     S    NULL
;             01100_01101_01011_0, 01100_00001_10111_0, 00111_10011_10110_0, 01001_10111_00000_0
L5729:  .byte     $63, $56,            $60, $6E,            $3C, $EC,            $4D, $C0

;--------------------------------------------[ PLAYER ]--------------------------------------------

;               P     L     A        Y     E     R        _    NULL  NULL
;             10100_10000_00101_0, 11101_01001_10110_0, 00001_00000_00000_0
L5731:  .byte     $A4, $0A,            $EA, $6C,            $08, $00 

;------------------------------[ YOUR SCORE IS ONE OF THE TEN BEST ]-------------------------------

;               Y     O     U        R     _     S        C     O     R        E     _     I      
;             11101_10011_11001_0, 10110_00001_10111_0, 00111_10011_10110_0, 01001_00001_01101_0
L5737:  .byte     $EC, $F2,            $B0, $6E,            $3C, $EC,            $48, $5A
;               S     _     O        N     E     _        O     F     _        T     H     E      
;             10111_00001_10011_0, 10010_01001_00001_0, 10011_01010_00001_0, 11000_01100_01001_0
L573F:  .byte     $B8, $66,            $92, $42,            $9A, $82,            $C3, $12
;               _     T     E        N     _     B        E     S     T      
;             00001_11000_01001_0, 10010_00001_00110_0, 01001_10111_11000_1
L5747:  .byte     $0E, $12,            $90, $4C,            $4D, $F1

;----------------------------------[ PEASE ENTER YOUR INITIALS ]-----------------------------------

;               P     L     E        A     S     E        _     E     N        T     E     R      
;             10100_10000_01001_0, 00101_10111_01001_0, 00001_01001_10010_0, 11000_01001_10110_0
L574D:  .byte     $A4, $12,            $2D, $D2,            $0A, $64,            $C2, $6C
;               _     Y     O        U     R     _        I     N     I        T     I     A      
;             00001_11101_10011_0, 11001_10110_00001_0, 01101_10010_01101_0, 11000_01101_00101_0
L5755:  .byte     $0F, $66,            $CD, $82,            $6C, $9A,            $C3, $4A
;               L     S    NULL    
;             10000_10111_00000_0
L575D:  .byte     $85, $C0

;---------------------------------[ PUSH ROTATE TO SELECT LETTER ]---------------------------------

;               P     U     S        H     _     R        O     T     A        T     E     _      
;             10100_11001_10111_0, 01100_00001_10110_0, 10011_11000_00101_0, 11000_01001_00001_0
L575F:  .byte     $A6, $6E,            $60, $6C,            $9E, $0A,            $C2, $42
;               T     O     _        S     E     L        E     C     T        _     L     E      
;             11000_10011_00001_0, 10111_01001_10000_0, 01001_00111_11000_0, 00001_10000_01001_0
L5767:  .byte     $C4, $C2,            $BA, $60,            $49, $F0,            $0C, $12
;               T     T     E        R    NULL  NULL    
;             11000_11000_01001_0, 10110_00000_00000_0
L576F:  .byte     $C6, $12,            $B0, $00

;----------------------------[ PUSH HYPERSPACE WHEN LETTER IS CORRECT ]----------------------------

;               P     U     S        H     _     H        Y     P     E        R     S     P      
;             10100_11001_10111_0, 01100_00001_01100_0, 11101_10100_01001_0, 10110_10111_10100_0
L5773:  .byte     $A6, $6E,            $60, $58,            $ED, $12,            $B5, $E8
;               A     C     E        _     W     H        E     N     _        L     E     T      
;             00101_00111_01001_0, 00001_11011_01100_0, 01001_10010_00001_0, 10000_01001_11000_0
L577B:  .byte     $29, $D2,            $0E, $D8,            $4C, $82,            $82, $70
;               T     E     R        _     I     S        _     C     O        R     R     E      
;             11000_01001_10110_0, 00001_01101_10111_0, 00001_00111_10011_0, 10110_10110_01001_0
L5783:  .byte     $C2, $6C,            $0B, $6E,            $09, $E6,            $B5, $92
;               C     T    NULL    
;             00111_11000_00000_0
L578B:  .byte     $3E, $00

;------------------------------------------[ PUSH START ]------------------------------------------

;               P     U     S        H     _     S        T     A     R        T    NULL  NULL    
;             10100_11001_10111_0, 01100_00001_10111_0, 11000_00101_10110_0, 11000_00000_00000_0
L578D:  .byte     $A6, $6E,            $60, $6E,            $C1, $6C,            $C0, $00

;------------------------------------------[ GAME OVER ]-------------------------------------------

;               G     A     M        E     _     O        V     E     R      
;             01011_00101_10001_0, 01001_00001_10011_0, 11010_01001_10110_1
L5795:  .byte     $59, $62,            $48, $66,            $D2, $6D

;----------------------------------------[ 1 COIN 2 PLAYS ]----------------------------------------

;               1     _     C        O     I     N        _     2     _        P     L     A      
;             00011_00001_00111_0, 10011_01101_10010_0, 00001_00100_00001_0, 10100_10000_00101_0
L579B:  .byte     $18, $4E,            $9B, $64,            $09, $02,            $A4, $0A
;               Y     S    NULL    
;             11101_10111_00000_0
L57A3:  .byte     $ED, $C0

;----------------------------------------[ 1 COIN 1 PLAY ]-----------------------------------------

;               1     _     C        O     I     N        _     1     _        P     L     A      
;             00011_00001_00111_0, 10011_01101_10010_0, 00001_00011_00001_0, 10100_10000_00101_0
L57A5:  .byte     $18, $4E,            $9B, $64,            $08, $C2,            $A4, $0A
;               Y    NULL  NULL    
;             11101_00000_00000_0
L57AD:  .byte     $E8, $00

;----------------------------------------[ 2 COINS 1 PLAY ]----------------------------------------

;               2     _     C        O     I     N        S     _     1        _     P     L      
;             00100_00001_00111_0, 10011_01101_10010_0, 10111_00001_00011_0, 00001_10100_10000_0
L57AF:  .byte     $20, $4E,            $9B, $64,            $B8, $46,            $0D, $20
;               A     Y    NULL    
;             00101_11101_00000_0
L57B7:  .byte     $2F, $40

;-----------------------------------------[ Thrust Data ]------------------------------------------

;Table used for calculating X and Y ship acceleration.
ThrustTbl:
L57B9: .byte $00, $03, $06, $09, $0C, $10, $13, $16, $19, $1C, $1F, $22, $25, $28, $2B, $2E
L57C9: .byte $31, $33, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58
L57D9: .byte $5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6B, $6D, $6F, $70, $71, $73, $74
L57E9: .byte $75, $76, $78, $79, $7A, $7A, $7B, $7C, $7D, $7D, $7E, $7E, $7E, $7F, $7F, $7F
L57F9: .byte $7F 

;Unused.
L57FA: .byte $00, $00, $00, $00, $00, $00
