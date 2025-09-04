function [Info] = CC_2tone_train(app, Info, Stim, ARDU, DAQ)
    % timeUnit in ARDU is ms; timeUnit in Matlab is sec
    
    %% Create a struct to store session data
    session = struct();
    session.repetition = 5;
    session.rule = Info.session.rule; % 'H-GO' or 'L-GO'
    session.tone_num = 2;
    
    Init = taskHelper.CC_audi_init(Info, session);
    
    session.iti = [];
    session.rule = {};
    session.CStypeDir = [];
    session.tone = {};
    session.trialType = {};
    session.repetitionReducedTrial = [0];
    session.pValue = [];
    
    %% Invariable parameters
    session.repReduceCriterionNum = 30;
    session.windowSize = 30; % used to calculate the average lick rate, and repetition reduction
    session.prespecifiedTrialNum = Info.session.prespecifiedTrialNum;
    session.motorConnection = Info.session.motorConnection;
    session.startCueDur = Info.taskparam.startCueDur;
    session.initDelay = Info.taskparam.isi;
    session.stimDur = Info.taskparam.stimDur;
    session.portDelay = Info.taskparam.portDelay;
    session.usDelay = Info.taskparam.usDelay;
    session.respDur = Info.taskparam.respDur;
    session.USprobability = 1; % always deliver US for training
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
    % session.Pave_lickRate = cell(4, 0);
    session.Nave_lickRate = cell(4, 0);
    for i = 1:4
        session.Rave_lickRate{i,1} = NaN;
        % session.Pave_lickRate{i,1} = NaN;
        session.Nave_lickRate{i,1} = NaN;
    end
    
    %% Create sound players
    Stim = audiHelper.loadTone(Stim, Info);
    speaker_low = audioplayer(Stim.tone_low, Stim.samplingFreq);
    speaker_high = audioplayer(Stim.tone_high, Stim.samplingFreq);
    
    %% Motor control
    nSteps = 5;
    [approach, withdraw] = taskHelper.getMotorSteps(Info, nSteps);
    
    %% Start the trial
    significance_counter = 0;
    trial_i = 1;
    taskHelper.CC_init_lickratePlot(session, Info, app, trial_i);
    taskHelper.CC_init_trialtypePlot(Info, Init, app, trial_i);
    hold(app.bigPlot, 'on');
    hold(app.smallPlot, 'on');
    while trial_i < min(Init.nTrials, session.prespecifiedTrialNum)
        app.trialNum.Text = num2str(trial_i);
        taskHelper.CC_plotTrialCurrent(Init, trial_i, app);
        session.iti(trial_i) = Init.iti(trial_i);
        session.rule{trial_i} = Init.rule{trial_i};
        session.CStypeDir(trial_i) = Init.CStypeDir(trial_i);
        flush(DAQ, "input"); % clear the input buffer
        flush(DAQ, "output"); % clear the output buffer
    
        %% start cue and initial delay
        taskHelper.stateTextOutput('Trial start', app);
        writeDigitalPin(ARDU, Info.PIN.LED, 1);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 1);
        pause(session.startCueDur);
        writeDigitalPin(ARDU, Info.PIN.LED, 0);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 0);
        pause(session.initDelay - 0.09); % there's a short delay as processing time
    
        %% Stimulus presentation
        taskHelper.stateTextOutput('Stim', app);
        switch Init.tone{trial_i}
            case 'H'
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
                play(speaker_high); % more accurate timing compared to playblocking
                pause(session.stimDur);
                % playblocking(speaker_high);
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
            case 'L'
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 1);
                play(speaker_low);
                pause(session.stimDur);
                % playblocking(speaker_low);
                writeDigitalPin(ARDU, Info.PIN.soundDaq, 0);
        end
        session.tone{trial_i} = Init.tone{trial_i};
    
        %% Port delay and approach
        taskHelper.stateTextOutput('Port delay', app);
        pause(session.portDelay - 0.08); % there's a short delay as processing time
        taskHelper.port_move(Info, approach, ARDU);
    
        %% US delay
        taskHelper.stateTextOutput('US delay', app);
        pause(session.usDelay);
    
        %% Port response
        taskHelper.stateTextOutput('US deliv.', app);
        session = taskHelper.CC_US_delivery(Init, ARDU, session, Info, trial_i);

        %% Response period and port off
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
        pause(session.iti(trial_i));
    
        % %% Lick rate and GUI
        [session.lickRate_anticipatory(trial_i), session.lickRate_result(trial_i)] = taskHelper.CC_getLickrates(session, trial_i);
        session = taskHelper.CC_plotLickrate_trialType(Init, session, trial_i, app);
    
        if strcmpi(app.TaskstoppedLampLabel.Text, "Task stopped")
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            taskHelper.saveData(session, Info, Init);
            taskHelper.stateTextOutput('Data saved', app);
            hold(app.bigPlot, 'off');
            hold(app.smallPlot, 'off');
            break;
        end
    
        %% TRIAL UPDATE
        window_size = session.windowSize; % 30
        repReduceCriterionNum = session.repReduceCriterionNum; % 30
        if trial_i >= window_size
            isR = session.CStypeDir(trial_i-window_size+1:trial_i) == 1;
            isN = session.CStypeDir(trial_i-window_size+1:trial_i) == 0;
            R_anticipatory = session.lickRate_anticipatory(isR);
            N_anticipatory = session.lickRate_anticipatory(isN);
            [h, p] = ttest2(R_anticipatory, N_anticipatory, 'Tail', 'right'); % the tail doesn't seem to be working
            session.pValue(trial_i) = p;
            if h == 1
                significance_counter = significance_counter + 1;
            else
                significance_counter = 0;
            end

            if session.repetition > 0
                if significance_counter >= repReduceCriterionNum
                    session.repetition = session.repetition - 1;
                    session.repetitionReducedTrial(end+1) = trial_i;
                    disp(['reduced repetition to ', num2str(session.repetition), ' at trial ', num2str(trial_i)])
                    [Init.CStypeDir, Init.tone] = taskHelper.CC_updateCStypeDir(Init.CStypeDir, trial_i, session.repetition, session.tone_num, session.initRule);
                    significance_counter = 0; % reset the counter
                    hold(app.smallPlot, 'off');
                    taskHelper.CC_init_trialtypePlot(Info, Init, app, trial_i+1);
                    hold(app.smallPlot, 'on');
                    app.bigPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, ' Lick Rate  Repetition: ', num2str(session.repetition)];
                    app.repSwitch.Text = num2str(trial_i);
                    if session.repetition == 0
                        app.bigPlot.Title.String = [Info.session.date, '  ',Info.session.animalID,'Lick Rate  Training done at trial ', num2str(session.repetitionReducedTrial(end))];
                    end
                end
            end
        end
        trial_i = trial_i + 1;
    end

    % save data if the session is finished
    if trial_i == min(Init.nTrials, session.prespecifiedTrialNum)
        stoptime = datetime('now');
        session.totalTime = stoptime - Info.session.startTime;
        taskHelper.saveData(session, Info, Init);
        taskHelper.stateTextOutput('Data saved', app);
        hold(app.bigPlot, 'off');
        hold(app.smallPlot, 'off');
    end
end