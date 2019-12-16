;A good start of the disassembly is located at:
;http://computerarcheology.com/Arcade/Asteroids/Code.html
;Mad props to Lonnie Howell and Mark McDougall
;This code is fully assemblable using Ophis.
;Last updated 12/8/2018 by Nick Mikstas.

.org $6800

.include "asteroids_defines.asm"

;-------------------------------[ Vector ROM Forward Declarations ]--------------------------------

.alias VecBankErr               $5088
.alias VecCredits               $50A4
.alias ShrapPatPtrTbl           $50F8
.alias ShipExpPtrTbl            $50E0
.alias ShipExpVelTbl            $50EC
.alias AstPtrnPtrTbl            $51DE
.alias ScrPtrnPtrTbl            $5250
.alias ShipDirPtrTbl            $526E
.alias ExtLivesDat              $54DA
.alias CharPtrTbl               $56D4
.alias EnglishTextTbl           $571E
.alias ThrustTbl                $57B9

;----------------------------------------[ Start Of Code ]-----------------------------------------

L6800:  JMP RESET               ;($7CF3)Initialize the game after power-up.

InitGame:
L6803:  JSR SilenceSFX          ;($6EFA)Turn off all SFX.
L6806:  JSR InitGameVars        ;($6ED8)Initialize various game variables.

InitWaves:
L6809:  JSR InitWaveVars        ;($7168)Initialize variables for the current asteroid wave.

GameRunningLoop:
L680C:  LDA SelfTestSw          ;Get self test switch status.
L680F:* BMI -                   ;Is self test active? If so, spin lock until watchdog reset.

L6811:  LSR FrameCounter        ;Has a new frame started?
L6813:  BCC GameRunningLoop     ;If not, no processing to do until next frame. Branch to wait.

VectorWaitLoop1:
L6815:  LDA Halt                ;Is the vector state machine busy?
L6818:  BMI VectorWaitLoop1     ;If so, loop until it is idle.

L681A:  LDA VectorRam+1         ;Swap which half of vector RAM is read and which half is-->
L681D:  EOR #$02                ;written. This is done by alternating the jump instruction-->
L681F:  STA VectorRam+1         ;at the beginning of the RAM between $4402 and $4002.

L6822:  STA DmaGo               ;Start the vector state machine.
L6825:  STA WdClear             ;Clear the watchdog timer.

L6828:  INC FrameTimerLo        ;
L682A:  BNE SetVecRamPtr        ;Increment frame counter.
L682C:  INC FrameTimerHi        ;

SetVecRamPtr:
L682E:  LDX #$40                ;Is vector RAM pointer currently pointing at $4400 range?
L6830:  AND #$02                ;
L6832:  BNE UpdateVecRamPtr     ;If so, branch to switch to $4000.

L6834:  LDX #$44                ;Prepare to switch to $4400.

UpdateVecRamPtr:
L6836:  LDA #$02                ;
L6838:  STA VecRamPtrLB         ;Swap vector RAM pointer.
L683A:  STX VecRamPtrUB         ;

L683C:  JSR ChkPreGameStuff     ;($6885)Check if non game play functions need to be run.
L683F:  BCS InitGame            ;Branch if attract mode is starting.

L6841:  JSR CheckHighScore      ;($765C)Check if player just got the high score.
L6844:  JSR ChkHighScrMsg       ;($6D90)Do high score and initial entry message if appropriate.
L6847:  BPL DoScreenText        ;Is game not in progress? If not, branch.

L6849:  JSR ChkHghScrList       ;($73C4)Check if high score list needs to be displayed.
L684C:  BCS DoScreenText        ;Is high scores list being displayed? If so, branch.

L684E:  LDA PlyrDispTimer       ;Is player not active?
L6850:  BNE DoAsteroids         ;If not, branch.

L6852:  JSR UpdateShip          ;($6CD7)Update ship firing and position.
L6855:  JSR EnterHyprspc        ;($6E74)Check if player entered hyperspace.
L6858:  JSR ChkExitHprspc       ;($703F)Check if coming out of hyperspace.
L685B:  JSR UpdateScr           ;($6B93)Update saucer status.

DoAsteroids:
L685E:  JSR UpdateObjects       ;($6F57)Update objects(asteroids, ship, saucer and bullets).
L6861:  JSR HitDectection       ;($69F0)Do hit detection calculations for all objects.

DoScreenText:
L6864:  JSR UpdateScreenText    ;($724F)Update in-game screen text and reserve lives.
L6867:  JSR ChkUpdateSFX        ;($7555)Check if SFX needs to be updated.

L686A:  LDA #$7F                ;X beam coordinate 4 * $7F = $1D0 = 464.
L686C:  TAX                     ;Y beam coordinate 4 * $7F = $1D0 = 464.
L686D:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L6870:  JSR GetRandNum          ;($77B5)Get a random number.

L6873:  JSR VecHalt             ;($7BC0)Halt the vector state machine.

L6876:  LDA ThmpSpeedTmr        ;
L6879:  BEQ ChkGameRunning      ;Is thump speed timer running? If so, decrement it.
L687B:  DEC ThmpSpeedTmr        ;

ChkGameRunning:
L687E:  ORA CurAsteroids        ;Is the game running?
L6881:  BNE GameRunningLoop     ;If so, branch to keep it going.

L6883:  BEQ InitWaves           ;Game not running, branch to initialize variables.

;---------------------------------------[ Helper Routines ]----------------------------------------

ChkPreGameStuff:
L6885:  LDA NumPlayers          ;Are there players currently playing?
L6887:  BEQ ChkCoinsPerCredit   ;If not, branch.

L6889:  LDA PlyrDispTimer       ;Is the Player 1/Player 2 message being displayed?
L688B:  BNE DecPlyrTimer        ;If so, branch to decrement timer.
L688D:  JMP ChkThmpFaster       ;($6960)Jump to check if the Thump SFX should be sped up.

DecPlyrTimer:
L6890:  DEC PlyrDispTimer       ;Decrement player text display timer.
L6892:  JSR DrawPlyrNum         ;($69E2)Draw player number on the display.

NoResetReturn1:
L6895:  CLC                     ;Return without reinitializing the game.
L6896:  RTS                     ;

DoFreePlay:
L6897:  LDA #$02                ;Load 2 credits always for free play.
L6899:  STA NumCredits          ;
L689B:  BNE CheckCredits        ;Branch always.

ChkCoinsPerCredit:
L689D:  LDA DipSwitchBits       ;Get the number of coins per credit.
L689F:  AND #$03                ;Is free play active?
L68A1:  BEQ DoFreePlay          ;If so, branch to add 2 credits.

CheckInputInitials:
L68A3:  CLC                     ;
L68A4:  ADC #OneTwoText-1       ;Prepare to display the coins per play message on the display.
L68A6:  TAY                     ;

L68A7:  LDA Plyr1Rank           ;Is this the high score entry part?
L68A9:  AND Plyr2Rank           ;If so, branch.
L68AB:  BPL CheckCredits        ;

L68AD:  JSR WriteText           ;($77F6)Write coins per play text to the display.

CheckCredits:
L68B0:  LDY NumCredits          ;Are credits available?
L68B2:  BEQ NoResetReturn1      ;If not, return.

L68B4:  LDX #$01                ;Has the Player 1 button been pressed?
L68B6:  LDA Player1Sw           ;
L68B9:  BMI Do1Player           ;If so, branch to start 1 player game.

L68BB:  CPY #$02                ;Are there at least 2 credits available?
L68BD:  BCC ChkStartText        ;If not, branch to skip 2 players check.

Chk2Players:
L68BF:  LDA Player2Sw           ;Is the Player 2 button being pressed?
L68C2:  BPL ChkStartText        ;If not, branch.

L68C4:  LDA MultiPurpBits       ;
L68C6:  ORA #RamSwap            ;
L68C8:  STA MultiPurpBits       ;Switch to Player 2 RAM.
L68CA:  STA MultiPurp           ;

L68CD:  JSR InitGameVars        ;($6ED8)Initialize various game variables.
L68D0:  JSR InitWaveVars        ;($7168)Initialize variables for the current asteroid wave.
L68D3:  JSR CenterShip          ;($71E8)Center ship on display and zero velocity.

L68D6:  LDA ShipsPerGame        ;Initialize the Player's lives.
L68D8:  STA Plyr2Ships          ;

L68DA:  LDX #$02                ;Indicate this is a 2 player game.
L68DC:  DEC NumCredits          ;Decrement credits for Player 2.

Do1Player:
L68DE:  STX NumPlayers          ;Store number of players this game(1 or 2).
L68E0:  DEC NumCredits          ;Decrement credits for player 1.

L68E2:  LDA MultiPurpBits       ;Clear Player 1 and 2 LEDs and RAM swap bit.
L68E4:  AND #$F8                ;
L68E6:  EOR NumPlayers          ;Turn on LEDs indicating 1 or 2 player game.
L68E8:  STA MultiPurpBits       ;
L68EA:  STA MultiPurp           ;

L68ED:  JSR CenterShip          ;($71E8)Center ship on display and zero velocity.

L68F0:  LDA #$01                ;
L68F2:  STA ShipSpawnTmr        ;Initialize ship spawn timer for both players.
L68F5:  STA ShipSpawnTmr+$100   ;

L68F8:  LDA #$92                ;
L68FA:  STA ScrTmrReload        ;
L68FD:  STA ScrTmrReload+$100   ;Initialize saucer timer and reload value.
L6900:  STA ScrTimer+$100       ;
L6903:  STA ScrTimer            ;

L6906:  LDA #$7F                ;
L6908:  STA ThmpSpeedTmr        ;Initialize thump speed timer for both players.
L690B:  STA ThmpSpeedTmr+$100   ;

L690E:  LDA #$05                ;
L6910:  STA ScrSpeedup          ;Load initial asteroid count that causes more frequent saucers.
L6913:  STA ScrSpeedup+$100     ;

L6916:  LDA #$FF                ;
L6918:  STA Plyr1Rank           ;Zero out both Player's rank.
L691A:  STA Plyr2Rank           ;

L691C:  LDA #$80                ;Load time for displaying Player 1/2.
L691E:  STA PlyrDispTimer       ;

L6920:  ASL                     ;
L6921:  STA CurrentPlyr         ;Set current player to 1 and the score index for Player 1.
L6923:  STA ScoreIndex          ;

L6925:  LDA ShipsPerGame        ;Set Player 1 reserve lives.
L6927:  STA Plyr1Ships          ;

L6929:  LDA #$04                ;
L692B:  STA ThisVolFreq         ;
L692D:  STA ThumpOffTime        ;Set initial thump SFX values.
L692F:  LDA #$30                ;
L6931:  STA ThmpOffReload       ;
L6934:  STA ThmpOffReload+$100  ;

L6937:  STA NoiseReset          ;Reset the noise SFX hardware.
L693A:  RTS                     ;

ChkStartText:
L693B:  LDA Plyr1Rank           ;Is this the high score entry part?
L693D:  AND Plyr1Rank           ;
L693F:  BPL CheckUpdateLeds     ;If so, branch to move on.

DoStartText:
L6941:  LDA FrameTimerLo        ;Is it time to display "PUSH START" on the display?
L6943:  AND #$20                ;
L6945:  BNE CheckUpdateLeds     ;If not, branch.

L6947:  LDY #PshStrtText        ;Display "PUSH START".
L6949:  JSR WriteText           ;($77F6)Write text to the display.

CheckUpdateLeds:
L694C:  LDA FrameTimerLo        ;Update LEDs every 16 frames.
L694E:  AND #$0F                ;Is this the 16th frame?
L6950:  BNE NoResetReturn2      ;If not, branch to return from function.

SetStartLeds:
L6952:  LDA #$01                ;
L6954:  CMP NumCredits          ;
L6956:  ADC #$01                ;Turn on Player 1/Player 2 button LEDs.
L6958:  EOR #$01                ;
L695A:  EOR MultiPurpBits       ;
L695C:  STA MultiPurpBits       ;

NoResetReturn2:
L695E:  CLC                     ;Return without reinitializing the game.
L695F:  RTS                     ;

ChkThmpFaster:
L6960:  LDA FrameTimerLo        ;Is it time to speed up the thump SFX?
L6962:  AND #$3F                ;
L6964:  BNE ChkMoreShips        ;If not, branch.

L6966:  LDA ThmpOffReload       ;Is the thump SFX at max speed?
L6969:  CMP #$08                ;
L696B:  BEQ ChkMoreShips        ;If so, branch.

L696D:  DEC ThmpOffReload       ;Speed up thump SFX by decreasing off time.

ChkMoreShips:
L6970:  LDX CurrentPlyr         ;Does the player have any ship remaining?
L6972:  LDA Plyr1Ships,X        ;
L6974:  BNE ChkShipStatus       ;If so, branch.

L6976:  LDA ShpShotTimer        ;Are there any ship bullets on the display?
L6979:  ORA ShpShotTimer+1      ;
L697C:  ORA ShpShotTimer+2      ;
L697F:  ORA ShpShotTimer+3      ;
L6982:  BNE ChkShipStatus       ;If so, branch.

WriteGameOver:
L6984:  LDY #GmOvrText          ;Write "GAME OVER" to the display.
L6986:  JSR WriteText           ;($77F6)Write text to the display.

L6989:  LDA NumPlayers          ;Is this a 2 player game?
L698B:  CMP #$02                ;
L698D:  BCC ChkShipStatus       ;If not, branch.

L698F:  JSR DrawPlyrNum         ;($69E2)Draw player number on the display.

ChkShipStatus:
L6992:  LDA ShipStatus          ;Does a ship still exist on the display?
L6995:  BNE NoResetReturn3      ;If so, branch to exit.

L6997:  LDA ShipSpawnTmr        ;Is ship about to re-spawn?
L699A:  CMP #$80                ;
L699C:  BNE NoResetReturn3      ;If so, branch to exit.

L699E:  LDA #$10                ;Start ship re-spawn timer.
L69A0:  STA ShipSpawnTmr        ;

L69A3:  LDX NumPlayers          ;Get number of players.

L69A5:  LDA Plyr1Ships          ;Are there any ships in Player 1 or 2 reserves?
L69A7:  ORA Plyr2Ships          ;
L69A9:  BEQ NoCurntGame         ;If not, branch. A game is not currently being played.

L69AB:  JSR SaucerReset         ;($702D)Reset saucer variables.

L69AE:  DEX                     ;Is this a 1 player game?
L69AF:  BEQ NoResetReturn3      ;If so, branch to exit.

L69B1:  LDA #$80                ;Load player display timer for Player 2.
L69B3:  STA PlyrDispTimer       ;

L69B5:  LDA CurrentPlyr         ;Change to next player.
L69B7:  EOR #$01                ;

L69B9:  TAX                     ;Does the new player have any lives remaining?
L69BA:  LDA Plyr1Ships,X        ;
L69BC:  BEQ NoResetReturn3      ;If not, branch to exit.

L69BE:  STX CurrentPlyr         ;
L69C0:  LDA #RamSwap            ;
L69C2:  EOR MultiPurpBits       ;RAM swap to new player RAM.
L69C4:  STA MultiPurpBits       ;
L69C6:  STA MultiPurp           ;

L69C9:  TXA                     ;
L69CA:  ASL                     ;Get index to new player score.
L69CB:  STA ScoreIndex          ;

NoResetReturn3:
L69CD:  CLC                     ;Return without reinitializing the game.
L69CE:  RTS                     ;

NoCurntGame:
L69CF:  STX PrevGamePlyrs       ;Keep track of any previous players.
L69D1:  LDA #$FF                ;Set no current players.
L69D3:  STA NumPlayers          ;
L69D5:  JSR SilenceSFX          ;($6EFA)Turn off all SFX.
L69D8:  LDA MultiPurpBits       ;
L69DA:  AND #$F8                ;Turn on both player button LEDs.
L69DC:  ORA #PlyrLamps          ;
L69DE:  STA MultiPurpBits       ;

NoResetReturn4:
L69E0:  CLC                     ;Return without reinitializing the game.
L69E1:  RTS                     ;

DrawPlyrNum:
L69E2:  LDY #PlyrText           ;Prepare to write "PLAYER" on the display.
L69E4:  JSR WriteText           ;($77F6)Write text to the display.

L69E7:  LDY CurrentPlyr         ;Get the current player number.
L69E9:  INY                     ;Set it to the proper index for drawing.
L69EA:  TYA                     ;
L69EB:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.
L69EE:  RTS                     ;

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L69EF:  .byte $62               ;Checksum byte.

;----------------------------------------[ Hit Detection ]-----------------------------------------

;Need to check hit detection between all the on-screen objects.  Object 1 is either a bullet (from
;either the ship or saucer), the player's ship of the saucer.  Object 2 is either an asteroid, the
;player's ship or the saucer.  Object 1 is the outer loop of the check and each object 1 is checked
;against all of the object 2s.  The hit box value extends in both the positive and negative
;directions in both the X and Y directions.

HitDectection:
L69F0:  LDX #$07                ;Prepare to check hit detection on bullets, ship and saucer.

HitDetObj1Loop:
L69F2:  LDA ShipStatus,X        ;Is the current object 1 slot active?
L69F5:  BEQ HitDetNextObj1      ;If not, branch to increment to the next object 1.

L69F7:  BPL HitDetObj2          ;If MSB clear, this object needs hit detection, branch if so.

HitDetNextObj1:
L69F9:  DEX                     ;Move to next object to check.
L69FA:  BPL HitDetObj1Loop      ;More object to check? if so, branch to do another.

L69FC:  RTS                     ;Done checking hit detection, exit.

HitDetObj2:
L69FD:  LDY #$1C                ;Prepare to check hits against asteroids, ship and saucer.

L69FF:  CPX #$04                ;Are we checking hit detection against a ship bullet?
L6A01:  BCS HitDetObj2Loop      ;If so, branch to check hit detection.

L6A03:  DEY                     ;Skip checking object 2 as a saucer, will be checked as object 1.
L6A04:  TXA                     ;Is object 1 not the player's ship?
L6A05:  BNE HitDetObj2Loop      ;If not, branch to do hit detection.

HitDetNextObj2:
L6A07:  DEY                     ;Have we checked all the object 2s?
L6A08:  BMI HitDetNextObj1      ;If so, branch to increment to the next object 1.

HitDetObj2Loop:
L6A0A:  LDA AstStatus,Y         ;Is the current object 2 slot active?
L6A0D:  BEQ HitDetNextObj2      ;If not, branch to increment to the next object 2.

L6A0F:  BMI HitDetNextObj2      ;If MSB clear, this object needs hit detection, branch if not.

L6A11:  STA Obj2Status          ;Store a copy of object 2's current status.

L6A13:  LDA AstXPosLo,Y         ;
L6A16:  SEC                     ;Subtract objects 1 and 2 lower byte of--> 
L6A17:  SBC ShipXPosLo,X        ;their X positions and save the result.
L6A1A:  STA ObjXDiff            ;

L6A1C:  LDA AstXPosHi,Y         ;Subtract objects 1 and 2 upper byte of their X positions.
L6A1F:  SBC shipXPosHi,X        ;
L6A22:  LSR                     ;Keep bit 8 in the difference. XDiff holds bits 8 to 1.
L6A23:  ROR ObjXDiff            ;
L6A25:  ASL                     ;Is the MSB of the positions the same?
L6A26:  BEQ ClacObjYDiff        ;If so, possible hit. Branch to calculate the Y difference.

L6A28:  BPL HitDetNextObj2_     ;Distance too great. No chance of a hit. Move to next object.

L6A2A:  EOR #$FE                ;Negative value calculated. Get ABS.
L6A2C:  BNE HitDetNextObj2_     ;Is MSB the same? IF not, distance too great. Move to next object.

L6A2E:  LDA ObjXDiff            ;Need to convert XDiff to ABS since its negative.
L6A30:  EOR #$FF                ;Perform 1s compliment.  It is now its ABS value-1.
L6A32:  STA ObjXDiff            ;

ClacObjYDiff:
L6A34:  LDA AstYPosLo,Y         ;
L6A37:  SEC                     ;Subtract objects 1 and 2 lower byte of--> 
L6A38:  SBC ShipYPosLo,X        ;their X positions and save the result.
L6A3B:  STA ObjYDiff            ;

L6A3D:  LDA AstYPosHi,Y         ;Subtract objects 1 and 2 upper byte of their Y positions.
L6A40:  SBC ShipYPosHi,X        ;
L6A43:  LSR                     ;Keep bit 8 in the difference. YDiff holds bits 8 to 1.
L6A44:  ROR ObjYDiff            ;
L6A46:  ASL                     ;Is the MSB of the positions the same?
L6A47:  BEQ HitDetPart2         ;If so, possible hit. Branch to calculate further.

L6A49:  BPL HitDetNextObj2_     ;Distance too great. No chance of a hit. Move to next object.

L6A4B:  EOR #$FE                ;Negative value calculated. Get ABS.
L6A4D:  BNE HitDetNextObj2_     ;Is MSB the same? IF not, distance too great. Move to next object.

L6A4F:  LDA ObjYDiff            ;Need to convert YDiff to ABS since its negative.
L6A51:  EOR #$FF                ;Perform 1s compliment.  It is now its ABS value-1.
L6A53:  STA ObjYDiff            ;

HitDetPart2:
L6A55:  LDA #$2A                ;Small asteroid hit box 42 X 42 from center.
L6A57:  LSR Obj2Status          ;Is this a small asteroid, ship or saucer?
L6A59:  BCS HitDetShip          ;If so, branch.

L6A5B:  LDA #$48                ;Medium asteroid hit box 72 X 72 from center.
L6A5D:  LSR Obj2Status          ;Is this a medium asteroid or a saucer?
L6A5F:  BCS HitDetShip          ;If so, branch.

L6A61:  LDA #$84                ;Large asteroid hit box 132 X 132 from center.

HitDetShip:
L6A63:  CPX #$01                ;Is object 1 not the player's ship?
L6A65:  BCS HitDetSaucer        ;If not, branch.

L6A67:  ADC #$1C                ;Ship hit box 42+28 = 70 X 70 from center.

HitDetSaucer:
L6A69:  BNE CheckObjHit         ;Is object a saucer? If not, branch.

L6A6B:  ADC #$12                ;Small saucer hit box 42+18 = 60 X 60 from center.
L6A6D:  LDX ScrStatus           ;

L6A70:  DEX                     ;Is the object a small saucer?
L6A71:  BEQ HitDetFinishScr     ;If so, branch.

L6A73:  ADC #$12                ;Large saucer hit box 42+18+18 = 78 X 78 from center.

HitDetFinishScr:
L6A75:  LDX #$01                ;Reload object 1 as a saucer.

CheckObjHit:
L6A77:  CMP ObjXDiff            ;Is object 1 X difference smaller than the hit box?
L6A79:  BCC HitDetNextObj2_     ;If not, no hit detected. Branch to check next object.

L6A7B:  CMP ObjYDiff            ;Is object 1 Y difference smaller than the hit box?
L6A7D:  BCC HitDetNextObj2_     ;If not, no hit detected. Branch to check next object.

HitDetPart3:
L6A7F:  STA ObjHitBox           ;Store hit box value.
L6A81:  LSR                     ;/2.
L6A82:  CLC                     ;Add two hit box values together.
L6A83:  ADC ObjHitBox           ;Hit box value is now 1.5 X value set above, about sqrt(2).
L6A85:  STA ObjHitBox           ;This has the effect of making the hit box more circular.

L6A87:  LDA ObjYDiff            ;Add the two difference values together.
L6A89:  ADC ObjXDiff            ;If it causes a carry, The distance is too great.
L6A8B:  BCS HitDetNextObj2_     ;Branch to move to next object.

L6A8D:  CMP ObjHitBox           ;Is combined difference values grater than the hit box?
L6A8F:  BCS HitDetNextObj2_     ;If so, branch to move to the next object.

L6A91:  JSR DoObjHit            ;($6B0F)Update object that got hit.

HitDetNextObj1_:
L6A94:  JMP HitDetNextObj1      ;($69F9)Check next object 1 for a hit.

HitDetNextObj2_:
L6A97:  DEY                     ;Are there more object 2s to check?
L6A98:  BMI HitDetNextObj1_     ;If not, branch to move to the next object 1.

L6A9A:  JMP HitDetObj2Loop      ;($6A0A)Check next object 2 for a hit.

;-----------------------------------[ Update Asteroid Routine ]------------------------------------

UpdateAsteroid:
L6A9D:  LDA AstStatus,Y         ;
L6AA0:  AND #$07                ;Save current asteroid size.
L6AA2:  STA GenByte08           ;

L6AA4:  JSR GetRandNum          ;($77B5)Get a random number.
L6AA7:  AND #$18                ;Use it to set the asteroid type.
L6AA9:  ORA GenByte08           ;

L6AAB:  STA AstStatus,X         ;Save asteroid size and type.

L6AAE:  LDA AstXPosLo,Y         ;
L6AB1:  STA AstXPosLo,X         ;Save asteroid X position.
L6AB4:  LDA AstXPosHi,Y         ;
L6AB7:  STA AstXPosHi,X         ;

L6ABA:  LDA AstYPosLo,Y         ;
L6ABD:  STA AstYPosLo,X         ;Save asteroid Y position.
L6AC0:  LDA AstYPosHi,Y         ;
L6AC3:  STA AstYPosHi,X         ;

L6AC6:  LDA AstXSpeed,Y         ;
L6AC9:  STA AstXSpeed,X         ;
L6ACC:  LDA AstYSpeed,Y         ;Save asteroid velocity.
L6ACF:  STA AstYSpeed,X         ;
L6AD2:  RTS                     ;

;--------------------------------------[ Draw Ship Routines ]--------------------------------------

DrawShip:
L6AD3:  STA VecPtrLB_           ;Save the pointer to the ship vector data.
L6AD5:  STX VecPtrUB_           ;

SetVecRAMData:
L6AD7:  LDY #$00                ;Start at beginning of vector data.

GetShipOpCode:
L6AD9:  INY                     ;Get opcode byte from vector ROM.
L6ADA:  LDA (VecPtr_),Y         ;

L6ADC:  EOR ShipDrawYInv        ;
L6ADE:  STA (VecRamPtr),Y       ;Invert Y axis of VEC data, if necessary.
L6AE0:  DEY                     ;

L6AE1:  CMP #SvecOpcode         ;Is this a SVEC vector opcode?
L6AE3:  BCS DrawShipSVEC        ;If so, branch to get the next SVEC byte.

L6AE5:  CMP #CurOpcode          ;Is this a VEC vector opcode?
L6AE7:  BCS DrawShipRTS         ;If not, branch because it must be an RTS opcode.

DrawShipVEC:
L6AE9:  LDA (VecPtr_),Y         ;Load second byte of VEC data into vector RAM.
L6AEB:  STA (VecRamPtr),Y       ;

L6AED:  INY                     ;
L6AEE:  INY                     ;Move to 3rd byte of VEC data and store in vector RAM.
L6AEF:  LDA (VecPtr_),Y         ;
L6AF1:  STA (VecRamPtr),Y       ;

L6AF3:  INY                     ;
L6AF4:  LDA (VecPtr_),Y         ;Move to 4th byte of VEC data.
L6AF6:  EOR ShipDrawXInv        ;Invert X axis of VEC data, if necessary.
L6AF8:  ADC ShipDrawUnused      ;
L6AFA:  STA (VecRamPtr),Y       ;Store 4th byte in vector RAM.

NextShipOpCode:
L6AFC:  INY                     ;Branch always.
L6AFD:  BNE GetShipOpCode       ;

DrawShipRTS:
L6AFF:  DEY                     ;Done with this segment of ship vector data.
L6B00:  JMP VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

DrawShipSVEC:
L6B03:  LDA (VecPtr_),Y         ;Load second byte of SVEC data into vector RAM.
L6B05:  EOR ShipDrawXInv        ;Invert X axis of SVEC data, if necessary.
L6B07:  CLC                     ;
L6B08:  ADC ShipDrawUnused      ;
L6B0A:  STA (VecRamPtr),Y       ;

L6B0C:  INY                     ;Branch always.
L6B0D:  BNE NextShipOpCode      ;

;--------------------------------------[ Update Hit Object ]---------------------------------------

DoObjHit:
L6B0F:  CPX #$01                ;Is object 1 that hit object 2 a saucer?
L6B11:  BNE ChkObj1Ship         ;If not, branch.

L6B13:  CPY #ShipIndex          ;Is object 2 that got hit the ship?
L6B15:  BNE ObjExplode          ;If not, branch.

L6B17:  LDX #$00                ;Set object 1 as the ship. 
L6B19:  LDY #ScrIndex           ;Set object 2 as the saucer.

ChkObj1Ship:
L6B1B:  TXA                     ;Is object 1 the ship?
L6B1C:  BNE ClearObjRAM         ;If not, branch.

Obj1ShipHit:
L6B1E:  LDA #$81                ;Indicate the ship is waiting to re-spawn.
L6B20:  STA ShipSpawnTmr        ;

L6B23:  LDX CurrentPlyr         ;Remove a life from the current player.
L6B25:  DEC Plyr1Ships,X        ;
L6B27:  LDX #$00                ;Indicate ship is object 1.

ObjExplode:
L6B29:  LDA #$A0                ;Indicate object is exploding.
L6B2B:  STA ShipStatus,X        ;

L6B2E:  LDA #$00                ;
L6B30:  STA ShipXSpeed,X        ;Zero out the ship's velocity.
L6B33:  STA ShipYSpeed,X        ;

L6B36:  CPY #$1B                ;Is object 2 an asteroid?
L6B38:  BCC ObjAsteroid         ;If so, branch.

L6B3A:  BCS SaucerHit           ;Must have been a saucer hit. Branch always.

ClearObjRAM:
L6B3C:  LDA #$00                ;Remove the hit object from RAM.
L6B3E:  STA ShipStatus,X        ;

L6B41:  CPY #ShipIndex          ;Is object 2 the ship?
L6B43:  BEQ Obj2ShipHit         ;If so, branch.

L6B45:  BCS SaucerHit           ;Was object 2 a saucer? If so, branch.

ObjAsteroid:
L6B47:  JSR BreakAsteroid       ;($75EC)Break down a hit asteroid.

ObjHitSFX:
L6B4A:  LDA AstStatus,Y         ;Change length of hit SFX based on object size.
L6B4D:  AND #$03                ;
L6B4F:  EOR #$02                ;
L6B51:  LSR                     ;
L6B52:  ROR                     ;
L6B53:  ROR                     ;
L6B54:  ORA #$3F                ;Set hit SFX minimum time.
L6B56:  STA ExplsnSFXTimer      ;Set hit SFX time.

L6B58:  LDA #$A0                ;Indicate object is exploding.
L6B5A:  STA AstStatus,Y         ;

L6B5D:  LDA #$00                ;
L6B5F:  STA AstXSpeed,Y         ;Zero out object velocity.
L6B62:  STA AstYSpeed,Y         ;
L6B65:  RTS                     ;

Obj2ShipHit:
L6B66:  TXA                     ;Get index to current player's reserve ships.
L6B67:  LDX CurrentPlyr         ;
L6B69:  DEC Plyr1Ships,X        ;Remove a life from the current player.
L6B6B:  TAX                     ;
L6B6C:  LDA #$81                ;Indicate the ship is waiting to re-spawn.
L6B6E:  STA ShipSpawnTmr        ;
L6B71:  BNE ObjHitSFX           ;Branch always.

SaucerHit:
L6B73:  LDA ScrTmrReload        ;Reset the saucer timer.
L6B76:  STA ScrTimer            ;

L6B79:  LDA NumPlayers          ;Is someone playing the game?
L6B7B:  BEQ ObjHitSFX           ;If not, branch to skip updating score.

L6B7D:  STX GenByte0D           ;Save object 1 index.
L6B7F:  LDX ScoreIndex          ;Get index to current player's score.

L6B81:  LDA ScrStatus           ;Check to see if a small saucer was hit.
L6B84:  LSR                     ;
L6B85:  LDA #SmallScrPnts       ;Prepare to add small saucer points to score.
L6B87:  BCS AddSaucerPoints     ;Was a small saucer hit? If so, branch.

L6B89:  LDA #LargeScrPnts       ;A large saucer was hit. Load large saucer points.

AddSaucerPoints:
L6B8B:  JSR UpdateScore         ;($7397)Add points to the current player's score.
L6B8E:  LDX GenByte0D           ;Restore object 1 index.
L6B90:  JMP ObjHitSFX           ;($6B4A)Set SFX for object being hit based on object size.

;------------------------------------[ Update Saucer Routines ]------------------------------------

UpdateScr:
L6B93:  LDA FrameTimerLo        ;Update saucers only every 4th frame.
L6B95:  AND #$03                ;Is this the 4th frame?
L6B97:  BEQ ChkScrExplode       ;If so, branch to continue processing.

EndUpdateScr:
L6B99:  RTS                     ;End update saucer routines.

ChkScrExplode:
L6B9A:  LDA ScrStatus           ;Is the saucer currently exploding?
L6B9D:  BMI EndUpdateScr        ;If so, branch to exit.

L6B9F:  BEQ DoScrTimers         ;Is no saucer active? if so, branch to update saucer timers.
L6BA1:  JMP ScrYVelocity        ;($6C34)Saucer active. Update saucer Y velocity.

DoScrTimers:
L6BA4:  LDA NumPlayers          ;Is a game currently being played?
L6BA6:  BEQ DoScrTmrUpdate      ;If not, branch to continue.

L6BA8:  LDA ShipStatus          ;Is the player's ship exploding or in hyperspace?
L6BAB:  BEQ EndUpdateScr        ;If so, branch to exit saucer update routines.
L6BAD:  BMI EndUpdateScr        ;

DoScrTmrUpdate:
L6BAF:  LDA AstBreakTimer       ;Was an asteroid just hit?
L6BB2:  BEQ UpdateScrTimer      ;If not, branch to update saucer timer.

L6BB4:  DEC AstBreakTimer       ;Decrement asteroid hit timer.

UpdateScrTimer:
L6BB7:  DEC ScrTimer            ;Is it time to re-spawn a saucer?
L6BBA:  BNE EndUpdateScr        ;If not, branch to exit.

L6BBC:  LDA #$01                ;Time to re-spawn a saucer. set timer just above 0-->
L6BBE:  STA ScrTimer            ;Just in case another factor keeps it from spawning.

L6BC1:  LDA AstBreakTimer       ;Was an asteroid just hit?
L6BC4:  BEQ GenNewSaucer        ;If not, branch to spawn a saucer.

L6BC6:  LDA CurAsteroids        ;If an asteroid was just hit and it was the last asteroid,-->
L6BC9:  BEQ EndUpdateScr        ;Branch to end function. No saucer spawn on an empty screen.

L6BCB:  CMP ScrSpeedup          ;Has the asteroid number hit the saucer spawn speedup threshold?
L6BCE:  BCS EndUpdateScr        ;If not, branch to end.

GenNewSaucer:
L6BD0:  LDA ScrTmrReload        ;
L6BD3:  SEC                     ;Saucer spawn speedup threshold hit. decrement saucer timer by 6.
L6BD4:  SBC #$06                ;

L6BD6:  CMP #$20                ;Is pawn timer below minimum value of 32?
L6BD8:  BCC InitNewSaucer       ;If so, branch to initialize the new saucer.

L6BDA:  STA ScrTmrReload        ;Maintain a minimum saucer spawn timer.

InitNewSaucer:
L6BDD:  LDA #$00                ;
L6BDF:  STA ScrXPosLo           ;Start saucer at left edge of the display.
L6BE2:  STA ScrXPosHi           ;

L6BE5:  JSR GetRandNum          ;($77B5)Get a random number.
L6BE8:  LSR                     ;
L6BE9:  ROR ScrYPosLo           ;
L6BEC:  LSR                     ;Use three of the random bits to set the saucer Y position.
L6BED:  ROR ScrYPosLo           ;
L6BF0:  LSR                     ;
L6BF1:  ROR ScrYPosLo           ;

L6BF4:  CMP #$18                ;Is remaining random bits greater than limit?
L6BF6:  BCC SetScrYPosHi        ;If not, branch.

L6BF8:  AND #$17                ;Limit max Y position high byte.

SetScrYPosHi:
L6BFA:  STA ScrYPosHi           ;Set high byte of saucer Y starting position.

L6BFD:  LDX #$10                ;Randomly set saucer X movement direction.
L6BFF:  BIT RandNumUB           ;Is saucer moving from left to right?
L6C01:  BVS ScrXVelocity        ;If so, branch.

L6C03:  LDA #$1F                ;
L6C05:  STA ScrXPosHi           ;Start saucer at right edge of the display.
L6C08:  LDA #$FF                ;
L6C0A:  STA ScrXPosLo           ;

L6C0D:  LDX #$F0                ;Set saucer X velocity for a negative direction(right to left).

ScrXVelocity:
L6C0F:  STX SaucerXSpeed        ;Save final saucer X velocity.

L6C12:  LDX #$02                ;Prepare to make a large saucer.
L6C14:  LDA ScrTmrReload        ;Is it still early in the asteroid wave?
L6C17:  BMI SetScrStatus        ;If so, branch to create a large saucer.

L6C19:  LDY ScoreIndex          ;Is the player's score above 3000?
L6C1B:  LDA Plr1ScoreThous_,Y   ;If so, branch to create a small saucer.
L6C1E:  CMP #$30                ;
L6C20:  BCS SetSmallScr         ;

L6C22:  JSR GetRandNum          ;($77B5)Get a random number.
L6C25:  STA GenByte08           ;
L6C27:  LDA ScrTmrReload        ;Is the random number smaller than the saucer timer-->
L6C2A:  LSR                     ;reload value / 2? If so, create a small saucer.
L6C2B:  CMP GenByte08           ;
L6C2D:  BCS SetScrStatus        ;Else branch to create a large saucer.

SetSmallScr:
L6C2F:  DEX                     ;X=1. Create a small saucer.

SetScrStatus:
L6C30:  STX ScrStatus           ;Store size of saucer and exit.
L6C33:  RTS                     ;

;For the routines below, a saucer is already active.  These routines update the active saucer.

ScrYVelocity:
L6C34:  LDA FrameTimerLo        ;Randomly change saucer Y velocity every 128 frames.
L6C36:  ASL                     ;Is it time to change the saucer's Y velocity?
L6C37:  BNE ChkScrUpdate        ;If not, branch.

ChangeScrYVel:
L6C39:  JSR GetRandNum          ;($77B5)Get a random number.
L6C3C:  AND #$03                ;Keep the lower 2 bits for index into table below.
L6C3E:  TAX                     ;
L6C3F:  LDA ScrYSpeedTbl,X      ;
L6C42:  STA SaucerYSpeed        ;Load new Y velocity value for the saucer.

ChkScrUpdate:
L6C45:  LDA NumPlayers          ;Is a game being played?
L6C47:  BEQ ChkScrFire          ;If not, branch to check saucer fire timer.

L6C49:  LDA ShipSpawnTmr        ;Is the player actively playing?
L6C4C:  BNE ScrUpdateEnd        ;If not, branch to exit.

ChkScrFire:
L6C4E:  DEC ScrTimer            ;Is it time for the saucer's next action?
L6C51:  BEQ ScrUpdateAction     ;If so, branch to do saucer's next action.

ScrUpdateEnd:
L6C53:  RTS                     ;Done doing saucer updates.

ScrUpdateAction:
L6C54:  LDA #$0A                ;Reload saucer timer for next saucer action.
L6C56:  STA ScrTimer            ;

L6C59:  LDA ScrStatus           ;Is this a big of small saucer?
L6C5C:  LSR                     ;If its a large saucer, prepare to shoot a random shot. -->
L6C5D:  BEQ GetScrShpDistance   ;If its a small saucer, prepare to shoot an aimed shot.

L6C5F:  JSR GetRandNum          ;($77B5)Get a random number.
L6C62:  JMP ScrShoot            ;($6CC2)Prepare to generate a saucer bullet.

GetScrShpDistance:
L6C65:  LDA SaucerXSpeed        ;Get saucer X direction velocity.
L6C68:  CMP #$80                ;
L6C6A:  ROR                     ;/2 with sign extension.
L6C6B:  STA GenByte0C           ;Save result.

L6C6D:  LDA ShipXPosLo          ;
L6C70:  SEC                     ;Get difference between saucer and ship X position low byte.
L6C71:  SBC ScrXPosLo           ;
L6C74:  STA GenByte0B           ;Save result.

L6C76:  LDA shipXPosHi          ;Get difference between saucer and ship X position high byte.
L6C79:  SBC ScrXPosHi           ;
L6C7C:  JSR NextScrShipDist     ;($77EC)Calculate next frame saucer/ship X distance.

L6C7F:  CMP #$40                ;Is the saucer to the left of the ship?
L6C81:  BCC SetSmallScrShotDir  ;If so, branch to shoot bullet to the right.

L6C83:  CMP #$C0                ;Is saucer to the far right of the ship?
L6C85:  BCS $6C89               ;If so, branch to shoot bullet to right so it can screen wrap. 

L6C87:  EOR #$FF                ;Change sign so bullet can shoot left.

SetSmallScrShotDir:
L6C89:  TAX                     ;Save X distance data for bullet.

L6C8A:  LDA SaucerYSpeed        ;Get saucer Y velocity and set carry if traveling
L6C8D:  CMP #$80                ;in a negative direction.
L6C8F:  ROR                     ;Divide speed by 2 and set MSB based on Y direction.
L6C90:  STA GenByte0C           ;

L6C92:  LDA ShipYPosLo          ;
L6C95:  SEC                     ;Get difference between saucer and ship X position low byte.
L6C96:  SBC ScrYPosLo           ;
L6C99:  STA GenByte0B           ;Save result.

L6C9B:  LDA ShipYPosHi          ;Get difference between saucer and ship X position high byte.
L6C9E:  SBC ScrYPosHi           ;
L6CA1:  JSR NextScrShipDist     ;($77EC)Calculate next frame saucer/ship Y distance.

L6CA4:  TAY                     ;Save Y distance data for bullet.

L6CA5:  JSR CalcScrShotDir      ;($76F0)Calculate the small saucer's shot direction.
L6CA8:  STA ScrBulletDir        ;Saucer shot direction is the same type of data as ship direction.

L6CAA:  JSR GetRandNum          ;($77B5)Get a random number.
L6CAD:  LDX ScoreIndex          ;
L6CAF:  LDY PlayerScores+1,X    ;Is the player's score less than 35,000?
L6CB1:  CPY #$35                ;If so, add inaccuracy to small saucer's bullet.
L6CB3:  LDX #$00                ;
L6CB5:  BCC ScrShotAddOffset    ;

L6CB7:  INX                     ;Player's score is high, make saucer shot more accurate.

ScrShotAddOffset:
L6CB8:  AND ShotRndAddTbl,X     ;Mask random value to randomize saucer bullet.
L6CBB:  BPL RandomizeScrShot    ;

L6CBD:  ORA ShotRndOrTbl,X      ;Is random value negative? If so, adjust bullet velocity.

RandomizeScrShot:
L6CC0:  ADC ScrBulletDir        ;Add randomized value to small saucer shot.

ScrShoot:
L6CC2:  STA ScrBulletDir        ;Prepare to fire a bullet if a slot is available.
L6CC4:  LDY #$03                ;Start index for saucer bullet slots.
L6CC6:  LDX #$01                ;2 bullet slots for the saucer.
L6CC8:  STX NumBulletSlots      ;
L6CCA:  JMP FindBulletSlot      ;($6CF2)Find an empty saucer bullet slot.

ShotRndAddTbl:
L6CCD:  .byte $8F, $87          ;Mask for random value to add to small saucer shot.

ShotRndOrTbl:
L6CCF:  .byte $70, $78          ;If negative random, set bits to bring it close to the ship.

;This table sets the saucer Y velocity.  It is randomly  
;set and moves the saucer diagonally across the screen.

ScrYSpeedTbl:
L6CD1:  .byte $F0               ;-16 Moving down.
L6CD2:  .byte $00               ; 0  No Y velocity.
L6CD3:  .byte $00               ; 0  No Y velocity.
L6CD4:  .byte $10               ;+16 Moving up.

L6CD5:  .byte $00, $00          ;Unused.

;-------------------------------------[ Update Ship Routine ]--------------------------------------

UpdateShip:
L6CD7:  LDA NumPlayers          ;Is a game currently being played?
L6CD9:  BEQ EndUpdateShip       ;If not, branch to exit.

L6CDB:  ASL FireSw              ;Shift current state of fire button into shift register.
L6CDE:  ROR ShipBulletSR        ;

L6CE0:  BIT ShipBulletSR        ;Is MSB of bullet shift register set?
L6CE2:  BPL EndUpdateShip       ;If not, branch to exit. Limits fire rate.

L6CE4:  BVS EndUpdateShip       ;Is bit 6 set? If so, branch to exit. Prevents auto fire.

L6CE6:  LDA ShipSpawnTmr        ;Is ship waiting to spawn?
L6CE9:  BNE EndUpdateShip       ;If so, branch to exit.

L6CEB:  TAX                     ;Zero out X. Indicates ship is updating in following functions.
L6CEC:  LDA #$03                ;Prepare to check 4 bullet slots.
L6CEE:  STA NumBulletSlots      ;
L6CF0:  LDY #$07                ;Set index to ship bullet slots.

;----------------------------------[ Bullet Generation Routines ]----------------------------------

;The functions below are used for both ship bullets and saucer bullets.

FindBulletSlot:
L6CF2:  LDA ShipStatus,Y        ;Get ship/saucer bullet status.
L6CF5:  BEQ BulletSlotFound     ;Is slot available? If so, branch to continue.

L6CF7:  DEY                     ;Move to next bullet slot.
L6CF8:  CPY NumBulletSlots      ;Is there more bullet slots to check?
L6CFA:  BNE FindBulletSlot      ;If so, branch check next bullet slot.

EndUpdateShip:
L6CFC:  RTS                     ;Done updating bullets.

BulletSlotFound:
L6CFD:  STX ShipScrShot         ;Store index to bullet type being processed.
L6CFF:  LDA #$12                ;Set bullet to last for 18 frames.
L6D01:  STA ShipStatus,Y        ;

L6D04:  LDA ShipDir,X           ;Get ship direction/saucer bullet direction.
L6D06:  JSR CalcXThrust         ;($77D2)Calculate X velocity for the bullet.

L6D09:  LDX ShipScrShot         ;Reload index to ship direction/saucer bullet direction.
L6D0B:  CMP #$80                ;Is ship/bullet facing left? If so, set carry bit.
L6D0D:  ROR                     ;Divide direction value by 2 and save carry bit in MSB.
L6D0E:  STA ShotXDir            ;

L6D10:  CLC                     ;Add X velocity change to existing velocity.
L6D11:  ADC ShipXSpeed,X        ;Is this a right to left traveling object?
L6D14:  BMI ChkMaxNegXVel       ;If so, branch to set a velocity limit.

L6D16:  CMP #$70                ;Must be a left to right moving object.
L6D18:  BCC SaveObjXVel         ;Has max X velocity been reached? if so, branch.

L6D1A:  LDA #$6F                ;Set maximum X velocity (111 pixels per frame).
L6D1C:  BNE SaveObjXVel         ;Branch always.

ChkMaxNegXVel:
L6D1E:  CMP #$91                ;Has max X velocity been reached (right to left)?
L6D20:  BCS SaveObjXVel         ;If not, branch.

L6D22:  LDA #$91                ;Maximum negative X velocity (-111 pixels per frame).

SaveObjXVel:
L6D24:  STA ShipXSpeed,Y        ;Save updated X velocity. Done only once for bullets.

L6D27:  LDA ShipDir,X           ;Get ship direction/saucer bullet direction.
L6D29:  JSR CalcThrustDir       ;($77D5)Calculate Y velocity for the bullet.

L6D2C:  LDX ShipScrShot         ;Reload index to ship direction/saucer bullet direction.
L6D2E:  CMP #$80                ;Is ship/bullet facing downward? If so, set carry bit.
L6D30:  ROR                     ;Divide direction value by 2 and save carry bit in MSB.
L6D31:  STA ShotYDir            ;

L6D33:  CLC                     ;Add Y velocity change to existing velocity.
L6D34:  ADC ShipYSpeed,X        ;Is this a top to bottom traveling object?
L6D37:  BMI ChkMaxNegYVel       ;If so, branch to set a velocity limit.

L6D39:  CMP #$70                ;Must be a bottom to top moving object.
L6D3B:  BCC SaveObjYVel         ;Has max Y velocity been reached? if so, branch.

L6D3D:  LDA #$6F                ;Set maximum Y velocity (111 pixels per frame).
L6D3F:  BNE SaveObjYVel         ;Branch always.

ChkMaxNegYVel:
L6D41:  CMP #$91                ;Has max Y velocity been reached (top to bottom)?
L6D43:  BCS SaveObjYVel         ;If not, branch.

L6D45:  LDA #$91                ;Maximum negative Y velocity (-111 pixels per frame).

SaveObjYVel:
L6D47:  STA ShipYSpeed,Y        ;Save updated Y velocity. Done only once for bullets.

L6D4A:  LDX #$00                ;Assume shot moving left to right.
L6D4C:  LDA ShotXDir            ;Is shot moving left to right?
L6D4E:  BPL SetShotXPos         ;If so, branch.

L6D50:  DEX                     ;Shot is moving right to left.

SetShotXPos:
L6D51:  STX ObjectXPosNeg       ;Store value used for properly updating shot X position.

L6D53:  LDX ShipScrShot         ;Reload index to ship direction/saucer bullet direction.
L6D55:  CMP #$80                ;Is ship/bullet facing left? If so, set carry bit.
L6D57:  ROR                     ;Divide direction value by 2 and save carry bit in MSB.
L6D58:  CLC                     ;Add value to the bullet X direction.
L6D59:  ADC ShotXDir            ;

L6D5B:  CLC                     ;
L6D5C:  ADC ShipXPosLo,X        ;Update lower byte of shot X position.
L6D5F:  STA ShipXPosLo,Y        ;

L6D62:  LDA ObjectXPosNeg       ;
L6D64:  ADC shipXPosHi,X        ;Update upper byte of shot X position with proper sign.
L6D67:  STA shipXPosHi,Y        ;

L6D6A:  LDX #$00                ;Assume shot moving bottom to top.
L6D6C:  LDA ShotYDir            ;Is shot moving bottom to top?
L6D6E:  BPL SetShotYPos         ;If so, branch.

L6D70:  DEX                     ;Shot is moving top to bottom.

SetShotYPos:
L6D71:  STX ObjectYPosNeg       ;Store value used for properly updating shot Y position.

L6D73:  LDX ShipScrShot         ;Reload index to ship direction/saucer bullet direction.
L6D75:  CMP #$80                ;Is ship/bullet facing down? If so, set carry bit.
L6D77:  ROR                     ;Divide direction value by 2 and save carry bit in MSB.
L6D78:  CLC                     ;Add value to the bullet Y direction.
L6D79:  ADC ShotYDir            ;

L6D7B:  CLC                     ;
L6D7C:  ADC ShipYPosLo,X        ;Update lower byte of shot Y position.
L6D7F:  STA ShipYPosLo,Y        ;

L6D82:  LDA ObjectYPosNeg       ;
L6D84:  ADC ShipYPosHi,X        ;Update upper byte of shot Y position with proper sign.
L6D87:  STA ShipYPosHi,Y        ;

L6D8A:  LDA #$80                ;
L6D8C:  STA SFXTimers,X         ;Turn on SFX for the shot fired.
L6D8E:  RTS                     ;

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L6D8F:  .byte $D6               ;Checksum byte.

;---------------------------------[ High Score Message Routines ]----------------------------------

ChkHighScrMsg:
L6D90:  LDA Plyr1Rank           ;Did one of the players get a ranking in the top 10?
L6D92:  AND Plyr2Rank           ;
L6D94:  BPL GetPrevPlayers      ;If so, branch to keep going.
L6D96:  RTS                     ;Else exit.

GetPrevPlayers:
L6D97:  LDA PrevGamePlyrs       ;Get the number of players in the game that just ended.
L6D99:  LSR                     ;Was last game a single player game?
L6D9A:  BEQ DoHighScrMsg        ;If so, branch.

L6D9C:  LDY #PlyrText           ;PLAYER.
L6D9E:  JSR WriteText           ;($77F6)Write text to the display.

L6DA1:  LDY #$02                ;Prepare to indicate player 2 high score.
L6DA3:  LDX Plyr2Rank           ;Did player 2 get a high score?
L6DA5:  BPL DoPlayerDigit       ;If so, branch.

L6DA7:  DEY                     ;Indicate player 1 got high score.

DoPlayerDigit:
L6DA8:  STY CurrentPlyr         ;Indicate which player got the high score.
L6DAA:  LDA FrameTimerLo        ;
L6DAC:  AND #$10                ;Should the player number be displayed?
L6DAE:  BNE DoHighScrMsg        ;If not, branch.

L6DB0:  TYA                     ;Set player's digit(1 or 2).
L6DB1:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

DoHighScrMsg:
L6DB4:  LSR CurrentPlyr         ;Get current player.
L6DB6:  JSR SwapRAM             ;($73B2)Set RAM for current player.

L6DB9:  LDY #YrScrText          ;YOUR SCORE IS ONE OF THE TEN BEST.
L6DBB:  JSR WriteText           ;($77F6)Write text to the display.
L6DBE:  LDY #InitText           ;PLEASE ENTER YOUR INITIALS.
L6DC0:  JSR WriteText           ;($77F6)Write text to the display.
L6DC3:  LDY #PshRtText          ;PUSH ROTATE TO SELECT LETTER.
L6DC5:  JSR WriteText           ;($77F6)Write text to the display.
L6DC8:  LDY #PshHypText         ;PUSH HYPERSPACE WHEN LETTER IS CORRECT.
L6DCA:  JSR WriteText           ;($77F6)Write text to the display.

L6DCD:  LDA #$20                ;Set global scale=2(*4).
L6DCF:  STA GlobalScale         ;

L6DD1:  LDA #$64                ;X beam coordinate 4 * $64 = $190  = 400.
L6DD3:  LDX #$39                ;Y beam coordinate 4 * $39 = $E4  = 228.
L6DD5:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L6DD8:  LDA #$70                ;Set scale 7(/4).
L6DDA:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L6DDD:  LDX CurrentPlyr         ;
L6DDF:  LDY Plyr1Rank,X         ;Save the offset to the current player's initials.
L6DE1:  STY GenByte0B           ;

L6DE3:  TYA                     ;Save index to player's current initial being changed.
L6DE4:  CLC                     ;
L6DE5:  ADC ThisInitial         ;
L6DE7:  STA SelInitial          ;
L6DE9:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L6DEC:  LDY GenByte0B           ;Draw second initial.
L6DEE:  INY                     ;
L6DEF:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L6DF2:  LDY GenByte0B           ;Draw third initial.
L6DF4:  INY                     ;
L6DF5:  INY                     ;
L6DF6:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L6DF9:  LDA HyprSpcSw           ;Get hyperspace button status.
L6DFC:  ROL                     ;
L6DFD:  ROL InitialDebounce     ;Roll value into debounce register.
L6DFF:  LDA InitialDebounce     ;
L6E01:  AND #$1F                ;Keep only lower 5 bits of debounce register.
L6E03:  CMP #$07                ;Hyperspace button must be pressed for 3 frames to register.
L6E05:  BNE ChkScoreTimeUp      ;Did player select an initial? If not, branch.

L6E07:  INC ThisInitial         ;Move to the next initial.
L6E09:  LDA ThisInitial         ;
L6E0B:  CMP #$03                ;Has the last initial been selected?
L6E0D:  BCC NextInitial         ;If not, branch.

L6E0F:  LDX CurrentPlyr         ;
L6E11:  LDA #$FF                ;Zero out the current player's rank.
L6E13:  STA Plyr1Rank,X         ;

FinishHighScore:
L6E15:  LDX #$00                ;
L6E17:  STX CurrentPlyr         ;Move to player 1 and zero out initial index.
L6E19:  STX ThisInitial         ;

L6E1B:  LDX #$F0                ;Reset frame timer.
L6E1D:  STX FrameTimerHi        ;
L6E1F:  JMP SwapRAM             ;($73B2)Set RAM for current player.

NextInitial:
L6E22:  INC SelInitial          ;Increment initial index.
L6E24:  LDX SelInitial          ;

L6E26:  LDA #$F4                ;Reset frame timer.
L6E28:  STA FrameTimerHi        ;

L6E2A:  LDA #$0B                ;Set value of new initial to A.
L6E2C:  STA HighScoreIntls,X    ;

ChkScoreTimeUp:
L6E2E:  LDA FrameTimerHi        ;Has initial entry time expired?
L6E30:  BNE ScoreTimeRemain     ;If not, branch.

L6E32:  LDA #$FF                ;
L6E34:  STA Plyr1Rank           ;Zero out player's ranks and finish.
L6E36:  STA Plyr2Rank           ;
L6E38:  BMI FinishHighScore     ;

ScoreTimeRemain:
L6E3A:  LDA FrameTimerLo        ;Only update displayed initial every 8th frame.
L6E3C:  AND #$07                ;Is this the 8th frame?
L6E3E:  BNE HighScoreEnd        ;If not, branch.

ChkScoreLftBtn:
L6E40:  LDA RotLeftSw           ;Has rotate left button been pressed?
L6E43:  BPL ChkScoreRghtBtn     ;If not, branch.

L6E45:  LDA #$01                ;Increment initial.
L6E47:  BNE ChangeInitial       ;Branch always.

ChkScoreRghtBtn:
L6E49:  LDA RotRghtSw           ;Has rotate right button been pressed?
L6E4C:  BPL HighScoreEnd        ;If not, branch to end.

L6E4E:  LDA #$FF                ;Decrement initial.

ChangeInitial:
L6E50:  LDX SelInitial          ;Update the selected initial.
L6E52:  CLC                     ;
L6E53:  ADC HighScoreIntls,X    ;Does value need to wrap around to Z?
L6E55:  BMI SetInitialMax       ;If so, branch.

L6E57:  CMP #$0B                ;Is initial less than the index for A?
L6E59:  BCS ChkInitialMax       ;If so, branch to force index to SPACE.

L6E5B:  CMP #$01                ;Is index for a number?
L6E5D:  BEQ SetInitialMin       ;If so, branch to force index to A.

L6E5F:  LDA #$00                ;Set initial index to SPACE.
L6E61:  BEQ SetInitial          ;Branch always.

SetInitialMin:
L6E63:  LDA #$0B                ;Set initial index to A.
L6E65:  BNE SetInitial          ;Branch always.

SetInitialMax:
L6E67:  LDA #$24                ;Set selected initial to Z.

ChkInitialMax:
L6E69:  CMP #$25                ;Does initial index need to wrap to SPACE?
L6E6B:  BCC SetInitial          ;If not, branch.

L6E6D:  LDA #$00                ;Set initial index to SPACE.

SetInitial:
L6E6F:  STA HighScoreIntls,X    ;Store new initial value.

HighScoreEnd:
L6E71:  LDA #$00                ;Done processing high score for this frame.
L6E73:  RTS                     ;

;-----------------------------------[ Enter Hyperspace Routine ]-----------------------------------

EnterHyprspc:
L6E74:  LDA NumPlayers          ;Is a game currently being played?
L6E76:  BEQ ChkHyprspcEnd       ;If not, branch to exit.

L6E78:  LDA ShipStatus          ;Is the player's ship currently exploding?
L6E7B:  BMI ChkHyprspcEnd       ;If so, branch to exit.

L6E7D:  LDA ShipSpawnTmr        ;Is the ship currently waiting to spawn?
L6E80:  BNE ChkHyprspcEnd       ;If so, branch to exit.

L6E82:  LDA HyprSpcSw           ;Has the hyperspace button been pressed?
L6E85:  BPL ChkHyprspcEnd       ;If not, branch to exit.

L6E87:  LDA #$00                ;Indicate the ship has entered hyperspace.
L6E89:  STA ShipStatus          ;

L6E8C:  STA ShipXSpeed          ;Zero out ship velocity.
L6E8F:  STA ShipYSpeed          ;

L6E92:  LDA #$30                ;Set ship spawn timer.
L6E94:  STA ShipSpawnTmr        ;

L6E97:  JSR GetRandNum          ;($77B5)Get a random number.
L6E9A:  AND #$1F                ;Get lower 5 bits for new ship X position.
L6E9C:  CMP #$1D                ;Make sure value is capped.
L6E9E:  BCC MinHyprspcXPos      ;Is value greater than the maximum allowed? If not, branch.

L6EA0:  LDA #$1C                ;Set X position to max value.

MinHyprspcXPos:
L6EA2:  CMP #$03                ;Is value less than the minimum allowed? If not, branch.
L6EA4:  BCS SetHyprspcXPos      ;

L6EA6:  LDA #$03                ;Set X position to min value.

SetHyprspcXPos:
L6EA8:  STA shipXPosHi          ;Set the new X position for the ship.

L6EAB:  LDX #$05                ;Prepare to get a random number 5 times.

HyprspceRandLoop:
L6EAD:  JSR GetRandNum          ;($77B5)Get a random number.
L6EB0:  DEX                     ;finished getting random numbers?
L6EB1:  BNE HyprspceRandLoop    ;If not, branch to get another one.

L6EB3:  AND #$1F                ;Get lower 5 bits of random number.

L6EB5:  INX                     ;Assume a successful hyperspace jump.

L6EB6:  CMP #$18                ;Check if random number causes a failed hyperspace jump.
L6EB8:  BCC MaxHyprspcYPos      ;Jump failed? If not, branch.

L6EBA:  AND #$07                ;Take lower 3 bits of random number *2 + 4.
L6EBC:  ASL                     ;Is the resulting value < current number of asteroids?
L6EBD:  ADC #$04                ;If so, jump was unsuccessful.
L6EBF:  CMP CurAsteroids        ;
L6EC2:  BCC MaxHyprspcYPos      ;Was jump successful? If so, branch.

L6EC4:  LDX #$80                ;Indicate an unsuccessful hyperspace jump.

MaxHyprspcYPos:
L6EC6:  CMP #$15                ;Make sure value is capped.
L6EC8:  BCC MinHyprspcYPos      ;Is value greater than the maximum allowed? If not, branch.

L6ECA:  LDA #$14                ;Set Y position to max value.

MinHyprspcYPos:
L6ECC:  CMP #$03                ;Is value less than the minimum allowed? If not, branch.
L6ECE:  BCS SetHyprspcYPos      ;

L6ED0:  LDA #$03                ;Set Y position to min value.

SetHyprspcYPos:
L6ED2:  STA ShipYPosHi          ;Set the new Y position for the ship.
L6ED5:  STX HyprSpcFlag         ;Set the success or failure of the hyperspace jump.

ChkHyprspcEnd:
L6ED7:  RTS                     ;End hyperspace entry routine.

;----------------------------------[ Initialize Game Variables ]-----------------------------------

InitGameVars:
L6ED8:  LDA #$02                ;Prepare to start wave 1 with 4 asteroids (+2 later).
L6EDA:  STA AstPerWave          ;

L6EDD:  LDX #$03                ;Is the DIP switches set for 3 ships per game?
L6EDF:  LSR CentCMShipsSw       ;
L6EE2:  BCS InitShipsPerGame    ;If so, branch.

L6EE4:  INX                     ;4 ships per game.

InitShipsPerGame:
L6EE5:  STX ShipsPerGame        ;Load initial ships to start this game with.

L6EE7:  LDA #$00                ;Prepare to zero variables.
L6EE9:  LDX #$03                ;

VarZeroLoop:
L6EEB:  STA ShipStatus,X        ;
L6EEE:  STA ShpShotTimer,X      ;
L6EF1:  STA PlayerScores,X      ;Zero out ship status, saucer status and player scores.
L6EF3:  DEX                     ;
L6EF4:  BPL VarZeroLoop         ;

L6EF6:  STA CurAsteroids        ;Zero out current number of asteroids.
L6EF9:  RTS                     ;

;------------------------------------[ Silence Sound Effects ]-------------------------------------

SilenceSFX:
L6EFA:  LDA #$00                ;
L6EFC:  STA ExpPitchVol         ;
L6EFF:  STA ThumpFreqVol        ;
L6F02:  STA SaucerSFX           ;
L6F05:  STA SaucerFireSFX       ;Zero out SFX control registers.
L6F08:  STA ShipThrustSFX       ;
L6F0B:  STA ShipFireSFX         ;
L6F0E:  STA LifeSFX             ;

L6F11:  STA ExplsnSFXTimer      ;
L6F13:  STA FireSFXTimer        ;
L6F15:  STA ScrFrSFXTimer       ;Zero out SFX timers.
L6F17:  STA ExLfSFXTimer        ;
L6F19:  RTS                     ;

;-----------------------------------------[ Draw Initial ]-----------------------------------------

DrawInitial:
L6F1A:  LDA HighScoreIntls_,Y   ;Get value of currently selected initial.
L6F1D:  ASL                     ;
L6F1E:  TAY                     ;Does it have a value?
L6F1F:  BNE DrawChar            ;If so, branch to draw the initial.

L6F21:  LDA Plyr1Rank           ;Is one of the players in the top 10?
L6F23:  AND Plyr2Rank           ;
L6F25:  BMI DrawChar            ;If not, branch to write the existing initial.

DrawUnderline:
L6F27:  LDA #$72                ;SVEC for drawing most of the underline.
L6F29:  LDX #$F8                ;
L6F2B:  JSR VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

L6F2E:  LDA #$01                ;SVEC for drawing the rest of the underline.
L6F30:  LDX #$F8                ;
L6F32:  JMP VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

DrawChar:
L6F35:  LDX CharPtrTbl+1,Y      ;Draw the initial on the display.
L6F38:  LDA CharPtrTbl,Y        ;
L6F3B:  JMP VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

;---------------------------------[ Draw Reserve Ship On Display ]---------------------------------

DrawExtraLives:
L6F3E:  BEQ EndDrawLives        ;Does payer have ships in reserve? If not, branch to exit.

L6F40:  STY GenByte08           ;Create counter value for number of ships to draw.
L6F42:  LDX #$D5                ;Y beam coordinate 4 * $D5 = $354 = 852.
L6F44:  LDY #$E0                ;Set global scale=14(/4).
L6F46:  STY GlobalScale         ;
L6F48:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

DrawLivesLoop:
L6F4B:  LDX #<ExtLivesDat       ;Load JSR to reserve ship vector data into vector RAM.
L6F4D:  LDA #>ExtLivesDat       ;
L6F4F:  JSR VecRomJSR           ;($7BFC)Load JSR command in vector RAM to vector ROM.
L6F52:  DEC GenByte08           ;More ships to draw?
L6F54:  BNE DrawLivesLoop       ;If so, branch.

EndDrawLives:
L6F56:  RTS                     ;Done drawing reserve ships.

;------------------------------------[ Update Objects Routine ]------------------------------------

UpdateObjects:
L6F57:  LDX #$22                ;Prepare to check every object.

UpdateObjLoop:
L6F59:  LDA AstStatus,X         ;Is the current object active?
L6F5C:  BNE UpdateCurObject     ;If so, branch to update it.

NextObjUpdate:
L6F5E:  DEX                     ;Move to next object.
L6F5F:  BPL UpdateObjLoop       ;Done checking objects? If not, branch to do the next one.

L6F61:  RTS                     ;Done updating objects.

UpdateCurObject:
L6F62:  BPL UpdateObjPos        ;Is current object exploding? If not, branch.

DoExplodeObj:
L6F64:  JSR TwosCompliment      ;($7708)Calculate the 2's compliment of the value in A.
L6F67:  LSR                     ;
L6F68:  LSR                     ;Move upper nibble to lower nibble.
L6F69:  LSR                     ;
L6F6A:  LSR                     ;

L6F6B:  CPX #ShipIndex          ;If it the ship that is exploding? If not, branch.
L6F6D:  BNE IncExplosion        ;

L6F6F:  LDA FrameTimerLo        ;Update ship explosion once every other frame.
L6F71:  AND #$01                ;Ship explosion is twice as slow as other objects.
L6F73:  LSR                     ;Time to update ship explosion?
L6F74:  BEQ SaveIncExplosion    ;If not, branch.

IncExplosion:
L6F76:  SEC                     ;Prepare to increment to next explosion state.

SaveIncExplosion:
L6F77:  ADC AstStatus,X         ;Save updated explosion timer.
L6F7A:  BMI ObjectExploding     ;Is object still exploding? If so, branch.

L6F7C:  CPX #ShipIndex          ;Did the ship just finish exploding?
L6F7E:  BEQ ResetShip           ;If so, branch.

L6F80:  BCS ResetSaucer         ;Did the saucer just finish exploding? If so, branch.

L6F82:  DEC CurAsteroids        ;Must have been an asteroid that finished exploding.
L6F85:  BNE ClearObjSlot        ;Decrement number of asteroids. Any left? If so, branch.

L6F87:  LDY #$7F                ;No more asteroids this wave.
L6F89:  STY ThmpSpeedTmr        ;Reset thump speed to slowest speed.

ClearObjSlot:
L6F8C:  LDA #$00                ;Free up asteroid slot.
L6F8E:  STA AstStatus,X         ;
L6F91:  BEQ NextObjUpdate       ;Branch always to move to the next object slot.

ResetShip:
L6F93:  JSR CenterShip          ;($71E8)Center ship on display and zero velocity.
L6F96:  JMP ClearObjSlot        ;($6F8C)Set ship status to 0.

ResetSaucer:
L6F99:  LDA ScrTmrReload        ;Reset saucer timer.
L6F9C:  STA ScrTimer            ;
L6F9F:  BNE ClearObjSlot        ;Branch always.

ObjectExploding:
L6FA1:  STA AstStatus,X         ;Save updated exploding timer.
L6FA4:  AND #$F0                ;
L6FA6:  CLC                     ;Get scale to use for exploding object.
L6FA7:  ADC #$10                ;

L6FA9:  CPX #ShipIndex          ;Special case. Is ship exploding?
L6FAB:  BNE SetObjExplodeScale  ;If not, branch to save exploding scale.

L6FAD:  LDA #$00                ;Prepare to set ship explode scale to 7(/4);

SetObjExplodeScale:
L6FAF:  TAY                     ;Save scale to use for object debris.

L6FB0:  LDA AstXPosLo,X         ;
L6FB3:  STA ThisObjXLB          ;
L6FB5:  LDA AstXPosHi,X         ;
L6FB8:  STA ThisObjXUB          ;Make a copy of the object position in preparation for drawing.
L6FBA:  LDA AstYPosLo,X         ;
L6FBD:  STA ThisObjYLB          ;
L6FBF:  LDA AstYPosHi,X         ;
L6FC2:  STA ThisObjYUB          ;

L6FC4:  JMP DoDrawObject        ;($7027)Prepare to draw current object on the display.

UpdateObjPos:
L6FC7:  CLC                     ;Assume object is moving from left to right.
L6FC8:  LDY #$00                ;
L6FCA:  LDA AstXSpeed,X         ;Is object moving from left to right?
L6FCD:  BPL UpdateObjXPos       ;If so, branch.

L6FCF:  DEY                     ;Indicate object moving from right to left.

UpdateObjXPos:
L6FD0:  ADC AstXPosLo,X         ;Add X velocity to current X position.
L6FD3:  STA AstXPosLo,X         ;
L6FD6:  STA ThisObjXLB          ;Make a copy of location for drawing the object.

L6FD8:  TYA                     ;Update the signed upper byte of the object X position.
L6FD9:  ADC AstXPosHi,X         ;

L6FDC:  CMP #$20                ;Is the object off the X edge of the display?
L6FDE:  BCC SaveObjXPos         ;If not, branch.

L6FE0:  AND #$1F                ;Wrap object to the other X edge of the display.
L6FE2:  CPX #ScrIndex           ;Is the object a saucer?
L6FE4:  BNE SaveObjXPos         ;If not, branch.

L6FE6:  JSR SaucerReset         ;($702D)Reset saucer variables.
L6FE9:  JMP NextObjUpdate       ;($6F5E)Check next object slot.

SaveObjXPos:
L6FEC:  STA AstXPosHi,X         ;Save the updated object X position.
L6FEF:  STA ThisObjXUB          ;

L6FF1:  CLC                     ;Assume object is moving from top to bottom.
L6FF2:  LDY #$00                ;
L6FF4:  LDA AstYSpeed,X         ;Is object moving from top to bottom?
L6FF7:  BPL UpdateObjYPos       ;If so, branch.

L6FF9:  LDY #$FF                ;Indicate object moving from top to bottom.

UpdateObjYPos:
L6FFB:  ADC AstYPosLo,X         ;Add Y velocity to current Y position.
L6FFE:  STA AstYPosLo,X         ;
L7001:  STA ThisObjYLB          ;Make a copy of location for drawing the object.

L7003:  TYA                     ;Update the signed upper byte of the object Y position.
L7004:  ADC AstYPosHi,X         ;

L7007:  CMP #$18                ;Is the object off the Y edge of the display?
L7009:  BCC SaveObjYPos         ;If not, branch.

L700B:  BEQ WrapObjYPos         ;Is object on Y edge border? If so, branch to wrap object.

L700D:  LDA #$17                ;Place object at the upper edge of the display.
L700F:  BNE SaveObjYPos         ;Branch always.

WrapObjYPos:
L7011:  LDA #$00                ;Put object at the bottom edge of the display.

SaveObjYPos:
L7013:  STA AstYPosHi,X         ;Save the updated object Y position.
L7016:  STA ThisObjYUB          ;

L7018:  LDA AstStatus,X         ;Reload the object status for further processing.

L701B:  LDY #$E0                ;Prepare to set scale to 9(/1).
L701D:  LSR                     ;Does object exist?
L701E:  BCS DoDrawObject        ;If so, branch to prepare to draw current object on the display.

L7020:  LDY #$F0                ;Prepare to set scale to 8(/2).
L7022:  LSR                     ;Does object exist?
L7023:  BCS DoDrawObject        ;If so, branch to prepare to draw current object on the display.

L7025:  LDY #$00                ;Prepare to set scale to 7(/4).

DoDrawObject:
L7027:  JSR DrawObject          ;($72FE)Draw asteroid, ship, saucer.
L702A:  JMP NextObjUpdate       ;($6F5E)Check next object slot.

;-----------------------------------------[ Saucer Reset ]-----------------------------------------

SaucerReset:
L702D:  LDA ScrTmrReload        ;Reset saucer timer.
L7030:  STA ScrTimer            ;

L7033:  LDA #$00                ;
L7035:  STA ScrStatus           ;
L7038:  STA SaucerXSpeed        ;Clear other saucer variables.
L703B:  STA SaucerYSpeed        ;
L703E:  RTS                     ;

;-------------------------------------[ Ship Status Updates ]--------------------------------------

ChkExitHprspc:
L703F:  LDA NumPlayers          ;Is a game being played?
L7041:  BEQ ShipStsExit1        ;If not, branch to exit.

L7043:  LDA ShipStatus          ;Is the Player's ship exploding?
L7046:  BMI ShipStsExit1        ;If so, branch to exit.

L7048:  LDA ShipSpawnTmr        ;Is the ship currently waiting to respawn?
L704B:  BEQ ChkPlyrInput        ;If not, branch.

L704D:  DEC ShipSpawnTmr        ;Decrement the spawn timer. Still waiting to respawn?
L7050:  BNE ShipStsExit1        ;If so, branch to exit.

L7052:  LDY HyprSpcFlag         ;Did a hyperspace jump just fail?
L7054:  BMI HyprspcFailed       ;If so, branch.

L7056:  BNE HyprspcSuccess      ;Is ship in hyperspace? If so, branch.

L7058:  JSR IsReturnSafe        ;($7139)Check to see if safe for ship to exit hyperspace.
L705B:  BNE ResetHyprspc        ;Did safety check succeed? If not, branch.

L705D:  LDY ScrStatus           ;Is a saucer on the screen?
L7060:  BEQ HyprspcSuccess      ;If not, branch to bring player out of hyperspace.

L7062:  LDY #$02                ;Make sure spawn timer is not 0. -->
L7064:  STY ShipSpawnTmr        ;Not safe to return from hyperspace.
L7067:  RTS                     ;

HyprspcSuccess:
L7068:  LDA #$01                ;Indicate ship is no longer in hyperspace.
L706A:  STA ShipStatus          ;
L706D:  BNE ResetHyprspc        ;Branch always.

HyprspcFailed:
L706F:  LDA #$A0                ;Indicate the ship is exploding.
L7071:  STA ShipStatus          ;

L7074:  LDX #$3E                ;Set the explosion SFX timer.
L7076:  STX ExplsnSFXTimer      ;

L7078:  LDX CurrentPlyr         ;Decrement the player's extra lives.
L707A:  DEC Plyr1Ships,X        ;

L707C:  LDA #$81                ;Set the ship spawn timer.
L707E:  STA ShipSpawnTmr        ;

ResetHyprspc:
L7081:  LDA #$00                ;Clear the hyperspace status.
L7083:  STA HyprSpcFlag         ;

ShipStsExit1:
L7085:  RTS                     ;Exit ship status update routines.

ChkPlyrInput:
L7086:  LDA RotLeftSw           ;Is rotate left being pressed?
L7089:  BPL ChkRotRght          ;If not, branch.

L708B:  LDA #$03                ;Prepare to add 3 to ship direction.
L708D:  BNE UpdateShipDir       ;Branch always.

ChkRotRght:
L708F:  LDA RotRghtSw           ;Is rotate right being pressed?
L7092:  BPL ChkThrust           ;If not, branch.

L7094:  LDA #$FD                ;Prepare to subtract 3 to ship direction.

UpdateShipDir:
L7096:  CLC                     ;
L7097:  ADC ShipDir             ;Update ship direction.
L7099:  STA ShipDir             ;

ChkThrust:
L709B:  LDA FrameTimerLo        ;Update ship velocity only every other frame.
L709D:  LSR                     ;Time to update ship velocity?
L709E:  BCS ShipStsExit1        ;If not, branch to exit.

L70A0:  LDA ThrustSw            ;Is thrust being pressed?
L70A3:  BPL ShipDecelerate      ;If not, branch.

ShipAccelerate:
L70A5:  LDA #$80                ;Enable the ship thrust SFX.
L70A7:  STA ShipThrustSFX       ;

L70AA:  LDY #$00                ;Assume ship is facing right (positive X direction).
L70AC:  LDA ShipDir             ;Get ship direction in preparation for thrust calculation.
L70AE:  JSR CalcXThrust         ;($77D2)Calculate thrust in X direction.
L70B1:  BPL UpdateShipXVel      ;Is ship facing right? If so, branch.

L70B3:  DEY                     ;Ship is facing left.  Set X for negative direction.

UpdateShipXVel:
L70B4:  ASL                     ;Multiply thrust value by 2.
L70B5:  CLC                     ;
L70B6:  ADC ShipXAccel          ;Add thrust to ship's X acceleration.
L70B8:  TAX                     ;Save the acceleration in X.
L70B9:  TYA                     ;
L70BA:  ADC ShipXSpeed          ;Add the acceleration to the ship's X velocity.
L70BD:  JSR ChkShipMaxVel       ;($7125)Ensure ship does not exceed maximum velocity.

L70C0:  STA ShipXSpeed          ;Save current ship X velocity and acceleration.
L70C3:  STX ShipXAccel          ;

L70C5:  LDY #$00                ;Assume ship is facing up (positive Y direction).
L70C7:  LDA ShipDir             ;Get ship direction in preparation for thrust calculation.
L70C9:  JSR CalcThrustDir       ;($77D5)Calculate thrust in Y direction.
L70CC:  BPL UpdateShipYVel      ;Is ship facing up? If so, branch.

L70CE:  DEY                     ;Ship is facing down.  Set Y for negative direction.

UpdateShipYVel:
L70CF:  ASL                     ;Multiply thrust value by 2.
L70D0:  CLC                     ;
L70D1:  ADC ShipYAccel          ;Add thrust to ship's Y acceleration.
L70D3:  TAX                     ;Save the acceleration in X.
L70D4:  TYA                     ;
L70D5:  ADC ShipYSpeed          ;Add the acceleration to the ship's Y velocity.
L70D8:  JSR ChkShipMaxVel       ;($7125)Ensure ship does not exceed maximum velocity.

L70DB:  STA ShipYSpeed          ;Save current ship Y velocity and acceleration.
L70DE:  STX ShipYAccel          ;
L70E0:  RTS                     ;Done calculating ship acceleration.

ShipDecelerate:
L70E1:  LDA #$00                ;Turn off ship thrust SFX.
L70E3:  STA ShipThrustSFX       ;

DecelerateX:
L70E6:  LDA ShipXSpeed          ;Does ship need to be decelerated in the X direction?
L70E9:  ORA ShipXAccel          ;
L70EB:  BEQ DecelerateY         ;If not, branch to check Y deceleration.

L70ED:  LDA ShipXSpeed          ;Get ship X velocity and multiply by 2.
L70F0:  ASL                     ;

L70F1:  LDX #$FF                ;Assume positive X velocity. X acceleration = -1.
L70F3:  CLC                     ;
L70F4:  EOR #$FF                ;Is ship traveling in the positive X direction?
L70F6:  BMI SetXDecelerate      ;If so, branch.

L70F8:  INX                     ;Ship traveling in negative X direction.
L70F9:  SEC                     ;Set X deceleration to +1.

SetXDecelerate:
L70FA:  ADC ShipXAccel          ;Update ship X acceleration.
L70FC:  STA ShipXAccel          ;

L70FE:  TXA                     ;
L70FF:  ADC ShipXSpeed          ;Update ship X velocity.
L7102:  STA ShipXSpeed          ;

DecelerateY:
L7105:  LDA ShipYAccel          ;Does ship need to be decelerated in the Y direction?
L7107:  ORA ShipYSpeed          ;
L710A:  BEQ DecelerateExit      ;If not, branch to exit.

L710C:  LDA ShipYSpeed          ;Get ship Y velocity and multiply by 2.
L710F:  ASL                     ;

L7110:  LDX #$FF                ;Assume positive Y velocity. Y acceleration = -1.
L7112:  CLC                     ;
L7113:  EOR #$FF                ;Is ship traveling in the positive Y direction?
L7115:  BMI SetYDecelerate      ;If so, branch.

L7117:  SEC                     ;Ship traveling in negative Y direction.
L7118:  INX                     ;Set Y deceleration to +1.

SetYDecelerate:
L7119:  ADC ShipYAccel          ;Update ship Y acceleration.
L711B:  STA ShipYAccel          ;

L711D:  TXA                     ;
L711E:  ADC ShipYSpeed          ;Update ship Y velocity.
L7121:  STA ShipYSpeed          ;

DecelerateExit:
L7124:  RTS                     ;Done decelerating the player's ship.

ChkShipMaxVel:
L7125:  BMI ChkMaxNegVel        ;Is ship traveling left/down (negative direction)? If so, branch.

ChkMaxPosVel:
L7127:  CMP #$40                ;Is ship moving less than max velocity in positive direction?
L7129:  BCC ChkMaxExit          ;If so, branch to exit.

L712B:  LDX #$FF                ;Max positive velocity reached. Set acceleration to -1.
L712D:  LDA #$3F                ;Set velocity to max positive value.
L712F:  RTS                     ;

ChkMaxNegVel:
L7130:  CMP #$C0                ;Is ship moving less than max velocity in negative direction?
L7132:  BCS ChkMaxExit          ;If so, branch to exit.

L7134:  LDX #$01                ;Max negative velocity reached. Set acceleration to +1.
L7136:  LDA #$C0                ;Set velocity to max negative value.

ChkMaxExit:
L7138:  RTS                     ;Done checking maximum ship velocity.

;--------------------------------[ Safe Hyperspace Return Routine ]--------------------------------

IsReturnSafe:
L7139:  LDX #ScrIndex           ;Prepare to check all asteroids and saucer.

SafeCheckLoop:
L713B:  LDA AstStatus,X         ;Is current object slot active?
L713E:  BEQ NextSafeCheck       ;If not, branch to move to next object.

SafeCheckX:
L7140:  LDA AstXPosHi,X         ;Get object X position and compare to ship X position.
L7143:  SEC                     ;
L7144:  SBC shipXPosHi          ;
L7147:  CMP #$04                ;Is object within +4 pixels of ship?
L7149:  BCC SafeCheckY          ;If so, branch to check object's Y position.

L714B:  CMP #$FC                ;Is object within -4 pixels of ship?
L714D:  BCC NextSafeCheck       ;If not, branch to check next object's position.

SafeCheckY:
L714F:  LDA AstYPosHi,X         ;Get object Y position and compare to ship Y position.
L7152:  SEC                     ;
L7153:  SBC ShipYPosHi          ;
L7156:  CMP #$04                ;Is object within +4 pixels of ship?
L7158:  BCC SafeCheckFail       ;If so, branch. Not safe to exit hyperspace.

L715A:  CMP #$FC                ;Is object within -4 pixels of ship?
L715C:  BCS SafeCheckFail       ;If so, branch. Not safe to exit hyperspace.

NextSafeCheck:
L715E:  DEX                     ;Is there another object to check?
L715F:  BPL SafeCheckLoop       ;If so, branch to check the object.

SafeCheckSuccess:
L7161:  INX                     ;Safe to exit hyperspace. Sets X to zero.
L7162:  RTS                     ;

SafeCheckFail:
L7163:  INC ShipSpawnTmr        ;Not safe to exit hyperspace. Ensures spawn timer is not zero.
L7166:  RTS                     ;

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L7167:  .byte $90               ;Checksum byte.

;------------------------------[ Initialize Asteroid Wave Variables ]------------------------------

InitWaveVars:
L7168:  LDX #MaxAsteroids       ;Start at highest asteroid status slot.
L716A:  LDA ThmpSpeedTmr        ;Is wave about to start?
L716D:  BNE ZeroAstStatuses     ;If so, branch to skip most of this routine.

L716F:  LDA ScrStatus           ;Is a saucer active?
L7172:  BNE EndInitWave         ;If so, branch to skip this routine.

L7174:  STA SaucerXSpeed        ;Zero out saucer speed.
L7177:  STA SaucerYSpeed        ;
L717A:  INC ScrSpeedup          ;Increment the min number of asteroids that triggers saucers-->
L717D:  LDA ScrSpeedup          ;appearing more frequently.
L7180:  CMP #$0B                ;Max value is 11 asteroids.
L7182:  BCC InitAstPerWave      ;
L7184:  DEC ScrSpeedup          ;Make sure value does not exceed 11 asteroids.

InitAstPerWave:
L7187:  LDA AstPerWave          ;Increase number of asteroids by 2 every wave.
L718A:  CLC                     ;
L718B:  ADC #$02                ;
L718D:  CMP #$0B                ;Ensure 11 asteroids max per wave.
L718F:  BCC SetWaveAst          ;

L7191:  LDA #$0B                ;Max initial asteroids per wave is 11.

SetWaveAst:
L7193:  STA CurAsteroids        ;Set the number of asteroids for the current wave.
L7196:  STA AstPerWave          ;

L7199:  STA GenByte08           ;Create a counter for decrementing through all asteroid slots.
L719B:  LDY #ScrIndex           ;Offset to saucer speed X and Y values.

InitWaveAsteroids:
L719D:  JSR GetRandNum          ;($77B5)Get a random number.
L71A0:  AND #$18                ;Randomly select asteroid type.
L71A2:  ORA #LargeAst           ;Make it a large asteroid.
L71A4:  STA AstStatus,X         ;Store the results.

L71A7:  JSR SetAstVel           ;($7203)Set asteroid X and Y velocities.

L71AA:  JSR GetRandNum          ;($77B5)Get a random number.
L71AD:  LSR                     ;Shift right to save LSB in carry.
L71AE:  AND #$1F                ;Keep lower 5 bits.
L71B0:  BCC AstPosScrBot        ;Is carry clear? If so, start asteroid at top/bottom of screen.

L71B2:  CMP #$18                ;If value beyond max Y position(6144/8=768)?
L71B4:  BCC AstPosScrRght       ;If not, branch to set Y position.

L71B6:  AND #$17                ;Limit Y position to < 768.

AstPosScrRght:
L71B8:  STA AstYPosHi,X         ;Set asteroid Y position.
L71BB:  LDA #$00                ;
L71BD:  STA AstXPosHi,X         ;Set X to 0.  Asteroid originates at left/right of screen.
L71C0:  STA AstXPosLo,X         ;
L71C3:  BEQ NextAstPos          ;Branch always.

AstPosScrBot:
L71C5:  STA AstXPosHi,X         ;Set asteroid X position.
L71C8:  LDA #$00                ;
L71CA:  STA AstYPosHi,X         ;Set Y to 0.  Asteroid originates at top/bottom of screen.
L71CD:  STA AstYPosLo,X         ;

NextAstPos:
L71D0:  DEX                     ;Move to next asteroid index.
L71D1:  DEC GenByte08           ;Are there more asteroid positions to process?
L71D3:  BNE InitWaveAsteroids   ;If so, branch to do another one.

L71D5:  LDA #$7F                ;
L71D7:  STA ScrTimer            ;Set initial saucer timer and thump SFX values.
L71DA:  LDA #$30                ;
L71DC:  STA ThmpOffReload       ;

ZeroAstStatuses:
L71DF:  LDA #$00                ;Zero out the asteroid statuses.
L71E1:* STA AstStatus,X         ;
L71E4:  DEX                     ;More asteroid statuses to zero?
L71E5:  BPL -                   ;If so, branch to do another.

EndInitWave:
L71E7:  RTS                     ;End init variables function.

;------------------------------------[ Center Ship On Screen ]-------------------------------------

CenterShip:
L71E8:  LDA #$60                ;
L71EA:  STA ShipXPosLo          ;Set lower XY ship position bytes for screen center.
L71ED:  STA ShipYPosLo          ;

L71F0:  LDA #$00                ;
L71F2:  STA ShipXSpeed          ;Set ship XY speed to 0.
L71F5:  STA ShipYSpeed          ;

L71F8:  LDA #$10                ;
L71FA:  STA shipXPosHi          ;
L71FD:  LDA #$0C                ;Set upper XY ship position bytes for screen center.
L71FF:  STA ShipYPosHi          ;
L7202:  RTS                     ;

;-----------------------------------[ Set Asteroid Velocities ]------------------------------------

SetAstVel:
L7203:  JSR GetRandNum          ;($77B5)Get a random number.
L7206:  AND #$8F                ;Keep the sign bit and lower nibble.
L7208:  BPL SetAstXVel          ;Is this a negative number?
L720A:  ORA #$F0                ;If so, sign extend the byte.

SetAstXVel:
L720C:  CLC                     ;Add the new X velocity to the old velocity.
L720D:  ADC AstXSpeed,Y         ;

L7210:  JSR GetAstVelocity      ;($7233)Get an X velocity to assign to the asteroid.
L7213:  STA AstXSpeed,X         ;

L7216:  JSR GetRandNum          ;($77B5)Get a random number.
L7219:  JSR GetRandNum          ;($77B5)Get a random number.
L721C:  JSR GetRandNum          ;($77B5)Get a random number.
L721F:  JSR GetRandNum          ;($77B5)Get a random number.
L7222:  AND #$8F                ;Keep the sign bit and lower nibble.
L7224:  BPL SetAstYVel          ;Is this a negative number?
L7226:  ORA #$F0                ;If so, sign extend the byte.

SetAstYVel:
L7228:  CLC                     ;Add the new Y velocity to the old velocity.
L7229:  ADC AstYSpeed,Y         ;

L722C:  JSR GetAstVelocity      ;
L722F:  STA AstYSpeed,X         ;($7233)Get a Y velocity to assign to the asteroid.
L7232:  RTS                     ;

GetAstVelocity:
L7233:  BPL SetPosVel           ;Is speed faster than max speed of -31?
L7235:  CMP #$E1                ;If so, branch to check min negative speed.
L7237:  BCS ChkNegTooSlow       ;

L7239:  LDA #$E1                ;Set max negative speed to -31.

ChkNegTooSlow:
L723B:  CMP #$FB                ;Is value faster than -6?
L723D:  BCC AstVelExit          ;If so, branch to exit.
L723F:  LDA #$FA                ;Set minimum negative speed to -6.
L7241:  RTS                     ;

SetPosVel:
L7242:  CMP #$06                ;Is speed above min speed of +6?
L7244:  BCS ChkPosTooFast       ;If so, branch to check max speed.

L7246:  LDA #$06                ;Set min positive speed to +6.

ChkPosTooFast:
L7248:  CMP #$20                ;Is value greater than +31?
L724A:  BCC AstVelExit          ;If not, branch to exit.
L724C:  LDA #$1F                ;Set max positive speed to +31.

AstVelExit:
L724E:  RTS                     ;Return the velocity in A.

;--------------------------------------[ Update Screen Text ]--------------------------------------

UpdateScreenText:
L724F:  LDA #$10                ;Set global scale=1(*2).
L7251:  STA GlobalScale         ;

L7253:  LDA #>VecCredits        ;Draw copyright text at bottom of the display.
L7255:  LDX #<VecCredits        ;
L7257:  JSR VecRomJSR           ;($7BFC)Load JSR command in vector RAM to vector ROM.

L725A:  LDA #$19                ;X beam coordinate 4 * $19 = $64  = 100.
L725C:  LDX #$DB                ;Y beam coordinate 4 * $DB = $36C = 876.
L725E:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L7261:  LDA #$70                ;Set scale 7(/4).
L7263:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L7266:  LDX #$00                ;Indicate number string should be drawn on the display.
L7268:  LDA NumPlayers          ;Is this a 2 player game?
L726A:  CMP #$02                ;
L726C:  BNE DrawPlr1Score       ;If not, branch to draw just player 1's score without blinking.

L726E:  LDA CurrentPlyr         ;Is player 2 playing?
L7270:  BNE DrawPlr1Score       ;If so, branch to draw player 1's score without blinking.

L7272:  LDX #$20                ;Override the zero blanking function.
L7274:  LDA ShipStatus          ;Is player 1's ship in play or in hyperspace?
L7277:  ORA HyprSpcFlag         ;If so, branch to draw player 1's score without blinking.
L7279:  BNE DrawPlr1Score       ;

L727B:  LDA ShipSpawnTmr        ;Is player 1 waiting to respawn?
L727E:  BMI DrawPlr1Score       ;If so, branch to draw player 1's score without blinking.

L7280:  LDA FrameTimerLo        ;Blink player 1's score every 16 frames.  This occurs-->
L7282:  AND #$10                ;when switching from one player to the next.
L7284:  BEQ DrawShipLives       ;Time to draw the score? If not, branch to turn it off.

DrawPlr1Score:
L7286:  LDA #Plr1ScoreBase      ;Prepare to draw Player 1's score on the display.
L7288:  LDY #$02                ;2 bytes for player 1's score.
L728A:  SEC                     ;Blank leading zeros.
L728B:  JSR DrawNumberString    ;($773F)Draw a string of numbers on the display.

L728E:  LDA #$00                ;Draw a trailing zero.
L7290:  JSR ChkSetDigitPntr     ;($778B)Prepare to draw a trailing zero after the score.

DrawShipLives:
L7293:  LDA #$28                ;X beam coordinate 4 * $28 = $A0 = 160.
L7295:  LDY Plyr1Ships          ;Get current number of reserve ships for Player 1.
L7297:  JSR DrawExtraLives      ;($6F3E)Draw player's reserve ships on the display.

L729A:  LDA #$00                ;Set global scale to 0(*1).
L729C:  STA GlobalScale         ;

L729E:  LDA #$78                ;X beam coordinate 4 * $78 = $1E0 = 480.
L72A0:  LDX #$DB                ;Y beam coordinate 4 * $DB = $36C = 876.
L72A2:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L72A5:  LDA #$50                ;Set scale 5(/16).
L72A7:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L72AA:  LDA #HighScores         ;Prepare to draw the high score on the display.
L72AC:  LDY #$02                ;2 bytes for the high score.
L72AE:  SEC                     ;Blank leading zeros.
L72AF:  JSR DrawNumberString    ;($773F)Draw a string of numbers on the display.

L72B2:  LDA #$00                ;Draw a trailing zero.
L72B4:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L72B7:  LDA #$10                ;Set global scale=1(*2).
L72B9:  STA GlobalScale         ;

L72BB:  LDA #$C0                ;X beam coordinate 4 * $C0 = $300 = 768.
L72BD:  LDX #$DB                ;Y beam coordinate 4 * $DB = $36C = 876.
L72BF:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L72C2:  LDA #$50                ;Set scale 5(/16).
L72C4:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L72C7:  LDX #$00                ;Indicate number string should be drawn on the display.
L72C9:  LDA NumPlayers          ;Is this a 2 player game?
L72CB:  CMP #$01                ;
L72CD:  BEQ EndScreenText       ;If not, branch to exit.

L72CF:  BCC DrawPlr2Score       ;Is a game active? If not, branch to draw player 2's score.

L72D1:  LDA CurrentPlyr         ;Is player 1 playing?
L72D3:  BEQ DrawPlr2Score       ;If so, branch to draw player 2's score without blinking.

L72D5:  LDX #$20                ;Override the zero blanking function.
L72D7:  LDA ShipStatus          ;Is player 2's ship in play or in hyperspace?
L72DA:  ORA HyprSpcFlag         ;If so, branch to draw player 2's score without blinking.
L72DC:  BNE DrawPlr2Score       ;

L72DE:  LDA ShipSpawnTmr        ;Is player 2 waiting to respawn?
L72E1:  BMI DrawPlr2Score       ;If so, branch to draw player 2's score without blinking.

L72E3:  LDA FrameTimerLo        ;Blink player 2's score every 16 frames.  This occurs-->
L72E5:  AND #$10                ;when switching from one player to the next.
L72E7:  BEQ DrawPlr2Ships       ;Time to draw the score? If not, branch to turn it off.

DrawPlr2Score:
L72E9:  LDA #Plr2ScoreBase      ;Prepare to draw Player 2's score on the display.
L72EB:  LDY #$02                ;2 bytes for the high score.
L72ED:  SEC                     ;Blank leading zeros.
L72EE:  JSR DrawNumberString    ;($773F)Draw a string of numbers on the display.

L72F1:  LDA #$00                ;Draw a trailing zero.
L72F3:  JSR ChkSetDigitPntr     ;($778B)Prepare to draw a trailing zero after the score.

DrawPlr2Ships:
L72F6:  LDA #$CF                ;X beam coordinate 4 * $CF = $33C = 828.
L72F8:  LDY Plyr2Ships          ;Get current number of reserve ships for Player 2.
L72FA:  JMP DrawExtraLives      ;($6F3E)Draw player's reserve ships on the display.

EndScreenText:
L72FD:  RTS                     ;Done drawing screen text.

;-------------------------------------[ Draw Object Routines ]-------------------------------------

DrawObject:
L72FE:  STY $00                 ;Save scale data.
L7300:  STX GenByte0D           ;Save a copy of the index to the object to draw.

L7302:  LDA ThisObjXUB          ;
L7304:  LSR                     ;
L7305:  ROR ThisObjXLB          ;
L7307:  LSR                     ;Divide the object's X position by 8.
L7308:  ROR ThisObjXLB          ;
L730A:  LSR                     ;
L730B:  ROR ThisObjXLB          ;
L730D:  STA ThisObjXUB          ;

L730F:  LDA ThisObjYUB          ;
L7311:  CLC                     ;
L7312:  ADC #$04                ;
L7314:  LSR                     ;
L7315:  ROR ThisObjYLB          ;Add 1024 object's Y position and divide by 8.
L7317:  LSR                     ;
L7318:  ROR ThisObjYLB          ;
L731A:  LSR                     ;
L731B:  ROR ThisObjYLB          ;
L731D:  STA ThisObjYUB          ;

L731F:  LDX #$04                ;Prepare to write 4 bytes to vector RAM.
L7321:  JSR SetCURData          ;($7C1C)Write CUR instruction in vector RAM.

L7324:  LDA #$70                ;Set the scale of the object.
L7326:  SEC                     ;
L7327:  SBC $00                 ;
L7329:  CMP #$A0                ;Is the scale 9 or smaller?
L732B:  BCC DrawSpotKill        ;If so, branch.

DrawMultiSpotKill:
L732D:  PHA                     ;Save A on the stack.
L732E:  LDA #$90                ;Set scale 9(/1).
L7330:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.
L7333:  PLA                     ;Restore A from the stack.

L7334:  SEC                     ;Subtract #$10 from scale value.
L7335:  SBC #$10                ;Is value below #$A0?
L7337:  CMP #$A0                ;If not, branch to run the spot kill routine again.
L7339:  BCS DrawMultiSpotKill   ;

DrawSpotKill:
L733B:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L733E:  LDX GenByte0D           ;Restore index to object to draw.
L7340:  LDA AstStatus,X         ;Is the object exploding?
L7343:  BPL DrawObjNoExplode    ;If not, branch to draw the normal object.

L7345:  CPX #ShipIndex          ;Is it the ship exploding?
L7347:  BEQ DrawShipExplode     ;If so, branch.

DrawObjectExplode:
L7349:  AND #$0C                ;Get index into shrapnel table.
L734B:  LSR                     ;
L734C:  TAY                     ;
L734D:  LDA ShrapPatPtrTbl,Y    ;Store JSR data in vector RAM for the Shrapnel graphics.
L7350:  LDX ShrapPatPtrTbl+1,Y  ;
L7353:  BNE SaveObjVecData      ;Branch always.

DrawShipExplode:
L7355:  JSR DoShipExplsn        ;($7465)Draw the ship exploding.
L7358:  LDX GenByte0D           ;Restore index to object being drawn.
L735A:  RTS                     ;Exit after drawing ship fragments.

DrawObjNoExplode:
L735B:  CPX #ShipIndex          ;Is it the ship that needs to be drawn?
L735D:  BEQ DoDrawShip          ;If so, branch.

L735F:  CPX #ScrIndex           ;Is it the saucer that needs to be drawn?
L7361:  BEQ DoDrawSaucer        ;If so, branch.

L7363:  BCS DoDrawBullet        ;Is it a bullet that needs to be drawn? If so, branch.

L7365:  AND #$18                ;Must be an asteroid.
L7367:  LSR                     ;
L7368:  LSR                     ;Get the asteroid type bits.
L7369:  TAY                     ;
L736A:  LDA AstPtrnPtrTbl,Y     ;Get asteroid vector data and write it to vector RAM.
L736D:  LDX AstPtrnPtrTbl+1,Y   ;

SaveObjVecData:
L7370:  JSR VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.
L7373:  LDX GenByte0D           ;Restore index to object.
L7375:  RTS                     ;Finished loading object data into vector RAM.

DoDrawShip:
L7376:  JSR UpdateShipDraw      ;($750B)Update the drawing of the player's ship.
L7379:  LDX GenByte0D           ;Restore index to object.
L737B:  RTS                     ;Finished loading ship data into vector RAM.

DoDrawSaucer:
L737C:  LDA ScrPtrnPtrTbl       ;Get saucer vector data and write it to vector RAM.
L737F:  LDX ScrPtrnPtrTbl+1     ;
L7382:  BNE SaveObjVecData      ;Branch always.

DoDrawBullet:
L7384:  LDA #$70                ;Set scale 7(/4).
L7386:  LDX #$F0                ;Prepare to draw a dot at full brightness(bullet).
L7388:  JSR DrawDot             ;($7CE0)Draw a dot on the screen.

L738B:  LDX GenByte0D           ;Restore index to object.
L738D:  LDA FrameTimerLo        ;Decrement shot timer every 4th frame.
L738F:  AND #$03                ;Is it time to decrement the shot timer?
L7391:  BNE DrawObjectDone      ;If not, branch.

L7393:  DEC AstStatus,X         ;Decrement shot timer.

DrawObjectDone:
L7396:  RTS                     ;Done with object vector data.

;-----------------------------------------[ Update Score ]-----------------------------------------

UpdateScore:
L7397:  SED                     ;Put ALU into decimal mode.

L7398:  ADC PlayerScores,X      ;Add value in Accumulator to score.
L739A:  STA PlayerScores,X      ;Does upper byte need to be updated?
L739C:  BCC UpdateScoreExit     ;If not, branch to exit.

L739E:  LDA PlayerScores+1,X    ;
L73A0:  ADC #$00                ;Increment upper score byte.
L73A2:  STA PlayerScores+1,X    ;

L73A4:  AND #$0F                ;Check if extra life should be granted.
L73A6:  BNE UpdateScoreExit     ;Extra life granted at 10,000 points.

L73A8:  LDA #$B0                ;Play extra life SFX.
L73AA:  STA ExLfSFXTimer        ;
L73AC:  LDX CurrentPlyr         ;Increment reserve ships.
L73AE:  INC Plyr1Ships,X        ;

UpdateScoreExit:
L73B0:  CLD                     ;Put ALU back into binary mode.
L73B1:  RTS                     ;

;-------------------------------------------[ Swap RAM ]-------------------------------------------

SwapRAM:
L73B2:  LDA CurrentPlyr         ;Get current player (0 or 1 value).
L73B4:  ASL                     ;
L73B5:  ASL                     ;
L73B6:  STA GenByte08           ;Move the LSB to the third bit position.

L73B8:  LDA MultiPurpBits       ;
L73BA:  AND #$FB                ;
L73BC:  ORA GenByte08           ;Set the player RAM based on the current player.
L73BE:  STA MultiPurpBits       ;
L73C0:  STA MultiPurp           ;
L73C3:  RTS                     ;

;------------------------------------[ Draw High Scores List ]-------------------------------------

ChkHghScrList:
L73C4:  LDA NumPlayers          ;Is a game currently being played?
L73C6:  BEQ ChkDrawScrList      ;If not, branch to see if its time to show the high score list.

SkipScrList:
L73C8:  CLC                     ;Indicate the high scores list is not being displayed.
L73C9:  RTS                     ;Exit high score list drawing routines.

ChkDrawScrList:
L73CA:  LDA FrameTimerHi        ;Is it time to draw the high scores list?
L73CC:  AND #$04                ;
L73CE:  BNE SkipScrList         ;If not, branch to exit.

L73D0:  LDA HiScoreBcdLo        ;Is the high scores list empty?
L73D2:  ORA HiScoreBcdHi        ;
L73D4:  BEQ SkipScrList         ;If so, branch to exit.

L73D6:  LDY #HghScrText         ;Prepare to display HIGH SCORES text.
L73D8:  JSR WriteText           ;($77F6)Write text to the display.

L73DB:  LDX #$00                ;Start at the first high score index.
L73DD:  STX InitialIndex        ;Start at the first initial index.

L73DF:  LDA #$01                ;Appears not to be used.
L73E1:  STA GenByte00           ;

L73E3:  LDA #$A7                ;Y beam coordinate = 4 * $A7 = $29C = 668.
L73E5:  STA HiScrBeamYLoc       ;Set top row of high score list.

L73E7:  LDA #$10                ;Set global scale=1(*2).
L73E9:  STA GlobalScale         ;

HighScoresLoop:
L73EB:  LDA HiScoreBcdLo,X      ;Is there a high score at the current location?
L73ED:  ORA HiScoreBcdHi,X      ;
L73EF:  BEQ HighScoreExit       ;If not, done with high score list. Branch to exit.

L73F1:  STX HiScrIndex          ;Store index to the current high score.

L73F3:  LDA #$5F                ;X beam coordinate 4 * $5F = $17C = 380.
L73F5:  LDX HiScrBeamYLoc       ;Set the Y beam coordinate based on current line being written.
L73F7:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L73FA:  LDA #$40                ;Set scale 4(/32).
L73FC:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L73FF:  LDA HiScrIndex          ;Get index to current high score to draw.
L7401:  LSR                     ;

L7402:  SED                     ;
L7403:  ADC #$01                ;Increment by 1 (base 10).
L7405:  CLD                     ;

L7406:  STA HiScrRank           ;Get the rank number of the current high score.
L7408:  LDA #HiScrRank          ;

L740A:  SEC                     ;Blank leading zeros.
L740B:  LDY #$01                ;Single byte for player's rank.
L740D:  LDX #$00                ;No override of zero blanking.
L740F:  JSR DrawNumberString    ;($773F)Draw a string of numbers on the display.

L7412:  LDA #$40                ;Set the brightness of the dot.
L7414:  TAX                     ;
L7415:  JSR DrawDot             ;($7CE0)Draw a dot on the screen.

L7418:  LDY #$00                ;Draw a SPACE on the display.
L741A:  JSR DrawChar            ;($6F35)Draw a single character on the display.

L741D:  LDA HiScrIndex          ;Move to next high score to draw.
L741F:  CLC                     ;
L7420:  ADC #HighScores         ;Prepare to draw next high score on the display.

L7422:  LDY #$02                ;2 bytes per high score.
L7424:  SEC                     ;Blank leading zeros.
L7425:  LDX #$00                ;No override of zero blanking.
L7427:  JSR DrawNumberString    ;($773F)Draw a string of numbers on the display.

L742A:  LDA #$00                ;Draw a trailing zero.
L742C:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L742F:  LDY #$00                ;Draw a SPACE on the display.
L7431:  JSR DrawChar            ;($6F35)Draw a single character on the display.

L7434:  LDY InitialIndex        ;Draw the first initial of this high score.
L7436:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L7439:  INC InitialIndex        ;Draw the second initial of this high score.
L743B:  LDY InitialIndex        ;
L743D:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L7440:  INC InitialIndex        ;Draw the third initial of this high score.
L7442:  LDY InitialIndex        ;
L7444:  JSR DrawInitial         ;($6F1A)Draw a single initial on the display.

L7447:  INC InitialIndex        ;Move to the next initial index.

L7449:  LDA HiScrBeamYLoc       ;
L744B:  SEC                     ;Move down to the next high score row on the display.
L744C:  SBC #$08                ;
L744E:  STA HiScrBeamYLoc       ;

L7450:  LDX HiScrIndex          ;Move to the next high score slot.
L7452:  INX                     ;
L7453:  INX                     ;Have all 10 high scores been drawn on the display?
L7454:  CPX #$14                ;If not, branch to draw the next one.
L7456:  BCC HighScoresLoop      ;

HighScoreExit:
L7458:  SEC                     ;Indicate the high scores list is being displayed.
L7459:  RTS                     ;Exit high score list drawing routines.

;----------------------------------[ Find A Free Asteroid Slot ]-----------------------------------

GetFreeAstSlot:
L745A:  LDX #MaxAsteroids       ;Prepare to check 27 asteroid slots.

NextAstSlotLoop:
L745C:  LDA AstStatus,X         ;Is this slot free?
L745F:  BEQ EndFreeAstSlot      ;If so, exit. A free slot is available.

L7461:  DEX                     ;More slots to test?
L7462:  BPL NextAstSlotLoop     ;If so, branch to check the next slot.

EndFreeAstSlot:
L7464:  RTS                     ;Asteroid slot found or no slot available.

;-----------------------------------[ Ship Explosion Routines ]------------------------------------

DoShipExplsn:
L7465:  LDA ShipStatus          ;Is this the first frame of the ship explosion?
L7468:  CMP #$A2                ;If so, load the initial debris data.
L746A:  BCS GetNumDebris        ;If not, branch to skip loading data.

L746C:  LDX #$0A                ;Prepare to load 12 values from ShipExpVelTbl.

LoadShipExplLoop:
L746E:  LDA ShipExpVelTbl,X     ;Get byte of ship debris X velocity.
L7471:  LSR                     ;
L7472:  LSR                     ;
L7473:  LSR                     ;Save only the upper nibble and shift to lower nibble.
L7474:  LSR                     ;
L7475:  CLC                     ;
L7476:  ADC #$F8                ;Sign extend the nibble to fill the whole byte.
L7478:  EOR #$F8                ;
L747A:  STA ShpDebrisXVelUB,X   ;Save signed value into RAM.

L747C:  LDA ShipExpVelTbl+1,X   ;Get byte of ship debris Y velocity.
L747F:  LSR                     ;
L7480:  LSR                     ;
L7481:  LSR                     ;Save only the upper nibble and shift to lower nibble.
L7482:  LSR                     ;
L7483:  CLC                     ;
L7484:  ADC #$F8                ;Sign extend the nibble to fill the whole byte.
L7486:  EOR #$F8                ;
L7488:  STA ShpDebrisYVelUB,X   ;Save signed value into RAM.

L748A:  DEX                     ;Move to next 2 bytes in the table.
L748B:  DEX                     ;Are there more bytes to load from the table?
L748C:  BPL LoadShipExplLoop    ;if so, loop to load 2 more bytes.

GetNumDebris:
L748E:  LDA ShipStatus          ;
L7491:  EOR #$FF                ;
L7493:  AND #$70                ;Calculate the pointer into the ship debris data based-->
L7495:  LSR                     ;on the ship status counter.  This has the effect of making-->
L7496:  LSR                     ;the debris disappear one by one over time.
L7497:  LSR                     ;
L7498:  TAX                     ;

ShipDebrisLoop:
L7499:  STX ShipDebrisPtr       ;Update ship debris index.

L749B:  LDY #$00                ;Assume the X velocity for this debris piece is positive.
L749D:  LDA ShipExpVelTbl,X     ;Is the debris piece moving in a positive X direction?
L74A0:  BPL GetDebrisXVel       ;If so, branch.

L74A2:  DEY                     ;The X velocity for this debris piece is negative.

GetDebrisXVel:
L74A3:  CLC                     ;Update fractional part of debris X position.
L74A4:  ADC ShpDebrisXVelLB,X   ;
L74A6:  STA ShpDebrisXVelLB,X   ;
L74A8:  TYA                     ;
L74A9:  ADC ShpDebrisXVelUB,X   ;Update integer part of debris X position.
L74AB:  STA ShpDebrisXVelUB,X   ;
L74AD:  STA ThisDebrisXLB       ;Save current debris X position.
L74AF:  STY ThisDebrisXUB       ;Save current debris X direction.

L74B1:  LDY #$00                ;Assume the Y velocity for this debris piece is positive.
L74B3:  LDA ShipExpVelTbl+1,X   ;Is the debris piece moving in a positive Y direction?
L74B6:  BPL GetDebrisYVel       ;If so, branch.

L74B8:  DEY                     ;The Y velocity for this debris piece is negative.

GetDebrisYVel:
L74B9:  CLC                     ;Update fractional part of debris Y position.
L74BA:  ADC ShpDebrisYVelLB,X   ;
L74BC:  STA ShpDebrisYVelLB,X   ;
L74BE:  TYA                     ;
L74BF:  ADC ShpDebrisYVelUB,X   ;Update integer part of debris Y position.
L74C1:  STA ShpDebrisYVelUB,X   ;
L74C3:  STA ThisDebrisYLB       ;Save current debris Y position.
L74C5:  STY ThisDebrisYUB       ;Save current debris Y direction.

L74C7:  LDA VecRamPtrLB         ;
L74C9:  STA VecPtrLB_           ;Save a copy of the vector RAM pointer.
L74CB:  LDA VecRamPtrUB         ;
L74CD:  STA VecPtrUB_           ;

L74CF:  JSR CalcDebrisPos       ;($7C49)Calculate the position of the exploded ship pieces.

L74D2:  LDY ShipDebrisPtr       ;Write the ship debris vector data to the vector RAM.
L74D4:  LDA ShipExpPtrTbl,Y     ;
L74D7:  LDX ShipExpPtrTbl+1,Y   ;
L74DA:  JSR VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

L74DD:  LDY ShipDebrisPtr       ;Draw the exact same line from above except backwards.
L74DF:  LDA ShipExpPtrTbl+1,Y   ;
L74E2:  EOR #$04                ;Backtrack in the Y direction.
L74E4:  TAX                     ;
L74E5:  LDA ShipExpPtrTbl,Y     ;
L74E8:  AND #$0F                ;Set the brightness of the backtracked vector to 0.
L74EA:  EOR #$04                ;Backtrack in the X direction.
L74EC:  JSR VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

L74EF:  LDY #$FF                ;Prepare to write 4 bytes to vector RAM.

VecBackTrack:
L74F1:  INY                     ;Get position of the data where this function first started-->
L74F2:  LDA (VecPtr_),Y         ;writing to vector RAM.
L74F4:  STA (VecRamPtr),Y       ;Copy the data again into the current position in vector RAM-->
L74F6:  INY                     ;Except draw it backwards to backtrack the XY position to-->
L74F7:  LDA (VecPtr_),Y         ;the starting point.
L74F9:  EOR #$04                ;Draw the exact same line from CalcDebrisPos except backwards.
L74FB:  STA (VecRamPtr),Y       ;This places the pointer back to the middle of the ship's position.
L74FD:  CPY #$03                ;Does the second word of the VEC opcode need to be written?
L74FF:  BCC VecBackTrack        ;If so, branch to write second word.

L7501:  JSR VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

L7504:  LDX ShipDebrisPtr       ;Move to next pair of ship debris data.
L7506:  DEX                     ;
L7507:  DEX                     ;Is there more ship debris data to process?
L7508:  BPL ShipDebrisLoop      ;If so, branch.

L750A:  RTS                     ;End ship debris routine.

;-------------------------------[ Update The Player's Ship Drawing ]-------------------------------

UpdateShipDraw:
L750B:  LDX #$00                ;Used for inverting index into ship direction table.
L750D:  STX ShipDrawUnused      ;Always 0.  Not used for anything.

L750F:  LDY #$00                ;Assume ship is pointing up.
L7511:  LDA ShipDir             ;Is ship pointing down?
L7513:  BPL SaveShipDir         ;If not, branch.

InvertShipY:
L7515:  LDY #$04                ;Set value indicating ship Y direction is inverted.
L7517:  TXA                     ;
L7518:  SEC                     ;Subtract ship direction from #$00 to invert index into-->
L7519:  SBC ShipDir             ;ShipDirPtrTbl

SaveShipDir:
L751B:  STA GenByte08           ;Save current index calculations.
L751D:  BIT GenByte08           ;Is ship pointing down and left?
L751F:  BMI InvertShipX         ;If so, branch to invert X axis of ship.

L7521:  BVC SetShipInvAxes      ;Is ship pointing up and left? If not, branch.

InvertShipX:
L7523:  LDX #$04                ;Set value indicating ship X direction is inverted.
L7525:  LDA #$80                ;
L7527:  SEC                     ;Subtract modified ship direction from #$80 to get-->
L7528:  SBC GenByte08           ;proper index into ShipDirPtrTbl.

SetShipInvAxes:
L752A:  STX ShipDrawXInv        ;Save the X and Y axis inversion indicators.
L752C:  STY ShipDrawYInv        ;

L752E:  LSR                     ;
L752F:  AND #$FE                ;Do final calculations on index for ShipDirPtrTbl.
L7531:  TAY                     ;

L7532:  LDA ShipDirPtrTbl,Y     ;Get pointer to ship vector data for current direction.
L7535:  LDX ShipDirPtrTbl+1,Y   ;
L7538:  JSR DrawShip            ;($6AD3)Draw the Player's ship on the display.

L753B:  LDA ThrustSw            ;Is the thrust button being pressed?
L753E:  BPL EndUpdShpDraw       ;If not, branch to exit.

L7540:  LDA FrameTimerLo        ;Show thrust animation every 4th frame.
L7542:  AND #$04                ;Is this the fourth frame?
L7544:  BEQ EndUpdShpDraw       ;If not, branch to exit.

L7546:  INY                     ;Prepare to move vector ROM pointer to thrust data.
L7547:  INY                     ;
L7548:  SEC                     ;
L7549:  LDX VecPtrUB_           ;Increment vector ROM pointer by 2 bytes.
L754B:  TYA                     ;
L754C:  ADC VecPtrLB_           ;Pointer is now at thrust vector data.
L754E:  BCC DrawShipThrust      ;Draw thrust vectors on the display.

L7550:  INX                     ;Increment the upper byte of the vector data pointer.

DrawShipThrust:
L7551:  JSR DrawShip            ;($6AD3)Draw the Player's ship on the display.

EndUpdShpDraw:
L7554:  RTS                     ;Finished updating the ship and thrust graphics.

;-------------------------------------[ SFX Control Routines ]-------------------------------------

ChkUpdateSFX:
L7555:  LDA NumPlayers          ;Is an active game in progress?
L7557:  BNE UpdateSFX           ;If so, branch to update SFX.
L7559:  RTS                     ;

UpdateSFX:
L755A:  LDX #$00                ;Prepare to turn off saucer SFX if it is exploding or not present.
L755C:  LDA ScrStatus           ;Is a saucer currently exploding?
L755F:  BMI UpdateScrSFX        ;If so, branch.

L7561:  BEQ UpdateScrSFX        ;Is a saucer present? If not, branch to ensure the SFX is off.

L7563:  ROR                     ;
L7564:  ROR                     ;Use saucer size to set proper saucer SFX.
L7565:  ROR                     ;
L7566:  STA SaucerSFXSel        ;

L7569:  LDX #$80                ;Turn on saucer SFX.

UpdateScrSFX:
L756B:  STX SaucerSFX           ;Enable/disable saucer SFX.

L756E:  LDX #$01                ;Select the saucer fire SFX.
L7570:  JSR StartSFXTimer       ;($75CD)Start SFX timer, if applicable.
L7573:  STA SaucerFireSFX       ;Store updated status of the SFX.

L7576:  DEX                     ;Select the ship fire SFX.
L7577:  JSR StartSFXTimer       ;($75CD)Start SFX timer, if applicable.
L757A:  STA ShipFireSFX         ;Store updated status of the SFX.

L757D:  LDA ShipStatus          ;Is the ship currently on the screen?
L7580:  CMP #$01                ;
L7582:  BEQ ChkNumAsteroids     ;If so, branch.

L7584:  TXA                     ;Load A with #$00. No ship on the screen.
L7585:  STA ShipThrustSFX       ;Turn off the thrust SFX.

ChkNumAsteroids:
L7588:  LDA CurAsteroids        ;Are there asteroids left in this wave?
L758B:  BEQ ThumpSFXOff         ;If not, branch to reset thump SFX.

L758D:  LDA ShipStatus          ;Is the ship exploding?
L7590:  BMI ThumpSFXOff         ;If so, branch to reset the thump SFX.

L7592:  ORA HyprSpcFlag         ;Is the ship not active and not in hyperspace?
L7594:  BEQ ThumpSFXOff         ;If so, branch to reset the thump SFX.

L7596:  LDA ThmpOnTime          ;Is the thump SFX currently playing?
L7598:  BEQ ChkThumpOffTime     ;If not, branch.

L759A:  DEC ThmpOnTime          ;Decrement thump on timer.
L759C:  BNE ChkExplTimer        ;Is thump on timer still active? if so, branch.

ThumpSFXOff:
L759E:  LDA ThisVolFreq         ;
L75A0:  AND #$0F                ;Turn off the thump SFX.
L75A2:  STA ThisVolFreq         ;
L75A4:  STA ThumpFreqVol        ;

L75A7:  LDA ThmpOffReload       ;
L75AA:  STA ThumpOffTime        ;Set thump off timer to max value.
L75AC:  BPL ChkExplTimer        ;

ChkThumpOffTime:
L75AE:  DEC ThumpOffTime        ;Decrement the thump off timer.
L75B0:  BNE ChkExplTimer        ;Is it time to turn thump SFX back on? If not, branch.

ThumpSFXOn:
L75B2:  LDA #$04                ;Set the thump on timer.
L75B4:  STA ThmpOnTime          ;

L75B6:  LDA ThisVolFreq         ;
L75B8:  EOR #$14                ;Toggle the thump volume bit on and set the frequency.
L75BA:  STA ThisVolFreq         ;
L75BC:  STA ThumpFreqVol        ;

ChkExplTimer:
L75BF:  LDA ExplsnSFXTimer      ;
L75C1:  TAX                     ;Is the explosion SFX timer active?
L75C2:  AND #$3F                ;If not, branch to skip decrementing it.
L75C4:  BEQ UpdateExplTimer     ;

L75C6:  DEX                     ;Decrement explosion SFX timer.

UpdateExplTimer:
L75C7:  STX ExplsnSFXTimer      ;
L75C9:  STX ExpPitchVol         ;Update explosion timer, pitch and volume.
L75CC:  RTS                     ;

StartSFXTimer:
L75CD:  LDA ShipFireSFX_,X      ;If the selected SFX active?
L75CF:  BMI ChkSFXTimer         ;If so, branch to check SFX timer status.

L75D1:  LDA SFXTimers,X         ;Is the selected SFX timer currently active?
L75D3:  BPL TurnOffSFX          ;If so, branch to turn it off.

L75D5:  LDA #$10                ;Initialize the timer for the selected SFX.
L75D7:  STA SFXTimers,X         ;

TurnOnSFX:
L75D9:  LDA #$80                ;Turn on the selected SFX.
L75DB:  BMI UpdateSFXStatus     ;Branch always.

ChkSFXTimer:
L75DD:  LDA SFXTimers,X         ;Get the tier value for the selected SFX.
L75DF:  BEQ TurnOffSFX          ;Is the timer expired? If so, branch to turn off.

L75E1:  BMI TurnOffSFX          ;Has the timer gone negative, if so, branch to turn off. 

L75E3:  DEC SFXTimers,X         ;Decrement the selected SFX timer.
L75E5:  BNE TurnOnSFX           ;Is the timer still active? If so, branch to turn SFX on.

TurnOffSFX:
L75E7:  LDA #$00                ;Turn off the selected SFX.

UpdateSFXStatus:
L75E9:  STA ShipFireSFX_,X      ;Update the SFX status.
L75EB:  RTS                     ;

;----------------------------------------[ Split Asteroid ]----------------------------------------

BreakAsteroid:
L75EC:  STX GenByte0D           ;Save a copy of the object 1 index.

L75EE:  LDA #$50                ;Set asteroid break timer to 80 frames.
L75F0:  STA AstBreakTimer       ;

L75F3:  LDA AstStatus,Y         ;
L75F6:  AND #$78                ;Save the asteroid status except the size. 
L75F8:  STA GenByte0E           ;

L75FA:  LDA AstStatus,Y         ;Reduce the asteroid size by 1.
L75FD:  AND #$07                ;
L75FF:  LSR                     ;
L7600:  TAX                     ;Does the asteroid still exist?
L7601:  BEQ SaveAstStatus       ;If not, branch to skip combining size with status.

L7603:  ORA GenByte0E           ;Combine the other asteroid properties with the new size.

SaveAstStatus:
L7605:  STA AstStatus,Y         ;Save the status of the new asteroid back into RAM.

L7608:  LDA NumPlayers          ;Is a game currently being played?
L760A:  BEQ SplitAsteroid       ;If not, branch to skip updating score.

AstScoreUpdate:
L760C:  LDA GenByte0D           ;Did the ship crash into the asteroid?
L760E:  BEQ DoAstScore          ;If so, branch to add points to score.

L7610:  CMP #$04                ;Was it a saucer or saucer bullet that hit the asteroid?
L7612:  BCC SplitAsteroid       ;If so, branch to skip updating the score.

DoAstScore:
L7614:  LDA AstPointsTbl,X      ;Get asteroid points from table based on asteroid size.
L7617:  LDX ScoreIndex          ;
L7619:  CLC                     ;
L761A:  JSR UpdateScore         ;($7397)Add points to the current player's score.

SplitAsteroid:
L761D:  LDX AstStatus,Y         ;Was the asteroid completely destroyed?
L7620:  BEQ BreakAstEnd         ;If so, branch to end. Asteroid not split.

L7622:  JSR GetFreeAstSlot      ;($745A)Find a free asteroid slot.
L7625:  BMI BreakAstEnd         ;Was a free slot available? If not, branch to end.

L7627:  INC CurAsteroids        ;Increment total number of asteroids.
L762A:  JSR UpdateAsteroid      ;($6A9D)Update new asteroid.
L762D:  JSR SetAstVel           ;($7203)Set asteroid X and Y velocities.

L7630:  LDA AstXSpeed,X         ;Get lower 5 bits asteroid X velocity and * 2.
L7633:  AND #$1F                ;
L7635:  ASL                     ;
L7636:  EOR AstXPosLo,X         ;Use this value to offset the X position of the new asteroid.
L7639:  STA AstXPosLo,X         ;

L763C:  JSR NextAstSlotLoop     ;($745C)Find a free asteroid slot.
L763F:  BMI BreakAstEnd         ;Was a free slot found? If not, branch to exit.

L7641:  INC CurAsteroids        ;Increment total number of asteroids.
L7644:  JSR UpdateAsteroid      ;($6A9D)Update new asteroid.
L7647:  JSR SetAstVel           ;($7203)Set asteroid X and Y velocities.

L764A:  LDA AstYSpeed,X         ;Get lower 5 bits asteroid Y velocity and * 2.
L764D:  AND #$1F                ;
L764F:  ASL                     ;
L7650:  EOR AstYPosLo,X         ;Use this value to offset the Y position of the new asteroid.
L7653:  STA AstYPosLo,X         ;

BreakAstEnd:
L7656:  LDX GenByte0D           ;Restore the object 1 index before exiting function.
L7658:  RTS                     ;

;The following table contains the points awarded for the different asteroid sizes.

AstPointsTbl:
L7659:  .byte SmallAstPnts, MedAstPnts, LargeAstPnts

;------------------------------------[ Check For High Score ]--------------------------------------

CheckHighScore:
L765C:  LDA NumPlayers          ;Is a game currently being played?
L765E:  BPL ChkHghScrEnd        ;If not, branch to end.

L7660:  LDX #$02                ;Start with player 2's score.

L7662:  STA FrameTimerHi        ;
L7664:  STA Plyr1Rank           ;Reset the frame timer and player's ranks.
L7666:  STA Plyr2Rank           ;

PlyrScoreLoop:
L7668:  LDY #$00                ;Start at the beginning of the high scores list.

ChkHighScoreLoop:
L766A:  LDA HighScores_,Y       ;Compare the player's score with each entry in the high-->
L766D:  CMP PlayerScores,X      ;score list.
L766F:  LDA HighScores_+1,Y     ;
L7672:  SBC PlayerScores+1,X    ;Is the player's score higher than the current score entry?
L7674:  BCC PayerHighScore      ;If so, branch to add player to the list.

L7676:  INY                     ;Move to next entry in the high score table.
L7677:  INY                     ;
L7678:  CPY #$14                ;Have all 10 entries been checked(2 bytes per entry)?
L767A:  BCC ChkHighScoreLoop    ;If no, branch to check the next entry.

NextPlayerScore:
L767C:  DEX                     ;Move to next player to check their score.
L767D:  DEX                     ;Is there another player to check?
L767E:  BPL PlyrScoreLoop       ;If so, branch.

L7680:  LDA Plyr2Rank           ;Did player 2 get a high score?
L7682:  BMI FinishHghScore      ;If not, branch to wrap up this routine.

L7684:  CMP Plyr1Rank           ;Did player 1 get a better score than player 2?
L7686:  BCC FinishHghScore      ;If not, branch to wrap up this routine.

L7688:  ADC #$02                ;Did player 1 make the last ranking?
L768A:  CMP #$1E                ;
L768C:  BCC SetPlyrRank         ;If not, branch so both players can enter scores.

L768E:  LDA #$FF                ;Player 2's score is scrubbed as it is 11th place.

SetPlyrRank:
L7690:  STA Plyr2Rank           ;Set player 2's rank.

FinishHghScore:
L7692:  LDA #$00                ;
L7694:  STA NumPlayers          ;Indicate game is over and prepare to enter high score initials.
L7696:  STA ThisInitial         ;

ChkHghScrEnd:
L7698:  RTS                     ;Done checking for high a score.

PayerHighScore:
L7699:  STX GenByte0B           ;Store index to current player being processed.
L769B:  STY GenByte0C           ;Store index into high scores table.

L769D:  TXA                     ;
L769E:  LSR                     ;Calculate player's rank(each rank increments by 3).
L769F:  TAX                     ;

L76A0:  TYA                     ;
L76A1:  LSR                     ;Calculate index into high scores initials table.
L76A2:  ADC GenByte0C           ;

L76A4:  STA GenByte0D           ;Store index into high scores initials.
L76A6:  STA Plyr1Rank,X         ;Store player's rank.

L76A8:  LDX #$1B                ;Start at lowest initials to preserve(rank 9).
L76AA:  LDY #$12                ;Start at lowest score to preserve(rank 9).

ShiftScoresLoop:
L76AC:  CPX GenByte0D           ;Has the the player's slot been reached in the high scores list?
L76AE:  BEQ ClearInitials       ;If so, branch to end shifting ranks.

L76B0:  LDA ThisInitial,X       ;
L76B2:  STA HighScoreIntls,X    ;
L76B4:  LDA Plyr1Rank,X         ;Get initials in high score table and move them down a rank.
L76B6:  STA HighScoreIntls+1,X  ;
L76B8:  LDA Plyr2Rank,X         ;
L76BA:  STA HighScoreIntls+2,X  ;

L76BC:  LDA HighScores_-2,Y     ;
L76BF:  STA HighScores_,Y       ;Get score in high score table and move it down a rank.
L76C2:  LDA HighScores_-1,Y     ;
L76C5:  STA HighScores_+1,Y     ;

L76C8:  DEY                     ;Move to next score in table.
L76C9:  DEY                     ;

L76CA:  DEX                     ;
L76CB:  DEX                     ;Move to next initials in table.
L76CC:  DEX                     ;

L76CD:  BNE ShiftScoresLoop     ;More scores to shift down the ranks? If so, branch.

ClearInitials:
L76CF:  LDA #$0B                ;Set first initial to A.
L76D1:  STA HighScoreIntls,X    ;
L76D3:  LDA #$00                ;Set second and third initial to SPACE.
L76D5:  STA HighScoreIntls+1,X  ;
L76D7:  STA HighScoreIntls+2,X  ;

L76D9:  LDA #$F0                ;Set frame timer for displaying initials.
L76DB:  STA FrameTimerHi        ;

L76DD:  LDX GenByte0B           ;Load index to current player being processed.
L76DF:  LDY GenByte0C           ;Load player's index into high score table.

L76E1:  LDA PlayerScores+1,X    ;
L76E3:  STA HiScoreBcdHi_,Y     ;Transfer player's score into the high score table.
L76E6:  LDA PlayerScores,X      ;
L76E8:  STA HiScoreBcdLo_,Y     ;

L76EB:  LDY #$00                ;Branch always to check next player's score.
L76ED:  BEQ NextPlayerScore     ;

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L76EF:  .byte $6E               ;Checksum byte.

;-----------------------------[ Calculate Small Saucer Shot Velocity ]-----------------------------

CalcScrShotDir:
L76F0:  TYA                     ;Load the Y distance between the saucer and the ship.
L76F1:  BPL ScrShotXDir         ;Is Y direction positive? If so, branch to do X direction.

L76F3:  JSR TwosCompliment      ;($7708)Calculate the 2's compliment of the Y distance.

L76F6:  JSR ScrShotXDir         ;($76FC)Calculate the X direction of the saucer shot.
L76F9:  JMP TwosCompliment      ;($7708)Calculate the 2's compliment of the value in A.

ScrShotXDir:
L76FC:  TAY                     ;Save the modified Y shot distance. 
L76FD:  TXA                     ;Get the the raw X shot distance.
L76FE:  BPL CalcScrShotAngle    ;Is X direction positive? If so, branch to calculate shot angle.

L7700:  JSR TwosCompliment      ;($7708)Calculate the 2's compliment of the value in A.
L7703:  JSR CalcScrShotAngle    ;($770E)Calculate the small saucer's shot angle.
L7706:  EOR #$80                ;Set the appropriate quadrant for the bullet.

;----------------------------------------[ 2's Compliment ]----------------------------------------

TwosCompliment:
L7708:  EOR #$FF                ;
L770A:  CLC                     ;Calculate the 2's compliment of the value in A.
L770B:  ADC #$01                ;
L770D:  RTS                     ;

;------------------------------[ Calculate Small Saucer Shot Angle ]-------------------------------

CalcScrShotAngle:
L770E:  STA ShotXYDistance      ;Store shot modified X distance.
L7710:  TYA                     ;
L7711:  CMP ShotXYDistance      ;Is X and Y distance the same?
L7713:  BEQ ShotAngle45         ;If so, angle is 45 degrees.  Branch to set and exit.

L7715:  BCC LookUpAngle         ;Is angle in lower 45 degrees of quadrant? if so, branch.

L7717:  LDY ShotXYDistance      ;Swap X and Y components as the shot is-->
L7719:  STA ShotXYDistance      ;in the upper 45 degrees of the quadrant.
L771B:  TYA                     ;
L771C:  JSR LookUpAngle         ;($7728)Look up angle but return to find proper quadrant.

L771F:  SEC                     ;Set the appropriate quadrant for the bullet.
L7720:  SBC #$40                ;
L7722:  JMP TwosCompliment      ;($7708)Calculate the 2's compliment of the value in A.

ShotAngle45:
L7725:  LDA #$20                ;Player's ship is at a 45 degree angle to the saucer.
L7727:  RTS                     ;

LookUpAngle:
L7728:  JSR FindScrAngleIndex   ;($776C)Find the index in the table below for the shot angle.
L772B:  LDA ShotAngleTbl,X      ;
L772E:  RTS                     ;Look up the proper angle and exit.

;The following table divides 45 degrees of a circle into 16 pieces.  Its used to calculate
;the direction of a bullet from a small saucer to the player's ship.  The other angles in
;the circle are derived from this table.

ShotAngleTbl:
L772F:  .byte $00, $02, $05, $07, $0A, $0C, $0F, $11, $13, $15, $17, $19, $1A, $1C, $1D, $1F 

;-----------------------------------[ Draw A String Of Numbers ]-----------------------------------

DrawNumberString:
L773F:  PHP                     ;Save carry bit status.
L7740:  STX ZeroBlankBypass     ;Save flag indicating if Zero blank should be overridden.
L7742:  DEY                     ;Adjust index so it is a zero based index.
L7743:  STY BCDIndex            ;
L7745:  CLC                     ;
L7746:  ADC BCDIndex            ;Use index to calculate actual address of BCD data byte.
L7748:  STA BCDAddress          ;
L774A:  PLP                     ;Restore carry bit status.

L774B:  TAX                     ;Get address to BCD byte to draw.

DrawNumStringLoop:
L774C:  PHP                     ;Save carry bit status.
L774D:  LDA $00,X               ;
L774F:  LSR                     ;
L7750:  LSR                     ;Get upper BCD digit to draw.
L7751:  LSR                     ;
L7752:  LSR                     ;
L7753:  PLP                     ;Restore carry bit status
L7754:  JSR SetDigitVecPtr      ;($7785)Set vector RAM pointer to digit JSR.

L7757:  LDA BCDIndex            ;Is this the lower byte of the digit string?
L7759:  BNE DoLowerDigit        ;If so, disable zero blank function.

L775B:  CLC                     ;Draw zeros, if present.

DoLowerDigit:
L775C:  LDX BCDAddress          ;Get lower BCD digit to draw.
L775E:  LDA $00,X               ;
L7760:  JSR SetDigitVecPtr      ;($7785)Set vector RAM pointer to digit JSR.

L7763:  DEC BCDAddress          ;Decrement to next BCD data byte.
L7765:  LDX BCDAddress          ;

L7767:  DEC BCDIndex            ;Is there more digits to draw in the number string?
L7769:  BPL DrawNumStringLoop   ;If so, branch to get next digit byte.

L776B:  RTS                     ;Done drawing number string.

;-----------------------------[ Small Saucer Shot Angle Calculation ]------------------------------

FindScrAngleIndex:
L776C:  LDY #$00                ;Zero out working variable.
L776E:  STY ShotAngleTemp       ;
L7770:  LDY #$04                ;Prepare to loop 4 times.

ScrAngleIndexLoop:
L7772:  ROL ShotAngleTemp       ;Roll upper bit of working variable into A
L7774:  ROL                     ;
L7775:  CMP ShotXYDistance      ;Is A now larger than the given distance?
L7777:  BCC UpdateAngleCount    ;If not, branch to do next loop.

L7779:  SBC ShotXYDistance      ;Subtract Distance from A. to get update proper angle index.

UpdateAngleCount:
L777B:  DEY                     ;Does another loop need to be run?
L777C:  BNE ScrAngleIndexLoop   ;If so, branch to do another loop.

L777E:  LDA ShotAngleTemp       ;Move the final index bit into position.
L7780:  ROL                     ;
L7781:  AND #$0F                ;Limit the index to 16 values.
L7783:  TAX                     ;
L7784:  RTS                     ;Done finding angle index.

;----------------------------------[ Score Pointer Calculation ]-----------------------------------

;This function can do one of two things:
;1) it can write a command in vector RAM to draw a digit, or
;2) or set a pointer to the next data to process, overriding the zero blanking function.
;This function is used to blink a zero score at the beginning of a 2 player game.
;If $17 is #$00, draw digit. If it is any other value, get a pointer to the draw JSR.

SetDigitVecPtr:
L7785:  BCC ChkSetDigitPntr     ;Is zero blanking active? If not, branch.

L7787:  AND #$0F                ;Is the digit to draw 0?
L7789:  BEQ DisplayDigit        ;If so, branch.

ChkSetDigitPntr:
L778B:  LDX ZeroBlankBypass     ;Is the zero blank override flag set?
L778D:  BEQ DisplayDigit        ;If not, branch to draw digit.

SetDigitPntr:
L778F:  AND #$0F                ;
L7791:  CLC                     ;Add 1 to digit index to skip the SPACE character.
L7792:  ADC #$01                ;

L7794:  PHP                     ;Save processor status.

L7795:  ASL                     ;Get lower byte of pointer.
L7796:  TAY                     ;Manually set bits into the proper position.
L7797:  LDA CharPtrTbl,Y        ;
L779A:  ASL                     ;Store value in lower byte of vector pointer.
L779B:  STA VecPtrLB_           ;
L779D:  LDA CharPtrTbl+1,Y      ;Get upper byte of pointer.
L77A0:  ROL                     ;Manually set bits into the proper position.
L77A1:  AND #$1F                ;Get rid of the opcode bits.
L77A3:  ORA #$40                ;Set MSB of the address manually.
L77A5:  STA VecPtrUB_           ;Store value in upper byte of vector pointer.

L77A7:  LDA #$00                ;Disable XY axis inversion.
L77A9:  STA ShipDrawXInv        ;
L77AB:  STA ShipDrawYInv        ;
L77AD:  JSR SetVecRAMData       ;($6AD7)Update vector RAM with character data.

L77B0:  PLP                     ;Restore processor status and exit.
L77B1:  RTS                     ;

DisplayDigit:
L77B2:  JMP PrepDrawDigit       ;($7BCB)Draw a digit on the display.

;-------------------------------[ Random Number Generator ]-------------------------------

GetRandNum:
L77B5:  ASL RandNumLB           ;
L77B7:  ROL RandNumUB           ;Use a shift register to store the random number.
L77B9:  BPL RandNumBit          ;

L77BB:  INC RandNumLB           ;Increment lower byte.

RandNumBit:
L77BD:  LDA RandNumLB           ;If the second bit set in the random number?
L77BF:  BIT RandNumBitTbl       ;
L77C2:  BEQ RandNumORUB         ;If not, branch to move on.

L77C4:  EOR #$01                ;Invert LSB of random number.
L77C6:  STA RandNumLB           ;

RandNumORUB:
L77C8:  ORA RandNumUB           ;Is new random number = 0?
L77CA:  BNE RandNumDone         ;If not, branch to exit.

L77CC:  INC RandNumLB           ;Ensure random number is never 0.

RandNumDone:
L77CE:  LDA RandNumLB           ;Return lower byte or random number.
L77D0:  RTS                     ;

RandNumBitTbl:
L77D1:  .byte $02               ;Used by random number generator above.

;---------------------------------[ Thrust Calculation Routines ]----------------------------------

CalcXThrust:
L77D2:  CLC                     ;Adding #$40 to ship/bullet direction will set MSB if facing left.
L77D3:  ADC #$40                ;

CalcThrustDir:
L77D5:  BPL GetVelocityVal      ;Is ship/saucer bullet facing right/up? If so, branch.

L77D7:  AND #$7F                ;Ship/saucer bullet is facing left/down. Clear direction MSB.
L77D9:  JSR GetVelocityVal      ;($77DF)Get ship/saucer bullet velocity for this XY component.
L77DC:  JMP TwosCompliment      ;($7708)Calculate the 2's compliment of the value in A.

GetVelocityVal:
L77DF:  CMP #$41                ;Is ship/saucer bullet facing right/up?
L77E1:  BCC LookupThrustVal     ;If so, branch.

L77E3:  EOR #$7F                ;Ship/saucer bullet is facing left/down. Need to lookup-->
L77E5:  ADC #$00                ;table in reverse order.

LookupThrustVal:
L77E7:  TAX                     ;
L77E8:  LDA ThrustTbl,X         ;Get velocity value from lookup table.
L77EB:  RTS                     ;

;--------------------------------[Next Frame Saucer/Ship Distance ]--------------------------------

NextScrShipDist:
L77EC:  ASL GenByte0B           ;
L77EE:  ROL                     ;Get the signed difference between-->
L77EF:  ASL GenByte0B           ;the ship and saucer upper 4 bits.
L77F1:  ROL                     ;

L77F2:  SEC                     ;Predict next location of saucer with respect to the ship-->
L77F3:  SBC GenByte0C           ;by subtracting the current saucer XY velocity from the-->
L77F5:  RTS                     ;from the saucer/ship distance.

;------------------------------------[ Text Writing Routines ]-------------------------------------

WriteText:
L77F6:  LDA LanguageSw          ;Get the language dip switch settings.
L77F9:  AND #$03                ;
L77FB:  ASL                     ;*2. 2 bytes per entry in the pointer table below.
L77FC:  TAX                     ;Save index into table in X.

L77FD:  LDA #$10                ;Appears to have no effect.
L77FF:  STA GenByte00           ;

L7801:  LDA LanguagePtrTbl+1,X  ;
L7804:  STA VecRomPtrUB         ;Get pointer to language data from the table below.
L7806:  LDA LanguagePtrTbl,X    ;
L7809:  STA VecRomPtrLB         ;

L780B:  ADC (VecRomPtr),Y       ;Add offset to desired text message.
L780D:  STA VecRomPtrLB         ;
L780F:  BCC GetTextPos          ;Does upper byte need to be incremented?
L7811:  INC VecRomPtrUB         ;If not, branch to move on.

GetTextPos:
L7813:  TYA                     ;
L7814:  ASL                     ;*2. Each entry in the table below is 2 bytes.
L7815:  TAY                     ;

L7816:  LDA TextPosTbl,Y        ;Get the screen position for the desired text.
L7819:  LDX TextPosTbl+1,Y      ;
L781C:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L781F:  LDA #$70                ;Set scale 7(/4).
L7821:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L7824:  LDY #$00                ;Zero out index values.
L7826:  LDX #$00                ;

TextWriteLoop:
L7828:  LDA (VecRomPtr,X)       ;Get the character byte from ROM.
L782A:  STA GenByte0B           ;
L782C:  LSR                     ;Move the upper 5 bits into the proper position.
L782D:  LSR                     ;
L782E:  JSR TextWriteIncPtr     ;($784D)Increment the vector ROM pointer and write to RAM.

L7831:  LDA (VecRomPtr,X)       ;Get the next character byte from ROM.
L7833:  ROL                     ;
L7834:  ROL GenByte0B           ;Roll the 2 upper bits into the working variable.
L7836:  ROL                     ;
L7837:  LDA GenByte0B           ;Move the next 5 character bits into the proper position.
L7839:  ROL                     ;
L783A:  ASL                     ;
L783B:  JSR CheckNextChar       ;($7853)Check if the next character is valid and write to RAM.

L783E:  LDA (VecRomPtr,X)       ;Get the next text character byte.
L7840:  STA GenByte0B           ;
L7842:  JSR TextWriteIncPtr     ;($784D)Increment the vector ROM pointer.

L7845:  LSR GenByte0B           ;Is the last bit 0?
L7847:  BCC TextWriteLoop       ;If not, branch to write another character.

TextWriteDone:
L7849:  DEY                     ;Last byte was end string character, compensate.
L784A:  JMP VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

TextWriteIncPtr:
L784D:  INC VecRomPtrLB         ;
L784F:  BNE CheckNextChar       ;Increment vector ROM pointer.
L7851:  INC VecRomPtrUB         ;

CheckNextChar:
L7853:  AND #$3E                ;Is the data empty? If so, end of string found.
L7855:  BNE PrepWriteChar       ;If not, branch to write character to display.

TextEndFound:
L7857:  PLA                     ;Pull last return address from stack and update-->
L7858:  PLA                     ;the vector RAM pointer.
L7859:  BNE TextWriteDone       ;

PrepWriteChar:
L785B:  CMP #$0A                ;Is the character non-indexed?
L785D:  BCC VecRamWriteChar     ;If so, add offset to get to the indexed characters.
L785F:  ADC #$0D                ;

VecRamWriteChar:
L7861:  TAX                     ;
L7862:  LDA CharPtrTbl-2,X      ;
L7865:  STA (VecRamPtr),Y       ;
L7867:  INY                     ;
L7868:  LDA CharPtrTbl-1,X      ;Store routine for writing desired character in vector RAM.
L786B:  STA (VecRamPtr),Y       ;
L786D:  INY                     ;
L786E:  LDX #$00                ;
L7870:  RTS                     ;

TextPosTbl:
L7871:  .byte $64, $B6          ;X=4*$64=$190=400. Y=4*$B6=$2D8=728.
L7873:  .byte $64, $B6          ;X=4*$64=$190=400. Y=4*$B6=$2D8=728.
L7875:  .byte $0C, $AA          ;X=4*$0C=$30 =48.  Y=4*$AA=$2A8=680.
L7877:  .byte $0C, $A2          ;X=4*$0C=$30 =48.  Y=4*$A2=$288=648.
L7879:  .byte $0C, $9A          ;X=4*$0C=$30 =48.  Y=4*$9A=$268=616.
L787B:  .byte $0C, $92          ;X=4*$0C=$30 =48.  Y=4*$92=$248=584.
L787D:  .byte $64, $C6          ;X=4*$64=$190=400. Y=4*$C6=$318=792.
L787F:  .byte $64, $9D          ;X=4*$64=$190=400. Y=4*$9D=$274=628.
L7881:  .byte $50, $39          ;X=4*$50=$140=320. Y=4*$39=$E4 =228.
L7883:  .byte $50, $39          ;X=4*$50=$140=320. Y=4*$39=$E4 =228.
L7885:  .byte $50, $39          ;X=4*$50=$140=320. Y=4*$39=$E4 =228.

LanguagePtrTbl:
L7887:  .word EnglishTextTbl    ;
L7889:  .word GermanTextTbl     ;Text table pointers.
L788B:  .word FrenchTextTbl     ;
L788D:  .word SpanishTextTbl    ;

;----------------------------------[ German Message Vector Data ]----------------------------------

;Message offsets
GermanTextTbl:
L788F:  .byte $0B               ;HOECHSTERGEBNIS
L7890:  .byte $15               ;SPIELER 
L7891:  .byte $1B               ;IHR ERGEBNIS IST EINES DER ZEHN BESTEN
L7892:  .byte $35               ;BITTE GEBEN SIE IHRE INITIALEN EIN
L7893:  .byte $4D               ;ZUR BUCHSTABENWAHL ROTATE DRUECKEN
L7894:  .byte $65               ;WENN BUCHSTABE OK HYPERSPACE DRUECKEN
L7895:  .byte $7F               ;STARTKNOEPFE DRUECKEN
L7896:  .byte $8D               ;SPIELENDE
L7897:  .byte $93               ;1 MUENZE 2 SPIELE
L7898:  .byte $9F               ;1 MUENZE 1 SPIEL
L7899:  .byte $AB               ;2 MUENZEN 1 SPIEL

;---------------------------------------[ HOECHSTERGEBNIS ]----------------------------------------

;               H     O     E        C     H     S        T     E     R        G     E     B      
;             01100_10011_01001_0, 00111_01100_10111_0, 11000_01001_10110_0, 01011_01001_00110_0
L789A:  .byte     $64, $D2,            $3B, $2E,            $C2, $6C,            $5A, $4C
;               N     I     S      
;             10010_01101_10111_1
L78A2:  .byte     $93, $6F

;-------------------------------------------[ SPIELER ]--------------------------------------------

;               S     P     I        E     L     E        R     _    NULL    
;             10111_10100_01101_0, 01001_10000_01001_0, 10110_00001_00000_0
L78A4:  .byte     $BD, $1A,            $4C, $12,            $B0, $40

;----------------------------[ IHR ERGEBNIS IST EINES DER ZEHN BESTEN ]----------------------------

;               I     H     R        _     E     R        G     E     B        N     I     S      
;             01101_01100_10110_0, 00001_01001_10110_0, 01011_01001_00110_0, 10010_01101_10111_0
L78AA:  .byte     $6B, $2C,            $0A, $6C,            $5A, $4C,            $93, $6E
;               _     I     S        T     _     E        I     N     E        S     _     D      
;             00001_01101_10111_0, 11000_00001_01001_0, 01101_10010_01001_0, 10111_00001_01000_0
L78B2:  .byte     $0B, $6E,            $C0, $52,            $6C, $92,            $B8, $50
;               E     R     _        Z     E     H        N     _     B        E     S     T      
;             01001_10110_00001_0, 11110_01001_01100_0, 10010_00001_00110_0, 01001_10111_11000_0
L78BA:  .byte     $4D, $82,            $F2, $58,            $90, $4C,            $4D, $F0
;               E     N    NULL    
;             01001_10010_00000_0
L78C2:  .byte     $4C, $80

;------------------------------[ BITTE GEBEN SIE IHRE INITIALEN EIN ]------------------------------

;               B     I     T        T     E     _        G     E     B        E     N     _      
;             00110_01101_11000_0, 11000_01001_00001_0, 01011_01001_00110_0, 01001_10010_00001_0
L78C4:  .byte     $33, $70,            $C2, $42,            $5A, $4C,            $4C, $82
;               S     I     E        _     I     H        R     E     _        I     N     I      
;             10111_01101_01001_0, 00001_01101_01100_0, 10110_01001_00001_0, 01101_10010_01101_0
L78CC:  .byte     $BB, $52,            $0B, $58,            $B2, $42,            $6C, $9A
;               T     I     A        L     E     N        _     E     I        N    NULL  NULL    
;             11000_01101_00101_0, 10000_01001_10010_0, 00001_01001_01101_0, 10010_00000_00000_0
L78D4:  .byte     $C3, $4A,            $82, $64,            $0A, $5A,            $90, $00

;------------------------------[ ZUR BUCHSTABENWAHL ROTATE DRUECKEN ]------------------------------

;               Z     U     R        _     B     U        C     H     S        T     A     B      
;             11110_11001_10110_0, 00001_00110_11001_0, 00111_01100_10111_0, 11000_00101_00110_0
L78DC:  .byte     $F6, $6C,            $09, $B2,            $3B, $2E,            $C1, $4C
;               E     N     W        A     H     L        _     R     O        T     A     T      
;             01001_10010_11011_0, 00101_01100_10000_0, 00001_10110_10011_0, 11000_00101_11000_0
L78E4:  .byte     $4C, $B6,            $2B, $20,            $0D, $A6,            $C1, $70
;               E     _     D        R     U     E        C     K     E        N    NULL  NULL    
;             01001_00001_01000_0, 10110_11001_01001_0, 00111_01111_01001_0, 10010_00000_00000_0
L78EC:  .byte     $48, $50,            $B6, $52,            $3B, $D2,            $90, $00

;-----------------------------[ WENN BUCHSTABE OK HYPERSPACE DRUECKEN ]----------------------------

;               W     E     N        N     _     B        U     C     H        S     T     A      
;             11011_01001_10010_0, 10010_00001_00110_0, 11001_00111_01100_0, 10111_11000_00101_0
L78F4:  .byte     $DA, $64,            $90, $4C,            $C9, $D8,            $BE, $0A
;               B     E     _        O     K     _        H     Y     P        E     R     S      
;             00110_01001_00001_0, 10011_01111_00001_0, 01100_11101_10100_0, 01001_10110_10111_0
L78FC:  .byte     $32, $42,            $9B, $C2,            $67, $68,            $4D, $AE
;               P     A     C        E     _     D        R     U     E        C     K     E      
;             10100_00101_00111_0, 01001_00001_01000_0, 10110_11001_01001_0, 00111_01111_01001_0
L7904:  .byte     $A1, $4E,            $48, $50,            $B6, $52,            $3B, $D2
;               N    NULL  NULL    
;             10010_00000_00000_0
L790C:  .byte     $90, $00

;------------------------------------[ STARTKNOEPFE DRUECKEN ]-------------------------------------

;               S     T     A        R     T     K        N     O     E        P     F     E      
;             10111_11000_00101_0, 10110_11000_01111_0, 10010_10011_01001_0, 10100_01010_01001_0
L790E:  .byte     $BE, $0A,            $B6, $1E,            $94, $D2,            $A2, $92
;               _     D     R        U     E     C        K     E     N      
;             00001_01000_10110_0, 11001_01001_00111_0, 01111_01001_10010_1
L7916:  .byte     $0A, $2C,            $CA, $4E,            $7A, $65

;------------------------------------------[ SPIELENDE ]-------------------------------------------

;               S     P     I        E     L     E        N     D     E      
;             10111_10100_01101_0, 01001_10000_01001_0, 10010_01000_01001_1
L791C:  .byte     $BD, $1A,            $4C, $12,            $92, $13

;--------------------------------------[ 1 MUENZE 2 SPIELE ]---------------------------------------

;               1     _     M        U     E     N        Z     E     _        2     _     S      
;             00011_00001_10001_0, 11001_01001_10010_0, 11110_01001_00001_0, 00100_00001_10111_0
L7922:  .byte     $18, $62,            $CA, $64,            $F2, $42,            $20, $6E
;               P     I     E        L     E    NULL    
;             10100_01101_01001_0, 10000_01001_00000_0
L792A:  .byte     $A3, $52,            $82, $40

;---------------------------------------[ 1 MUENZE 1 SPIEL ]---------------------------------------

;               1     _     M        U     E     N        Z     E     _        1     _     S      
;             00011_00001_10001_0, 11001_01001_10010_0, 11110_01001_00001_0, 00011_00001_10111_0
L792E:  .byte     $18, $62,            $CA, $64,            $F2, $42,            $18, $6E
;               P     I     E        L    NULL  NULL    
;             10100_01101_01001_0, 10000_00000_00000_0
L7936:  .byte     $A3, $52,            $80, $00

;--------------------------------------[ 2 MUENZEN 1 SPIEL ]---------------------------------------

;               2     _     M        U     E     N        Z     E     N        _     1     _      
;             00100_00001_10001_0, 11001_01001_10010_0, 11110_01001_10010_0, 00001_00011_00001_0
L793A:  .byte     $20, $62,            $CA, $64,            $F2, $64,            $08, $C2
;               S     P     I        E     L    NULL    
;             10111_10100_01101_0, 01001_10000_00000_0
L7942:  .byte     $BD, $1A,            $4C, $00

;----------------------------------[ French Message Vector Data ]----------------------------------

;Message offsets
FrenchTextTbl:
L7946:  .byte $0B               ;MEILLEUR SCORE
L7947:  .byte $15               ;JOUER 
L7948:  .byte $19               ;VOTRE SCORE EST UN DES 10 MEILLEURS
L7949:  .byte $31               ;SVP ENTREZ VOS INITIALES
L794A:  .byte $41               ;POUSSEZ ROTATE POUR VOS INITIALES
L794B:  .byte $57               ;POUSSEZ HYPERSPACE QUAND LETTRE CORRECTE
L794C:  .byte $73               ;APPUYER SUR START
L794D:  .byte $7F               ;FIN DE PARTIE
L794E:  .byte $89               ;1 PIECE 2 JOUEURS
L794F:  .byte $95               ;1 PIECE 1 JOUEUR
L7950:  .byte $A1               ;2 PIECES 1 JOUEUR

;----------------------------------------[ MEILLEUR SCORE ]----------------------------------------

;               M     E     I        L     L     E        U     R     _        S     C     O      
;             10001_01001_01101_0, 10000_10000_01001_0, 11001_10110_00001_0, 10111_00111_10011_0
L7951:  .byte     $8A, $5A,            $84, $12,            $CD, $82,            $B9, $E6
;               R     E    NULL    
;             10110_01001_00000_0
L7959:  .byte     $B2, $40

;--------------------------------------------[ JOUER ]---------------------------------------------

;               J     O     U        E     R     _      
;             01110_10011_11001_0, 01001_10110_00001_1
L795B:  .byte     $74, $F2,            $4D, $83

;-------------------------------[ VOTRE SCORE EST UN DES 10 MEILLEURS ]----------------------------

;               V     O     T        R     E     _        S     C     O        R     E     _      
;             11010_10011_11000_0, 10110_01001_00001_0, 10111_00111_10011_0, 10110_01001_00001_0
L795F:  .byte     $D4, $F0,            $B2, $42,            $B9, $E6,            $B2, $42
;               E     S     T        _     U     N        _     D     E        S     _     1      
;             01001_10111_11000_0, 00001_11001_10010_0, 00001_01000_01001_0, 10111_00001_00011_0
L7967:  .byte     $4D, $F0,            $0E, $64,            $0A, $12,            $B8, $46
;               0     _     M        E     I     L        L     E     U        R     S    NULL    
;             00010_00001_10001_0, 01001_01101_10000_0, 10000_01001_11001_0, 10110_10111_00000_0
L796F:  .byte     $10, $62,            $4B, $60,            $82, $72,            $B5, $C0

;-----------------------------------[ SVP ENTREZ VOS INITIALES ]-----------------------------------

;               S     V     P        _     E     N        T     R     E        Z     _     V      
;             10111_11010_10100_0, 00001_01001_10010_0, 11000_10110_01001_0, 11110_00001_11010_0
L7977:  .byte     $BE, $A8,            $0A, $64,            $C5, $92,            $F0, $74
;               O     S     _        I     N     I        T     I     A        L     E     S      
;             10011_10111_00001_0, 01101_10010_01101_0, 11000_01101_00101_0, 10000_01001_10111_1
L797F:  .byte     $9D, $C2,            $6C, $9A,            $C3, $4A,            $82, $6F

;------------------------------[ POUSSEZ ROTATE POUR VOS INITIALES ]-------------------------------

;               P     O     U        S     S     E        Z     _     R        O     T     A      
;             10100_10011_11001_0, 10111_10111_01001_0, 11110_00001_10110_0, 10011_11000_00101_0
L7987:  .byte     $A4, $F2,            $BD, $D2,            $F0, $6C,            $9E, $0A
;               T     E     _        P     O     U        R     _     V        O     S     _      
;             11000_01001_00001_0, 10100_10011_11001_0, 10110_00001_11010_0, 10011_10111_00001_0
L798F:  .byte     $C2, $42,            $A4, $F2,            $B0, $74,            $9D, $C2
;               I     N     I        T     I     A        L     E     S      
;             01101_10010_01101_0, 11000_01101_00101_0, 10000_01001_10111_1
L7997:  .byte     $6C, $9A,            $C3, $4A,            $82, $6F

;---------------------------[ POUSSEZ HYPERSPACE QUAND LETTRE CORRECTE ]---------------------------

;               P     O     U        S     S     E        Z     _     H        Y     P     E      
;             10100_10011_11001_0, 10111_10111_01001_0, 11110_00001_01100_0, 11101_10100_01001_0
L799D:  .byte     $A4, $F2,            $BD, $D2,            $F0, $58,            $ED, $12
;               R     S     P        A     C     E        _     Q     U        A     N     D      
;             10110_10111_10100_0, 00101_00111_01001_0, 00001_10101_11001_0, 00101_10010_01000_0
L79A5:  .byte     $B5, $E8,            $29, $D2,            $0D, $72,            $2C, $90
;               _     L     E        T     T     R        E     _     C        O     R     R      
;             00001_10000_01001_0, 11000_11000_10110_0, 01001_00001_00111_0, 10011_10110_10110_0
L79AD:  .byte     $0C, $12,            $C6, $2C,            $48, $4E,            $9D, $AC
;               E     C     T        E    NULL  NULL    
;             01001_00111_11000_0, 01001_00000_00000_0
L79B5:  .byte     $49, $F0,            $48, $00

;--------------------------------------[ APPUYER SUR START ]---------------------------------------

;               A     P     P        U     Y     E        R     _     S        U     R     _      
;             00101_10100_10100_0, 11001_11101_01001_0, 10110_00001_10111_0, 11001_10110_00001_0
L79B9:  .byte     $2D, $28,            $CF, $52,            $B0, $6E,            $CD, $82
;               S     T     A        R     T    NULL    
;             10111_11000_00101_0, 10110_11000_00000_0
L79C1:  .byte     $BE, $0A,            $B6, $00

;----------------------------------------[ FIN DE PARTIE ]-----------------------------------------

;               F     I     N        _     D     E        _     P     A        R     T     I      
;             01010_01101_10010_0, 00001_01000_01001_0, 00001_10100_00101_0, 10110_11000_01101_0
L79C5:  .byte     $53, $64,            $0A, $12,            $0D, $0A,            $B6, $1A
;               E    NULL  NULL    
;             01001_00000_00000_0
L79CD:  .byte     $48, $00

;--------------------------------------[ 1 PIECE 2 JOUEURS ]---------------------------------------

;               1     _     P        I     E     C        E     _     2        _     J     O      
;             00011_00001_10100_0, 01101_01001_00111_0, 01001_00001_00100_0, 00001_01110_10011_0
L79CF:  .byte     $18, $68,            $6A, $4E,            $48, $48,            $0B, $A6
;               U     E     U        R     S    NULL    
;             11001_01001_11001_0, 10110_10111_00000_0
L79D7:  .byte     $CA, $72,            $B5, $C0

;---------------------------------------[ 1 PIECE 1 JOUEUR ]---------------------------------------

;               1     _     P        I     E     C        E     _     1        _     J     O      
;             00011_00001_10100_0, 01101_01001_00111_0, 01001_00001_00011_0, 00001_01110_10011_0
L79DB:  .byte     $18, $68,            $6A, $4E,            $48, $46,            $0B, $A6
;               U     E     U        R    NULL  NULL    
;             11001_01001_11001_0, 10110_00000_00000_0
L79E3:  .byte     $CA, $72,            $B0, $00

;--------------------------------------[ 2 PIECES 1 JOUEUR ]---------------------------------------

;               2     _     P        I     E     C        E     S     _        1     _     J      
;             00100_00001_10100_0, 01101_01001_00111_0, 01001_10111_00001_0, 00011_00001_01110_0
L79E7:  .byte     $20, $68,            $6A, $4E,            $4D, $C2,            $18, $5C
;               O     U     E        U     R    NULL    
;             10011_11001_01001_0, 11001_10110_00000_0
L79EF:  .byte     $9E, $52,            $CD, $80

;---------------------------------[ Spanish Message Vector Data ]----------------------------------

;Message offsets
SpanishTextTbl:
L79F3:  .byte $0B               ;RECORDS
L79F4:  .byte $11               ;JUGADOR
L79F5:  .byte $17               ;SU PUNTAJE ESTA ENTRE LOS DIEZ MEJORES
L79F6:  .byte $31               ;POR FAVOR ENTRE SUS INICIALES
L79F7:  .byte $45               ;OPRIMA ROTATE PARA SELECCIONAR LA LETRA
L79F8:  .byte $5F               ;OPRIMA HYPERSPACE
L79F9:  .byte $6B               ;PULSAR START
L79FA:  .byte $73               ;JUEGO TERMINADO
L79FB:  .byte $7D               ;1 FICHA 2 JUEGOS
L79FC:  .byte $89               ;1 FICHA 1 JUEGO
L79FD:  .byte $93               ;2 FICHAS 1 JUEGO

;-------------------------------------------[ RECORDS ]--------------------------------------------

;               R     E     C        O     R     D        S    NULL  NULL    
;             10110_01001_00111_0, 10011_10110_01000_0, 10111_00000_00000_0
L79FE:  .byte     $B2, $4E,            $9D, $90,            $B8, $00

;-------------------------------------------[ JUGADOR ]--------------------------------------------

;               J     U     G        A     D     O        R     _    NULL    
;             01110_11001_01011_0, 00101_01000_10011_0, 10110_00001_00000_0
L7A04:  .byte     $76, $56,            $2A, $26,            $B0, $40

;----------------------------[ SU PUNTAJE ESTA ENTRE LOS DIEZ MEJORES ]----------------------------

;               S     U     _        P     U     N        T     A     J        E     _     E      
;             10111_11001_00001_0, 10100_11001_10010_0, 11000_00101_01110_0, 01001_00001_01001_0
L7A0A:  .byte     $BE, $42,            $A6, $64,            $C1, $5C,            $48, $52
;               S     T     A        _     E     N        T     R     E        _     L     O      
;             10111_11000_00101_0, 00001_01001_10010_0, 11000_10110_01001_0, 00001_10000_10011_0
L7A12:  .byte     $BE, $0A,            $0A, $64,            $C5, $92,            $0C, $26
;               S     _     D        I     E     Z        _     M     E        J     O     R      
;             10111_00001_01000_0, 01101_01001_11110_0, 00001_10001_01001_0, 01110_10011_10110_0
L7A1A:  .byte     $B8, $50,            $6A, $7C,            $0C, $52,            $74, $EC
;               E     S    NULL    
;             01001_10111_00000_0
L7A22:  .byte     $4D, $C0

;--------------------------------[ POR FAVOR ENTRE SUS INICIALES ]---------------------------------

;               P     O     R        _     F     A        V     O     R        _     E     N      
;             10100_10011_10110_0, 00001_01010_00101_0, 11010_10011_10110_0, 00001_01001_10010_0
L7A24:  .byte     $A4, $EC,            $0A, $8A,            $D4, $EC,            $0A, $64
;               T     R     E        _     S     U        S     _     I        N     I     C      
;             11000_10110_01001_0, 00001_10111_11001_0, 10111_00001_01101_0, 10010_01101_00111_0
L7A2C:  .byte     $C5, $92,            $0D, $F2,            $B8, $5A,            $93, $4E
;               I     A     L        E     S    NULL    
;             01101_00101_10000_0, 01001_10111_00000_0
L7A34:  .byte     $69, $60,            $4D, $C0

;---------------------------[ OPRIMA ROTATE PARA SELECCIONAR LA LETRA ]----------------------------

;               O     P     R        I     M     A        _     R     O        T     A     T      
;             10011_10100_10110_0, 01101_10001_00101_0, 00001_10110_10011_0, 11000_00101_11000_0
L7A38:  .byte     $9D, $2C,            $6C, $4A,            $0D, $A6,            $C1, $70
;               E     _     P        A     R     A        _     S     E        L     E     C      
;             01001_00001_10100_0, 00101_10110_00101_0, 00001_10111_01001_0, 10000_01001_00111_0
L7A40:  .byte     $48, $68,            $2D, $8A,            $0D, $D2,            $82, $4E
;               C     I     O        N     A     R        _     L     A        _     L     E      
;             00111_01101_10011_0, 10010_00101_10110_0, 00001_10000_00101_0, 00001_10000_01001_0
L7A48:  .byte     $3B, $66,            $91, $6C,            $0C, $0A,            $0C, $12
;               T     R     A      
;             11000_10110_00101_1
L7A50:  .byte     $C5, $8B

;--------------------------------------[ OPRIMA HYPERSPACE ]---------------------------------------

;               O     P     R        I     M     A        _     H     Y        P     E     R      
;             10011_10100_10110_0, 01101_10001_00101_0, 00001_01100_11101_0, 10100_01001_10110_0
L7A52:  .byte     $9D, $2C,            $6C, $4A,            $0B, $3A,            $A2, $6C
;               S     P     A        C     E    NULL    
;             10111_10100_00101_0, 00111_01001_00000_0
L7A5A:  .byte     $BD, $0A,            $3A, $40

;-----------------------------------------[ PULSAR START ]-----------------------------------------

;               P     U     L        S     A     R        _     S     T        A     R     T      
;             10100_11001_10000_0, 10111_00101_10110_0, 00001_10111_11000_0, 00101_10110_11000_1
L7A5E:  .byte     $A6, $60,            $B9, $6C,            $0D, $F0,            $2D, $B1

;---------------------------------------[ JUEGO TERMINADO ]----------------------------------------

;               J     U     E        G     O     _        T     E     R        M     I     N      
;             01110_11001_01001_0, 01011_10011_00001_0, 11000_01001_10110_0, 10001_01101_10010_0
L7A66:  .byte     $76, $52,            $5C, $C2,            $C2, $6C,            $8B, $64
;               A     D     O      
;             00101_01000_10011_1
L7A6E:  .byte     $2A, $27

;---------------------------------------[ 1 FICHA 2 JUEGOS ]---------------------------------------

;               1     _     F        I     C     H        A     _     2        _     J     U      
;             00011_00001_01010_0, 01101_00111_01100_0, 00101_00001_00100_0, 00001_01110_11001_0
L7A70:  .byte     $18, $54,            $69, $D8,            $28, $48,            $0B, $B2
;               E     G     O        S    NULL  NULL    
;             01001_01011_10011_0, 10111_00000_00000_0
L7A78:  .byte     $4A, $E6,            $B8, $00

;---------------------------------------[ 1 FICHA 1 JUEGO ]----------------------------------------

;               1     _     F        I     C     H        A     _     1        _     J     U      
;             00011_00001_01010_0, 01101_00111_01100_0, 00101_00001_00011_0, 00001_01110_11001_0
L7A7C:  .byte     $18, $54,            $69, $D8,            $28, $46,            $0B, $B2
;               E     G     O      
;             01001_01011_10011_1
L7A84:  .byte     $4A, $E7

;---------------------------------------[ 2 FICHAS 1 JUEGO ]---------------------------------------

;               2     _     F        I     C     H        A     S     _        1     _     J      
;             00100_00001_01010_0, 01101_00111_01100_0, 00101_10111_00001_0, 00011_00001_01110_0
L7A86:  .byte     $20, $54,            $69, $D8,            $2D, $C2,            $18, $5C
;               U     E     G        O    NULL  NULL    
;             11001_01001_01011_0, 10011_00000_00000_0
L7A8E:  .byte     $CA, $56,            $98, $00

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L7A92:  .byte $52               ;Checksum byte.

;--------------------------------[ Check Coin Insertion Routines ]---------------------------------

CheckCoinsInserted:
L7A93:  LDX #$02                ;Prepare to check all 3 coin mechanisms.

CheckCoinsLoop:
L7A95:  LDA LeftCoinSw,X        ;Get status of coin switch and store it in the carry bit.
L7A98:  ASL                     ;

L7A99:  LDA CoinDropTimers,X    ;Get coin drop timer value.
L7A9B:  AND #$1F                ;Was a coin insertion detected?
L7A9D:  BCC CheckDropTimerVal   ;If not, branch to check coin drop timer.

L7A9F:  BEQ CheckSlamSw         ;Has coin drop timer run until it hit 0? If so, branch.

L7AA1:  CMP #$1B                ;Has timer just started with detected coin insertion?
L7AA3:  BCS DecDropTimer        ;If so, branch.

L7AA5:  TAY                     ;Wait 7 NMI periods(28ms). During this time, the coin-->
L7AA6:  LDA NmiCounter          ;switch should be active, the drop timer should be active-->
L7AA8:  AND #$07                ;and the slam switch should not be active. If these-->
L7AAA:  CMP #$07                ;conditions are true, decrement the coin drop timer.
L7AAC:  TYA                     ;
L7AAD:  BCC CheckSlamSw         ;Check slam switch during first 7 NMIs.

DecDropTimer:
L7AAF:  SBC #$01                ;Things check out so far, decrement coin drop timer.

CheckSlamSw:
L7AB1:  STA CoinDropTimers,X    ;Update the coin drop timer.
L7AB3:  LDA SlamSw              ;Get the slam switch status.
L7AB6:  AND #$80                ;Was a slam detected?
L7AB8:  BEQ CheckSlamTimer      ;If not, branch to move on.

SlamDetected:
L7ABA:  LDA #$F0                ;Slam detected. Set slam timer.
L7ABC:  STA SlamTimer           ;

CheckSlamTimer:
L7ABE:  LDA SlamTimer           ;Is the slam timer active?
L7AC0:  BEQ CheckWaitTimer      ;If not, branch to move on.

SlamTimeout:
L7AC2:  DEC SlamTimer           ;
L7AC4:  LDA #$00                ;Decrement the slam timer and hold the other timers-->
L7AC6:  STA CoinDropTimers,X    ;in their zero state until the slam timer clears.
L7AC8:  STA WaitCoinTimers,X    ;

CheckWaitTimer:
L7ACA:  CLC                     ;Is this wait timer finished?
L7ACB:  LDA WaitCoinTimers,X    ;
L7ACD:  BEQ CheckNextMech       ;If so, branch to see if another mechanism needs to be checked.

L7ACF:  DEC WaitCoinTimers,X    ;Is this timer still active? decrement and branch if done.
L7AD1:  BNE CheckNextMech       ;

L7AD3:  SEC                     ;Branch always.
L7AD4:  BCS CheckNextMech       ;

CheckDropTimerVal:
L7AD6:  CMP #$1B                ;If timer is a high value, the coin switch cleared too-->
L7AD8:  BCS ResetDropTimer      ;soon. False flag. Branch to reset the drop timer.

L7ADA:  LDA CoinDropTimers,X    ;Max value after add is #$3F.
L7ADC:  ADC #$20                ;
L7ADE:  BCC CheckSlamSw         ;Branch always.

L7AE0:  BEQ ResetDropTimer      ;This code does not appear to be accessed.
L7AE2:  CLC                     ;

ResetDropTimer:
L7AE3:  LDA #$1F                ;Prepare to reset the coin drop timer.
L7AE5:  BCS CheckSlamSw         ;If carry is set, something funny happened, check slam switch.

L7AE7:  STA CoinDropTimers,X    ;Reset the coin drop timer.
L7AE9:  LDA WaitCoinTimers,X    ;is this the first transition of the wait timer?
L7AEB:  BEQ SetWaitTimer        ;If so, branch to set timer and move to next coin mech.

L7AED:  SEC                     ;Timer transition already happened, prepare to do more processing.

SetWaitTimer:
L7AEE:  LDA #$78                ;Load the wait timer.
L7AF0:  STA WaitCoinTimers,X    ;

CheckNextMech:
L7AF2:  BCC DoNextCoinMech      ;Branch to check next coin mech if timer transition just happened.

L7AF4:  LDA #$00                ;Is this the left coin mech?
L7AF6:  CPX #$01                ;
L7AF8:  BCC CalcMult            ;If so, branch to increment coins. No multipliers this coin mech.

L7AFA:  BEQ CCoinMechMult       ;Is this the center coin mech? If so, branch to calc multiplier.

RCoinMechMult:
L7AFC:  LDA DipSwitchBits       ;Only option left is the right coin mechanism.
L7AFE:  AND #$0C                ;
L7B00:  LSR                     ;Get the Dip switch values and /4.
L7B01:  LSR                     ;
L7B02:  BEQ CalcMult            ;If no multiplier active, branch to increment coins.

L7B04:  ADC #$02                ;Multiplier active on the right coin mech. Get the shifted-->
L7B06:  BNE CalcMult            ;DIP switch value and add 2 for a range between 4-6. Branch always.

CCoinMechMult:
L7B08:  LDA DipSwitchBits       ;Check if there is a multiplier active on the center coin mech.
L7B0A:  AND #$10                ;
L7B0C:  BEQ CalcMult            ;If not, branch to increment the coins.

L7B0E:  LDA #$01                ;Multiplier active.  Add an additional coin.

CalcMult:
L7B10:  SEC                     ;Add at least one coin.
L7B11:  ADC CoinMult            ;Add the any others from multipliers.
L7B13:  STA CoinMult            ;Update the total coins.
L7B15:  INC ValidCoins,X        ;Indicate a valid coin. Used for incrementing coin counter.

DoNextCoinMech:
L7B17:  DEX                     ;Are there coin mechanisms left to check:
L7B18:  BMI CalcCoinsPerPlay    ;If not, next step is to update coins.

L7B1A:  JMP CheckCoinsLoop      ;($7A95)Check next coin mechanism.

CalcCoinsPerPlay:
L7B1D:  LDA DipSwitchBits       ;Get the coins per play value. On = 0, Off = 1.
L7B1F:  AND #$03                ;
L7B21:  TAY                     ;Is free play active?
L7B22:  BEQ UpdateCoinMult      ;If so, branch to add 0 coins.

L7B24:  LSR                     ;
L7B25:  ADC #$00                ;Get the number of coins required to get a credit-->
L7B27:  EOR #$FF                ;and subtract the number of current coins. if more-->
L7B29:  SEC                     ;coins are needed, branch to finish for this frame.-->
L7B2A:  ADC CoinMult            ;Else add up to 2 credits this frame.
L7B2C:  BCC CreditUpdateDone    ;

L7B2E:  CPY #$02                ;Do 2 credits need to be added?
L7B30:  BCS Add1Credit          ;If not, branch to add only 1.

Add2Credits:
L7B32:  INC NumCredits          ;Add the first of 2 credits.

Add1Credit:
L7B34:  INC NumCredits          ;Increment the credits.

UpdateCoinMult:
L7B36:  STA CoinMult            ;Store updated coin value.

CreditUpdateDone:
L7B38:  LDA NmiCounter          ;Is this an odd NMI period?
L7B3A:  LSR                     ;
L7B3B:  BCS EndCoinCheck        ;If so, branch to end, if not, keep processing.

L7B3D:  LDY #$00                ;Prepare to check all 3 valid coin indicators.
L7B3F:  LDX #$02                ;

ValidCoinLoop1:
L7B41:  LDA ValidCoins,X        ;
L7B43:  BEQ NextValidCoin1      ;
L7B45:  CMP #$10                ;This function continues a valid coin timer.-->
L7B47:  BCC NextValidCoin1      ;During this time, the coin counters are enabled.-->
L7B49:  ADC #$EF                ;the counter will last for 16 NMIs when a single-->
L7B4B:  INY                     ;coin is inserted. The counter will last longer-->
L7B4C:  STA ValidCoins,X        ;if more coins are added.
NextValidCoin1:                 ;
L7B4E:  DEX                     ;
L7B4F:  BPL ValidCoinLoop1      ;

L7B51:  TYA                     ;Is a valid coin counter active from above?
L7B52:  BNE EndCoinCheck        ;

L7B54:  LDX #$02                ;Prepare to check all 3 valid coin indicators.

ValidCoinLoop2:
L7B56:  LDA ValidCoins,X        ;
L7B58:  BEQ NextValidCoin2      ;
L7B5A:  CLC                     ;
L7B5B:  ADC #$EF                ;This function will initiate a valid coin-->
L7B5D:  STA ValidCoins,X        ;timer.  The coin counters will be enabled-->
L7B5F:  BMI EndCoinCheck        ;at this time.
NextValidCoin2:                 ;
L7B61:  DEX                     ;
L7B62:  BPL ValidCoinLoop2      ;

EndCoinCheck:
L7B64:  RTS                     ;Done checking coin insertion.

;---------------------------------------------[ NMI ]----------------------------------------------

NMI:
L7B65:  PHA                     ;Push A, Y and X onto the stack.
L7B66:  TYA                     ;
L7B67:  PHA                     ;
L7B68:  TXA                     ;
L7B69:  PHA                     ;
L7B6A:  CLD                     ;Set processor to binary mode.

L7B6B:  LDA StackBottom         ;Has the stack overflowed or underflowed?
L7B6E:  ORA StackTop            ;If so, spin lock until watchdog reset.
L7B71:* BNE -                   ;

L7B73:  INC NmiCounter          ;Is it time to start a new frame(every 4th NMI)?
L7B75:  LDA NmiCounter          ;
L7B77:  AND #$03                ;
L7B79:  BNE CheckCoins          ;If not, branch to skip frame counter increment.

L7B7B:  INC FrameCounter        ;Start a new frame. 62.5 frames per second.
L7B7D:  LDA FrameCounter        ;Have more than 3 frames passed without being acknowledged?
L7B7F:  CMP #$04                ;
L7B81:* BCS -                   ;If so, something is wrong. Spin lock until watchdog reset.

CheckCoins:
L7B83:  JSR CheckCoinsInserted  ;($7A93)Check if player inserted any coins.

L7B86:  LDA MultiPurpBits       ;Get the multipurpose bits and discard the coin-->
L7B88:  AND #$C7                ;counter enable bits. They will be set next.

L7B8A:  BIT LValidCoin          ;Was a valid coin detected in the left coin mech?
L7B8C:  BPL CheckCValidCoin     ;If not, branch to check the next coin mech.

L7B8E:  ORA #CoinCtrLeft        ;Activate the left coin counter.

CheckCValidCoin:
L7B90:  BIT CValidCoin          ;Was a valid coin detected in the center coin mech?
L7B92:  BPL CheckRValidCoin     ;If not, branch to check the next coin mech.

L7B94:  ORA #CoinCtrCntr        ;Activate the center coin counter.

CheckRValidCoin:
L7B96:  BIT RValidCoin          ;Was a valid coin detected in the right coin mech?
L7B98:  BPL UpdateCoinCounters  ;If not, branch to update the active coin counters.

L7B9A:  ORA #CoinCtrRght        ;Activate the right coin counter.

UpdateCoinCounters:
L7B9C:  STA MultiPurpBits       ;Update the current states of the coin counters.
L7B9E:  STA MultiPurp           ;

L7BA1:  LDA SlamTimer           ;Is slam timer active?
L7BA3:  BEQ UpdateSlamSFX       ;If not, branch.

L7BA5:  LDA #$80                ;Slam detected. Start the slam SFX.
L7BA7:  BNE EnDisSlamSFX        ;

UpdateSlamSFX:
L7BA9:  LDA ExLfSFXTimer        ;Slam has not recently been active. Disable slam SFX.
L7BAB:  BEQ EnDisSlamSFX        ;

L7BAD:  LDA FrameTimerLo        ;Is this an odd frame?
L7BAF:  ROR                     ;
L7BB0:  BCC FrameTimerRoll3     ;If not, branch to skip decrementing SFX timer.

L7BB2:  DEC ExLfSFXTimer        ;Decrement SFX timer every other frame.

FrameTimerRoll3:
L7BB4:  ROR                     ;
L7BB5:  ROR                     ;Rolling the value creates a unique SFX.
L7BB6:  ROR                     ;

EnDisSlamSFX:
L7BB7:  STA LifeSFX             ;Enables or disables slam SFX.

L7BBA:  PLA                     ;Pull A, Y and X from the stack.
L7BBB:  TAX                     ;
L7BBC:  PLA                     ;
L7BBD:  TAY                     ;
L7BBE:  PLA                     ;
L7BBF:  RTI                     ;Return from interrupt.

;-----------------------------------[ Vector Drawing Routines ]------------------------------------

VecHalt:
L7BC0:  LDA #HaltOpcode         ;Write HALT command to vector RAM.

VecRam2Write:
L7BC2:  LDY #$00                ;Write 2 bytes to vector RAM.
L7BC4:  STA (VecRamPtr),Y       ;
L7BC6:  INY                     ;
L7BC7:  STA (VecRamPtr),Y       ;
L7BC9:  BNE VecPtrUpdate        ;($7C39)Branch always. Update Vector RAM pointer.

PrepDrawDigit:
L7BCB:  BCC DrawDigit           ;($7BD1)Draw a single digit on the display.
L7BCD:  AND #$0F                ;Is a blank space to be drawn?
L7BCF:  BEQ PrepDigitPointer    ;If so, branch.

DrawDigit:
L7BD1:  AND #$0F                ;Save lower nibble and add 1 to it.
L7BD3:  CLC                     ;
L7BD4:  ADC #$01                ;Adding 1 skips the "space" character.

PrepDigitPointer:
L7BD6:  PHP                     ;Save the processor status on the stack.
L7BD7:  ASL                     ;*2. The digit pointers are 2 bytes.
L7BD8:  LDY #$00                ;Start at current vector RAM pointer position.
L7BDA:  TAX                     ;

L7BDB:  LDA CharPtrTbl,X        ;Load the JSR command that draws the appropriate digit.
L7BDE:  STA (VecRamPtr),Y       ;
L7BE0:  LDA CharPtrTbl+1,X      ;
L7BE3:  INY                     ;
L7BE4:  STA (VecRamPtr),Y       ;
L7BE6:  JSR VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

L7BE9:  PLP                     ;Restore the processor status from the stack.
L7BEA:  RTS                     ;

UnusedFunc00:
L7BEB:  LSR                     ;
L7BEC:  AND #$0F                ;Appears to be an unused function.
L7BEE:  ORA #$E0                ;

VecRamPtrUpdate:
L7BF0:  LDY #$01                ;Load upper byte of JSR word into vector RAM.
L7BF2:  STA (VecRamPtr),Y       ;
L7BF4:  DEY                     ;Decrement index to load lower byte.
L7BF5:  TXA                     ;
L7BF6:  ROR                     ;Convert byte into proper address format.
L7BF7:  STA (VecRamPtr),Y       ;Store lower byte.
L7BF9:  INY                     ;Increment index for proper JSR return address.
L7BFA:  BNE VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

VecRomJSR:
L7BFC:  LSR                     ;Shift right to preserve JSR upper address bit.
L7BFD:  AND #$0F                ;Keep upper address nibble.
L7BFF:  ORA #JsrOpcode          ;Add JSR opcode.
L7C01:  BNE VecRamPtrUpdate     ;Branch always. Update vector RAM with JSR.

MoveBeam:
L7C03:  LDY #$00                ;
L7C05:  STY MovBeamXUB          ;Zero out X and Y upper address bytes.
L7C07:  STY MovBeamYUB          ;

L7C09:  ASL                     ;
L7C0A:  ROL MovBeamXUB          ;
L7C0C:  ASL                     ;Break X address byte into the proper opcode format.
L7C0D:  ROL MovBeamXUB          ;
L7C0F:  STA MovBeamXLB          ;

L7C11:  TXA                     ;Move Y address byte into A

L7C12:  ASL                     ;
L7C13:  ROL MovBeamYUB          ;
L7C15:  ASL                     ;Break Y address byte into the proper opcode format.
L7C16:  ROL MovBeamYUB          ;
L7C18:  STA MovBeamYLB          ;

L7C1A:  LDX #$04                ;Prepare to load 4 bytes into vector RAM.

SetCURData:
L7C1C:  LDA VecRamPtrLB,X       ;Get lower byte of upper CUR word.
L7C1E:  LDY #$00                ;
L7C20:  STA (VecRamPtr),Y       ;Store it in vector RAM.

L7C22:  LDA VecRamPtrUB,X       ;Get upper byte of upper CUR word.
L7C24:  AND #$0F                ;
L7C26:  ORA #CurOpcode          ;Add CUR opcode to the CUR instruction.
L7C28:  INY                     ;
L7C29:  STA (VecRamPtr),Y       ;Store it in vector RAM.

L7C2B:  LDA VecRamPtrLB-2,X     ;Get lower byte of lower CUR word.
L7C2D:  INY                     ;
L7C2E:  STA (VecRamPtr),Y       ;Store it in vector RAM.

L7C30:  LDA VecRamPtrUB-2,X     ;Get upper byte of lower CUR word.
L7C32:  AND #$0F                ;
L7C34:  ORA GlobalScale         ;Add global scale data to the CUR instruction.
L7C36:  INY                     ;
L7C37:  STA (VecRamPtr),Y       ;Store it in vector RAM.

VecPtrUpdate:
L7C39:  TYA                     ;Y has the number of bytes to increment vector ROM pointer by.
L7C3A:  SEC                     ;
L7C3B:  ADC VecRamPtrLB         ;Update vector ROM pointer.
L7C3D:  STA VecRamPtrLB         ;
L7C3F:  BCC +                   ;Does upper byte of pointer need to increment? if not, branch.
L7C41:  INC VecRamPtrUB         ;Increment upper pointer byte.
L7C43:* RTS                     ;

VecRamRTS:
L7C44:  LDA #RtsOpcode          ;Prepare to write RTS opcode to vector RAM.
L7C46:  JMP VecRam2Write        ;($7BC2)Write the same byte twice to vector RAM.

;-------------------------------[ Calculate Ship Debris Position ]---------------------------------

;The purpose of this function is to calculate the proper starting point for the selected piece of
;ship debris.  It needs to take into account any out of bounds conditions if the ship is close to 
;any of the 4 edges of the display.  It draws a VEC with zero brightness to the proper starting
;position.

CalcDebrisPos:
L7C49:  LDA ThisDebrisXUB       ;Is the debris traveling in a negative X direction?
L7C4B:  CMP #$80                ;
L7C4D:  BCC ChkYDebris          ;If not, branch.

L7C4F:  EOR #$FF                ;Convert negative direction into a positive-->
L7C51:  STA ThisDebrisXUB       ;number by using two's compliment.
L7C53:  LDA ThisDebrisXLB       ;
L7C55:  EOR #$FF                ;Lower byte contains debris absolute value position.
L7C57:  ADC #$00                ;Upper byte contains debris direction.
L7C59:  STA ThisDebrisXLB       ;
L7C5B:  BCC +                   ;
L7C5D:  INC ThisDebrisXUB       ;
L7C5F:* SEC                     ;Set bit to indicate debris is moving in negative X direction.

ChkYDebris:
L7C60:  ROL GenByte08           ;Save X direction bit.

L7C62:  LDA ThisDebrisYUB       ;Is the debris traveling in a negative Y direction?
L7C64:  CMP #$80                ;
L7C66:  BCC ChkPosXYUB          ;If not, branch.

L7C68:  EOR #$FF                ;Convert negative direction into a positive-->
L7C6A:  STA ThisDebrisYUB       ;number by using two's compliment.
L7C6C:  LDA ThisDebrisYLB       ;
L7C6E:  EOR #$FF                ;Lower byte contains debris absolute value position.
L7C70:  ADC #$00                ;Upper byte contains debris direction.
L7C72:  STA ThisDebrisYLB       ;
L7C74:  BCC +                   ;
L7C76:  INC ThisDebrisYUB       ;
L7C78:* SEC                     ;Set bit to indicate debris is moving in negative Y direction.

ChkPosXYUB:
L7C79:  ROL GenByte08           ;Save Y direction bit.

L7C7B:  LDA ThisDebrisXUB       ;Is debris piece close to the lowest X or Y border?
L7C7D:  ORA ThisDebrisYUB       ;
L7C7F:  BEQ ChkPosXYLB          ;If so, branch to check lower byte for edge proximity.

ChkXYMaxBounds:
L7C81:  LDX #$00                ;Prepare to clip debris if at max XY position.
L7C83:  CMP #$02                ;Is debris at maximum XY edge of screen?
L7C85:  BCS SetScaleAndDirBits  ;If so, branch.

L7C87:  LDY #$01                ;Not at edge of screen. Prepare to calculate proper scaling.
L7C89:  BNE PrepXYMult2         ;

ChkPosXYLB:
L7C8B:  LDY #$02                ;Prepare to set scaling if not at screen edge.
L7C8D:  LDX #$09                ;Prepare to clip debris if at min XY position.
L7C8F:  LDA ThisDebrisXLB       ;
L7C91:  ORA ThisDebrisYLB       ;Is debris at minimum XY edge of screen?
L7C93:  BEQ SetScaleAndDirBits  ;If so, branch.

L7C95:  BMI PrepXYMult2         ;Is proper scaling already set? If so, branch.

CalcShiftVal:
L7C97:  INY                     ;
L7C98:  ASL                     ;Calculate proper scaling value for displacing this debris.
L7C99:  BPL CalcShiftVal        ;

PrepXYMult2:
L7C9B:  TYA                     ;Transfer scaling value to X.
L7C9C:  TAX                     ;
L7C9D:  LDA ThisDebrisXUB       ;Move debris X direction into A.

RestoreDebrisPos:
L7C9F:  ASL ThisDebrisXLB       ;
L7CA1:  ROL                     ;
L7CA2:  ASL ThisDebrisYLB       ;Restore the debris position from a single byte back to 2 bytes.
L7CA4:  ROL ThisDebrisYUB       ;
L7CA6:  DEY                     ;
L7CA7:  BNE RestoreDebrisPos    ;

L7CA9:  STA ThisDebrisXUB       ;Save restored upper byte of debris X position.

SetScaleAndDirBits:
L7CAB:  TXA                     ;
L7CAC:  SEC                     ;
L7CAD:  SBC #$0A                ;Compute scaling bits.
L7CAF:  EOR #$FF                ;
L7CB1:  ASL                     ;
L7CB2:  ROR GenByte08           ;Get Y direction bit.
L7CB4:  ROL                     ;
L7CB5:  ROR GenByte08           ;
L7CB7:  ROL                     ;Get X direction bit.
L7CB8:  ASL                     ;
L7CB9:  STA GenByte08           ;Save the completed configuration bits back to RAM.

L7CBB:  LDY #$00                ;Write the Y position lower byte to vector RAM.
L7CBD:  LDA ThisDebrisYLB       ;
L7CBF:  STA (VecRamPtr),Y       ;
L7CC1:  LDA GenByte08           ;
L7CC3:  AND #$F4                ;Get the scale and Y direction bits for the VEC opcode.
L7CC5:  ORA ThisDebrisYUB       ;Combine the Y position upper byte.
L7CC7:  INY                     ;
L7CC8:  STA (VecRamPtr),Y       ;Write the byte to vector RAM.
L7CCA:  LDA ThisDebrisXLB       ;
L7CCC:  INY                     ;
L7CCD:  STA (VecRamPtr),Y       ;Write the X position lower byte to vector RAM.
L7CCF:  LDA GenByte08           ;
L7CD1:  AND #$02                ;Get the X direction bit.
L7CD3:  ASL                     ;
L7CD4:  ORA GenByte01           ;Set brightness for this vector(should be 0).
L7CD6:  ORA ThisDebrisXUB       ;Combine the X position upper byte.
L7CD8:  INY                     ;
L7CD9:  STA (VecRamPtr),Y       ;Write the byte to vector RAM.
L7CDB:  JMP VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

;------------------------------------------[ Spot Kill ]-------------------------------------------

SpotKill:
L7CDE:  LDX #$00                ;Prepare to draw a dot with brightness 0.

DrawDot:
L7CE0:  LDY #$01                ;Store scale in vector RAM.
L7CE2:  STA (VecRamPtr),Y       ;
L7CE4:  DEY                     ;
L7CE5:  TYA                     ;
L7CE6:  STA (VecRamPtr),Y       ;Set X and Y delta values to 0.
L7CE8:  INY                     ;
L7CE9:  INY                     ;
L7CEA:  STA (VecRamPtr),Y       ;
L7CEC:  INY                     ;
L7CED:  TXA                     ;Store dot brightness in vector RAM.
L7CEE:  STA (VecRamPtr),Y       ;
L7CF0:  JMP VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

;--------------------------------------------[ Reset ]---------------------------------------------

IRQ:
RESET:
L7CF3:  LDX #$FE                ;Set stack pointer to #$FE
L7CF5:  TXS                     ;

L7CF6:  CLD                     ;Set processor to binary mode.

L7CF7:  LDA #Zero               ;Prepare to clear the RAM.
L7CF9:  TAX                     ;

RamClearLoop:
L7CFA:  DEX                     ;Loop until all RAM is zeroed.
L7CFB:  STA Player2Ram,X        ;
L7CFE:  STA Player1Ram,X        ;
L7D01:  STA OnePageRam,X        ;
L7D04:  STA ZeroPageRam,X       ;
L7D06:  BNE RamClearLoop        ;More bytes to clear? If so, loop to write more.

L7D08:  LDY SelfTestSw          ;Is the self test switch set for test mode?
L7D0B:  BMI DoSelfTest          ;If so, branch to do self test routine.

L7D0D:  INX                     ;Write JUMP to RAM address $4402 opcode to vector RAM.-->
L7D0E:  STX VectorRam           ;The vector RAM is divided in half and one half is written to-->
L7D11:  LDA #JumpOpcode+2       ;while the other half is read. The read/write halves are-->
L7D13:  STA VectorRam+1         ;swapped every frame.
L7D16:  LDA #HaltOpcode         ;
L7D18:  STA VectorRam+3         ;Write HALT opcode to vector RAM address $4002

L7D1B:  STA Plyr1Rank           ;Write some initial data to player's rank.
L7D1D:  STA Plyr2Rank           ;

L7D1F:  LDA #PlyrLamps          ;
L7D21:  STA MultiPurpBits       ;Turn on the Player 1 and 2 LEDs.
L7D23:  STA MultiPurp           ;

L7D26:  AND PlayTypeSw          ;Get how many coins to play a game
L7D29:  STA DipSwitchBits       ;

L7D2B:  LDA RghtCoinMechSw      ;
L7D2E:  AND #$03                ;
L7D30:  ASL                     ;Get the coin multiplier for the Right coin mech.
L7D31:  ASL                     ;
L7D32:  ORA DipSwitchBits       ;
L7D34:  STA DipSwitchBits       ;

L7D36:  LDA CentCMShipsSw       ;
L7D39:  AND #$02                ;
L7D3B:  ASL                     ;
L7D3C:  ASL                     ;Get the coin multiplier for the center coin mech.
L7D3D:  ASL                     ;
L7D3E:  ORA DipSwitchBits       ;
L7D40:  STA DipSwitchBits       ;

L7D42:  JMP InitGame            ;($6803)Initialize the game after reset.

VecWriteWord:
L7D45:  LDY #$00                ;Write 2 bytes into vector RAM.
L7D47:  STA (VecRamPtr),Y       ;
L7D49:  INY                     ;
L7D4A:  TXA                     ;
L7D4B:  STA (VecRamPtr),Y       ;
L7D4D:  JMP VecPtrUpdate        ;($7C39)Update Vector RAM pointer.

;--------------------------------------[ Self Test Routines ]--------------------------------------

DoSelfTest:
L7D50:  STA VectorRam,X         ;Loop and clear all 2K of vector RAM.
L7D53:  STA VectorRam+$100,X    ;
L7D56:  STA VectorRam+$200,X    ;
L7D59:  STA VectorRam+$300,X    ;
L7D5C:  STA VectorRam+$400,X    ;
L7D5F:  STA VectorRam+$500,X    ;
L7D62:  STA VectorRam+$600,X    ;
L7D65:  STA VectorRam+$700,X    ;
L7D68:  INX                     ;
L7D69:  BNE DoSelfTest          ;More RAM to clear? If so, branch.

L7D6B:  STA WdClear             ;Clear the watchdog timer.
L7D6E:  LDX #Zero               ;Prepare for RAM check test.

RamPage0TestLoop:
L7D70:  LDA GenZPAdrs00,X       ;RAM address to check should always start out as 0.
L7D72:  BNE RamPage0Fail        ;
L7D74:  LDA #$11                ;Four bit RAM. Load a single bit per RAM.

RamPage0ByteTest:
L7D76:  STA GenZPAdrs00,X       ;Store the bit pattern in RAM.
L7D78:  TAY                     ;Read the value back out of RAM.
L7D79:  EOR GenZPAdrs00,X       ;Compare it with itself.
L7D7B:  BNE RamPage0Fail        ;Is the value the same? If not, branch to failure.

L7D7D:  TYA                     ;Rotate the bit pattern in the RAM.
L7D7E:  ASL                     ;
L7D7F:  BCC RamPage0ByteTest    ;More bits to test at this address? If so, branch.

L7D81:  INX                     ;Done testing that RAM address.
L7D82:  BNE RamPage0TestLoop    ;More addresses in Page 0 to test? If so, branch.

L7D84:  STA WdClear             ;Clear the watchdog timer.

L7D87:  TXA                     ;Clear A by transferring the #$00 in X.
L7D88:  STA GenPtr00LB          ;Clear address $00.
L7D8A:  ROL                     ;Get the set carry bit and put in A. A = #$01.

RamTestNextPage:
L7D8B:  STA GenPtr00UB          ;Load the next bank upper address.
L7D8D:  LDY #Zero               ;Start at beginning of the bank.

RamPageNTestLoop:
L7D8F:  LDX #$11                ;Four bit RAM. Load a single bit per RAM.
L7D91:  LDA (GenPtr00),Y        ;Byte read should be equal to 0 at first.
L7D93:  BNE RamPageNFail        ;If not 0, branch. Bad RAM found.

RamPageNByteTest:
L7D95:  TXA                     ;Store the bit pattern in RAM.
L7D96:  STA (GenPtr00),Y        ;
L7D98:  EOR (GenPtr00),Y        ;Read the value back out and compare to the original.
L7D9A:  BNE RamPageNFail        ;Do the values match? If not, branch. Bad RAM.

L7D9C:  TXA                     ;Shift the bit pattern left by one.
L7D9D:  ASL                     ;
L7D9E:  TAX                     ;
L7D9F:  BCC RamPageNByteTest    ;Done writing to this address? If not branch.

L7DA1:  INY                     ;Increment to next address.
L7DA2:  BNE RamPageNTestLoop    ;Done with this page? If not, branch to write another byte.

L7DA4:  STA WdClear             ;Clear the watchdog timer.

L7DA7:  INC GenPtr00UB          ;Increment to the next page.
L7DA9:  LDX GenPtr00UB          ;
L7DAB:  CPX #MpuRamPages        ;Have the 4 MPU RAM pages been checked?
L7DAD:  BCC RamPageNTestLoop    ;If not, branch to check next page.

L7DAF:  LDA #VectorRamUB        ;MPU RAM check complete. Move on to vector RAM.
L7DB1:  CPX #VectorRamUB        ;More vector RAM to check?
L7DB3:  BCC RamTestNextPage     ;If so, branch to check more.

L7DB5:  CPX #VectorRamEndUB     ;Have all the vector RAM pages been checked?
L7DB7:  BCC RamPageNTestLoop    ;If not, branch to check the next one.
L7DB9:  BCS RomTest             ;RAM test passed. Move to the ROM/PROM test.

RamPage0Fail:
L7DBB:  LDY #$00                ;Zero page RAM failed, Y = #$00.
L7DBD:  BEQ MakeRamList         ;Branch always.

RamPageNFail:
L7DBF:  LDY #$00                ;MPU RAM failed, Y = #$00.
L7DC1:  LDX BadRamPage          ;Get RAM page that failed.
L7DC3:  CPX #MpuRamPages        ;Was it MPU RAM that failed?.
L7DC5:  BCC MakeRamList         ;If so, branch.

L7DC7:  INY                     ;Lower vector RAM failed, Y = #$01
L7DC8:  CPX #VectorRamUB+4      ;Was it lower vector RAM half that failed?.
L7DCA:  BCC MakeRamList         ;If so, branch.

L7DCC:  INY                     ;Upper vector RAM failed, Y = #$02.

MakeRamList:
L7DCD:  CMP #$10                ;Detected difference stored in A. If difference was in upper-->
L7DCF:  ROL                     ;nibble, upper RAM is bad and bit is rolled into LSB A.
L7DD0:  AND #$1F                ;Check for lower nibble difference.
L7DD2:  CMP #$02                ;If one exists, a bit will be rolled into LSB A.
L7DD4:  ROL                     ;
L7DD5:  AND #$03                ;Keep only two lower bits as they are the failure bits.

ShiftRamPairs:
L7DD7:  DEY                     ;Decrement Y to move to next RAM pairs.
L7DD8:  BMI BadRamToneLoop      ;Finished shifting? If so, play RAM tones.

L7DDA:  ASL                     ;Need to move the bad RAM pairs up in memory-->
L7DDB:  ASL                     ;to make room for the next RAM pairs.
L7DDC:  BCC ShiftRamPairs       ;More Ram pairs to shift? If so, branch.

BadRamToneLoop:
L7DDE:  LSR                     ;Move RAM good/bad bit to carry.
L7DDF:  LDX #GoodRamFreq        ;Assume RAM is good and prepare to play good RAM tone.
L7DE1:  BCC LoadRamThump        ;Is good/bad bit cleared? If so, branch. RAM is good.

L7DE3:  LDX #BadRamFreq         ;This is bad RAM. Load bad RAM thump frequency.

LoadRamThump:
L7DE5:  STX ThumpFreqVol        ;Play RAM tone.
L7DE8:  LDX #$00                ;
L7DEA:  LDY #$08                ;Play tone for 256*8 3KHz periods (.68 seconds).

BadRamPlayTone:
L7DEC:* BIT Clk3Khz             ;
L7DEF:  BPL -                   ;Wait for 1 3KHz period (333us).
L7DF1:* BIT Clk3Khz             ;
L7DF4:  BMI -                   ;

L7DF6:  DEX                     ;One more 3KHz period has passed.
L7DF7:  STA WdClear             ;Clear the watchdog timer.
L7DFA:  BNE BadRamPlayTone      ;Has 256 3KHz periods elapsed? If not, branch to wait more.

L7DFC:  DEY                     ;Another 256 3KHz periods have passed.
L7DFD:  BNE BadRamPlayTone      ;More time left to play RAM tone? If so, branch.

L7DFF:  STX ThumpFreqVol        ;Turn off thump SFX.
L7E02:  LDY #$08                ;Prepare to wait another .68 seconds.

BadRamWaitTone:
L7E04:* BIT Clk3Khz             ;
L7E07:  BPL -                   ;Wait for 1 3KHz period (333us).
L7E09:* BIT Clk3Khz             ;
L7E0C:  BMI -                   ;

L7E0E:  DEX                     ;One more 3KHz period has passed.
L7E0F:  STA WdClear             ;Clear the watchdog timer.
L7E12:  BNE BadRamWaitTone      ;Has 256 3KHz periods elapsed? If not, branch to wait more.

L7E14:  DEY                     ;Another 256 3KHz periods have passed.
L7E15:  BNE BadRamWaitTone      ;More time left to play RAM tone? If so, branch.

L7E17:  TAX                     ;Are there still more RAMs to play tones for?
L7E18:  BNE BadRamToneLoop      ;If so, branch to do the next RAM chip.

BadRamCheckTest:
L7E1A:  STA WdClear             ;Clear the watchdog timer.
L7E1D:  LDA SelfTestSw          ;Is self test still enabled?
L7E20:  BMI BadRamCheckTest     ;If so, loop until it is disabled.

BadRamSpinLock:
L7E22:  BPL BadRamSpinLock      ;Self test released. Spin lock until watchdog reset.

RomTest:
L7E24:  LDA #VectorRomLB        ;
L7E26:  TAY                     ;
L7E27:  TAX                     ;Point to the start of the vector ROM.
L7E28:  STA VecRomPtrLB         ;
L7E2A:  LDA #VectorRomUB        ;

RomTestKBLoop:
L7E2C:  STA VecRomPtrUB         ;Prepare to test 1Kb of ROM (#$0400 bytes).
L7E2E:  LDA #$04                ;
L7E30:  STA GenByte0B           ;
L7E32:  LDA #$FF                ;Prepare to invert all the bits.

RomTestBankLoop:
L7E34:  EOR (VecRomPtr),Y       ;Keep a running checksum on ROM contents.
L7E36:  INY                     ;Move to the next address.
L7E37:  BNE RomTestBankLoop     ;Is this page done? If not, branch to get another byte.

L7E39:  INC VecRomPtrUB         ;Move to next ROM page.
L7E3B:  DEC GenByte0B           ;Is 1 KB of ROM done?
L7E3D:  BNE RomTestBankLoop     ;If not, branch to start next page.

L7E3F:  STA RomChecksum,X       ;Store checksum for this 1Kb of ROM.              
L7E41:  INX                     ;Move to next checksum storage byte.

L7E42:  STA WdClear             ;Clear the watchdog timer.

L7E45:  LDA VecRomPtrUB         ;Are we at the end of the vector ROM?
L7E47:  CMP #VectorRomEndUB     ;If not, branch to get checksum of another Kb.
L7E49:  BCC RomTestKBLoop       ;

L7E4B:  BNE RomChecksumDone     ;Are checking the program ROM? If so, branch.

L7E4D:  LDA #ProgramRomUB       ;Start checking the program ROM.

RomChecksumDone:
L7E4F:  CMP #ProgramRomEndUB    ;Are we done checking the program ROM?
L7E51:  BCC RomTestKBLoop       ;If not, branch to do another Kb.

BankSwitchTest:
L7E53:  STA Player2Ram          ;Store ProgramRomEndUB(#$80) into RAM location $0300.

L7E56:  LDX #RamSwap            ;Swap RAM locations $0200-$02FF with $0300-$03FF.
L7E58:  STX MultiPurp           ;

L7E5B:  STX DiagStepState       ;Initialize DiagStepState with #$04. Draws initial-->
L7E5D:  LDX #$00                ;line on screen if DiagStep is active.

CheckPlr1Ram:
L7E5F:  CMP Player1Ram          ;The value of A stored in Player2Ram should now be here.
L7E62:  BEQ CheckPlr2Ram        ;Did the RAM swap successfully? If so, branch.

L7E64:  INX                     ;There was a RAM swap problem. Increment X.

CheckPlr2Ram:
L7E65:  LDA Player2Ram          ;The final bit pattern written in the RAM test routine-->
L7E68:  CMP #$88                ;Should be here.
L7E6A:  BEQ CheckSwapDone

L7E6C:  INX                     ;There was a RAM swap problem. Increment X.

CheckSwapDone:
L7E6D:  STX RamSwapResults      ;Store the results of the RAM swap test.

L7E6F:  LDA #$10                ;Written but not read.
L7E71:  STA GenByte00           ;

SelfTestMainLoop:
L7E73:  LDX #SelfTestWait       ;Wait for 36 3KHz periods(12 ms).

SelfTestWaitLoop:
L7E75:* LDA Clk3Khz             ;
L7E78:  BPL -                   ;Wait for 1 3KHz period (333us).
L7E7A:* LDA Clk3Khz             ;
L7E7D:  BMI -                   ;

L7E7F:  DEX                     ;Has 12 ms elapsed?
L7E80:  BPL SelfTestWaitLoop    ;If not, branch to wait some more.

VectorWaitLoop2:
L7E82:  BIT Halt                ;Is the vector state machine busy?
L7E85:  BMI VectorWaitLoop2     ;If so, loop until it is idle.

L7E87:  STA WdClear             ;Clear the watchdog timer.

L7E8A:  LDA #VectorRamLB        ;
L7E8C:  STA VecRamPtrLB         ;Set vector RAM pointer to start of RAM.
L7E8E:  LDA #VectorRamUB        ;
L7E90:  STA VecRamPtrUB         ;

L7E92:  LDA DiagStep            ;Is diagnostic step active?
L7E95:  BPL ShowDipStatus       ;If not, branch to next test.

L7E97:  LDX DiagStepState       ;Get current diagnostic step state.

L7E99:  LDA HyprSpcSw           ;Has the hyperspace button been pressed?
L7E9C:  BPL LoadDiagVects       ;If so, update diagnostic step.

UpdateDiagStep:
;7E9E:  EOR TestSFXInit_        ;***Incorrect assembly as zero page opcode***
L7E9E:  .byte $4D, $09, $00     ;Was hyperspace button just pressed?
L7EA1:  BPL LoadDiagVects       ;If not, branch to display current DiagStep lines.

L7EA3:  DEX                     ;Hyperspace was pressed. Can anymore DiagStep lines be added?
L7EA4:  BEQ LoadDiagVects       ;If not, branch to draw existing DiagStep lines.

L7EA6:  STX DiagStepState       ;Add another DiagStep line to the display.

LoadDiagVects:
L7EA8:  LDY DiagStepIdxTbL-1,X  ;Get the current address into the vector RAM.
L7EAB:  LDA #$B0                ;Add a HALT to the last addresses($B000).
L7EAD:  STA (VecRamPtr),Y       ;

L7EAF:  DEY                     ;Move down to the next word in the vector RAM.
L7EB0:  DEY                     ;

DiagStepWriteLoop:
L7EB1:  LDA DiagStepDatTbl,Y    ;Get next byte from the table below and write to vector RAM.
L7EB4:  STA (VecRamPtr),Y       ;

L7EB6:  DEY                     ;Any more bytes to write to vector RAM?
L7EB7:  BPL DiagStepWriteLoop   ;If so, branch to get another byte.

L7EB9:  JMP GetTestButtons      ;($7F9D)Jump to get user inputs.

;The values in the table are indexes to the data tables below.
;The actual index is the value in the table - 2. Must account
;for $B000 written to the end of each segment. The $B000 is
;overwritten by the next segment allowing drawing continuation.
DiagStepIdxTbL:
L7EBC: .byte $33, $1D, $17, $0D

DiagStepDatTbl:
;Draws the first line. Written to vector RAM at $4000.
L7EC0:  .word $A080, $0000      ;CUR  scale=0(/512) x=0     y=128  
L7EC4:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L7EC8:  .word $92FF, $73FF      ;VEC  scale=9(/1)   x=1023  y=767   b=7

;Draws the first line. Written to vector RAM at $400C.
L7ECC:  .word $A1D0, $0230      ;CUR  scale=0(/512) x=560   y=464  
L7ED0:  .word $7000, $0000      ;VEC  scale=7(/4)   x=0     y=0     b=0
L7ED4:  .word $FB7F             ;SVEC scale=3(/16)  x=-3    y=3     b=7

;Draws the third line. Written to vector RAM at $4016.
L7ED6:  .word $E00D             ;JMP  $401A
L7ED8:  .word $B000             ;HALT 
L7EDA:  .word $FA7E             ;SVEC scale=3(/16)  x=-2    y=2     b=7

;Draws the last triangle. Written to vector RAM at $401C.
L7EDC:  .word $C011             ;JSR  $4022
L7EDE:  .word $FE78             ;SVEC scale=3(/16)  x=0     y=-2    b=7
L7EE0:  .word $B000             ;HALT 
L7EE2:  .word $C013             ;JSR  $4026
L7EE4:  .word $D000             ;RTS 
L7EE6:  .word $C015             ;JSR  $402A
L7EE8:  .word $D000             ;RTS 
L7EEA:  .word $C017             ;JSR  $402E
L7EEC:  .word $D000             ;RTS 
L7EEE:  .word $F87A             ;SVEC scale=3(/16)  x=2     y=0     b=7
L7EF0:  .word $D000             ;RTS

ShowDipStatus:
L7EF2:  LDA #VectorRomUB        ;Prepare to load cross-hatch pattern on the screen.
L7EF4:  LDX #VectorRomLB        ;
L7EF6:  JSR VecRomJSR           ;($7BFC)Load JSR command in vector RAM to vector ROM.

L7EF9:  LDA #$69                ;X beam coordinate 4 * $69 = $1A4 = 420.
L7EFB:  LDX #$93                ;Y beam coordinate 4 * $93 = $24C = 588.
L7EFD:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L7F00:  LDA #$30                ;Set scale 3(/64).
L7F02:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L7F05:  LDX #$03                ;Prepare to read the 4 pairs of DIP switches.

DrawDipStatusLoop:
L7F07:  LDA DipSw,X             ;Get selected DIP switch pair status.
L7F0A:  AND #$01                ;Keep only lower DIP switch status.
L7F0C:  STX GenByte0B           ;Save a copy of the DIP pair currently being checked.
L7F0E:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F11:  LDX $0B                 ;Restore a copy of the DIP pair currently being checked.
L7F13:  LDA DipSw,X             ;Reload the selected DIP switch pair status.
L7F16:  AND #$02                ;Keep only upper DIP switch status.
L7F18:  LSR                     ;Move it to the LSB.
L7F19:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F1C:  LDX GenByte0B           ;Reload the selected DIP switch pair status.
L7F1E:  DEX                     ;Does another DIP switch pair need to be checked?
L7F1F:  BPL DrawDipStatusLoop   ;If so, branch to get the next pair.

L7F21:  LDA #$7A                ;X beam coordinate 4 * $7A = $1E8 = 488.
L7F23:  LDX #$9D                ;Y beam coordinate 4 * $9D = $274 = 628.
L7F25:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L7F28:  LDA #$10                ;Set scale 1(/256).
L7F2A:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

L7F2D:  LDA CentCMShipsSw       ;Get the center coin mechanism switch status and display it.
L7F30:  AND #$02                ;
L7F32:  LSR                     ;
L7F33:  ADC #$01                ;
L7F35:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F38:  LDA RghtCoinMechSw      ;Get the right coin mechanism switches status.
L7F3B:  AND #$03                ;
L7F3D:  TAX                     ;Use the switches status to display the coin multiplier value.
L7F3E:  LDA CoinMultTbl,X       ;
L7F41:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F44:  LDA RamSwapResults      ;Was there a RAM swap error?
L7F46:  BEQ VerifyChecksum      ;If not, branch to move to the next test.

L7F48:  LDX #<VecBankErr        ;Prepare to write bank error message to the display.
L7F4A:  LDA #>VecBankErr
L7F4C:  JSR VecRomJSR           ;($7BFC)Load JSR command in vector RAM to vector ROM.

VerifyChecksum:
L7F4F:  LDX #$96                ;Y beam coordinate 4 * $96 = $258 = 600.
;7F51:  STX GenByte0C_          ;***Incorrect assembly as zero page opcode***
L7F51:  .byte $8E, $0C, $00     ;Store base value for Y beam coordinate.

L7F54:  LDX #$07                ;Prepare to check all 8 checksum values.

ChecksumLoop:
L7F56:  LDA RomChecksum,X       ;Is this checksum correct?
L7F58:  BEQ NextChecksum        ;If so, branch to get next checksum.

L7F5A:  PHA                     ;Incorrect checksum. Save checksum value on stack.
;7F5B:  STX GenByte0B_          ;***Incorrect assembly as zero page opcode***
L7F5B:  .byte $8E, $0B, $00     ;Save current checksum index.

;7F5E:  LDX GenByte0C_          ;***Incorrect assembly as zero page opcode***
L7F5E:  .byte $AE, $0C, $00     ;Prepare to move the Y beam position to display failure info.

L7F61:  TXA                     ;Move the Y bean position down by 32.
L7F62:  SEC                     ;
L7F63:  SBC #$08                ;
;7F65:  STA GenByte0C_          ;***Incorrect assembly as zero page opcode***
L7F65:  .byte $8D, $0C, $00     ;Save new beam position.

L7F68:  LDA #$20                ;X beam coordinate 4 * $20 = $80 = 128.
L7F6A:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.

L7F6D:  LDA #$70                ;Set scale 7(/4).
L7F6F:  JSR SpotKill            ;($7CDE)Draw zero vector to prevent spots on the screen.

;7F72:  LDA GenByte0B_          ;***Incorrect assembly as zero page opcode***
L7F72:  .byte $AD, $0B, $00     ;Write failing checksum index to the display.
L7F75:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F78:  LDA CharPtrTbl          ;Point to first entry in character pointer table (space).
L7F7B:  LDX CharPtrTbl+1        ;Prepare to write a space to the display.
L7F7E:  JSR VecWriteWord        ;($7D45)Write 2 bytes to vector RAM.

L7F81:  PLA                     ;Get the incorrect checksum value again.
L7F82:  PHA                     ;Store it right back on the stack.

L7F83:  LSR                     ;
L7F84:  LSR                     ;Prepare to write the upper nibble to the display.
L7F85:  LSR                     ;
L7F86:  LSR                     ;

L7F87:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

L7F8A:  PLA                     ;Prepare to write the lower nibble to the display.
L7F8B:  JSR DrawDigit           ;($7BD1)Draw a single digit on the display.

;7F8E:  LDX GenByte0B_          ;***Incorrect assembly as zero page opcode***
L7F8E:  .byte $AE, $0B, $00     ;Get the next checksum index to check.

NextChecksum:
L7F91:  DEX                     ;Is there another checksum to check?
L7F92:  BPL ChecksumLoop        ;If so, branch.

L7F94:  LDA #$7F                ;X beam coordinate 4 * $7F = $1FC = 508.
L7F96:  TAX                     ;Y beam coordinate 4 * $7F = $1FC = 508.
L7F97:  JSR MoveBeam            ;($7C03)Move the CRT beam to a new location.
L7F9A:  JSR VecHalt             ;($7BC0)Halt the vector state machine.

GetTestButtons:
L7F9D:  LDA #$00                ;Prepare to get the statuses of 5 switches.
L7F9F:  LDX #$04                ;

GetBtnsLoop1:
L7FA1:  ROL HyprSpcSw,X         ;Get the status of: self test, slam, diagnostic step,-->
L7FA4:  ROR                     ; fire and hyperspace switches.
L7FA5:  DEX                     ;More switches to get the status of?
L7FA6:  BPL GetBtnsLoop1        ;If so, branch.

L7FA8:  TAY                     ;Prepare to get the statuses of 8 switches.
L7FA9:  LDX #$07                ;

GetBtnsLoop2:
L7FAB:  ROL LeftCoinSw,X        ;Get the status of: rotate left, rotate right, thrust,-->
L7FAE:  ROL                     ;2 player start, 1 player start, right coin, center coin-->
L7FAF:  DEX                     ; left coin switches.
L7FB0:  BPL GetBtnsLoop2        ;More switches to get the status of? If so, branch.

L7FB2:  TAX                     ;
L7FB3:  EOR GenByte08           ;Store bits indicating button changes.
L7FB5:  STX GenByte08           ;

L7FB7:  PHP                     ;Save processor status.

L7FB8:  LDA #RamSwap            ;Swap RAM pages.
L7FBA:  STA MultiPurp           ;

L7FBD:  ROL HyprSpcSw           ;
L7FC0:  ROL                     ;
L7FC1:  ROL FireSw              ;
L7FC4:  ROL                     ;
L7FC5:  ROL RotLeftSw           ;Save the statuses of the player inputs into X.
L7FC8:  ROL                     ;
L7FC9:  ROL RotRghtSw           ;
L7FCC:  ROL                     ;
L7FCD:  ROL ThrustSw            ;
L7FD0:  ROL                     ;
L7FD1:  TAX                     ;

L7FD2:  PLP                     ;Restore processor status.
L7FD3:  BNE ButtonChanged       ;Were buttons changed? if so, branch.

L7FD5:  EOR GenByte0A           ;Was a button change detected?
L7FD7:  BNE ButtonChanged       ;If so, branch to make a sound.

L7FD9:  TYA                     ;Was a button changed detected?
L7FDA:  EOR TestSFXInit         ;
L7FDC:  BEQ DoHardwareWrite     ;If not, branch to turn off the SFX.

ButtonChanged:
L7FDE:  LDA #EnableBit          ;Button change detected, set the MSB,

DoHardwareWrite:
L7FE0:  STA LifeSFX             ;Play/halt SFX.
L7FE3:  STA MultiPurp           ;No effect.
L7FE6:  STA DmaGo               ;Start/stop the vector state machine.

L7FE9:  STX GenByte0A           ;Store current button statuses.
L7FEB:  STY TestSFXInit         ;
L7FED:  LDA SelfTestSw          ;Is self test switch still on? If so, loop.

SelfTestSpinLock1:
L7FF0:  BPL SelfTestSpinLock1   ;self test released. Spin lock until watchdog reset.

L7FF2:  JMP SelfTestMainLoop    ;($7E73)Stay in self test loop.

;The table below sets the right coin mechanism multiplier
;based on the settings of DIP switches 5 and 6.
CoinMultTbl:
L7FF5:  .byte $01, $04, $05, $06

;----------------------------------------[ Checksum Byte ]-----------------------------------------

L7FF9:  .byte $4E               ;Checksum byte.

;--------------------------------------[ Interrupt Vectors ]---------------------------------------

L7FFA:  .word NMI               ;($7B65)NMI vector.
L7FFC:  .word RESET             ;($7CF3)Reset vector.
L7FFE:  .word IRQ               ;($7CF3)IRQ vector.
