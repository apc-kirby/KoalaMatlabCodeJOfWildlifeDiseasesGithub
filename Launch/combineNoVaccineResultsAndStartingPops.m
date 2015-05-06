% combineNoVaccineResultsAndStartingPops
% The disease calibration simulations may have been run on different
% computers; this script combines the separate results files and saves
% these combined results.

dbstop if error

baseParams = getBaseParamsAndSetPath();

goodParamsIndexes = [];

if baseParams.reRunJustChosenParams
    dataFromThisMachine = load([baseParams.resultsDir baseParams.goodParamsIndexesInfFileName '_1.mat']); % Variable is goodParamsIndexesInfection
    goodParamsIndexes = dataFromThisMachine.goodParamsIndexesInfection;
else
    for indMachine = 1:baseParams.numberOfNoVaccineMachines
        dataFromThisMachine = load([baseParams.resultsDir baseParams.goodParamsIndexesInfFileName '_' num2str(indMachine) '.mat']); % Variable is goodParamsIndexesInfection
        goodParamsIndexes = [goodParamsIndexes; dataFromThisMachine.goodParamsIndexesInfection];
    end
end

startingPopulationsForVaccine = [];
if baseParams.reRunJustChosenParams
    tempStartingPop = load([baseParams.resultsDir baseParams.popSnapshotsWithInfFileName '_1.mat'],'populationSnapshotsWithInfection');
        startingPopulationsForVaccine = tempStartingPop.populationSnapshotsWithInfection;
else
    for indMachine = 1:baseParams.numberOfMachines
        tempStartingPop = load([baseParams.resultsDir baseParams.popSnapshotsWithInfFileName '_' num2str(indMachine) '.mat'],'populationSnapshotsWithInfection');
        startingPopulationsForVaccine = [startingPopulationsForVaccine; tempStartingPop.populationSnapshotsWithInfection];
    end
end
% Check all infection prevalences in starting populations

numStartingPops = length(startingPopulationsForVaccine);
infPrev = nan(numStartingPops, 1);
diseasePrev = nan(numStartingPops, 1);

for ind = 1:numStartingPops
    currentMonth = startingPopulationsForVaccine(ind).currentMonth;
    % Previously next line compared infectionEnds to zero instead of
    % currentMonth; that was wrong.
    infPrev(ind) = sum(startingPopulationsForVaccine(ind).infectionEnds > currentMonth) / length(startingPopulationsForVaccine(ind).infectionEnds);
    
    diseasePrev(ind) = sum( ...
        startingPopulationsForVaccine(ind).diseaseStageCEmerges <= currentMonth ...
        | startingPopulationsForVaccine(ind).diseaseStageBEmerges <= currentMonth ...
        | (startingPopulationsForVaccine(ind).diseaseStageAEmerges <= currentMonth & startingPopulationsForVaccine(ind).infectionEnds > currentMonth) ...
        ) / length(startingPopulationsForVaccine(ind).infectionEnds);
end

minPrev = baseParams.minDiseasePrevPercent / 100; % This depends on the populations we want to simulate
maxPrev = baseParams.maxDiseasePrevPercent / 100; % This depends on the populations we want to simulate
chosenPopIndexes = zeros(baseParams.paramSetsToPick, length(minPrev));

for indPrev = 1:length(minPrev)
    disp(['Trying to pick ' num2str(baseParams.paramSetsToPick) ' param sets with disease prev ' num2str(minPrev(indPrev)) '-' num2str(maxPrev(indPrev)) '...'])
    allPopIndexesDiseaseOK = find(diseasePrev >= minPrev(indPrev) & diseasePrev <= maxPrev(indPrev));
    allPopIndexesInfOK = find(infPrev >= minPrev(indPrev) & infPrev <= maxPrev(indPrev));
    disp(['  Pops with disease prev in range: ' num2str(length(allPopIndexesDiseaseOK)) '. Pops with inf prev in range: ' num2str(length(allPopIndexesInfOK)) '.'])
    allPopIndexesDiseaseOKInfOK = intersect(allPopIndexesDiseaseOK,allPopIndexesInfOK);
    disp(['  Intersect: ' num2str(length(allPopIndexesDiseaseOKInfOK)) '.'])
    if length(allPopIndexesDiseaseOKInfOK) >= baseParams.paramSetsToPick
        chosenPopIndexes(:,indPrev) = randsample(allPopIndexesDiseaseOKInfOK,baseParams.paramSetsToPick);
        disp(['    Chose ' num2str(baseParams.paramSetsToPick) ' sets of params for which disease prev and inf prev are both OK.'])
        disp(['    Remember that these are the indexes of the STARTING POPULATIONS.'])
    else
        err(['    There were only ' num2str(length(allPopIndexesDiseaseOKInfOK)) ' pops for which disease prev and inf prev are both OK, so could not choose ' num2str(baseParams.paramSetsToPick) ' sets.'])
    end
end

popIndexesCol = sort(reshape(chosenPopIndexes, [numel(chosenPopIndexes) 1]));
chosenGoodParamsIndexes = goodParamsIndexes(popIndexesCol);
chosenStartingPopulationsForVaccine = startingPopulationsForVaccine(popIndexesCol);
save([baseParams.resultsDir baseParams.chosenParamsIndexesForVaccineFile '.mat'], 'chosenGoodParamsIndexes');
save([baseParams.resultsDir baseParams.startingPopulationsForVaccineFile '.mat'], 'chosenStartingPopulationsForVaccine');