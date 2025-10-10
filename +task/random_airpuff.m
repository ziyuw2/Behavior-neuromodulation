function [Info] = random_airpuff(app, Info, Stim, ARDU, DAQ)
% timeUnit in ARDU is ms; timeUnit in Matlab is sec
    
    %% Create a struct to store session data
    session = struct();
    Init = taskHelper.RAND_init(Info);
    % only need ITI 
    session.iti = [];

    %% Invariable parameters
    session.prespecifiedTrialNum = Info.session.prespecifiedTrialNum;
    session.startCueDur = Info.taskparam.startCueDur;
    session.initDelay = Info.taskparam.isi;
    session.stimDur = Info.taskparam.stimDur;
    session.portDelay = Info.taskparam.portDelay;
    session.usDelay = Info.taskparam.usDelay;
    session.respDur = Info.taskparam.respDur;
    session.airpuffDur = Info.taskparam.airpuffDur;
    session.waterTTLTime = Info.taskparam.waterTTLTime;
    session.recording = Info.session.recording;

    
    % Trial event storage
    session.event.led = [];
    session.event.lick_times = {};
    session.event.sound = [];
    session.event.port_on = [];
    session.event.port_off = [];
    session.event.water = [];
    session.event.airpuff = [];
    
    %% Motor control
    nSteps = 5;
    [approach, withdraw] = taskHelper.getMotorSteps(Info, nSteps);
    
    %% Pupil camera 
    if strcmp(session.recording, 'yes')
        % cd('C:\Rig\Pupil_cam')
        fclose(fopen('C:\Rig\Pupil_cam\start_cam.txt', 'w'));
        disp("Signal sent to start camera.");
        pause(5);
    end

    %% Start the trial
    trial_i = 1;
    while trial_i <= session.prespecifiedTrialNum
        app.trialNum.Text = num2str(trial_i);
        session.iti(trial_i) = Init.iti(trial_i);
        flush(DAQ, "input"); % clear the input buffer
        flush(DAQ, "output"); % clear the output buffer
    
        %% start cue and initial delay
        taskHelper.stateTextOutput('Trial start', app);
        % writeDigitalPin(ARDU, Info.PIN.LED, 1);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 1);
        pause(session.startCueDur);
        % writeDigitalPin(ARDU, Info.PIN.LED, 0);
        writeDigitalPin(ARDU, Info.PIN.LEDDaq, 0);
        pause(session.initDelay - 0.09); % there's a short delay as processing time

        pause(session.stimDur);
    
        %% Port delay and approach
        pause(session.portDelay - 0.08); % there's a short delay as processing time
        taskHelper.port_move(Info, approach, ARDU);
    
        %% US delay
        pause(session.usDelay);
    
        %% Port response
        taskHelper.stateTextOutput('US deliv.', app);
        writeDigitalPin(ARDU, Info.PIN.airpuff, 1);
        writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
        pause(session.airpuffDur);
        writeDigitalPin(ARDU, Info.PIN.airpuff, 0);
        writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0);
        session.trialType{trial_i} = 'R'; % reward

       taskHelper.stateTextOutput('ITI', app);

        %% Response period and port off
        pause(session.respDur);
        taskHelper.port_move(Info, withdraw, ARDU);
    
        %% ITI and serial read
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
  

        if strcmpi(app.TaskstoppedLampLabel.Text, "Task stopped")
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            taskHelper.saveData(session, Info, Init);
            taskHelper.stateTextOutput('Data saved', app);
            break;
        end

         % save data if the session is finished
        if trial_i == min(Init.nTrials, session.prespecifiedTrialNum)
            stoptime = datetime('now');
            session.totalTime = stoptime - Info.session.startTime;
            app.RunSwitch.Value = 'Stop';
            taskHelper.saveData(session, Info, Init);
            taskHelper.stateTextOutput('Data saved', app);
            break;
        end
    
        trial_i = trial_i + 1;
    end
end

