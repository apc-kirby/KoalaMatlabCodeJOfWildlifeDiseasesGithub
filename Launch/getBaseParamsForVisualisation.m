function baseParams = getBaseParamsForVisualisation(observedCurrentPop, outputResultsNum)

% baseParams = getBaseParamsForVisualisation(observedCurrentPop, outputResultsNum)
% Creates a slightly expanded version of the model 'metaparameters' struct.
%
% observedCurrentPop: Current real-world population size.
% outputResultsNum: ID of intervention simulations.
%
% baseParams: Model 'metaparameter' struct.
 
baseParams = getBaseParamsAndSetPath();

baseParams.checkSnapshotMonthsFromResultsAndPopSnapshotsAreSame = false;
baseParams.fontSize = 10;
baseParams.popChangeTol = 1000;
baseParams.observedCurrentPop = observedCurrentPop;
baseParams.outputResultsNum = outputResultsNum;
baseParams.monthsToRetain = 12*30;
approxCapturesPerYearAll = getApproxCapturesPerYear(baseParams.setupVaccineParamsFn);
baseParams.approxCapturesPerYear = approxCapturesPerYearAll;
baseParams.successfulScenarioParamsMatrixFileName = 'successfulScenarioParamsMatrix';

end