function GNG_drawAccuracy_init(Info, app, trial_i)    
    %% plotting accuracy
    app.accuPlot.YLabel.String = 'Accuracy/D-prime';
    app.accuPlot.YTick = [-2 -1 0 1 2];  % lick rate
    app.accuPlot.YLim = [-2 2];
    app.accuPlot.XLabel.String = 'Trial number';
    app.accuPlot.XTick = 0 : 10 : 1000; 
    app.accuPlot.XTickLabel = string(app.accuPlot.XTick); % Ensure labels match 
    app.accuPlot.XLim = [trial_i-1 trial_i+39];

    app.accuPlot.FontName = 'Arial';
    app.accuPlot.FontSize = 20;
    app.accuPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, '  Accuracy/D-prime'];
    app.accuPlot.Title.Color = [0.1    0.1    0.1];
end