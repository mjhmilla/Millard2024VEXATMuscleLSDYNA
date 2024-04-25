function [hsv, stats] = applyRingBuffer(cm,hsv,ncycle,idpart,tt,no_hsvs,trueDelayedValue)

idxHsvLceATN          = 6;
idxHsvLceATNDelay     = 60;
idxHsvBufSize         =50;
idxHsvBufEleDelay     =51;
idxHsvBufValStart     =52;   
idxHsvBufIdx          =53;
idxHsvBufDelayIdx     =54;
idxHsvBufTimeStart    =55;     

idxCmBufDelay = 22;


flag_init = 0;
flag_update = 0;
count_seek = 0;

%  Initialize the buffer     
if(hsv(idxHsvBufValStart,1) ~= 150)  
  hsv(idxHsvBufValStart,1) = 150;
  sizeBuffer = floor((no_hsvs-hsv(idxHsvBufValStart,1)-4)/2);

  hsv(idxHsvBufTimeStart,1) = hsv(idxHsvBufValStart,1)+sizeBuffer+2;
  hsv(idxHsvBufSize,1)      = sizeBuffer;

  hsv(idxHsvBufEleDelay,1)  = cm(idxCmBufDelay)*1.1 / sizeBuffer;

  for i0 =  1:1:sizeBuffer
      i1 = i0+hsv(idxHsvBufValStart,1)-1;
      hsv(i1,1)=0;
      i2 = i0+hsv(idxHsvBufTimeStart,1)-1;
      hsv(i2,1)=0;
  end 

  hsv(idxHsvBufIdx,1)       = 0;
  hsv(idxHsvBufDelayIdx,1)  = 1 ;


  idxTime      = hsv(idxHsvBufIdx,1)+hsv(idxHsvBufTimeStart,1);
  hsv(idxTime,1)=tt;

  idxValue       = hsv(idxHsvBufIdx,1)+hsv(idxHsvBufValStart,1);
  hsv(idxValue,1)= hsv(idxHsvLceATN);
  flag_init = 1;
end

%  Update the buffer if enough time has passed
idxTime = hsv(idxHsvBufTimeStart,1)+hsv(idxHsvBufIdx,1);
timeLastRecorded = hsv(idxTime,1);

if(tt >= (timeLastRecorded+hsv(idxHsvBufEleDelay,1)))
  hsv(idxHsvBufIdx,1) = mod(      hsv(idxHsvBufIdx,1)+1, ...
                                  hsv(idxHsvBufSize,1));
  idxTime        = hsv(idxHsvBufTimeStart,1) + hsv(idxHsvBufIdx,1);   
  hsv(idxTime,1) = tt;

  idxValue      = hsv(idxHsvBufValStart,1)+hsv(idxHsvBufIdx,1);   
  hsv(idxValue,1) = hsv(idxHsvLceATN);

  flag_debug=0;
  if(flag_debug==1)
    fprintf('%i\ttime start\n%i\ttime current\n%i\ttime past\n',...
        hsv(idxHsvBufTimeStart,1),idxTime,idxTimeDelay);
    fprintf('  %i\tvalue start\n  %i\tvalue current\n  %i\tvalue past\n',...
        hsv(idxHsvBufValStart,1),idxValue,idxValueDelay);  
    here=1;
  end
  flag_update=1;
end


if(tt >= cm(idxCmBufDelay))
    i=0;
    flag_found=0;
    ttDelay=tt-cm(idxCmBufDelay);
    while i < hsv(idxHsvBufSize,1) && flag_found==0
       
        idxTime0 = hsv(idxHsvBufTimeStart,1) ...
             + hsv(idxHsvBufDelayIdx,1);
        idxTime1 = hsv(idxHsvBufTimeStart,1) ...
             + mod( hsv(idxHsvBufDelayIdx,1)+1,hsv(idxHsvBufSize,1));

        if( ttDelay >= hsv(idxTime0,1) && ttDelay < hsv(idxTime1,1))
            flag_found = 1;
        else
            i=i+1; 
            hsv(idxHsvBufDelayIdx,1) = ...
              mod( hsv(idxHsvBufDelayIdx,1)+1,hsv(idxHsvBufSize,1));            
        end
        count_seek = count_seek+1;
    end
    
    idxVal0     = hsv(idxHsvBufValStart,1)+hsv(idxHsvBufDelayIdx,1);
    idxVal1     = hsv(idxHsvBufValStart,1)...
               +mod( hsv(idxHsvBufDelayIdx,1)+1,hsv(idxHsvBufSize,1));
    
    n = (ttDelay-hsv(idxTime0,1))/ ...
        ( hsv(idxTime1,1)-hsv(idxTime0,1));
    
    hsv(idxHsvLceATNDelay,1) = hsv(idxVal0,1) ...
        + n*(hsv(idxVal1,1)-hsv(idxVal0,1));

end

stats = struct('flag_init',flag_init,'flag_update',flag_update,'count_seek',count_seek);
