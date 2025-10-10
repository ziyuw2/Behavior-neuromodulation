function GNG_drawAccuracy_init(Info, app, trial_i)    
    %% plotting accuracy
    app.bigPlot.YLabel.String = 'Accuracy/HIT/FA Rate';
    app.bigPlot.YTick = [0 0.25 0.5 0.75 1];  % lick rate
    app.bigPlot.YLim = [0 1];
    app.bigPlot.XLabel.String = 'Trial number';
    app.bigPlot.XTick = 0 : 10 : 1000; 
    app.bigPlot.XTickLabel = string(app.bigPlot.XTick); % Ensure labels match 
    app.bigPlot.XLim = [trial_i-1 trial_i+49];

    app.bigPlot.FontName = 'Arial';
    app.bigPlot.FontSize = 20;
    app.bigPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, '  Accuracy/HIT/FA Rate'];
    app.bigPlot.Title.Color = [0.1    0.1    0.1];
end