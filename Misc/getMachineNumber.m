function [thisMachineNum, fromParamSetNum, toParamSetNum, numberOfParameterSetsPerScenario] = getMachineNumber(baseParams)

% [thisMachineNum, fromParamSetNum, toParamSetNum, numberOfParameterSetsPerScenario] = getMachineNumber(baseParams)
% Identifies the numbers of the parameter sets that should be run on this computer.
%
% baseParams: Struct of the simulation 'metaparameters'.
%
% thisMachineNum: Number of this particular computer, out of all the
% computers on which simulations are being run.
% fromParamSetNum: Number of the first parameter set to be simulated on this
% computer.
% toParamSetNum: Number of the last parameter set to be simulated on this
% computer.
% numberOfParameterSetsPerScenario: Total number of parameter sets to be
% simulated on this computer.

    [~, thisMachineName] = dos('hostname');
    cleanedMachineName = strrep(strtrim(thisMachineName),'-','_'); % Machines may have a '-' in their names, but in that case they can't be used as field names.
    thisMachineNum = baseParams.thisMachine.(cleanedMachineName);
    fromParamSetNum = baseParams.thisMachineFromParamSet(thisMachineNum);
    toParamSetNum = baseParams.thisMachineToParamSet(thisMachineNum);
    numberOfParameterSetsPerScenario = toParamSetNum - fromParamSetNum + 1;
    disp(['This is machine number ' num2str(thisMachineNum)]);
end