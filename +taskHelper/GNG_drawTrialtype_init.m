function GNG_drawTrialtype_init(Info, Init, app, trial_i)           
    cla(app.smallPlot);
    % cla(app.smallPlot);
    idx = trial_i:trial_i+19;

    switch Init.rule{trial_i}
        case 'H_GO'
            marker = 'o';
            tiralTypes = Init.trialTypeDir(idx)./abs(Init.trialTypeDir(idx));
        case 'L_GO'
            marker = 'square';
            tiralTypes = -Init.trialTypeDir(idx)./abs(Init.trialTypeDir(idx));
        otherwise
            marker = 'diamond';
            tiralTypes = Init.trialTypeDir(idx)./abs(Init.trialTypeDir(idx));
    end
    scatter(app.smallPlot, idx, tiralTypes, 'Marker',marker, ...
        'MarkerEdgeColor',[.5 .5 .5], 'SizeData',70, 'LineWidth', 2);
   
    app.smallPlot.YLabel.String = 'Trial type';
    app.smallPlot.YTick = [-1 1];
    app.smallPlot.YTickLabel = {'NOGO', 'GO'};
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