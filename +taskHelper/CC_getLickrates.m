function [anticipatory_lickrate, result_lickrate] = CC_getLickrates(session, trial_i)
    % all the event will be saved in ms
    lickTime = session.event.lick_times{trial_i};
    soundOn = session.event.sound(trial_i);
    portOn = session.event.port_on(trial_i);
    portOff = session.event.port_off(trial_i);
    waterOn = session.event.water(trial_i);
    airpuff = session.event.airpuff(trial_i);

if any(isnan(lickTime)) || isnan(portOn) || (isnan(waterOn) && isnan(airpuff)) || isnan(portOff) || isnan(soundOn)
    anticipatory_lickrate = nan;
    result_lickrate = nan;
else
    if isnan(waterOn)
        us = airpuff;
    else
        us = waterOn;
    end
    if session.motorConnection % movable port
        anticipatory_lickrate = sum(lickTime >= portOn & lickTime < us) / session.usDelay;
        result_lickrate = sum(lickTime >= us & lickTime < portOff) / session.respDur;
    else % still port
        anticipatory_lickrate = sum(lickTime >= soundOn & lickTime < us) / session.usDelay;
        result_lickrate = sum(lickTime >= us & lickTime < portOff) / session.respDur;
    end
end
