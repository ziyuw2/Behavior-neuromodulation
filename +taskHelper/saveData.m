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
    pause(5);
    if contains(Info.session.name, 'CC')
        saveLickFigure(session, Info);
    end
    if contains(Info.session.name, 'GNG')
        saveFigure_GNG(session, Info);
    end
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
  
% Lick rate
lickTimes = session.event.lick_times;
winRange  = [0 10];    % analysis window [start end] in sec
winSize   = 1.0;       % window size (s)
stepSize  = 0.1;       % step size (s)
% Define time bins (window centers)
tCenters = winRange(1) : stepSize : (winRange(2) - winSize);

% Preallocate matrix: trials x time
nTrials = numel(lickTimes);
lickRate = nan(nTrials, numel(tCenters));
soundT = mean(session.event.sound)/1000;
portT = mean(session.event.port_on)/1000;
outcomeT = nanmean(session.event.water)/1000;

% Compute lick rate per trial
for tr = 1:nTrials
    licks = lickTimes{tr}/1000;  % lick times in this trial

    for i = 1:numel(tCenters)
        t0 = tCenters(i);
        t1 = t0 + winSize;

        % Count licks within [t0, t1]
        nLicks = sum(licks >= t0 & licks < t1);

        % Convert to rate (Hz)
        lickRate(tr,i) = nLicks / winSize;
    end
end

% only anticipatory lick - calculated by each trials %%%%%%%%%%
lickRate2 = nan(nTrials, 1);
% Compute anticipatory lick rate 
for tr = 1:nTrials
    licks = lickTimes{tr};  % lick times in this trial
    port_on = session.event.port_on(tr);
    water_on = session.event.water(tr);
    nLicks = sum(licks>port_on & licks<water_on);
    lickRate2(tr) = nLicks/(water_on/1000-port_on/1000); 
end

clr = [0 0 1; 0 0 0];
%% Plot
RewT = strcmp(session.tone, 'H');
OmiT = strcmp(session.tone, 'L');
[h,p] = ttest2(lickRate2(RewT),lickRate2(OmiT));
TrialType = [RewT',OmiT'];
tCenters2 = tCenters+1;
fHandle = figure('PaperUnits','Centimeters','PaperPosition',[2 2 4 3]);hold on
anticipatory_lick = cell(2,1);
for iT = 1:size(TrialType,2)
    meanRate = mean(lickRate(TrialType(:,iT),:), 1, 'omitnan');
    semRate  = std(lickRate(TrialType(:,iT),:), [], 1, 'omitnan') / sqrt(sum(TrialType(:,iT)));

    anticipatory_lick{iT} = mean(lickRate(TrialType(:,iT),tCenters2>portT&tCenters2<outcomeT),2);
    % Shaded error bar (mean ± SEM)
    fill([tCenters2 fliplr(tCenters2)], ...
        [meanRate+semRate fliplr(meanRate-semRate)], ...
        clr(iT,:),'EdgeColor','none');  % light blue shading
    plot(tCenters2, meanRate, '-','color',clr(iT,:), 'LineWidth', 1);
end
alpha(0.3)

plot([soundT soundT], [-2 18],'r--','linewidth',0.5);
plot([portT portT], [-2 18],'k--','linewidth',0.5);
plot([outcomeT outcomeT], [-2 18],'b--','linewidth',0.5);
text(4.5,17,['\it{p} = ',mat2str(round(p,3),3)],'FontSize', 6)

set(gca,'TickDir','out','box','off','FontSize', 6,...
    'xlim',[0 6],'ylim',[0 18],'xtick',[soundT portT outcomeT outcomeT+1 outcomeT+2],'ytick',[0:5:15],...
    'xticklabel',[0 1 2 3 4]);
xlabel('Time form cue (s)');
ylabel('Lick rate (Hz)');

% saveas(fHandle, '2025-09-12-07-717-CC_2tone_test-H_GO-lickRate.png');

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

function saveFigure_GNG(session, Info)

    accuracy = session.accuracy;
    hitRate = session.hitRate;
    faRate = session.faRate;

    fHandle = figure('PaperUnits','Centimeters','PaperPosition',[2 2 8 6]);
    hold on;
    plot(accuracy, '-o', 'Color', '#00b000', 'LineWidth', 2, 'DisplayName', 'Accuracy');
    hold on;
    plot(hitRate, '-o', 'Color', '#0000ff', 'LineWidth', 2, 'DisplayName', 'Hit Rate');
    plot(faRate, '-o', 'Color', '#ad0000', 'LineWidth', 2, 'DisplayName', 'FA Rate');
    % legend('show');

    set(gca,'TickDir','out','box','off','FontSize', 6,...
    'ylim',[-0.2 1],'ytick', [-0.2:0.2:1]);
    xlabel('Trials');
    ylabel('Accuracy/Hit Rate/FA Rate');
    saveas(fHandle, fullfile(Info.path.animalData, Info.session.animalID, strcat(Info.session.name, '-performance.png')));
    disp('Saved figure to animal folder.');
end
    
