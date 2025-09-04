function [approach, withdraw] = getMotorSteps(Info, nSteps)
approach =  linspace(Info.port.withdraw, Info.port.approach, nSteps);
if approach(end) ~= Info.port.approach
    approach(end) = Info.port.approach;
end
withdraw = fliplr(approach);
end