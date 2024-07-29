%%
% SPDX-FileCopyrightText: 2024 Matthew Millard <millard.matthew@gmail.com>
%
% SPDX-License-Identifier: MIT
%
%%

clc;
close all;
clear all;


cm      = zeros(25,1);
bufferSize = 100;
hsv     = ones((150+2*bufferSize+4),1).*-10;
no_hsvs = size(hsv,1);


cm(22,1) = 0.0001;%0.025; %buffer delay

dt = 0.01/(bufferSize*2);
tt = [0:dt:(0.01*5)]';
if(cm(22,1)>0)
    dt = cm(22,1)/(bufferSize*2);
    tt = [0:dt:(cm(22,1)*5)]';
end
y  = sin(tt.*(4*pi/max(tt)));

yD     = zeros(size(y));
yDring = zeros(size(y));
yDerr= zeros(size(y));

idxHsvLceATN          = 6;
idxHsvLceATNDelay     = 60;

countInit   = zeros(size(y));
countUpdate = zeros(size(y));
countSeek   = zeros(size(y));

for i=1:1:size(y,1)
    yD(i,1)     = sin( (tt(i,1)-cm(22,1))*(4*pi/max(tt)) );
    hsv(idxHsvLceATN,1)=y(i,1);    
    [hsv,stats] = applyRingBuffer(cm,hsv,i,0,tt(i,1),no_hsvs,yD(i,1));

    if(tt(i,1)>cm(22,1))        
        yDring(i,1) = hsv(idxHsvLceATNDelay,1);
        yDerr(i,1) = yDring(i,1)-yD(i,1);
    end

    countInit(i,1)   = stats.flag_init;
    countUpdate(i,1) = stats.flag_update;
    countSeek(i,1)   = stats.count_seek;
end

figStats=figure;
subplot(2,3,1);
    plot(tt,countInit);
    xlabel('Iteration');
    ylabel('Count');
    title('Initialization Calls')
    box off;
subplot(2,3,2);
    plot(tt,countUpdate);
    xlabel('Iteration');
    ylabel('Count');
    title('Update Calls')
    box off;
    
subplot(2,3,3);
    plot(tt,countSeek);
    xlabel('Iteration');
    ylabel('Count');
    title('Seek Loops')
    box off;

subplot(2,3,4);
    plot(tt,y,'k','DisplayName', 'y(t)');
    hold on
    plot(tt,yD,'b','DisplayName', 'y(t-d)');
    hold on;
    legend;
    legend boxoff;
    xlabel('Time (s)');
    ylabel('Magnitude');
    title('Signal and Delay');
    box off;

subplot(2,3,5);
    plot(tt,yD,'b','DisplayName', 'y(t-d)');
    hold on
    plot(tt,yDring,'--r','DisplayName', 'r(y(t),d)');
    hold on;
    legend;
    legend boxoff;        
    xlabel('Time (s)');
    ylabel('Magnitude');
    title('Delayed Signal and Ring Buffer Signal');
    box off;

subplot(2,3,6);
    plot(tt,yDerr,'--r','DisplayName', 'r(y(t),d)-y(t-d)');
    hold on
    legend;
    legend boxoff;        
    xlabel('Time (s)');
    ylabel('Abs. Error');
    title('Ring Buffer Error');
    box off;



