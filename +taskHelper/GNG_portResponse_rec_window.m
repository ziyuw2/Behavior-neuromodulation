function session = GNG_portResponse_rec_window(Init, trial_i, session, ARDU, Info, withdraw, resp_period_start)    
    %% Record animal behavior during the response; deliver reward or airpuff
    trialTypeDir = Init.trialTypeDir(trial_i); % trial type dir represents tone in this case
    rule = Init.rule{trial_i};
    % assign whether the trial is go or nogo based on the rule
    % go or nogo is assigned based on the trialTypeDir in init
    switch session.tone_num
        case 2
            switch rule
                case 'H_GO'
                    session.trialTypeDir(trial_i) = trialTypeDir;
                case 'L_GO'
                    session.trialTypeDir(trial_i) = -trialTypeDir;
            end
        % case 3
        %     switch rule
        %         case 'A'
        %             if trialTypeDir == 0 % for the M tone trial, rule A is R
        %                 session.trialTypeDir(trial_i) = 1;
        %             else
        %                 session.trialTypeDir(trial_i) = trialTypeDir;
        %             end
        %         case 'B'
        %             if trialTypeDir == 0 % for the M tone trial, rule B is P
        %                 session.trialTypeDir(trial_i) = -1;
        %             else
        %                 session.trialTypeDir(trial_i) = trialTypeDir;
        %             end
        %     end
    end
     
    if session.trialTypeDir(trial_i) > 0 % go trials
        while 1 % infinite loop to check if the break condition is met
            %%%%% Didn't lick -> MISS -> no water %%%%%
            if toc(resp_period_start) > session.lickWindow  % didn't lick within the lick window; port retracts
                session.reactionTime(trial_i) = nan;
                taskHelper.port_move(Info, withdraw, ARDU);

                session.licked(trial_i) = 0;
                session.correct(trial_i) = 0;
                session.rewarded(trial_i) = 0;
                session.punished(trial_i) = 0;
                session.behavior{trial_i} = 'Miss'; % hit, miss, fa, cr
                break;
            end
            %%%%% Licked -> HIT -> water%%%%%
            if readDigitalPin(ARDU, Info.PIN.lickSensor) % licked within the lick window
                session.reactionTime(trial_i) = toc(resp_period_start);

                pause(session.reinforcerDelay); % we need to wait for the delay of the reinforcer
                if rand <= session.reinforcerProb
                    writeDigitalPin(ARDU, Info.PIN.water, 1);
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                    pause(session.waterTTLTime);
                    writeDigitalPin(ARDU, Info.PIN.water, 0);   
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                else
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                    pause(session.waterTTLTime);
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                end
                pause(session.respDur);
                taskHelper.port_move(Info, withdraw, ARDU);

                session.licked(trial_i) = 1;
                session.correct(trial_i) = 1;
                session.rewarded(trial_i) = 1;
                session.punished(trial_i) = 0;
                session.behavior{trial_i} = 'Hit';
                break;
                
            end
        end
    
    else % nogo trials
        while 1
            %%%%% Didn't lick -> CR -> nothing happens%%%%%
            if toc(resp_period_start) > session.lickWindow
                session.reactionTime(trial_i) = nan;
                taskHelper.port_move(Info, withdraw, ARDU);

                session.licked(trial_i) = 0;
                session.correct(trial_i) = 1;
                session.rewarded(trial_i) = 0;
                session.punished(trial_i) = 0;
                session.behavior{trial_i} = 'CR';
                break;
            end
            %%%%% Licked -> FA -> airpuff%%%%%
            if readDigitalPin(ARDU, Info.PIN.lickSensor)
                session.reactionTime(trial_i) = toc(resp_period_start);

                pause(session.reinforcerDelay); % we need to wait for the delay of the reinforcer
                if rand <= session.reinforcerProb
                    writeDigitalPin(ARDU, Info.PIN.airpuff, 1); 
                    writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
                    pause(session.airpuffDur);
                    writeDigitalPin(ARDU, Info.PIN.airpuff, 0);
                    writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0);
                else
                    writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
                    pause(session.airpuffDur);
                    writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0);
                end
                pause(session.respDur);
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