% combineNoInfectionResults
% The demographic calibration simulations may have been run on different
% computers; this script combines the separate results files and saves
% these combined results.

baseParams = getBaseParamsAndSetPath();
goodParamsIndexesNoInfection = [];

for indMachine = 1:baseParams.numberOfMachines
    dataFromThisMachine = csvreadFromResultsDir([baseParams.prerunGoodParamsIndexesNoInfectionFile '_' num2str(indMachine) '.csv']);
    disp(['From machine ' num2str(indMachine) ', found ' num2str(length(dataFromThisMachine)) ' good param sets.'])
    goodParamsIndexesNoInfection = [goodParamsIndexesNoInfection; dataFromThisMachine];
end

disp(['Found ' num2str(length(goodParamsIndexesNoInfection)) ' good param sets.'])
disp('Saving good param set indexes (no infection)...')
csvwrite([baseParams.resultsDir baseParams.prerunGoodParamsIndexesNoInfectionFile '.csv'], goodParamsIndexesNoInfection)
disp('Saved good param sets indexes (no infection).')