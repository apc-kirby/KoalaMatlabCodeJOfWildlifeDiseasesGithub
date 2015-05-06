function reversalTimes = calculateReversalTimes(recordsVaccine, ntile)

% reversalTimes = calculateReversalTimes(recordsVaccine, ntile)
% Returns the 'reversal time', i.e., the time at which a time course is
% considered to go from descending to ascending, for all interventions.
% The time course is a % (smoothed) pointwise quantile of the simulations 
% for the intervention in question.
%
% recordsVaccine: Intervention results.
% ntile: Quantile for which results are wanted.
%
% reversalTimes: 'Reversal times' for all the interventions.

scenarioNums = unique(recordsVaccine.popRecordMatrix(:,1));
nScenarios = length(scenarioNums);
reversalTimes = double([scenarioNums -99+zeros(nScenarios,1)]);
for indScenario = 1:nScenarios
    if mod(indScenario, 100) == 0
        disp(['Calculating reversal times for scenario ' num2str(indScenario) ' of ' num2str(nScenarios) '...'])
    end
    thisScenario = scenarioNums(indScenario);
    reversalTimes(indScenario,2) = getReversalTimeForOneScenario(recordsVaccine, thisScenario, ntile);
end

end