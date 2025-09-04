function [YMag] = generateSirenEphys(sampling_freq, te)
% checked
% sampling freq = 44100; te = 3
dt = 1/sampling_freq;
t = 0:dt:te; % 0:1/44100:3, 3s
f = 100* sin(2*pi*t) + 300;

% Generate the signal
angl = cumtrapz(t,f); % integral of f on interval t
YMag = 30*sin(2*pi*angl); % increased the amplitude to be twice as prev
end