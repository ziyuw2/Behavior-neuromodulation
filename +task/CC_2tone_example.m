function [Info] = CC_2tone_example(app, Info, Stim, ARDU, DAQ)
    % timeUnit in ARDU is ms; timeUnit in Matlab is sec
    
    %% Create a struct to store session data
    session = struct();
    session.repetition = 1;
    session.initRule = Info.session.initRule;
    session.secondRule = char('A' + 'B' - session.initRule);
    session.tone_num = 2;
    
    Init = taskHelper.CC_audi_init(Info, session);
    session.switchThreshold = Init.switchThreshold;
    
    session.iti = [];
    session.rule = {};
    session.CStypeDir = [];
    session.tone = {};
    session.trialType = {};
    session.switchTrial = 0;
    session.repetitionReducedTrial = 0;
    
    %% Invariable parameters
    session.repReduceCriterionNum = 2;
    session.startCueDur = Info.taskparam.startCueDur;
    session.initDelay = Info.taskparam.isi;
    session.portDelay = Info.taskparam.portDelay;
    session.usDelay = Info.taskparam.usDelay;
    session.respDur = Info.taskparam.respDur;
    session.USprobability = Info.taskparam.USprobability;
    session.airpuffDur = Info.taskparam.airpuffDur;
    session.waterTTLTime = Info.taskparam.waterTTLTime;
    
    % Trial event storage
    session.event.led = [];
    session.event.lick_times = {};
    session.event.sound = [];
    session.event.port_on = [];
    session.event.port_off = [];
    session.event.water = [];
    session.event.airpuff = [];
    
    session.lickRate_anticipatory = [];
    session.lickRate_result = [];
    session.Rave_lickRate = cell(4, 0);
    session.Pave_lickRate = cell(4, 0);
    session.Nave_lickRate = cell(4, 0);
    for i = 1:4
        session.Rave_lickRate{i,1} = NaN;
        session.Pave_lickRate{i,1} = NaN;
        session.Nave_lickRate{i,1} = NaN;
    end
    
    %% Create sound players
    Stim = audiHelper.loadTone(Stim, Info);
    speaker_low = audioplayer(Stim.tone_low, Stim.samplingFreq);
    speaker_high = audioplayer(Stim.tone_high, Stim.samplingFreq);
    speaker_mid = audioplayer(Stim.tone_mid, Stim.samplingFreq);
    
    %% Motor control
    nSteps = 5;
    [approach, withdraw] = taskHelper.getMotorSteps(Info, nSteps);
    
    %% Start the trial
    significance_counter = 0;
    trial_i = 1;
    taskHelper.CC_drawLickrate_init(session, Info, Init, app, trial_i);
    taskHelper.CC_drawTrialtype_init(Info, Init, app, trial_i);
    hold(app.bigPlot, 'on');
    hold(app.smallPlot, 'on');
    while trial_i < Init.nTrials
        app.trialNum.Text = num2str(trial_i);
        taskHelper.CC_drawTrialCurrent(Init, trial_i, app);
        session.iti(trial_i) = Init.iti(trial_i);
        session.rule{trial_i} = Init.rule{trial_i};
        session.CStypeDir(trial_i) = Init.CStypeDir(trial_i);
    
        %% start cue and initial delay
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
    
        %% Water delay
        taskHelper.stateTextOutput('Water delay', app);
        pause(session.usDelay);
    
        %% Port response and response period
        taskHelper.stateTextOutput('US deliv.', app);
        session = taskHelper.CC_US_delivery(Init, ARDU, session, Info, trial_i);
        taskHelper.stateTextOutput('Response', app);
        pause(session.respDur);
        taskHelper.port_move(Info, withdraw, ARDU);
        taskHelper.stateTextOutput('Port off', app);
    
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
    
        % %% Lick rate and GUI
        [session.lickRate_anticipatory(trial_i), session.lickRate_result(trial_i)] = taskHelper.CC_getLickrates(session, trial_i);
        session = taskHelper.CC_drawLickrate_trialType(Init, session, trial_i, app);
    
        if strcmpi(app.TaskstoppedLampLabel.Text, "Task stopped")
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            taskHelper.saveData(session, Info);
            taskHelper.stateTextOutput('Data saved', app);
            hold(app.bigPlot, 'off');
            hold(app.smallPlot, 'off');
            break;
        end
    
        %% TRIAL UPDATE
        window_size = 30;
        repReduceCriterionNum = session.repReduceCriterionNum; % 30
        if trial_i >= window_size
            isP = contains(session.trialType, 'P');
            isR = contains(session.trialType, 'R');
            R_anticipatory = session.lickRate_anticipatory(isR);
            P_anticipatory = session.lickRate_anticipatory(isP);
            [h, ~] = ttest2(R_anticipatory, P_anticipatory, 'Tail', 'right');
            if h == 1
                significance_counter = significance_counter + 1;
            else
                significance_counter = 0;
            end

            if session.repetition > 0
                if significance_counter >= repReduceCriterionNum
                    session.repetition = session.repetition - 1;
                    session.repetitionReducedTrial = trial_i;
                    disp(['reduced repetition to ', num2str(session.repetition), ' at trial ', num2str(trial_i)])
                    [Init.CStypeDir, Init.tone] = taskHelper.CC_updateCStypeDir(Init.CStypeDir, trial_i, session.repetition, session.tone_num, session.initRule);
                    significance_counter = 0;
                    hold(app.smallPlot, 'off');
                    taskHelper.CC_drawTrialtype_init(Info, Init, app, trial_i+1);
                    hold(app.smallPlot, 'on');
                end
            end

            if session.repetition == 0
                app.bigPlot.Title.String = [Info.session.ID, '  ',Info.session.animalID,'  Training done at trial ', num2str(trial_i)];
            end
        end
        app.repSwitch.Text = num2str(session.repetition);
        trial_i = trial_i + 1;
    end
    end