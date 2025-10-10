function [Info] = GNG_2tone_test(app, Info, Stim, ARDU, DAQ)
    % timeUnit in ARDU is ms; timeUnit in Matlab is sec
    
    %% Create a struct to store session data
    session = struct();
    session.repetition = 0;    
    session.rule = Info.session.rule; % 'H-GO' or 'L-GO'
    session.volume = Info.taskparam.volume;
    session.tone_num = 2;
    
    Init = taskHelper.GNG_audi_init(Info, session);
    session.iti = [];
    session.rule = {};
    session.trialTypeDir = [];
    session.tone = {};
    session.switchTrial = 0;
    session.blockSize = 70; % for accuracy calculation
    
    %% Invariable parameters
    session.prespecifiedTrialNum = Info.session.prespecifiedTrialNum;
    session.motorConnection = Info.session.motorConnection;
    session.startCueDur = Info.taskparam.startCueDur;
    session.initDelay = Info.taskparam.isi;
    session.stimDur = Info.taskparam.stimDur;
    session.portDelay = Info.taskparam.portDelay;
    session.lickWindow = Info.taskparam.lickWindow;
    session.reinforcerDelay = Info.taskparam.reinforcerDelay;
    session.reinforcerProb = Info.taskparam.reinforcerProb;
    session.airpuffDur = Info.taskparam.airpuffDur;
    session.waterTTLTime = Info.taskparam.waterTTLTime;
    session.timeout = Info.taskparam.timeout;
    session.respDur = Info.taskparam.respDur;
    session.recording = Info.session.recording;
    session.expType = Info.session.expType;
 
    % Trial event storage
    session.event.led = [];
    session.event.lick_times = {};
    session.event.sound = [];
    session.event.port_on = [];
    session.event.port_off = [];
    session.event.water = [];
    session.event.airpuff = [];

    session.reactionTime = [];
    session.licked = [];
    session.correct = [];
    session.rewarded = [];
    session.punished = [];
    session.behavior = {}; % hit, miss, fa, cr
    session.accuracy = [];
    session.dprime = [];

    %% Create sound players
    Stim = audiHelper.loadTone(Stim, Info);
    if ~isempty(session.volume)
        volume = session.volume;
        speaker.L1 = audioplayer(volume(1) * Stim.tone_low, Stim.samplingFreq);
        speaker.H1 = audioplayer(volume(1) * Stim.tone_high, Stim.samplingFreq);
        speaker.L2 = audioplayer(volume(2) * Stim.tone_low, Stim.samplingFreq);
        speaker.H2 = audioplayer(volume(2) * Stim.tone_high, Stim.samplingFreq);
        speaker.L3 = audioplayer(volume(3) * Stim.tone_low, Stim.samplingFreq);
        speaker.H3 = audioplayer(volume(3) * Stim.tone_high, Stim.samplingFreq);
        speaker.L4 = audioplayer(volume(4) * Stim.tone_low, Stim.samplingFreq);
        speaker.H4 = audioplayer(volume(4) * Stim.tone_high, Stim.samplingFreq);
    else
        speaker.L = audioplayer(Stim.tone_low, Stim.samplingFreq);
        speaker.H = audioplayer(Stim.tone_high, Stim.samplingFreq);
        % speaker_mid = audioplayer(Stim.tone_mid, Stim.samplingFreq);
    end
    %% Motor control
    nSteps = 5;
    [approach, withdraw] = taskHelper.getMotorSteps(Info, nSteps);

    %% Pupil camera 
    switch session.expType
        case '1P imaging'
        % cd('C:\Rig\Pupil_cam')
        fclose(fopen('C:\Rig\Pupil_cam\start_cam.txt', 'w'));
        disp("Signal sent to start camera.");
        pause(5);
    end
    
    %% Start the trial
    trial_i = 1;
    taskHelper.GNG_drawTrialtype_init(Info, Init, app, trial_i);
    taskHelper.GNG_drawAccuracy_init(Info, app, trial_i);
    hold(app.smallPlot, 'on');
    hold(app.bigPlot, 'on');
    while trial_i <= min(Init.nTrials, session.prespecifiedTrialNum)
        app.trialNum.Text = num2str(trial_i);
        taskHelper.GNG_drawTrialCurrent(Init, trial_i, app);
        session.iti(trial_i) = Init.iti(trial_i);
        session.rule{trial_i} = Init.rule{trial_i};
        app.repSwitch.Text = num2str(session.repetition);
        flush(DAQ, "input");
        flush(DAQ, "output");

        %% Start cue and initial delay
        taskHelper.stateTextOutput('Trial start', app);
        writeDigitalPin(ARDU, Info.PIN.LED, 1);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 1);
        pause(session.startCueDur);
        writeDigitalPin(ARDU, Info.PIN.LED, 0);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 0);
        pause(session.initDelay - 0.09); % there's a short delay as processing time
    
        %% Stimulus presentation
        taskHelper.stateTextOutput('Stim', app);
        writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
        play(speaker.(Init.tone{trial_i}));
        pause(session.stimDur);
        writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
        session.tone{trial_i} = Init.tone{trial_i};
    
        %% Port delay and approach
        taskHelper.stateTextOutput('Port delay', app);
        pause(session.portDelay - 0.08); % there's a short delay as processing time
        taskHelper.port_move(Info, approach, ARDU);
    
        %% Port response and response period
        taskHelper.stateTextOutput('Response', app);
        resp_period_start = tic; % record the start time of the lick
        % session.trialTypeDir gets updated from -1 1 0 to only 1 and -1
        session = taskHelper.GNG_portResponse_rec_window(Init, trial_i, session, ARDU, Info, withdraw, resp_period_start);

        %% ITI and serial read
        taskHelper.stateTextOutput('ITI', app);
        session.iti(trial_i) = Init.iti(trial_i);
        try
            % disp(['trial ', num2str(trial_i)])
            ev = taskHelper.readAllEvents(DAQ);
        catch
            disp("Didn't receive full data from Arduino for trial " + trial_i);
        end
        session = taskHelper.parseEventStruct(ev, trial_i, session);

        flush(DAQ, "input");
        flush(DAQ, "output");
        if session.correct(trial_i) == 0
            pause(session.timeout);
        end
        pause(Init.iti(trial_i));
    
        %% Accuracy and d' calculation
        % acc, dprime, Aacc, Bacc get updated
        session = taskHelper.GNG_getPerformance(session, trial_i);
        taskHelper.GNG_drawPerformance(session, trial_i, app, Init);
    
        if strcmpi(app.TaskstoppedLampLabel.Text, "Task stopped")
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            taskHelper.saveData(session, Info, Init);
            taskHelper.stateTextOutput('Data saved', app);
            hold(app.bigPlot, 'off');
            hold(app.smallPlot, 'off');
            break;
        end

        if trial_i == min(Init.nTrials, session.prespecifiedTrialNum)
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            app.RunSwitch.Value = 'Stop';
            taskHelper.saveData(session, Info, Init);
            taskHelper.stateTextOutput('Data saved', app);
            hold(app.bigPlot, 'off');
            hold(app.smallPlot, 'off');
            break;
        end
    
        %% TRIAL UPDATE
        trial_i = trial_i + 1;
    end