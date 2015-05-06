function scenarioSuccesses = calculationReversalProportions(recordsVaccine, yearInQuestion)

% scenarioSuccesses = calculationReversalProportions(recordsVaccine, yearInQuestion)
% Returns the proportion of simulations for which the population decline
% 'reversed' (i.e., went from descending to ascending), for each
% intervetion.
%
% recordsVaccine: Intervention results.
% yearInQuestion: Year by which reversal must have occurred.
%
% scenarioSuccesses: Proportion of simulations for which population decline
% reversed, for each intervention.

smoothWindow = 12;
increaseRequiredForReversal = 1.2;
monthInQuestion = yearInQuestion * 12;
nSims = size(recordsVaccine.popRecordMatrix,1);
reversalMonth = nan(nSims,1);
% Find reversal times of each sim.
for indSim = 1:nSims
    if mod(indSim, 1000) == 1
        disp(['Finding reversal time of SIMULATION ' num2str(indSim) ' of ' num2str(nSims) '...'])
    end
    timeCourse = double(recordsVaccine.popRecordMatrix(indSim, 3:(end-1))); % end-1 because last column is just zeros.
    smoothedTimeCourse = smooth(timeCourse, smoothWindow);
    [minOfSmoothedTimeCourse, indexOfMin] = min(smoothedTimeCourse);
    if any(timeCourse((indexOfMin+1):end) >= minOfSmoothedTimeCourse * increaseRequiredForReversal)
        reversalMonth(indSim) = indexOfMin;
    end
end
% Find proportion of reversal times that are less than year in question.
scenarioNums = unique(recordsVaccine.popRecordMatrix(:,1));
nScenarios = length(scenarioNums);
nParams = length(unique(recordsVaccine.popRecordMatrix(:,2)));
scenarioSuccesses = double([scenarioNums -99+zeros(nScenarios,1)]);
for indScenario = 1:nScenarios
    if mod(indScenario, 100) == 0
        disp(['Calculating success for scenario ' num2str(indScenario) ' of ' num2str(nScenarios) '...'])
    end
    thisScenario = scenarioNums(indScenario);
    filterThisScenario = ismember(recordsVaccine.popRecordMatrix(:,1), thisScenario);
    nSuccessesForThisScenario = sum(reversalMonth(filterThisScenario) <= monthInQuestion);
    scenarioSuccesses(indScenario,2) = nSuccessesForThisScenario / nParams;
end

end