function [records, snapshotMonthsOfGoodParams, lastMonthsOfSims] = getUsedNoVaccineResults(baseParams)

% [records, snapshotMonthsOfGoodParams, lastMonthsOfSims] = getUsedNoVaccineResults(baseParams)
% Loads 'no intervention' results.
%
% baseParams: Model 'metaparameters'.
%
% records: 'No intervention' results.
% snapshotMonthsOfGoodParams: Months in which population snapshots were
% taken, for those parameter sets that passed calibration.
% lastMonthsOfSims: Last simulated month, for each simulation.

records.popRecordMatrix = [];
records.infRecordMatrix = [];
records.incidenceRecordMatrix = [];
records.diseasedRecordMatrix = [];
records.vaccinatedRecordMatrix = [];
records.fecundityRecordMatrix = [];
records.deathsRecordMatrix = [];
records.vaccinationRecordMatrix = [];
records.deathsByDiseaseRecordMatrix = [];
records.deathsByEuthanasiaRecordMatrix = [];
records.deathsByOtherRecordMatrix = [];
records.deathsMotherDiedRecordMatrix = [];

snapshotMonthsOfGoodParams = [];
lastMonthsOfSims = [];

load([baseParams.resultsDir() baseParams.chosenParamsIndexesForVaccineFile]); % Variable is chosenGoodParamsIndexes
disp('Loading NO VACCINE results from different machines...')
resultsFileNames = {dir([baseParams.resultsDir '\recordsNoVaccine' num2str(baseParams.inputResultsNum) '_*.mat'])};
resultsMachineNumbers1 = regexp({resultsFileNames{:}.name}, 'recordsNoVaccine[0-9]+_([0-9]+).mat', 'tokens');
resultsMachineNumbers2 = [resultsMachineNumbers1{~cellfun(@isempty, resultsMachineNumbers1)}]; % To get rid of blanks from files such as *_RERUN.mat
resultsMachineNumbers3 = cellfun(@(c)str2num(c{1}), resultsMachineNumbers2, 'UniformOutput', false);
resultsMachineNumbers = sort([resultsMachineNumbers3{:}]);
disp(['Machine numbers identified in results files are: ' num2str(resultsMachineNumbers) '.'])
load([baseParams.resultsDir baseParams.startingPopulationsForVaccineFile '.mat']); % Loads as chosenStartingPopulationsForVaccine
load([baseParams.resultsDir baseParams.chosenParamsIndexesForVaccineFile '.mat']); % Loads as chosenStartingPopulationsForVaccine
if baseParams.checkSnapshotMonthsFromResultsAndPopSnapshotsAreSame
    chosenStartingPopsForVaccineParams = [chosenStartingPopulationsForVaccine(:).paramSetNum]';
end
disp(['Loaded population snapshots (to get snapshot month)'])
for indMachine = 1:length(resultsMachineNumbers)
    disp(['Loading results from run ' num2str(baseParams.inputResultsNum) ' machine ' num2str(resultsMachineNumbers(indMachine)) '...']);
    ticMachine = tic;
    
    load([baseParams.resultsDir baseParams.recordsNoVaccineFileName '_' num2str(resultsMachineNumbers(indMachine)) '.mat']); % Loads as recordsNoVaccine
    sharedFields = intersect(fields(records), fields(recordsNoVaccine));
    filterResultsForChosenParams = ismember(recordsNoVaccine.popRecordMatrix(:, 2), chosenGoodParamsIndexes);
    chosenParamsInOrderOfFilter = recordsNoVaccine.popRecordMatrix(filterResultsForChosenParams, 2);
    filterChosenGoodParamsIndexes = ismember(chosenGoodParamsIndexes, recordsNoVaccine.popRecordMatrix(:, 2));
    goodParamsUsedForThisMachine = chosenGoodParamsIndexes(filterChosenGoodParamsIndexes); % Used for debugging
    for indField = 1:length(sharedFields)
        tempRecordsMatrix = recordsNoVaccine.(sharedFields{indField});
        records.(sharedFields{indField}) = [records.(sharedFields{indField}); tempRecordsMatrix( filterResultsForChosenParams, :)];
    end
    if baseParams.checkSnapshotMonthsFromResultsAndPopSnapshotsAreSame
        tempSnapshotMonthFromStartingPops = nan(size(chosenParamsInOrderOfFilter));
        for indParam = 1:length(chosenParamsInOrderOfFilter)
            tempSnapshotMonthFromStartingPops(indParam) = chosenStartingPopulationsForVaccine(chosenStartingPopsForVaccineParams == chosenParamsInOrderOfFilter(indParam)).currentMonth;
        end
        tempSnapshotMonthFromResults = [recordsNoVaccine.results(filterResultsForChosenParams).snapshotMonth]';
        tempSnapshotMonthFromStartingPops = [chosenStartingPopulationsForVaccine(filterChosenGoodParamsIndexes).currentMonth]';
        if ~all(tempSnapshotMonthFromResults == tempSnapshotMonthFromStartingPops)
            warning('The snapshot months taken from the results and the population snapshots do not all match. This should be impossible! The problem is probably in modelMonthly.')
        end
        snapshotMonthsOfGoodParams = [snapshotMonthsOfGoodParams; tempSnapshotMonthFromStartingPops];
    else
        tempSnapshotMonthFromStartingPops = nan(size(chosenParamsInOrderOfFilter));
        tempSnapshotMonthFromResults = [recordsNoVaccine.results(filterResultsForChosenParams).snapshotMonth]';
        snapshotMonthsOfGoodParams = [snapshotMonthsOfGoodParams; tempSnapshotMonthFromResults];
    end
    tempLastMonthsOfSimsFromResults = [recordsNoVaccine.results(filterResultsForChosenParams).lastMonthOfSim]';
    lastMonthsOfSims = [lastMonthsOfSims; tempLastMonthsOfSimsFromResults];
    disp(['Added results from run ' num2str(baseParams.inputResultsNum) ' machine ' num2str(resultsMachineNumbers(indMachine)) '. Took ' num2str(toc(ticMachine)) ' seconds.']);
    
end
disp(['Param sets represented in records output variable: ' num2str(length(unique(records.popRecordMatrix(:, 2)))) '. Should be ' num2str(length(unique(chosenGoodParamsIndexes))) '.'])
if length(unique(records.popRecordMatrix(:, 2))) ~= length(unique(chosenGoodParamsIndexes))
   error('A different number of no vaccine record parameter sets were loaded than there are elems in chosenGoodParamsIndexes.') 
end
if length(unique(records.popRecordMatrix(:, 2))) ~= length(snapshotMonthsOfGoodParams)
   error('A different number of no vaccine record parameter sets were loaded than there are elems in snapshotMonthsOfGoodParams.') 
end
end