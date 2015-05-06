
function [recordsVaccine, scenarioParamsMatrix, scenarioLabels] = combineVaccineResults(observedPop, resultsNum)

% [recordsVaccine, scenarioParamsMatrix, scenarioLabels] = combineVaccineResults(observedPop, resultsNum)
% Simulation results can be saved across multiple files. This function combines
% them.
%
% observedPop: Approximate number of koalas at the zero year of each
% simulation.
% resultsNum: ID of the results to combine.
%
% recordsVaccine: Combined intervention simulation results.
% scenarioParamsMatrix: Matrix of the intervention parameters.
% scenarioLabels: Names of the intervention parameters.

baseParams = getBaseParamsForVisualisation(observedPop, resultsNum);
monthsToRetain = baseParams.monthsToRetain;
if monthsToRetain > baseParams.monthsToSimulate
    error('Trying to retain more months than were simulated.')
end
isLoadDeathResults = false;
if ~isLoadDeathResults
    disp('To save RAM, death results will not be loaded.')
end
secondsToWaitOnError = 10;
disp(['Viewing results ' num2str(baseParams.outputResultsNum) '...'])
leadingData = 2;
% currentMaxScenarioNumber = 0;

fieldsToLoad = {'popRecordMatrix', 'infRecordMatrix', 'incidenceRecordMatrix', 'diseasedRecordMatrix', 'vaccinatedRecordMatrix', ...
    'mothersWithYoungRecordMatrix', 'potentialMothersRecordMatrix', 'vaccinationRecordMatrix'};
% Fields currently not loading:
% deathsRecordMatrix,
% deathsByDiseaseRecordMatrix, deathsByEuthanasiaRecordMatrix,
% deathsByOtherRecordMatrix, deathsMotherDiedRecordMatrix.

for indField = 1:length(fieldsToLoad)
    recordsVaccine.(fieldsToLoad{indField}) = [];
end

scenarioParamsMatrix = [];

isThereWereErrors = false;

disp('Loading VACCINE results from different machines...')
ticLoad = tic;
addToScenarioMultiplier = 100000;
for indResults = 1:length(baseParams.outputResultsNum)
    numResults = baseParams.outputResultsNum(indResults)
    addToScenarios = numResults * addToScenarioMultiplier;
    % Find all machine numbers in results folder for this results number.
    resultsFileNames = {dir([baseParams.resultsDir '\vaccineResults' num2str(numResults) '_*_results.mat'])};
    resultsMachineNumbers1 = regexp({resultsFileNames{:}.name}, 'vaccineResults[0-9]+_([0-9]+)_results.mat', 'tokens');
    resultsMachineNumbers2 = cellfun(@(c)str2num(c{1}{1}), resultsMachineNumbers1, 'UniformOutput', false);
    resultsMachineNumbers = sort([resultsMachineNumbers2{:}]);
    disp(['Machine numbers identified in results files are: ' num2str(resultsMachineNumbers) '.'])
    for indMachine = 1:length(resultsMachineNumbers)
        disp(['Loading results from run ' num2str(numResults) ' machine ' num2str(resultsMachineNumbers(indMachine)) '...']);
        ticMachine = tic;
        load([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(resultsMachineNumbers(indMachine)) '_errorList.mat']);
        isThereWereErrorsForThisMachine = ~(all(all(cellfun(@isempty, errorList))));
        if isThereWereErrorsForThisMachine
            error(['  THERE WAS AT LEAST ONE ERROR FOR RUN ' num2str(numResults) ' MACHINE ' num2str(resultsMachineNumbers(indMachine)) '!!!']);
        end
        isThereWereErrors = isThereWereErrors || isThereWereErrorsForThisMachine;
        
        for indField = 1:length(fieldsToLoad)
            disp(['  Trying to load field ' fieldsToLoad{indField} '...'])
            isLoaded = false;
            while ~isLoaded
                try
                    temp.(fieldsToLoad{indField}) = load([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(resultsMachineNumbers(indMachine)) ...
                        '_' fieldsToLoad{indField} '.mat']);
                    isLoaded = true;
                catch err
                    if strcmp(err.identifier, 'MATLAB:load:notBinaryFile')
                        disp('    Failed to load and reported that file was not a .mat binary file, almost certainly erroneously.')
                        disp(['    Will wait ' num2str(secondsToWaitOnError) ' seconds and try again.'])
                        pause(secondsToWaitOnError)
                    else
                        throw(err);
                    end
                end
            end
            matrixToAdd = temp.(fieldsToLoad{indField}).(fieldsToLoad{indField});
            matrixToAdd(:,1) = addToScenarios + matrixToAdd(:,1);
            matrixToAdd(matrixToAdd(:,1)==addToScenarios,1) = 0; % No-vaccine scenario
            recordsVaccine.(fieldsToLoad{indField}) = [recordsVaccine.(fieldsToLoad{indField}); matrixToAdd(:,(1:(leadingData+monthsToRetain)))];
            tempRecordsVaccineMatrixCopy = recordsVaccine.(fieldsToLoad{indField});
            firstScenarioJustLoaded = min(matrixToAdd(:,1));
            lastScenarioJustLoaded = max(matrixToAdd(:,1));
            nScenariosJustLoaded = length(unique(matrixToAdd(:,1)));
            disp(['  Loaded field ' fieldsToLoad{indField} ' successfully. It has scenarios ' num2str(firstScenarioJustLoaded) ...
                ' to ' num2str(lastScenarioJustLoaded) ' (that is ' num2str(nScenariosJustLoaded) ' scenarios).'])
            disp(['  Largest scenario number so far is ' num2str(max(tempRecordsVaccineMatrixCopy(:,1))) '.']) 
            
        end

        disp(['Loaded results from run ' num2str(numResults) ' machine ' num2str(resultsMachineNumbers(indMachine)) '. Took ' num2str(toc(ticMachine)) ' seconds.']);
        disp(['There are ' num2str(sum(recordsVaccine.popRecordMatrix(:,2)==0)) ' rows for which the param number is 0, which should be impossible.'])
    end
    % Also update scenarioParamsMatrix.
    tempDetails = load([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(resultsMachineNumbers(indMachine)) '_scenarioDetails.mat']);
    tempDetails.scenarioDetails.scenarioParamsMatrix(:,1) = tempDetails.scenarioDetails.scenarioParamsMatrix(:,1) + double(addToScenarios);
    scenarioParamsMatrix = [scenarioParamsMatrix; tempDetails.scenarioDetails.scenarioParamsMatrix];

    disp(['Finished combining results from run ' num2str(numResults) ' with previous results.'])
end
disp(['Assuming that any scenario with number ' num2str(addToScenarioMultiplier) '*n (n integer) is a no-vaccine scenario.'])
disp('These no-vaccine scenarios should be the same regardless of which results set they came from. Checking this...')
for indField = 1:length(fieldsToLoad)
   disp(['Extracting from ' fieldsToLoad{indField} ' the no-vaccine scenarios...'])
   tempRecordMatrix = recordsVaccine.(fieldsToLoad{indField});
   noVaccineRecords = tempRecordMatrix(tempRecordMatrix(:,1)==0,:);
   if ~isempty(noVaccineRecords)
      tempRecordMatrix(tempRecordMatrix(:,1)==0,:) = [];
      disp(['  Found ' num2str(length(unique(noVaccineRecords(:,2)))) ' unique param sets in ' num2str(size(noVaccineRecords,1)) ' no-vaccine sims.'])
      dedupNoVaccineRecords = unique(noVaccineRecords, 'rows');
      disp(['  After de-duplication, found ' num2str(length(unique(dedupNoVaccineRecords(:,2)))) ' unique param sets in ' num2str(size(dedupNoVaccineRecords,1)) ' no-vaccine sims.'])
      if length(unique(dedupNoVaccineRecords(:,2))) ~= size(dedupNoVaccineRecords,1)
          error('There are still duplicate param numbers for the no-vaccine scenarios. This should not be possible.')
      end
      recordsVaccine.(fieldsToLoad{indField}) = [dedupNoVaccineRecords; tempRecordMatrix];
   end
end
scenarioLabels = tempDetails.scenarioDetails.scenarioLabels;
disp(['Loaded and combined results from different machines. Took ' num2str(toc(ticLoad)) ' seconds.'])
if isThereWereErrors
    disp(['THERE WAS AT LEAST ONE ERROR!!!']);
else
    disp(['There were no errors in any of the simulations.'])
end
% Find out which param sets correspond to which 'populations' (in terms of
% prevalence)
load([baseParams.resultsDir baseParams.chosenParamsIndexesForVaccineFile '.mat']);
load([baseParams.resultsDir baseParams.startingPopulationsForVaccineFile '.mat']);
numStartingPops = length(chosenGoodParamsIndexes);
infPrev = nan(numStartingPops, 1);
diseasePrev = nan(numStartingPops, 1);
for ind = 1:numStartingPops
    currentMonth = chosenStartingPopulationsForVaccine(ind).currentMonth;
    infPrev(ind) = sum(chosenStartingPopulationsForVaccine(ind).infectionEnds > currentMonth) / length(chosenStartingPopulationsForVaccine(ind).infectionEnds);
    
    diseasePrev(ind) = sum( ...
        chosenStartingPopulationsForVaccine(ind).diseaseStageCEmerges <= currentMonth ...
        | chosenStartingPopulationsForVaccine(ind).diseaseStageBEmerges <= currentMonth ...
        | (chosenStartingPopulationsForVaccine(ind).diseaseStageAEmerges <= currentMonth & chosenStartingPopulationsForVaccine(ind).infectionEnds > currentMonth) ...
        ) / length(chosenStartingPopulationsForVaccine(ind).infectionEnds);
end
minPrev = baseParams.minDiseasePrevPercent / 100; % This depends on the populations we want to simulate
maxPrev = baseParams.maxDiseasePrevPercent / 100; % This depends on the populations we want to simulate
for indPrev = 1:length(minPrev)
    filterPop{indPrev} = infPrev >= minPrev(indPrev) & infPrev <= maxPrev(indPrev) & diseasePrev >= minPrev(indPrev) & diseasePrev <= maxPrev(indPrev);
    disp(['There were ' num2str(sum(filterPop{indPrev})) ' param sets with inf and prev in range ' num2str(minPrev(indPrev)) '-' num2str(maxPrev(indPrev)) '.'])
end
% Check for duplicate rows, indicative of a simulation having been run
% twice.
duplicateParamNums = checkForDuplicateParamSets(recordsVaccine);
theFieldnames = fieldnames(recordsVaccine);
if ~isempty(duplicateParamNums)
    valForNaN = -999;
    ticRemoveDups = tic;
    for indField = 1:length(theFieldnames)
        disp(['Removing duplicate rows from ' theFieldnames{indField} '...'])
        recordsVaccineMatrix = recordsVaccine.(theFieldnames{indField});
        if any(any(recordsVaccineMatrix == valForNaN))
            error('Value used to substitute in for NaN in record matrix already appears in record matrix.')
        elseif any(any(isnan(recordsVaccineMatrix)))
            disp([' Found at least one NaN value in ' theFieldnames{indField} '. Substituting ' num2str(valForNaN) ' temporarily.'])
        end
        recordsVaccineMatrix(isnan(recordsVaccineMatrix)) = valForNaN;
        recordsVaccineMatrix = unique(recordsVaccineMatrix, 'rows');
        recordsVaccineMatrix(recordsVaccineMatrix == valForNaN) = NaN;
        recordsVaccine.(theFieldnames{indField}) = recordsVaccineMatrix;
        disp(['  Finished removing duplicate rows from ' theFieldnames{indField} ...
            '. Time elapsed since start of de-dup process is ' num2str(toc(ticRemoveDups)/60) ' minutes.'])
    end
    clear recordsVaccineMatrix;
    checkForDuplicateParamSets(recordsVaccine);
end
[scenarioParamsMatrix, scenarioLabels] = addAvgEffToScenarioParamsMatrix(scenarioParamsMatrix, scenarioLabels);
[monthReachedMaxPop, ~, ~] = checkForProbablyReachedMaxPop(recordsVaccine.popRecordMatrix);
if any(monthReachedMaxPop(:,3) < Inf)
    disp(['Because at least one sim reached the max allowed pop, the earliest year for which it is safe to take results for is ' num2str(min(monthReachedMaxPop(:,3)/12)) '.'])
end
disp('DROPPING RESULTS FOR BOOST TYPE 0 (boosting does nothing)...')
nScenariosBeforeDropping = size(scenarioParamsMatrix,1);
boostTypeCol = strcmp('Boost type', scenarioLabels);
scenarioNumsWithBoostType0 = scenarioParamsMatrix(scenarioParamsMatrix(:,boostTypeCol)==0,1);
% Drop scenarios with boost type 0 from scenarioParamsMatrix.
scenarioParamsMatrix(ismember(scenarioParamsMatrix(:,1), scenarioNumsWithBoostType0),:) = [];
% Drop scenarios with boost type 0 from recordsVaccine matrices.
for indField = 1:length(theFieldnames)
    disp(['  Dropping results for ' theFieldnames{indField}])
    tempRecordMatrix = recordsVaccine.(theFieldnames{indField});
    tempRecordMatrix( ismember(tempRecordMatrix(:,1), scenarioNumsWithBoostType0),:) = [];
    recordsVaccine.(theFieldnames{indField}) = tempRecordMatrix;
end
nScenariosAfterDropping = size(scenarioParamsMatrix,1);
disp(['Dropped ' num2str(nScenariosBeforeDropping - nScenariosAfterDropping) ' scenarios. ' num2str(nScenariosAfterDropping) ' scenarios remain.'])
end