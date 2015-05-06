function [fromParamSets, toParamSets] = getSuggestedParamSetsByMachine(nParamSets, nMachines)

% [fromParamSets, toParamSets] = getSuggestedParamSetsByMachine(nParamSets, nMachines)
% Suggests the parameter sets that should be run by each computer, given 
% the total number of parameter sets and the number of computers between 
% which they are divided, such that each computer runs roughly the same number.
%
% nParamSets: Total number of parameter sets to be run.
% nMachines: Number of computers over which simulations will be run.
%
% fromParamSets: Vector of first parameter sets for each computer.
% toParamSets: Vector of last parameter sets for each computer.

fromParamSets = round([1 (1:(nMachines-1)) * nParamSets / nMachines]);
toParamSets = [fromParamSets(2:end)-1 nParamSets];
paramSetsByMachine = toParamSets - fromParamSets + 1;
if sum(paramSetsByMachine) ~= nParamSets
   error('Total number of param sets by machine does not equal required number of param sets.') 
end
end

