function baseParams = getBaseParamsAndSetPath()

% baseParams = getBaseParamsAndSetPath()
% Generates a struct containing 'metaparameters' for the simulations
% (filenames, simulation IDs, numbers used in calibration etc.).
%
% baseParams: Struct containing the 'metaparameters'.

addPaths();

baseParams.reRunJustChosenParams = true; % Set to true to just re-run 
% simulations for those parameter sets that are used to simulate
% interventions. This can be used if, for example, code is added to record
% more information, so this information can be produced just for those
% parameter sets for which plots are actually made.
baseParams.observedCurrentPop = 1250; % Population shapshots of simulations 
% that pass calibration will tend to have slightly more koalas than are 
% in the population being simulated, as there is a tolerance on the number
% of koalas required. Therefore, this is set slightly lower than the actual
% number of koalas in the real population.
baseParams.inputResultsNum = 8; % Calibration set ID.
baseParams.outputResultsNum = 23; % Intervention set ID.
baseParams.setupVaccineParamsFn = @setupScenarioParams23012015_23Culling;
baseParams.resultsDir = getResultsDir();

baseParams.maxAllowedPop = 100000;
baseParams.numberOfWorkers = getenv('NUMBER_OF_PROCESSORS');
baseParams.numberOfParameterSetsPerScenarioAllMachines = 100000;
baseParams.paramSetsToPick = 100;
baseParams.randSeedMax = 100000;
baseParams.initialPrevalence = 0.5;
baseParams.monthsToSimulate = 12*30;
baseParams.minDiseasePrevPercent = [35]; % [15 35 50];
baseParams.maxDiseasePrevPercent = [70]; % [50 70 85];
baseParams.assumedYearsBeforeStabilising = 10;
baseParams.createNewPopulationForNoVaccineSims = true;
baseParams.halvingTimeIndex = [2]; % [1 2 3];

% nParams = baseParams.numberOfParameterSetsPerScenarioAllMachines; % For no-infection sims
% nParams = getNGoodParamsIndexesNoInfection(baseParams.inputResultsNum ); % For no-vaccine sims, if being run for the first time
nParams = baseParams.paramSetsToPick; % For vaccine sims, and re-running just good params
baseParams.numberOfNoVaccineMachines = 10; % Used in combineNoVaccineResultsAndStartingPops
baseParams.numberOfMachines = 1; % Set to the number of computers on which simulations will be run.
baseParams.thisMachine = struct('sepph10',1); % If running on multiple
% computers, this struct should be expanded to, e.g.,
% struct('machine1', 1, 'machine2', 2 ... ) up to
% baseParams.numberOfMachines.
% The name of a computer can be found with dos('hostname').
[baseParams.thisMachineFromParamSet, baseParams.thisMachineToParamSet] = getSuggestedParamSetsByMachine(nParams, baseParams.numberOfMachines);

% Data files that must already exist.
baseParams.paramsFile = 'parameterTable.xlsx';
baseParams.bodyScoreParamsFile = 'bodyScoreParams.xlsx';
baseParams.weightToReprodSuccessWeightFile = 'weightReprodSuccessWeights.xlsx';
baseParams.weightToReprodSuccessReprodSuccessFile = 'weightReprodSuccessReprodSuccess.xlsx';
baseParams.weightTrackParamsFile = 'weightTrackParamsFile.xlsx';
baseParams.koalaCoastPopFile = 'koalaCoastPop.csv';

% Data files that are created during simulation process.
inputResultsNumStr = num2str(baseParams.inputResultsNum);
outputResultsNumStr = num2str(baseParams.outputResultsNum);
baseParams.paramsFieldNamesFile = ['paramsFieldNames' inputResultsNumStr];
baseParams.startingPopulationsForVaccineFile = ['startingPopulationsForVaccine_chosen' inputResultsNumStr];
baseParams.chosenParamsIndexesForVaccineFile = ['goodParamsIndexes_chosen' inputResultsNumStr];
baseParams.paramSetsInfectionParamsUpdatedFile = ['paramsMatrixNoVaccineSims' inputResultsNumStr];
baseParams.paramSetsBeforeInfectionFile = ['paramsMatrix' inputResultsNumStr];
baseParams.paramSetsNoVaccineFile = ['paramsMatrixNoVaccineSims' inputResultsNumStr];
baseParams.prerunGoodParamsIndexesNoInfectionFile = ['goodParamsIndexesNoInfection' inputResultsNumStr];
baseParams.popSnapshotsWithInfFileName = ['populationSnapshotsWithInfection' inputResultsNumStr];
baseParams.recordsNoVaccineFileName = ['recordsNoVaccine' inputResultsNumStr];
baseParams.goodParamsIndexesInfFileName = ['goodParamsIndexesInfection' inputResultsNumStr];
baseParams.vaccineResultsFileName = ['vaccineResults' outputResultsNumStr];

% nonInfectionParams must be in same order as they appear in file
baseParams.nonInfectionParams = {'femaleYoungBreedingAge', 'youngFemaleMatesProbability', 'youngFemaleBreedingReduction', 'femaleDominantBreedingAge', ...
    'monthlyProbInBreedingSeasonOfMatingProducingYoung', 'monthlyProbOffBreedingSeasonOfMatingProducingYoung', ...
    'highJoeyBirthSeasonStart', 'highJoeyBirthSeasonFinish', 'mateOutsideBreedingSeason', 'j3', 'femaleOldAge', 'oldFemaleBreedingReduction', 'maleYoungBreedingAge', ...
    'maleDominantBreedingAge', 'maleOldAge', 'dependentSurvivorship', 'pouchEmergeAge', 'juvenileAge', 'maleJuvenileSurvivorship', ...
    'femaleJuvenileSurvivorship', 'maleAdultAge', 'femaleAdultAge', 'adultSurvivorship', 'oldSurvivorship', 'b', 'pairingsPerFemale', 'mD', ...
    'monthsFromFailedMatingUntilNextMating', 'lengthOfPregnancyMonths', 'maxAge','randomSeed','reprodSuccessCurveNumber'};
baseParams.infectionParams = {'tm', 'tf', 'tj', 'probabilityOfInfectionKilling', 'pr', 'yearsBeforeDeath', 'monthsUntilInfectionKills', ...
    'monthsUntilInfectionKillsLowerBound', 'monthsUntilInfectionKillsUpperBound', 'yearsBeforeClearance', 'monthsBeforeClearance', ...
    'monthsBeforeClearanceLowerBound', 'monthsBeforeClearanceUpperBound', 'probabilityOfDiseaseStageBDeveloping', 'probabilityOfDiseaseStageADeveloping', ...
    'a2', 'a3', 'monthsUntilDiseaseEmerges', 'peakInfectiousnessDuration', 'peakInfectiousnessMultiplier', 'probabilityOfHighSheddingIfDiseased', 'rr', ...
    'resistanceDuration', 'resistanceDurationMonths', 'resistanceDurationMonthsLowerBound', 'resistanceDurationMonthsUpperBound', 'timeInHospital'};
baseParams.integerFieldsWithRanges = {'mD','monthsUntilInfectionKills','monthsBeforeClearance','resistanceDurationMonths','randomSeed','reprodSuccessCurveNumber'};

baseParams.calibrationParamsNoVaccineSims.matingWithInfectedPartnerCanCauseDisease = false;
baseParams.calibrationParamsNoVaccineSims.assumedYearsBeforeStabilising = baseParams.assumedYearsBeforeStabilising;
baseParams.calibrationParamsNoVaccineSims.minInfectionPrevPercent = 0;
baseParams.calibrationParamsNoVaccineSims.maxInfectionPrevPercent = 100;
baseParams.calibrationParamsNoVaccineSims.minDiseasePrevPercent = baseParams.minDiseasePrevPercent;
baseParams.calibrationParamsNoVaccineSims.maxDiseasePrevPercent = baseParams.maxDiseasePrevPercent;
baseParams.calibrationParamsNoVaccineSims.minSnapshotSize = 0.9 * baseParams.observedCurrentPop; % observedCurrentPop - 10%
baseParams.calibrationParamsNoVaccineSims.maxSnapshotSize = 1.1 * baseParams.observedCurrentPop; % observedCurrentPop + 10%
minHalvingTimes = [2.5 5 10];
maxHalvingTimes = [5 10 15];
baseParams.calibrationParamsNoVaccineSims.minHalvingTime = minHalvingTimes(baseParams.halvingTimeIndex);
baseParams.calibrationParamsNoVaccineSims.maxHalvingTime = maxHalvingTimes(baseParams.halvingTimeIndex);
baseParams.calibrationParamsNoVaccineSims.minYearsBeforeSnapshot = baseParams.calibrationParamsNoVaccineSims.assumedYearsBeforeStabilising + baseParams.calibrationParamsNoVaccineSims.minHalvingTime;
baseParams.calibrationParamsNoVaccineSims.prevalenceMustBeGTZero = true;
baseParams.calibrationParamsNoVaccineSims.initialNumberOfKoalasForNoVaccineSims = ...
    ceil( 2 * baseParams.calibrationParamsNoVaccineSims.minSnapshotSize ...
    / exp( log(1/2) * baseParams.calibrationParamsNoVaccineSims.assumedYearsBeforeStabilising / (0.5 * min(baseParams.calibrationParamsNoVaccineSims.minHalvingTime)) ) );
baseParams.calibrationParamsNoVaccineSims.yearsToSimulate =  ceil ( log( baseParams.calibrationParamsNoVaccineSims.maxSnapshotSize/baseParams.calibrationParamsNoVaccineSims.initialNumberOfKoalasForNoVaccineSims) * max(baseParams.calibrationParamsNoVaccineSims.maxHalvingTime) / log(1/2) + baseParams.calibrationParamsNoVaccineSims.assumedYearsBeforeStabilising/2 );
baseParams.calibrationParamsNoVaccineSims.maxPermittedPopulation = 1.5 * baseParams.calibrationParamsNoVaccineSims.initialNumberOfKoalasForNoVaccineSims;

baseParams.calibrationParamsVaccineSims.matingWithInfectedPartnerCanCauseDisease = false;
baseParams.calibrationParamsVaccineSims.yearsToSimulate = baseParams.monthsToSimulate/12;
baseParams.calibrationParamsVaccineSims.prevalenceMustBeGTZero = false;
baseParams.calibrationParamsVaccineSims.maxPermittedPopulation = baseParams.maxAllowedPop;

end