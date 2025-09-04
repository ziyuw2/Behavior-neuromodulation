function [Init] = CC_audi_init(Info, session)    
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
    Init.nTrials = 960;
    
    % Init.switchThreshold = randi([Info.taskparam.switchThreshold(1), Info.taskparam.switchThreshold(2)]); % 140, 150

    %% Generate port delay, water delay and ITI
    if length(Info.taskparam.iti) == 2
        Init.iti = rand(Init.nTrials, 1) * (Info.taskparam.iti(2) - Info.taskparam.iti(1)) + Info.taskparam.iti(1);
    else
        Init.iti = ones(Init.nTrials, 1)* Info.taskparam.iti;
    end
    
    %% Assign rule to the trials
    rule = Info.session.rule;
    Init.rule = cell(1, Init.nTrials);
    [Init.rule{:}] = deal(rule); 
    
    %% Generate pseudo-random reward and punishment balanced trials based on tone
    Init.CStypeDir = nan(1, Init.nTrials); % blockwise when training, trial balanced in testing
    tone_num = session.tone_num;
    if session.repetition ~= 0 % training mode
        repetition = session.repetition; % technically can only be 5 or 0
        block_size = repetition * tone_num * 2;
        if tone_num == 2

            for i = 1:Init.nTrials/block_size
                block = [zeros(1, 2), ones(1, 2)]; % 0 and 1 for neutral and reward
                block = block(randperm(tone_num*2));
                Init.CStypeDir((i-1)*block_size + 1:i*block_size) = repelem(block, repetition);
            end
        else
            disp('Tone number is not 2, please double check.');
        end

    elseif session.repetition == 0 % testing mode
        if tone_num == 2
            % pseudo-random reward and punishment balanced trials every 20 trials
            block_size = 20;                    
            % Generate random numbers in blocks of 20
            % punishing:-1 rewarding:1
            for i = 1:(Init.nTrials/block_size) 
                % Create a block with 10 ones and 10 zeros
                block = [ones(1, block_size/tone_num), zeros(1, block_size/tone_num)];
                % Shuffle the block randomly
                block = block(randperm(block_size));
                % Place the block into the array
                Init.CStypeDir((i-1)*block_size + 1:i*block_size) = block;
            end
        else
            disp('Tone number is not 2, please double check.');
        end
    else
        error('Session repetition is not 0 or positive integer');
    end

    %% Assign tone to the trials
    Init.tone = repmat({'None'}, 1, Init.nTrials); % H, M or L, created in Init, assigned based on rule and CStypeDir
    isN = (Init.CStypeDir == 0); % neutral
    isR = (Init.CStypeDir == 1); % has water reward
    switch session.rule
        case 'H_GO'
            Init.tone(isN) = {'L'};
            Init.tone(isR) = {'H'};
        case 'L_GO'
            Init.tone(isR) = {'L'};
            Init.tone(isN) = {'H'};
    end
    end