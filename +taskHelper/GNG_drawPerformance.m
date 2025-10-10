function GNG_drawPerformance(session, trial_i, app, Init)
    % trial num
    app.trialNum.Text = num2str(trial_i); 
    % CR
    app.accuracy.Text = num2str(session.accuracy(trial_i));
    % D prime
    app.dprime.Text = num2str(session.dprime(trial_i));

    switch session.rule{trial_i}
        case 'H_GO'
            marker = 'o';
            trialTypes = Init.trialTypeDir(trial_i);
        case 'L_GO'
            marker = 'square';
            trialTypes = -Init.trialTypeDir(trial_i);
        otherwise
            marker = 'diamond';
    end

    % disp(['marker: ', marker]);
    alphaData = abs(trialTypes)/range(Init.trialTypeDir)*2;

    if session.correct(trial_i) == 1 % correct trial
        scatter(app.smallPlot, trial_i, trialTypes/abs(trialTypes), ...
            'Marker', marker,'MarkerFaceColor','#4CB5F5','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5], ...
            'MarkerFaceAlpha', alphaData);
    elseif isnan(session.correct(trial_i)) 
        scatter(app.smallPlot, trial_i, trialTypes/abs(trialTypes), ...
            'Marker', marker,'MarkerFaceColor','#050505','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5], ...
            'MarkerFaceAlpha', alphaData);
    else% incorrect trial
        scatter(app.smallPlot, trial_i, trialTypes/abs(trialTypes), ...
            'Marker', marker,'MarkerFaceColor','#F52549','SizeData',70,...
            'LineWidth', 0.5, 'MarkerEdgeColor',[.5 .5 .5], ...
            'MarkerFaceAlpha', alphaData);    
    end

    scatter(app.smallPlot, trial_i + 20, Init.trialTypeDir(trial_i + 20)/abs(Init.trialTypeDir(trial_i + 20)), ...
        'Marker', marker,'MarkerEdgeColor',[.5 .5 .5],'SizeData', 70,...
        'LineWidth', 2);
        

    if isfield(session, 'repetitionReducedTrial')
        xlimLowerbound = session.repetitionReducedTrial(end);
    else
        xlimLowerbound = session.switchTrial;
    end 

    idx = trial_i - xlimLowerbound;
    max_trials_showing = 80;
    future_trials_showing = 5;
    start_compressing_trial = 50;
    
    if (idx + future_trials_showing <= max_trials_showing) && ...
        (idx + future_trials_showing > start_compressing_trial)
        app.smallPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];
    end

    if idx + future_trials_showing > max_trials_showing
        app.smallPlot.XLim = [trial_i - max_trials_showing + future_trials_showing trial_i + future_trials_showing];
    end

    %% Update hit/FA/accuracy plot
    cla(app.bigPlot);
    plot(app.bigPlot, 1: trial_i, session.hitRate(1:trial_i), '-o', 'Color', '#0000ff', 'LineWidth', 2, 'DisplayName', 'Hit Rate'); % blue
    plot(app.bigPlot, 1: trial_i, session.faRate(1:trial_i), '-o', 'Color', '#ad0000', 'LineWidth', 2, 'DisplayName', 'FA Rate');
    plot(app.bigPlot, 1: trial_i, session.accuracy(1:trial_i), '-o', 'Color', '#00b000', 'LineWidth', 2, 'DisplayName', 'Accuracy'); % green
    legend(app.bigPlot, 'show');
    
    idx = trial_i - xlimLowerbound;
    max_trials_showing = 100;
    future_trials_showing = 10;
    start_compressing_trial = 50;
    % compressing the plot
    if (idx + future_trials_showing <= max_trials_showing) && ...
        (idx + future_trials_showing > start_compressing_trial)
        app.bigPlot.XLim = [xlimLowerbound trial_i + future_trials_showing];   
    end
    % move the plot to the right
    if idx + future_trials_showing > max_trials_showing
        app.bigPlot.XLim = [trial_i - max_trials_showing + future_trials_showing trial_i + future_trials_showing];
    end
    % legend(app.accuPlot, 'show');
end