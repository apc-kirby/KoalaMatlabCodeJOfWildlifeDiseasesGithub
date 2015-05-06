function outputPops = adjustDatesOfPopulationSnapshots(snapshots)

% outputPops = adjustDatesOfPopulationSnapshots(snapshots)
% Population snapshots have dates for e.g., birth based on a simulation start time
% of zero. When running a new simulation, all such dates need to be
% adjusted such that the start time of the new simulation is zero. This
% function does that.
%
% snapshots: Snapshots of the population from the previous simulation.
%
% outputPops: Population snapshots with updated times.

outputPops = snapshots;

for ind = 1:length(snapshots)
    lastMonthThatWasSimulated = snapshots(ind).currentMonth;
    outputPops(ind).dob = snapshots(ind).dob - lastMonthThatWasSimulated;
    outputPops(ind).naturalDod = snapshots(ind).naturalDod - lastMonthThatWasSimulated;
    outputPops(ind).dod = snapshots(ind).dod - lastMonthThatWasSimulated;
    outputPops(ind).breedsNext = snapshots(ind).breedsNext - lastMonthThatWasSimulated;
    
    outputPops(ind).infectionEnds = snapshots(ind).infectionEnds - lastMonthThatWasSimulated;
    outputPops(ind).resistanceEnds = snapshots(ind).resistanceEnds - lastMonthThatWasSimulated;
    
    outputPops(ind).diseaseStageCEmerges = snapshots(ind).diseaseStageCEmerges - lastMonthThatWasSimulated;
    outputPops(ind).diseaseStageBEmerges = snapshots(ind).diseaseStageBEmerges - lastMonthThatWasSimulated;
    outputPops(ind).diseaseStageAEmerges = snapshots(ind).diseaseStageAEmerges - lastMonthThatWasSimulated;
    outputPops(ind).infectionStarted = snapshots(ind).infectionStarted - lastMonthThatWasSimulated;
    
end
end