function [Info] = GNG_2tone_test(app, Info, Stim, ARDU, DAQ)
    % timeUnit in ARDU is ms; timeUnit in Matlab is sec
    
    %% Create a struct to store session data
    session = struct();
    session.repetition = 0;
    session.initRule = Info.session.initRule;
    if session.initRule ~= 'C'
        session.secondRule = char('A' + 'B' - session.initRule);
    end
    session.tone_num = 2;
    
    Init = taskHelper.GNG_audi_init(Info, session);
    session.switchThreshold = Init.switchThreshold;
    session.iti = [];
    session.rule = {};
    session.trialTypeDir = [];
    session.tone = {};
    session.switchTrial = 0;
    session.blockSize = 70; % for accuracy calculation
    
    %% Invariable parameters
    session.startCueDur = Info.taskparam.startCueDur;
    session.initDelay = Info.taskparam.isi;
    session.portDelay = Info.taskparam.portDelay;
    session.airpuffDur = Info.taskparam.airpuffDur;
    session.waterTTLTime = Info.taskparam.waterTTLTime;
    session.timeout = Info.taskparam.timeout;
    session.respDur = Info.taskparam.respDur;
    session.accuracyLevel = Info.taskparam.accuracyLevel;
    session.dprimeLevel = Info.taskparam.dprimeLevel;
 
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
    session.Aaccuracy = [];
    session.Baccuracy = [];
    
    %% Create sound players
    Stim = audiHelper.loadTone(Stim, Info);
    speaker_low = audioplayer(Stim.tone_low, Stim.samplingFreq);
    speaker_high = audioplayer(Stim.tone_high, Stim.samplingFreq);
    speaker_mid = audioplayer(Stim.tone_mid, Stim.samplingFreq);
    
    %% Motor control
    nSteps = 5;
    [approach, withdraw] = taskHelper.getMotorSteps(Info, nSteps);
    
    %% Start the trial
    trial_i = 1;
    taskHelper.GNG_drawTrialtype_init(Info, Init, app, trial_i);
    taskHelper.GNG_drawAccuracy_init(Info, app, trial_i);
    hold(app.smallPlot, 'on');
    hold(app.accuPlot, 'on');
    while trial_i < Init.nTrials
        app.trialNum.Text = num2str(trial_i);
        taskHelper.GNG_drawTrialCurrent(Init, trial_i, app);
        session.iti(trial_i) = Init.iti(trial_i);
        session.rule{trial_i} = Init.rule{trial_i};
        app.repSwitch.Text = num2str(session.switchTrial);

        %% Start cue and initial delay
        taskHelper.stateTextOutput('Trial start', app);
        flush(DAQ, "input");
        flush(DAQ, "output");
        writeDigitalPin(ARDU, Info.PIN.LED, 1);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 1);
        pause(session.startCueDur);
        writeDigitalPin(ARDU, Info.PIN.LED, 0);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 0);
        pause(session.initDelay);
    
        %% Stimulus presentation
        taskHelper.stateTextOutput('Stim', app);
        switch Init.tone{trial_i}
            case 'H'
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
                play(speaker_high); % more accurate timing compared to playblocking
                pause(0.3);
                % playblocking(speaker_high);
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
            case 'L'
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
                play(speaker_low);
                pause(0.3);
                % playblocking(speaker_low);
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
            case 'M'
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
                play(speaker_mid);
                pause(0.3);
                % playblocking(speaker_mid);
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
        end
        session.tone{trial_i} = Init.tone{trial_i};
    
        %% Port delay and approach
        taskHelper.stateTextOutput('Port delay', app);
        pause(session.portDelay);
        taskHelper.port_move(Info, approach, ARDU);
    
        %% Port response and response period
        taskHelper.stateTextOutput('Response', app);
        resp_period_start = tic; % record the start time of the lick
        % session.trialTypeDir gets updated from -1 1 0 to only 1 and -1
        session = taskHelper.GNG_portResponse(Init, trial_i, session, ARDU, Info, withdraw, resp_period_start);

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
            hold(app.accuPlot, 'off');
            hold(app.smallPlot, 'off');
            break;
        end
    
        %% TRIAL UPDATE
    % if the accuracy for the past
    if session.rule{trial_i} == session.initRule && session.initRule ~= 'C'
        if trial_i >= session.switchThreshold && session.accuracy(trial_i) >= session.accuracyLevel && session.dprime(trial_i) >= session.dprimeLevel
            session.switchTrial = trial_i;
            app.repSwitch.Text = num2str(session.switchTrial);
            Init.rule(trial_i+1:end) = deal({session.secondRule});
            % Init.trialTypeDir(trial_i+1:end) = -Init.trialTypeDir(trial_i+1:end); % reverse the trial type for 2 tone only
            hold(app.smallPlot, 'off');
            taskHelper.GNG_drawTrialtype_init(Info, Init, app, trial_i+1);
            hold(app.smallPlot, 'on'); % trial plot  
            hold(app.accuPlot, 'on'); % delay plot
            app.smallPlot.Title.String = [Info.session.date, '  ',Info.session.animalID,'  Switched at: ', num2str(session.switchTrial)];
        end
    end
    trial_i = trial_i+1;
    end
    end