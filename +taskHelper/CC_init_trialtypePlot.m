function CC_init_trialtypePlot(Info, Init, app, trial_i)           
    %% plotting trial type (R, P, RO, PO, N)
    cla(app.smallPlot);
    idx = trial_i:trial_i+19;
    switch Init.rule{trial_i}
        case 'H_GO' % gray outline
            scatter(app.smallPlot, idx, Init.CStypeDir(idx),'Marker','o', ...
                'MarkerEdgeColor',[.5 .5 .5], 'SizeData',70, 'LineWidth', 2);
        case 'L_GO'
            scatter(app.smallPlot, idx, Init.CStypeDir(idx),'Marker','square', ...
                'MarkerEdgeColor',[.5 .5 .5], 'SizeData',70, 'LineWidth', 2);
    end
    app.smallPlot.YLabel.String = 'Trial type';
    app.smallPlot.YTick = [0 1];
    app.smallPlot.YTickLabel = {'N','R'};
    app.smallPlot.YLim = [-0.5 1.5];

    app.smallPlot.XLabel.String = 'Trial number';
    % app.smallPlot.XTick = 0 : 10 : 1000; 
    app.smallPlot.XTickLabel = string(app.smallPlot.XTick); % Ensure labels match 
    app.smallPlot.XLim = [trial_i-1 trial_i+49];    

    app.smallPlot.FontName = 'Arial';
    app.smallPlot.FontSize = 20;
    app.smallPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, '  Trial Type'];
    app.smallPlot.Title.Color = [0.1    0.1    0.1];
end