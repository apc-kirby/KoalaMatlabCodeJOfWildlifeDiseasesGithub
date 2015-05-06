% launchNoVaccineSims
% Script that starts the disease calibration process and saves the results.

clear
dbstop if error

if ~matlabpool('size');
    disp('Starting parallel Matlab...');
    matlabpool(getenv('NUMBER_OF_PROCESSORS'));
end
 
baseParams = getBaseParamsAndSetPath();

isRetainResults = false

[thisMachineNum, fromParamSetNum, toParamSetNum, numberOfParameterSetsPerScenario] = getMachineNumber(baseParams);

numberOfLHSSamples = 10;

recordVarType = 'uint32';
maxValuePermittedByRecordVarType = 2^32 - 1;

calibrationParamsNoVaccineSims = baseParams.calibrationParamsNoVaccineSims;

reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams);

if calibrationParamsNoVaccineSims.maxPermittedPopulation < calibrationParamsNoVaccineSims.initialNumberOfKoalasForNoVaccineSims
    error('Initial number of koalas for no vaccine sims is greater than that permitted.')
end

if (calibrationParamsNoVaccineSims.maxPermittedPopulation > maxValuePermittedByRecordVarType)
    error('Max permitted population is larger than max allowed value of record variable type.')
end

ticIDTotal = tic;

disp(['Loading body health score parameter file: ' baseParams.bodyScoreParamsFile])
[bodyScoreParamsData,bodyScoreParamsTextdata] = importfile1(baseParams.bodyScoreParamsFile);
bodyScoreParams = setupBodyScoreParams(bodyScoreParamsData,bodyScoreParamsTextdata);

lengthOfResults = 11;

disp('Loading pre-run good params indexes (no infection)...')
% Import pre-determined goodParamsIndexesNoInfection
if baseParams.reRunJustChosenParams
    load([getResultsDir baseParams.chosenParamsIndexesForVaccineFile '.mat']); % Loads as chosenGoodParamsIndexes
    allGoodParamsIndexesNoInfection = chosenGoodParamsIndexes;
else
    allGoodParamsIndexesNoInfection = csvreadFromResultsDir([baseParams.prerunGoodParamsIndexesNoInfectionFile '.csv']);
end
disp(['Loaded ' num2str(length(allGoodParamsIndexesNoInfection)) ' pre-run good params indexes (no infection).']);
disp(['Will use good params indices ' num2str(fromParamSetNum) ' to ' num2str(toParamSetNum) ' (total param sets: ' num2str(numberOfParameterSetsPerScenario) ') on this machine.'])
goodParamsIndexesNoInfectionThisMachine = allGoodParamsIndexesNoInfection(fromParamSetNum:toParamSetNum);
disp(['  (Good params index ' num2str(fromParamSetNum) ' is param set no. ' num2str(goodParamsIndexesNoInfectionThisMachine(1)) ', and good params index ' num2str(toParamSetNum) ...
    ' is param set no. ' num2str(goodParamsIndexesNoInfectionThisMachine(end)) '.)']);

if isempty(goodParamsIndexesNoInfectionThisMachine)
    disp('No parameter sets for this machine. Consider increasing number of parameter sets.');
else
    
    
    disp(['Loading model parameter file: ' baseParams.paramsFile])
    [paramsData,paramsTextdata] = importfile1(baseParams.paramsFile);
    [fields,mins,maxes] = setupParamsAsArrays(paramsData,paramsTextdata);
    fields = cat(2, fields, {'randomSeed','reprodSuccessCurveNumber'});
    mins = cat(2, mins, [1 1]);
    maxes = cat(2, maxes, [baseParams.randSeedMax size(reproductiveSuccessStruct.weightTrackParamADistn, 1)]);
    disp('Loading pre-generated parameter sets for no vaccine sims (all parameters)...')
    paramsStruct = importParams([baseParams.paramSetsBeforeInfectionFile '.csv'], baseParams.paramsFieldNamesFile);
    paramsStruct.paramsWithoutRanges = getParamsWithoutRanges(fields,mins,maxes);
    disp('Loaded pre-generated parameter sets.')

    
    if baseParams.createNewPopulationForNoVaccineSims
        disp('SKIPPING creation of initial population for no vaccine sims.')
        disp('(Each population will be generated just before it is used in a simulation.)')
    else
        disp('UPDATING starting population for each parameter set, for no vaccine sims...')
        startingPopulationsWithInfection = adjustDatesOfPopulationSnapshots(populationSnapshotsNoInfection);
        disp('UPDATED starting populations.')
    end
    
    disp('Running simulations without vaccines...')
    ticNoVaccine = tic;
    [goodParamsIndexesInfection,recordsNoVaccine,populationSnapshotsWithInfection] = ...
        runNoVaccineSims(goodParamsIndexesNoInfectionThisMachine,paramsStruct.paramsMatrix, paramsStruct.paramsFieldNames, paramsStruct.paramsWithoutRanges, ...
        [],calibrationParamsNoVaccineSims,lengthOfResults,baseParams.initialPrevalence,bodyScoreParams, calibrationParamsNoVaccineSims.initialNumberOfKoalasForNoVaccineSims, true, recordVarType, reproductiveSuccessStruct);
    tocNoVaccine = toc(ticNoVaccine);
    disp(['Finished running simulations without vaccines. Took ' num2str(tocNoVaccine) ' seconds.']);
    goodParamsIndexesInfection'
    
    disp(['Number of good parameter sets: ' num2str(length(goodParamsIndexesInfection))])
    
    if length(goodParamsIndexesInfection) ~= length(populationSnapshotsWithInfection)
        disp('WARNING: Number of good param sets and number of population snapshots are not the same.');
    end
    
    disp('Finished running simulations without vaccines.')
    
    if baseParams.reRunJustChosenParams
        save([baseParams.resultsDir baseParams.goodParamsIndexesInfFileName '_' num2str(thisMachineNum) '_RERUN.mat'], 'goodParamsIndexesInfection');
        save([baseParams.resultsDir baseParams.popSnapshotsWithInfFileName '_' num2str(thisMachineNum) '_RERUN.mat'], 'populationSnapshotsWithInfection');
        save([baseParams.resultsDir baseParams.recordsNoVaccineFileName '_' num2str(thisMachineNum) '_RERUN.mat'], 'recordsNoVaccine');
    else
        save([baseParams.resultsDir baseParams.goodParamsIndexesInfFileName '_' num2str(thisMachineNum) '.mat'], 'goodParamsIndexesInfection');
        save([baseParams.resultsDir baseParams.popSnapshotsWithInfFileName '_' num2str(thisMachineNum) '.mat'], 'populationSnapshotsWithInfection');
        save([baseParams.resultsDir baseParams.recordsNoVaccineFileName '_' num2str(thisMachineNum) '.mat'], 'recordsNoVaccine');
    end
end

disp(['Total running time: ' num2str(toc(ticIDTotal))]);
matlabpool close
