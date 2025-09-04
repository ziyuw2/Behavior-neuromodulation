    function session = GNG_getPerformance(session, trial_i)
        blockSize = session.blockSize; % Training: 30 for 3 tones and 20 for 2 tones; Testing: 70 for 3 tone and 2 tone
        if trial_i < blockSize
            block = 1:trial_i;
        else
            block = trial_i - blockSize + 1 : trial_i;
        end

        session.accuracy(trial_i) = sum(session.correct(block) == 1) / sum(~isnan(session.correct(block)));

        behavior = session.behavior(block);
        hit_rate = sum(ismember(behavior, 'Hit')) / (sum(ismember(behavior, 'Hit')) + sum(ismember(behavior, 'Miss')));
        fa_rate = sum(ismember(behavior, 'FA')) / (sum(ismember(behavior, 'FA')) + sum(ismember(behavior, 'CR')));
        session.dprime(trial_i) = norminv(hit_rate, 0, 1) - norminv(fa_rate, 0, 1);

        session.Aaccuracy(trial_i) = sum((session.correct(block) == 1) & ismember(session.rule(block), 'A')) / sum(ismember(session.rule(block), 'A') & ~isnan(session.correct(block)));
        session.Baccuracy(trial_i) = sum((session.correct(block) == 1) & ismember(session.rule(block), 'B')) / sum(ismember(session.rule(block), 'B') & ~isnan(session.correct(block)));

        if session.switchTrial ~= 0 % already switched
            switch session.rule{trial_i} % rule for new trial
                case 'A'
                    session.Aaccuracy(trial_i) = sum((session.correct(block) == 1) & ismember(session.rule(block), 'A')) / sum(ismember(session.rule(block), 'A') & ~isnan(session.correct(block)));
                    session.Baccuracy(trial_i) = session.Baccuracy(session.switchTrial);
                case 'B'
                    session.Aaccuracy(trial_i) = session.Aaccuracy(session.switchTrial);
                    session.Baccuracy(trial_i) = sum((session.correct(block) == 1) & ismember(session.rule(block), 'B')) / sum(ismember(session.rule(block), 'B') & ~isnan(session.correct(block)));
            end
        end

    end