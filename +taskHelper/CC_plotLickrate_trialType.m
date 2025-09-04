function session = CC_plotLickrate_trialType(Init, session, trial_i, app)     
    %% Text update
    % calculate the average lick rate in the last 60 trials
    window_size = session.windowSize;
    if trial_i >= window_size
        x = trial_i-window_size+1:trial_i;
        lickRate_window = session.lickRate_anticipatory(x);
        CStypeDir_window = session.CStypeDir(x);
    else
        x = 1:trial_i;
        lickRate_window = session.lickRate_anticipatory(x);
        CStypeDir_window = session.CStypeDir(x);

    end
    % calculate the average lick rate for each trial type and rule
    rule = session.rule{trial_i};
    CStypeDir = session.CStypeDir(trial_i);

    switch CStypeDir
        case 1
            trialType = 'R';
            isTrialType = CStypeDir_window == 1;
            session = ave_lickRateUpdate(session, lickRate_window, isTrialType, trialType);
            app.([trialType, 'lickRate']).Text = num2str(session.Rave_lickRate{1, trial_i});
        case 0
            trialType = 'N';
            isTrialType = CStypeDir_window == 0;
            session = ave_lickRateUpdate(session, lickRate_window, isTrialType, trialType);
            app.([trialType, 'lickRate']).Text = num2str(session.Nave_lickRate{1, trial_i});
    end


    cla(app.bigPlot);  % Clear plot before drawing
    plotGen(1:trial_i, cell2mat(session.Rave_lickRate(1,:)), [0 0.024 0.949]);
    % plotGen(1:trial_i, cell2mat(session.Pave_lickRate(1,:)), [0.98 0.02 0.063]);
    plotGen(1:trial_i, cell2mat(session.Nave_lickRate(1,:)), [0 0 0 0.7]);
    shadingGen(cell2mat(session.Rave_lickRate(3,:)), cell2mat(session.Rave_lickRate(4,:)), 1:trial_i, [0 0.024 0.949]);
    % shadingGen(cell2mat(session.Pave_lickRate(3,:)), cell2mat(session.Pave_lickRate(4,:)), 1:trial_i, [0.98 0.02 0.063]);
    shadingGen(cell2mat(session.Nave_lickRate(3,:)), cell2mat(session.Nave_lickRate(4,:)), 1:trial_i, [0 0 0.7]);

    function session = ave_lickRateUpdate(session, lickRate_window, isTrialType, trialType)
        ave_lickRate = mean(lickRate_window(isTrialType));
        [upper, lower] = errerbarGen(lickRate_window(isTrialType));
        session.([trialType, 'ave_lickRate']){1, trial_i} = ave_lickRate;
        session.([trialType, 'ave_lickRate']){2, trial_i} = [rule, trialType];
        session.([trialType, 'ave_lickRate']){3, trial_i} = upper;
        session.([trialType, 'ave_lickRate']){4, trial_i} = lower;
        allType = {'R', 'N'};
        notCurrentType = allType(~strcmp(allType, trialType));
        if trial_i > 1
            for i = 1:length(notCurrentType)
                session.([notCurrentType{i}, 'ave_lickRate']){1, trial_i} = session.([notCurrentType{i}, 'ave_lickRate']){1, trial_i-1};
                session.([notCurrentType{i}, 'ave_lickRate']){2, trial_i} = [rule, trialType];
                session.([notCurrentType{i}, 'ave_lickRate']){3, trial_i} = session.([notCurrentType{i}, 'ave_lickRate']){3, trial_i-1};
                session.([notCurrentType{i}, 'ave_lickRate']){4, trial_i} = session.([notCurrentType{i}, 'ave_lickRate']){4, trial_i-1};
            end
        else
            for i = 1:length(notCurrentType)
                session.([notCurrentType{i}, 'ave_lickRate']){1, trial_i} = NaN;
                session.([notCurrentType{i}, 'ave_lickRate']){2, trial_i} = [rule, trialType];
                session.([notCurrentType{i}, 'ave_lickRate']){3, trial_i} = NaN;
                session.([notCurrentType{i}, 'ave_lickRate']){4, trial_i} = NaN;
            end
        end
    end

    function [upper, lower] = errerbarGen(data)
        upper = mean(data) + std(data) / sqrt(length(data));
        lower = mean(data) - std(data) / sqrt(length(data));
    end

    function shadingGen(upper, lower, x, color)
        valid = ~isnan(upper) & ~isnan(lower);
        if any(valid)
            fill(app.bigPlot, [x(valid) fliplr(x(valid))], [upper(valid) fliplr(lower(valid))], color, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        end
    end

    function plotGen(x, y, color)
        plot(app.bigPlot, x, y, '-o', 'Color', color, 'LineWidth', 2);
    end

    %% Plotting trial type
    marker = [];
    switch session.rule{trial_i}
        case 'H_GO'
            marker = 'o';
        case 'L_GO'
            marker = 's';
    end

    if isnan(session.lickRate_anticipatory(trial_i))
        scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
        '#050505', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
    else
        switch session.trialType{trial_i}
            case 'P'
                scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
                '#F52549', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
            case 'R'
                scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
                '#4CB5F5', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
            case 'N'
                scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
                '#cccccc', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
            case 'PO'
                scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
                '#cccccc', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
            case 'RO'
                scatter(app.smallPlot, trial_i, session.CStypeDir(trial_i), 'Marker', marker, 'MarkerFaceColor', ...
                '#cccccc', 'SizeData', 70, 'LineWidth', 0.5, 'MarkerEdgeColor', [.5 .5 .5]);
        end
    end

    scatter(app.smallPlot, trial_i+20, Init.CStypeDir(trial_i+20), 'Marker', marker, ...
            'MarkerEdgeColor', [.5 .5 .5], 'SizeData', 70, 'LineWidth', 2);
    
    if isfield(session, 'repetitionReducedTrial') % training sessions
        xlimLowerbound = session.repetitionReducedTrial(end); 
    else
        xlimLowerbound = 0; % test session
    end 

    idx = trial_i - xlimLowerbound;
    max_trials_showing = 60;
    future_trials_showing = 5;
    start_compressing_trial = 50;
    % compressing the plot
    if idx + future_trials_showing <= max_trials_showing && idx + future_trials_showing > start_compressing_trial
        app.smallPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];   
    end
    % move the plot to the right
    if idx + future_trials_showing > max_trials_showing
        app.smallPlot.XLim = [trial_i + future_trials_showing - max_trials_showing trial_i + future_trials_showing];
    end
    
    xlimLowerbound = 0;
    idx = trial_i - xlimLowerbound;
    max_trials_showing = 120;
    future_trials_showing = 5;
    start_compressing_trial = 50;
    % compressing the plot
    if idx + future_trials_showing <= max_trials_showing && idx + future_trials_showing > start_compressing_trial
        app.bigPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];   
    end
    % move the plot to the right
    if idx + future_trials_showing > max_trials_showing
        app.bigPlot.XLim = [trial_i + future_trials_showing - max_trials_showing trial_i + future_trials_showing];
    end
    % legend(app.accuPlot, 'show');
end