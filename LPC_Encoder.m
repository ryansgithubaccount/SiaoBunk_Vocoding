% STFT Pitch Detection
clear;

[yin,Fs] = audioread("CHN.wav");



W = 4096;
OL = 2012;
f = W-OL;
frames = fix((length(yin)-OL)/(W-OL));
lpclen = fix((frames/24));
a = zeros(frames,lpclen);
g = zeros(1,frames);

y = lowpass(yin(:,1),400,Fs,'ImpulseResponse','iir','Steepness',0.99);
gain = movmean(abs(yin),256);
S = abs(spectrogram(y(:,1),kaiser(W,18),OL,W,Fs,'MinThreshold',-75,'yaxis')).^6;
[FT , P] = islocalmax(S);
pitch = zeros(1,(size(S,2)));
VUV = zeros(1,(size(S,2)));

for n = 1:(size(S,2))
    m = 1;
    while(P(m,n)<500 && m<=(size(S,1)-2))
        m = m+1;
    end
    pitch(1,n) = m*10;
    if(m>=500)
        pitch(1,n) = 0;
        VUV(1,n) = 1;
    end
end

for q = 1:frames
    [a(q,:),g(1,q)] = (lpc( yin( ((((q-1)*f)+1):((q*f))) ,1 ) , (lpclen-1)));
end

output = zeros((size(a,2)+4),size(a,1));

output(1:size(a,2),:) = ((a').*10^4);
output((size(a,2)+1),:) = (g.*10^10);
output((size(a,2)+2),:) = pitch;
output((size(a,2)+3),:) = VUV;
output((size(a,2)+4),1) = size(yin,1);
output((size(a,2)+4),2) = Fs;

output = cast(output,'int32');

csvwrite("LPCout_cast2.csv",output);
