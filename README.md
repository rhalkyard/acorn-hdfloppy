# High-density floppy modification for Acorn Archimedes computers

Add high-density floppy support to your Archimedes using the stock 1772 floppy
controller!

## Introduction

The 'first generation' Acorn Archimedes hardware (A300, A400, A540 and A3000)
use a 1772 floppy controller that does not support high density floppy discs, as
the 8MHz clock supplied to it is not fast enough to allow decoding of the
500kbps data rate used on high-density formats.

A [well-known modification](http://qubeserver.com/Qube/projects/hdfloppy.html)
to support high-density floppies on these machines involves selectively
overclocking the 1772 to 16MHz, with a clock source controlled by a spare pin on
the IOC control port. A patched version of ADFS then selects the clock based on
the desired density. The downside to this modification is that it is rather
invasive, requiring that the 1772 be de-soldered and mounted on a carrier board.
Additionally, the particular 1772s used by Acorn do not usually work well at the
higher clock rate, and genuine 16MHz-rated parts are difficult to find.

There is, however, another way to accomplish the same goal: rather than clocking
the 1772 at double speed to handle the higher data rate, we can halve the
drive's rotation speed when a high-density disc is present, bringing the data
rate down to the same 250Kbps used by double-density discs. While it may sound a
bit ridiculous, Commodore did exactly this to add high-density support to some
Amiga models without having to re-engineer their highly-integrated custom floppy
controller.

While Commodore's own drives were manufactured by Chinon with half-speed
functionality built in, various third-party drives also existed, which were
typically off-the-shelf PC drives with circuit modifications to add the
half-speed high density feature and support the Shugart-style disc-change and
drive-ready signalling used by the Amiga. An example of one of these drives is
the ["Real HD-Drive" by
Amtrade](https://bigbookofamigahardware.com/bboah/product.aspx?id=381), which
was recently cloned by [TubeTime](https://github.com/schlae) as the [Herr Doktor
Diskettenlaufwerk](https://github.com/schlae/amiga-hddlw) (or HDDLW for short).

Conveniently, the first-generation Archimedes machines require drives with the
same Shugart-style interface as the Amiga (i.e. `/READY` on pin 34 and
`/DISKCHANGE` on pin 2), so the HDDLW kills two birds with one stone - it
converts the not-quite-standard signalling of a PC floppy drive to
Shugart-style, and also provides the half-speed high density operation that we
want!

## Files in this repo

[**`ModuleSave.bas`**](ModuleSave.bas): BBC Basic program to save the currently
loaded ADFS module to a file so that it can be patched.

[**`MkHDADFS.bas`**](MkHDADFS.bas): BBC Basic program to patch ADFS for
half-speed high density support.

[**`flashfloppy/IMG.CFG`**](flashfloppy/IMG.CFG): FlashFloppy image-format
configuration for half-speed high density operation using a [FlashFloppy
device](https://github.com/keirf/flashfloppy).

See the Releases tab for a
[SparkFS](http://www.riscos.com/ftp_space/generic/sparkfs/index.htm) archive
containing a pre-patched copy of ADFS.

## What to do

1. [Build an HDDLW drive](https://github.com/schlae/amiga-hddlw) and install it
   in your Acorn system. Alternatively, a Gotek floppy emulator running the
   FlashFloppy firmware can be [configured](flashfloppy/IMG.cfg) to behave in
   the same way.

2. Verify that the new drive can read and write double-density discs - ideally
   testing with ADFS L, D and E, and MS-DOS 720k formats.

3. Load the patched ADFS module supplied in this repo.

4. Verify that with the patched ADFS loaded, you can read, write and format ADFS
   F and MS-DOS 1440k formats in addition to the double-density formats above.

Once you have confirmed that everything is working, it would make sense to load
the patched ADFS at boot or even better, add it to a Podule ROM.

Without the ADFS patch, the drive will read and write double-density discs as
normal. This includes high-density discs unwisely formatted as double-density,
so long as the disc's density-select hole is taped over.

## Notes on building the HDDLW

While the HDDLW modification supports both the Sony MPF920E and Teac FD235HF
drive mechanisms, [the FD235HF-4240
variant](https://github.com/schlae/amiga-hddlw/issues/7) is not suitable for
modification as its motor controller is clocked directly from a crystal on the
motor PCB, rather than a square wave from the main controller IC. These variants
have a 10-pin connector between the main and motor PCBs, rather than the 11 pins
described in the HDDLW instructions.

### Modifying other drives

Other drive mechanisms may also work, but every drive is different, and the
details of converting them are left as an exercise for the reader. In short, the
drive PCB must be modified as follows:

* Acitve-low high-density sense output on pin 4 (pin 4 is usually a no-connect,
  but most drives provide a jumper or shortable pad that enables this feature)

* Locate and break the clock connection from the main IC to the motor-driver IC.
  This is typically a 500KHz-1MHz square wave that is active when the motor is
  running.

* Connect the motor clock output from the main IC to pin 14 (normally
  drive-select A, unused when drive is jumpered for use in a PC).

* Connect the clock input pin of the motor-driver IC to pin 6 (normally a
  no-connect)

* If present, drive-select and interface-configuration jumpers should be left in
  their default PC-style configuration (i.e. drive-select B, `/DISKCHANGE` on
  pin 34, no `/READY` output) as the HDDLW board handles interface conversion.

It will likely also be necessary to modify the layout of the HDDLW board to suit
the connector placement of your particular drive.

### Drives that don't work

Note that not all drives operate correctly with these modifications - I have
tried the following drives and confirmed them NOT to work:

* **Teac FD235HF-4240:** while some FD235HF variants are suitable for this
  modification, this particular variant does not have a convenient clock signal
  to interpose - the motor driver uses a crystal for its reference clock, rather
  than being clocked with a square wave from the main IC.

* **Sony MP-F17W:** disc rotation is unstable (and noisy) at 150RPM - the
  spindle motor appears to have fewer poles than other drives, making it
  'notchy' when run at slower speeds.

* **NEC FD1231T:** disc rotates too fast with halved clock - 180RPM instead of
  150RPM. Slowing the clock further does not appear to slow down rotation.

## How it works

### Hardware

The [HDDLW readme](https://github.com/schlae/amiga-hddlw/README.md) does a good
job at explaining how the drive modification works, but I'll repeat it here for
good measure. Essentially, it intercepts the reference clock for the drive's
motor controller IC, passing it through unmodified when a double density disc is
inserted, and dividing it by 2 when a high density disc is inserted. This tricks
the motor controller into running the motor at half speed when a high density
disc is inserted.

Additionally, the HDDLW board converts the PC-style interface of a regular
floppy drive, to the Shugart-style interface expected by Acorn (and Amiga)
systems. This entails moving the 'disk change' signal from pin 34 to pin 2, and
using the index, motor-on and drive-select signals to derive an open-collector
'drive ready' signal that is output on pin 34.

Of note is the fact that there is no signalling of density between the drive and
the computer (technically, the HDDLW implements an Amiga-specific density
signalling scheme overlaid on the drive-ready output, but we do not use this).
This simplifies the hardware greatly, as we do not need to borrow an IOC control
pin or do any motherboard modifications - all the hardware modifications are
contained within the drive itself. The drive selects 300 or 150RPM operation
based on its density-sense switch, and on the software side, a heuristic is used
to determine the density of the disc based on its geometry.

### Software

Since Risc OS 3's ADFS already has support for high density formats on later
models that had a PC-style floppy controller, only a few small changes are
required to enable it on 1772-based machines - primarily just modifying validity
checks, and a adding a heuristic to differentiate between double density and
high density formats.

For those of you who want to follow along, the vestigial 1772 support code in
the Risc OS 3.6 [ADFS
module](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/tree/RO_3_60/)
appears to be largely unchanged from the ADFS 2.67 that shipped with Risc OS
3.10. Interestingly, that source has a number of conditional-assembly blocks to
enable high-density support on the original pre-production A500 hardware, which
had an FDC9793 controller, similiar to the 1772 but supporting higher data
rates. Many of the patches simply involve reinstating these omitted sections (or
equivalent code).

* [**`s.ADFS15` line 294**](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/blob/RO_3_60/s/Adfs15#L294)
  Allow high density when validating the disc record at the start of a disc
  operation.

* [**`s.ADFS15` line 891**](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/blob/RO_3_60/s/Adfs15#L891)
  When reading sector IDs, wait 420ms (instead of 210ms) to allow a complete
  revolution of the disc at 150rpm.

* [**`s.ADFS15` line 1799**](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/blob/RO_3_60/s/Adfs15#L1799)
  Differentiate between HD vs. DD discs, using total track size as a heuristic.

* [**`s.ADFS15` line 2093**](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/blob/RO_3_60/s/Adfs15#L2093)
  Allow high density when validating the disc record for formatting.

* [**`s.ADFS50` line 751**](https://gitlab.riscosopen.org/RiscOS/Sources/FileSys/ADFS/ADFS/-/blob/RO_3_60/s/Adfs50#L751) 
  Add high density to the bitmap of valid densities for the 1772 controller (as
  done with the A500).

#### Format detection

When a disc is mounted, ADFS determines its format by attempting to read track 0
in each possible density, from the highest to the lowest (and then a second time
if that fails). The first density that yields valid sectors is stored in the
disc record, along with the disc's geometry (calculated from the number and size
of sectors observed). This disc record is then offered to filesystem modules,
which then check its density and geometry against the formats that they know
about.

While this approach is reasonable for a normal setup where each density comes in
at a different data rate, it poses a problem for us, as with our variable-speed
drive, high and double densities now use the same data rate, and without a
separate density signal from the drive, there is no way to positively tell the
difference between the two. Reading with the wrong density will produce valid
sectors, and even the correct geometry, but the density field in the disc record
will be set incorrectly, which means that filesystems will not recognise the
format.

To get around this, rather than adding high-density to this probing algorithm,
we let ADFS detect the disc as double density, and continue to the point where
it determines the disc geometry. Here, we patch in a routine that calculates the
formatted size of track 0 (i.e. sector size multiplied by number of sectors,
excluding overhead). If this size exceeds the unformatted size of a DD track
(6144 bytes), then we can be sure that the disc is high density, and update the
disc record to reflect that.

This heuristic is not 100% foolproof - a nonstandard HD format containing <=6144
data bytes on track 0 will result in a false negative. But any reasonable HD
format will have a formatted track capacity much greater than this, and
formatting overheads mean that all DD formats will fall under  this threshold.
Thus, false positives are unlikely. Copy-protected discs may be another story,
but at this point in time I think we can consider that a rare use case.

## Caveats

As the floppy drive is operating outside of its design parameters, this
modification can not be expected to provide as reliable operation as a genuine
16MHz 1772 with an unmodified high-density drive. Some drives may simply not
work reliably (or at all) in this application, and drives that do work may still
have issues with less-than-perfect media.

Since the timeout for reading sector IDs is now doubled to allow for half-speed
operation, the sector list returned by the "Read track" DiscOp for will repeat
twice on double-density discs. This deviates from the behavior described in the
PRM, which states that in the worst case, 3 duplicate sectors may be returned.
Software that allocates only minimal space for the sector list may be affected.
However, such software will also likely have issues with hard discs,
high-density floppy discs, and other storage media.

## Acknowledgments

* cheesestraws, IanJ, LandonR and vanpeebles from the Stardot forums
  for their Acorn wisdom and encouragement to do such a silly thing.

* [TubeTime](https://github.com/schlae) for coming up with the HDDLW design and
  sharing it with the world.

* Boris Leppin for devising the original 16MHz 1772 modification and the ADFS
  patches to use it (which served as a base for my own patches).