function GNG_drawTrialCurrent(Init, trial_i, app)   
    %% Plotting trial type
    marker = [];
    switch Init.rule{trial_i}
        case 'A'
            marker = 'o';   
        case 'B'
            marker = 's';
        case 'C'
            marker = 'd';
    end
    scatter(app.smallPlot, trial_i, Init.trialTypeDir(trial_i), 'Marker', marker, ...
            'MarkerEdgeColor', [.5 .5 .5], 'SizeData', 70, 'LineWidth', 4);
end