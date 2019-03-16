clear;
M = csvread('LPCout_ahhhy2.csv');
a = (M(1:(size(M,1)-4),:)./10^4);  %-3 : the last pitch are g, pitch and vuv
g = (M((size(M,1)-3),:).*10^10);
pitch = M((size(M,1)-2),:);
vuv = M((size(M,1))-1,:);
siglen = M((size(M,1)),1);
Fs = M((size(M,1)),2);

yout = zeros(siglen,1);

framelen = fix((siglen/(size(M,1)-3))/32);

L = 2048/44100; %2048 is the number of the samples % 44100 is the sampling frequency
t = [1 : 1 : (framelen)];
T = 0.001; % 1 kHz

frame = size(M,2);

for k = 1:frame
    
if (vuv(1,k) == 1)
    y = 700.*g(1,k).*rand((framelen),1);

else
    y = 700.*g(1,k).*sinc(500.*cos(((2.*3.14159).*t).*pitch(1,k).*13));
end
h = filter(1 , a(:,k) , y);

yout((((framelen)*(k-1))+1):(((framelen)*k)),1) = h;
disp(k);

end

audiowrite('HYT_p.wav',(yout),Fs);
