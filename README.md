# Viscoelastic Cross-bridge Active Titin Muscle Model for LS-DYNA

This is an LS-DYNA implementation of Millard et al.'s VEXAT muscle model that also includes the reflex controller described in Wochner et al. This material has only been compiled and tested in LS-DYNA R9.3.1 using the MPP (  massively-parallel-processing) interface. It is possible to build the SMP (shared-memory-parallel) interface, but this has not been tested as of July 2024). This model is benchmarked in [1], formulated in [2], and uses the reflex controller described in [3]. Please reference papers [1,2] if you use the VEXAT muscle model, and paper [3] for the reflex-controller.

1. Matthew Millard, Norman Stutzig, Jörg Fehr, Tobias Siebert. A benchmark of muscle models to length changes great and small. Journal of the Mechanical Behavior of Biomedical Materials. 2024 (submitted)

2. Matthew Millard, David W Franklin, Walter Herzog. A three filament mechanistic model of musculotendon force and impedance. eLife 12:RP88344, https://doi.org/10.7554/eLife.88344.3, 2024 (accepted)

3. Wochner I, Nölle LV, Martynenko OV, Schmitt S. ‘Falling heads’: investigating reflexive responses to head–neck perturbations. BioMedical Engineering OnLine. 2022 Apr 16;21(1):25.


All of the code and files in this repository are covered by the license mentioned in the SPDX file header which makes it possible to audit the licenses in this code base using the ```reuse lint``` command from https://api.reuse.software/. A full copy of the license can be found in the LICENSES folder. To keep the reuse tool happy even this file has a license:

 SPDX-FileCopyrightText: 2024 Matthew Millard <millard.matthew@gmail.com>

 SPDX-License-Identifier: MIT

## Pre-requisites

1. A working copy of LS-DYNA R9.3.1.

2. Able to compile your own user materials using the MPP version.


## Compilation 

1. Put a copy of dyn21.f in MPP_R931

2. Edit the copy of dyn21.f so that the make file can automatically insert the subroutines: 
    1. Open dyn21.f and add the line `C start of umat43` so that it appears just before `subroutine umat43` and `c END OF SUBROUTINE UMAT43` appears after the end statement.
    2. If you are also compiling the extended Hill-type muscle (EHTM) model, download the EHTM_v_4.0.00.f (https://doi.org/10.18419/darus-1144)
        1. Place the EHTM_v_4.0.00.f in the WORK_R931 folder
        2. Rename the file to umat41.f
        3. Open dyn21.f and add the line `C start of umat41` so that it appears just before `subroutine umat41` and `c END OF SUBROUTINE UMAT41` appears after the end statement.
        4. For more information on the EHTM model please see:

        - Martynenko OV, Kempter F, Kleinbach C, Nölle LV, Lerge P, Schmitt S, Fehr J. Development and verification of a physiologically motivated internal controller for the open-source extended Hill-type muscle model in LS-DYNA. Biomechanics and Modeling in Mechanobiology. 2023 Dec;22(6):2003-32. https://doi.org/10.1007/s10237-023-01748-9

        - Kleinbach C, Martynenko O, Promies J, Haeufle DF, Fehr J, Schmitt S. Implementation and validation of the extended Hill-type muscle model with robust routing capabilities in LS-DYNA for active human body models. Biomedical engineering online. 2017 Dec;16:1-28. https://doi.org/10.1186/s12938-017-0399-7

        - Günther M, Schmitt S, Wank V. High-frequency oscillations as a consequence of neglected serial damping in Hill-type muscle models. Biological cybernetics. 2007 Jul;97(1):63-79. https://doi.org/10.1007/s00422-007-0160-6

3. Put the files needed to compile an LS-DYNA user material into build/MPP_9.3.1/usermat/ folder. On my machine this list of files includes:

```
adjcom.inc
adummy_ansyslic.o
adummy_ansys.o
adummy_graph.o
adummy_msc.o
alemisc.inc
bigprb.inc
bk05.inc
bk06.inc
bk07.inc
bk08.inc
bk13.inc
bk19.inc
chash.o
couple2other_user.f
couple2other_user.o
dyn17fv.o
dyn21b.f
dyn21b.o
dyn21.f
dyn21.o
dynm.o
dynrfn_user.f
dynrfn_user.o
get_csthk.o
histlist.txt
implicit1.inc
init_dyn21.f
init_dyn21.o
init_once.o
iodeg.inc
iounits.inc
libbcsext4.a
libblas.a
libcese.a
libchemistry.a
libcparse.a
libdyna.a
libem.a
libeosfl.a
libfemster1d.a
libfemster2d.a
libfemster.a
libfemster_wrap1d.a
libfemster_wrap2d.a
libfemster_wrap.a
libfftw3.a
liblapack.a
liblcpack.a
liblscrypt.a
liblsda.a
liblsm.a
liblsmpp.a
liblsmppdes.a
liblso.a
liblssecurity.a
libmetis.a
libmf2.a
libmoving.a
libmpp_lanczos.a
libparticles.a
libpfem.a
libresurf.a
libsfg.a
libspooles.a
libsprng.a
Makefile
matflr.inc
memaia.inc
mscapi.o
nhisparm.inc
nikcpl.inc
nlqparm
oasys_ceap.inc
orderByMetis.o
ptimes.inc
sbelt.inc
sc_util.o
secvend2.inc
shlioc.inc
slcntr.inc
sph.inc
subcyc.inc
superp.inc
txtline.inc
umatss.inc
xjobid.inc
```


4. Open the file `nhisparm.inc` in MPP_R931 and set NHISVAR to 1000: <code>parameter (NHISVAR=1000)</code>. This sets the maximum size of the user defined buffer for each usrmat to 1000 elements. Note:
    1. This buffer of memory is needed for the delay channel of the VEXAT model's (umat43) reflex controller. 
    2. You can use as little as 300 for nhisvar if you are using the reflex controller. 
    3. If you are not using the reflex controller you should use no less than nhisvar 150. 
    4. The size of the buffer actually used during simulation is set by the ```nhv``` variable in the material card.

5. Open a terminal in the Millard2024VEXATMuscleLSDYNA directory and load the oneAPI tools. If you are working from the University of Stuttgart ITM use this command from one of the computers on the network: ```source /space/fkempter_to_others/intel/oneapi/setvars.sh```. This should produce the output:

```
    :: initializing oneAPI environment ...
       -bash: BASH_VERSION = 5.1.16(1)-release
       args: Using "$@" for setvars.sh arguments: 
    :: advisor -- latest
    :: ccl -- latest
    :: clck -- latest
    :: compiler -- latest
    :: dal -- latest
    :: debugger -- latest
    :: dev-utilities -- latest
    :: dnnl -- latest
    :: dpcpp-ct -- latest
    :: dpl -- latest
    :: inspector -- latest
    :: ipp -- latest
    :: ippcp -- latest
    :: ipp -- latest
    :: itac -- latest
    :: mkl -- latest
    :: mpi -- latest
    :: tbb -- latest
    :: vpl -- latest
    :: vtune -- latest
    :: oneAPI environment initialized ::
```

6. From the same terminal that you've just used to load the oneAPI tools call `make MPP931` to compile the MPP version of the library.

7. If everything works you'll have an ```mppdyna``` executable in the MPP_931.

## Testing

1. Open a terminal in 'Millard2024VEXATMuscleLSDYNA/example/MPP_R931/umat43/active_passive_force_length/active_force_length_06/' 
2. From this terminal call  ```../../../../../MPP_R931/mppdyna i=active_force_length_06.k```
3. If everying works LS-DYNA will activate the cat soleus model at its optimal fiber length and produce a large number of output files:

```
adptmp
bg_switch
binout0000
d3dump01.0000
d3full01
d3hsp
d3plot
d3plot01
d3plot02
f1HN.0000000002
f2HN.0000000002
falN.0000000002
fCpFcnN.0000000002
fecmHN.0000000002
fort.13
fort.59
ftFcnN.0000000002
fvN.0000000002
glstat
kill_by_pid
ktFcnN.0000000002
load_profile.csv
load_profile.xy
mes0000
musdebug.0000000002
musout.0000000002
status.out

```

These files are output files produce by LS-DYNA
```
binout0000 (binary)
d3hsp (text)
```
This file is from the muscle model (space separated with human-readable column headers) and is generated whenever the output field in the muscle card is set to 1 or higher
```
musout.0000000002
```
These files are also from the muscle model (space separated with human-readable column headers) and are generated when the output field in the muscle card is set to 2
```
musdebug.0000000002
f1HN.0000000002
f2HN.0000000002
falN.0000000002
fCpFcnN.0000000002
fecmHN.0000000002
ftFcnN.0000000002
fvN.0000000002
ktFcnN.0000000002
```
The output files from the muscle model can be suppressed by setting the ```output``` flag to 0 in the umat43 material card.

## Folder Layout

6. Here is a quick overview of all of the folders that appear
  - build: contains the files needed to build a version of LS-DYNA with user materials. These files should be stored in the folders MPP_9.3.1/usermat/ and SMP_9.3.1/usermat/ for the multiple message passing and single message passing interfaces respectively.
  - example: contains the files needed to run the umat43 user material to test that it is working.
  - LICENSES: A folder that contains the licenses that apply to the files in this project. This project's licensing is compliant with the license auditing tool provided by https://api.reuse.software/
  - MPP_R931: A folder that contains the dyn21.f file (for the user materials) and the compiled version of LS-DYNA using the MPP interface
  - SMP_R931: Same as the MPP_R931 folder but contains the single-message-passing compiled version of LS-DYNA (not tested).
  - WORK_R931: A folder that contains the dyn21.f file (for the user materials) and the compiled version of LS-DYNA using the MPP interface



## Developer Notes

1. Detailed documentation on umat43.f appears in the beginning of the file.

2. If you change the number of input arguments in the card note that you will have to very carefully adjust the hard-coded indices for each argument. These can be found by searching for `cm(` : the cm vector contains all of the card input values. 

3. If you change the layout of the hsv vector you will have to do this carefully: the layout of this vector is detailed near line 469 of umat43.f. Any updates may also require changes to the idxHsv variables (e.g. idxHsvLp) that store the indices of the hsv values in user-friendly names.

## Future Work

1. All of the curves used in this model are quadratic Bezier splines that have been hard coded in the model. The user is only provided with a modest ability to scale and shift some of these curves, but there is not fine-grained control over the shape of these curves. While this makes the model relatively easy to use, it limits the degree of customization that is possible. Although it will result in slower code, it would be good to 

    1. Make a version of umat43 that uses LS-DYNA's built in DEFINE_CURVE. This will make it possible for people to customize these curves.

    2. Make a series of scripts to automatically generate the correct curve values. This is certainly needed for this model as the process of generating the various ECM and titin curves is non-trivial.

2. The reflex controller only turns the muscle on. In reality there is also a reflex called Golgi tendon inhibition that turns the muscle off as its force becomes too high. To learn more about this phenomena start with:

    1. Jami L. Golgi tendon organs in mammalian skeletal muscle: functional properties and central actions. Physiological reviews. 1992 Jul 1;72(3):623-66.

    2. Chalmers G. Strength training: Do Golgi tendon organs really inhibit muscle activity at high force levels to save muscles from injury, and adapt with strength training?. Sports biomechanics. 2002 Jul 1;1(2):239-49.



