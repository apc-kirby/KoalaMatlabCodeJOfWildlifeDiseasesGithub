function reversalMonth = getReversalTimeForOneScenario(recordsVaccine, thisScenario, ntile)

% reversalMonth = getReversalTimeForOneScenario(recordsVaccine, thisScenario, ntile)
% Returns the 'reversal time', i.e., the time at which a time course is
% considered to go from descending to ascending. The time course is a
% (smoothed) pointwise quantile of the simulations for the intervention in question.
%
% recordsVaccine: Intervention results.
% thisScenario: ID of intervention for which results are wanted.
% ntile: Quantile for which results are wanted.
%
% reversalMonth: Month at which 'reversal' occurs.

increaseRequiredForReversal = 1.2;
quantileTimeCourseForThisScenario = getQuantileTimeCourseForThisScenario(recordsVaccine, thisScenario, ntile);
[minOfQuantileTimeCourseForThisScenario, indexOfMin] = min(quantileTimeCourseForThisScenario);
if any(quantileTimeCourseForThisScenario((indexOfMin+1):end) >= minOfQuantileTimeCourseForThisScenario * increaseRequiredForReversal)
    reversalMonth = indexOfMin;
else
    reversalMonth = NaN;
end

end