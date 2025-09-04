function events = readAllEvents(serialObj, maxEvents)
    % Reads streaming serial input from Arduino and parses it into a struct
    % Input: serialObj - the serialport object
    %        maxEvents - maximum number of events to read (optional)
    % Output: events - struct array with fields: label, time, state
    
    if nargin < 2
        maxEvents = 5000; % default max events
    end
    
    events = struct('label', {}, 'time', {}, 'state', {});
    i = 1;
    
    while serialObj.NumBytesAvailable > 0 && i <= maxEvents
        line = strtrim(readline(serialObj));
        % disp(">> " + line);  % Add this for debugging
        if startsWith(line, "EVENT:")
            data = extractAfter(line, "EVENT:");
            parts = split(data, ",");
            if numel(parts) == 3
                events(i).label = parts{1};
                events(i).time = str2double(parts{2});
                events(i).state = str2double(parts{3});
                i = i + 1;
            else
                disp("Malformed EVENT line: " + line);  % Add this
            end
        end
    end
end








