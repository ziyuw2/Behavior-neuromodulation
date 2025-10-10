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
    Init.nTrials = 960;

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
    Init.trialTypeDir = nan(1, Init.nTrials); % blockwise when training, trial balanced in testing
    Init.tone = repmat({'None'}, 1, Init.nTrials); % H, M or L, created in Init, assigned based on rule and trialTypeDir

    tone_num = session.tone_num;
    if ~isempty(session.volume)
        if tone_num == 2
            block_size = length(session.volume) * 2;
            for i = 1:Init.nTrials/block_size
                block = [zeros(1, length(session.volume)) - (1:1:length(session.volume)), 1:1:length(session.volume)];
                block = block(randperm(block_size));
                Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
            end
            switch session.rule
                case 'H_GO'
                    Init.tone(Init.trialTypeDir == 1) = {'H1'};
                    Init.tone(Init.trialTypeDir == -1) = {'L1'};
                    Init.tone(Init.trialTypeDir == 2) = {'H2'};
                    Init.tone(Init.trialTypeDir == -2) = {'L2'};
                    Init.tone(Init.trialTypeDir == 3) = {'H3'};
                    Init.tone(Init.trialTypeDir == -3) = {'L3'};
                    Init.tone(Init.trialTypeDir == 4) = {'H4'};
                    Init.tone(Init.trialTypeDir == -4) = {'L4'};
                case 'L_GO'
                    Init.tone(Init.trialTypeDir == 1) = {'L1'};
                    Init.tone(Init.trialTypeDir == -1) = {'H1'};
                    Init.tone(Init.trialTypeDir == 2) = {'H2'};   
                    Init.tone(Init.trialTypeDir == -2) = {'L2'};
                    Init.tone(Init.trialTypeDir == 3) = {'H3'};
                    Init.tone(Init.trialTypeDir == -3) = {'L3'};
                    Init.tone(Init.trialTypeDir == 4) = {'H4'};
                    Init.tone(Init.trialTypeDir == -4) = {'L4'};
            end
        else
            disp('Tone number is not 2, please double check.');
        end
    else
        block_size = tone_num * 2;
        for i = 1:Init.nTrials/block_size
            block = [zeros(1, tone_num) - 1, ones(1, tone_num)]; % -1 and 1 for nogo and go
            block = block(randperm(tone_num*2));
            Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
        end
        switch session.rule
            case 'H_GO'
                Init.tone(Init.trialTypeDir == 1) = {'H'};
                Init.tone(Init.trialTypeDir == -1) = {'L'};
            case 'L_GO'
                Init.tone(Init.trialTypeDir == 1) = {'L'};
                Init.tone(Init.trialTypeDir == -1) = {'H'};
        end
    end

    % if session.repetition ~= 0 % training mode
    %     repetition = session.repetition; % technically can only be 5 or 0
    %     block_size = repetition * tone_num * 2;
    %     if tone_num == 2
    %         for i = 1:Init.nTrials/block_size
    %             block = [zeros(1, 2) - 1, ones(1, 2)]; % -1 and 1 for nogo and go
    %             block = block(randperm(tone_num*2));
    %             Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = repelem(block, repetition);
    %         end
    %     elseif tone_num == 3 % -1 0 1
    %         for i = 1:Init.nTrials/block_size
    %             block = [zeros(1, 2) - 1, zeros(1, 2), ones(1, 2)]; % -1 and 1 for neutral and reward
    %             block = block(randperm(tone_num*2));
    %             Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = repelem(block, repetition);
    %         end
    %     end
    % elseif session.repetition == 0 % testing mode
    %     if tone_num == 2
    %         % pseudo-random reward and punishment balanced trials every 20 trials
    %         block_size = 10;                    
    %         % Generate random numbers in blocks of 20
    %         % punishing:-1 rewarding:1
    %         for i = 1:(Init.nTrials/block_size) 
    %             % Create a block with 10 ones and 10 zeros
    %             block = [ones(1, block_size/tone_num), zeros(1, block_size/tone_num)-1];
    %             % Shuffle the block randomly
    %             block = block(randperm(block_size));
    %             % Place the block into the array
    %             Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
    %         end
    %     elseif tone_num == 3
    %         block_size = 24; %pseudo-random reward and punishment balanced trials every 24 trials
    %         for i = 1:(Init.nTrials/block_size)
    %             block = [ones(1, block_size/tone_num), zeros(1, block_size/tone_num)-1, zeros(1, block_size/tone_num)];
    %             block = block(randperm(block_size));
    %             Init.trialTypeDir((i-1)*block_size + 1:i*block_size) = block;
    %         end
    %     end
    % else
    %     error('Session repetition is not 0 or positive integer');
    % end

    % %% Assign tone to the trials
    % Init.tone = repmat({'None'}, 1, Init.nTrials); % H, M or L, created in Init, assigned based on rule and trialTypeDir
    % isH = (Init.trialTypeDir == 1);
    % isM = (Init.trialTypeDir == 0);
    % isL = (Init.trialTypeDir == -1);
    % Init.tone(isH) = {'H'};
    % Init.tone(isM) = {'M'};
    % Init.tone(isL) = {'L'};
end