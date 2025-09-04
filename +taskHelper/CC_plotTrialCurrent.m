function CC_plotTrialCurrent(Init, trial_i, app)
    %% Plotting trial type
    marker = [];
    switch Init.rule{trial_i}
        case 'H_GO' 
            marker = 'o';
        case 'L_GO'
            marker = 'square';
    end
    scatter(app.smallPlot, trial_i, Init.CStypeDir(trial_i), 'Marker', marker, ...
            'MarkerEdgeColor', [.5 .5 .5], 'SizeData', 70, 'LineWidth', 4);
end