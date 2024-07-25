# Viscoelastic Cross-bridge Active Titin Muscle Model for LS-DYNA

This is an LS-DYNA implementation of Millard et al.'s VEXAT muscle model that also includes the reflex controller described in Wochner et al. This material has only been compiled and tested in LS-DYNA R9.3.1.

Matthew Millard, David W. Franklin, Walter Herzog (2023). A three filament mechanistic model of musculotendon force and impedance eLife12:RP88344 https://doi.org/10.7554/eLife.88344.2

Wochner I, Nölle LV, Martynenko OV, Schmitt S. ‘Falling heads’: investigating reflexive responses to head–neck perturbations. BioMedical Engineering OnLine. 2022 Apr 16;21(1):25.

## Pre-requisites

1. A working copy of LS-DYNA R9.3.1.

2. Able to compile your own user materials.


## Compilation 

1. Put a copy of dyn21.f in MPP_R931

2. Edit the copy of dyn21.f so that `C start of umat43` appears just before `subroutine umat43` and `c END OF SUBROUTINE UMAT43` appears after the end statement. 

3. Put the files needed to compile an LS-DYNA user material into build/MPP_9.3.1/usermat for the MPP version, and build/MPP_9.3.1/usermat for the SMP version. On my machine this list of files includes:

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

7. If everyting works you'll have an ```mppdyna``` executable in the MPP_931.

## Testing

1. Open a terminal in 'Millard2024VEXATMuscleLSDYNA' 
2. From this terminal call  ```MPP_R931/mppdyna i=/example/MPP_R931/umat43/active_passive_force_length/active_force_length_06/active_force_length_06.k```
3. If everying works LS-DYNA will activate a cat soleus model at its optimal fiber length. The simulation requires these files:
- example/MPP_R931/umat43/active_force_length_06/active_force_length_06.k
- example/MPP_R931/umat43/active_force_length_06/active_passive_force_length.k
- example/MPP_R931/common/catsoleusHL1997Umat43Parameters.k
- example/MPP_R931/common/catsoleusHL1997Umat43.k
See catsoleusHL1997Umat43.k for an example umat43 card.

## Notes

1. Detailed documentation on umat43.f appears in the beginning of the file.
2. If you change the number of input arguments in the card note that you will have to very carefully adjust the hard-coded indices for each argument. These can be found by searching for `cm(` : the cm vector contains all of the card input values
3. If you change the layout of the hsv vector you will have to do this carefully: the layout of this vector is detailed near line 469 of umat43.f. Any updates may also require changes to the idxHsv variables (e.g. idxHsvLp) that store the indices of the hsv values in user-friendly names.

## Upgrades

All of the curves used in this model are quadratic Bezier splines that have been hard coded in the model. The user is only provided with a modest ability to scale and shift some of these curves, but there is not fine-grained control over the shape of these curves. While this makes the model relatively easy to use, it it limits the degree of customization that is possible. Although it will result in slower code, it would be good to 

1. Make a version of umat43 that uses LS-DYNA's built in DEFINE_CURVE. This will make it possible for people to customize these curves.
2. Make a series of scripts to automatically generate the correct curve values. This is certainly needed for this model as the process of generating the various ECM and titin curves is non-trivial.


