function [Init] = GNG_audi_init(Info, session)
    % To generate block trials or reward and punishment balanced pseudo-random trials
    % Then assign sound to the trials based on the rule
    % Lastly generate delay and ITI
    % Init Stuct contains:
    %   nTrials: number of trials
    %   switchThreshold: number of trials after which the rule is switched
    %   iti: inter-trial interval
    %   rule: rule of the trials
    %   CStypeDir: type of the trials
    %   tone: tone of the trials
    %   trialType: type of the trials
    Init = struct();
    Init.nTrials = 720;
    
    %% Randomly genereate the switch after ... trials; might not be used in training sessions
    Init.switchThreshold = randi([Info.taskparam.switchThreshold(1), Info.taskparam.switchThreshold(2)]); % 80 100

    %% Generate port delay, water delay and ITI
    if length(Info.taskparam.iti) == 2
        Init.iti = rand(Init.nTrials, 1) * (Info.taskparam.iti(2) - Info.taskparam.iti(1)) + Info.taskparam.iti(1);
    else
        Init.iti = ones(Init.nTrials, 1)* Info.taskparam.iti;
    end
    
    %% Assign rule to the trials
    initRule = Info.session.initRule;
    Init.rule = cell(1, Init.nTrials);
    [Init.rule{:}] = deal(initRule); 
    
    %% Generate pseudo-random reward and punishment balanced trials based on tone
    Init.trialTypeDir = nan(1, Init.nTrials); % blockwise when training, trial balanced in testing
    tone_num = session.tone_num;
    if session.repetition ~= 0 % training mode
        repetition = session.repetition; % technically can only be 5 or 0
        block_size = repetition * tone_num * 2;
        if tone_num == 2
            for i = 1:Init.nTrials/block_size
                block = [zeros(1, 2) - 1, ones(1, 2)]; % -1 and 1
                block = block(randperm(tone_num*2));
                Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = repelem(block, repetition);
            end
        elseif tone_num == 3 % -1 0 1
            for i = 1:Init.nTrials/block_size
                block = [zeros(1, 2) - 1, zeros(1, 2), ones(1, 2)];
                block = block(randperm(tone_num*2));
                Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = repelem(block, repetition);
            end
        end
    elseif session.repetition == 0 % testing mode
        if tone_num == 2
            % pseudo-random reward and punishment balanced trials every 20 trials
            block_size = 20;                    
            % Generate random numbers in blocks of 20
            % punishing:-1 rewarding:1
            for i = 1:(Init.nTrials/block_size) 
                % Create a block with 10 ones and 10 zeros
                block = [ones(1, block_size/tone_num), zeros(1, block_size/tone_num)-1];
                % Shuffle the block randomly
                block = block(randperm(block_size));
                % Place the block into the array
                Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
            end
        elseif tone_num == 3
            block_size = 24;
            for i = 1:(Init.nTrials/block_size)
                block = [ones(1, block_size/tone_num), zeros(1, block_size/tone_num)-1, zeros(1, block_size/tone_num)];
                block = block(randperm(block_size));
                Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
            end
        end
    else
        error('Session repetition is not 0 or positive integer');
    end

    %% Assign tone to the trials
    Init.tone = repmat({'None'}, 1, Init.nTrials); % H, M or L, created in Init, assigned based on rule and trialTypeDir
    isH = (Init.trialTypeDir == 1);
    isM = (Init.trialTypeDir == 0);
    isL = (Init.trialTypeDir == -1);
    Init.tone(isH) = {'H'};
    Init.tone(isM) = {'M'};
    Init.tone(isL) = {'L'};
    end