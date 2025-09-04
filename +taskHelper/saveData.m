function saveData(session, Info, Init)
    removeLastFolderIfEmpty(Info);
    Info = makedir_session(Info);

    Info.mainARDU.Port = Info.ARDU.Port; % e.g., 'COM11'
    Info.mainARDU.BaudRate = Info.ARDU.BaudRate; % e.g., 9600
    % Info.DAQARDU.Port = DAQ.ARDU_COM;
    % Info.DAQARDU.BaudRate = DAQ.ARDU_baudrate;    
    Info = rmfield(Info, 'ARDU');
    Info = rmfield(Info, 'servo');
    % save mat
    session.Info = Info;
    session.Init = Init;
    % saving the augmented session struct into a .mat file
    save(fullfile(Info.path.dataSession, strcat(Info.session.name, '.mat')), 'session');
    disp(['Saved data to: ', strcat(Info.session.name, '.mat')])
    saveByAnimal(session, Info);
    saveLickFigure(session, Info);
    disp('===============================================')
end

function saveByAnimal(session, Info)
    animalDir = fullfile(Info.path.animalData, Info.session.animalID);
    if ~isfolder(animalDir)
        mkdir(animalDir);
    end
    save(fullfile(animalDir, strcat(Info.session.name, '.mat')), 'session');
    disp(['Saved data to animal folder: ', Info.session.animalID])
end

function [sessionNum_str] = getSessionNum(Info)
    % number of session is determined by how many session has been
    % performed on the same day, each session will get a unique
    % identifier: yyyy-MM-dd-XX
    date = datetime('now','Format','yyyy-MM-dd');
    date = char(date);
    dataFolders = dir(Info.path.data);
    dataFolders = dataFolders([dataFolders.isdir]);  % only directories
    sessionNames = {dataFolders.name};
    n_session = sum(contains(sessionNames, date)) + 1;
    sessionNum_str = sprintf('%02d', n_session);
end

function Info = makedir_session(Info)            
    % Check if data folder exist; if not, make dir
    dataFolderPath = Info.path.data;
    isfolder(dataFolderPath)
    if isfolder(dataFolderPath) == 0
        mkdir(dataFolderPath);
    end
    
    sessionNum_str = getSessionNum(Info);
    
    date = datetime('now','Format','yyyy-MM-dd');
    date = char(date);
    animalID = Info.session.animalID;
    Info.session.ID = [date, '-', num2str(sessionNum_str)];
    if ~Info.session.motorConnection
        nameMain = [Info.session.ID, '-', animalID, '-', Info.session.taskName, '-', Info.session.rule, '-stillPort'];
    else
        nameMain = [Info.session.ID, '-', animalID, '-', Info.session.taskName, '-', Info.session.rule];
    end 
    % yyyy-MM-dd-0X-WAXX-rev_audigonogo_recording-mPFC-active

    switch Info.session.recording
        case 'yes'
            nameMain = [nameMain, '-record'];
    end

    Info.session.name = nameMain;
    % Create session folder
    Info.path.dataSession = fullfile(dataFolderPath, nameMain);
    mkdir(Info.path.dataSession)
    disp(['Created folder: ', Info.session.name])
end

function removeLastFolderIfEmpty(Info)
    % Check if data folder exist; if not, make dir
    dataFolderPath = Info.path.data;
    isfolder(dataFolderPath)
    if isfolder(dataFolderPath) == 0
        mkdir(dataFolderPath);
    end
    lastSessionNum = str2num(getSessionNum(Info)) - 1;
    lastSessionNum = sprintf('%02d', lastSessionNum);

    date = datetime('now','Format','yyyy-MM-dd');
    date = char(date);
    lastSessionID = [date, '-', num2str(lastSessionNum)];

    % if no mat file is saved, remove the empty folder
    sessions = dir(dataFolderPath);
    sessionNames = {sessions.name};

    isLastSession = contains(sessionNames, lastSessionID);
    lastSessionFolder = sessionNames(isLastSession);
    lastSessionFolderPath = fullfile(dataFolderPath, lastSessionFolder);
    if isfolder(lastSessionFolderPath)
        % have to use {1} to get the element
        contents = dir(lastSessionFolderPath{1});
        isLastSessionMatFile = contains({contents.name}, lastSessionID);
        if sum(isLastSessionMatFile) == 0 % does not contain the mat file
            rmdir(lastSessionFolderPath{1}, 's');
            disp(['Removed folder: ', lastSessionID])   
        end
    end
end

function saveLickFigure(session, Info)
    %% Lick plot
    lickTimes = cellfun(@(x) x ./ 1000, session.event.lick_times, 'UniformOutput', false);
    waterOnTimes = session.event.water/1000; % water onset
    airpuffOnTimes = session.event.airpuff/1000; % airpuff onset
    USonTimes = waterOnTimes;
    USonTimes(isnan(waterOnTimes)) = airpuffOnTimes(isnan(waterOnTimes));
    portOnTimes = session.event.port_on/1000; % port on onset
    soundOnTimes = session.event.sound/1000; % sound onset
    onsetTimes = soundOnTimes;
    window = [-1, 5]; % Time window relative to sound onset (e.g., -1s before to +5s after)
    windowSize = 0.1; % 100ms window

    % stepSize = 1/FramRate; % 100-ms step size
    edges = window(1):windowSize:window(2); % Time bins
    timepoints = edges(1:end-1) + windowSize/2; % Bin centers
    lickRateMatrix = NaN(length(USonTimes), length(edges)-1); % Preallocate lick rate matrix
    anticipatoryLickRateAve = NaN(length(USonTimes), 1);
    resultLickRateAve = NaN(length(USonTimes), 1);
    for i = 1:length(USonTimes) % iterate over each trial
        anticipatoryLickRateAve(i) = sum(lickTimes{i} >= portOnTimes(i) & lickTimes{i} < portOnTimes(i) + 0.5) / 0.5; % 0.5 second after port on
        resultLickRateAve(i) = sum(lickTimes{i} >= USonTimes(i) & lickTimes{i} < USonTimes(i) + 0.5) / 0.5; % 0.5 second after US on
        % Apply moving window
        for j = 1:length(edges)-1
            % Find licks within the 1-second window
            binStartTime = onsetTimes(i) + edges(j);
            binEndTime = binStartTime + windowSize;
            lickRateMatrix(i, j) = sum(lickTimes{i} >= binStartTime & lickTimes{i} < binEndTime);
        end
    end

    isRewarded = contains(session.trialType, {'R', 'P'}); 
    isNeutral = contains(session.trialType, 'N');
    % comparing the lick rate 0.5s after the tone onset and the water delivery for rewarded and neutral trials
    % [~, pRewarded] = ttest(mean(anticipatoryLickRateAve(isRewarded)), mean(resultLickRateAve(isRewarded)));
    % [~, pNeutral] = ttest(mean(anticipatoryLickRateAve(isNeutral)), mean(resultLickRateAve(isNeutral)));

    meanRewarded = mean(lickRateMatrix(isRewarded, :), 1) / windowSize; % Normalize by window size
    stdRewarded = (std(lickRateMatrix(isRewarded, :), 1) / sqrt(sum(isRewarded)))/ windowSize;
    meanNeutral = mean(lickRateMatrix(isNeutral, :), 1) / windowSize; % Normalize by window size
    stdNeutral = (std(lickRateMatrix(isNeutral, :), 1) / sqrt(sum(isNeutral)))/ windowSize;

    [~, pAnticipatory] = ttest2(anticipatoryLickRateAve(isRewarded), anticipatoryLickRateAve(isNeutral));
    
    fHandle = figure('PaperUnits','Centimeters','PaperPosition',[2 2 8 6]);
    % plot rewarded trials
    fill([timepoints, flip(timepoints)],[meanRewarded+stdRewarded, flip(meanRewarded-stdRewarded)], '-b','EdgeColor','none');
    alpha(0.4);
    hold on;
    plot(timepoints, meanRewarded, '-b', 'LineWidth',1);
    % plot neutral trials
    fill([timepoints, flip(timepoints)],[meanNeutral+stdNeutral, flip(meanNeutral-stdNeutral)], '-k','EdgeColor','none'); 
    alpha(0.4);
    hold on;
    plot(timepoints, meanNeutral, '-k', 'LineWidth',1);

    xline(mean(soundOnTimes), 'r--', 'LineWidth', 1, 'DisplayName', 'Sound onset'); % red vertical line at sound onset
    xline(mean(portOnTimes), 'k--', 'LineWidth', 1, 'DisplayName', 'Port onset'); % black vertical line at port onset
    xline(mean(USonTimes), 'b--', 'LineWidth', 1, 'DisplayName', 'US onset'); % blue vertical line at US onset

    % text(3, 11,['Rewarded, p = ',mat2str(pRewarded, 2)], 'color', 'blue','FontSize', 6)
    % text(3, 10,['Neutral, p = ',mat2str(pNeutral, 2)], 'color', 'black','FontSize', 6)
    text(4, 10, ['p = ', mat2str(pAnticipatory, 2)], 'color', 'black','FontSize', 6)
    
    set(gca,'TickDir','out','box','off','FontSize', 6,...
        'xlim',[mean(onsetTimes)+window(1) mean(onsetTimes)+window(2)], ...
        'xtick',[mean(onsetTimes)+window(1):1:mean(onsetTimes)+window(2)], ...
        'ylim', [0 12], ...
        'ytick', [0:4:12], ...
        'xticklabel',[window(1):1:window(2)]);
    xlabel('Time from cue (s)','FontSize', 8)
    ylabel('Lick rate (Hz)','FontSize', 8)

    if session.motorConnection
        title('Movable port')
    else
        title('Still port')
    end
    animalDir = fullfile(Info.path.animalData, Info.session.animalID);
    saveas(fHandle, fullfile(animalDir, strcat(Info.session.name, '-lickRate.png')));
    disp('Saved figure to animal folder.')
    % close(fHandle);
end

