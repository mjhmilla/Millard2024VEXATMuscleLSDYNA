*KEYWORD
*MAT_USER_DEFINED_MATERIAL_MODELS
$ Millard 2022 Muscle
$#     mid        ro        mt       lmc       nhv    iortho     ibulk        ig
         1       1.0        43        34      1000         0         3         4
$#   ivect     ifail    itherm    ihyper      ieos      lmca    unused    unused
         0         0         0         0         0         0                    
$#  stimId exDefault    tauAct  tauDeact fceOptIso    lceOpt alphaOptD useRgdTdn
         3       0.0     0.040     0.080   &fceOpt   &lceOpt  &penOptD         0
$#   ltSlk     etIso       dtN  scalePEE  shiftPEE lambdaECM  lPevkPtN lceHNLb1A
    &ltSlk     0.049    0.0556 &scalePEE &shiftPEE      0.56       0.5      0.40 
$# act1AHN  beta1AHN  beta1PHN kxOptIsoN dxOptIsoN gainTrack  actTrack    vceMax
      0.25      65.0      0.05      47.8     0.354    1000.0      0.05   &vceMax
$# taudvst   dvsBeta    dtNumN   aniType   ctlType  ctlDelay  ctlThrsh ctlOnTime    
     0.001       1.0    0.0001         1         1     0.025     0.075     0.000   
$#  output     dtout
         2    &dtOut
*END
