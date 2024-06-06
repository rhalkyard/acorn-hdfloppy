ON ERROR PRINT REPORT$;" in Line ";ERL:END
DIM modmem% 64*1024

REM Patch locations
loc_help_date=&0043
loc_discop_allow_hd=&3040
loc_sector_count_timeout=&34A8
loc_identify_hd=&3AD0
loc_format_allow_hd=&3D04
loc_1772_density_bitmap=&6FFC

OSCLI "*Load ADFS "+STR$~(modmem%)
PROCasmpatch(modmem%)
OSCLI " *SAVE HDADFS "+STR$~(modmem%)+" +"+STR$~(P%)
OSCLI " *SETTYPE HDADFS Module"
END

DEF PROCasmpatch(mb%)
FOR pass%=4 TO 6 STEP 2
PROCpatch(mb%)

REM These patch routines get appended to the end of the module.
REM the first instruction of each of these routines is the
REM instruction that is overwritten by the branch to the patch.
P%=&8434
O%=mb%+&8434
[OPT pass%
REM Allow high density DiscOps
.patch_discop_allow_hd
  TEQNE   R14,#2 : REM Test double density (original insn.)
  TEQNE   R14,#4 : REM Test quad/high density
  B       loc_discop_allow_hd+4

REM Identify HD discs using track size as heuristic
REM Track size calculated as sector_size * sector_count
REM i.e. excluding all overhead
.patch_identify_hd
  REM R5=disc record, R6=sectors per track, R4=log2(sector size)
  REM Write sectors per track to disc record (original insn.)
  STRB    R6,[R5,#1]
  REM Total track size=R6*2^R4
  MOV     R14,R6,ASL R4
  REM Check track size against 6K theoretical max. for DD.
  REM No reasonable DD format will be this big (ADFS E = 5K)
  REM Any reasonable HD format will be much bigger (ADFS F = 10K)
  CMPS    R14,#6144
  REM If > 6K, then we have an HD disc, update the disc record
  MOVHI   R14,#4
  REM Density field is byte at offset 3 of disc record
  STRHIB  R14,[R5,#3]
  B       loc_identify_hd+4

REM Allow formatting as high density
.patch_format_allow_hd
  TEQNE   R6,#2 : REM Test double density (original insn.)
  TEQNE   R6,#4 : REM Test quad/high density
  B       loc_format_allow_hd+4
]
NEXT
ENDPROC

DEF PROCpatch(mb%)

REM Tack "HD" onto alignment padding at end of help string
PROCat(loc_help_date, mb%)
[OPT pass%:EQUS "(":EQUS FNdate:EQUS ") HD":EQUB 0:]

REM Increase sector-counting timeout for 150RPM operation
REM Time is in 10ms ticks. 410ms = 1/150s + 1 tick
PROCat(loc_sector_count_timeout, mb%):[OPT pass%:MOVLS R0,#41:]

REM Enable high density bit in 1772 controller definition
REM Was &6 (densities 1 and 2)
PROCat(loc_1772_density_bitmap, mb%):[OPT pass%:equd &16:]

REM Insert branches to longer patch routines appended to module
PROCat(loc_discop_allow_hd, mb%)
[OPT pass%:BNE patch_discop_allow_hd:]
PROCat(loc_identify_hd, mb%)
[OPT pass%:B   patch_identify_hd:]
PROCat(loc_format_allow_hd, mb%)
[OPT pass%:BNE patch_format_allow_hd:]
ENDPROC

DEF PROCat(addr%, mb%)
P%=addr%
O%=mb%+addr%
ENDPROC

DEF FNdate
DIM date% 64
?date%=3:SYS "OS_Word",&0E,date%
SYS "OS_ConvertDateAndTime",date%,date%+16,32,"%DY %M3 %CE%YR" TO
A%,B%
?B%=13:=$A%
ENDFN

