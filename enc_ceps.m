% STFT Pitch Detection
function [yout Fs] = enc_ceps(name,br)

[yin,Fs] = audioread(name);


W = 4096;
OL = fix(4000.*(1-br))+1;
if(mod(OL,2))
    OL = OL + 1;
end
disp(br);
disp(OL);

f = W-OL;
frames = fix((length(yin)-OL)/(W-OL));
%lpclen = fix((frames/300));
lpclen = 24;
a = zeros(frames,lpclen);
g = zeros(1,frames);

%win = ((f));
w = (kaiser(W,12));

y = lowpass(yin(:,1),300,Fs,'ImpulseResponse','fir','Steepness',0.9999);
gain = movmean(abs(yin),256);
y = (y./gain);

pitch = zeros(frames,1);
VUV = zeros(1,frames);

for n = 1:frames
    
    ysam(:,1) = (y(((((n-1)*(W-OL)))+1):(((n-1)*(W-OL))+W),1)).*w;
    
    yf = real(ifft((fft(ysam,W)).^2,W));
    [TF P] = islocalmax(yf);
    flag = 0;
    for q = 1:((W/2))
        if((P(q,1)>=0.1) & (flag == 0))
            q1 = q;
            flag = 1;
            continue;
        end
        if((P(q,1)>=0.1) & (flag == 1))
            pitch(n,1) = 47000./(q-q1);
            if(pitch(n,1)>=450)
                pitch(n,1) = (pitch(n,1)/2);
            end
            if(pitch(n,1) <=10)
                VUV(1,n) = 1;
            end
            flag = 0;
            break;
        end 
    end
end

ylpc0 = lowpass(yin(:,1),3500,Fs,'ImpulseResponse','iir','Steepness',0.7);
%ylpc0 = highpass(ylpc0,200,Fs,'ImpulseResponse','iir','Steepness',0.9999);
ylpc0 = yin(:,1);

for q = 1:frames
    [a(q,:),g(1,q)] = (lpc( (ylpc0( ((((q-1)*f)+1):((q*f))) ,1 )) , (lpclen-1)));
end

output = zeros((size(a,2)+4),size(a,1));

output(1:size(a,2),:) = ((a').*(10^4));
output((size(a,2)+1),:) = (log10(g).*10^3);
output((size(a,2)+2),:) = pitch';
output((size(a,2)+3),:) = VUV;
output((size(a,2)+4),1) = size(yin,1);
output((size(a,2)+4),2) = Fs;

%output = cast(output,'int32');

yout = yin(:,1);

csvwrite("GUIData.csv",output);
