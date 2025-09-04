function GNG_drawTrialtype_init(Info, Init, app, trial_i)           
    cla(app.smallPlot);

    %% plotting trial type (GO, GO, NOGO)
    if Init.rule{trial_i} == 'A'
        app.smallPlot.YTickLabel = {'NOGO', 'GO', 'GO'};
    elseif Init.rule{trial_i} == 'B'
        app.smallPlot.YTickLabel = {'NOGO', 'NOGO', 'GO'};
    elseif Init.rule{trial_i} == 'C'
        app.smallPlot.YTickLabel = {'GO', 'GO', 'GO'};
    end
    % cla(app.smallPlot);
    idx = trial_i:trial_i+19;

    switch Init.rule{trial_i}
        case 'A'
            marker = 'o';
        case 'B'
            marker = 's';
        case 'C'
            marker = 'd';
    end
    
    scatter(app.smallPlot, idx, Init.trialTypeDir(idx),'Marker',marker, ...
        'MarkerEdgeColor',[.5 .5 .5], 'SizeData',70, 'LineWidth', 2);
   
    app.smallPlot.YLabel.String = 'Trial type';
    app.smallPlot.YTick = [-1 0 1];
    app.smallPlot.YLim = [-1.5 1.5];

    app.smallPlot.XLabel.String = 'Trial number';
    app.smallPlot.XTick = 0 : 10 : 1000; 
    app.smallPlot.XTickLabel = string(app.smallPlot.XTick); % Ensure labels match 
    app.smallPlot.XLim = [trial_i-1 trial_i+49];

    app.smallPlot.FontName = 'Arial';
    app.smallPlot.FontSize = 20;
    app.smallPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, '  Trial Type'];
    app.smallPlot.Title.Color = [0.1    0.1    0.1];
end