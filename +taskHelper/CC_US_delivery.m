function session = CC_US_delivery(Init, ARDU, session, Info, trial_i)       
    if session.repetition ~= 0 % only when the animal learned the rule
        USprobability = 1;
    else
        USprobability = session.USprobability; % probability of US delivery
        airpuffProbability = session.airpuffProbability; % probability of airpuff delivery when US is not delivered
    end

    switch Init.CStypeDir(trial_i)
        case 1 % CS for reward
            if rand <= USprobability
                writeDigitalPin(ARDU, Info.PIN.water, 1);
                writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                pause(session.waterTTLTime);
                writeDigitalPin(ARDU, Info.PIN.water, 0);
                writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                session.trialType{trial_i} = 'R'; % reward
            else
                if rand <= airpuffProbability
                    if session.airpuffDur > 0
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 1);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 1);
                        pause(session.airpuffDur);
                        writeDigitalPin(ARDU, Info.PIN.airpuff, 0);
                        writeDigitalPin(ARDU, Info.PIN.airpuffDaq, 0);
                        session.trialType{trial_i} = 'P'; % punishment
                    else
                        writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                        pause(session.waterTTLTime); % add delay for consistency
                        writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                        session.trialType{trial_i} = 'RO'; % reward omission
                    end
                else
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
                    pause(session.waterTTLTime); % add delay for consistency
                    writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
                    session.trialType{trial_i} = 'RO'; % reward omission
                end
            end

        case 0 % CS for neutral
            writeDigitalPin(ARDU, Info.PIN.waterDaq, 1);
            pause(session.waterTTLTime); % add delay for consistency
            writeDigitalPin(ARDU, Info.PIN.waterDaq, 0);
            session.trialType{trial_i} = 'N';
    end
end