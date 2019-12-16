;Most of the information in this file was already mapped out.
;I found a great deal of this information on:
;http://computerarcheology.com/Arcade/Asteroids/RAMUse.html
;Mad props to Lonnie Howell and Mark McDougall
;This code is fully assemblable using Ophis.
;Last updated 7/28/2018 by Nick Mikstas.

;--------------------------------------[ Memory Boundaries ]---------------------------------------

.alias ZeroPageRam      $00     ;Through $00FF.
.alias OnePageRam       $0100   ;Through $01FF. The stack resides here.
.alias Player1Ram       $0200   ;Through $02FF. A total of 1K MCU RAM.
.alias Player2Ram       $0300   ;Through $03FF.
.alias VectorRam        $4000   ;Through $47FF. A total of 2K of vector RAM.
.alias VectorRom        $5000   ;Through $57FF. A total of 2k of vector ROM.

.alias VectorRamLB      $00     ;Lower byte of start of vector RAM.
.alias VectorRamUB      $40     ;Upper byte of start of vector RAM.
.alias VectorRamEndLB   $00     ;Lower byte of end of vector RAM.
.alias VectorRamEndUB   $48     ;Upper byte of end of vector RAM.

.alias VectorRomLB      $00     ;Lower byte of start of vector ROM.
.alias VectorRomUB      $50     ;Upper byte of start of vector ROM.
.alias VectorRomEndLB   $00     ;Lower byte of end of vector ROM.
.alias VectorRomEndUB   $58     ;Upper byte of end of vector ROM.

.alias ProgramRomLB     $00     ;Lower byte of start of program ROM.
.alias ProgramRomUB     $68     ;Upper byte of start of program ROM.
.alias ProgramRomEndLB  $00     ;Lower byte of end of program ROM.
.alias ProgramRomEndUB  $80     ;Upper byte of end of program ROM.

;----------------------------------------------[ RAM ]---------------------------------------------

.alias GenZPAdrs00      $00     ;General zero page address.
.alias GenZPAdrs01      $01     ;General zero page address.

.alias GenByte00        $00     ;General use byte.
.alias GenByte01        $01     ;General use byte.

.alias GenPtr00         $00     ;General use pointer.
.alias GenPtr00LB       $00     ;General use pointer, lower byte.
.alias GenPtr00UB       $01     ;General use pointer, upper byte.

.alias GenWrd00         $00     ;General use word.
.alias GenWrd00LB       $00     ;General use word, lower byte.
.alias GenWrd00UB       $01     ;General use word, upper byte.

.alias GlobalScale      $00     ;Stores global scale info when building CUR instruction.
.alias BadRamPage       $01     ;Contains memory page that failed the RAM test.

.alias VecRamPtr        $02     ;Pointer to current vector RAM location.
.alias VecRamPtrLB      $02     ;Pointer to current vector RAM location, lower byte.
.alias VecRamPtrUB      $03     ;Pointer to current vector RAM location, upper byte.

.alias ThisDebrisXLB    $04     ;Current debris piece to draw, X position, lower byte.
.alias ThisDebrisXUB    $05     ;Current debris piece to draw, X position, upper byte.
.alias ThisDebrisYLB    $06     ;Current debris piece to draw, Y position, lower byte.
.alias ThisDebrisYUB    $07     ;Current debris piece to draw, Y position, upper byte.

.alias ThisObjXLB       $04     ;Current object to draw, X position, lower byte.
.alias ThisObjXUB       $05     ;Current object to draw, X position, upper byte.
.alias ThisObjYLB       $06     ;Current object to draw, Y position, lower byte.
.alias ThisObjYUB       $07     ;Current object to draw, Y position, upper byte.

.alias MovBeamXLB       $04     ;Stores X position, lower byte when building CUR instruction.
.alias MovBeamXUB       $05     ;Stores X position, upper byte when building CUR instruction.
.alias MovBeamYLB       $06     ;Stores Y position, lower byte when building CUR instruction.
.alias MovBeamYUB       $07     ;Stores Y position, upper byte when building CUR instruction.

.alias GenByte08        $08     ;General use byte.

.alias ObjXDiff         $08     ;Difference in two object's X coordinates.
.alias ObjYDiff         $09     ;Difference in two object's Y coordinates.

.alias ShipDrawXInv     $08     ;Used to invert X direction of ship while rendering.
.alias ShipDrawYInv     $09     ;Used to invert Y direction of ship while rendering.

.alias VecRomPtr        $08     ;Pointer to current vector ROM location.
.alias VecRomPtrLB      $08     ;Pointer to current vector ROM location, lower byte.
.alias VecRomPtrUB      $09     ;Pointer to current vector ROM location, upper byte.

.alias TestSFXInit_     $0009   ;Used to start SFX during self test routines.
.alias TestSFXInit      $09     ;Used to start SFX during self test routines.

.alias ObjectXPosNeg    $08     ;#$00 if bullet moving right, #$FF if bullet moving left.
.alias ShipDebrisPtr    $09     ;Index to ship debris vector data while ship is exploding.
.alias ShotXDir         $09     ;Stores copy of ship/bullet X direction.

.alias GenByte0B_       $000B   ;General use byte.
.alias GenByte0C_       $000C   ;General use byte.

.alias GenByte0A        $0A     ;General use byte.
.alias GenByte0B        $0B     ;General use byte.

.alias Obj2Status       $0B     ;Copy of object 2 status during hit detection routine.
.alias ObjHitBox        $0B     ;Hit box value for the item that got hit.

.alias VecPtr_          $0B     ;Vector RAM/ROM pointer.
.alias VecPtrLB_        $0B     ;Vector RAM/ROM pointer, lower byte.
.alias VecPtrUB_        $0C     ;Vector RAM/ROM pointer, upper byte.

.alias GenByte0C        $0C     ;General use byte.
.alias GenByte0D        $0D     ;General use byte.
.alias GenByte0E        $0E     ;General use byte.

.alias ObjectYPosNeg    $0B     ;#$00 if bullet moving up, #$FF if bullet moving down.
.alias ShotAngleTemp    $0B     ;Working variable for calculating shot angle look up index.
.alias ShotYDir         $0C     ;Stores copy of ship/bullet Y direction.
.alias ShotXYDistance   $0C     ;Stores XY components of small saucer shot for angle calculation.
.alias SelInitial       $0C     ;Current initial selected on high score entry screen(0 to 2).
.alias ShipScrShot      $0D     ;Stores index to current bullet type to process (ship or saucer).
.alias RomChecksum      $0D     ;Through $14 Stores result of ROM Kb checksums.
.alias NumBulletSlots   $0E     ;Number of bullet slots. #$01 for saucer, #$03 for ship.

.alias HiScrRank        $0D     ;The current rank of the high score being drawn.
.alias HiScrBeamYLoc    $0E     ;Saves of the Y beam location while drawing high score list.
.alias HiScrIndex       $0F     ;Saves the current high score while drawing high score list.
.alias InitialIndex     $10     ;Current index to initial in high scores being processed.

.alias BCDAddress       $15     ;Stored address of BCD data byte(can only be zero page address).
.alias BCDIndex         $16     ;Index to BCD data byte.
.alias ZeroBlankBypass  $17     ;Fag to determine if zero blanking should be overridden.

.alias DiagStepState    $15     ;Keep track of which lines are drawn during diagnostic step.
.alias RamSwapResults   $16     ;#$00=No RAM swap problems. Any other value indicates a problem.
.alias ShipDrawUnused   $17     ;Always #$00. Was used for something in ship drawing routines.

.alias CurrentPlyr      $18     ;Current active player. #$00=Player 1, #$01=Player 2.
.alias ScoreIndex       $19     ;Offset to current player's score registers.
.alias PrevGamePlyrs    $1A     ;Number of players in the game that just ended.

.alias NumPlayers       $1C     ;Indicates if there is 1 or 2 players.
.alias HighScores_      $001D   ;Base address of high scores.
.alias HighScores       $1D     ;Through $30. Top 10 high scores. 2 bytes each.
.alias HiScoreBcdLo     $1D     ;Lower 2 BCD digits of high score.
.alias HiScoreBcdHi     $1E     ;Upper 2 BCD digits of high score.
.alias HiScoreBcdLo_    $001D   ;Lower 2 BCD digits of high score.
.alias HiScoreBcdHi_    $001E   ;Upper 2 BCD digits of high score.
.alias ThisInitial      $31     ;Current initial selected on high score entry screen(0-2).
.alias Plyr1Rank        $32     ;Player 1 rank in top score list*3 (0,3,6,9, etc).
.alias Plyr2Rank        $33     ;Player 2 rank in top score list*3 (0,3,6,9, etc).
.alias HighScoreIntls_  $0034   ;Base address of high score initials.
.alias HighScoreIntls   $34     ;Through $51. High score initials. 3 bytes each.
.alias PlayerScores     $52     ;Base address of the player's scores.
.alias Plr1ScoreBase    $52     ;Base address of Player 1's score.
.alias Plr1ScoreTens    $52		;Player 1 Score Tens(In BCD).
.alias Plr1ScoreThous   $53		;Player 1 Score Thousands(In BCD).
.alias Plr1ScoreThous_  $0053   ;Player 1 Score Thousands(In BCD).
.alias Plr2ScoreBase    $54     ;Base address of Player 2's score.
.alias Plr2ScoreTens    $54		;Player 2 Score Tens(In BCD).
.alias Plr2ScoreThous   $55		;Player 2 Score Thousands(In BCD).
.alias ShipsPerGame     $56     ;Number of ships a player starts with.
.alias Plyr1Ships       $57     ;Current number of player 1 ships.
.alias Plyr2Ships       $58     ;Current number of player 2 ships.
.alias HyprSpcFlag      $59     ;#$00=N0 hyperspace, #$01=Jump successful, #$80=Jump unsuccessful.
.alias PlyrDispTimer    $5A     ;Timer to display Player 1/Player 2 between waves.
.alias FrameCounter     $5B     ;Increments every 4 NMIs. If game loop not running, causes reset.
.alias FrameTimerLo     $5C     ;16-bit timer increments every frame, lower byte.
.alias FrameTimerHi     $5D     ;16-bit timer increments every frame, upper byte.
.alias NmiCounter       $5E     ;Increments every NMI period.
.alias RandNumLB        $5F     ;Low byte of random number word.
.alias RandNumUB        $60     ;High byte of random number word.
.alias ShipDir          $61     ;Player's ship direction.
.alias ScrBulletDir     $62     ;Saucer bullet direction.
.alias InitialDebounce  $63     ;Debounces hyperspace switch while entering initials.
.alias ShipBulletSR     $63     ;Shift register for limiting ship fire rate.
.alias ShipXAccel       $64     ;Ship acceleration in the X direction.
.alias ShipYAccel       $65     ;Ship acceleration in the Y direction.
.alias SFXTimers        $66     ;Starting address for SFX timers.
.alias FireSFXTimer     $66     ;Time to play fire SFX.
.alias ScrFrSFXTimer    $67     ;Time to play saucer fire SFX.
.alias ExLfSFXTimer     $68     ;Time to play extra life SFX.
.alias ExplsnSFXTimer   $69     ;Time to play explosion SFX.
.alias ShipFireSFX_     $6A     ;Controls the ship fire SFX.
.alias SaucerFireSFX_   $6B     ;Controls the saucer fire SFX.
.alias ThisVolFreq      $6C     ;Current settings for the thump frequency and volume.
.alias ThmpOnTime       $6D     ;Time thump SFX stays on.
.alias ThumpOffTime     $6E     ;Time thump SFX stays off.
.alias MultiPurpBits    $6F     ;Storage for bits to set in the MultiPurp register.
.alias NumCredits       $70     ;Current number of credits.
.alias DipSwitchBits    $71     ;Storage for dip switch values.
.alias SlamTimer        $72     ;Decrements from #$0F if slam detected during coin insertion.
.alias CoinMult         $73     ;Number of coins after multipliers.
.alias ValidCoins       $74     ;Base address for valid coin registers below.
.alias LValidCoin       $74     ;Indicate left coin mechanism valid coin.
.alias CValidCoin       $75     ;Indicate center coin mechanism valid coin.
.alias RValidCoin       $76     ;Indicate right coin mechanism valid coin.
.alias WaitCoinTimers   $77     ;Base address for timers below.
.alias LWaitCoinTimer   $77     ;Countdown timer before another left coin will be recognized.
.alias CWaitCoinTimer   $78     ;Countdown timer before another center coin will be recognized.
.alias RWaitCoinTimer   $79     ;Countdown timer before another right coin will be recognized.
.alias CoinDropTimers   $7A     ;Base address for timers below.
.alias LCoinDropTimer   $7A     ;Countdown timer for left coin passing into system.
.alias CCoinDropTimer   $7B     ;Countdown timer for center coin passing into system.
.alias RCoinDropTimer   $7C     ;Countdown timer for right coin passing into system.
.alias ShpDebrisXVelLB  $7D     ;Through $88. X velocity of ship debris pieces, lower byte.
.alias ShpDebrisXVelUB  $7E     ;Through $88. X velocity of ship debris pieces, upper byte.
.alias ShpDebrisYVelLB  $89     ;Through $94. Y velocity of ship debris pieces, lower byte.
.alias ShpDebrisYVelUB  $8A     ;Through $94. Y velocity of ship debris pieces, upper byte.

.alias StackTop         $01D0   ;The stack should never grow past this point.
.alias StackBottom      $01FF   ;The stack should never shrink to this point.

.alias AstStatus        $0200   ;Through $021A. 17 asteroids max-their current status:
                                ;The bits are arranged as follows: EEETTSSS
                                ;EEE - Explosion timer.  If the MSB is set, asteroid exploding.
                                ;When the timer reaches F, the explosion disappears.
                                ;TT  - Asteroid type. One of the 4 asteroid types.
                                ;SSS - Asteroid size. 001=small, 010=medium, 100=large.
.alias ShipStatus       $021B   ;0=No Ship Or In Hyperspace, 1=Alive, $A0-$FF=Ship Exploding.
.alias ScrStatus        $021C   ;0=No Saucer, 1=Small Saucer, 2=Large Saucer, MSB set=Exploding.
.alias ScrShotTimer     $021D   ;Through $021E. Timers for current saucer bullets.
.alias ShpShotTimer     $021F   ;Through $0222. Timers for current ship bullets.
.alias AstXSpeed        $0223   ;Through $023D. Asteroid horiz speed. 255-192=Left, 1-63=Right.
.alias ShipXSpeed       $023E   ;Ship horizontal speed.
.alias SaucerXSpeed     $023F   ;Saucer horizontal speed.
.alias ScrShotXSpeed    $0240   ;Through $0241. Saucer bullet horizontal speed.
.alias ShipShotXSpeed   $0242   ;Through $0245. Ship bullet horizontal speed.
.alias AstYSpeed        $0246   ;Through $0260. Asteroid vert speed. 255-192=Down, 1-63=Up. 
.alias ShipYSpeed       $0261   ;Ship vertical speed.
.alias SaucerYSpeed     $0262   ;Saucer vertical speed.
.alias ScrShotYSpeed    $0263   ;Through $0264. Saucer bullet vertical speed.
.alias ShipShotYSpeed   $0265   ;Through $0268. Ship bullet vertical speed.
.alias AstXPosHi        $0269   ;Through $0283. Asteroid horz position, high byte.
.alias shipXPosHi       $0284   ;Ship X position, high byte.
.alias ScrXPosHi        $0285   ;Saucer X position, high byte.
.alias ScrShotXPosHi    $0286   ;Through $0287. Saucer bullets X position, high byte.
.alias ShipShotXPosHi   $0288   ;Through $02AB. Ship bullets X position, high byte.
.alias AstYPosHi        $028C   ;Through $02A6. Asteroid vert position, high byte.
.alias ShipYPosHi       $02A7   ;Ship Y position, high byte.
.alias ScrYPosHi        $02A8   ;Saucer Y position, high byte.
.alias ScrShotYPosHi    $02A9   ;Through $02AA. Saucer bullets Y position, high byte.
.alias ShipShotYPosHi   $02AB   ;Through $02AE. Ship bullets Y position, high byte.
.alias AstXPosLo        $02AF   ;Through $02C9. Asteroid horz position, low byte.
.alias ShipXPosLo       $02CA   ;Ship X position, low byte.
.alias ScrXPosLo        $02CB   ;Saucer X position, low byte.
.alias ScrShotXPosLo    $02CC   ;Through $02CD. Saucer bullets X position, low byte.
.alias ShipShotXPosLo   $02CE   ;Through $02D1. Ship bullets X position, low byte.
.alias AstYPosLo        $02D2   ;Through $02EC. Asteroid vert position, low byte.
.alias ShipYPosLo       $02ED   ;Ship Y position, low byte.
.alias ScrYPosLo        $02EE   ;Saucer Y position, low byte.
.alias ScrShotYPosLo    $02EF   ;Through $02F0. Saucer bullets Y position, low byte.
.alias ShipShotYPosLo   $02F1   ;Through $02F4. Ship bullets Y position, low byte.
.alias AstPerWave       $02F5   ;Asteroids per wave.
.alias CurAsteroids     $02F6   ;Current number of asteroids.
.alias ScrTimer         $02F7   ;Countdown timer for saucer spawn.
.alias ScrTmrReload     $02F8   ;Reload value for saucer timer.
.alias AstBreakTimer    $02F9   ;Set after asteroid hit. Prevents saucer spawn after last asteroid.
.alias ShipSpawnTmr     $02FA   ;Ship spawn timer. #$81=waiting to re-spawn.
.alias ThmpSpeedTmr     $02FB   ;Timer That controls thump SFX speed.
.alias ThmpOffReload    $02FC   ;Reload value for ThumpOffTime register.
.alias ScrSpeedup       $02FD   ;Saucer occurrences increase if asteroid count is below this value.

;--------------------------------------[ Hardware Mapped IO ]--------------------------------------

.alias Clk3Khz          $2001   ;3KHz clock.
.alias Halt             $2002   ;Halt gives the vector state machine status. 1=busy, 0=idle.
.alias HyprSpcSw        $2003   ;Hyperspace button status.
.alias FireSw           $2004   ;Fire button status.
.alias DiagStep         $2005   ;Diagnostic step. Draws diagonal lines on screen.
.alias SlamSw           $2006   ;Slam switch status.
.alias SelfTestSw       $2007   ;Self test DIP switch status.

.alias LeftCoinSw       $2400   ;Left coin switch status.
.alias CntrCoinSw       $2401   ;Center coin switch status.
.alias RghtCoinSw       $2402   ;Right coin switch status.
.alias Player1Sw        $2403   ;Player 1 button status.
.alias Player2Sw        $2404   ;Player 2 button status.
.alias ThrustSw         $2405   ;Thrust button status.
.alias RotRghtSw        $2406   ;Rotation right button status.
.alias RotLeftSw        $2407   ;Rotation left button status.

.alias DipSw            $2800   ;Base address for the DIP switches.
.alias PlayTypeSw       $2800   ;Play type DIP switches (switches 7 and 8);
.alias RghtCoinMechSw   $2801   ;Coin multiplier DIP switches for right coin mechanism.
.alias CentCMShipsSw    $2802   ;Coin multiplier center coin mechanism, ships per play DIP switches.
.alias LanguageSw       $2803   ;Language selection DIP switches.

.alias DmaGo            $3000   ;Writing this address starts the vector state machine.

.alias MultiPurp        $3200   ;Multipurpose write register. Below are the bit functions:
                                ;%00000001 - Player 2 button lamp control.
                                ;%00000010 - Player 1 button lamp control.
                                ;%00000100 - RAM select: swap RAM bank 2 and 3.
                                ;%00001000 - Enable/disable left coin counter.
                                ;%00010000 - Enable/disable center coin counter.
                                ;%00100000 - Enable/disable right coin counter.
                                ;%01000000 - Not used.
                                ;%10000000 - Not used.

.alias WdClear          $3400   ;Clears the watchdog timer.

.alias ExpPitchVol      $3600   ;Controls the explosion SFX pitch and volume.
.alias ThumpFreqVol     $3A00   ;Controls the thump frequency and volume.
.alias SaucerSFX        $3C00   ;Controls the saucer sound.
.alias SaucerFireSFX    $3C01   ;Controls the saucer fire SFX.
.alias SaucerSFXSel     $3C02   ;Controls the frequency of the saucer SFX.
.alias ShipThrustSFX    $3C03   ;Controls the ship thrust SFX.
.alias ShipFireSFX      $3C04   ;Controls the ship fire SFX.
.alias LifeSFX          $3C05   ;Controls the life SFX.
.alias NoiseReset       $3E00   ;Resets the noise SFX.

;------------------------------------------[ Constants ]-------------------------------------------

.alias Zero             $00     ;Constant zero.
.alias MpuRamPages      $04     ;four pages = 1k MPU RAM.
.alias SelfTestWait     $24     ;36 3Khz clock wait (.144 seconds).
.alias BadRamFreq       $1D     ;Thump frequency setting for bad RAM.
.alias GoodRamFreq      $14     ;Thump frequency setting for good RAM.
.alias EnableBit        $80     ;The MSB is used to check/set hardware enables.
.alias MaxAsteroids     $1A     ;Max number of asteroids(26+1 = 27).
.alias ShipIndex        $1B     ;Index to ship status.
.alias ScrIndex         $1C     ;Index to saucer status.

.alias LargeAst         $04     ;Large asteroid.
.alias MediumAst        $02     ;Medium asteroid.
.alias SmallAst         $01     ;Small asteroid.

.alias LargeAstPnts     $02     ;20 points for a Large asteroid hit.
.alias MedAstPnts       $05     ;50 points for medium asteroid hit.
.alias SmallAstPnts     $10     ;100 points for a small asteroid hit.
.alias LargeScrPnts     $20     ;200 points for a large saucer hit.
.alias SmallScrPnts     $99     ;990 points for a small saucer hit.

.alias HghScrText       $00     ;HIGH SCORES 
.alias PlyrText         $01     ;PLAYER
.alias YrScrText        $02     ;YOUR SCORE IS ONE OF THE TEN BEST 
.alias InitText         $03     ;PLEASE ENTER YOUR INITIALS
.alias PshRtText        $04     ;PUSH ROTATE TO SELECT LETTER 
.alias PshHypText       $05     ;PUSH HYPERSPACE WHEN LETTER IS CORRECT 
.alias PshStrtText      $06     ;PUSH START 
.alias GmOvrText        $07     ;GAME OVER
.alias OneTwoText       $08     ;1 COIN 2 PLAYS 
.alias OneOneText       $09     ;1 COIN 1 PLAY 
.alias TwoOneText       $0A     ;2 COINS 1 PLAY 

.alias Vec0Opcode       $00     ;VEC vector state machine opcode.
.alias Vec1Opcode       $01     ;VEC vector state machine opcode.
.alias Vec2Opcode       $02     ;VEC vector state machine opcode.
.alias Vec3Opcode       $03     ;VEC vector state machine opcode.
.alias Vec4Opcode       $04     ;VEC vector state machine opcode.
.alias Vec5Opcode       $05     ;VEC vector state machine opcode.
.alias Vec6Opcode       $06     ;VEC vector state machine opcode.
.alias Vec7Opcode       $07     ;VEC vector state machine opcode.
.alias Vec8Opcode       $08     ;VEC vector state machine opcode.
.alias Vec9Opcode       $09     ;VEC vector state machine opcode.
.alias CurOpcode        $A0     ;CUR vector state machine opcode.
.alias HaltOpcode       $B0     ;HALT vector state machine opcode.
.alias JsrOpcode        $C0     ;JSR vector state machine opcode.
.alias RtsOpcode        $D0     ;RTS vector state machine opcode.
.alias JumpOpcode       $E0     ;JUMP vector state machine opcode.
.alias SvecOpcode       $F0     ;SVEC vector state machine opcode.

.alias Plyr2Lamp        $01     ;Illuminate player 2 button lamp.
.alias Plyr1Lamp        $02     ;Illuminate player 1 button lamp.
.alias PlyrLamps        $03     ;Illuminate both player button lamps.
.alias RamSwap          $04     ;Swap RAM banks 2 and 3.
.alias CoinCtrLeft      $08     ;Enable left coin counter.
.alias CoinCtrCntr      $10     ;Enable center coin counter.
.alias CoinCtrRght      $20     ;Enable right coin counter.

.alias Coin2Play1       $00     ;2 coins for 1 play.
.alias Coin1Play1       $01     ;1 coin for 1 play.
.alias Coin1Play2       $02     ;1 coin for 2 plays.
.alias FreePlay         $03     ;Free play enabled.

.alias CoinRX1          $03     ;Right coin mechanism multiplier X 1.
.alias CoinRX4          $02     ;Right coin mechanism multiplier X 4.
.alias CoinRX5          $01     ;Right coin mechanism multiplier X 5.
.alias CoinRX6          $00     ;Right coin mechanism multiplier X 6.

.alias CoinLX1          $01     ;Left coin mechanism multiplier X 1.
.alias CoinLX2          $00     ;Left coin mechanism multiplier X 2.

.alias ShipsX3          $00     ;3 ships per game.
.alias ShipsX4          $01     ;4 ships per game.

.alias English          $03     ;English language DIP switch settings.
.alias German           $02     ;German language DIP switch settings.
.alias French           $01     ;French language DIP switch settings.
.alias Spanish          $00     ;Spanish language DIP switch settings.

.alias ExpPitch         $C0     ;Explosion pitch control bits.
.alias ExpVolume        $3C     ;Explosion volume control bits.
.alias ThumpFreq        $0F     ;Thump frequency control bits.
.alias ThumpVol         $10     ;Thump volume control bit.
