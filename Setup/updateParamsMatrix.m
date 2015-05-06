function newParamsMatrix = updateParamsMatrix(paramsStruct,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,nonInfectionParams,goodParamsIndexesNoInfection)

% newParamsMatrix = updateParamsMatrix(paramsStruct,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,nonInfectionParams,goodParamsIndexesNoInfection)
% The function that actually generates the new infection parameter samples
% and updates the parameter set matrix.
%
% paramsStruct: Struct of parameters.
% minsInOrderOfFieldNames: Parameter minima in order of field names.
% maxesInOrderOfFieldNames: Parameter maxima in order of field names.
% nonInfectionParams: Names of demographic parameters.
% goodParamsIndexesNoInfection: IDs of parameter sets that passed
% demographic calibration.
%
% newParamsMatrix: Updated parameter set matrix.

newParamsMatrix = paramsStruct.paramsMatrix;

filterNonInfectionParams = ismember(paramsStruct.paramsFieldNames,nonInfectionParams);
filterInfectionParams = ~filterNonInfectionParams;
numberOfInfectionParams = sum(filterInfectionParams);

numberOfGoodParamSets = length(goodParamsIndexesNoInfection);
lhsDesignMatrix = lhsdesign(numberOfGoodParamSets,numberOfInfectionParams);
lhsParamSets = lhsDesignMatrix * diag(maxesInOrderOfFieldNames(filterInfectionParams)-minsInOrderOfFieldNames(filterInfectionParams)) + repmat(minsInOrderOfFieldNames(filterInfectionParams),[numberOfGoodParamSets 1]);

newParamsMatrix(goodParamsIndexesNoInfection, filterInfectionParams) = lhsParamSets;


end