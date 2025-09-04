function [updatedDir, updatedTone] = CC_updateCStypeDir(oldDir, trial_i, repetition, tone_num, rule)   
    if repetition > 0 % for training
        % Determine block size based on number of tones and repetition
        if tone_num == 2
            % Two tones: -1 and 1 (punishment and reward)
            block_size = repetition * tone_num * 2;  % e.g., 4 tones × repetition
            block_generator = @() [zeros(1, 2), ones(1, 2)];
        else
            error('Unsupported number of tones: tone_num must be 2.');
        end

        % Total number of remaining trials
        remaining_trials = length(oldDir) - trial_i;

        % How many full blocks can we fit?
        full_blocks = floor(remaining_trials / block_size);
        usable_trials = full_blocks * block_size;

        % Preallocate and generate the new block sequence
        newDir = nan(1, usable_trials);
        for i = 1:full_blocks
            block = block_generator();
            block = block(randperm(length(block)));  % shuffle
            newDir((i-1) * block_size + 1 : i * block_size) = repelem(block, repetition);    
        end

    elseif repetition == 0 % for reversal, will never be used
        remaining_trials = length(oldDir) - trial_i;

        if tone_num == 2
            % Two tones: -1 and 1 (punishment and reward)
            block_generator = @() [zeros(1, 10), ones(1, 10)];
        else
            error('Unsupported number of tones: tone_num must be 2.');
        end

        block_size = 10 * tone_num;
        full_blocks = floor(remaining_trials / block_size);
        usable_trials = full_blocks * block_size;

        newDir = nan(1, usable_trials);
        for i = 1:full_blocks
            block = block_generator();
            block = block(randperm(length(block)));  % shuffle
            newDir((i-1) * block_size + 1 : i * block_size) = block;    
        end
    end

    % Replace the relevant portion of the old Dir array
    updatedDir = oldDir;
    updatedDir(trial_i + 1: trial_i + usable_trials) = newDir;

    % Optionally NaN out any remaining tail trials
    updatedDir(trial_i + usable_trials + 1 : end) = NaN;

    updatedTone = repmat({'None'}, 1, usable_trials); % H, M or L, created in Init, assigned based on rule and CStypeDir
    switch rule
        case 'H_GO'
            updatedTone(updatedDir == 0) = deal({'L'});
            updatedTone(updatedDir == 1) = deal({'H'});
            updatedTone(isnan(updatedDir)) = deal({'None'});
        case 'L_GO'
            updatedTone(updatedDir == 1) = deal({'L'});
            updatedTone(updatedDir == 0) = deal({'H'});
            updatedTone(isnan(updatedDir)) = deal({'None'});
    end
end
