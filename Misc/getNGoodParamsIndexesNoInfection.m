function n = getNGoodParamsIndexesNoInfection(resultsNum)

% n = getNGoodParamsIndexesNoInfection(resultsNum)
% Returns the number of simulations that passed demographic calibration.
% 
% resultsNum: ID of the results.
%
% n: Number of simulations that passed demographic calibration.

goodParamsIndexesNoInfection = csvread([getResultsDir() 'goodParamsIndexesNoInfection' num2str(resultsNum) '.csv']);
if size(goodParamsIndexesNoInfection, 2) == 1
    n = length(goodParamsIndexesNoInfection);
else
    error('goodParamsIndexesNoInfection*.csv has wrong number of columns (should be 1).');
end
end