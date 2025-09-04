function session = GNG_portResponse_new(Init, trial_i, session, ARDU, Info, withdraw, resp_period_start)    
    %% Record animal behavior during the response; deliver reward or airpuff
    trialTypeDir = Init.trialTypeDir(trial_i); % trial type dir represents tone in this case
    rule = Init.rule{trial_i};
    % assign whether the trial is go or nogo based on the rule
    switch session.tone_num
        case 2
            switch rule
                case 'A'
                    session.trialTypeDir(trial_i) = trialTypeDir;
                case 'B'
                    session.trialTypeDir(trial_i) = -trialTypeDir;
                case 'C'
                    session.trialTypeDir(trial_i) = 1;
            end
        case 3
            switch rule
                case 'A'
                    if trialTypeDir == 0 % for the M tone trial, rule A is R
                        session.trialTypeDir(trial_i) = 1;
                    else
                        session.trialTypeDir(trial_i) = trialTypeDir;
                    end
                case 'B'
                    if trialTypeDir == 0 % for the M tone trial, rule B is P
                        session.trialTypeDir(trial_i) = -1;
                    else
                        session.trialTypeDir(trial_i) = trialTypeDir;
                    end
                case 'C'
                    session.trialTypeDir(trial_i) = 1;
            end
    end
     

    switch session.trialTypeDir(trial_i)
        case 1 % go trials
            while 1 % infinite loop to check if the break condition is met
                %%%%% Didn't lick -> incorrect -> no water %%%%%
                if toc(resp_period_start) > 0.8  % need to lick within 800ms
                    session.reactionTime(trial_i) = nan;

                    taskHelper.port_move(Info, withdraw, ARDU);

                    session.licked(trial_i) = 0;
                    session.correct(trial_i) = 0;
                    session.rewarded(trial_i) = 0;
                    session.punished(trial_i) = 0;
                    session.behavior{trial_i} = 'Miss'; % hit, miss, fa, cr
                    break;
                end
                %%%%% Licked -> correct -> water%%%%%
                if readDigitalPin(ARDU, Info.PIN.lickSensor)
                    session.reactionTime(trial_i) = toc(resp_period_start);
                    if session.reactionTime(trial_i) < 0.8 % licked within 800ms
                        pause(1 - session.reactionTime(trial_i)); % the total response duration is 1s, so we need to wait for the rest of the time
                        writeDigitalPin(ARDU, Info.PIN.water, 1);
                        writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                        pause(session.waterTTLTime);
                        writeDigitalPin(ARDU, Info.PIN.water, 0);
                        writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                        pause(session.respDur);
                        taskHelper.port_move(Info, withdraw, ARDU);

                        session.licked(trial_i) = 1;
                        session.correct(trial_i) = 1;
                        session.rewarded(trial_i) = 1;
                        session.punished(trial_i) = 0;
                        session.behavior{trial_i} = 'Hit';
                        break;
                    else % licked after 800ms, even tho licked still considered as a miss
                        session.reactionTime(trial_i) = session.reactionTime(trial_i);
                        taskHelper.port_move(Info, withdraw, ARDU);
                        session.licked(trial_i) = 1;
                        session.correct(trial_i) = 0;
                        session.rewarded(trial_i) = 0;
                        session.punished(trial_i) = 0;
                        session.behavior{trial_i} = 'Miss';
                        break;
                    end
                end
            end
    
        case -1 % nogo trials
            while 1
                %%%%% Didn't lick -> correct -> nothing happens%%%%%
                if toc(resp_period_start) > 0.8
                    pause(1-0.8+session.respDur);
                    taskHelper.port_move(Info, withdraw, ARDU);

                    session.reactionTime(trial_i) = nan;
                    session.licked(trial_i) = 0;
                    session.correct(trial_i) = 1;
                    session.rewarded(trial_i) = 0;
                    session.punished(trial_i) = 0;
                    session.behavior{trial_i} = 'CR';
                    break;
                end
                %%%%% Licked -> incorrect -> airpuff%%%%%
                if readDigitalPin(ARDU, Info.PIN.lickSensor)
                    session.reactionTime(trial_i) = toc(resp_period_start);
                    if session.reactionTime(trial_i) < 1 % licked within 1s
                        pause(1 - session.reactionTime(trial_i)); % the total response duration is 1s, so we need to wait for the rest of the time
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 1);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
                        pause(session.airpuffDur);
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 0);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0);

                        pause(session.respDur);
                        taskHelper.port_move(Info, withdraw, ARDU);

                        session.licked(trial_i) = 1;
                        session.correct(trial_i) = 0;
                        session.rewarded(trial_i) = 0;
                        session.punished(trial_i) = 1;
                        session.behavior{trial_i} = 'FA';
                        break;
                    else
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 1);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
                        pause(session.airpuffDur);
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 0);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0); 
                        
                        pause(session.respDur - session.reactionTime(trial_i));
                        taskHelper.port_move(Info, withdraw, ARDU);

                        session.licked(trial_i) = 1;
                        session.correct(trial_i) = 0;
                        session.rewarded(trial_i) = 0;
                        session.punished(trial_i) = 1;
                        session.behavior{trial_i} = 'FA';
                        break;
                    end
                end
            end
    end
    end