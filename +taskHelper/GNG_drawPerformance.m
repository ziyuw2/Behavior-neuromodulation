function GNG_drawPerformance(session, trial_i, app, Init)
    % trial num
    app.trialNum.Text = num2str(trial_i); 
    % CR
    app.accuracy.Text = num2str(session.accuracy(trial_i));
    % rule A CR
    app.Aaccuracy.Text = num2str(session.Aaccuracy(trial_i));
    % rule B CR
    app.Baccuracy.Text = num2str(session.Baccuracy(trial_i));
    % D prime
    app.dprime.Text = num2str(session.dprime(trial_i));

    marker = [];

%     yyaxis(app.UIAxes, 'left');
    switch session.rule{trial_i}
        case 'A'
            marker = 'o';
        case 'B'
            marker = 's';
        case 'C'
            marker = 'd';
    end

    if session.correct(trial_i) == 1 % correct trial
        scatter(app.smallPlot, trial_i, Init.trialTypeDir(trial_i), ...
            'Marker', marker,'MarkerFaceColor','#4CB5F5','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5]);
    elseif isnan(session.correct(trial_i)) 
        scatter(app.smallPlot, trial_i, Init.trialTypeDir(trial_i), ...
            'Marker', marker,'MarkerFaceColor','#050505','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5]);
    else% incorrect trial
        scatter(app.smallPlot, trial_i, Init.trialTypeDir(trial_i), ...
            'Marker', marker,'MarkerFaceColor','#F52549','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5]);
    end

    scatter(app.smallPlot, trial_i+20, Init.trialTypeDir(trial_i+20), ...
        'Marker', marker,'MarkerEdgeColor',[.5 .5 .5],'SizeData', 70,...
        'LineWidth', 2);

    if isfield(session, 'repetitionReducedTrial')
        xlimLowerbound = session.repetitionReducedTrial(end);
    else
        xlimLowerbound = session.switchTrial;
    end 

    idx = trial_i - xlimLowerbound;
    max_trials_showing = 120;
    future_trials_showing = 10;
    start_compressing_trial = 50;
    
    if (idx + future_trials_showing <= max_trials_showing) && ...
        (idx + future_trials_showing > start_compressing_trial)
        app.smallPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];
    end

    if idx + future_trials_showing > max_trials_showing
        app.smallPlot.XLim = [trial_i - max_trials_showing + future_trials_showing trial_i + future_trials_showing];
    end

    cla(app.accuPlot);
    plot(app.accuPlot, 1: trial_i, session.accuracy(1:trial_i), '-o', 'Color', '#00b000', 'LineWidth', 2, 'DisplayName', 'Accuracy');
    plot(app.accuPlot, 1: trial_i, session.dprime(1:trial_i), '-o', 'Color', '#ad0000', 'LineWidth', 2, 'DisplayName', 'D-prime');
    
    idx = trial_i - xlimLowerbound;
    max_trials_showing = 80;
    future_trials_showing = 5;
    start_compressing_trial = 50;
    % compressing the plot
    if (idx + future_trials_showing <= max_trials_showing) && ...
        (idx + future_trials_showing > start_compressing_trial)
        app.accuPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];   
    end
    % move the plot to the right
    if idx + future_trials_showing > max_trials_showing
        app.accuPlot.XLim = [trial_i - max_trials_showing + future_trials_showing trial_i + future_trials_showing];
    end
    % legend(app.accuPlot, 'show');
end