function Cepstrum
f = figure;

set(f, 'units', 'normalized', 'position', [1 1 1 1])
loadfilename = 0;
%------------------------------------------
% Plot 1
% [x1 y1 x2 y2]

ax1 = axes(f);
ax1.Units = 'pixels';
ax1.Position = [150 375 450 150]
ax1.ActivePositionProperty = 'outerposition';


% Spectrogram
ax2 = axes(f);
ax2.Units = 'pixels';
ax2.Position = [700 350 500 200]

ax3 = axes(f);
ax3.Units = 'pixels';
ax3.Position = [150 125 450 150]

% Spectrogram
ax4 = axes(f);
ax4.Units = 'pixels';
ax4.Position = [700 100 500 200]

%------------------------------------------
% Encoder Selection Button
c = uicontrol(f,'Style','popupmenu');
c.Position = [5 275 100 200];
c.String = {'Select One', 'STFT      ','Cepstrum  '};
c.Callback = @loadbutton;

%------------------------------------------

t = uicontrol(f,'Style','text',...
    'String','Select a data set.',...
    'Position',[5 500 130 30]);
t.String = 'Bit Rate Slider';

%------------------------------------------
% Decoder Selection Button
c1 = uicontrol(f,'Style','popupmenu');
c1.Position = [5 25 100 200];
c1.String = {'None  ', 'Female','Male  '};

%------------------------------------------
% Decoder button
c2 = uicontrol;
c2.Position = [5 175 100 20];
c2.String = 'Decode File';
c2.Callback = @Decodebutton;

%------------------------------------------
%p = uipanel(f);
c3 = uicontrol(f,'Style','slider');
c3.Position = [10 500 100 10];
c3.Value = 0.9;

%------------------------------------------

% Play1 button
c4 = uicontrol;
c4.Position = [5 150 100 20];
c4.String = 'Play LPC';
c4.Callback = @playbutton;

%------------------------------------------

% Play2 button
c4 = uicontrol;
c4.Position = [5 425 100 20];
c4.String = 'Play Input';
c4.Callback = @playbutton2;

%------------------------------------------
    function Decodebutton(src,event)
        %[filename pathname] = uigetfile({'*.csv'}, 'File Selector');
        val = c1.Value;
        str = c1.String;
        str{val};
        if(str{val} == 'None  ')
            pit = 1;
        elseif(str{val} == 'Female')
            pit = 5;
        elseif(str{val} == 'Male  ')
            pit = 0.2;
        end
        
        [y Fs] = decode('GUIData.csv',pit);
        
        disp(Fs);
        x = [0:1/Fs:((size(y,1)/Fs)-(1/Fs))];
        axes(ax3); 
        plot(x,y);
        xlabel('Time (s)');
        ylim([-0.8 0.8]);
        axes(ax4);
        spectrogram(y,kaiser(4096,18),3500,4096,'Minthreshold',-100,Fs,'yaxis');
        
    end

    function loadbutton(src,event)
        val = c.Value;
        str = c.String;
        str{val};
        disp(['Selection: ' str{val}]);
        if(str{val} == 'Select One')
            return;
        end
        
        [filename pathname] = uigetfile({'*.wav'}, 'File Selector');
        loadfilename = filename;
        disp(c3.Value);
        if(str{val} == 'Cepstrum  ')
            [y Fs] = enc_ceps(filename , (c3.Value));
        elseif(str{val} == 'STFT      ')
            [y Fs] = enc_stft(filename , (c3.Value));
        end

        %disp(Fs);
        x = [0:1/Fs:((size(y,1)/Fs)-(1/Fs))];
        axes(ax1); 
        plot(x,y);
        xlabel('Time (s)');
        ylim([-0.8 0.8]);
        axes(ax2);
        spectrogram(y,kaiser(4096,18),3500,4096,'Minthreshold',-100,Fs,'yaxis');
    end
    function playbutton(src,event)
         %disp('HERE');

         [y,Fs] = audioread('GUIout.wav');
         audio = audioplayer(y,Fs);
         play(audio);
         
         pause((size(y,1)/Fs));

    end

    function playbutton2(src,event)
         %disp('HERE');

         [y,Fs] = audioread(loadfilename);
         audio = audioplayer(y,Fs);
         play(audio);
         
         pause((size(y,1)/Fs));

    end


end