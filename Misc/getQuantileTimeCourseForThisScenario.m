function smoothedQuantileTimeCourseForThisScenario = getQuantileTimeCourseForThisScenario(recordsVaccine, thisScenario, ntile)

% smoothedQuantileTimeCourseForThisScenario = getQuantileTimeCourseForThisScenario(recordsVaccine, thisScenario, ntile)
% From a set of simulation results for an intervention, returns a smoothed
% pointwise n-tile.
%
% recordsVaccine: Intervention results.
% thisScenario: ID of intervention for which results are wanted.
% ntile: Pointwise quantile to be returned.
%
% smoothedQuantileTimeCourseForThisScenario: Smoothed quantile time course
% for intervention for which results are wanted.

smoothWindow = 12;
timeCoursesForThisScenario = single( ...
    recordsVaccine.popRecordMatrix(recordsVaccine.popRecordMatrix(:,1)==thisScenario, 3:end)   );
quantileTimeCourseForThisScenario = prctile(timeCoursesForThisScenario, ntile);
smoothedQuantileTimeCourseForThisScenario = [smooth(quantileTimeCourseForThisScenario(1:(end-1)), smoothWindow)];
end