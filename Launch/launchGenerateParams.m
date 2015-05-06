% launchGenerateParams
% Generates samples from the parameter space, to be used in calibration.
% The samples are saved in files.

baseParams = getBaseParamsAndSetPath();

reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams);

disp(['Loading model parameter file: ' baseParams.paramsFile])
[paramsData,paramsTextdata] = importfile1(baseParams.paramsFile);
[fields,mins,maxes] = setupParamsAsArrays(paramsData,paramsTextdata);
fields = cat(2, fields, {'randomSeed','reprodSuccessCurveNumber'});
mins = cat(2, mins, [1 1]);
maxes = cat(2, maxes, [baseParams.randSeedMax size(reproductiveSuccessStruct.weightTrackParamADistn, 1)]);


if length(union(baseParams.nonInfectionParams, baseParams.infectionParams)) ~= length(fields) || ~isempty(intersect(baseParams.nonInfectionParams, baseParams.infectionParams))
    error('Either a param name is specified as being both an infection and non-infection param, or a param is not specified as either.');
end

ticGeneratingParamSets = tic;
disp(['Generating ' num2str(baseParams.numberOfParameterSetsPerScenarioAllMachines) ' parameter sets...'])
[paramsFieldNames,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,paramsWithoutRanges] = generateParamsStructBasics(fields,mins,maxes);
paramsMatrix = generateParamsMatrix(fields,mins,maxes,baseParams.numberOfParameterSetsPerScenarioAllMachines,baseParams.integerFieldsWithRanges);
paramsStruct.paramsMatrix = paramsMatrix;
paramsStruct.paramsFieldNames = paramsFieldNames;
paramsStruct.paramsIndices = getParamIndices(paramsFieldNames);
paramsStruct.paramsWithoutRanges = paramsWithoutRanges;
disp(['Parameter sets generated. Took ' num2str(toc(ticGeneratingParamSets)) ' seconds.'])
disp('Saving parameter sets...')
ticSaving = tic;
csvwrite([baseParams.resultsDir baseParams.paramSetsBeforeInfectionFile '.csv'], paramsMatrix);
disp(['Saved parameter sets. Took ' num2str(toc(ticSaving)) ' seconds.'])
disp('Saving field names...')
ticSaving = tic;
xlswrite([baseParams.resultsDir baseParams.paramsFieldNamesFile '.xlsx'], paramsFieldNames, 'VersionForImport');
disp(['Saved field names. Took ' num2str(toc(ticSaving)) ' seconds.'])
