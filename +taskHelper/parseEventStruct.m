function session = parseEventStruct(events, trial_i, session)
    debugging = 0;
    % Parse Arduino event stream into structured session fields
    % events: struct array with fields 'label', 'time', 'state'
    % trial_i: current trial index
    % session: session struct to be updated
    
    % Extract event labels
    labels = {events.label};
    times = [events.time];
    states = [events.state];
    if debugging
        disp(['Trial: ', num2str(trial_i)])
    end
    
    % --- LED
    led_idx = strcmp(labels, 'LED') & states == 1;
    if any(led_idx)
        led_time = times(find(led_idx, 1));
        if debugging
            disp(['>>', 'LED: ', num2str(led_time)])
        end
        session.event.led(trial_i) = led_time;
    else
        session.event.led(trial_i) = NaN;
    end
    
    % --- SOUND
    sound_idx = strcmp(labels, 'SOUND') & states == 1;
    if any(sound_idx)
        sound_time = times(find(sound_idx, 1));
        if debugging
            disp(['>>', 'SOUND: ', num2str(sound_time)])
        end
        session.event.sound(trial_i) = sound_time;
    else
        session.event.sound(trial_i) = NaN;
    end
    
    % --- PORT (advance & withdraw)
    port_idx = find(strcmp(labels, 'PORT') & states == 1);
    if length(port_idx) == 2
        port_time = times(port_idx);
        if debugging
            disp(['>>', 'PORT: ', num2str(port_time)])
        end
        session.event.port_on(trial_i) = port_time(1);
        session.event.port_off(trial_i) = port_time(2);
    else  
        session.event.port_on(trial_i) = NaN;
    end

    % --- WATER
    water_idx = strcmp(labels, 'WATER') & states == 1;
    if any(water_idx)
        water_time = times(find(water_idx, 1));
        if debugging
            disp(['>>', 'WATER: ', num2str(water_time)])
        end
        session.event.water(trial_i) = water_time;
    else
        session.event.water(trial_i) = NaN;
    end
    
    % --- AIRPUFF
    airpuff_idx = strcmp(labels, 'AIRPUFF') & states == 1;
    if any(airpuff_idx)
        airpuff_time = times(find(airpuff_idx, 1));
        if debugging
            disp(['>>', 'AIRPUFF: ', num2str(airpuff_time)])
        end
        session.event.airpuff(trial_i) = airpuff_time;
    else
        session.event.airpuff(trial_i) = NaN;
    end
    
    % --- LICKS
    lick_on_idx = strcmp(labels, 'LICK') & states == 1;
    if any(lick_on_idx)
        lick_time = times(lick_on_idx);
        if debugging
            disp(['>>', 'LICK: ', num2str(lick_time)])
        end
        session.event.lick_times{trial_i} = lick_time;
    else
        session.event.lick_times{trial_i} = [];
    end
    
    end
    