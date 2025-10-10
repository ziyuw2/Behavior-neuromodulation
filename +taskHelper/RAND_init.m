function [Init] = RAND_init(Info)    
    % To generate block trials or reward and punishment balanced pseudo-random trials
    % Then assign sound to the trials based on the rule
    % Lastly generate delay and ITI
    % Init Stuct contains:
    %   nTrials: number of trials
    %   switchThreshold: number of trials after which the rule is switched
    %   iti: inter-trial interval
    %   rule: rule of the trials
    %   CStypeDir: type of the trials
    %   tone: tone of the trials
    %   trialType: type of the trials
    Init = struct();
    Init.nTrials = 960;
    
    % Init.switchThreshold = randi([Info.taskparam.switchThreshold(1), Info.taskparam.switchThreshold(2)]); % 140, 150

    %% Generate port delay, water delay and ITI
    if length(Info.taskparam.iti) == 2
        Init.iti = rand(Init.nTrials, 1) * (Info.taskparam.iti(2) - Info.taskparam.iti(1)) + Info.taskparam.iti(1);
    else
        Init.iti = ones(Init.nTrials, 1)* Info.taskparam.iti;
    end
    end