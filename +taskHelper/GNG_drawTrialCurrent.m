function GNG_drawTrialCurrent(Init, trial_i, app)   
    %% Plotting trial type
    switch Init.rule{trial_i}
        case 'H_GO'
            marker = 'o';   
        case 'L_GO'
            marker = 'square';
        otherwise
            marker = 'diamond';
    end
    scatter(app.smallPlot, trial_i, Init.trialTypeDir(trial_i)/abs(Init.trialTypeDir(trial_i)), 'Marker', marker, ...
            'MarkerEdgeColor', [.5 .5 .5], 'SizeData', 70, 'LineWidth', 4);
end