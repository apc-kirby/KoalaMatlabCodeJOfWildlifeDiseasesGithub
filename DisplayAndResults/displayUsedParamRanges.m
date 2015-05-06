function displayUsedParamRanges(recordsVaccine_normalAll)

% displayUsedParamRanges(recordsVaccine_normalAll)
% Displays the parts of the parameter ranges that passed calibration and
% were used in the intervention simulations.
%
% recordsVaccine_normalAll: Intervention results.

baseParams = getBaseParamsAndSetPath();

reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams);

disp(['Loading model parameter file: ' baseParams.paramsFile])
[paramsData,paramsTextdata] = importfile1(baseParams.paramsFile);
[fields,mins,maxes] = setupParamsAsArrays(paramsData,paramsTextdata);
fields = cat(2, fields, {'randomSeed','reprodSuccessCurveNumber'});
mins = cat(2, mins, [1 1]);
maxes = cat(2, maxes, [baseParams.randSeedMax size(reproductiveSuccessStruct.weightTrackParamADistn, 1)]);
disp('Loading pre-generated parameter sets for vaccine sims (all parameters)...')
paramsStruct = importParams([baseParams.paramSetsBeforeInfectionFile '.csv'], [baseParams.paramsFieldNamesFile '.xlsx']);
paramsStruct.paramsWithoutRanges = getParamsWithoutRanges(fields,mins,maxes);
disp('Loaded pre-generated parameter sets.')

disp('Loading pre-run good params indexes...')
% Import pre-determined goodParamsIndexes
load([getResultsDir() baseParams.chosenParamsIndexesForVaccineFile '.mat']); % Variable is chosenGoodParamsIndexes
allGoodParamsIndexes = chosenGoodParamsIndexes;
disp(['Loaded ' num2str(length(allGoodParamsIndexes)) ' pre-run good params indexes.']);
goodParamsIndexes = allGoodParamsIndexes;

for indParam = 1:length(paramsStruct.paramsFieldNames)
    disp(['Param ' num2str(indParam) ' is ' paramsStruct.paramsFieldNames{indParam} '. Range is ' ...
        num2str(min(paramsStruct.paramsMatrix(goodParamsIndexes, indParam))) ' - ' ...
        num2str(max(paramsStruct.paramsMatrix(goodParamsIndexes, indParam))) '.']);
end
disp(['Saving parameter sets and population sizes for use in SaSAT...'])
% Output the parameter sets in Excel format so sensitivity analysis can be
% run in SaSAT.
xlswrite([baseParams.resultsDir 'sasatSamples.xls'], paramsStruct.paramsFieldNames, ['A1:' char(length(paramsStruct.paramsFieldNames)+64) '1']);
xlswrite([baseParams.resultsDir 'sasatSamples.xls'], paramsStruct.paramsMatrix(goodParamsIndexes, :), ...
    ['A2:' char(length(paramsStruct.paramsFieldNames)+64) num2str(1+length(goodParamsIndexes))]);
% Output the results in Excel format so sensitivity analysis can be run in
% SaSAT.
monthInQuestion = 12*20;
filterNoVaccineScenarios = recordsVaccine_normalAll.popRecordMatrix(:,1) == 0;
goodParamsPopAtMonthInQuestion = recordsVaccine_normalAll.popRecordMatrix(filterNoVaccineScenarios, 2+monthInQuestion);
xlswrite([baseParams.resultsDir 'sasatOutput.xls'], 'Output', ['A1:A1']);
xlswrite([baseParams.resultsDir 'sasatOutput.xls'], goodParamsPopAtMonthInQuestion, ...
    ['A2:A' num2str(1+length(goodParamsIndexes))]);
disp(['Finished saving.'])
end