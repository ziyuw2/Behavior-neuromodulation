function Stim = loadTone(Stim, Info)   
    % Load tones with low, mid, and high frequencies and apply fades

    % Extract parameters
    stimDur = Info.taskparam.stimDur;       % Stimulus duration (seconds), 0.5s
    sampleFreq = Stim.samplingFreq;     % Sampling frequency (Hz), 48000
    fadeDur = Stim.fade_duration;       % Fade duration (ms) , 10ms

    % Generate tones with fading applied
    Stim.tone_low = generateTone(min(Stim.toneFreq), stimDur, sampleFreq, fadeDur);
    Stim.tone_mid = generateTone(Stim.toneFreq(2), stimDur, sampleFreq, fadeDur);
    Stim.tone_high = generateTone(max(Stim.toneFreq), stimDur, sampleFreq, fadeDur); % Amplitude scaling
    % stim.tone_mid = generateTone(stim.toneFreq(2), stimDur, sampleFreq, fadeDur);
end

function tone = generateTone(freq, dur, sampRate, fadeDur)
    % Generate a sine wave tone with fade-in and fade-out

    % Validate inputs
    validateattributes(freq, {'numeric'}, {'scalar', 'positive'}, mfilename, 'freq');
    validateattributes(dur, {'numeric'}, {'scalar', 'positive'}, mfilename, 'dur');
    validateattributes(sampRate, {'numeric'}, {'scalar', 'positive'}, mfilename, 'sampRate');
    validateattributes(fadeDur, {'numeric'}, {'scalar', 'nonnegative'}, mfilename, 'fadeDur');

    % Generate time vector and sine wave
    nSamples = round(dur * sampRate);
    t = linspace(0, dur, nSamples);
    tone = sin(2 * pi * freq * t); % Sine wave

    % Apply fade-in and fade-out
    fadeDurSamples = floor(fadeDur * 1e-3 * sampRate); % Convert fade duration to samples
    tone = applyFade(tone, fadeDurSamples);
end

function signal = applyFade(signal, fadeSamples)
    % Apply fade-in and fade-out to a signal

    % Validate fade duration relative to signal length
    nSamples = length(signal);
    fadeSamples = min(fadeSamples, floor(nSamples / 2)); % Limit fade to half the signal length

    % Generate fade window
    fadeWindow = linspace(0, 1, fadeSamples).^2; % Quadratic fade

    % Apply fade-in
    signal(1:fadeSamples) = signal(1:fadeSamples) .* fadeWindow;

    % Apply fade-out
    signal(end-fadeSamples+1:end) = signal(end-fadeSamples+1:end) .* flip(fadeWindow);
end