

function varargout = main(varargin)

% MAIN MATLAB code for main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main

% Last Modified by GUIDE v2.5 16-Mar-2019 22:53:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Choose default command line output for main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 

% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in pushbutton1.
%function pushbutton1_Callback(hObject, eventdata, handles)

%A = csvread("synthsized.csv");
%plot(yout);
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%end
function [h1 h2] = decoder(name)

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
disp(frame);
disp(framelen);

end

audiowrite('HYT_p.wav',(yout),Fs);
%csvwrite("synthsized.csv",yout);
h1 = yout;
h2 = 44100;

end


function [audio sr] = LPC_Encoder(name)

[audio sr] = enc_stft(name);

%{
[yin,Fs] = audioread(name);
%c = csvread('PE_BPF.csv');

W = 4096;
OL = 4000;
f = W-OL;
frames = fix((length(yin)-OL)/(W-OL));
%lpclen = fix((frames/300));
lpclen = 8;
a = zeros(frames,lpclen);
g = zeros(1,frames);

%win = ((f));

y = lowpass(yin(:,1),100,Fs,'ImpulseResponse','fir','Steepness',0.75);
gain = movmean(abs(yin),256);
S = abs(spectrogram((y(:,1)),kaiser(W,18),OL,W,Fs,'MinThreshold',-75,'yaxis')).^6;
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

ylpc0 = lowpass(yin(:,1),3200,Fs,'ImpulseResponse','iir','Steepness',0.7);
ylpc0 = highpass(ylpc0,500,Fs,'ImpulseResponse','iir','Steepness',0.7);
%ylpc0 = yin(:,1);

%ylpc0 = filter(c , 1 , yin(:,1));

for q = 1:frames
    [a(q,:),g(1,q)] = (lpc( (ylpc0( ((((q-1)*f)+1):((q*f))) ,1 )) , (lpclen-1)));
end

output = zeros((size(a,2)+4),size(a,1));

output(1:size(a,2),:) = ((a').*(10^4));
output((size(a,2)+1),:) = (log10(g).*10^3);
output((size(a,2)+2),:) = pitch;
output((size(a,2)+3),:) = VUV;
output((size(a,2)+4),1) = size(yin,1);
output((size(a,2)+4),2) = Fs;

output = cast(output,'int32');

csvwrite("GUIData.csv",output);
y1 = yin(:,1);
y2 = Fs;
%}
t = [0:(1/sr):((size(audio,1)/sr)-(1/sr))];
    plot(t,audio);
end

function [audio sr] = LPC_Encoder_cepstrum(name)

[audio sr] = enc_ceps(name);

%{
[yin,Fs] = audioread(name);
W = 4096;
OL = 3000;
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
ylpc0 = highpass(ylpc0,200,Fs,'ImpulseResponse','iir','Steepness',0.9999);
%ylpc0 = yin(:,1);

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

csvwrite("GUIData.csv",output);


k1 = yin(:,1);
k2 = Fs;
%}
t = [0:(1/sr):((size(audio,1)/sr)-(1/sr))];
    plot(t,audio);

end

% --- Executes on button press in pushbutton2.
%function pushbutton2_Callback(hObject, eventdata, handles)

%axes(handles.axes1);
%M = csvread("LPCout_cast2.csv");
%x = [1:1:size(M,2)];
%plot(x,M((size(M,1)-1),:));


% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%end


%function edit1_Callback(hObject, eventdata, handles)

% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
%end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)


% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


%function edit2_Callback(hObject, eventdata, handles)
%M = csvread(LPCout_cast2.csv');
%csvimport('LPCout_cast2.csv');
%fid=fopen('LPCout_cast2.csv','r');
%A = fscanf(fid, '%f,');
%fclose(filenamecsv);

% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
%end

% --- Executes during object creation, after setting all properties.
%function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

%if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%    set(hObject,'BackgroundColor','white');

 
%end
%end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1

end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
radiobutton2_Callback;
end


% --- Executes on button press in pushbutton4.
%function pushbutton4_Callback(hObject, eventdata, handles)
%plotter = LPC_Encoder(filename);
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes2);
[filename pathname] = uigetfile({'*.csv'}, 'File Selector');
[audio sr] = decode(filename);
t = [0:(1/sr):((size(audio,1)/sr)-(1/sr))];
plot(t,audio);
ylim([-1 1]);
end


% --- Executes on selection change in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
[filename pathname] = uigetfile({'*.wav'}, 'File Selector');
sr = 44100;

  contents = get(handles.radiobutton2,'string'); 
  popupmenu4value = contents{get(handles.radiobutton2,'Value')};
  switch popupmenu4value
      case 'A'
          LPC_Encoder_cepstrum(filename);
      case 'B'
          LPC_Encoder(filename);
          
  
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns radiobutton2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from radiobutton2
  end
    
end
