function CC_init_lickratePlot(session, Info, app, trial_i)           
    %% plotting anticipatory lick rate
    cla(app.bigPlot);
    app.bigPlot.YLabel.String = 'Anticipatory lick rate (Hz)';
    app.bigPlot.YTick = [0 2 4 6 8 10];  % lick rate
    app.bigPlot.YLim = [0 10];
    app.bigPlot.XLabel.String = 'Trial number';
    app.bigPlot.XTick = 0 : 5 : 1000; 
    app.bigPlot.XTickLabel = string(app.bigPlot.XTick); % Ensure labels match 
    app.bigPlot.XLim = [trial_i-1 trial_i+39];

    app.bigPlot.FontName = 'Arial';
    app.bigPlot.FontSize = 20;
    app.bigPlot.Title.String = [Info.session.date, ' ', Info.session.animalID, '  Repetition: ', num2str(session.repetition)];
    app.bigPlot.Title.Color = [0.1    0.1    0.1];
end