function Stim = soundInit(Stim, Info)
    soundAmp = 0.2; % Sound amplitude. Range 0 to 1.

    freq_low = Stim.toneFreq(1);
    freq_high = Stim.toneFreq(2);

    stimDur= Info.taskparam.stimDur;       % Stimulus duration (seconds), 0.3s
    sampleFreq = Stim.samplingFreq;     % Sampling frequency (Hz), 44100
    scalingFact = [1 1];

    Stim.tone_low = generateTone(freq_low, stimDur, sampleFreq, fadeDur);
    Stim.tone_high = generateTone(freq_high, stimDur, sampleFreq, fadeDur); % Amplitude scaling
    
    soundStimMatrix = [
        1 freq_low scalingFact(1)*soundAmp stimDur50
        2 freq_low scalingFact(1)*soundAmp*0.3163 stimDur50
        3 freq_low scalingFact(1)*soundAmp*0.1 stimDur50
        4 freq_low scalingFact(1)*soundAmp*0.03163 stimDur50
        
        5 freq_high scalingFact(2)*soundAmp stimDur50
        6 freq_high scalingFact(2)*soundAmp*0.3163 stimDur50
        7 freq_high scalingFact(2)*soundAmp*0.1 stimDur50
        8 freq_high scalingFact(2)*soundAmp*0.03163 stimDur50
        ]; % column 1 is index, 2 is freq, 3: amp, 4: dur; 5: SNR

    nSound = size(soundStimMatrix,1);
    
    for i = 1:nSound
        f = soundStimMatrix(i,2);
        a = soundStimMatrix(i,3);
        d = soundStimMatrix(i,4);
        SNR = soundStimMatrix(i,5);;
        t = linspace(0,d,soundDriverFreq*d);
        s = a*sin(2*pi*f*t);
        s = s + randn(size(s))*std(s)/db2mag(SNR);
        allSound{i} = [s; s];
    end
    
    %%% INITIALIZE SOUND DRIVE + CREATE BUFFER FOR SOUNDS %%%
    InitializePsychSound;
    PsychPortAudio('Close');
    snd.pahandle = PsychPortAudio('Open', [], [], 1, soundDriverFreq, 2);
    PsychPortAudio('RunMode', snd.pahandle, 1);
    for i = 1:nSound
        snd.buffers(i) = PsychPortAudio('CreateBuffer', snd.pahandle, allSound{i});
    end
    

    function tone = generateTone(freq, dur, sampRate, fadeDur)

    end