*KEYWORD
*MAT_USER_DEFINED_MATERIAL_MODELS
$ Hill-type Muscle
$#     mid        ro        mt       lmc       nhv    iortho     ibulk        ig
         1       1.0        41        48       600         0        31        32
$#   ivect     ifail    itherm    ihyper      ieos      lmca    unused    unused
         0         0         0         0         0         0                    
$#  ActOpt   STIM_ID        q0    tauq/c betaq/eta         k         m   FMTUlim
         1        -3    1.0E-4     0.025       0.5                           1.0
$#    Fmax    lCEopt     dWdes      nCEd     dWasc      nCEa     Arel0     Brel0      
 &fceOptAT &lceOptAT    &dWdes  &nuCEdes    &dWasc  &nuCEasc     &Arel     &Brel
$#    Secc      Fecc     LPEE0      nPEE      FPEE     lSEE0    dUSnll      dUSl
     &Secc     &Fecc    &LPEE0    &nuPEE     &FPEE    &ltSlk &dUSEEnll   &duSEEl
$#  dFSEE0   FSDElim      Dsde      Rsde    Output     dtOut
   &dFSEE0       1.0       0.3      0.01         2    &dtOut 
*END
