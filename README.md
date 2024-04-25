# Viscoelastic Cross-bridge Active Titin Muscle Model for LS-DYNA

This is an LS-DYNA implementation of Millard et al.'s VEXAT muscle model that also includes the reflex controller described in Wochner et al. This material has only been compiled and tested in LS-DYNA R9.3.1.

Matthew Millard, David W. Franklin, Walter Herzog (2023). A three filament mechanistic model of musculotendon force and impedanceeLife12:RP88344 https://doi.org/10.7554/eLife.88344.2

Wochner I, Nölle LV, Martynenko OV, Schmitt S. ‘Falling heads’: investigating reflexive responses to head–neck perturbations. BioMedical Engineering OnLine. 2022 Apr 16;21(1):25.

## Pre-requisites

1. A working copy of LS-DYNA R9.3.1.

2. Able to compile your own user materials.


## Quick start

1. Put a copy of dyn21.f in MPP_R931
2. Edit the copy of dyn21.f so that `C start of umat43` appears just before `subroutine umat43` and `c END OF SUBROUTINE UMAT43` appears after the end statement. Put this copy into the SMP_931 if this is the SMP dyn21.f library file, and into MPP_931 if this is the MPP dyn21.f library file.
3. Put the files needed to compile an LS-DYNA user material into build/MPP_9.3.1/usermat for the MPP version, and build/MPP_9.3.1/usermat for the SMP version.
4. Open a terminal in this directory and call `make MPP931` to compile the MPP version of the library, or `make SMP931` to compile the SMP version of the library.
5. If everyting works you'll have a compiled version of lsdyna sitting in the MPP_931 or SMP_931 folder.
6. Open a terminal in 'Millard2024VEXATMuscleLSDYNA/example/MPP_R931/umat43/active_force_length_06' and run LS-DYNA on 'active_force_length_06.k'. If everying works LS-DYNA will activate a cat soleus model at its optimal fiber length. The simulation requires these files:
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


