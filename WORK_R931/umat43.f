c=======================================================================
c     Background
c=======================================================================
c ---------------------------------------------------------------------- 
c     About
c ----------------------------------------------------------------------
c     Author: Matthew Millard  
c     Date  : start of development: December 2021 
c           : current date        : June 2022
c ---------------------------------------------------------------------- 
c     Background Notes
c ----------------------------------------------------------------------
c
c
c
c     Activation dynamic model:
c           Is described in Millard et al. 2013 and but originates from 
c           Winters 1995 and Thelen 2003. 
c 
c           Millard M, Uchida T, Seth A, Delp SL. Flexing computational 
c           muscle: modeling and simulation of musculotendon dynamics. 
c           Journal of biomechanical engineering. 2013 Feb 1;135(2).
c     
c     Musculotendon model:
c           At the time this comment has been written the paper has not
c           yet been submitted. However, the paper describing the muscle
c           model will appear like this:
c
c           Millard M, Franklin D, Herzog W. A three filament 
c           mechanistic model of musculotendon force and impedance
c
c           This model has three features:
c           1. A viscoelastic lumped cross-bridge element
c           2. An active titin model
c           3. Dynamics that drive the model to behave like a 
c              spring-damper in the short-range, but like a Hill model 
c              over longer periods of time.
c ---------------------------------------------------------------------- 
c     Model diagram
c ----------------------------------------------------------------------
c                            Half Sarcomere                   Half Sarc.         Tendon
c      <--------------------------------------------------->|<-------->|<-------------------->|
c                  la             lx             lm (fixed)
c     |---------------->|<-------->|<---------------------->|        
c     |        (actin)           
c     |================[|]===============|   
c                       |(cross-bridge)
c                       |     kx                           
c                       |---|/\/\|---|       (myosin)       |           |
c                       |      bx    |==x===================|===========|
c                       |---[    ]---|  |                   |           |           kt
c                                       |                   |           |      |--|/\/\|--|
c     |     IgP       PEVK    IgD       |  (titin)          |           |------|    bt    |---|
c     |---|\/\/\|--|\[|]\/|----------|--x-------------------|-----------|      |--[    ]--|
c     |               |                                     |           |
c     |   (actin)     |                                     |           |
c     |==============[|]====================|               |           | 
c     |---- l1 ------>|         (extra-cellular matrix: ECM)|           |         
c     |---------------------|\/\/\/\/\/\|-------------------|-----------| 
c     |---------------------[           ]-------------------|-----------| 
c    
c     |-------------------------1/2 lce --------------------|--1/2 lce--|------------lt-------|  
c
c ---------------------------------------------------------------------- 
c     Model state and notation
c ----------------------------------------------------------------------
c
c     State vector : x = [lce,dla,la,l1] stretch goal: e1
c     lce    : fiber velocity                            (units: m/s)
c     lce    : fiber length                              (units: m)
c     la     : sliding length                            (units: m)
c     lx     : cross bridge stretch                      (units: m)
c     l1     : length of the titin segment between       (units: m)
c              the Z-line and the PEVK/distal IG border
c     e1     : calcium + stretch induced enhancement     (integral of act*m/s)
c     
c     Ascii Variable Notation convention
c     
c     ce : fiber 
c     t  : tendon 
c     1  : titin segment from the z-line to the PEVK/IG2 border
c     2  : titin segment from the PEVK/IG2 border to the m-line
c     s  : actin myosin attachement
c     x  : cross bridge
c     a  : actin
c     m  : m-line
c     z  : z-line
c      
c     N  : normalized
c     H  : half
c
c=======================================================================
c     Usage
c=======================================================================
c ---------------------------------------------------------------------- 
c     Example input from the material card in kN,mm,ms
c ----------------------------------------------------------------------
c     *KEYWORD
c     *MAT_USER_DEFINED_MATERIAL_MODELS
c     $ Millard 2022 Muscle
c     $#     mid        ro        mt       lmc       nhv    iortho     ibulk        ig
c              11.00000E-6        43        34      1000         0         3         4
c     $#   ivect     ifail    itherm    ihyper      ieos      lmca    unused    unused
c              0         0         0         0         0         0                    
c     $#  stimId exDefault    tauAct  tauDeact fceOptIso    lceOpt alphaOptD useRgdTdn
c              0        0.       10.       40.    0.0128  141.2747        0.         0
c     $#   ltSlk     etIso       dtN  scalePEE  shiftPEE lambdaECM  lPevkPtN lceHNLb1A
c             1.     0.068      55.6        1.       0.1      0.56       0.5       0.4
c     $# act1AHN  beta1AHN  beta1PHN kxOptIsoN dxOptIsoN   gainTrk    actTrk    vceMax
c            0.1    65000.      250.      47.8     0.354     0.001      0.05      0.01
c     $# taudvst   dvsBeta    dtNumN   aniType   ctlType  ctlDelay  ctlThrsh ctlOnTime
c          1000.     0.001       0.1         0         3     &cDly     &cThr  &cOnTime
c     $#  output     dtout     IBULK        IG
c              1        1.      0.13      0.13
c     dtout   
c     0.005
c     *END
c ---------------------------------------------------------------------- 
c     Example input from the material card in N,m,s
c ----------------------------------------------------------------------
c     *KEYWORD
c     *MAT_USER_DEFINED_MATERIAL_MODELS
c     $ Millard 2022 Muscle
c     $#     mid        ro        mt       lmc       nhv    iortho     ibulk        ig
c              1       1.0        43        34      1000         0         3         4
c     $#   ivect     ifail    itherm    ihyper      ieos      lmca    unused    unused
c              0         0         0         0         0         0                    
c     $#  stimId exDefault    tauAct  tauDeact fceOptIso    lceOpt alphaOptD useRgdTdn
c              3       0.0     0.040     0.080   &fceOpt   &lceOpt  &penOptD         0
c     $#   ltSlk     etIso       dtN  scalePEE  shiftPEE lambdaECM  lPevkPtN lceHNLb1A
c         &ltSlk     0.049    0.0556      1.00       0.1      0.56       0.5      0.40
c     $# act1AHN  beta1AHN  beta1PHN kxOptIsoN dxOptIsoN gainTrack  actTrack    vceMax
c            0.1      65.0      0.05      47.8     0.354    1000.0      0.05   &vceMax
c     $# taudvst   dvsBeta    dtNumN   aniType   ctlType  ctlDelay  ctlThrsh ctlOnTime    
c          0.001       1.0    0.0001         1         1     0.025     0.075     0.000   
c     $#  output     dtout
c              2    &dtOut
c     *END
c     
c     
c     These input variables are stored in the input vector cm. Where
c     ever possible the coefficients used in the model have been made
c     dimensionless so that these parameters do not have to change if
c     the simulation time is desribed in seconds or milliseconds. When
c     the coefficient has been fitted to data, the type of animal used
c     for the data source will be mentioned. Dimensionless coefficients
c     should be applicable, in principle, across muscles of different
c     architecture within the same animal, and hopefully across mammals.
c     That said many of the experiments used to fit coefficients have 
c     only been done in a single species: these coefficients might not
c     generalize to all mammals, for example.
c
c     Entries which do depend on the units of the simulation are starred
c     Entries which depend on the unit of time (seconds vs milliseconds) 
c       have two stars (**)
c      
c     cm(1) :  stimId   
c           : the id of the curve that defines the excitation                 
c     
c     cm(2) : excitationDefault 
c           : the default excitation used during the
c             initialization phase when neither the
c             curves nor the history variables are defined
c           : Unit: Dimensionless
c           : 0.0         (all muscle)
c
c    *cm(3) :  tauAct   
c           : activation time constant        
c           : Unit: Time
c           : 0.010 s     (mammalian muscle)
c
c    *cm(4) : tauDeact 
c           : deactivation time constant      
c           : Unit: Time
c           : 0.040 s     (mammalian muscle)
c
c    *cm(5) : fceOptIso
c           : maximum active isometric force 
c           : Unit: Force
c           : 21.5 N      (cat soleus)
c
c    *cm(6) : lceOpt   
c           : optimal fiber length    
c           : Unit: Distance
c           : 0.0428 m    (cat soleus)
c
c     cm(7) : alphaOptD
c           : pennation angle                 
c           : Unit: Angle (Degrees)     
c           : 7.0 degrees (cat soleus)
c
c     cm(8) : useRgdTdn
c           : 0: Elastic tendon is simulated                 
c           : 1: Rigid tendon model is used
c
c    *cm(9) :  ltSlk    
c           : tendon slack length             
c           : Unit: Distance
c           : 0.0305 m    (cat soleus)
c
c     cm(10):  etIso   
c           : tendon strain at fceOptIso    
c           : Unit: Distance/Distance
c
c     cm(11):  dtN  
c           : Normalized tendon damping model coefficient 
c           : Unit: Dimensionless
c           : 0.0556      (rabbits)
c                       
c           : Scales tendon-stiffness to damping. 
c           : For details see Millard, Franklin & Herzog
c           : and the Netti et al.
c                        
c       Netti P, D'amore A, Ronca D, Ambrosio L, Nicolais L. 
c       Structure-mechanical properties relationship of natural tendons 
c       and ligaments. Journal of Materials Science: Materials in 
c       Medicine. 1996 Sep;7(9):525-30.
c
c     cm(12): scalePEE 
c           : scalar factor that scales the passive-force-length curve
c           : Unit: Dimensionless
c           : 1.0         (cat soleus)
c
c     cm(13): shiftPEE 
c           : Shifts the ECM, Prox. and Distal titin curves such that
c           : the resulting passive force-length curve is shifted
c           : by shiftPEE (measured in optimal fiber lengths)
c           : Unit: Normalized length
c           : 1.0         (cat soleus)
c
c     cm(14): lambdaECM
c           : Fraction of the PE due to titin (Dimenionless)
c           : Unit: Dimensionless
c           : 0.56 (avg. of 5 rabbit skeletal muscles)
c                      
c       Prado LG, Makarenko I, Andresen C, Krüger M, Opitz CA, Linke WA. 
c       Isoform diversity of giant proteins in relation to passive and 
c       active contractile properties of rabbit skeletal muscles. The 
c       Journal of general physiology. 2005 Nov;126(5):461-80.                  
c
c     cm(15):  lPevkPtN  
c           : The point within the PEVK segment that bonds      
c             to titin. This is a normalized variable
c             where 0 is the proximal end of the PEVK 
c             segment and 1 is the distal end
c           : Unit : Normalized length
c           : 0.5 (to match Herzog and Leonard 2002)
c
c     cm(16): lceHNLb1A 
c           : The titin-actin bond does not form when lceHN is below 
c             this lower bound
c             See Hisey, Leonard, Herzog (2009) for details  
c           : Unit: normalized length
c           : 0.5
c
c     cm(17): act1AHN   
c           : titin-actin bond activation threshold
c           : When activation is approx 2x act1AHN the titin-actin bond 
c             has reached maximum strength. This is in place so that 
c             the titin-actin bond achieves its maximum strength at low
c             activation levels, as biological muscle does.
c             See Fukutani & Herzog (2018) for details
c           : Unit activation
c           : 0.1
c
c     cm(18): beta1AHN 
c           : Norm. titin-actin active damping coeff 
c           : Unit: Dimensionless: (Force/Force)/(Velocity/Velocity)
c           : 65          (cat soleus)
c
c     cm(19): beta1PHN 
c           : Titin-actin passive damping coeff
c           : Unit: Dimensionless: (Force/Force)/(Velocity/Velocity)
c           : 0.25        (cat soleus)
c
c     cm(20): kxOptIsoN
c           : Max. norm. cross-bridge stiffness 
c           : Unit: Dimensionless: (Force/Force)/(Distance/Distance)
c           : 47.5        (cat soleus)
c
c     cm(21): dxOptIsoN
c           : Max. norm. cross-bridge damping
c           : Unit: Dimensionless: (Force/Force)/(Velocity/Velocity)
c           : 0.354       (cat soleus) 
c
c   **cm(22): gainTrack
c           : Gain applied to low-activation term
c           : Unit: 1/Time^2
c           : 1000 1/sec^2 (cat soleus)
c
c     cm(23): actTracking
c           : Gain applied to the term in the fiber                     
c
c   **cm(24): vceMax   
c           : Maximum shortening velocity 
c           : Unit: (1/Distance)/Time
c           : 4.5 lceOpt/second (cat soleus)
c                       
c   **cm(25): taudvst  
c           : Time-constant applied to the cross-bridge's 
c             cycling acceleration
c           : Unit: Time^2
c           : 0.001 seconds^2   (cat soleus)
c
c     cm(26): dvsBeta  
c           : Cross-bridge acceleration damping coefficient 
c           : Unit: 1/Time
c           : 1.0 1/s           (cat soleus)
c
c     cm(27): betaNumN  
c           : Normalized numerical damping 
c           : Unit: 1/Time
c           : 0.001 1/s           
c 
c     cm(28): aniType  
c           : Type of animal used for the force-length curve,
c             and titin curves. The length of actin varies
c             across mammals, and this affects the 
c             force-length curve and the relative proportion
c             of titin that is bound to myosin
c           : 0 : Human
c           : 1 : Cat
c
c     cm(29): ctrlType  
c           : Type of ctrlType scheme used:
c                     
c           0 :   Output of curve stimId used as an excitation signal
c           1 :   Output of curve stimId used as an activation signal
c           2 :   Output of curve stimId applied directly as a tension
c                 to the material
c           3 :   Simple reflex is used when the muscle
c                 length is greater than the threshold a 100% excitation
c                 signal is applied after the delay has passed. To use this
c                 option the material should have around 1000 temporary 
c                 variables (set nhv to 1000) to implement a large enough
c                 ring buffer.
c
c     cm(30): ctrlDelay 
c           : control signal delay  [used only with ctrlType=3]
c           : The total delay between the time the muscle length exceeds
c             the threshold and the time the excitation signal is 
c             triggered. 
c
c             I have not yet read enough to be confident in the value 
c             that is placed here. Brault, Siegmund, Wheeler 2000
c             show that at the time of sternocleidomastoid activation
c             the muscle has strained by about 2.5%. This would suggest
c             that the threshold should be 2.5% and the delay should
c             be equal to 0 + the electromechanical delay (10-15 ms).
c             Since the activation time constant is about 10 ms
c             this would suggest that ctrlDelay should be zero.
c
c           : Unit: Time
c           : 25 ms
c
c     cm(31): ctrlThresh
c           : threshold  [used only with ctrlType=3]
c           : When the length of the CE is greater than threshold,
c             expressed as a fraction of the initial CE length, the
c             reflex controller is triggered.
c           : Example: a value of 0.1 means the reflex controller will
c             be triggered when the CE length exceeds 10% of its 
c             initial length.
c           : Unit: normalized length
c           : 0.075
c
c     cm(32): ctrlOnTime 
c           : The time at which the controller is enabled. Prior to
c             being enabled the muscles are excited at the default
c             value
c
c     cm(33): output   
c           : Level of output
c           : 0: No muscle-specific information written to file
c           : 1: A detailed matrix of model quantities written to file     
c              : (currently has 45 columns)
c           : 2: The output of #1 + a separate file for every
c                curve in the model. Each file contains the
c                argument to the curve, its value, derivative
c                and second derivative. The curves written 
c                include: the active force length curve, the 
c                force-velocity curve, the 
c                extra-cellular-matrix curve, the proximal
c                titin curve and the distal titin curve.
c
c     cm(34): dtout    
c           : The time-step used to write data to file. 
c           : Unit: Time
c           : Note that data is written as soon as the current 
c             exceeds the last write time by one dtout.
c             In any case there is a time vector printed, so
c             the slightly off sampling should not hurt the
c             quality of the out
      subroutine umat43(cm,eps,sig,epsp,hsv,dt1,capa,etype,tt,
     1 temper,failel,crv,nnpcrv,cma,qmat,elsiz,idele,reject,
     2 lft,x,v,acc_EHTM,i,d1,d2,d3,NHISVAR,no_hsvs,cmall)
c************************************************************************
c******************************************************************
c|  Livermore Software Technology Corporation  (LSTC)             |
c|  ------------------------------------------------------------  |
c|  Copyright 1987-2008 Livermore Software Tech. Corp             |
c|  All rights reserved                                           |
c******************************************************************
c
      include 'nlqparm'
      include 'bk06.inc'
      include 'iounits.inc'
      include 'memaia.inc'
      
c These additional lines have been added at the suggestion of Dynamore 
c (Tobias Eckert) to Fabian Kempter's request on Juni 2017 
c (Ticket#201705197000073) so that it is possible to retrieve the 
c length of the muscle path prior to simulation (needed for 
c initialization) : 
c
c common/soundloc/sndspd(nlq),sndsp(nlq),diagm(nlq),sarea(nlq).
c The total length of all bars (PART_AVERAGED) should then be "sqrt(sarea(i))".
c
c and also to fetch the part id of the muscle
c
c common/aux33loc/
c 1 ix1(nlq),ix2(nlq),ix3(nlq),ix4(nlq),ix5(nlq),mxt(nlq)
c and then use the following expression to get the external PART-Id:
c write(...) lqfmiv(mxt(l�))

c
c   567 |    5    |    5    |    5    |    5    |    5    |    5    | 2  5    |
c      common/aux33loc/ix1(nlq),ix2(nlq),ix3(nlq),ix4(nlq),ix5(nlq),
c     1 ix6(nlq),ix7(nlq),ix8(nlq),mxt(nlq),ix9(nlq),ix10(nlq)
      common/prescloc/voltot(nlq)
      common/bk00/numnp,numpc,numlp,neq,ndof,nlcur,numcl,numvc,
     + ndtpts,nelmd,nmmat,numelh,numelb,numels,numelt,numdp,
     + grvity,idirgv,nodspc,nspcor,nusa
      common/bk07/n1,n2,n3,n4,n5,n6,n7,n8,n9     

   
      
c############################################
c#   defining input variable types          #
c############################################
c
      dimension cm(*),eps(*),sig(*),hsv(*),crv(lq1,2,*),cma(*)
      dimension x(3,*),v(3,*),acc_EHTM(3,*),qmat(3,3) 
      dimension d1(*),d2(*),d3(*)
      dimension cmall(*)
      integer nnpcrv(*)
      logical failel,reject  
      character*5 etype

c###########################################
c# Constants
c###########################################
c  Apparently Fortran does not have a Pi constant  
c  Here I use enough digits for a quadruple because
c  the method used to convert a decimal number to a
c  binary number can affect exactly the value of then
c  the constant you get:
c  http://www.mimirgames.com/articles/programming/digits-of-pi-needed-for-floating-point-numbers/
      real*8 PI 
       
c Indices of the various quantities in hsv
c hsv layout: 
c  [1]        output, 
c  [2-4]      boundary conditions, 
c  [5-9]      state, 
c  [10-14]    stateDerivative, 
c  [15-23]    Auxilary: basic
c  [24-40]    Auxilary: element-by-element
c  [41-43]    Auxilary: acceleration detail
c  [50-60]    Ring buffer 
c  [61-69]    Unassigned
c  [70-83]    Advanced debugging data
c  [84-149]   Unassigned
c
c  [150-no_hsvs] Ring Buffer for the reflex controller
c
c  hsv: output [1], boundary conditions[2,5], state[5,9], stateDerivative[10,14]
c  1 idxHsvOutputCounter: count of the number of times text has been written to file
c  2 idxHsvLp           : path length
c  3 idxHsvVp           : path rate of lengthening
c  4 idxHsvExcitation   : excitation/stimulation
c  5 idxHsvAct          : [model state] activation state
c  6 idxHsvLceATN       : [model state] normalized length of the CE along the tendon
c  7 idxHsvL1HN         : [model state] normalized length of the prox. titin along the tendon
c  8 idxHsvLsHN         : [model state] normalized length to the lumped XE attachment point
c  9 idxHsvVsHNN        : [model state] normalized velocity of the lumped XE attachment point
c 10 idxHsvActDot       : [model state derivative] d/dt activation state
c 11 idxHsvLceATNDot    : [model state derivative] d/dt normalized length of the CE along the tendon
c 12 idxHsvL1HNDot      : [model state derivative] d/dt normalized length of the prox. titin along the tendon
c 13 idxHsvLsHNDot      : [model state derivative] d/dt normalized length to the lumped XE attachment point
c 14 idxHsvVsHNNDot     : [model state derivative] d/dt normalized velocity of the lumped XE attachment point
      integer idxHsvOutputCounter, idxHsvLp, idxHsvVp,   
     1 idxHsvExcitation, idxHsvAct, idxHsvLceATN, idxHsvL1HN, 
     2 idxHsvLsHN, idxHsvVsHNN, idxHsvActDot, idxHsvLceATNDot, 
     3 idxHsvL1HNDot, idxHsvLsHNDot, idxHsvVsHNNDot

c Auxiliary: basic
c 15 idxHsvLceN     : Norm. CE length    
c 16 idxHsvVceNN    : Norm. CE rate of length change
c 17 idxHsvFceN     : Norm. CE force
c 18 idxHsvAlpha    : pennation angle (radians)
c 19 idxHsvAlphaDot : pennation angular velocity (radians/s)      
c 20 idxHsvFceATN   : Norm. CE force along the tendon
c 21 idxHsvLtN      : Norm. length of the tendon    
c 22 idxHsvVtN      : Norm. rate length change of the tendon
c 23 idxHsvFtN      : Norm. tendon force
      integer idxHsvLceN, idxHsvVceNN, idxHsvFceN, idxHsvAlpha,    
     1 idxHsvAlphaDot, idxHsvFceATN, idxHsvLtN, idxHsvVtN, idxHsvFtN   

c Auxiliary: element-by-element arguments and forces
c 24 idxHsvLaN      : CE length ignorning X-bridge strain
c 25 idxHsvFalN     : active-force-length-multiplier
c 26 idxHsvVaNN     : Normalized (+/- 1) CE velcoity ignorning X-bridge strain rate   
c 27 idxHsvFvN      : force-velocity multiplier
c 28 idxHsvLceHN    : Norm. half-CE length   
c 29 idxHsvFecmHN   : Norm. elastic force of the extra-cellular-matrix   
c 30 idxHsvF1HN     : Norm. force of the proximal titin segment   
c 31 idxHsvL2HN     : Norm. length of the distal titin segment   
c 32 idxHsvF2HN     : Norm. force of the distal titin segment    
c 33 idxHsvLxHN     : Norm. x-bridge length (half-CE)  
c 34 idxHsvVxHN     : Norm. x-bridge rate-of-length change (half-CE)   
c 35 idxHsvFxHN     : Norm. force developed by the x-bridge element 
c 36 idxHsvFtfcnN   : Norm. elastic force of the tendon   
c 37 idxHsvFtBetaN   : Norm. tendon damping force
c 
      integer idxHsvLaN, idxHsvFalN, idxHsvVaNN, idxHsvFvN, idxHsvLceHN,        
     1 idxHsvFecmHN, idxHsvF1HN, idxHsvL2HN, idxHsvF2HN,         
     2 idxHsvLxHN, idxHsvVxHN, idxHsvFxHN, idxHsvFtfcnN,       
     3 idxHsvFtBetaN      
c Auxiliary: acceleration term detail     
c 38 idxHsvDvsHNHill    : Sliding element acceleration Hill term
c 39 idxHsvDvsHNDamping : "  " damping term
c 40 idxHsvDvsHNTracking: "  " tracking term    
      integer idxHsvDvsHNHill, idxHsvDvsHNDamping, idxHsvDvsHNTracking
c 41 idxHsvTpVmW: time derivative of system energy less work          
      integer idxHsvTpVmW
c 42  idxHsvRefLceATN
c 43  idxHsvCtrlForce
      integer idxHsvRefLceATN, idxHsvCtrlForce
c 44  idxHsvLceATNDelay             
      integer idxHsvLceATNDelay
c 45  idxHsvCtrlOnTime
      integer idxHsvCtrlOnTime      

c Advanced debugging terms      
c Titin power terms  
c 70 idxHsvPT1, 71 idxHsvPT2, 72 idxHsvPT12 
      integer idxHsvPT1 ,idxHsvPT2, idxHsvPT12 
c ECM power terms  
c 73 idxHsvPEcmK, 74 idxHsvPEcmD
      integer idxHsvPEcmK, idxHsvPEcmD  
c XE power terms          
c 75 idxHsvPXeK, 76 idxHsvPXeD, 77 idxHsvPXeA      
      integer idxHsvPXeK,idxHsvPXeD,idxHsvPXeA   
c Parallel element power terms           
c 78 idxHsvPCp
      integer idxHsvPCp
c Tendon power terms               
c 79 idxHsvPTK, 80 idxHsvPTD
      integer idxHsvPTK,idxHsvPTD
c Path power terms               
c 81 idxHsvPP
      integer idxHsvPP
c Force and velocity constraint errors                
c 82 idxHsvErrForce, 83 idxHsvErrVelocity
      integer idxHsvErrForce, idxHsvErrVelocity 

c############################################
c#   defining model variables               #
c############################################

c lceATNReachedLowerBound: true if the CE has hit its lower bound
c useRigidTendonModel: true if a rigid tendon model is being used 
c modelIsPennated: true if the model is pennated     
      logical useRigidTendonModel,lceATNReachedLowerBound,
     1 modelIsPennated
c id of the part      
      integer idpart
c lp: length of the path
c vp: rate of length change of the path      
      real*8 lp, vp
c id of the element      
      integer idele

c numEpsilon  : Approx 2e-16 for a double
c numEpsM     : Approx 10*2e-16 for a double
c numEpsSqrt  : Approx 1.8e-8 for a double    
      real*8 numEpsilon, numEpsM, numEpsSqrt      
c Using the activation model detailed in Eqn. 1,2,3 of 
c   Millard, Uchida, Seth, Delp (2013). Flexing computational
c   muscle: modelling and simulationof musculotendon dynamics
c   Journal of biomechanical engineering, 135 (2).


c stimId      : the id of the curve that defines the excitation
c excitation  : electrical stimulation of the muscle
c excitationDefault: the default value for excitation
c activation  : chemical (Ca2+) activation (0-1) of the muscle, 
c activationDot: derivative of the chemical activation of the muscle
c tauAct      : activation time constant 
c tauDeact    : deactivation time constant
c actTracking : when activation is less than or equal to actTracking
c                 a tracking term drives the slider to follow the
c                 location of myosin location 
c activationTitinActinBond : activation value between titin-actin
c act1AHN  : the value at which the bond between 
c     titin and actin begins to saturate. This parameter is in place to
c     mimic the low-calcium sensitivity of the titin-actin bond as 
c     measured by
c     Fukutani, Herzog (2018). Residual force enhancement is preserved
c     for conditions of reduced contractile force. Medicine & Science
c     in Sports and Exercise.
c
c lceHNLb1A      : At lengths greater than 
c     lceHNLb1A the titin-actin bond is enabled,
c     otherwise it is disabled to mimic the results of 
c     Hisey, Leonard, Herzog (2009). Does residual force enhancement
c     increase with increasing stretch magnitudes. J. Biomech.
c
c lceLbWidth1AHN : This is a parameter that determines
c     the width overwhich the strength of the titin-actin goes from
c     0 to 1 as lceN exceeds lceNLowerBoundTitinActinBond
c lceNTitinActinLB: This is the modulated titin-actin bond strength
c                   that goes to zero as lceN drops below the 
c                   lower bound, which is typically 0.5 lceOpt
c lceNTitinActinUP: This is the modulated titin-actin bond strength
c                   as a function of CE length, which drops to zero as
c                   l1HN + LT12 exceeds the length of the actin filament
c 
      real*8 stimId
      real*8 excitation, excitationDefault, activation, activationDot
      real*8 tauAct, tauDeact, actTracking
      real*8 activationTitinActinBond, act1AHN, act1AHNWidth
      real*8 lceHNLb1A, lceLbWidth1AHN
      real*8 lceNTitinActinLB,lceNTitinActinUB, f2f1HNDiff,f2f1HNWidth
      real*8 realTemp,realTemp1,realTemp2
c lceATN     : CE length along the tendon normalized by lceOpt 
c lceATNCtrl: delayed lceATN value used only by the reflex controller 
c l1HN  : Proximal titin length (Z-line to N2A) normalized by lceOpt
c lsHN  : length between Z-line and lumped XE normalized by lceOpt 
c vsHN  : velocity of the lumped XE w.r.t. the Z-line norm. by lceOpt
c vsHNN : velocity of the lumped XE w.r.t. the Z-line norm. by 
c         lceOpt*vceMax
      real*8 lceATN, lceATNCtrl, l1HN, lsHN, vsHN, vsHNN

c lsH       : length between Z-line and lumped XE
c vsH       : velocity of the lumped XE w.r.t. the Z-line
      real*8 lsH, vsH 

         
c fceOptIso : Maximum isometric force
c lceOpt    : Optimal length of the contractile element (CE) length
c alphaOptD : pennation of the CE at the optimal CE length in degrees
c alphaOpt  : "..." in radians
      real*8 fceOptIso, lceOpt, alphaOptD, alphaOpt

c lceAT     : length contractile element along the tendon
c lenXT     : length contractile element across the tendon (thickness)
c lce       : length of the contractile element
c lceH      : half the length of the contractile element
c lceN      : length contractile element normalized
c lceHN     : length of half of the contractile element, normalized
      real*8 lceAT, LceXT, lce, lceH, lceN, lceHN
c alpha     : pennation angle (radians)
c cosAlpha  : cosine of the pennation angle (radians)
c sinAlpha  : sine of the pennation angle (radians)
      real*8 alpha, cosAlpha, sinAlpha
c vce       : velocity of the contractile element (+'ve=lengthening)
c vceN      : velocity of the ce normalzied by (lceOpt)
c vceHN     : velocity of the half-ce normalzied by (lceOpt)
c vceNN     : velocity of the ce normalzied by (vmax*lceOpt)  
c dalpha    : rate change of pennation angle  
c vceMax    : maximum contraction velocity in fiber lengths/s
c A0         : a temporary variable used in solving for vce with an elastic tendon
c B0         : "  "
c C0         : "  "
      real*8 vt, vtN, vce, vceN, vceHN, vceNN, dalpha, vceMax
      real*8 A0,B0,C0
c vceAT     : velocity of the contracile element along the tendon
c vceATN    : norm. velocity of the contracile element along the tendon
      real*8 vceAT, vceATN
c when set to true will write a text file that contains the values and
c derivatives of all of the curves during simulation
      logical writeCurvesToFile
c laN        : length of the CE ignoring cross-bridge strain   
c laNXeAdj   : laN with an adjustment to shift the force-length curve
c              to the left by 1 cross-bridge strain: the end result is
c              that the force-length curve with cross-bridge strain
c              aligns exactly with where you'd like the curve.   
c falN       : active-force-length multiplier
c falNDer1   :1st derivative of the active force length curve w.r.t 
c             lceN
c falNDer2   : 2nd derivative ...
      real*8 laN, laNXeAdj, falN, falNDer1, falNDer2
c vaNN      : velocity of the CE ignoring cross-bridge strain-rate            
c fvN       : force-velocity multiplier
c fvNDer1   : 1st derivative w.r.t. vceNN 
c fvNDer2   : 2nd derivative w.r.t. vceNN
      real*8 vaNN, fvN, fvNDer1, fvNDer2      
c fecmHN    : force of the extra cellular matrix
c fecmHN1Der: 1st derivative w.r.t. lceHN
c fecmHN2Der: 2nd derivative w.r.t. lceHN
      real*8 fecmHN, fecmHNDer1, fecmHNDer2     
c f1HN    : force of the proximal Ig elastic element
c f1HN1Der: 1st derivative w.r.t. l1N
c f1HN2Der: 2nd derivative w.r.t. l1N      
      real*8 f1HN, f1HNDer1, f1HNDer2 
c LmHN   : length of the scaled half myosin normalized w.r.t. optimal 
c          fiber length
c LmH    : length of the scaled half myosin normalized
c LActN  : length of the scaled actin filament
c LAct   : length of the actin filament
c l1H    : length of the prox segment of titin: Z-line to N2A epitope  
c k1HN   : terminal normalized stiffness of the f1HN curve
c LT12   : normalized length of the titin segment between the Z-line and
c          the T10 epitope
c lPevkPtN : Normalized point along the PEVK segment that attaches to
c             actin
c
      real*8 LmHN, LActHN, LActH, LSarOpt, l1H, k1THN, LT12, lPevkPtN
c v1HN   : normalized velocity of the proximal titin segment      
      real*8 v1HN
c LTiRigidHN : the length of the titin segment that can be considered
c              to be rigid: the parts bound up in myosin, and the 
c              segment between the z-line and the T12 epitope    
      real*8 LTiRigidHN
c f2HN    : force of the PEVK + distal Ig element
c f2HN1Der: 1st derivative w.r.t. l2N
c f2HN2Der: 2nd derivative w.r.t. l2N
      real*8 f2HN, f2HNDer1, f2HNDer2      
c l12HN  : norm. length of the free segment of titin: Z-line to 
c          myosin tip      
c l2H    : length of the distal segment of titin: N2A epitope to myosin
c l2HN   : " ... " normalized w.r.t. optimal fiber length    
c k2HN   : terminal normalized stiffness of the f2HN curve
      real*8 l12HN, l2H, l2HN, k2THN  
c beta1   : damping coefficient between the titin attachment point 
c           and actin         
c beta1AHN: maximum active damping coefficient between the titin 
c           attachment point and actin 
c beta1PHN: passive damping coefficient  between the titin attachment 
c           point and actin
      real*8 beta1, beta1AHN, beta1PHN
c The file name of the file that contains the falN curve data
c      character*10 falNFileName
c ltSlk  : tendon slack length      
c eTIso  : strain of the tendon at one isometric force   
c dtIsoN : norm. tendon damping at one isometric force  
c betaNumN : numerically small norm. tendon damping
c et     : strain of the tendon ()
c etN    : strain of the tendon normalized by etIso
c lt        : length of the tendon
c ltN    : normalized tendon length
c ftN    : normalized tendon force
c betaTNN: normalized tendon damping coefficient
      real*8 ltSlk,etIso,dtIsoN,betaNumN,et,etN,lt,ltN,ftN,betaTNN
c ftFcnN : normalized tendon force-length function value  
c ftFcnN1Der  : 1st derivative w.r.t. etN
c ftFcnN2Der  : 2nd derivative w.r.t. etN 
c ktFcnN      : normalized tendon stiffness function value  
c ktFcnN1Der : 1st derivative w.r.t. etN
c ktFcnN2Der : 2nd derivative w.r.t. etN
      real*8 ftFcnN,  ftFcnN1Der, ftFcnN2Der
      real*8 ktFcnN,  ktFcnN1Der, ktFcnN2Der
c ftCpFcnN : normalized compressive force-length function value  
c ftCpFcnN1Der  : 1st derivative w.r.t. lceATN
c ftCpFcnN2Der  : 2nd derivative w.r.t. lceATN   
      real*8 fCpFcnN, fCpFcnN1Der, fCpFcnN2Der
c      
c vMax: maximum contraction velocity in lOpt/sec
c fvNEccMax: maximum force deveuped during an eccentric contraction
c fvNConcAtHalfvNMax: normalized force developed at half the maximum 
c                   normalized shortening velocity. 
      real*8 vMax, fvNEccMax, fvNConcAtHalfvNMax 
c scalePEE: scales the combined passive force developed by the ECM and
c           titin elements
c shiftPEE: shifts the ECM, distal titin, and proximal titin curves
c           such that the resulting passive curve is shifted by shiftPEE
c lambdaECM: sets the fraction of the passive force due to the ECM, 
c            while (1-lambdaECM) is developed by titin
      real*8 scalePEE, shiftPEE, lambdaECM 
c shiftECM: amount to shift the ECM s.t. the total force-length curve
c           is shifted by shiftPEE  
c shiftProxTitin: amount to shift the Prox. Titin s.t. the total 
c           force-length curve is shifted by shiftPEE  
c shiftDistTitin: amount to shift the Dist. Titin s.t. the total 
c                 force-length curve is shifted by shiftPEE  
      real*8 shiftECM, shift1THN, shift2THN
      
c kXOptIsoNN      : maximum normalized lumped cross-bridge stiffness
c kXHNN           : normalized lumped cross-bridge stiffness
c betaXOptIsoNN   : maximum normalized lumped cross-bridge damping
c betaXHNN        : normalized lumped cross-bridge damping
c gainTracking    : feedback gain on cross-bridge strain during low activation
c actTracking     : activation threshold at which the gain tracking term becomes
c                   (smoothly) active
      real*8 kXOptIsoNN,kXHNN,betaXOptIsoNN,betaXHNN,gainTracking

c lxH       : lumped cross-bridge strain (half sarcomere)
c lxHN      : norm. lumped cross-bridge strain (half sarcomere)
c vxH       : lumped cross-bridge strain rate (half sarcomere)
c vxHN      : norm. lumped cross-bridge strain rate (half sarcomere)
c dvxH      : lumped cross-bridge strain rate derivative (half sarcomere)    
c dvxHN     : norm lumped cross-bridge strain rate derivative (half sarcomere)       
      real*8 lxH, lxHN, vxH, vxHN, dvxH, dvxHN 
c fxHN      : visco elastic crossbridge forces     
c fceN      : normalized CE force
c fceATN    : normalized CE force along the tendon
c fceAT     : CE force along the tendon      
      real*8 fxHN, fceN, fceATN, fceAT


c dvsHN          : Normalized half actin-myosin-attachment-pt acceleration
c dvsHNHill      : Hill-force tracking term in dvsHN
c dvsHNDamping   : Damping term in dvsHN
c dvsHNTracking  : Term to force lsHN and dlsHN to track myosin
c                   during low activation
      real*8 dvsHN, dvsHNHill, dvsHNDamping, dvsHNTracking
c ka             : term used in dvsHNTracking    
c taudvsdt  : A time constant used in dvsHNHill
c dvsBeta   : Cycling damping term used in dvsHNDamping 
      real*8 ka, taudvsdt, dvsBeta
c aniType: animal type: 0 human, 1 feline. This setting affects
c          the shape of the active-force-length curve and the f1 
c          and f2 curves of titin.      
c ctrlType: [0,1,2,3] 
c    0: curve stimId applied as an excitation signal
c    1: curve stimId applied as an activation signal
c    2: curve stimId applied directly as a tension to the material
c    3: reflex controller used
      integer aniType, ctrlType, ctrlTypeEx, ctrlTypeAct, ctrlTypeCurve
      integer ctrlTypeReflex

c ctrlDelay: The delay between when the controller is triggered and
c               when the excitation signal is applied to the muscle
c ctrlThresh: when the CE length exceeds its initial length
c                   by a fraction (1+ctrlThresh) the reflex
c                   controller will be triggered.
c ctrlForce: this constant force value is applied to the muscle. This
c            value is set by the curve that appears in stimId.
c ctrlOnTime: the time at which to enable the controller
      real*8 ctrlDelay, ctrlThresh, ctrlForce, ctrlOnTime 

c output :  output mode that sets the level of output:
c           0: no output
c           1: write musout file with diagnostic information
c           2: Additionally write out muscle curve values and derivatives
c dtout  :  sampling rate used to generate the output files      
      real*8 output
      real*8 dtout
      real*8 outputCounter

c errorLeft       : left value in a scalar bisection method
c errorRight      : right value in a scalar bisection method
c errorBest       : best value in a scalar bisection method
      real*8 errorLeft, errorRight, errorBest

c argLeft       : left value in a scalar bisection method
c argRight      : right value in a scalar bisection method
c argBest       : best value in a scalar bisection method
c argDelta      : the step width in value to try
      real*8 argLeft, argRight, argBest, argDelta

c i0, i1  : temporary integer variables
      integer i0
c Dtvw_Dt : time derivative of system energy less work (T+V-W)
      real*8 D_TpVmW_Dt

      common/soundloc/sndspd(nlq),sndsp(nlq),diagm(nlq),sarea(nlq)
      common/aux33loc/
     1 ix1(nlq),ix2(nlq),ix3(nlq),ix4(nlq),ix5(nlq),mxt(nlq)
      common/aux14loc/
     1 sig1(nlq),sig2(nlq),sig3(nlq),sig4(nlq),
     2 sig5(nlq),sig6(nlq),epx1(nlq),epx2(nlq),aux(nlq,14),dig1(nlq),
     3 sig_pass(nlq),sig_actv(nlq),act_levl(nlq),out_leng(nlq),
     4 eps_rate(nlq),sig_svs(nlq),sig_sde(nlq)   
c############################################
c#   set the model constants                #
c############################################
       

      PI = 3.1415926535897932384626433832795028      
      numEpsilon    = epsilon(PI)
      numEpsM       = 10.0*numEpsilon
      numEpsSqrt    = dsqrt(numEpsilon)


c Constants used to denote the type of controller.
c Added as of June 5 2023 because MM screwed up the simulation of
c a specific controller because he was using the integers inconsistently
      ctrlTypeEx        =0 
      ctrlTypeAct       =1 
      ctrlTypeCurve     =2
      ctrlTypeReflex    =3

c counter
      idxHsvOutputCounter     =1

c boundary conditions
      idxHsvLp                =2
      idxHsvVp                =3
      idxHsvExcitation        =4
c State
      idxHsvAct               =5
      idxHsvLceATN            =6
      idxHsvL1HN              =7
      idxHsvLsHN              =8
      idxHsvVsHNN             =9
c State derivative
      idxHsvActDot            =10
      idxHsvLceATNDot         =11
      idxHsvL1HNDot           =12
      idxHsvLsHNDot           =13
      idxHsvVsHNNDot          =14

c Auxillary variables: basic
      idxHsvLceN              =15
      idxHsvVceNN             =16
      idxHsvFceN              =17
      idxHsvAlpha             =18
      idxHsvAlphaDot          =19
      idxHsvFceATN            =20
      idxHsvLtN               =21
      idxHsvVtN               =22
      idxHsvFtN               =23

c Auxillary variables: element-by-element
      idxHsvLaN               =24
      idxHsvFalN              =25
      idxHsvVaNN              =26
      idxHsvFvN               =27
      idxHsvLceHN             =28
      idxHsvFecmHN            =29
      idxHsvF1HN              =30
      idxHsvL2HN              =31
      idxHsvF2HN              =32
      idxHsvLxHN              =33
      idxHsvVxHN              =34
      idxHsvFxHN              =35
      idxHsvFtfcnN            =36
      idxHsvFtBetaN           =37
      
c Auxillary variables: acceleration terms
      idxHsvDvsHNHill         =38
      idxHsvDvsHNDamping      =39
      idxHsvDvsHNTracking     =40
c Time derivative of the sum of system energy less work (should be zero)      
      idxHsvTpVmW             =41
c Control variables
      idxHsvRefLceATN         =42
      idxHsvCtrlForce         =43      
      idxHsvInitVelocities    =44
      idxHsvCtrlOnTime        =45
c Buffer variables
      idxHsvLceATNDelay       =60


c Detailed debugging data      
      idxHsvPT1               =70
      idxHsvPT2               =71
      idxHsvPT12              =72
      idxHsvPEcmK             =73
      idxHsvPEcmD             =74      
      idxHsvPXeK              =75
      idxHsvPXeD              =76
      idxHsvPXeA              =77
      idxHsvPCp               =78
      idxHsvPTK               =79
      idxHsvPTD               =80
      idxHsvPP                =81
      idxHsvErrForce          =82 
      idxHsvErrVelocity       =83

c############################################
c#   read in the material card values       #
c############################################
      stimId      = cm(1)
c      print *, "stimId:", stimId

      excitationDefault = cm(2)
c      print *, "exDefault:", excitationDefault

      tauAct      = cm(3)
c      print *, "tauAct:", tauAct

      tauDeact    = cm(4)
c      print *, "tauDeact:", tauDeact

      fceOptIso   = cm(5)
c      print *, "fceOptIso:", fceOptIso

      lceOpt      = cm(6)
c      print *, "lceOpt:", lceOpt
       
      alphaOptD   = cm(7)
      alphaOpt    = alphaOptD * (PI/180.0)      
c      print *, "alphaOptD:", alphaOptD

      useRigidTendonModel = .FALSE.
      if(cm(8).GT.0.5) then 
            useRigidTendonModel=.TRUE.
      endif
c      print *, "useRigidTendonModel:", useRigidTendonModel

      ltSlk       = cm(9)
c      print *, "ltSlk:", ltSlk

      etIso       = cm(10)  
c      print *, "etIso:", etIso    

      dtIsoN      = cm(11)
c      print *, "dtIsoN:", dtIsoN     

      scalePEE    = cm(12)
c      print *, "scalePEE:", scalePEE

      shiftPEE    = cm(13)
c      print *, "shiftPEE:", shiftPEE

      lambdaECM   = cm(14)
c      print *, "lambdaECM:", lambdaECM  

      lPevkPtN = cm(15) 
c      print *, "lPevkPtN:", lPevkPtN

      lceHNLb1A = cm(16)
c      print *, "lceHNLb1A:", lceHNLb1A

      act1AHN  = cm(17)
c      print *, "act1AHN:", act1AHN

      beta1AHN    = cm(18)
c      print *, "beta1AHN:", beta1AHN      

      beta1PHN    = cm(19)      
c      print *, "beta1PHN:", beta1PHN

      kXOptIsoNN   = cm(20)
c      print *, "kXOptIsoNN:", kXOptIsoNN

      betaXOptIsoNN   = cm(21)
c      print *, "betaXOptIsoNN:", betaXOptIsoNN

      gainTracking = cm(22)
c      print *, "gainTracking:", gainTracking

      actTracking  = cm(23)
c      print *, "actTracking:", actTracking      

      vceMax      = cm(24)
c      print *, "vceMax:", vceMax  

      taudvsdt    = cm(25)
c      print *, "taudvsdt:", taudvsdt  

      dvsBeta     = cm(26)
c      print *, "dvsBeta:", dvsBeta

      betaNumN    = cm(27)
c      print *, "betaNumN:", betaNumN     

      aniType     = int(cm(28))      
c      print *, "aniType:", aniType        

      ctrlType     = int(cm(29))
c      print *, "ctrlType:", ctrlType        

      ctrlDelay = cm(30)
c      print *, "ctrlDelay:", ctrlDelay

      ctrlThresh = cm(31)
c      print *, "ctrlThresh:", ctrlThresh

      ctrlOnTime = cm(32)
c      print *, "ctrlOnTime:", ctrlOnTime      

      output      = cm(33)
c      print *, "output:", output

      dtout       = cm(34)
c      print *, "dtout:", dtout

c      return
      modelIsPennated=.FALSE.
      if(alphaOpt.GT.numEpsSqrt) then
         modelIsPennated=.TRUE.
      endif

      hsv(idxHsvCtrlOnTime) = ctrlOnTime
      
c Hard coded parameter values
c     
c
c     This is the width over which the active damping between the PEVK
c     segment changes from 0-1 as the CE length exceeds lceHNLb1A, and
c     transitions from 1-0 as the l1HN exceeds the length of actin.
c     If this seems odd to you, note that all of the nonlinear curves
c     in this muscle model are also hard coded: it would be overwhelming
c     and error prone to give a typical user access to all of the 
c     parameters needed to generate the many nonlinear curves this model
c     depends on.
c
      lceLbWidth1AHN     = 0.05

c     When the distal element of titin (f2) is under more tension than
c     the proximal element the titin-actin bond is strengthened. And
c     just the opposite is true: when the f1 element is under more tension
c     than the f2 element the bond strength approaches zero. This width
c     parameter determines how much of a force difference is required
c     between the f2 and f1 elements to drive this transition.  
c   
      f2f1HNWidth        = 0.01

c     The strength of the titin-actin bond is known to reach maximum
c     strength before maximum activation is reached. I'm modeling this
c     using a tanh function. This parameter defines the width overwhich
c     the tanh function transitions from 0-1.
      act1AHNWidth = 0.1
c############################################
c#   Sarcomere-geometric constants          #
c############################################
c
c Even though this model is only being used for human simulations, many
c single benchmark simulations are done using cat muscle. And so, to
c have a fair comparision this model must have the flexibility to 
c simulate cat (skeletal) muscle.
c
c The geometric data below comes from:
c
c Rassier DE, MacIntosh BR, Herzog W. Length dependence of active force 
c production in skeletal muscle. Journal of applied physiology. 1999 
c May 1;86(5):1445-57.
c      
      select case (aniType)
c       Human      
        case(0)
c         Sarcomere length (um)        
          LSarOpt     = 2.725
c         Half myosin length (um/um)                  
c           4.24um:  max active length
c           2.64um:  beginning of the plateau
          LmHN        = 0.5*(4.24-2.64)/LSarOpt
c         T12 length (um/um)                           
c           0.1um: length from the Z-line to the T12 epitope
          LT12        = 0.1/LSarOpt
c         Segments of titin considered to be rigid (um/um)          
          LTiRigidHN  = LT12+LmHN
c         Actin length (um/um): 
c           half of: max active length, less myosin, less z-line thickness
c           4.24um: max active length
c           2*LmHN: total myosin length
c           0.05  : z-line thickness
          LActHN = 0.5*((4.24/LSarOpt)-2.0*LmHN-(2.0*0.05)/LSarOpt)
c       Feline      
        case(1)
c         All quantitues evaluated using same approach as is used for
c         the human case, but with the keypoints of the 
c         active-force-length relation updated        
          LSarOpt    = 2.425
          LmHN       = 0.5*(3.94-2.34)/LSarOpt
          LT12       = 0.1/LSarOpt
          LTiRigidHN = LT12+LmHN    
          LActHN     = 0.5*((3.94/LSarOpt)-2.0*LmHN-(2.0*0.05)/LSarOpt)
        case default 
          print *, "aniType must be human (0) or feline (1), not ",
     +           aniType
          return
      end select

      LmH = LmHN*lceOpt

c The thickness of the muscle      
      LceXT = lceOpt*dsin(alphaOpt)

c############################################
c#   calc length of muscle element          #
c############################################

      idpart = lqfmiv(mxt(lft))
c      print *, "idpart", idpart
      lp = dsqrt(sarea(i))
      vp = 0.0      
      if (dt1.LE.0) then
        hsv(idxHsvInitVelocities)=1.0
      endif
      if ((etype.eq.'tbeam').and.(dt1.GT.0)) then
         vp = eps(1)/dt1*dsqrt(sarea(i))                   
      endif


c############################################
c# Excitation, Activation, and Control
c############################################
      call updHsvControlSignals(cm,hsv,tt,dt1,ncycle,
     1 excitationDefault,lq1,crv,nnpcrv,no_hsvs)

      excitation=hsv(idxHsvExcitation)
      activation=hsv(idxHsvAct)
      ctrlForce =hsv(idxHsvCtrlForce)
      
c############################################
c# Shift values for the ECM, prox and distal titin curves
c############################################
c     A long length that is guaranteed to be in the region where
c     the stiffness of the curves is constant      
      k1THN= calcTitinProxHDer(2.0, 0., lPevkPtN, 1, numEpsM, aniType)
      k2THN= calcTitinDistHDer(2.0, 0., lPevkPtN, 1, numEpsM, aniType)

c     The model is of a half-sarcomere and so the ECM shift is half       
c     shiftPEE
      shiftECM = 0.5*shiftPEE;

c     The shift is distributed between the prox and distal titins in       
c     proportion to their relative compliance
      shift1THN = (0.5*shiftPEE)*((k2THN)/(k1THN+k2THN))
      shift2THN = (0.5*shiftPEE)*((k1THN)/(k1THN+k2THN))

c#################################################
c#   initialization 
c#     (call until, and including 1st iteration with dt1 > 0) #
c#################################################
c      print *, "ncycle : ", ncycle
c      print *, "dt1 : ", dt1 
c      print *, "lp : ", lp
c      print *, "vp : ", vp
c Note: element lengths are not defined for the first 3 cycles     
      if ((dt1.EQ.0).or.(ncycle.LE.1).or.(
     +     hsv(idxHsvInitVelocities).gt.(0.5))) then 
     

c        print *,"Initalization"
c        print *, "lp :",lp
c        print *, "vp :",vp
        if (dabs(dt1).GT.0) then
          hsv(idxHsvInitVelocities)=0.0
        endif        
c     no timestep available --> only initialisation  
c            print *, "Initialization"

c Check to see if the model is being restarted from an initialization
c     simulation AND if the reflex controller is being used. 
c     If this is the case, do not initialize the model
        if((lp.ge.0.95*hsv(idxHsvLp)).and.(
     +      lp.le.1.05*hsv(idxHsvLp)).and.(
     +      ctrlType.eq.ctrlTypeReflex)) then
            return
        endif

c Path state
        hsv(idxHsvLp)=lp
        hsv(idxHsvVp)=vp
        
c ActivationState
        hsv(idxHsvAct)=excitation
c        print *, "Pre Init"
c        print *, "lp: ", lp
c        print *, "vp: ", vp        
c        print *, "lceATN :", hsv(idxHsvLceATN)
c        print *, "l1HN :", hsv(idxHsvL1HN)      
c        print *, "lsHN :", hsv(idxHsvLsHN)         
c        print *, "vsHNN :", hsv(idxHsvVsHNN)                
                           

c CE States: lceAT, lsHN, vsHNN
        if (useRigidTendonModel.EQ.(.TRUE.)) then
          
c         Initialize Rigid-Tendon CEStates:          
c           hsv(idxHsvLceATN) 
c           hsv(idxHsvLsHN)
c           hsv(idxHsvVsHNN)
c           hsv(idxHsvL1HN)
          call updHsvInitialRigidTendonCEState(cm,hsv,PI,LceXT, 
     +      lceATNLowerBound, LmHN, shiftECM, shift1THM, shift2THM, 
     +      lPevkPtN, LTiRigidHN, numEpsSqrt,actTracking,16)

                 
        else


c         Initialize Elastic-Tendon CEStates:          
c           hsv(idxHsvLceATN) 
c           hsv(idxHsvLsHN)
c           hsv(idxHsvVsHNN)
c           hsv(idxHsvL1HN)
           call updHsvInitialElasticTendonCEState(cm,hsv,PI,LceXT, 
     +      lceATNLowerBound, LmHN, shiftECM, shift1THM, shift2THM,  
     +      lPevkPtN, LTiRigidHN, betaNumN,numEpsSqrt, actTracking,16)
                      
        endif



        hsv(idxHsvOutputCounter)    = 0.
c            print *, "hsv(idxHsvOutputCounter)    = 0."            


c State derivatives: All zero
        hsv(idxHsvActDot        ) =0
        hsv(idxHsvLceATNDot     ) =0
        hsv(idxHsvL1HNDot       ) =0
        hsv(idxHsvLsHNDot       ) =0
        hsv(idxHsvVsHNNDot      ) =0

c Initialize variables related to the reflex controlller
c Reference length for the reflex controller, if it is used.
        hsv(idxHsvRefLceATN)        = hsv(idxHsvLceATN)    
c        print *, "LenRef: ", hsv(idxHsvRefLceATN)

c        print *, "Post Init"
c        print *, "lp : ", lp
c        print *, "vp : ", vp
c        print *, "ltSlk : ", ltSlk
c        print *, "  lceATN : ", hsv(idxHsvLceATN)
c        print *, "    l1HN : ", hsv(idxHsvL1HN)      
c        print *, "    lsHN : ", hsv(idxHsvLsHN)         
c        print *, "   vsHNN : ", hsv(idxHsvVsHNN)
        
        return
      endif  
      
      
      
c############################################
c#   evaluate lengths of the subsegments of the muscle #
c############################################

c Get the kinematic state of the muscle
      outputCounter  = hsv(idxHsvOutputCounter)  

c----------------------------------------
c Kinematic States
c----------------------------------------
      
      lceATN         = hsv(idxHsvLceATN)
      
      l1HN           = hsv(idxHsvL1HN)    
            
      lsHN           = hsv(idxHsvLsHN)    
            
      vsHNN          = hsv(idxHsvVsHNN) 

c      print *, "Input"
c      print *, "      lp : ", lp
c      print *, "      vp : ", vp
c      print *, "   ltSlk : ", ltSlk      
c      print *, "  lceATN : ", lceATN
c      print *, "    l1HN : ", l1HN
c      print *, "    lsHN : ", lsHN      
c      print *, "   vsHNN : ", vsHNN

c      print *, "lxHN :", hsv(idxHsvLxHN)

c bound limits on lceATN      
      if(useRigidTendonModel.EQ.(.TRUE.)) then 
            lceAT             = lp-ltSlk
            lceATN            = lceAT/lceOpt
            hsv(idxHsvLceATN) = lceATN     
      endif

c The lower bound should not be reached: the compressive force length
c curve should prevent the solution from getting close to this 
c value. However, just in case, this check is in place to ensure that
c lceATN has a small finite value: otherwise the pennation model will
c have a singularity.

      lceATNReachedLowerBound=.FALSE.
      if( lceATN.LE.numEpsSqrt ) then 
            lceATNReachedLowerBound=.TRUE.
            lceATN  = numEpsSqrt
            lceAT   = lceATN*lceOpt
            hsv(idxHsvLceATN)=lceATN
      endif

      lceAT = lceATN*lceOpt
      l1H   = l1HN*lceOpt
      lsH   = lsHN*lceOpt
      vsHN  = vsHNN*(vceMax)     
      vsH   = vsHNN*(lceOpt*vceMax)
   
      lt    = lp-lceAT  
      ltN   = lt/ltSlk
      et    = ltN-1.0
      etN   = et/etIso   

c      print *, "Tendon strains"
c      print *, "      lt : ", lt
c      print *, "     ltN : ", ltN
c      print *, "      et : ", et
c      print *, "     etN : ", etN

c Evaluate the pennation model
      LceXT = lceOpt*dsin(alphaOpt)
      alpha = calcPennationAngle(lceAT,lceOpt,alphaOpt,
     1     LceXT,numEpsSqrt)

      cosAlpha = dcos(alpha)
      sinAlpha = dsin(alpha)
      lce      = dsqrt(lceAT*lceAT + LceXT*LceXT)
      lceN     = lce/lceOpt
      lceHN    = lceN*0.5
c Evaluate the lumped cross bridge strain 
      lxHN = lceHN - (LmHN + lsHN)
      lxH  = lxHN*lceOpt

c Evaluate the titin segment lengths and state derivative   
      l12HN = (lceHN-LTiRigidHN)
      l2HN  = l12HN-l1HN 

c#####################################################
c#   evaluate the position dependent curves & forces #
c#####################################################      

c Here laN is shifted by (2.0/kXOptIsoNN) to accomodate for the 
c shift in the force-length curve introduced by the strain of the 
c cross-bridges. See Sec. 3.4 of Millard et al. 2023 for details
c https://doi.org/10.1101/2023.03.27.534347 
      laN      = 2.0*(lsHN+LmHN)
      laNXeAdj = laN + (2.0/kXOptIsoNN)
      falN     = calcFalDer(laNXeAdj,0,numEpsM,aniType)
      
      fecmHN    = calcFecmHDer(lceHN,shiftECM,0,numEpsM,aniType)
      fecmHN    = lambdaECM*scalePEE*fecmHN 

      f1HN= calcTitinProxHDer(l1HN,shift1THN,lPevkPtN,0,numEpsM,aniType)
      f1HN= (1-lambdaECM)*scalePEE*f1HN

      f2HN= calcTitinDistHDer(l2HN,shift2THN,lPevkPtN,0,numEpsM,aniType)
      f2HN= (1-lambdaECM)*scalePEE*f2HN


      kXHNN    = activation*falN*kXOptIsoNN
      betaXHNN = activation*falN*betaXOptIsoNN
      
      fCpFcnN = calcCpNDer(lceATN,0,numEpsM)


c We solve for the value of dlce which balances the force developed
c between the CE and the tendon. We can expand the quantities for 
c the CE velocity along the tendon
c
c [1]   dlceAT     = dlce/cosAlpha; 
c 
c the tendon's rate-of-lengthening
c
c [2]  dltN       = (dlp-dlce/cosAlpha)/ltSlk;
c
c the crossbridge rate-of-lengthening
c
c [3]  dlxHN      = (dlce*0.5-dlaH)/lceOpt;
c
c The force dveloped by the CE is
c
c [4]  fce      = (fxHN + f2HN + fEcmHN + betaNumN*vceHN)*cosAlpha - fCpN;
c
c which we expand to
c
c [5]  fce      = (kxHNN*lxHN + betaxHNN*dlxHN 
c                + f2HN 
c                + (fEcmfcnHN + (betaNum + betafEcmHN*fEcmfcnHN)*dlceHN))*cosAlpha
c                - fCpN
c
c so that the only unknown is dlce (in dlxHN and dlceHN).
c The tension developed by the tendon is given by
c
c [6]  ft  = fTkN + betaTNN*(dlp - dlce/cosAlpha)/ltSlk;
c
c which has only dlce as an unknown. 
c If we subtract Eqn 5 from 6 we end up with the force imbalance between
c the CE and the tendon
c
c errF0 = -(kxHNN*lxHN ...
c            - (betaxHNN*dlaH/lceOpt) ...
c            + f2HN ...
c            + fEcmfcnHN ...
c         )*cosAlpha ...  
c         + fCpN
c         + (fTkN + betaTNN*(dlp/ltSlk)) ...
c         - dlce*( (betaxHNN*0.5/lceOpt) + (betaNum + betafEcmHN*fEcmfcnHN)*(0.5/lceOpt))*cosAlpha ...  
c         - dlce*(betaTNN/(cosAlpha*ltSlk))
c         = 0
c
c which can be solved for dlce since it is the only unknown. 
c Since the damping model for the ECM and the tendon include betaNum, 
c which is a small value above zero, there is guaranteed to be a 
c finite solution for dlce.
c
      if(useRigidTendonModel.EQ.(.FALSE.)) then
        ftFcnN  = calcFtNDer(etN,0,numEpsM)
        ktFcnN  = calcKtNDer(etN,0,numEpsM)
        betaTNN = dtIsoN*ktFcnN + betaNumN

        A0 = -(kXHNN*lxHN - (betaXHNN*vsH/lceOpt) + f2HN + fecmHN
     1        )*cosAlpha + fCpFcnN
        B0 = (ftFcnN + betaTNN*(vp/ltSlk))   
        C0 = -((betaXHNN+betaNumN)*(0.5/lceOpt))*cosAlpha
     1       - (betaTNN/(cosAlpha*ltSlk))    
        vce = -(A0+B0)/C0

        vceAT = vce/cosAlpha

      endif 

      if (useRigidTendonModel.EQ.(.TRUE.)) then
        vceAT = vp      
      endif

c     The compressive element should prevent this if statement from
c     ever being executed. Since this is not a guarantee, the if statement
c     is here to prevent the CE from reaching a length that produces
c     a singularity in the pennation model.
      if(lceATNReachedLowerBound) then
c        zero out vce if it is shortening        
         if(vceAT.LT.(0.)) then 
           vce   = 0.
           vceAT = 0.
         endif
c        zero out vsHN if it is shortening            
         if((vsHN).LE.(0.)) then 
           vsHNN = 0.
           vsHN  = 0.
           vsH   = 0.
         endif      
      endif 


c################################################
c#   evaluate the velocity dependent quantities #
c################################################ 

      vaNN     = 2.0*(vsHNN)
      fvN      = calcFvDer(vaNN,0,numEpsM,aniType)

c Solving for the pennation angular velocity
c Eqn 1.
c   d/dt (lce*sin(alpha)) = 0
c Eqn 2.
c   d/dt (lce * cos(alpha)) - vceAT = 0
c
c dalpha = -vceAT*sin(alpha)/lce
c    vce = cos(alpha) vceAT
      dalpha = -sinAlpha*vceAT/lce 
      vce    =  cosAlpha*vceAT
      vceH   =  vce*0.5


      vceATN = vceAT/lceOpt
      vceN   =   vce/lceOpt
      vceNN  =  vceN/vceMax
      vceHN  =  vceN*0.5;

c Evaluate the lumped cross bridge strain rate
      vxHN = vceHN - vsHN
      vxH  = vceH - vsH      
c Evaluate the tendon strain rate
c   : vceAT, ftFcnN, and betaTNN have been set appropriately for the
c     tendon's elasticity

      vt   = vp - vceAT
      vtN  = vt/ltSlk


c      print *, "CE rate of lengthening"
c      print *, "      vce: ", vce
c      print *, "    vceAT: ", vceAT
c      print *, "     vxHN: ",vxHN

c      print *, "Tendon normalized rate of lengthening"
c      print *, "     vt  : ", vt
c      print *, "     vtN : ", vtN


c############################################
c#   update the forces                      #
c############################################

      fxHN     = kXHNN*lxHN + betaXHNN*vxHN;

      fceN    = (fxHN + fecmHN + betaNumN*vceHN + f2HN)
     +          - (fCpFcnN/cosAlpha)
      fceATN  = fceN*cosAlpha
      fceAT   = fceATN*fceOptIso

      if (useRigidTendonModel.EQ.(.TRUE.)) then
        ftFcnN  = fceATN 
        ktFcnN  = 0.
        betaTNN = 0.        
      endif

      ftN     = ftFcnN + betaTNN*vtN

c      print *, "CE forces"            
c      print *, "   fceATN: ", fceATN
c      print *, "   fceAT : ", fceAT 

c      print *, "Tendon forces "
c      print *, "  ftFcnN : ", ftFcnN
c      print *, " betaTNN : ", betaTNN
c      print *, "     ftN : ", ftN

c      print *, "Constraint:"
c      A0 = (fceATN-ftN)
c      print *, "fceATN-ftN: ", A


c############################################
c#   apply forces to the element            #
c############################################

c  calc stresses from force
c  cross-section area is volume divided by part length

      if (etype.eq.'tbeam') then  
         if(ctrlType.ne.ctrlTypeCurve) then
            sig(1)=ftN*fceOptIso/(voltot(i)/dsqrt(sarea(i)))
            sig(2)=0.0
            sig(3)=0.0
         else
             sig(1)=ctrlForce/(voltot(i)/dsqrt(sarea(i)))
             sig(2)=0.0
             sig(3)=0.0
         endif
      endif

c############################################
c#   state derivative                       #
c############################################  

      activationDot = calcActivationDerivative(activation,excitation,
     1    tauAct,tauDeact)


c     Goes to 1 quickly after activation > act1AHN to model
c     the fact that the titin-actin bond reaches maximum strengh at 
c     low calcium concentrations
c     See Fukutani & Herzog (2018) for details
      realTemp = (activation-act1AHN)/act1AHNWidth
      realTemp1= (0-act1AHN)/act1AHNWidth
      realTemp1=0.5+0.5*tanh(realTemp1)
      realTemp2= (1-act1AHN)/act1AHNWidth
      realTemp2=0.5+0.5*tanh(realTemp2)
      activationTitinActinBond = 
     +  (0.5+0.5*tanh(realTemp)-realTemp1)/(realTemp2-realTemp1)


c     Active titin forces are not allowed to develop until lceHN has
c     exceeded lceHNLb1A, which is set to 0.5, or the optimal CE length
c     (which is 0.5 for the half sarcomere)
c     See Hisey, Leonard, Herzog (2009) for details
      realTemp = (lceHN-lceHNLb1A)/lceLbWidth1AHN
      lceNTitinActinLB = 0.5+0.5*dtanh(realTemp)

c     Active titin forces go to zero when the actin-titin bond position 
c     exceeds the length of actin. This is a consequence of the
c     kinematic model, and so there is no reference.
      realTemp = (LActHN-(l1HN + LT12))/lceLbWidth1AHN
      lceNTitinActinUB =  0.5+0.5*dtanh(realTemp)

c     Active titin forces only build when the distal element has a 
c     greater tension in it than the proximal element. If this condition
c     is not in place then the passive force developed by the f2 element
c     will drop substantially during shortening. Given enough shortening
c     it would even be conceivable that the f2 element could reverse
c     directions and drive the force of the CE to zero.
      realTemp   = (f2HN-f1HN)/f2f1HNWidth
      f1f2HNDiff = 0.5+0.5*dtanh(realTemp)

      beta1 = beta1PHN + (lceNTitinActinLB*lceNTitinActinUB
     +                 *activationTitinActinBond*f1f2HNDiff)*beta1AHN
      v1HN  = (f2HN-f1HN)/beta1 

c      print *, "    v1HN : ", v1HN

      dvsHNHill      = (fxHN-activation*falN*fvN)/taudvsdt
      dvsHNDamping   = -vsHNN*dvsBeta;      
      ka             = activation/actTracking
      dvsHNTracking  = dexp(-ka*ka)*gainTracking*(lxHN+vxHN)
      dvsHN          = dvsHNHill+dvsHNDamping+dvsHNTracking


c      print *, " dvsHNHill: ", dvsHNHill
c      print *, " dvsHNDamp: ", dvsHNDamping
c      print *, "        ka: ", ka
c      print *, " dvsHNTrak: ", dvsHNTracking
c      print *, "     dvsHN: ", dvsHN
      

c############################################
c#   update debugging details                #
c############################################      
c     The code below evaluates the terms of d/dt(T+V-W) where T is
c     potential energy, V is kinetic energy, and W is work. This model
c     has no mass, and so there are no V terms. All elastic terms are
c     V terms, and as such are positive. All dampers are work terms
c     and so are negative. Dampers also do negative work, and so there
c     are two negatives which cancel - I've left these in place
c     for clairity.

      hsv(idxHsvPT1 ) =( 2.* v1HN*lceOpt*f1HN*fceOptIso)
      hsv(idxHsvPT2 ) =( 2.*(vceHN-v1HN)*lceOpt*f2HN*fceOptIso)

c This is the damper between f1 and f2
      hsv(idxHsvPT12) =(-2.*(v1HN  )*lceOpt*(v1HN*beta1)*fceOptIso)  
      hsv(idxHsvPEcmK)=( 2.*(vceHN )*lceOpt*fecmHN*fceOptIso)  

c This the numerical damping of the ECM      
      hsv(idxHsvPEcmD)=(-2.*(vceHN )*lceOpt*(vceHN*betaNumN)*fceOptIso)        

      hsv(idxHsvPXeK) = ( 2.*(vxHN  )*lceOpt*(kXHNN*lxHN)*fceOptIso)  
c This is the cross-bridge damping      
      hsv(idxHsvPXeD) = (-2.*(vxHN  )*lceOpt*(betaXHNN*vxHN)*fceOptIso)  

c This is the active work done by the cycling cross bridges to the
c muscle. Since tension is a positive sign, the negative has to be
c added: when vs < 0 and fxHN > 0 cross-bridge cycling is doing positive
c work
      hsv(idxHsvPXeA) =(-2.*(vsHN  )*lceOpt*fxHN*fceOptIso)   

c This is not a damper: its a compressive spring to prevent the CE from
c reaching a length of zero (which causes a numerical singularity in )
c the pennation model.
      hsv(idxHsvPCp ) =(-1.*(vceATN)*lceOpt*fCpFcnN*fceOptIso)   
      hsv(idxHsvPTK ) =( 1.*(vtN   )* ltSlk*(ftFcnN)*fceOptIso)   

c This is the tendon's damping      
      hsv(idxHsvPTD ) =(-1.*(vtN   )* ltSlk*(betaTNN*vtN)*fceOptIso)    

c This is the work done by the boundary on the muscle
      hsv(idxHsvPP  ) =( 1.*(vp    )*(ftN)*fceOptIso)   

      hsv(idxHsvErrForce    ) =  fceATN-ftN
      hsv(idxHsvErrVelocity ) =  vp-(vceAT+vt) + (vceH-(vsH+vxH))

c############################################
c#   energy tracking                        #
c############################################  
       D_TpVmW_Dt = hsv(idxHsvPT1 )
     +             +hsv(idxHsvPT2 )
     +             -hsv(idxHsvPT12)
     +             +hsv(idxHsvPEcmK)
     +             -hsv(idxHsvPEcmD)     
     +             +hsv(idxHsvPXeK)
     +             -hsv(idxHsvPXeD)
     +             -hsv(idxHsvPXeA)
     +             +hsv(idxHsvPCp )
     +             +hsv(idxHsvPTK )
     +             -hsv(idxHsvPTD )
     +             -hsv(idxHsvPP  )

c      D_TpVmW_Dt = (2.*v1HN*lceOpt*f1HN*fceOptIso)
c     + +( 2.*(vceHN-v1HN)*lceOpt*f2HN*fceOptIso)    
c     + -(-2.*(v1HN      )*lceOpt*(f2HN-f1HN)*fceOptIso)     
c     + +( 2.*(vceHN     )*lceOpt*fecmHN*fceOptIso)
c     + +( 2.*(vxHN      )*lceOpt*(kXHNN*lxHN)*fceOptIso)
c     + -(-2.*(vxHN      )*lceOpt*(betaXHNN*vxHN)*fceOptIso)
c     + -(-2.*(vsHN      )*lceOpt*fxHN*fceOptIso)
c     + +(-1.*(vceATN    )*lceOpt*fCpFcnN*fceOptIso)
c     + +( 1.*(vtN       )* ltSlk*(ftFcnN)*fceOptIso)
c     + +(+1.*(vtN       )* ltSlk*(betaTNN*vtN)*fceOptIso)     
c     + -( 1.*(vp        )*(ftN)*fceOptIso)



c############################################
c#   update the history vector                #
c############################################      
          
c     hsv(idxHsvOutputCounter ) : updated below 
      hsv(idxHsvLp            ) = lp 
      hsv(idxHsvVp            ) = vp
      hsv(idxHsvExcitation    ) = excitation

c Integrate the state forwards in time      
      hsv(idxHsvAct           ) = activation + activationDot*dt1
      hsv(idxHsvLceATN        ) = lceATN     + vceATN*dt1
      hsv(idxHsvL1HN          ) = l1HN       + v1HN*dt1
      hsv(idxHsvLsHN          ) = lsHN       + vsHN*dt1
      hsv(idxHsvVsHNN         ) = vsHNN      + (dvsHN*dt1)/(vceMax)

c      print *, "End of first call"
c      print *, "lceATN :", lceATN
c      print *, "lsHN :", lsHN      
c      print *, "vsHNN :", vsHNN
c      print *, "l1HN :", l1HN
c      print *, "lxHN :",lxHN
      
c State dervative      
      hsv(idxHsvActDot        ) = activationDot
      hsv(idxHsvLceATNDot     ) = vceATN
      hsv(idxHsvL1HNDot       ) = v1HN
      hsv(idxHsvLsHNDot       ) = vsHN
      hsv(idxHsvVsHNNDot      ) = dvsHN/vceMax
      

c      print *, "vceATN :", vceATN
c      print *, "lsHNDot :", vsHN      
c      print *, "vsHNNDot :", dvsHN/vceMax
c      print *, "v1HN :", v1HN
c      print *, "vxHN :",vxHN
      
c Auxiliary variables: basic
      hsv(idxHsvLceN          ) = lceN
      hsv(idxHsvVceNN         ) = vceNN
      hsv(idxHsvFceN          ) = fceN
      hsv(idxHsvAlpha         ) = alpha
      hsv(idxHsvAlphaDot      ) = dalpha
      hsv(idxHsvFceATN        ) = fceATN
      hsv(idxHsvLtN           ) = ltN
      hsv(idxHsvVtN           ) = vtN
      hsv(idxHsvFtN           ) = ftN
c Auxillary variables: element-by-element
   
      hsv(idxHsvLaN     ) = laN 
      hsv(idxHsvFalN    ) = falN 
      hsv(idxHsvVaNN    ) = vaNN 
      hsv(idxHsvFvN     ) = fvN 
      hsv(idxHsvLceHN   ) = lceHN 
      hsv(idxHsvFecmHN  ) = fecmHN 
      hsv(idxHsvF1HN    ) = f1HN 
      hsv(idxHsvL2HN    ) = l2HN 
      hsv(idxHsvF2HN    ) = f2HN 
      hsv(idxHsvLxHN    ) = lxHN 
      hsv(idxHsvVxHN    ) = vxHN 
      hsv(idxHsvFxHN    ) = fxHN 
      hsv(idxHsvFtfcnN  ) = ftFcnN 
      hsv(idxHsvFtBetaN ) = betaTNN*vtN 

c Auxillary variables: acceleration terms
      hsv(idxHsvDvsHNHill     ) = dvsHNHill
      hsv(idxHsvDvsHNDamping  ) = dvsHNDamping
      hsv(idxHsvDvsHNTracking ) = dvsHNTracking

c Time derivative of system energy less work
      hsv(idxHsvTpVmW         ) = D_TpVmW_Dt

c Control output
      hsv(idxHsvCtrlForce)      = ctrlForce



c     Update the reference length only if the reflex controller is
c     not currently activated: this makes it possible to run an 
c     initial short simulation to get the resting position of the model
      if((ctrlType.ne.ctrlTypeReflex).or.(ncycle.le.3)) then
         hsv(idxHsvRefLceATN)     = lceATN 
c         print *, "LenRef ", hsv(idxHsvRefLceATN)
      endif

c Extra debugging output
c      hsv(idxHsvExtra00) = lceAT
c      hsv(idxHsvExtra01) = lceOpt
c      hsv(idxHsvExtra02) = alphaOpt
c      hsv(idxHsvExtra03) = LceXT
      
c      if((hsv(idxHsvInitVelocities).LE.(0.5)).AND.(dt1.GE.0)) then
c        call exit(0)
c      endif
c############################################
c#   output data
c############################################
      if((output.eq.1).or.(output.eq.2)) then
         if(tt.GE.(outputCounter*dtout)) then
c            print *, "call writeMuscleDataToFile(86,..."
            call writeMuscleDataToFile(86,outputCounter,idpart,tt,hsv)
            call writeDebugDataToFile(85,outputCounter,idpart,tt,hsv)     
            if(output.eq.2) then
               falNDer1  = calcFalDer(laNXeAdj,1,numEpsM, aniType)
               falNDer2  = calcFalDer(laNXeAdj,2,numEpsM, aniType) 

               call writeCurveDataToFile(87,'falN.',
     1            outputCounter,idpart,tt,laN,falN,falNDer1,falNDer2)

               fvNDer1   = calcFvDer(vaNN,1,numEpsM,aniType)
               fvNDer2   = calcFvDer(vaNN,2,numEpsM,aniType)
               call writeCurveDataToFile(88,'fvN.',
     1            outputCounter,idpart,tt,vaNN,fvN,fvNDer1,fvNDer2)

               fecmHN    =calcFecmHDer(lceHN,shiftECM,0,numEpsM,aniType)
               fecmHNDer1=calcFecmHDer(lceHN,shiftECM,1,numEpsM,aniType)
               fecmHNDer2=calcFecmHDer(lceHN,shiftECM,2,numEpsM,aniType)

               call writeCurveDataToFile(10,'fecmHN.',
     1          outputCounter,idpart,tt,lceHN,fecmHN,fecmHNDer1,
     2          fecmHNDer2)   

               f1HN     =calcTitinProxHDer(l1HN,shift1THN,lPevkPtN,0,
     1                    numEpsM, aniType)
               f1HNDer1 =calcTitinProxHDer(l1HN,shift1THN,lPevkPtN,1,
     1                    numEpsM, aniType)
               f1HNDer2 =calcTitinProxHDer(l1HN,shift1THN,lPevkPtN,2,
     1                    numEpsM, aniType)

               call writeCurveDataToFile(11,'f1HN.',
     1          outputCounter,idpart,tt,l1HN,f1HN,f1HNDer1,f1HNDer2)

               f2HN     =calcTitinDistHDer(l2HN,shift2THN,lPevkPtN,0,
     1                    numEpsM,aniType)
               f2HNDer1 =calcTitinDistHDer(l2HN,shift2THN,lPevkPtN,1,
     1                    numEpsM,aniType)
               f2HNDer2 =calcTitinDistHDer(l2HN,shift2THN,lPevkPtN,2,
     1                    numEpsM,aniType)

               call writeCurveDataToFile(12,'f2HN.',
     1          outputCounter,idpart,tt,l2HN,f2HN,f2HNDer1,f2HNDer2)  
c# Dummy value for etN just to ensure the curves are implemented correctly
c# before I start adding the elastic tendon model
               etN = (lceATN-1)
               ftFcnN     = calcFtNDer(etN,0,numEpsM)
               ftFcnN1Der = calcFtNDer(etN,1,numEpsM)
               ftFcnN2Der = calcFtNDer(etN,2,numEpsM)  

               call writeCurveDataToFile(20,'ftFcnN.',
     1          outputCounter,idpart,tt,etN,ftFcnN,ftFcnN1Der,
     2          ftFcnN2Der)

               ktFcnN     = calcKtNDer(etN,0,numEpsM)
               ktFcnN1Der = calcKtNDer(etN,1,numEpsM)
               ktFcnN2Der = calcKtNDer(etN,2,numEpsM)  

               call writeCurveDataToFile(21,'ktFcnN.',
     1          outputCounter,idpart,tt,etN,ktFcnN,ktFcnN1Der,
     2          ktFcnN2Der)               

c#               fCpFcnN     = calcCpNDer(lceATN,0,numEpsM)
               fCpFcnN1Der = calcCpNDer(lceATN,1,numEpsM)
               fCpFcnN2Der = calcCpNDer(lceATN,2,numEpsM)  

               call writeCurveDataToFile(22,'fCpFcnN.',
     1          outputCounter,idpart,tt,lceATN,fCpFcnN,fCpFcnN1Der,
     2          fCpFcnN2Der)               


            endif 
            hsv(idxHsvOutputCounter)=hsv(idxHsvOutputCounter)+1
         endif
      endif

c for other element types EHTM not applicable

      if (etype.ne.'tbeam') then
         cerdat(1)=etype
         call lsmsg(3,MSG_SOL+1150,ioall,ierdat,rerdat,cerdat,0)
c
c10   format(/
c    1 ' *** Error element type ',a,' can not be',
c    2 '           run with the current material model.')
      endif
c
      return
      end
c END OF SUBROUTINE UMAT43
c
c############################################
c#   ring buffer subroutine               # #
c############################################
      subroutine ringbuffer_umat43(cm,hsv,tt,no_hsvs)

        dimension cm(*),hsv(*)
        integer no_hsvs
        logical flag_found
        integer idxHsvLceATN, idxHsvLceATNDelay, idxHsvBufSize, 
     1    idxHsvBufEleDelay, idxHsvBufValStart, idxHsvBufIdx, 
     2    idxHsvBufDelayIdx, idxHsvBufTimeStart, idxCmBufDelay, 
     3    i0,i1,j0,j1,idx
        real*8 ttLast, ttDelay, n

        idxHsvLceATN          = 6
        idxHsvLceATNDelay     = 60
        idxHsvBufSize         = 50
        idxHsvBufEleDelay     = 51
        idxHsvBufValStart     = 52   
        idxHsvBufIdx          = 53
        idxHsvBufDelayIdx     = 54
        idxHsvBufTimeStart    = 55    

        idxCmBufDelay         = 30

c   Lazy initialization
        if(hsv(idxHsvBufValStart).ne.150) then

          if(no_hsvs.le.200) then 
            call usermsg('hsv must be at least 200 elements long')
          endif

c         Index 150 is chosen as the start: in the comments for umat41 it is
c         mentioned that lsdyna appears to use hsv(142:145) internally  
c         so here we're using 150 as a starting point away from 142:145        
          hsv(idxHsvBufValStart)=150

c         Set the buffer size so that there is enough space for a buffer
c         to hold the sample times, and another to hold the values with
c         an open item at the ends of each buffer          
          hsv(idxHsvBufSize) = 
     1      floor((no_hsvs-hsv(idxHsvBufValStart)-4)/2)
          hsv(idxHsvBufTimeStart)=hsv(idxHsvBufValStart)
     1                           +hsv(idxHsvBufSize)+2

c         The delay of each entry is set to ensure that the buffer data 
c         covers the entire duration with a little extra. If the buffer is
c         sized to fit the desired time exactly, it can happen that there is
c         not an interval that can be used to linearly interpolate the data
          hsv(idxHsvBufEleDelay) = 
     1      cm(idxCmBufDelay)*1.1/hsv(idxHsvBufSize)

c         Initialize the buffer values to zeros
          do i=0,(hsv(idxHsvBufSize)-1),1 
            hsv(hsv(idxHsvBufValStart)+i)=0.    
            hsv(hsv(idxHsvBufTimeStart)+i)=0.    
          enddo 

c         Initialize the index of the current buffer value, and the location
c         of the index that is delayed by cm(idxCmBufDelay)
          hsv(idxHsvBufIdx)     =0
          hsv(idxHsvBufDelayIdx)=1 

c         Initialize the starting values of the time and value records
          i0 = hsv(idxHsvBufTimeStart)+hsv(idxHsvBufIdx)
          hsv(i0) = tt
          j0 = hsv(idxHsvBufValStart) +hsv(idxHsvBufIdx)
          hsv(j0) = hsv(idxHsvLceATN)             
        endif

        ttLast = hsv( hsv(idxHsvBufTimeStart)+hsv(idxHsvBufIdx) )

c       Update the buffer if enough time has passed
        if( tt.ge.( ttLast+hsv(idxHsvBufEleDelay) ) ) then 
c           Increment the buffer index            
            hsv(idxHsvBufIdx)= 
     1          mod(hsv(idxHsvBufIdx)+1, hsv(idxHsvBufSize))
            i0 = hsv(idxHsvBufTimeStart)+hsv(idxHsvBufIdx)
            hsv(i0) = tt 

            j0 = hsv(idxHsvBufValStart)+hsv(idxHsvBufIdx)
            hsv(j0) = hsv(idxHsvLceATN)

        endif

c       If enough time has passsed, fetch the delayed values
        if( tt.gt.cm(idxCmBufDelay) ) then 
          idx=0
          flag_found = .FALSE.
          ttDelay = tt-cm(idxCmBufDelay)

c         Go find the an interval in the delayed data that brackets
c         the delayed time t0
          do while ( (idx.lt.(hsv(idxHsvBufSize))).and.(
     1                                 flag_found.eq.(.FALSE.) )   ) 

            i0 = hsv(idxHsvBufTimeStart)+hsv(idxHsvBufDelayIdx)
            i1 = hsv(idxHsvBufTimeStart)
     1         + mod( hsv(idxHsvBufDelayIdx)+1, hsv(idxHsvBufSize))
            if( (ttDelay.ge.(hsv(i0))).and.(ttDelay.lt.hsv(i1)) ) then
                flag_found = .TRUE.
            else 
                idx=idx+1
                hsv(idxHsvBufDelayIdx) = 
     1            mod(hsv(idxHsvBufDelayIdx)+1,hsv(idxHsvBufSize))         
            endif

          end do
          if(flag_found.eq.(.FALSE.)) then 
            call usermsg('ringbuffer: could not find past value')
          endif

c         Evaluate how far ttDelay is within the time interval
          n = (ttDelay-hsv(i0))/(hsv(i1)-hsv(i0))

          j0 = hsv(idxHsvBufValStart)+hsv(idxHsvBufDelayIdx)
          j1 = hsv(idxHsvBufValStart)
     1         + mod( hsv(idxHsvBufDelayIdx)+1, hsv(idxHsvBufSize))

c         Interpolate the stored values within the interval
          hsv(idxHsvLceATNDelay)= hsv(j0) + n*(hsv(j1)-hsv(j0))

        endif        
        return
      end 


c############################################
c#   output subroutine                    # #
c############################################
c
      subroutine writeCurveDataToFile(fileNo,crvName,outputCounter, 
     1   idpart,tt,arg,crvVal,crv1DerVal,crv2DerVal)
   
      integer idpart,fileNo
      character*80 fname
      character*10 fname1
      character(*) crvName
      write(fname1,'(I10.10)') idpart
      fname = crvName // fname1
      if (outputCounter.eq.0) then
         OPEN(fileNo,FILE=fname,FORM='FORMATTED',STATUS='UNKNOWN')
         write(fileNo,'('' output for muscle (PartID):'',I10)')idpart
         write(fileNo,'(''           time            arg''
     +                  ''            val           der1''
     +                  ''           der2'')')
         write(fileNo,'(5ES15.5E3)')tt,arg,crvVal,crv1DerVal,crv2DerVal
         CLOSE(fileNo)
      else
         OPEN(fileNo,FILE=fname,ACCESS='APPEND',FORM='FORMATTED',
     1      STATUS='UNKNOWN')
         write(fileNo,'(5ES15.5E3)')tt,arg,crvVal,crv1DerVal,crv2DerVal
         CLOSE(fileNo)
      endif                            
      return
      end
c END OF CURVE OUTPUT SUBROUTINE
      subroutine writeMuscleDataToFile(fileNo, outputCounter,idpart,
     1 tt,hsv)
c
      dimension hsv(*)        
      integer idpart, fileNo
      character*80 fname,fname1
      write(fname1,'(I10.10)') idpart
      fname = 'musout.'//fname1

c write extended output if output option == 2 and controller 
c card is set
c      print *, "writeMuscleDataToFile: if(outputCounter.eq.0) ..."
      if (outputCounter.eq.0) then
c     open/create the file under the filename created above
c         print *, "writeMuscleDataToFile: write header start"
         OPEN(fileNo,FILE=fname,FORM='FORMATTED',STATUS='UNKNOWN')
c        write header at the beginning
         write (fileNo,'(''advanced output for muscle (PartID):
     1      '',I10)')idpart
         write (fileNo,
     +    '(''           time             lp             vp''
     +      ''              e              a         lceATN''
     +      ''           l1HN           lsHN          vsHNN''
     +      ''           aDot         vceATN           v1HN''
     +      ''           vsHN       vsHNNDot           lceN''
     +      ''          vceNN           fceN          alpha''
     +      ''         dalpha         fceATN            ltN''
     +      ''            vtN            ftN            laN''
     +      ''           falN           vaNN            fvN''
     +      ''          lceHN         fecmHN           f1HN''
     +      ''           l2HN           f2HN           lxHN''
     +      ''           vxHN           fxHN         ftFcnN''
     +      ''        ftBetaN      dvsHNHill      dvsHNDamp''
     +      ''      dvsHNTrak     D_TpVmW_Dt      ctrlLceN0''
     +      ''      ctrlForce'')')
  
         write (fileNo,'(43ES15.5E3)')tt,hsv(2:43)
         CLOSE(fileNo)
c         print *, "writeMuscleDataToFile: write header end"
      else
c         open/create the file under the filename created above
c         print *, "writeMuscleDataToFile: write data start"
         OPEN(fileNo,FILE=fname,ACCESS='APPEND',FORM='FORMATTED',
     1      STATUS='UNKNOWN')
c         write normal data without header from now on
         write (fileNo,'(43ES15.5E3)')tt,hsv(2:43)
           CLOSE(fileNo)
c         print *, "writeMuscleDataToFile: write data end"
      endif

      return
      end
c      
c END OF SUBROUTINE OUTPUT
      subroutine writeDebugDataToFile(fileNo,outputCounter,idpart,tt
     1  ,hsv)
c
      dimension hsv(*)        
      integer idpart, fileNo
      character*80 fname,fname1
      write(fname1,'(I10.10)') idpart
      fname = 'musdebug.'//fname1

c write extended output if output option == 2 and controller 
c card is set
c      print *, "writeMuscleDataToFile: if(outputCounter.eq.0) ..."
      if (outputCounter.eq.0) then
c     open/create the file under the filename created above
c         print *, "writeMuscleDataToFile: write header start"
         OPEN(fileNo,FILE=fname,FORM='FORMATTED',STATUS='UNKNOWN')
c        write header at the beginning
         write (fileNo,'(''advanced output for muscle (PartID):
     1      '',I10)')idpart
         write (fileNo,
     +    '(''           time        pwrTi1K        pwrTi2K''
     +      ''        pwrTi12        pwrEcmK        pwrEcmD''
     +      ''         pwrXeK         pwrXeD         pwrXeA''
     +      ''         pwrCpK          pwrTK          pwrTD''
     +      ''          pwrPP       errForce         errVel'')')
  
         write (fileNo,'(15ES15.5E3)')tt,hsv(70:83)
         CLOSE(fileNo)
c         print *, "writeMuscleDataToFile: write header end"
      else
c         open/create the file under the filename created above
c         print *, "writeMuscleDataToFile: write data start"
         OPEN(fileNo,FILE=fname,ACCESS='APPEND',FORM='FORMATTED',
     1      STATUS='UNKNOWN')
c         write normal data without header from now on
         write (fileNo,'(15ES15.5E3)')tt,hsv(70:83)
           CLOSE(fileNo)
c         print *, "writeMuscleDataToFile: write data end"
      endif

      return
      end
c      
c END OF SUBROUTINE OUTPUT

c############################################
c#    calcActivationDerivative
c############################################
      real*8 function calcActivationDerivative(act,exc,tauAct,tauDeact)

      real*8 act,exc,tauAct,tauDeact,dact, tau

c evaluate the previous activation derivative      
      if (exc.GE.act) then
            tau = (tauAct*(0.5+1.5*act))
            calcActivationDerivative=(exc-act)/tau
      else
            tau = (tauDeact/(0.5+1.5*act))
            calcActivationDerivative=(exc-act)/tau            
      endif

      return
      end
c############################################
c#    calcPennationAngle
c############################################
      real*8 function calcPennationAngle(argLceAT,argLceOpt,
     1      argAlphaOpt, argLceXT,tolerance)

      real*8 argLceAT, argLceOpt, argAlphaOpt, argLceXT, tolerance

      if (argAlphaOpt.LE.tolerance) then
            calcPennationAngle=0.      
      else         
         calcPennationAngle = datan2(argLceXT,argLceAT)
      endif
      
      return
      end

c############################################
c#    calcCEVelocity
c############################################
c# Across the tendon we have
c# [1]  lce*sin(alpha)=h
c# where h is a constant. Taking a time derivative
c# [2] dlce*sin(alpha)+lce*cos(alpha)*dalpha=0
c# and solving for dalpha yields
c# [3] dalpha = (-dlce*sin(alpha)) / (lce*cos(alpha)) 
c# Along the tendon we have
c# [4] lceAT = lce*cos(alpha)
c# Taking a time derivative yields
c# [5]  dlceAT = dlce*cos(alpha) - lce*sin(alpha)*dalpha
c# Substituting in Eqn. 3 yields
c# [6]  dlceAT = dlce*cos(alpha) - lce*sin(alpha)*(-dlce*sin(alpha)) / (lce*cos(alpha)) 
c# which simplifies to
c# [7]  dlceAT = [dlce*cos2(alpha) + dlce*sin2(alpha)] / (cos(alpha))
c# and finally
c# [8]  dlceAT = dlce/cos(alpha)
      real*8 function calcVce(argVceAT,argCosAlpha)
        real*8 argVceAT,argCosAlpha
        calcVce = argVceAT*argCosAlpha      
        return
      end      

c############################################
c#    calcPennationAngularVelocity
c############################################
      real*8 function calcPennationAngularVelocity(argLce,argVce,
     +                  argSinAlpha,argCosAlpha)
        real*8 argLce,argVce,argSinAlpha,argCosAlpha

        calcPennationAngularVelocity = 
     +      -(argVce*argSinAlpha)/(argLce*argCosAlpha)
        return
      end 
c###############################################
c#   calculate the control signals           # #
c###############################################
c
      subroutine updHsvControlSignals(cm,hsv,tt,dt1,ncycle,
     1 excitationDefault, lq1,crv,nnpcrv,no_hsvs)
      
        include 'memaia.inc'
        common/bk07/n1,n2,n3,n4,n5,n6,n7,n8,n9
        common/bk00/numnp,numpc,numlp,neq,ndof,nlcur      
      
        integer lq1, ncycle
        dimension cm(*),hsv(*),crv(lq1,2,*)
        integer nnpcrv(*)
        
        real*8 excitationDefault, yval, slope
        
        integer idxHsvExcitation, indexHsvAct, idxHsvLceATN,
     +    indexHsvCtrlForce, idxHsvRefLceATN, idxHsvLceATNDelay,
     +    idxHsvVp, idxHsvCtrlOnTime      
        integer ctrlType

        real*8 stimId, activation, excitation, ctrlForce, ctrlDelay,
     +      ctrlThresh,lceATNCtrl
     
        stimId       = cm(1)
        ctrlType     = int(cm(29))
        ctrlDelay    = cm(30)
        ctrlThresh   = cm(31)

        idxHsvVp                =3

        idxHsvExcitation        =4
        idxHsvAct               =5
        idxHsvLceATN            =6
        
        idxHsvRefLceATN        =42
        idxHsvCtrlForce        =43

        idxHsvCtrlOnTime       =45

        idxHsvLceATNDelay       =60

        excitation = 0.
        activation = 0.
        ctrlForce  = 0.

        if(tt.le.hsv(idxHsvCtrlOnTime)) then
c         If the controller is not yet enabled, use the default values          
c         for excitation and activation
          excitation            = excitationDefault 
          activation            = excitationDefault
          hsv(idxHsvRefLceATN)  = hsv(idxHsvLceATN)

        else
        
          select case (ctrlType)

            case (0)         
c             ctrlTypeEx must be 0            
c             Excitation is driven by the curve with stimId         
c             Fetch the excitation signal 

              call crvval(crv,nnpcrv,stimId,tt,yval,slope)        
              excitation           = yval     

c             Fetch the activation signal

              activation = hsv(idxHsvAct) 
                
            case (1)
c             ctrlTypeAct must be 1                        
c             Activation is driven by the curve with stimId  

              call crvval(crv,nnpcrv,stimId,tt,yval,slope)
              activation        = yval
              excitation        = yval

            case (2)         
c             ctrlTypeCurve must be 2                        
c             Tension is directly set by the curve                           
              call crvval(crv,nnpcrv,stimId,tt,yval,slope)
              ctrlForce          = yval   

            case (3)
c             ctrlTypeReflex must be 3                                   
c             Initialization phase         
c             Continues to ncycle=2 to ensure that the muscle initialisation
c             function has been called before the ringbuffer is used

              if ((dt1.EQ.0).or.(ncycle.LE.2)) then
                excitation            = excitationDefault 
                activation            = excitationDefault                 
              else   

c               Reflex controller  

                if(ctrlDelay.gt.0) then
                  call ringbuffer_umat43(cm,hsv,tt,no_hsvs) 
c                 Use delayed data from the ring buffer, if its available  

                  if(tt.ge.ctrlDelay) then 
                    lceATNCtrl = hsv(idxHsvLceATNDelay)
                  else
                    lceATNCtrl = hsv(idxHsvLceATN)
                  endif

                else
c                 No delay                                
                  lceATNCtrl = hsv(idxHsvLceATN)
                endif

c               Once time exceeds the delay time, run the reflex controller
                if(tt.ge.ctrlDelay) then 
                  if(lceATNCtrl.ge.(
     1                (1.0+ctrlThresh)*hsv(idxHsvRefLceATN) ) ) then
                    excitation=1.0
                  elseif( (lceATNCtrl.ge.hsv(idxHsvRefLceATN)).and.(
     2                     hsv(idxHsvExcitation).ge.1.0) ) then
                    excitation=1.0
                  else
                    excitation=excitationDefault 
                  endif
c                   Otherwise use the default excitation
                else 
                      excitation=excitationDefault
                endif                  
              
              endif
                
              activation = hsv(idxHsvAct)

            case default
              excitation            = excitationDefault 
              activation            = excitationDefault
              hsv(idxHsvExcitation) = excitation
              hsv(idxHsvAct)        = activation  

              call usermsg('Error: ctrlType is not valid');          
          end select

        endif 

        excitation = max( 0., min(1.,excitation))
        activation = max( 0., min(1.,activation))
                
        hsv(idxHsvExcitation)   = excitation
        hsv(idxHsvAct)          = activation
        hsv(idxHsvCtrlForce)    = ctrlForce
        
        return
      end      

c###############################################
c#   Rigid Tendon CE Initialization Routine
c#      To call this function the following variables must be 
c#      already initialized in hsv:
c#
c#        hsv(idxHsvLp         ) 
c#        hsv(idxHsvVp         ) 
c#        hsv(idxHsvExcitation ) 
c#        hsv(idxHsvAct        ) 
c#
c#      This function will update the 4 states associated with the CE
c#        hsv(idxHsvLceATN) 
c#        hsv(idxHsvLsHN)
c#        hsv(idxHsvVsHNN)
c#        hsv(idxL1HN)
c#
c#      To initialize the state of this model requires maxBisectionIter
c#      iterations over the length of the CE along the tendon. Each 
c#      iteration of this bisection method is as computationally 
c#      as 2 calls to updHsvInitialElasticTendonCEState: initializing
c#      an elastic tendon muscle model is 
c#      maxBisectionIter*maxBisectionIter 
c#      times as expensive as initializing a rigid tendon model.
c#          
c###############################################
      subroutine updHsvInitialElasticTendonCEState(cm,hsv,PI,LceXT, 
     +  lceATNLowerBound, LmHN, shiftECM, shift1THM, shift2THM,
     +  lPevkPtN, LTiRigidHN, betaNumN,tolerance,actTracking,
     +  maxBisectionIter)
c     Input variables       
        dimension cm(*), hsv(*)
        real*8 PI, LceXT, lceATNLowerBound, LmHN, tolerance,
     +    actTracking, lPevkPtN, shiftECM, shift1THM, shift2THM, 
     +    LTiRigidHN, betaNumN  
        integer maxBisectionIter, aniType   
c     cm constants           
        real*8 lceOpt,alphaOpt,alphaOptD,ltSlk,etIso,kXOptIsoNN,vceMax,
     +          betaXOptIsoNN  
c     Inputs        
        real*8 lp,vp,ex,act
c     Lce quantities        
        real*8 lceAT,lceATN,lce,lceH,lceN,lceHN,vce,vceH,vceHN
     +         vceAT, vceATN
c     Pennation quantities       
        real*8 alpha, cosAlpha, sinAlpha
c     Tendon quantities        
        real*8 lt,ltN,et,etN,vt,vtN
c     Cross bridge quantities
        real*8 lxHN,vxH,vxHN
c     Sliding element quantities        
        real*8  lsN, lsHN, vsH, vsHN, vsHNN
c     Length of actin-myosin ignoring the x-bridge strain
        real*8 vaH,lamN, lamNXeAdj        
c     Titin element
        real*8 l1HN,l2HN,l12HN      
c     Multipler related variables
        real*8 fvN, falN, fecmHN, ftFcnN, ktFcnN, betaTNN, ftN, 
     +         fCpFcnN, dtIsoN,f1HN,f2HN, kXHNN, betaXHNN  
        real*8 scalePEE, lambdaECM
c     Indices
        integer idxHsvLp, idxHsvVp, idxHsvExcitation, idxHsvAct
        integer idxHsvLceHN, idxHsvLceATN
        integer idxHsvLxHN 
        integer idxHsvLsHN, idxHsvVsHNN
        integer idxHsvL1HN
c     Counters
        integer iterLceAT, iterLceATStepDir, iterLceATStepMax,
     +   iterVceAT, iterVceATStepDir, iterVceATStepMax,
     +   maxVceATBisectionIter
c     Flags        
        logical lceATNReachedLowerBound
        logical useRigidTendonModel
c     Variables for the bisection method code        
        real*8 lceATStepSign,lceATDelta,errLceAT
        real*8 vceATStepSign,vceATDelta,errVceAT
        real*8 A,B,C
        real*8, dimension(7)::lceATLeft
        real*8, dimension(7)::lceATRight
        real*8, dimension(7)::lceATBest
        real*8, dimension(7)::vceATLeft        
        real*8, dimension(7)::vceATRight
        real*8, dimension(7)::vceATBest
        
        idxHsvLp          = 2 
        idxHsvVp          = 3 
        idxHsvExcitation  = 4 
        idxHsvAct         = 5
        idxHsvLceATN      = 6         
        idxHsvL1HN        = 7         
        idxHsvLsHN        = 8
        idxHsvVsHNN       = 9

        idxHsvLceHN       = 28

c Model constants
        lceOpt      = cm(6)
        alphaOptD   = cm(7)
        alphaOpt    = alphaOptD * (PI/180.0)         
        useRigidTendonModel= .FALSE. 
        if(cm(8).GT.0.5) then 
            useRigidTendonModel=.TRUE.
        endif    
        ltSlk       = cm(9)
        etIso       = cm(10) 
        dtIsoN      = cm(11)
        kXOptIsoNN    = cm(20)
        betaXOptIsoNN = cm(21)
        vceMax      = cm(24)
        aniType     = int(cm(28))
        scalePEE    = cm(12) 
        lambdaECM   = cm(14)

c Inputs
        lp      = hsv(idxHsvLp)
        vp      = hsv(idxHsvVp)
        ex      = hsv(idxHsvExcitation)
        act     = hsv(idxHsvAct)

c        print *,"Input"
c        print *," lp:",lp
c        print *," vp:",vp
c        print *," ex:",ex
c        print *," act:",act

c Iterate over the length of the contractile element to find the
c length, along with assumed velocity values, that best satisfy the
c force equilibrium between the CE and the tendon        

c iterLceAT counts the length iterations
        iterLceAT=0 
c iterLceATStepDir counts the direction (left/right) iterations        
        iterLceATStepDir=0

        do while (iterLceAT.LE.maxBisectionIter)

          if( iterLceAT.EQ.0 ) then 
c           Solve for the error of the initial solution length of the CE
            lceATBest(2)      = lp*0.5
            lceATDelta        = lp*0.25
            iterLceATStepMax  = 1
            iterLceATStepDir  = 0
c            print *,"iterLceAt ", iterLceAT
c            print *," lceATBest: ",lceATBest(2)
c            print *," lceATDelta: ",lceATDelta
c            print *," iterLceATStepMax: ",iterLceATStepMax
c            print *," iterLceATStepDir: ",iterLceATStepDir
          else 
c           Normal bisection iteration            
            iterLceATStepMax  = 2
            iterLceATStepDir  = 0
c            print *,"iterLceAt ", iterLceAT            
          endif 
          

          do while (iterLceATStepDir.LT.iterLceATStepMax)

c           Choose a left step direction / right step direction
            select case (iterLceATStepDir)
              case (0)
                lceATStepSign=-1.
              case (1)
                lceATStepSign= 1.
            end select

c           For the first iteration take no step.            
            if(iterLceAT.EQ.0) then
              lceATStepSign = 0.           
            endif

            lceAT = lceATBest(2) + lceATDelta*lceATStepSign
            lceATN=lceAT/lceOpt
c            print *," lceAT: ",lceAT

            if( lceATN.LE.lceATNLowerBound ) then 
                lceATN = lceATNLowerBound
                lceAT  = lceATN*lceOpt
            endif            

            alpha   = calcPennationAngle(lceAT,lceOpt,alphaOpt,
     1                  LceXT,tolerance)
            cosAlpha = dcos(alpha)
            sinAlpha = dsin(alpha)
c            print *," alpha: ",alpha

            lce   = dsqrt(lceAT*lceAT + LceXT*LceXT)
            lceH  = lce*0.5
            lceN  = lce/lceOpt
            lceHN = lceN*0.5            
            lceATN= lceAT/lceOpt
c            print *," lceN: ",lceN
            
            lt    = lp-lceAT
            ltN   = lt/ltSlk
            et    = ltN-1.0
            etN   = et/etIso
c            print *," et: ",et
c           Evaluate length dependent forces

            fecmHN  = calcFecmHDer(lceHN,shiftECM,0,tolerance,aniType)
            fecmHN  = lambdaECM*scalePEE*fecmHN   
c            print *," fecmHM: ",fecmHN

            fCpFcnN = calcCpNDer(lceATN,0,tolerance)     
c            print *," fCpFcnN: ",fCpFcnN
            
            ftFcnN  = calcFtNDer(etN,0,tolerance) 
            ktFcnN  = calcKtNDer(etN,0,numEpsM)
            betaTNN = dtIsoN*ktFcnN + betaNumN 
c            print *," ftFcnN: ",ftFcnN
c            print *," ktFcnN: ",ktFcnN
c            print *," betaTNN: ",betaTNN
c           Solve for the equlibrium position of the two titin segments            
            call updHsvInitialTitinState(cm,hsv,lceHN,lPevkPtN,
     +            shift1THM, shift2THM, LTiRigidHN, tolerance,
     +            maxBisectionIter)
            l1HN    = hsv(idxHsvL1HN)
            l12HN   = lceHN-LTiRigidHN
            l2HN    = l12HN-l1HN
c            print *," l1HN: ",l1HN
c            print *," l2HN: ",l2HN
            
            f1HN    = calcTitinProxHDer(l1HN,shift1THN,lPevkPtN,
     +                  0,tolerance, aniType)
            f1HN    = (1.-lambdaECM)*scalePEE*f1HN            
            
            f2HN    = calcTitinDistHDer(l2HN,shift2THN,lPevkPtN,
     +                  0,tolerance, aniType)
            f2HN    = (1.-lambdaECM)*scalePEE*f2HN            
c            print *," f1HN: ",f1HN
c            print *," f2HN: ",f2HN
c           Iterate over dlceAT in an effort to find the velocity that
c           balances the forces between the CE and the tendon such that
c           1. the cross-bridge stain-rate is zero,
c           2. and the acceleration of the sliding point is zero.

            iterVceAT   = 0
            vceATBest(3)= vp*0.5
            vceATDelta  = vp*0.25 
            maxVceATBisectionIter=maxBisectionIter
            if (dabs(vp).LE.tolerance) then 
                maxVceATBisectionIter=1
            endif
c            print *, " maxVceATBisectionIter: ", maxVceATBisectionIter
            do while (iterVceAT.LT.maxVceATBisectionIter)
              iterVceATStepDir=0

              vceATLeft(1) = 1.0E10 
              vceATRight(1)= 1.0E10

              if(iterVceAT.EQ.0) then 
                iterVceATStepMax=1
              else
                iterVceATStepMax=2
              endif 
              
c              print *,"  iterVceAT: ",iterVceAT
              
              do while (iterVceATStepDir.LT.iterVceATStepMax)
                select case (iterVceATStepDir)
                  case (0)
                    vceATStepSign=-1.
                  case (1)
                    vceATStepSign= 1.                  
                end select

                if(iterVceAT.EQ.0) then
                  vceATStepSign=0.
                endif

                vceAT = vceATBest(3) + vceATStepSign*vceATDelta
c                print *,"    vceAT: ",vceAT
                
                vt    = vp-vceAT
                vtN   = vt/ltSlk
c                print *,"    vtN: ",vtN

                vce   = calcVce(vceAT, cosAlpha)
                vceH  = vce*0.5
                vceN  = vce/lceOpt
                vceHN = vceN*0.5
c                print *,"    vceN: ",vceN

c               We are looking for solutions that do not begin with
c               a transient force: this means vxH = 0, since the 
c               cross-bridges are quite stiff
                vxH   = 0
                vxHN  = vxH/lceOpt
                vsHN  = vceHN-vxHN
                vsHNN = vsHN/vceMax
                vaNN  = 2.0*vsHNN
                fvN   = calcFvDer(vaNN,0,tolerance,aniType)
c                print *,"    vxHN: ",vxHN
c                print *,"    vaNN: ",vaNN
c                print *,"     fvN: ",fvN
c               Solve for the cross-bridge strain that satisfies
c               the acceleration equation
                call updHsvInitialCrossbridgeLength(cm,hsv,lce,vsHNN,
     1                 vxHN,actTracking,tolerance, 3, aniType)

                idxHsvLxHN  = 33
                lxHN        = hsv(idxHsvLxHN)
c                print *,"     lxHN: ",lxHN
                
c               Solve for the difference in the force developed by 
c               the CE and the tendon
                lsHN      = lceHN-LmHN-lxHN 
                lamN      = (lceHN - lxHN)*2.0
                lamNXeAdj = lamN  + (2.0/kXOptIsoNN)
                falN      = calcFalDer(lamNXeAdj,0,tolerance,aniType)
                kXHNN     = act*falN*kXOptIsoNN
                betaXHNN  = act*falN*betaXOptIsoNN 
c                print *,"     lsHN: ",lsHN
c                print *,"     lamN: ",lamN
c                print *,"     falN: ",falN
c                print *,"    kXHNN: ",kXHNN
c                print *," betaXHNN: ",betaXHNN
                
                vaH = vceH - vxH  
c                print *,"      vaH: ",vaH

                A = -(kxHNN*lxHN-(betaXHNN*vaH/lceOpt)
     +                +f2HN+fecmHN)*cosAlpha + fCpFcnN
              
                B = (ftFcnN + betaTNN*(vp/ltSlk))
              
                C = - ((betaXHNN*0.5/lceOpt) 
     +            + (betaNumN)*(0.5/lceOpt))*cosAlpha
     +            - (betaTNN/(cosAlpha*ltSlk))
                              
                errVceAT =  dabs(-C*vce-(A+B))
c                print *,"        A: ",A
c                print *,"        B: ",B
c                print *,"        C: ",C
c                print *,"  errVceAT: ",errVceAT

                if(iterVceAT.EQ.0) then 
c                 Save the error, arguments, and the full state                  
                  vceATBest(1) = errVceAT
                  vceATBest(2) = lceAT 
                  vceATBest(3) = vceAT 
                  vceATBest(4) = lceATN
                  vceATBest(5) = l1HN
                  vceATBest(6) = lsHN 
                  vceATBest(7) = vsHNN 
c                  print *,"  vceATBest: ", errVceAT
                  
                else

                  select case (iterVceATStepDir)
                    case (0)
                      vceATLeft(1) = errVceAT
                      vceATLeft(2) = lceAT 
                      vceATLeft(3) = vceAT 
                      vceATLeft(4) = lceATN
                      vceATLeft(5) = l1HN
                      vceATLeft(6) = lsHN 
                      vceATLeft(7) = vsHNN 
c                      print *,"   vceATLeft: ", errVceAT
                    case (1)
                      vceATRight(1) = errVceAT
                      vceATRight(2) = lceAT 
                      vceATRight(3) = vceAT 
                      vceATRight(4) = lceATN
                      vceATRight(5) = l1HN
                      vceATRight(6) = lsHN 
                      vceATRight(7) = vsHNN
c                      print *,"   vceATRight:", errVceAT
                  end select

                endif
                
                iterVceATStepDir=iterVceATStepDir+1
              end do

c             Update the best solution
              if ( (vceATLeft(1).LT.vceATBest(1)).AND.(
     1              vceATLeft(1).LT.vceATRight(1)) ) then                   
                vceATBest(1) = vceATLeft(1)
                vceATBest(2) = vceATLeft(2) 
                vceATBest(3) = vceATLeft(3) 
                vceATBest(4) = vceATLeft(4) 
                vceATBest(5) = vceATLeft(5)
                vceATBest(6) = vceATLeft(6)
                vceATBest(7) = vceATLeft(7)
c                print *,"   upd vceATBest(L): ", vceATBest(1)
              endif

              if ( (vceATRight(1).LT.vceATBest(1)).AND.(
     1              vceATRight(1).LT.vceATLeft(1)) ) then                   
                vceATBest(1) = vceATRight(1)
                vceATBest(2) = vceATRight(2) 
                vceATBest(3) = vceATRight(3) 
                vceATBest(4) = vceATRight(4) 
                vceATBest(5) = vceATRight(5)
                vceATBest(6) = vceATRight(6)
                vceATBest(7) = vceATRight(7)
c                print *,"  upd vceATBest(R): ", vceATBest(1)
              endif   

              vceATDelta  = vceATDelta*0.5
              iterVceAT   = iterVceAT+1
            end do

c           Evalute the error of the initial solution
            if( iterLceAT.EQ.0 ) then
c           Set error best  
              lceATBest(1) = vceATBest(1)
              lceATBest(2) = vceATBest(2)
              lceATBest(3) = vceATBest(3)
              lceATBest(4) = vceATBest(4)
              lceATBest(5) = vceATBest(5)
              lceATBest(6) = vceATBest(6)
              lceATBest(7) = vceATBest(7)
c              print *,"*lceATBest: ", lceATBest(1)
            
            else
c           Set the appropriate errorLeft / errorRight
              select case (iterLceATStepDir)
                case (0)
                  lceATLeft(1)  = vceATBest(1)
                  lceATLeft(2)  = vceATBest(2)
                  lceATLeft(3)  = vceATBest(3)
                  lceATLeft(4)  = vceATBest(4)
                  lceATLeft(5)  = vceATBest(5)
                  lceATLeft(6)  = vceATBest(6)
                  lceATLeft(7)  = vceATBest(7)
c                  print *," upd lceATLeft: ", vceATBest(1)
                case (1)
                  lceATRight(1) = vceATBest(1) 
                  lceATRight(2) = vceATBest(2) 
                  lceATRight(3) = vceATBest(3) 
                  lceATRight(4) = vceATBest(4) 
                  lceATRight(5) = vceATBest(5) 
                  lceATRight(6) = vceATBest(6) 
                  lceATRight(7) = vceATBest(7)
c                  print *," upd lceATRight: ", vceATBest(1)
              end select            

            endif 

            iterLceATStepDir=iterLceATStepDir+1

          end do 
c If errorLeft or errorRight is better than errorBest, update
c         Update the best solution
          if ( (lceATLeft(1).LT.lceATBest(1)).AND.(
     1          lceATLeft(1).LT.lceATRight(1)) ) then                   
            lceATBest(1) = lceATLeft(1)
            lceATBest(2) = lceATLeft(2) 
            lceATBest(3) = lceATLeft(3) 
            lceATBest(4) = lceATLeft(4) 
            lceATBest(5) = lceATLeft(5)
            lceATBest(6) = lceATLeft(6)
            lceATBest(7) = lceATLeft(7)
c            print *,"*lceATBest: ", lceATBest(1)
          endif

          if ( (lceATRight(1).LT.lceATBest(1)).AND.(
     1          lceATRight(1).LT.lceATLeft(1)) ) then                   
            lceATBest(1) = lceATRight(1)
            lceATBest(2) = lceATRight(2) 
            lceATBest(3) = lceATRight(3) 
            lceATBest(4) = lceATRight(4) 
            lceATBest(5) = lceATRight(5)
            lceATBest(6) = lceATRight(6)
            lceATBest(7) = lceATRight(7) 
c            print *,"*lceATBest: ", lceATBest(1)
          endif 

          lceATDelta = lceATDelta*0.5
          iterLceAT=iterLceAT+1

        end do

c Update hsv with the best state vector
        hsv(idxHsvLceATN) = lceATBest(4)
      
        hsv(idxHsvL1HN)   = lceATBest(5) 
            
        hsv(idxHsvLsHN)   = lceATBest(6) 
            
        hsv(idxHsvVsHNN)  = lceATBest(7)        


c        print *, "updHsvInitialElasticTendonCEState"
c        print *, "lceATN: ", hsv(idxHsvLceATN)
c        print *, "  l1HN: ", hsv(idxHsvL1HN)
c        print *, "  lsHN: ", hsv(idxHsvLsHN)
c        print *, " vsHNN: ", hsv(idxHsvVsHNN)

c        lt    = lp-hsv(idxHsvLceATN)*lceOpt
c        ltN   = lt/ltSlk
c        et    = ltN-1.0
c        etN   = et/etIso
c        print *,"    et: ", et
c        print *,"   etN: ", etN
        
      end

c###############################################
c#   Rigid Tendon CE Initialization Routine
c#      To call this function the following variables must be 
c#      already initialized in hsv:
c#
c#        hsv(idxHsvLp         ) 
c#        hsv(idxHsvVp         ) 
c#        hsv(idxHsvExcitation ) 
c#        hsv(idxHsvAct        ) 
c#
c#      This function will update the 4 states associated with the CE
c#        hsv(idxHsvLceATN) 
c#        hsv(idxHsvLsHN)
c#        hsv(idxHsvVsHNN)
c#        hsv(idxHsvL1HN)
c#
c#      The computational cost to initialize these states is rougly 
c#      as follows:
c#
c#      lceATN     : directly calculated
c#      lsHN & vsHN: 3 fixed point iterations 
c#      l1HN       : maxBisectionIter iterations of the bisection method
c#          
c###############################################
      subroutine updHsvInitialRigidTendonCEState(cm,hsv,PI,LceXT, 
     +  lceATNLowerBound, LmHN, shiftECM, shift1THM, shift2THM,
     +  lPevkPtN, LTiRigidHN, tolerance, actTracking, maxBisectionIter)
c     Input variables       
        dimension cm(*), hsv(*)
        real*8 PI, LceXT, lceATNLowerBound, LmHN, shiftECM, shift1THM, 
     +    shift2THM, tolerance, actTracking, lPevkPtN, LTiRigidHN  
        integer maxBisectionIter,aniType  
c     cm constants           
        real*8 lceOpt,alphaOpt,alphaOptD,ltSlk,etIso,kXOptIsoNN,vceMax
c     Inputs        
        real*8 lp,vp,ex,act
c     Lce quantities        
        real*8 lceAT,lceATN,lce,lceH,lceN,lceHN, vce, vceAT
c     Pennation quantities       
        real*8 alpha, cosAlpha
c     Tendon quantities        
        real*8 ltN,et,etN,vt,vtN
c     Cross bridge quantities
        real*8 lxHN,vxHN
c     Sliding element quantities        
        real*8  lsHN,  vsH, vsHN, vsHNN 
c     Multiplers
        real*8 fvN
c     Indices
        integer idxHsvLp, idxHsvVp, idxHsvExcitation, idxHsvAct
        integer idxHsvLceHN, idxHsvLceATN
        integer idxHsvLxHN 
        integer idxHsvLsHN, idxHsvVsHNN
c     Flags        
        logical lceATNReachedLowerBound

        idxHsvLp          = 2 
        idxHsvVp          = 3 
        idxHsvExcitation  = 4 
        idxHsvAct         = 5
        idxHsvLceATN      = 6        
        idxHsvLsHN        = 8
        idxHsvVsHNN       = 9

        idxHsvLceHN       = 28

c Model constants
        lceOpt      = cm(6)
        alphaOptD   = cm(7)
        alphaOpt    = alphaOptD * (PI/180.0)         
        ltSlk       = cm(9)
        etIso       = cm(10) 
        kXOptIsoNN  = cm(20)
        vceMax      = cm(24)
        aniType     = int(cm(28))

c Inputs
        lp      = hsv(idxHsvLp)
        vp      = hsv(idxHsvVp)
        ex      = hsv(idxHsvExcitation)
        act     = hsv(idxHsvAct)

c Solve for the length of the CE
        lceAT   = lp-ltSlk
        lceATN  = lceAT/lceOpt
        vceAT   = vp   
         
        if( lceATN.LE.lceATNLowerBound ) then 
            lceATN = lceATNLowerBound
            lceAT  = lceATN*lceOpt
            vceAT = 0.
        endif

c Evaluate vsHNN
        alpha   = calcPennationAngle(lceAT,lceOpt,alphaOpt,
     1              LceXT,tolerance)

        cosAlpha  = dcos(alpha)
c   Evaluate vce given vceAT:        
c   1.     lce*sinAlpha = h
c     d/dt(lce*sinAlpha)= 0
c          dlce*sinAlpha+lce*cosAlpha*dalpha = 0
c          dalpha = -dlce*sinAlpha/(lce*cosAlpha)
c
c   2. vceAT = d/dt(lce*cosAlpha)
c            = vce*cosAlpha-lce*sinAlpha*dalpha
c            = vce*cosAlpha-lce*sinAlpha*(-vce*sinAlpha/(lce*cosAlpha))
c            = (vce*cos2Alpha+vce*sin2Alpha)/cosAlpha
c            = vce/cosAlpha
c     Thus 
c        vce= vceAT*cosAlpha
c
        vce    = vceAT*cosAlpha
c     Assume that the XE is cycling fast enough that vxHN = 0        
        vxHN   = 0 
        vsH    = vce*0.5 - vxHN
        vsHNN  = vsH/(vceMax*lceOpt)

c   Evaluate lsHN
c
c   Since 
c     lxHN = lceHN - (LmHN + lsHN) 
c   we're going to solve for lsHN by evaluating lxHN (since we know lceHN)
c   
c
c   Solve for the XE strain if the acceleration equation
c   evalates to zero.
c   
c     ddlaHN  = ((kXHNN*lxHN + betaXHNN*dlxHN)-a*flN*fvN)/tau
c                -betaCXHN*dlaNN
c                +lowActivationGain*exp(-ka*ka)*(lxHN + dlxHN)   
c             = 0
c     since we've set dlx=0, and have a candidate values for lceAT
c     and dlceAT the only unknown in this equation is lx. Technically
c     this function is nonlinear in lx since flN(lamN(lmH,laH))
c   
c       lxHN*(kXHNN/tau + lowActivationGain*exp(-ka*ka)) = 
c         -( betaXHNN*dlxHN - a*flN*fvN)/tau
c         + betaCXHN*dlaNN
c         -( lowActivationGain*exp(-ka*ka) )*dlxHN
c   
        lce     = dsqrt(LceXT*LceXT + lceAT*lceAT) 
        lceN    = lce/lceOpt    
        lceH    = lce  * 0.5
        lceHN   = lceN * 0.5

        call updHsvInitialCrossbridgeLength(cm,hsv,lce,vsHNN,vxHN,
     1    actTracking,tolerance, 3, aniType)
                
        idxHsvLxHN  = 33
        lxHN        = hsv(idxHsvLxHN)
        lsHN        = lceHN - LmHN - lxHN   

c Update hsv
        hsv(idxHsvLceATN) = lceATN
c            print *, "lceATN", lceATN
        hsv(idxHsvLsHN)   = lsHN
c            print *, "lsHN:", lsHN                  
        hsv(idxHsvVsHNN)  = vsHNN
c            print *, "vsHN:", vsHN  
              
c     Initialize Titin States
        call updHsvInitialTitinState(cm,hsv,lceHN,lPevkPtN,
     +        shift1THM, shift2THM,LTiRigidHN,tolerance,
     +        maxBisectionIter)



      end

c###############################################
c#    Crossbridge length initialization subroutine
c#      This function uses fixed point iteration to solve for
c#      a value of the cross-bridge strain that results in an
c#      acceleration of zero for the point of cross-bridge--to--actin
c#      attachment (dvsHN). Here dvsHN is given by
c#
c#      ka    = a/actTracking
c#      dvsHN = [(a*flN*(kXOptIsoNN*lxHN + betaXOptIsoNN*vxHN))
c#              - a*flN*fvN]/taudvsdt
c#              -vsHNN*dvsBeta
c#              dexp(-ka*ka)*gainTracking*(lxHN+vxHN)
c#
c#      By setting dvsHN to zero and taking a candidate value of lxHN,
c#      we can solve dvsHN above for lxHN. Preliminary numerical studies
c#      suggest that this fixed point iteration converges very quickly
c#      - 2 iterations is often enough.
c#
c###############################################
      subroutine updHsvInitialCrossbridgeLength(cm,hsv,lce,vsHNN,vxHN, 
     1  actTracking,tolerance, maxFixedPointIterations,aniType)
        dimension cm(*), hsv(*)
        real*8 lce,vsHNN,vxHN,actTracking,tolerance
        integer maxFixedPointIterations,aniType
        real*8 kXOptIsoNN,betaXOptIsoNN,lceOpt,actTracking
     +    taudvsdt, gainTracking,dvsBeta
        real*8 vaNN,lxH,lxHN,fvN,laH,laN,laNXeAdj,activation
        real*8 lceH,falN,kXHNN,betaXHNN,ka,t0,t1,expKaSq
        integer i,idxHsvAct,idxHsvLxHN

        lceOpt       = cm(6)
        kXOptIsoNN   = cm(20)
        gainTracking = cm(22)
        taudvsdt     = cm(25)
        dvsBeta      = cm(26)
        
        idxHsvAct    = 5
        activation   = hsv(idxHsvAct)

        lceH = lce*0.5

        vaNN = 2.0*vsHNN
        fvN  = calcFvDer(vaNN,0,tolerance,aniType)
        lxHN = fvN/kXOptIsoNN
           
        i=0
        do while (i.LE.maxFixedPointIterations)
          lxH  = lxHN*lceOpt
          laH  = lceH-lxH
          laN  = (2.0*laH)/lceOpt
          laNXeAdj = laN + (2.0/kXOptIsoNN)
          falN = calcFalDer(laNXeAdj,0,tolerance,aniType)
          kXHNN     = activation*falN*kXOptIsoNN
          betaXHNN  = activation*falN*betaXOptIsoNN

          ka = activation/actTracking

          expKaSq = dexp(-ka*ka)
          t0 = ((kXHNN/taudvsdt)+gainTracking*expKaSq)
          t1 = -(betaXHNN*vxHN-(activation*falN*fvN))/taudvsdt
     1          +vsHNN*dvsBeta 
     2          -gainTracking*expKaSq*vxHN         
          lxHN=t1/t0
c          print *, "lxHN: ", lxHN
          i=i+1
        end do

        idxHsvLxHN     = 33         
        hsv(idxHsvLxHN)=lxHN
c        print *, "lxHN: ", lxHN


      end
c###############################################
c#   Titin initialization subroutine: 
c#      To call this function the following variables must be 
c#      already initialized in hsv:
c#
c#        hsv(idxHsvLceHN         ) : set by a previous initialization function  
c#
c#      This function will update the single state associated with titin
c#        hsv(idxHsvL1HN          ) 
c#       
c###############################################
c
      subroutine updHsvInitialTitinState(cm,hsv,lceHN,lPevkPtN,
     +            shift1THM, shift2THM, LTiRigidHN,tolerance,
     +            maxBisectionIter)
        dimension cm(*), hsv(*)
        real*8 lPevkPtN, LTiRigidHN, shift1THM, shift2THM, tolerance
        integer maxBisectionIter
        integer idxHsvL1HN     
        integer aniType, i0
        real*8 lceHN, l12HN
        real*8 argLeft, errLeft, argRight, errRight, delta
        real*8 lceOpt, argBest, errBest

c boundary conditions
        idxHsvL1HN              =7

c input values        
        l12HN = lceHN-LTiRigidHN 

        aniType = int(cm(28))

c use the bisection method to solve for l1HN s.t. f1HN-f2HN is as small
c as possible

        errLeft     = 0.
        errRight    = 0.
        delta       = 0.25
        i0          = 1

        argBest = 0.5*l12HN
        errBest = 
     +    calcTitinDistHDer(l12HN-argBest,shift2THN,lPevkPtN,0,
     +                      tolerance,aniType)
     +   -calcTitinProxHDer(      argBest,shift1THN, lPevkPtN,0,
     +                      tolerance,aniType)
              
        errBest=dabs(errBest)
        i0=1
        do while(i0.LE.maxBisectionIter)
          argLeft = argBest-delta*l12HN
          argRight= argBest+delta*l12HN

          errLeft =
     +      calcTitinDistHDer(l12HN-argLeft,shift2THN,lPevkPtN,0,
     +                        tolerance,aniType)
     +     -calcTitinProxHDer(      argLeft,shift1THN,lPevkPtN,0,
     +                        tolerance,aniType)
          errLeft =dabs(errLeft)

          errRight=
     +     calcTitinDistHDer(l12HN-argRight,shift2THN,lPevkPtN,0,
     +                       tolerance,aniType)
     +    -calcTitinProxHDer(      argRight,shift1THN,lPevkPtN,0, 
     +                       tolerance,aniType)
          errRight=dabs(errRight)

          if ((errRight.LT.errBest).AND.(errRight.LT.errLeft)) then
            errBest=errRight 
            argBest=argRight
          endif
          if ((errLeft.LT.errBest).AND.(errLeft.LT.errRight)) then
            errBest=errLeft 
            argBest=argLeft
          endif

          delta = delta*0.5
          i0=i0+1
        end do
        hsv(idxHsvL1HN)=argBest

c        print *, "updHsvInitialTitinState-end " 
c        print *, "errBest: ", errBest
c        print *, "argBest: ", argBest
       
        return
      end    
      
      
c############################################
c#    
c# Curve functions
c#
c#   All curves are quadratic Bezier splines that have been generated
c#   using this code
c#
c#    https://github.com/mjhmilla/FastMuscleCurves
c#
c#    Why quadratic Bezier splines? These curves can be evaluated
c#    without iteration (higher order curves require a root solve) and
c#    have desireable properties: the curves are convex, C1 continuous
c#    and its easy to make them follow a desired path.
c#
c#    To generate new curves:
c#    1. Clone https://github.com/mjhmilla/FastMuscleCurves
c#    2. Run main_createExplicitBezierSplineMuscleCurves.m
c#    3. See output/tables/FortranExport for directories
c#       of curves for feline and human muscle. Note that
c#
c#    QuadraticBezierCurvesZero
c#    QuadraticBezierCurvesOne
c#
c#    The 'Zero' and 'One' refers to the location of the titin actin
c#    bond. Here 'Zero' means that Q=0 and the titin-actin bond happens  
c#    at the most proximal end of the PEVK segment. Here 'One' means 
c#    that Q=1 and the titin-actin bond happens at the distal end of the
c#    PEVK segment.
c#    
c#    For details see Sec. 2 and Appendix B.3 of Millard et al. 2023
c#    https://doi.org/10.1101/2023.03.27.534347
c#
c############################################      
c############################################
c#    calcTitinDistHDer 
c############################################
      real*8 function calcTitinDistHDer(inputL2HN, inputL2HNShift,
     +    lPevkPtN,derivativeOrder, tolerance, aniType)
      
      real*8 inputL2HN,inputL2HNShift,tolerance,lPevkPtN,A,B,val,t1,t3
      real*8 argL2HN
      integer derivativeOrder, col, ncol, row, nrow, aniType
      logical useHuman, useFeline

c     Coefficients of the distal titin force length curve when
c     the most proximal point of PEVK bonds to actin            
      real*8, dimension(3,2)::xPts0 
      real*8, dimension(3,2)::yPts0 
      real*8, dimension(2)::xEnd0 
      real*8, dimension(2)::yEnd0 
      real*8, dimension(2)::dydxEnd0 
      real*8, dimension(2)::d2ydx2End0 

c     Coefficients of the distal titin force length curve when
c     the most distal point of PEVK bonds to actin            
      real*8, dimension(3,2)::xPts1 
      real*8, dimension(3,2)::yPts1 
      real*8, dimension(2)::xEnd1 
      real*8, dimension(2)::yEnd1 
      real*8, dimension(2)::dydxEnd1 
      real*8, dimension(2)::d2ydx2End1 

c     Coefficients of the distal titin force length curve when
c     the desired point of PEVK bonds to actin   
      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2,2)::dxPts 
      real*8, dimension(2,2)::dyPts 
      real*8, dimension(1,2)::d2xPts 
      real*8, dimension(1,2)::d2yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End             

      argL2HN=inputL2HN-inputL2HNShift

      nrow = 3
      ncol = 2
      A = 1.0-lPevkPtN
      B =     lPevkPtN

      useHuman=.FALSE.
      useFeline=.FALSE.
      select case (aniType)
            case (0)
                  useHuman=.TRUE.
            case (1)
                  useFeline=.TRUE.
            case default
                  useHuman=.TRUE.
      end select

c     Human   
      if(useHuman) then   
c       Distal titin curve when the attachment point is at the
c       very proximal end of the pevk segment        
        xPts0 = reshape((/
     +   2.958647229490e-02,1.274039654301e-01,1.599895588448e-01,
     +   1.599895588448e-01,1.926055490568e-01,2.903926453946e-01/),
     +   shape(xPts0))

        yPts0 = reshape((/
     +   4.585676623301e-04,4.586045901026e-04,1.252294593874e-01,
     +   1.252294593874e-01,2.501167040977e-01,1.000000000000e+00/),
     +   shape(yPts0))

        xEnd0 = reshape((/
     +   2.958647229490e-02,2.903926453946e-01/),
     +   shape(xEnd0))

        yEnd0 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd0))

        dydxEnd0 = reshape((/
     +   3.775170610959e-07,7.668530143400e+00/),
     +   shape(dydxEnd0))

        d2ydx2End0 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End0))

c       Proximal titin curve when the attachment point is at the
c       very distal end of the pevek segment        
        xPts1 = reshape((/
     +   5.229329491005e-03,2.251830860583e-02,2.827772469731e-02,
     +   2.827772469731e-02,3.404251334105e-02,5.132611990361e-02/),
     +   shape(xPts1))

        yPts1 = reshape((/
     +   4.585676623301e-04,4.586045901025e-04,1.252294593874e-01,
     +   1.252294593874e-01,2.501167040977e-01,1.000000000000e+00/),
     +   shape(yPts1))

        xEnd1 = reshape((/
     +   5.229329491005e-03,5.132611990361e-02/),
     +   shape(xEnd1))

        yEnd1 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd1))

        dydxEnd1 = reshape((/
     +   2.135913990088e-06,4.338696863921e+01/),
     +   shape(dydxEnd1))

        d2ydx2End1 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End1))

      endif 


c     Feline
      if(useFeline) then

        xPts0 = reshape((/
     +   3.109047159828e-02,9.393098254459e-02,1.148648188432e-01,
     +   1.148648188432e-01,1.358181820881e-01,1.986391660881e-01/),
     +   shape(xPts0))

        yPts0 = reshape((/
     +   4.585676623301e-04,4.585913856949e-04,1.252294527741e-01,
     +   1.252294527741e-01,2.501166996103e-01,1.000000000000e+00/),
     +   shape(yPts0))

        xEnd0 = reshape((/
     +   3.109047159828e-02,1.986391660881e-01/),
     +   shape(xEnd0))

        yEnd0 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd0))

        dydxEnd0 = reshape((/
     +   3.775170573815e-07,1.193682831185e+01/),
     +   shape(dydxEnd0))

        d2ydx2End0 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End0))


        xPts1 = reshape((/
     +   5.495157327227e-03,1.660204880945e-02,2.030204813431e-02,
     +   2.030204813431e-02,2.400549879447e-02,3.510893894140e-02/),
     +   shape(xPts1))

        yPts1 = reshape((/
     +   4.585676623301e-04,4.585913856951e-04,1.252294527741e-01,
     +   1.252294527741e-01,2.501166996103e-01,1.000000000000e+00/),
     +   shape(yPts1))

        xEnd1 = reshape((/
     +   5.495157327227e-03,3.510893894140e-02/),
     +   shape(xEnd1))

        yEnd1 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd1))

        dydxEnd1 = reshape((/
     +   2.135913986198e-06,6.753612308138e+01/),
     +   shape(dydxEnd1))

        d2ydx2End1 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End1))
         
      endif

      
c     Interpolate the control points
      col=1
      do while(col.LE.ncol)     
        row=1
        do while(row.LE.nrow)   
c          print *, row, col
          xPts(row,col) = xPts0(row,col)*A + xPts1(row,col)*B
          yPts(row,col) = yPts0(row,col)*A + yPts1(row,col)*B
          row=row+1
        end do
        col=col+1
      end do

c     Print to screen 
c      print *, 'lPevkPtN'
c      print *, lPevkPtN
      
c      print *, 'A'
c      print *, A
      
c      print *, 'B'
c      print *, B

c      print *, 'xPts0'  
c      print *,  xPts0 
      
c      print *, 'xPts1'  
c      print *,  xPts1  
            
c      print *, 'xPts'  
c      print *,  xPts  
      
c      print *, 'yPts0'  
c      print *,  yPts0  
            
c      print *, 'yPts1' 
c      print *,  yPts1 
            
c      print *, 'yPts'  
c      print *, yPts 
      
c      call exit(0)
c     Interpolate the ends
c     Interpolate the ends
      xEnd(1) = xEnd0(1)*A + xEnd1(1)*B 
      xEnd(2) = xEnd0(2)*A + xEnd1(2)*B
      
      yEnd(1) = yEnd0(1)*A + yEnd1(1)*B 
      yEnd(2) = yEnd0(2)*A + yEnd1(2)*B

c     Evaluate the differences of the ends:
c       The derivatives of the end points is NOT the interpolation
c       of the derivatives of curves 0 and 1 at the ends. 
      dxPts(1,1) = (xPts(2,1)   -xPts(1,1)   )*(real(nrow)-1.0)
      dxPts(2,1) = (xPts(3,1)   -xPts(2,1)   )*(real(nrow)-1.0)
      dxPts(1,2) = (xPts(2,ncol)-xPts(1,ncol))*(real(nrow)-1.0)
      dxPts(2,2) = (xPts(3,ncol)-xPts(2,ncol))*(real(nrow)-1.0)

      d2xPts(1,1) = (dxPts(2,1) -dxPts(1,1)  )*(real(nrow)-2.0)
      d2xPts(1,2) = (dxPts(2,2) -dxPts(1,2)  )*(real(nrow)-2.0)

      dyPts(1,1) = (yPts(2,1)   -yPts(1,1)   )*(real(nrow)-1.0)
      dyPts(2,1) = (yPts(3,1)   -yPts(2,1)   )*(real(nrow)-1.0)
      dyPts(1,2) = (yPts(2,ncol)-yPts(1,ncol))*(real(nrow)-1.0)
      dyPts(2,2) = (yPts(3,ncol)-yPts(2,ncol))*(real(nrow)-1.0)

      d2yPts(1,1) = (dyPts(2,1) -dyPts(1,1)  )*(real(nrow)-2.0)
      d2yPts(1,2) = (dyPts(2,2) -dyPts(1,2)  )*(real(nrow)-2.0)

c     Set the first and second derivatives of the end points
      dydxEnd(1) = dyPts(1,1)/dxPts(1,1)
      dydxEnd(2) = dyPts(2,2)/dxPts(2,2)

      t1 = 1.0/dxPts(1,1)
      t3 = dxPts(1,1)*dxPts(1,1)
      d2ydx2End(1) = (d2yPts(1,1)*t1 - dyPts(1,1)/t3*d2xPts(1,1))*t1

      t1 = 1.0/dxPts(2,2)
      t3 = dxPts(2,2)*dxPts(2,2)
      d2ydx2End(2) = (d2yPts(1,2)*t1 - dyPts(2,2)/t3*d2xPts(1,2))*t1


c     Now we interpolate the Bezier control points to arrive at the
c     curve that results when the attachment points are at a normalized
c     location lPevkPtN

c linear extrapolation
      if(argL2HN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcTitinDistHDer=dydxEnd(1)*(argL2HN-xEnd(1))+yEnd(1)
            case (1)
                calcTitinDistHDer=dydxEnd(1)
            case (2)
                calcTitinDistHDer=0.
            case default
                calcTitinDistHDer=-1.
        end select
c linear extrapolation
      elseif(argL2HN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcTitinDistHDer=dydxEnd(2)*(argL2HN-xEnd(2))+yEnd(2)
            case (1)
                calcTitinDistHDer=dydxEnd(2)
            case (2)
                calcTitinDistHDer=0.
            case default
                calcTitinDistHDer=-2.
        end select
         
c evaluate the Bezier curve
      else
        col=1
        do while (((argL2HN.LT.xPts(1,col)).OR.(argL2HN.GT.xPts(3,col))
     +             ).AND.( col.LE.ncol ))
          col=col+1
        end do
        if (col.LE.ncol) then
          if ((argL2HN.GE.xPts(1,col)).AND.(argL2HN.LE.xPts(3,col))
     +         ) then
               calcTitinDistHDer = calcQuadraticBezierCurveDer(argL2HN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
          else
c error case: should never occur                  
               calcTitinDistHDer = col+10
          endif
        else
c error case: should never occur            
          calcTitinDistHDer = col + 100
        endif
      endif

      return
      end 

c############################################
c#    calcTitinProximalHDer 
c############################################
      real*8 function calcTitinProxHDer(inputL1HN,inputL1HNShift,
     +      lPevkPtN,derivativeOrder, tolerance, aniType)
      
      real*8 inputL1HN,inputL1HNShift,tolerance,lPevkPtN,A,B,val,t1,t3
      real*8 argL1HN
      integer derivativeOrder, col, ncol, row, nrow, aniType
      logical useHuman, useFeline

c     Coefficients of the distal titin force length curve when
c     the most proximal point of PEVK bonds to actin            
      real*8, dimension(3,2)::xPts0 
      real*8, dimension(3,2)::yPts0 
      real*8, dimension(2)::xEnd0 
      real*8, dimension(2)::yEnd0 
      real*8, dimension(2)::dydxEnd0 
      real*8, dimension(2)::d2ydx2End0 

c     Coefficients of the distal titin force length curve when
c     the most distal point of PEVK bonds to actin            
      real*8, dimension(3,2)::xPts1 
      real*8, dimension(3,2)::yPts1 
      real*8, dimension(2)::xEnd1 
      real*8, dimension(2)::yEnd1 
      real*8, dimension(2)::dydxEnd1 
      real*8, dimension(2)::d2ydx2End1 

c     Coefficients of the distal titin force length curve when
c     the desired point of PEVK bonds to actin   
      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2,2)::dxPts 
      real*8, dimension(2,2)::dyPts 
      real*8, dimension(1,2)::d2xPts 
      real*8, dimension(1,2)::d2yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End

      argL1HN= inputL1HN-inputL1HNShift

      nrow = 3
      ncol = 2      
      A = 1.0-lPevkPtN
      B =     lPevkPtN

      useHuman=.FALSE.
      useFeline=.FALSE.
      select case (aniType)
            case (0)
                  useHuman=.TRUE.
            case (1)
                  useFeline=.TRUE.
            case default
                  useHuman=.TRUE.
      end select

c     Human   
      if(useHuman) then   
c       Proximal titin curve when the attachment point is at the
c       very proximal end of the pevk segment        
        xPts0 = reshape((/
     +   1.616338206311e-02,6.960204478165e-02,8.740387633713e-02,
     +   8.740387633713e-02,1.052223139632e-01,1.586443706112e-01/),
     +   shape(xPts0))

        yPts0 = reshape((/
     +   4.585676623301e-04,4.586045901023e-04,1.252294593874e-01,
     +   1.252294593874e-01,2.501167040977e-01,1.000000000000e+00/),
     +   shape(yPts0))

        xEnd0 = reshape((/
     +   1.616338206311e-02,1.586443706112e-01/),
     +   shape(xEnd0))

        yEnd0 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd0))

        dydxEnd0 = reshape((/
     +   6.910309952349e-07,1.403696044210e+01/),
     +   shape(dydxEnd0))

        d2ydx2End0 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End0))

   

c       Proximal titin curve when the attachment point is at the
c       very distal end of the pevek segment   
        xPts1 = reshape((/
     +   4.052052486700e-02,1.744877016059e-01,2.191157104846e-01,
     +   2.191157104846e-01,2.637853496790e-01,3.977108961022e-01/),
     +   shape(xPts1))

        yPts1 = reshape((/
     +   4.585676623301e-04,4.586045901024e-04,1.252294593874e-01,
     +   1.252294593874e-01,2.501167040977e-01,1.000000000000e+00/),
     +   shape(yPts1))

        xEnd1 = reshape((/
     +   4.052052486700e-02,3.977108961022e-01/),
     +   shape(xEnd1))

        yEnd1 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd1))

        dydxEnd1 = reshape((/
     +   2.756479106644e-07,5.599255078136e+00/),
     +   shape(dydxEnd1))

        d2ydx2End1 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End1))

      endif 


c     Feline
      if(useFeline) then

        xPts0 = reshape((/
     +   1.698503173870e-02,5.131542359285e-02,6.275178514243e-02,
     +   6.275178514243e-02,7.419881445564e-02,1.085185385461e-01/),
     +   shape(xPts0))

        yPts0 = reshape((/
     +   4.585676623301e-04,4.585913856951e-04,1.252294527741e-01,
     +   1.252294527741e-01,2.501166996103e-01,1.000000000000e+00/),
     +   shape(yPts0))

        xEnd0 = reshape((/
     +   1.698503173870e-02,1.085185385461e-01/),
     +   shape(xEnd0))

        yEnd0 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd0))

        dydxEnd0 = reshape((/
     +   6.910310028091e-07,2.184992217339e+01/),
     +   shape(dydxEnd0))

        d2ydx2End0 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End0))


        xPts1 = reshape((/
     +   4.258034600976e-02,1.286443573280e-01,1.573145558513e-01,
     +   1.573145558513e-01,1.860114977493e-01,2.720487656929e-01/),
     +   shape(xPts1))

        yPts1 = reshape((/
     +   4.585676623301e-04,4.585913856952e-04,1.252294527741e-01,
     +   1.252294527741e-01,2.501166996103e-01,1.000000000000e+00/),
     +   shape(yPts1))

        xEnd1 = reshape((/
     +   4.258034600976e-02,2.720487656929e-01/),
     +   shape(xEnd1))

        yEnd1 = reshape((/
     +   4.585676623301e-04,1.000000000000e+00/),
     +   shape(yEnd1))

        dydxEnd1 = reshape((/
     +   2.756479120967e-07,8.715796285877e+00/),
     +   shape(dydxEnd1))

        d2ydx2End1 = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End1))
         
      endif

c     Interpolate the control points
      col=1
      do while(col.LE.ncol)     
        row=1;
        do while(row.LE.nrow)   
          xPts(row,col) = xPts0(row,col)*A + xPts1(row,col)*B
          yPts(row,col) = yPts0(row,col)*A + yPts1(row,col)*B
          row=row+1
        end do
        col=col+1
      end do

c     Interpolate the ends
      xEnd(1) = xEnd0(1)*A + xEnd1(1)*B 
      xEnd(2) = xEnd0(2)*A + xEnd1(2)*B
      
      yEnd(1) = yEnd0(1)*A + yEnd1(1)*B 
      yEnd(2) = yEnd0(2)*A + yEnd1(2)*B

c     Evaluate the differences of the ends:
c       The derivatives of the end points is NOT the interpolation
c       of the derivatives of curves 0 and 1 at the ends. 
      dxPts(1,1) = (xPts(2,1)   -xPts(1,1)   )*(real(nrow)-1.0)
      dxPts(2,1) = (xPts(3,1)   -xPts(2,1)   )*(real(nrow)-1.0)
      dxPts(1,2) = (xPts(2,ncol)-xPts(1,ncol))*(real(nrow)-1.0)
      dxPts(2,2) = (xPts(3,ncol)-xPts(2,ncol))*(real(nrow)-1.0)

      d2xPts(1,1) = (dxPts(2,1) -dxPts(1,1)  )*(real(nrow)-2.0)
      d2xPts(1,2) = (dxPts(2,2) -dxPts(1,2)  )*(real(nrow)-2.0)

      dyPts(1,1) = (yPts(2,1)   -yPts(1,1)   )*(real(nrow)-1.0)
      dyPts(2,1) = (yPts(3,1)   -yPts(2,1)   )*(real(nrow)-1.0)
      dyPts(1,2) = (yPts(2,ncol)-yPts(1,ncol))*(real(nrow)-1.0)
      dyPts(2,2) = (yPts(3,ncol)-yPts(2,ncol))*(real(nrow)-1.0)

      d2yPts(1,1) = (dyPts(2,1) -dyPts(1,1)  )*(real(nrow)-2.0)
      d2yPts(1,2) = (dyPts(2,2) -dyPts(1,2)  )*(real(nrow)-2.0)

c     Set the first and second derivatives of the end points
      dydxEnd(1) = dyPts(1,1)/dxPts(1,1)
      dydxEnd(2) = dyPts(2,2)/dxPts(2,2)

      t1 = 1.0/dxPts(1,1)
      t3 = dxPts(1,1)*dxPts(1,1)
      d2ydx2End(1) = (d2yPts(1,1)*t1 - dyPts(1,1)/t3*d2xPts(1,1))*t1

      t1 = 1.0/dxPts(2,2)
      t3 = dxPts(2,2)*dxPts(2,2)
      d2ydx2End(2) = (d2yPts(1,2)*t1 - dyPts(2,2)/t3*d2xPts(1,2))*t1


c     Now we interpolate the Bezier control points to arrive at the
c     curve that results when the attachment points are at a normalized
c     location lPevkPtN
      

c linear extrapolation
      if(argL1HN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcTitinProxHDer=dydxEnd(1)*(argL1HN-xEnd(1))+yEnd(1)
            case (1)
                calcTitinProxHDer = dydxEnd(1)
            case (2)
                calcTitinProxHDer = 0.
            case default
                calcTitinProxHDer = -1.
        end select
c linear extrapolation
      elseif(argL1HN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcTitinProxHDer=dydxEnd(2)*(argL1HN-xEnd(2))+yEnd(2)
            case (1)
                calcTitinProxHDer = dydxEnd(2)
            case (2)
                calcTitinProxHDer = 0.
            case default
                calcTitinProxHDer = -2.
        end select
         
c evaluate the Bezier curve
      else
        col=1
        do while (((argL1HN.LT.xPts(1,col)).OR.(argL1HN.GT.xPts(3,col))
     +            ).AND.( col.LE.ncol ))
             col=col+1
        end do
        if (col.LE.ncol) then
           if ((argL1HN.GE.xPts(1,col)).AND.(argL1HN.LE.xPts(3,col))
     +        ) then
              calcTitinProxHDer = calcQuadraticBezierCurveDer(argL1HN, 
     +                       xPts(:,col),yPts(:,col),derivativeOrder,
     +                       tolerance) 
           else
c error case: should never occur                  
              calcTitinProxHDer = col+10
           endif
        else
c error case: should never occur            
          calcTitinProxHDer = col + 100
        endif
      endif

      return
      end 

c############################################
c#    Compressive-force length curve used to prevent
c#    the lce*cos(alpha) from approaching zero (which causes)
c#    a numerical singularity in the pennation model 
c#
c#    Note: This curve was derived assuming that lceATN is
c#          given by (lce*cos(alpha)) / (lceOpt*cos(alphaOpt))
c#          and was derived for a highly pennated model (human soleus)
c#
c#          In this implementation lceATN is given by 
c#          (lce*cos(alpha)) / (lceOpt) which will be smaller than
c#          (lce*cos(alpha)) / (lceOpt*cos(alphaOpt)) 
c#          since cos(alphaOpt)<=1
c#    
c#          And so this compressive curve will start to generate force
c#          when lce is longer than in the original implementation.
c#          Given that it begins to generate force at a normalized
c#          length of 0.08 this should be acceptable for any curve:
c#          the active-force-length curve goes to zero well before
c#          this point is hit.
c#
c############################################
      real*8 function calcCpNDer(argLceATN, derivativeOrder,tolerance)
      
      real*8 argLceATN, val, tolerance
      integer derivativeOrder, col, ncol

      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End 
      ncol = 2

        xPts = reshape((/
     +    3.931704800488e-07,1.342752085263e-02,4.216996546112e-02,
     +    4.216996546112e-02,5.455529017866e-02,8.433953775177e-02/),
     +    shape(xPts))

        yPts = reshape((/
     +    1.000000000000e+00,2.039800884390e-01,6.142710077956e-02,
     +    6.142710077956e-02,0.000000000000e+00,0.000000000000e+00/),
     +    shape(yPts))

        xEnd = reshape((/
     +    3.931704800488e-07,8.433953775177e-02/),
     +    shape(xEnd))

        yEnd = reshape((/
     +    1.000000000000e+00,0.000000000000e+00/),
     +    shape(yEnd))

        dydxEnd = reshape((/
     +    -5.928445237171e+01,0.000000000000e+00/),
     +    shape(dydxEnd))

        d2ydx2End = reshape((/
     +    0.000000000000e+00,0.000000000000e+00/),
     +    shape(d2ydx2End))


c linear extrapolation
      if(argLceATN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcCpNDer = dydxEnd(1)*(argLceATN-xEnd(1)) + yEnd(1)
            case (1)
                calcCpNDer = dydxEnd(1)
            case (2)
                calcCpNDer = 0.
            case default
                calcCpNDer = -1.
        end select
c linear extrapolation
      elseif(argLceATN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcCpNDer = dydxEnd(2)*(argLceATN-xEnd(2)) + yEnd(2)
            case (1)
                calcCpNDer = dydxEnd(2)
            case (2)
                calcCpNDer = 0.
            case default
                calcCpNDer = -2.
        end select
         
c evaluate the Bezier curve
      else
         col=1
         do while (((argLceATN.LT.xPts(1,col)).OR.(
     +               argLceATN.GT.xPts(3,col))).AND.(col.LE.ncol))
              col=col+1
         end do
         if (col.LE.ncol) then
            if ((argLceATN.GE.xPts(1,col)).AND.(
     +           argLceATN.LE.xPts(3,col))) then
               calcCpNDer = calcQuadraticBezierCurveDer(argLceATN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
            else
c error case: should never occur                  
               calcCpNDer = col+10
            endif
         else
c error case: should never occur            
            calcCpNDer = col + 100
         endif
      endif

      return
      end 

c############################################
c#    Tendon force-length curve that takes norm. strain
c#      (lt-ltSlk)/eIso as an argument 
c############################################
      real*8 function calcFtNDer(argEtN, derivativeOrder,tolerance)
      
      real*8 argEtN, val, tolerance
      integer derivativeOrder, col, ncol

      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End 
      ncol = 2

        xPts = reshape((/
     +   0.000000000000e+00,1.948154528865e-01,3.787878787879e-01,
     +   3.787878787879e-01,4.991804249556e-01,7.575757575758e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   1.220703125000e-04,1.220940936833e-04,1.882567514616e-01,
     +   1.882567514616e-01,3.113730843139e-01,6.666666666667e-01/),
     +   shape(yPts))

        xEnd = reshape((/
     +   0.000000000000e+00,7.575757575758e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220703125000e-04,6.666666666667e-01/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.220703128668e-07,1.375000000000e+00/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))

c linear extrapolation
      if(argEtN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcFtNDer = dydxEnd(1)*(argEtN-xEnd(1)) + yEnd(1)
            case (1)
                calcFtNDer = dydxEnd(1)
            case (2)
                calcFtNDer = 0.
            case default
                calcFtNDer = -1.
        end select
c linear extrapolation
      elseif(argEtN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcFtNDer = dydxEnd(2)*(argEtN-xEnd(2)) + yEnd(2)
            case (1)
                calcFtNDer = dydxEnd(2)
            case (2)
                calcFtNDer = 0.
            case default
                calcFtNDer = -2.
        end select
         
c evaluate the Bezier curve
      else
         col=1
         do while (((argEtN.LT.xPts(1,col)).OR.(
     +               argEtN.GT.xPts(3,col))).AND.(col.LE.ncol))
              col=col+1
         end do
         if (col.LE.ncol) then
            if ((argEtN.GE.xPts(1,col)).AND.(argEtN.LE.xPts(3,col))
     +         ) then
               calcFtNDer = calcQuadraticBezierCurveDer(argEtN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
            else
c error case: should never occur                  
               calcFtNDer = col+10
            endif
         else
c error case: should never occur            
            calcFtNDer = col + 100
         endif
      endif

      return
      end 

c############################################
c#    Tendon stiffness-length (approx.) curve that takes norm. strain
c#      (lt-ltSlk)/eIso as an argument 
c#
c#    This function is here to ensure that the tendon's damping 
c#    coefficient (which is evaluated using this function) is C1 
c#    continuous. If instead calcFtNDer() to evaluate the first
c#    derivative of ftN, the damping coefficient would only be 
c#    C0 continuous.
c############################################

      real*8 function calcKtNDer(argEtN, derivativeOrder,tolerance)
      
      real*8 argEtN, val, tolerance
      integer derivativeOrder, col, ncol

      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End 
      ncol = 2


        xPts = reshape((/
     +   0.000000000000e+00,1.388888888889e-01,3.787878787879e-01,
     +   3.787878787879e-01,6.186868686869e-01,7.575757575758e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   1.220703128668e-07,1.220703129690e-07,6.875000610352e-01,
     +   6.875000610352e-01,1.375000000000e+00,1.375000000000e+00/),
     +   shape(yPts))

        xEnd = reshape((/
     +   0.000000000000e+00,7.575757575758e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220703128668e-07,1.375000000000e+00/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.074462627669e-15,0.000000000000e+00/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))


c linear extrapolation
      if(argEtN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcKtNDer = dydxEnd(1)*(argEtN-xEnd(1)) + yEnd(1)
            case (1)
                calcKtNDer = dydxEnd(1)
            case (2)
                calcKtNDer = 0.
            case default
                calcKtNDer = -1.
        end select
c linear extrapolation
      elseif(argEtN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcKtNDer = dydxEnd(2)*(argEtN-xEnd(2)) + yEnd(2)
            case (1)
                calcKtNDer = dydxEnd(2)
            case (2)
                calcKtNDer = 0.
            case default
                calcKtNDer = -2.
        end select
         
c evaluate the Bezier curve
      else
         col=1
         do while (((argEtN.LT.xPts(1,col)).OR.(
     +               argEtN.GT.xPts(3,col))).AND.(col.LE.ncol))
              col=col+1
         end do
         if (col.LE.ncol) then
            if ((argEtN.GE.xPts(1,col)).AND.(argEtN.LE.xPts(3,col))
     +         ) then
               calcKtNDer = calcQuadraticBezierCurveDer(argEtN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
            else
c error case: should never occur                  
               calcKtNDer = col+10
            endif
         else
c error case: should never occur            
            calcKtNDer = col + 100
         endif
      endif

      return
      end 


c############################################
c#    calcEcmHDer 
c############################################
      real*8 function calcFecmHDer(inputLceHN,inputLceHNShift, 
     +                              derivativeOrder,tolerance,aniType)
      
      real*8 inputLceHN, argLceHN, inputLceHNShift, val, tolerance
      integer derivativeOrder, col, ncol, aniType
      logical useHuman, useFeline      

      real*8, dimension(3,2)::xPts 
      real*8, dimension(3,2)::yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End 
      ncol = 2

      argLceHN=inputLceHN-inputLceHNShift

      useHuman=.FALSE.
      useFeline=.FALSE.
      select case (aniType)
            case (0)
                  useHuman=.TRUE.
            case (1)
                  useFeline=.TRUE.
            case default
                  useHuman=.TRUE.
      end select      

      if(useHuman) then 
        xPts = reshape((/
     +   3.760250837158e-01,5.272702737882e-01,5.776686645397e-01,
     +   5.776686645397e-01,6.280920818896e-01,7.793122453636e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   2.441406250000e-04,2.441775500951e-04,1.251221333102e-01,
     +   1.251221333102e-01,2.500621003846e-01,1.000000000000e+00/),
     +   shape(yPts))

        xEnd = reshape((/
     +   3.760250837158e-01,7.793122453636e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   2.441406250000e-04,1.000000000000e+00/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   2.441406244650e-07,4.959245396824e+00/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))        
      endif


      if(useFeline) then
        xPts = reshape((/
     +   4.192095239555e-01,5.163733820512e-01,5.487506246042e-01,
     +   5.487506246042e-01,5.811439437381e-01,6.782917252528e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   2.441406250000e-04,2.441643466452e-04,1.251221267026e-01,
     +   1.251221267026e-01,2.500620959037e-01,1.000000000000e+00/),
     +   shape(yPts))

        xEnd = reshape((/
     +   4.192095239555e-01,6.782917252528e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   2.441406250000e-04,1.000000000000e+00/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   2.441406252256e-07,7.719557692445e+00/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))
      endif


c linear extrapolation
      if(argLceHN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcFecmHDer = dydxEnd(1)*(argLceHN-xEnd(1)) + yEnd(1)
            case (1)
                calcFecmHDer = dydxEnd(1)
            case (2)
                calcFecmHDer = 0.
            case default
                calcFecmHDer = -1.
        end select
c linear extrapolation
      elseif(argLceHN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcFecmHDer = dydxEnd(2)*(argLceHN-xEnd(2)) + yEnd(2)
            case (1)
                calcFecmHDer = dydxEnd(2)
            case (2)
                calcFecmHDer = 0.
            case default
                calcFecmHDer = -2.
        end select
         
c evaluate the Bezier curve
      else
         col=1
         do while (((argLceHN.LT.xPts(1,col)).OR.(
     +               argLceHN.GT.xPts(3,col))).AND.(col.LE.ncol))
              col=col+1
         end do
         if (col.LE.ncol) then
            if ((argLceHN.GE.xPts(1,col)).AND.(argLceHN.LE.xPts(3,col))
     +         ) then
               calcFecmHDer = calcQuadraticBezierCurveDer(argLceHN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
            else
c error case: should never occur                  
               calcFecmHDer = col+10
            endif
         else
c error case: should never occur            
            calcFecmHDer = col + 100
         endif
      endif

      return
      end 


c############################################
c#    calcFvDer 
c#      This is the calibrated version of the force-velocity curve
c############################################
      real*8 function calcFvDer(argVceNN, derivativeOrder,tolerance,
     +  aniType)
      
      real*8 argVceNN, val, tolerance
      integer derivativeOrder, col, ncol, aniType
      real*8, dimension(3,8)::xPts 
      real*8, dimension(3,8)::yPts 
      real*8, dimension(2)::xEnd 
      real*8, dimension(2)::yEnd 
      real*8, dimension(2)::dydxEnd 
      real*8, dimension(2)::d2ydx2End 
      logical useHuman, useFeline

      ncol = 8

      useHuman=.FALSE.
      useFeline=.FALSE.
      select case (aniType)
            case (0)
                  useHuman=.TRUE.
            case (1)
                  useFeline=.TRUE.
            case default
                  useHuman=.TRUE.
      end select      


      if(useHuman) then 
        xPts = reshape((/
     +   -1.150000000000e+00,-1.125874836960e+00,-1.035000000000e+00,
     +   -1.035000000000e+00,-9.945053837255e-01,-9.200000000000e-01,
     +   -9.200000000000e-01,-6.283724718097e-01,-4.600000000000e-01,
     +   -4.600000000000e-01,-1.445713104906e-01,0.000000000000e+00,
     +   0.000000000000e+00,2.515625000000e-03,2.875000000000e-03,
     +   2.875000000000e-03,3.234375000000e-03,5.750000000000e-03,
     +   5.750000000000e-03,3.211730745390e-02,6.037500000000e-02,
     +   6.037500000000e-02,7.157750171372e-02,1.150000000000e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   1.220703125000e-04,1.220728733402e-04,2.647864560052e-02,
     +   2.647864560052e-02,3.822336322098e-02,6.164647332405e-02,
     +   6.164647332405e-02,1.533287566750e-01,2.814978171246e-01,
     +   2.814978171246e-01,5.216095072290e-01,1.000000000000e+00,
     +   1.000000000000e+00,1.008324273186e+00,1.010702636953e+00,
     +   1.010702636953e+00,1.013081000721e+00,1.038053820279e+00,
     +   1.038053820279e+00,1.299804284388e+00,1.306630145974e+00,
     +   1.306630145974e+00,1.309336195876e+00,1.315000000000e+00/),
     +   shape(yPts))

        xEnd = reshape((/
     +   -1.150000000000e+00,1.150000000000e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220703125000e-04,1.315000000000e+00/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.061480979499e-07,1.304347826087e-01/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))
      endif

      if(useFeline) then
        xPts = reshape((/
     +   -1.150000000000e+00,-1.117799028773e+00,-1.035000000000e+00,
     +   -1.035000000000e+00,-9.994230184375e-01,-9.200000000000e-01,
     +   -9.200000000000e-01,-6.002466558748e-01,-4.600000000000e-01,
     +   -4.600000000000e-01,-8.720798709495e-02,0.000000000000e+00,
     +   0.000000000000e+00,2.515625000000e-03,2.875000000000e-03,
     +   2.875000000000e-03,3.234375000000e-03,5.750000000000e-03,
     +   5.750000000000e-03,1.091684730011e-02,6.037500000000e-02,
     +   6.037500000000e-02,7.367782838457e-02,1.150000000000e-01/),
     +   shape(xPts))

        yPts = reshape((/
     +   1.220703125000e-04,1.220737305718e-04,1.100152727842e-02,
     +   1.100152727842e-02,1.567619706645e-02,2.702702702703e-02,
     +   2.702702702703e-02,7.272493564212e-02,1.396385355947e-01,
     +   1.396385355947e-01,3.175027096917e-01,1.000000000000e+00,
     +   1.000000000000e+00,1.019687500000e+00,1.025312500000e+00,
     +   1.025312500000e+00,1.030937500000e+00,1.090000000000e+00,
     +   1.090000000000e+00,1.211308588785e+00,1.222394460147e+00,
     +   1.222394460147e+00,1.225376242445e+00,1.234000000000e+00/),
     +   shape(yPts))

        xEnd = reshape((/
     +   -1.150000000000e+00,1.150000000000e-01/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220703125000e-04,1.234000000000e+00/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.061480974145e-07,2.086956521739e-01/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))
      endif


c linear extrapolation
      if(argVceNN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcFvDer = dydxEnd(1)*(argVceNN-xEnd(1)) + yEnd(1)
            case (1)
                calcFvDer = dydxEnd(1)
            case (2)
                calcFvDer = 0.
            case default
                calcFvDer = -1.
        end select
c linear extrapolation
      elseif(argVceNN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcFvDer = dydxEnd(2)*(argVceNN-xEnd(2)) + yEnd(2)
            case (1)
                calcFvDer = dydxEnd(2)
            case (2)
                calcFvDer = 0.
            case default
                calcFvDer = -2.
        end select
         
c evaluate the Bezier curve
      else
         col=1
         do while ((( argVceNN.LT.xPts(1,col) ).OR.( 
     +                argVceNN.GT.xPts(3,col) )).AND.( col.LE.ncol ))
              col=col+1
         end do
         if (col.LE.ncol) then
            if ((argVceNN.GE.xPts(1,col)).AND.(
     +           argVceNN.LE.xPts(3,col))) then
               calcFvDer = calcQuadraticBezierCurveDer(argVceNN, 
     +                        xPts(:,col),yPts(:,col),derivativeOrder,
     +                        tolerance) 
            else
c error case: should never occur                  
               calcFvDer = col+10
            endif
         else
c error case: should never occur            
            calcFvDer = col + 100
         endif
      endif

      return
      end 


c############################################
c#    calcFalDer 
c#      These are the calibrated active-force length curves
c############################################
      real*8 function calcFalDer(argLceN, derivativeOrder,tolerance,
     +      aniType)
      
c      include 'memaia.inc'
c      common/bk07/n1,n2,n3,n4,n5,n6,n7,n8,n9
c      common/bk00/numnp,numpc,numlp,neq,ndof,nlcur
      real*8 argLceN, val, tolerance
      integer derivativeOrder, col, ncol, aniType
      logical useHuman, useFeline
      real*8, dimension(3,10) :: xPts
      real*8, dimension(3,10) :: yPts 
      real*8, dimension(2)  :: xEnd 
      real*8, dimension(2)  :: yEnd 
      real*8, dimension(2)  :: dydxEnd 
      real*8, dimension(2)  :: d2ydx2End
      ncol = 10

      useHuman=.FALSE.
      useFeline=.FALSE.
      select case (aniType)
            case (0)
                  useHuman=.TRUE.
            case (1)
                  useFeline=.TRUE.
            case default
                  useHuman=.TRUE.
      end select


c Human active force length curve 
c Rassier DE, MacIntosh BR, Herzog W. Length dependence of active force 
c production in skeletal muscle. Journal of applied physiology. 1999 
c May 1;86(5):1445-57.
      if(useHuman) then
        xPts = reshape((/
     +   2.954128440367e-01,3.973584555968e-01,4.201834862385e-01,
     +   4.201834862385e-01,4.679633697549e-01,5.449541284404e-01,
     +   5.449541284404e-01,6.219706055629e-01,6.706422018349e-01,
     +   6.706422018349e-01,6.937384996598e-01,7.963302752294e-01,
     +   7.963302752294e-01,8.751209098480e-01,8.981651376147e-01,
     +   8.981651376147e-01,9.691622110642e-01,1.000000000000e+00,
     +   1.000000000000e+00,1.030891927721e+00,1.146788990826e+00,
     +   1.146788990826e+00,1.181238306090e+00,1.293577981651e+00,
     +   1.293577981651e+00,1.477380938414e+00,1.510091743119e+00,
     +   1.510091743119e+00,1.563061498473e+00,1.726605504587e+00/),
     + shape(xPts))

        yPts = reshape((/
     +   1.220494821531e-04,1.220619266857e-04,2.927946285165e-03,
     +   2.927946285165e-03,8.801534361020e-03,3.589719262454e-01,
     +   3.589719262454e-01,7.092592910671e-01,7.538359825697e-01,
     +   7.538359825697e-01,7.749891113317e-01,8.589108910891e-01,
     +   8.589108910891e-01,9.233629414480e-01,9.421423693143e-01,
     +   9.421423693143e-01,1.000000000000e+00,1.000000000000e+00,
     +   1.000000000000e+00,1.000000000000e+00,7.796158750215e-01,
     +   7.796158750215e-01,7.141087603694e-01,5.000610351562e-01,
     +   5.000610351562e-01,1.498499046182e-01,9.268737006149e-02,
     +   9.268737006149e-02,1.220694460210e-04,1.220494821531e-04/),
     + shape(yPts))

        xEnd = reshape((/
     +   2.954128440367e-01,1.726605504587e+00/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220494821531e-04,1.220494821531e-04/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.220703118494e-07,-1.220703125000e-07/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))
      endif

c Feline active force length curve (Rassier et al.)
      if(useFeline) then
        xPts = reshape((/
     +   3.319587628866e-01,4.465162026809e-01,4.721649484536e-01,
     +   4.721649484536e-01,5.258557453947e-01,6.123711340206e-01,
     +   6.123711340206e-01,6.970928203288e-01,7.226804123711e-01,
     +   7.226804123711e-01,7.389588951085e-01,8.329896907216e-01,
     +   8.329896907216e-01,8.986146734074e-01,9.164948453608e-01,
     +   9.164948453608e-01,9.654477751308e-01,1.000000000000e+00,
     +   1.000000000000e+00,1.034713609500e+00,1.164948453608e+00,
     +   1.164948453608e+00,1.203659539833e+00,1.329896907216e+00,
     +   1.329896907216e+00,1.536438374095e+00,1.573195876289e+00,
     +   1.573195876289e+00,1.632718591068e+00,1.816494845361e+00/),
     +   shape(xPts))

        yPts = reshape((/
     +   1.220469052030e-04,1.220608892654e-04,3.315029567576e-03,
     +   3.315029567576e-03,9.998905436810e-03,4.084768767404e-01,
     +   4.084768767404e-01,7.986933020690e-01,8.258673199177e-01,
     +   8.258673199177e-01,8.431550654673e-01,9.084158415842e-01,
     +   9.084158415842e-01,9.539619552249e-01,9.662787284369e-01,
     +   9.662787284369e-01,1.000000000000e+00,1.000000000000e+00,
     +   1.000000000000e+00,1.000000000000e+00,7.796158750215e-01,
     +   7.796158750215e-01,7.141087603691e-01,5.000610351563e-01,
     +   5.000610351562e-01,1.498499046182e-01,9.268737002057e-02,
     +   9.268737002057e-02,1.220693388278e-04,1.220469052030e-04/),
     +   shape(yPts))

        xEnd = reshape((/
     +   3.319587628866e-01,1.816494845361e+00/),
     +   shape(xEnd))

        yEnd = reshape((/
     +   1.220469052030e-04,1.220469052030e-04/),
     +   shape(yEnd))

        dydxEnd = reshape((/
     +   1.220703125000e-07,-1.220703125000e-07/),
     +   shape(dydxEnd))

        d2ydx2End = reshape((/
     +   0.000000000000e+00,0.000000000000e+00/),
     +   shape(d2ydx2End))
      endif 



c linear extrapolation
      if(argLceN.LE.xEnd(1)) then
        select case(derivativeOrder)
            case (0)
                calcFalDer = dydxEnd(1)*(argLceN-xEnd(1)) + yEnd(1)
            case (1)
                calcFalDer = dydxEnd(1)
            case (2)
                calcFalDer = 0.
            case default
                calcFalDer = -1.
        end select
c linear extrapolation
      elseif(argLceN.GE.xEnd(2)) then
         select case(derivativeOrder)
            case (0)
                calcFalDer = dydxEnd(2)*(argLceN-xEnd(2)) + yEnd(2)
            case (1)
                calcFalDer = dydxEnd(2)
            case (2)
                calcFalDer = 0.
            case default
                calcFalDer = -2.
        end select
         
c evaluate the Bezier curve
      else
        col=1
        do while (((argLceN.LT.xPts(1,col)).OR.(argLceN.GT.xPts(3,col))
     +            ).AND.( col.LE.ncol ))
             col=col+1
        end do
        if (col.LE.ncol) then
           if ((argLceN.GE.xPts(1,col)).AND.(
     +          argLceN.LE.xPts(3,col))) then
              calcFalDer = calcQuadraticBezierCurveDer(argLceN, 
     +                       xPts(:,col),yPts(:,col),derivativeOrder,
     +                       tolerance) 
           else
c error case: should never occur                  
              calcFalDer = col+10
           endif
        else
c error case: should never occur            
           calcFalDer = col+100
        endif
      endif

      return
      end 

c############################################
c#    calcBezierCurveDer the derivative value of a 
c#                quadratic Bezier curve
c############################################
      real*8 function calcQuadraticBezierCurveDer(x, xPts, yPts,
     +      derivativeOrder,tolerance,numEpsilon)

c      include 'memaia.inc'
c      common/bk07/n1,n2,n3,n4,n5,n6,n7,n8,n9
c      common/bk00/numnp,numpc,numlp,neq,ndof,nlcur
c      integer rows, cols
      dimension xPts(3,1), yPts(3,1)
      integer derivativeOrder
      real*8 x, a, b, c, t0, u, v, u2, v2, x0, x1, x2, y0, y1, y2
      real*8 num, den
      real*8 du, dv, dv_du, d_u2_du, d_u2_du2, d_v2_du, d_v2_du2,
     +       d2_u2_du2, d2_v2_du2
      real*8 dy_du, dx_du, d2x_du2, d2y_du2
      real*8 tolerance, numEpsilon

c for now, for readability
      x0 = xPts(1,1)
      x1 = xPts(2,1)
      x2 = xPts(3,1)
      y0 = yPts(1,1)
      y1 = yPts(2,1)
      y2 = yPts(3,1)

c Solve for u where x = a u^2 + b u + c
      a     = x0-2.0*x1+x2;
      b     = -2.0*x0 +2.0*x1;
      c     = x0-x;
      t0    = sqrt(b*b-4.0*a*c)
      num   = (-b+t0)
      den   = 2.0*a
c This is a linear section     
      if ((a.GT.(-tolerance)).AND.(a.LT.(tolerance))) then 
            u = -c/b
      else 
c This is a quadratic section            
            t0    = sqrt(b*b-4.0*a*c)
            u     = (-b+t0)/(2.0*a)    
      endif
      
      if ((u.LT.(-tolerance)).OR.(u.GT.(1.+tolerance))) then
            u = (-b-t0)/(2.0*a)
      endif
c     clamp u within [0,1]            
      if (u.LT.0.) then
            u=0.0
      endif
      if (u.GT.1.0) then
            u=1.0
      endif
      u2 = u*u
      v = 1.0-u
      v2=v*v

c     evaluate the desired derivative of the curve
      select case (derivativeOrder)
         case (0) 
            calcQuadraticBezierCurveDer = v2*y0 + 2.0*u*v*y1 +u2*y2

         case (1)   
            du       = 1.0
            d_u2_du  = 2.0*u*du
            
            dv_du    =-1.0*du 
            d_v2_du  = 2.0*v*dv_du 

c           y = v2*y0 + 2*u*v*y1 + u2*y2
            dy_du= (  d_v2_du*y0 + (2.0*du*v + 2.0*u*dv_du)*y1  
     1       + d_u2_du*y2)

c           x = v2*x0 + 2*u*v*x1 + u2*x2
            dx_du= (  d_v2_du*x0 + (2.0*du*v + 2.0*u*dv_du)*x1  
     1       + d_u2_du*x2)

            calcQuadraticBezierCurveDer = dy_du/dx_du

         case (2)
            du          = 1.0
            d_u2_du     = 2.0*u*du
            d2_u2_du2   = 2.0*du*du;
            
            dv_du       =-1.0*du 
            d_v2_du     = 2.0*v*dv_du 
            d2_v2_du2   = 2.0*dv_du*dv_du;

c           y = v2*y0 + 2*u*v*y1 + u2*y2;
            dy_du    = (  d_v2_du*y0 + (2.0*du*v + 2.0*u*dv_du)*y1  
     1       + d_u2_du*y2)

            d2y_du2  = (  d2_v2_du2*y0 + (4.0*du*dv_du        )*y1  
     1       + d2_u2_du2*y2)

c           x = v2*x0 + 2*u*v*x1 + u2*x2;
            dx_du= (  d_v2_du*x0 + (2.0*du*v + 2.0*u*dv_du)*x1  
     1       + d_u2_du*x2)

            d2x_du2  = (  d2_v2_du2*x0 + (4.0*du*dv_du        )*x1  
     1         +d2_u2_du2*x2)

            calcQuadraticBezierCurveDer=((d2y_du2*dx_du-dy_du*d2x_du2)
     1          /(dx_du*dx_du))*(1.0/dx_du)
         case default
            calcQuadraticBezierCurveDer=-1
      end select 

      return
      end
c END OF SUBROUTINE OUTPUT
