% recalcLHSSamplesForInfectionParams
% After demographic calibration, N of the parameter sets will have been
% retained and others discarded. Since the infection parameters have not
% been used at this point, this script generates N new infection parameter
% sets using Latin hypercube sampling and combines them with the
% N demographic parameter sets that passed demographic calibration.

baseParams = getBaseParamsAndSetPath();
reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams);

disp(['Loading model parameter file: ' baseParams.paramsFile])
[paramsData,paramsTextdata] = importfile1(baseParams.paramsFile);
[fields,mins,maxes] = setupParamsAsArrays(paramsData,paramsTextdata);
fields = cat(2, fields, {'randomSeed','reprodSuccessCurveNumber'});
mins = cat(2, mins, [1 1]);
maxes = cat(2, maxes, [baseParams.randSeedMax size(reproductiveSuccessStruct.weightTrackParamADistn, 1)]);

disp(['Loading pre-generated parameter sets...'])
paramsStruct = importParams([baseParams.paramSetsBeforeInfectionFile '.csv'], [baseParams.paramsFieldNamesFile '.xlsx']);
paramsStruct.paramsWithoutRanges = getParamsWithoutRanges(fields,mins,maxes);
disp('Loaded pre-generated parameter sets.')
if size(paramsStruct.paramsMatrix,1) ~= baseParams.numberOfParameterSetsPerScenarioAllMachines
    error('Number of rows of paramsStruct.paramsMatrix does not equal baseParams.numberOfParameterSetsPerScenarioAllMachines.')
end

allGoodParamsIndexesNoInfection = csvreadFromResultsDir([baseParams.prerunGoodParamsIndexesNoInfectionFile '.csv']);
disp(['Loaded ' num2str(length(allGoodParamsIndexesNoInfection)) ' pre-run good params indexes (no infection).']);

disp('Re-calculating Latin hypercube samples for infection parameters...')
[paramsFieldNames,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,paramsWithoutRanges] = generateParamsStructBasics(fields,mins,maxes);
paramsStruct.paramsMatrix = updateParamsMatrix(paramsStruct,minsInOrderOfFieldNames,maxesInOrderOfFieldNames, ...
    baseParams.nonInfectionParams,allGoodParamsIndexesNoInfection);

disp('Re-calculated samples for infection parameters.')
disp('Saving re-calculated samples...')
ticSaving = tic;
csvwrite([getResultsDir() baseParams.paramSetsInfectionParamsUpdatedFile '.csv'], paramsStruct.paramsMatrix);
disp(['Saved re-calculated samples. Took ' num2str(toc(ticSaving)) ' seconds.'])