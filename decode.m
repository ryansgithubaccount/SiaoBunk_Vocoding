function [sout sf] = decode(name)
M = csvread(name);
a = (M(1:(size(M,1)-4),:)./(10^4));  %-3 : the last pitch are g, pitch and vuv
g = (10.^(M((size(M,1)-3),:)/1000));
pitch = M((size(M,1)-2),:);
vuv = M((size(M,1))-1,:);
siglen = M((size(M,1)),1);
Fs = M((size(M,1)),2);
LPClen = (size(M,1)-4);

yout = zeros(siglen,1);

framelen = fix(((siglen/(size(M,1)-3))/(1.05*(size(M,2))/size(M,1))));

%L = 2048/44100; %2048 is the number of the samples % 44100 is the sampling frequency
t = [1 : 1 : (framelen)];
T = 0.001; % 1 kHz

frame = size(M,2);

for k = 1:frame
    
if (vuv(1,k) == 1)
    y = 1.*g(1,k).*rand((framelen),1);

else
    y = 1.*g(1,k).*sinc(400.*cos(((2.*3.14159).*t).*pitch(1,k).*13));
end
h = 9000.*filter(1 , a(:,k) , y);
%h = filter(1 , a(:,k) , h0);

yout((((framelen)*(k-1))+1):(((framelen)*k)),1) = h;
disp(k);

end


%yout2 = lowpass(yout,500,Fs,'ImpulseResponse','fir','Steepness',0.5);
%yout2 = highpass(yout,100,Fs,'ImpulseResponse','fir','Steepness',0.5);

sout = yout;
sf = Fs;

audiowrite('Cast2_PE.wav',(yout),Fs);
