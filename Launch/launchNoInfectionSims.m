% launchNoInfectionSims
% Runs demographic calibration (i.e., runs simulations of infection-free
% populations, retains or discards based on whether their features are
% as required), and saves the results.

clear
dbstop if error

baseParams = getBaseParamsAndSetPath();

if ~matlabpool('size');
    disp('Starting parallel Matlab...');
    matlabpool('open');
end

isRetainResults = false;


[thisMachineNum, fromParamSetNum, toParamSetNum, numberOfParameterSetsPerScenario] = getMachineNumber(baseParams);
thisMachineParamSetRange = fromParamSetNum:toParamSetNum;

numberOfLHSSamples = 10;

recordVarType = 'uint32';
maxValuePermittedByRecordVarType = 2^32 - 1;

calibrationParamsNoInfectionSims.matingWithInfectedPartnerCanCauseDisease = false;
calibrationParamsNoVaccineSims.matingWithInfectedPartnerCanCauseDisease = false;
calibrationParamsNoInfectionSims.assumedYearsBeforeStabilising = baseParams.assumedYearsBeforeStabilising;
calibrationParamsNoInfectionSims.yearsToSimulate = calibrationParamsNoInfectionSims.assumedYearsBeforeStabilising + 10;
calibrationParamsNoInfectionSims.minDoublingTime = 2.7;
calibrationParamsNoInfectionSims.maxDoublingTime = Inf;
calibrationParamsNoInfectionSims.prevalenceMustBeGTZero = false;
calibrationParamsNoInfectionSims.maxPermittedPopulation = baseParams.observedCurrentPop * 2^ (1 + 2 * calibrationParamsNoInfectionSims.assumedYearsBeforeStabilising / calibrationParamsNoInfectionSims.minDoublingTime);
calibrationParamsNoInfectionSims.minSnapshotSize = 0;
calibrationParamsNoInfectionSims.maxSnapshotSize = calibrationParamsNoInfectionSims.maxPermittedPopulation;
calibrationParamsNoInfectionSims.minYearsBeforeSnapshot = calibrationParamsNoInfectionSims.assumedYearsBeforeStabilising;
initialNumberOfKoalasForNoInfectionSims = baseParams.observedCurrentPop;

reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams);

if calibrationParamsNoInfectionSims.maxPermittedPopulation < initialNumberOfKoalasForNoInfectionSims
    error('Initial number of koalas for no infection sims is greater than that permitted.')
end

if (calibrationParamsNoInfectionSims.maxPermittedPopulation > maxValuePermittedByRecordVarType)
    error('Max permitted population is larger than max allowed value of record variable type.')
end

ticIDTotal = tic;

disp(['Loading body health score parameter file: ' baseParams.bodyScoreParamsFile])
[bodyScoreParamsData,bodyScoreParamsTextdata] = importfile1(baseParams.bodyScoreParamsFile);
bodyScoreParams = setupBodyScoreParams(bodyScoreParamsData,bodyScoreParamsTextdata);

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

lengthOfResults = 11;

disp(['Reduced rows of paramsStruct.paramsMatrix from ' num2str(size(paramsStruct.paramsMatrix,1)) ' to ' num2str(numberOfParameterSetsPerScenario)])
disp(['  by taking rows ' num2str(fromParamSetNum) ' to ' num2str(toParamSetNum) ' (inclusive).'])

disp('SKIPPING creation of initial population for no infection sims.')
disp('(Each population will be generated just before it is used in a simulation.)')

disp('Running simulations without infection...')
ticNoInfection = tic;
[goodParamsIndexesNoInfection,recordsNoInfection,populationSnapshotsNoInfection] = runNoInfectionSims( ...
    paramsStruct.paramsMatrix(thisMachineParamSetRange,:) ...
    ,paramsStruct.paramsFieldNames, paramsStruct.paramsWithoutRanges, ...
    [], ...
    calibrationParamsNoInfectionSims,lengthOfResults,[],[],bodyScoreParams,initialNumberOfKoalasForNoInfectionSims, isRetainResults, recordVarType, reproductiveSuccessStruct);
tocNoInfection = toc(ticNoInfection);
disp(['Finished running simulations without infection. Took ' num2str(tocNoInfection) ' seconds.'])
disp('Good parameter sets from no infection simulations:')
goodParamsIndexesNoInfection'
disp('Their corresponding actual param numbers:')
thisMachineParamSetRange'
disp(['Number of good parameter sets: ' num2str(length(goodParamsIndexesNoInfection))])
disp('Saving indexes of good parameter sets...')
ticSaving = tic
csvwrite([getResultsDir() baseParams.prerunGoodParamsIndexesNoInfectionFile '_' num2str(thisMachineNum) '.csv'], thisMachineParamSetRange(goodParamsIndexesNoInfection)')
disp(['Saved indexes of good parameter sets. Took ' num2str(toc(ticSaving)) ' seconds.'])

matlabpool close