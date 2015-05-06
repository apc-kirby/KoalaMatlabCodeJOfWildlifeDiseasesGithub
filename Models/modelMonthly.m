function [results, popSnapshot, records, stopFlag,snapshotRecord, crashError] = ...
    modelMonthly(paramsVector, paramsFieldNames, params, drawGraphs,displayStats,startingKoalas,yearsToSimulate,initialPrevalence,vaccineProtocol, ...
    startingPopulation,noInfection,calibrationParams,isTakeSnapshotNecessary,bodyScoreParams,isSnapshotRecordNecessary,reproductiveSuccessStruct, paramsIndex)

% [results, popSnapshot, records, stopFlag,snapshotRecord, crashError] = ...
%    modelMonthly(paramsVector, paramsFieldNames, params, drawGraphs,displayStats,startingKoalas,yearsToSimulate,initialPrevalence,vaccineProtocol, ...
%    startingPopulation,noInfection,calibrationParams,isTakeSnapshotNecessary,bodyScoreParams,isSnapshotRecordNecessary,reproductiveSuccessStruct, paramsIndex)
% This function runs one simulation and returns the results.
%
% paramsVector: Parameter values.
% paramsFieldNames: Parameter names.
% params: Struct used to look up parameter values by name.
% drawGraphs: Flag for whether to draw graphs at end of simulation.
% displayStats: Flag for whether to list summary statistics at end of
% simulation.
% startingKoalas: Number of koalas at start of simulation.
% yearsToSimulate: Number of years to simulate.
% initialPrevalence: Infection prevalence at start of simulation.
% vaccineProtocol: Struct containing the intervention parameters.
% startingPopulation: Snapshot of the population to run the simulation on.
% noInfection: Flag for whether or not infections should be created in the
% initial population.
% calibrationParams: Struct of some 'metaparameters' used in calibration.
% isTakeSnapshotNecessary: Flag for whether a population snapshot should be
% taken.
% bodyScoreParams: Struct of parameters used to calculate body score.
% isSnapshotRecordNecessary: Flag for whether to record detailed
% information about population at each timestep of simulation.
% reproductiveSuccessStruct: Struct of reproductive success weights.
% paramsIndex: ID of parameter set being used.
%
% results: Summary statistics for simulation.
% popSnapshot: Snapshot of population at some point in simulation.
% records: More summary statistics for simulation (by month).
% stopFlag: Flag indicating some conditions for why simulation was stopped.
% snapshotRecord: Even more detailed summary statistics.
% crashError: Error, if one occurred.

male = 0;
female = 1;

crashError = [];

for ind = 1:length(paramsFieldNames)
    params.(paramsFieldNames{ind}) = paramsVector(ind);
end
rng(params.randomSeed, 'combRecursive');

snapshotRecord = [];

if isempty(vaccineProtocol)
    vaccineProtocol.numberOfCapturesByMonth = [];
    vaccineProtocol.initialEfficacy = 0;
    vaccineProtocol.halfLife = 1;
    vaccineProtocol.boostFromMating = false;
    vaccineProtocol.preventsWhat = 0;
    vaccineProtocol.emigrationsByMonth = zeros(1, 12*yearsToSimulate);
else
    vaccinateBothGenders = length(vaccineProtocol.groups(1).gender) == 2;
    vaccinateMales = ~isempty(find(vaccineProtocol.groups(1).gender == male, 1));
    vaccinateFemales = ~isempty(find(vaccineProtocol.groups(1).gender == female, 1));
    
end

monthsToSimulate = 12*yearsToSimulate;

[params.cumulativeFemaleProbOfDyingBeforeThisMonth,params.cumulativeMaleProbOfDyingBeforeThisMonth] = getLifespanProbabilitiesMonthly(params, 1);
params.monthlyProbabilityOfConceivingIfMated = getOneMonthlyProbabilityOfConceivingIfMated(params);

weightToReprodSuccessWeight = reproductiveSuccessStruct.allWeightToReprodSuccessWeight(params.reprodSuccessCurveNumber,:);
weightToReprodSuccessReprodSuccess = reproductiveSuccessStruct.allWeightToReprodSuccessReprodSuccess(params.reprodSuccessCurveNumber,:);

popSnapshot = [];
snapshotMonth = NaN;

id = [];
dob = [];
dod = [];
naturalDod = [];
infectionNumber = [];
infectionEnds = [];
resistanceEnds = [];
ageAtFirstParturation = [];
joeysHad = [];
gender = [];
vaccinationTime = [];
joey = [];
leavesHospital = [];
diseaseStageCEmerges = [];
diseaseStageBEmerges = [];
diseaseStageAEmerges = [];
breedsNext = [];
infectionStarted = [];
weightTrackParamA = [];


inHospitalId = [];
inHospitalDob = [];
inHospitalDod = [];
inHospitalNaturalDod = [];
inHospitalInfectionNumber = [];
inHospitalInfectionEnds = [];
inHospitalResistanceEnds = [];
inHospitalAgeAtFirstParturation = [];
inHospitalJoeysHad = [];
inHospitalGender = [];
inHospitalVaccinationTime = [];
inHospitalJoey = [];
inHospitalLeavesHospital = [];
inHospitalDiseaseStageCEmerges = [];
inHospitalDiseaseStageBEmerges = [];
inHospitalDiseaseStageAEmerges = [];
inHospitalBreedsNext = [];
inHospitalInfectionStarted = [];

lastNewKoalaID = 0;
calendarOffsetFromStartingPop = 0;
% If an initial number of koalas has been specified, create that number of
% koalas.
if ~isempty(startingKoalas)
    % Check to see if both startingKoalas and startingPopulation have been
    % specified. If they have, it is likely that this function has been
    % called incorrectly, so we throw an error.
    if ~isempty(startingPopulation)
        err = MException('setUpErr:tooManyInputs','Attempting to specify both a starting population and a starting number of koalas to be randomly generated.')
    end
    startingPopulation = determineOneRandomStartingPop(params, startingKoalas, reproductiveSuccessStruct, rng);
    
end

importPopulation();
filterEligibleForImmigration = isEligibleForMigration();
startingKoalas = length(dob);
lastNewKoalaID = max(id);

% Adds infections to initial population if necessary.
if ~isempty(initialPrevalence) && initialPrevalence ~= 0
    startingKoalas = length(dob);
    randomlyPermutedIndexes = randperm(startingKoalas);
    totalKoalasInfected = floor(startingKoalas * initialPrevalence);
    infectedKoalaIndexes = randomlyPermutedIndexes(1:totalKoalasInfected);
    filterKoalasInfected = false(startingKoalas,1);
    filterKoalasInfected(infectedKoalaIndexes) = true;
    newInfectionsThisIteration = 0;
    currentMonth = 0;
    setUpNewInfections(filterKoalasInfected);
end

populationRecord = zeros(1,monthsToSimulate);
infectedPopulationRecord = zeros(1,monthsToSimulate);
incidenceRecord = zeros(1,monthsToSimulate);
diseasedPopulationRecord = zeros(1,monthsToSimulate);
vaccinatedRecord = zeros(1,monthsToSimulate);
mothersWithYoungRecord = zeros(1,monthsToSimulate);
potentialMothersRecord = zeros(1,monthsToSimulate);
shouldBeHospitalizedRecord = zeros(1,monthsToSimulate);
shouldBeEuthanizedRecord = zeros(1,monthsToSimulate);
deathsRecord = zeros(1,monthsToSimulate);
vaccinationRecord = zeros(1,monthsToSimulate);
deathsByEuthanasiaRecord = zeros(1,monthsToSimulate);
deathsByDiseaseRecord = zeros(1,monthsToSimulate);
deathsByOtherRecord = zeros(1,monthsToSimulate);
deathsMotherDiedRecord = zeros(1,monthsToSimulate);
immigrantsEnteredRecord = zeros(1,monthsToSimulate);
emigrantsExitedRecord = zeros(1,monthsToSimulate);
if isSnapshotRecordNecessary
    monthToTakeAnnualSnapshotForRecord = 0; % 0 is December
    currentSnapshotRecordKoalaCapacity = 1000;
    blankSnapshotRecordDummyEntry = -99;
    snapshotRecord.ageInMonths = blankSnapshotRecordDummyEntry * ones(currentSnapshotRecordKoalaCapacity, yearsToSimulate, 'int8');
    snapshotRecord.encodedStatus = blankSnapshotRecordDummyEntry * ones(currentSnapshotRecordKoalaCapacity, yearsToSimulate, 'int8');
end

femaleJoeyPopulationRecord = zeros(1,monthsToSimulate);
femaleJuvenilePopulationRecord = zeros(1,monthsToSimulate);
femaleYoungBreederPopulationRecord = zeros(1,monthsToSimulate);
femaleMatureBreederPopulationRecord = zeros(1,monthsToSimulate);
femaleOldPopulationRecord = zeros(1,monthsToSimulate);
maleJoeyPopulationRecord = zeros(1,monthsToSimulate);
maleJuvenilePopulationRecord = zeros(1,monthsToSimulate);
maleYoungBreederPopulationRecord = zeros(1,monthsToSimulate);
maleMatureBreederPopulationRecord = zeros(1,monthsToSimulate);
maleOldPopulationRecord = zeros(1,monthsToSimulate);
femaleJoeyInfectedRecord = zeros(1,monthsToSimulate);
femaleJuvenileInfectedRecord = zeros(1,monthsToSimulate);
femaleYoungBreederInfectedRecord = zeros(1,monthsToSimulate);
femaleMatureBreederInfectedRecord = zeros(1,monthsToSimulate);
femaleOldInfectedRecord = zeros(1,monthsToSimulate);
maleJoeyInfectedRecord = zeros(1,monthsToSimulate);
maleJuvenileInfectedRecord = zeros(1,monthsToSimulate);
maleYoungBreederInfectedRecord = zeros(1,monthsToSimulate);
maleMatureBreederInfectedRecord = zeros(1,monthsToSimulate);
maleOldInfectedRecord = zeros(1,monthsToSimulate);
femaleJoeyDiseasedRecord = zeros(1,monthsToSimulate);
femaleJuvenileDiseasedRecord = zeros(1,monthsToSimulate);
femaleYoungBreederDiseasedRecord = zeros(1,monthsToSimulate);
femaleMatureBreederDiseasedRecord = zeros(1,monthsToSimulate);
femaleOldDiseasedRecord = zeros(1,monthsToSimulate);
maleJoeyDiseasedRecord = zeros(1,monthsToSimulate);
maleJuvenileDiseasedRecord = zeros(1,monthsToSimulate);
maleYoungBreederDiseasedRecord = zeros(1,monthsToSimulate);
maleMatureBreederDiseasedRecord = zeros(1,monthsToSimulate);
maleOldDiseasedRecord = zeros(1,monthsToSimulate);

susceptibleKoalaMonths = 0;
totalInfections = 0;

% Loop for required number of years, exiting if the current population of
% koalas (i.e. length(dob)) exceeds the maximum population, or if all
% koalas die.

allKoalasDeadFlag = false;
idsOfNewMothers = [];
idsOfInfectedNewMothers = [];
currentMonth = 1;
tic
stopFlag.error = false;
stopFlag.simulatedRequiredYears = currentMonth >= monthsToSimulate;
stopFlag.maxPermittedPopExceeded = length(dob) > calibrationParams.maxPermittedPopulation;
stopFlag.allKoalasDead = isempty(dob) || allKoalasDeadFlag;
stopFlag.prevalenceZeroWhenRequiredPositive = calibrationParams.prevalenceMustBeGTZero && currentMonth > 1 && infectedPopulationRecord(currentMonth-1) == 0;
while ~stopFlag.error && ~stopFlag.simulatedRequiredYears && ~stopFlag.maxPermittedPopExceeded && ~stopFlag.allKoalasDead && ~stopFlag.prevalenceZeroWhenRequiredPositive
    try
        idAtStart = id;
        killKoalasFnCalledFlag = false;
        removeEmigrantsFnCalledFlag = false;
        
        if isTakeSnapshotNecessary && isempty(popSnapshot) && length(dob) >= calibrationParams.minSnapshotSize && length(dob) <= calibrationParams.maxSnapshotSize ...
                && currentMonth/12 >= calibrationParams.minYearsBeforeSnapshot
            popSnapshot =  takeSnapshot();
            snapshotMonth = popSnapshot.currentMonth;
        end
        
        susceptibleKoalaMonths = susceptibleKoalaMonths + sum(infectionEnds <= currentMonth);
        newInfectionsThisIteration = 0;
        filterMarkedForDeath = false(length(dob),1);
        
        %% JOEYS BECOME INDEPENDENT
        filterJoeysWhoBecomeIndependent = joeysOfTheseMothers(true(length(dob),1)) & ageInYears() >= params.juvenileAge;
        joeysBecomeIndependent(filterJoeysWhoBecomeIndependent);
        
        
        %% FIELD CAPTURES
        %==================================
        % FIELD CAPTURES
        %==================================
        if currentMonth <= length(vaccineProtocol.numberOfCapturesByMonth)
            numberOfCapturesThisMonth = vaccineProtocol.numberOfCapturesByMonth(currentMonth);
            
            if numberOfCapturesThisMonth > 0
                % We are assuming thuat only one group is targeted, hence
                % .groups(1) .
                if vaccineProtocol.cull == 0 % Not culling
                    if vaccineProtocol.groups(1).mothersOnly == true
                        filterMothersIfNecessary = ~isnan(joey);
                        filterGenderToVaccinate = gender == female;
                    else
                        filterMothersIfNecessary = true(length(dob),1);
                        
                        if vaccinateBothGenders
                            filterGenderToVaccinate = true(length(dob),1);
                        else
                            if vaccinateMales
                                filterGenderToVaccinate = gender == male;
                            elseif vaccinateFemales
                                filterGenderToVaccinate = gender == female;
                            end
                        end
                        
                    end
                    if vaccineProtocol.targetUnvaccinatedKoalas
                        filterUnvaccinatedKoalasIfNecessary = isnan(vaccinationTime);
                    else
                        filterUnvaccinatedKoalasIfNecessary = true(length(dob),1);
                    end
                    if vaccineProtocol.groups(1).motherAndJoeyAsSet == true
                        filterNonJoeys = ~joeysOfTheseMothers(true(length(dob),1));
                        filterPreferencedKoalas = ...
                            filterGenderToVaccinate & ...
                            getWeights() >= vaccineProtocol.groups(1).minWeight & ...
                            ageInYears() >= vaccineProtocol.groups(1).minAge & ...
                            ageInYears() <= vaccineProtocol.groups(1).maxAge & ...
                            filterMothersIfNecessary & filterUnvaccinatedKoalasIfNecessary & ...
                            filterNonJoeys ...
                            & ~isInHospital(); %
                        
                        filterNonPreferencedNonJoeysNotInHosp = filterNonJoeys & ~filterPreferencedKoalas & ~isInHospital();
                        
                        % Randomly permute the indexes of all koalas, but with the
                        % preferenced koalas first.
                        indexesOfPreferencedKoalas = find(filterPreferencedKoalas);
                        permutedIndexesOfPreferencedKoalas = randpermArray(indexesOfPreferencedKoalas);
                        indexesOfNonPreferencedNonJoeys = find(filterNonPreferencedNonJoeysNotInHosp);
                        permutedIndexesOfNonPreferencedNonJoeysNotInHosp = randpermArray(indexesOfNonPreferencedNonJoeys);
                        permutedIndexesOfAllNonJoeysNotInHosp = [permutedIndexesOfPreferencedKoalas; permutedIndexesOfNonPreferencedNonJoeysNotInHosp];
                        if vaccineProtocol.proportionLocateable < 1
                            nKoalasCanBeFound = round(vaccineProtocol.proportionLocateable * length(permutedIndexesOfAllNonJoeysNotInHosp));
                            filterIndexexThatCanBeFound = false(size(permutedIndexesOfAllNonJoeysNotInHosp));
                            filterIndexexThatCanBeFound(randsample(1:length(permutedIndexesOfAllNonJoeysNotInHosp), nKoalasCanBeFound)) = true;
                            permutedIndexesOfAllNonJoeysNotInHosp = permutedIndexesOfAllNonJoeysNotInHosp(filterIndexexThatCanBeFound);
                        end
                        
                        % Mothers with joeys count as two koalas (the mother and their
                        % joey), so we need to take this into account when selecting
                        % the right number of koalas to vaccinate.
                        hasAJoeyByIndex = ~isnan(joey(permutedIndexesOfAllNonJoeysNotInHosp));
                        numberOfKoalasPerEntryByIndex = ones(length(permutedIndexesOfAllNonJoeysNotInHosp),1) + hasAJoeyByIndex;
                        cumulativeSumOfKoalasByIndex = cumsum(numberOfKoalasPerEntryByIndex);
                        
                        indexWhereCumSumIsGTNumberToCapture = find(cumulativeSumOfKoalasByIndex >= numberOfCapturesThisMonth,1,'first');
                        if isempty(indexWhereCumSumIsGTNumberToCapture)
                            indexWhereCumSumIsGTNumberToCapture = length(dob);
                        end
                        if indexWhereCumSumIsGTNumberToCapture > length(permutedIndexesOfAllNonJoeysNotInHosp)
                            indexesOfNonJoeysToCapture = permutedIndexesOfAllNonJoeysNotInHosp;
                        else
                            indexesOfNonJoeysToCapture = permutedIndexesOfAllNonJoeysNotInHosp(1:indexWhereCumSumIsGTNumberToCapture);
                        end
                        filterNonJoeysToCapture = indexToFilter(indexesOfNonJoeysToCapture);
                        filterJoeysToCapture = joeysOfTheseMothers(filterNonJoeysToCapture);
                        filterCapturedKoalas = filterNonJoeysToCapture | filterJoeysToCapture;
                    else % if mothers and joeys are not counted as a set
                        
                        error('Code for mothers and joeys not counted as set has not been checked.')
                        
                        filterPreferencedKoalas = ...
                            filterGenderToVaccinate & ...
                            getWeights() >= vaccineProtocol.groups(1).minWeight & ...
                            ageInYears() >= vaccineProtocol.groups(1).minAge & ...
                            ageInYears() <= vaccineProtocol.groups(1).maxAge & ...
                            filterMothersIfNecessary & filterUnvaccinatedKoalasIfNecessary;
                        
                        indexesOfPreferencedKoalas = find(filterPreferencedKoalas);
                        permutedIndexesOfPreferencedKoalas = randpermArray(indexesOfPreferencedKoalas);
                        indexesOfNonPreferencedKoalas = find(~filterPreferencedKoalas);
                        permutedIndexesOfNonPreferencedKoalas = randpermArray(indexesOfNonPreferencedKoalas);
                        permutedIndexesOfAllKoalas = [permutedIndexesOfPreferencedKoalas; permutedIndexesOfNonPreferencedKoalas];
                        
                        indexesOfKoalasToCapture = permutedIndexesOfAllKoalas(1:min(numberOfCapturesThisMonth,length(permutedIndexesOfAllKoalas)));
                        filterCapturedKoalas = indexToFilter(indexesOfKoalasToCapture);
                        
                    end % if mothers and joeys are not counted as a set
                    
                    
                    filterCapturedAndWillGoToHospital = filterCapturedKoalas & needsToGoToHospital();
                    filterCapturedAndWillBeEuthanized = filterCapturedKoalas & needsToBeEuthanized();
                    filterCapturedButWillNotGoToHospital = filterCapturedKoalas & ~filterCapturedAndWillGoToHospital & ~filterCapturedAndWillBeEuthanized;
                    goToHospital(filterCapturedAndWillGoToHospital);
                    vaccinate(filterCapturedAndWillGoToHospital | filterCapturedButWillNotGoToHospital);
                    vaccinationRecord(currentMonth) = sum(filterCapturedAndWillGoToHospital | filterCapturedButWillNotGoToHospital);
                    deathsByEuthanasiaRecord(currentMonth) = sum(filterCapturedAndWillBeEuthanized);
                    euthanize(filterCapturedAndWillBeEuthanized);
                    
                else
                    permutedIndexesOfKoalas = [];
                    filterDiseaseCKoalas = diseaseStageCEmerges <= currentMonth;
                    filterDiseaseBKoalas = diseaseStageBEmerges <= currentMonth;
                    filterDiseaseAKoalas = diseaseStageBEmerges <= currentMonth;
                    filterInfectedKoalas = isInfected();
                    filterSterileKoalas = filterDiseaseBKoalas & gender == female;
                    filterSterileNotCKoalas = filterSterileKoalas & ~filterDiseaseCKoalas;
                    filterInfectedNotCKoalas = filterInfectedKoalas & ~filterDiseaseCKoalas;
                    filterDiseaseBNotCKoalas = filterDiseaseBKoalas & ~filterDiseaseCKoalas;
                    filterDiseaseANotCNorBKoalas = filterDiseaseAKoalas & ~filterDiseaseCKoalas & ~filterDiseaseBKoalas;
                    filterInfectedNotDiseasedKoalas = filterInfectedKoalas & ~filterDiseaseCKoalas & ~filterDiseaseBKoalas & ~filterDiseaseAKoalas;
                    indexesOfDiseaseCKoalas = find(filterDiseaseCKoalas);
                    indexesOfDiseaseBNotCKoalas = find(filterDiseaseBNotCKoalas);
                    indexesOfDiseaseANotCNorBKoalas = find(filterDiseaseANotCNorBKoalas);
                    indexesOfInfectedNotDiseasedKoalas = find(filterInfectedNotDiseasedKoalas);
                    indexesOfInfectedKoalas = find(isInfected());
                    indexesOfSterileKoalas = find(filterSterileKoalas);
                    indexesOfSterileNotCKoalas = find(filterSterileNotCKoalas);
                    indexesOfInfectedNotCKoalas = find(filterInfectedNotCKoalas);
                    if vaccineProtocol.cull == 1 % Cull by body score
                        [~, permutedIndexesOfKoalas] = sort(getBodyScore());
                    elseif vaccineProtocol.cull == 2 % Cull by sickness and infection, prioritising by severity
                        permutedIndexesOfKoalas = ...
                            [randpermArray(indexesOfDiseaseCKoalas); ...
                            randpermArray(indexesOfDiseaseBNotCKoalas); ...
                            randpermArray(indexesOfDiseaseANotCNorBKoalas); ...
                            randpermArray(indexesOfInfectedNotDiseasedKoalas)];
                    elseif vaccineProtocol.cull == 3 % Cull by infection
                        permutedIndexesOfKoalas = randpermArray(indexesOfInfectedKoalas);
                    elseif vaccineProtocol.cull == 4 % Cull by sickness (not infection), prioritising by severity
                        permutedIndexesOfKoalas = ...
                            [randpermArray(indexesOfDiseaseCKoalas); ...
                            randpermArray(indexesOfDiseaseBNotCKoalas); ...
                            randpermArray(indexesOfDiseaseANotCNorBKoalas)];
                    elseif vaccineProtocol.cull == 5 % Cull by disease stage C only
                        indexesOfDiseaseCKoalas = find(filterDiseaseCKoalas);
                        permutedIndexesOfKoalas = ...
                            randpermArray(indexesOfDiseaseCKoalas);
                    elseif vaccineProtocol.cull == 6 || vaccineProtocol.cull == 10
                        % 6 = cull with any koala eligible
                        % 10 = random selection, with diseased culled and antibiotics to all others
                        permutedIndexesOfKoalas = randpermArray(1:length(dob));
                    elseif vaccineProtocol.cull == 7 || vaccineProtocol.cull == 9 || vaccineProtocol.cull == 11 || vaccineProtocol.cull == 12 || vaccineProtocol.cull == 13
                        % 7 = cull by disease and infection, no prioritising
                        % 9 = target both diseased and infected: cull diseased, antibiotics to infected
                        % 11 = target both diseased and infected: cull disease stage B & C, antibiotics to disease stage A and infected
                        % 13 = target both diseased and infected: no culling, antibiotics to disease stage A & B & C and infected
                        permutedIndexesOfKoalas = ...
                            randpermArray([indexesOfDiseaseCKoalas; indexesOfDiseaseBNotCKoalas; indexesOfDiseaseANotCNorBKoalas; indexesOfInfectedNotDiseasedKoalas]);
                    elseif vaccineProtocol.cull == 8 % Cull by disease, no prioritising
                        permutedIndexesOfKoalas = ...
                            randpermArray([indexesOfDiseaseCKoalas; indexesOfDiseaseBNotCKoalas; indexesOfDiseaseANotCNorBKoalas]);
                    elseif vaccineProtocol.cull == 14 % Cull disease stage B (females only) & C, no prioritising.
                        permutedIndexesOfKoalas = ...
                            randpermArray(unique([indexesOfDiseaseCKoalas; indexesOfSterileKoalas]));
                    elseif vaccineProtocol.cull == 15 || vaccineProtocol.cull == 16 || vaccineProtocol.cull == 17
                        % 15 = 'Cull and treat': Cull disease stage B (females only) & C; antibiotics to infected, no prioritising. 
                        % 16 = 'Treat only': Antibiotics to disease stage B (females only) & C & infected, no prioritising.
                        % 17 = 'Cull only': Cull disease stage B (females only) & C & infected, no prioritising.
                        permutedIndexesOfKoalas = ...
                            randpermArray(unique([indexesOfDiseaseCKoalas; indexesOfSterileKoalas; indexesOfInfectedKoalas]));
                    end
                    filterCaptured = indexToFilter(permutedIndexesOfKoalas(1:min(numberOfCapturesThisMonth,length(permutedIndexesOfKoalas))));
                    if vaccineProtocol.cull == 9 || vaccineProtocol.cull == 10
                        filterCapturedAndInfectedNotDiseased = filterCaptured & filterInfectedNotDiseasedKoalas;
                        filterCapturedAndDiseased = filterCaptured & ~filterInfectedNotDiseased;
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCapturedAndDiseased);
                        euthanize(filterCapturedAndDiseased);
                        cureKoalas(filterCapturedAndInfectedNotDiseased);
                    elseif vaccineProtocol.cull == 11
                        filterEligibleToTreat = filterDiseaseANotCNorBKoalas | filterInfectedNotDiseasedKoalas;
                        filterEligibleToCull = filterDiseaseCKoalas | filterDiseaseBKoalas;
                        filterCapturedAndEligibleToTreat = filterCaptured & filterEligibleToTreat;
                        filterCapturedAndEligibleToCull = filterCaptured & filterEligibleToCull;
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCapturedAndEligibleToCull);
                        euthanize(filterCapturedAndEligibleToCull);
                        cureKoalas(filterCapturedAndEligibleToTreat);
                    elseif vaccineProtocol.cull == 12
                        filterEligibleToTreat = filterDiseaseANotCNorBKoalas | filterDiseaseBNotCKoalas | filterInfectedNotDiseasedKoalas;
                        filterEligibleToCull = filterDiseaseCKoalas;
                        filterCapturedAndEligibleToTreat = filterCaptured & filterEligibleToTreat;
                        filterCapturedAndEligibleToCull = filterCaptured & filterEligibleToCull;
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCapturedAndEligibleToCull);
                        euthanize(filterCapturedAndEligibleToCull);
                        cureKoalas(filterCapturedAndEligibleToTreat);
                    elseif vaccineProtocol.cull == 13
                        filterEligibleToTreat = filterDiseaseANotCNorBKoalas | filterDiseaseBNotCKoalas | filterInfectedNotDiseasedKoalas;
                        filterCapturedAndEligibleToTreat = filterCaptured & filterEligibleToTreat;
                        cureKoalas(filterCapturedAndEligibleToTreat);
                        cureDiseaseCKoalas(filterDiseaseCKoalas & filterCaptured);
                    elseif vaccineProtocol.cull == 14
                        % 14 = Cull disease stage B (females only) & C, no prioritising.
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCaptured);
                        euthanize(filterCaptured);
                    elseif vaccineProtocol.cull == 15 
                        % 15 = 'Cull and treat': Cull disease stage B (females only) & C; antibiotics to infected, no prioritising.
                        filterEligibleToCull = filterDiseaseCKoalas | filterSterileKoalas;
                        filterCapturedAndEligibleToCull = filterCaptured & filterEligibleToCull;
                        filterCapturedAndEligibleToTreat = filterCaptured & ~filterEligibleToCull;
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCapturedAndEligibleToCull);
                        euthanize(filterCapturedAndEligibleToCull);
                        cureKoalas(filterCapturedAndEligibleToTreat);
                    elseif vaccineProtocol.cull == 16
                        % 16 = 'Treat only': Antibiotics to disease stage B (females only) & C & infected, no prioritising.
                        filterCapturedAndEligibleToTreatNotC = filterCaptured & ~filterDiseaseCKoalas;
                        cureKoalas(filterCapturedAndEligibleToTreatNotC);
                        cureDiseaseCKoalas(filterDiseaseCKoalas & filterCaptured);
                    elseif vaccineProtocol.cull == 17
                        % 17 = 'Cull only': Cull disease stage B (females only) & C & infected, no prioritising.
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCaptured);
                        euthanize(filterCaptured);
                    else
                        deathsByEuthanasiaRecord(currentMonth) = sum(filterCaptured);
                        euthanize(filterCaptured);
                    end
                end % vaccineProtocol.cull == 0
            end % numberOfCapturesThisMonth > 0
        end
        
        
        
        %% INFECTIONS
        %==================================
        % INFECTIONS
        %==================================
        
        if params.mateOutsideBreedingSeason || isBreedingSeason(currentMonth) % Also encompasses BIRTHS section
            filterYoungBreedingFemales = ...
                ~isInHospital() ...
                & gender == female ...
                & ageInYears() >= params.femaleYoungBreedingAge ...
                & ageInYears() < params.femaleDominantBreedingAge ...
                & breedsNext <= currentMonth ...
                & rand(length(dob),1) < params.youngFemaleMatesProbability;
            filterDominantBreedingFemales = ...
                ~isInHospital() ...
                & gender == female ...
                & ageInYears() >= params.femaleDominantBreedingAge ...
                & ageInYears() < params.femaleOldAge ...
                & breedsNext <= currentMonth;
            filterOldBreedingFemales = ...
                ~isInHospital() ...
                & gender == female ...
                & ageInYears() >= params.femaleOldAge ...
                & breedsNext <= currentMonth;
             
            filterBreedingFemales = filterYoungBreedingFemales | filterDominantBreedingFemales | filterOldBreedingFemales;
            numberOfBreedingFemales = sum(filterBreedingFemales);
            
            filterYoungBreedingMales = ...
                ~isInHospital() ...
                & gender == male ...
                & ageInYears() >= params.maleYoungBreedingAge ...
                & ageInYears() < params.maleDominantBreedingAge;
            
            filterDominantBreedingMales = ...
                ~isInHospital() ...
                & gender == male ...
                & ageInYears() >= params.maleDominantBreedingAge;
            
            filterBreedingMales = filterYoungBreedingMales | filterDominantBreedingMales;
            numberOfBreedingMales = sum(filterBreedingMales);
            
            totalNumberOfPartnerships = min(numberOfBreedingFemales, params.mD*numberOfBreedingMales);
            
            if (numberOfBreedingFemales > 0 && numberOfBreedingMales > 0) % Also encompasses BIRTHS section
                
                indexesOfBreedingFemales = find(filterBreedingFemales);
                permutedIndexesOfBreedingFemales = randpermArray(indexesOfBreedingFemales);
                
                % Each row of maleMateMatrix corresponds to one koala.
                % Rows of maleMateMatrix corresponding to female koalas are all NaN.
                % Each col of maleMateMatrix corresponds to 'round' of breeding within month, so as to impose an order on breeding events for individual males.
                % Entries of maleMateMatrix are indexes of female partners.
                % No female mates with more than one partner, so the order in which one
                % male's mating events occur relative to another male's mating events
                % is irrelevant. 
                roundsOfMatingNeeded = params.mD;
                maleMateMatrix = zeros(length(dob), roundsOfMatingNeeded, 'uint32');
                
                probWeights = repmat(getRelativeMatingProb(),[1 roundsOfMatingNeeded]);
                probWeightsCorrespondingToMales = probWeights(gender == male, :);
                
                indexesOfMaleMateMatrix = reshape(1:numel(maleMateMatrix), size(maleMateMatrix));
                indexesOfMaleMateMatrixCorrespondingToMales = indexesOfMaleMateMatrix(gender == male, :);
                maleMateMatrix( datasample(reshape(indexesOfMaleMateMatrixCorrespondingToMales, 1, numel(indexesOfMaleMateMatrixCorrespondingToMales)) ...
                    , totalNumberOfPartnerships, 'Replace', false, 'Weights', reshape(probWeightsCorrespondingToMales, 1, numel(probWeightsCorrespondingToMales)))) ...
                    = permutedIndexesOfBreedingFemales(1:totalNumberOfPartnerships);
                
                % We will use filterFemalesWhoMate in BIRTHS section to determine
                % whether females who mated conceive.
                filterFemalesWhoMate = false(length(dob),1);
                filterFemalesWhoMate(permutedIndexesOfBreedingFemales(1:totalNumberOfPartnerships)) = true;
                
                % Check that only rows of maleMateMatrix have non-NaN entries,
                % and that all breeding females are present in maleMateMatrix.
                isZeroMaleMateMatrix = maleMateMatrix == 0;
                if not(all(all(isZeroMaleMateMatrix(gender == female,:)))) || sum(sum(not(isZeroMaleMateMatrix(gender == male,:)))) ~= totalNumberOfPartnerships
                    error('maleMateMatrix has non-zero entries in female rows, or does not have totalNumberOfPartnerships non-zero entries in male rows.')
                end
                
                % Loop over columns of maleMateMatrix. This processes the mating events in
                % order, so that on-transmission within a month can occur.
                
                for indRound = 1:size(maleMateMatrix,2)
                    maleMatesForThisRound = maleMateMatrix(:,indRound);
                    % If any males have partners in this round, check for new infections
                    % etc.
                    if sum(maleMatesForThisRound ~= 0) > 0
                        filterInfectedKoalas = infectionEnds > currentMonth;
                        
                        
                        oneToLength = (1:length(dob))';
                        partnersIndexVector = maleMatesForThisRound; % Partners of males
                        partnersIndexVector(maleMatesForThisRound(maleMatesForThisRound ~= 0)) = oneToLength(maleMatesForThisRound ~= 0); % partners of females
                        filterKoalasWithPartners = partnersIndexVector ~= 0;
                        
                        filterKoalasWhoMateWithInfectedKoalas = false(length(dob),1);
                        filterKoalasWhoMateWithInfectedKoalas(filterKoalasWithPartners) = filterInfectedKoalas(partnersIndexVector(filterKoalasWithPartners));
                        filterInfectedKoalasWhoMateWithInfectedKoalas = filterKoalasWhoMateWithInfectedKoalas & infectionEnds > currentMonth;
                        filterUninfectedKoalasWhoMateWithInfectedKoalas = filterKoalasWhoMateWithInfectedKoalas & infectionEnds <= currentMonth;
                        filterVaccinatedKoalasWhoMateWithInfectedKoalas = ~isnan(vaccinationTime) & filterKoalasWhoMateWithInfectedKoalas;
                        
                        if calibrationParams.matingWithInfectedPartnerCanCauseDisease
                            determineNewDisease(filterInfectedKoalasWhoMateWithInfectedKoalas);
                        end
                        
                        infectiousnessOfPartner = zeros(length(dob),1);
                        infectiousnessOfAllKoalas = getInfectiousness();
                        infectiousnessOfPartner(filterKoalasWithPartners) = infectiousnessOfAllKoalas(partnersIndexVector(filterKoalasWithPartners));
                        reductionDueToVaccine = 0;
                        if vaccineProtocol.preventsWhat == 0 || vaccineProtocol.preventsWhat == 3
                            reductionDueToVaccine = calculateReductionDueToVaccine();
                        end
                        chanceOfContracting = infectiousnessOfPartner .* getBaseMaleOrFemaleTransmissionProbability() ...
                            .* (1 - calculateReductionDueToResistance()) ...
                            .* (1 - reductionDueToVaccine);
                        filterNewlyInfectedKoalas = filterUninfectedKoalasWhoMateWithInfectedKoalas & rand(length(dob),1) < chanceOfContracting;
                        setUpNewInfections(filterNewlyInfectedKoalas);
                        
                        if vaccineProtocol.boostFromMating
                            boostFromMating(filterVaccinatedKoalasWhoMateWithInfectedKoalas & ~filterNewlyInfectedKoalas);
                        end
                    end
                end
                
                
                
                %% BIRTHS
                %==================================
                % BIRTHS
                %==================================
                % Determine all mothers who conceive joeys and carry them to pouch
                % emergence.
                
                if params.mateOutsideBreedingSeason || isBreedingSeason(currentMonth)
                    randomVector = rand(length(dob),1);
                    % To determine new mothers, we filter with filterFemalesWhoMate so
                    % that only females who actually mated are considered, and also
                    % with filterYoungBreedingFemales etc. to avoid having to classify
                    % females by age a second time in one iteration (as it has already
                    % been done in INFECTIONS section).
                    filterNewMothers = ~isInfertileOrSterile() & filterFemalesWhoMate & ...
                        ( (filterYoungBreedingFemales & randomVector <= (params.youngFemaleBreedingReduction * params.monthlyProbabilityOfConceivingIfMated(getCalendarMonth(currentMonth)))) ...
                        | (filterDominantBreedingFemales & randomVector <= params.monthlyProbabilityOfConceivingIfMated(getCalendarMonth(currentMonth))) ...
                        | (filterOldBreedingFemales & randomVector <= (params.oldFemaleBreedingReduction * params.monthlyProbabilityOfConceivingIfMated(getCalendarMonth(currentMonth))))  );
                    filterFemalesWhoMatedButAreNotNewMothers = (filterYoungBreedingFemales | filterDominantBreedingFemales | filterOldBreedingFemales) & ~filterNewMothers;
                    
                    breedsNext(filterFemalesWhoMatedButAreNotNewMothers) = currentMonth + params.monthsFromFailedMatingUntilNextMating;
                    breedsNext(filterNewMothers) = NaN;
                    filterInfectedNewMothers = filterNewMothers & isInfected();
                    % We will kill some koalas before the new joeys are created, and this
                    % will make the filters inaccurate; therefore, we record IDs of new
                    % mothers.
                    idsOfNewMothers = id(filterNewMothers);
                    idsOfInfectedNewMothers = id(filterInfectedNewMothers);
                end
            end
        end
        
        
        %% CHECK THAT IDS ARE THE SAME AS THEY WERE AT START OF ITERATION
        % If they are not, then some part of the code is adding/removing/moving
        % koalas, which should not happen, so throw an error.
        if ~all(id == idAtStart)
            err = MException('modelRunErr:idsChangedDuringIteration','ID vector has changed during iteration. Code is probably adding/removing/moving IDs illegally.');
        end
        
        %% BIRTHS AND DEATHS
        %==================================
        % BIRTHS AND DEATHS
        %==================================
        % Births and deaths affect the positions of koalas, and so will disturb
        % previously created filters. Therefore, births and deaths should
        % happen at the end of each iteration (although before immigration and emigration).
        deathsByOtherRecord(currentMonth) = sum(dod <= currentMonth & dod == naturalDod);
        deathsByDiseaseRecord(currentMonth) = sum(dod <= currentMonth & dod ~= naturalDod);
        filterMarkedForDeath = filterMarkedForDeath | dod <= currentMonth;
        killKoalas(filterMarkedForDeath);
        
        % Check all koala vectors are same length
        % If they are not, then some part of the code is not cleaning up
        % correctly, so throw an error.
        idLength = length(id);
        if ...
                length(  dob  ) ~= idLength ...
                || length(	naturalDod	) ~= idLength ...
                || length(	gender	) ~= idLength ...
                || length(	dod	) ~= idLength ...
                || length(	infectionNumber	) ~= idLength ...
                || length(	infectionEnds	) ~= idLength ...
                || length(	resistanceEnds	) ~= idLength ...
                || length(	ageAtFirstParturation	) ~= idLength ...
                || length(	joeysHad	) ~= idLength ...
                || length(	vaccinationTime	) ~= idLength ...
                || length(	leavesHospital	) ~= idLength ...
                || length(	diseaseStageCEmerges	) ~= idLength ...
                || length(	diseaseStageBEmerges	) ~= idLength ...
                || length(	diseaseStageAEmerges	) ~= idLength ...
                || length(	breedsNext	) ~= idLength ...
                || length(	infectionStarted	) ~= idLength ...
                || length(	joey	) ~= idLength ...
                || length(  weightTrackParamA ) ~= idLength ...
                || ~all(ismember(joey(~isnan(joey)), id))
            err = MException('modelRunErr:unbalancedVectors','Koala property vectors are not all of same length. Code probably fails to clean up properly.');
            throw(err);
        else
            if idLength == 0
                allKoalasDeadFlag = true;
            else
                
                % Now that the dead koalas have been removed, we use the IDs of the new
                % mothers to create filters and create new joeys using these.
                filterRemainingNewMothers = ismember(id, idsOfNewMothers);
                filterRemainingInfectedNewMothers = ismember(id, idsOfInfectedNewMothers);
                numberOfNewJoeys = sum(filterRemainingNewMothers);
                newJoeyIDs = initialiseNewKoalas(numberOfNewJoeys, params.lengthOfPregnancyMonths);
                joey(filterRemainingNewMothers) = newJoeyIDs;
                % Determine whether or not a new joey whose mother is infected is also
                % infected.
                filterNewJoeysWhoAreVerticallyInfected = joeysOfTheseMothers(filterRemainingInfectedNewMothers) & rand(length(dob),1) < getInfectiousness() * params.tj;
                setUpNewInfections(filterNewJoeysWhoAreVerticallyInfected);
                
            end
        end
        
        %% IMMIGRATION AND EMIGRATION
        if vaccineProtocol.emigrationsByMonth(currentMonth) > 0
            filterEligibleForEmigration = isEligibleForMigration();
            if sum(filterEligibleForEmigration) <= vaccineProtocol.emigrationsByMonth(currentMonth)
                filterEmigrants = filterEligibleForEmigration;
            else
                filterEmigrants = false(size(filterEligibleForEmigration));
                filterEmigrants(randsample(find(filterEligibleForEmigration), vaccineProtocol.emigrationsByMonth(currentMonth), false)) = true;
            end
            numEmigrants = sum(filterEmigrants);
            removeEmigrants(filterEmigrants);
            emigrantsExitedRecord(currentMonth) = numEmigrants;
            addImmigrants(numEmigrants);
        end
        
        %% CHECK ALL KOALA VECTORS ARE SAME LENGTH AGAIN
        % If they are not, then some part of the code is not cleaning up
        % correctly, so throw an error.
        idLength = length(id);
        if ...
                length(  dob  ) ~= idLength ...
                || length(	naturalDod	) ~= idLength ...
                || length(	gender	) ~= idLength ...
                || length(	dod	) ~= idLength ...
                || length(	infectionNumber	) ~= idLength ...
                || length(	infectionEnds	) ~= idLength ...
                || length(	resistanceEnds	) ~= idLength ...
                || length(	ageAtFirstParturation	) ~= idLength ...
                || length(	joeysHad	) ~= idLength ...
                || length(	vaccinationTime	) ~= idLength ...
                || length(	leavesHospital	) ~= idLength ...
                || length(	diseaseStageCEmerges	) ~= idLength ...
                || length(	diseaseStageBEmerges	) ~= idLength ...
                || length(	diseaseStageAEmerges	) ~= idLength ...
                || length(	breedsNext	) ~= idLength ...
                || length(	infectionStarted	) ~= idLength ...
                || length(	joey	) ~= idLength ...
                || length(  weightTrackParamA ) ~= idLength ...
                || ~all(ismember(joey(~isnan(joey)), id))
            err = MException('modelRunErr:unbalancedVectors','Koala property vectors are not all of same length. Code probably fails to clean up properly.');
            throw(err);
        else
            if idLength == 0
                allKoalasDeadFlag = true;
            end
        end
        
        
        
        %% UPDATE RECORDS
        
        if isSnapshotRecordNecessary && mod(currentMonth,12) == monthToTakeAnnualSnapshotForRecord
            if length(dob) > currentSnapshotRecordKoalaCapacity
                % If snapshotRecord matrices do not contain as many rows as
                % there are now koalas, add enough rows to the snapshotRecord
                % matrices.
                oldSnapshotRecordKoalaCapacity = currentSnapshotRecordKoalaCapacity;
                currentSnapshotRecordKoalaCapacity = length(dob);
                snapshotRecord.ageInMonths((currentSnapshotRecordKoalaCapacity - oldSnapshotRecordKoalaCapacity +1):currentSnapshotRecordKoalaCapacity, :) = blankSnapshotRecordDummyEntry;
                snapshotRecord.encodedStatus((currentSnapshotRecordKoalaCapacity - oldSnapshotRecordKoalaCapacity +1):currentSnapshotRecordKoalaCapacity, :) = blankSnapshotRecordDummyEntry;
            end
            
            snapshotRecord.ageInMonths(1:length(dob),currentMonth/12) = currentMonth - dob;
            snapshotRecord.encodedStatus(1:length(dob),currentMonth/12) = encodeKoalaStatus(gender == female, ...
                isInfected(), ...
                diseaseStageAEmerges <= currentMonth & isInfected(), ...
                diseaseStageBEmerges <= currentMonth, ...
                diseaseStageCEmerges <= currentMonth);
        end
        
        populationRecord(currentMonth) = length(dob);
        infectedPopulationRecord(currentMonth) = sum(isInfected());
        incidenceRecord(currentMonth) = newInfectionsThisIteration;
        diseasedPopulationRecord(currentMonth) = sum(isDiseased());
        vaccinatedRecord(currentMonth) = sum(~isnan(vaccinationTime));
        mothersWithYoungRecord(currentMonth) = sum(~isnan(joey));
        potentialMothersRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleYoungBreedingAge);
        shouldBeHospitalizedRecord(currentMonth) = sum(needsToGoToHospital());
        shouldBeEuthanizedRecord(currentMonth) = sum(needsToBeEuthanized());
        % vaccinationRecord is updated in CAPTURE section
        totalInfections = totalInfections + newInfectionsThisIteration;
        
        femaleJoeyPopulationRecord(currentMonth) = sum(gender == female & ageInYears() < params.juvenileAge);
        femaleJuvenilePopulationRecord(currentMonth) = sum(gender == female & ageInYears() >= params.juvenileAge & ageInYears() < params.femaleYoungBreedingAge);
        femaleYoungBreederPopulationRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleYoungBreedingAge & ageInYears() < params.femaleDominantBreedingAge);
        femaleMatureBreederPopulationRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleDominantBreedingAge & ageInYears() < params.femaleOldAge);
        femaleOldPopulationRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleOldAge);
        
        maleJoeyPopulationRecord(currentMonth) = sum(gender == male & ageInYears() < params.juvenileAge);
        maleJuvenilePopulationRecord(currentMonth) = sum(gender == male & ageInYears() >= params.juvenileAge & ageInYears() < params.maleYoungBreedingAge);
        maleYoungBreederPopulationRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleYoungBreedingAge & ageInYears() < params.maleDominantBreedingAge);
        maleMatureBreederPopulationRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleDominantBreedingAge & ageInYears() < params.maleOldAge);
        maleOldPopulationRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleOldAge);
        
        femaleJoeyInfectedRecord(currentMonth) = sum(gender == female & ageInYears() < params.juvenileAge & isInfected());
        femaleJuvenileInfectedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.juvenileAge & ageInYears() < params.femaleYoungBreedingAge & isInfected());
        femaleYoungBreederInfectedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleYoungBreedingAge & ageInYears() < params.femaleDominantBreedingAge & isInfected());
        femaleMatureBreederInfectedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleDominantBreedingAge & ageInYears() < params.femaleOldAge & isInfected());
        femaleOldInfectedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleOldAge & isInfected());
        
        maleJoeyInfectedRecord(currentMonth) = sum(gender == male & ageInYears() < params.juvenileAge & isInfected());
        maleJuvenileInfectedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.juvenileAge & ageInYears() < params.maleYoungBreedingAge & isInfected());
        maleYoungBreederInfectedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleYoungBreedingAge & ageInYears() < params.maleDominantBreedingAge & isInfected());
        maleMatureBreederInfectedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleDominantBreedingAge & ageInYears() < params.maleOldAge & isInfected());
        maleOldInfectedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleOldAge & isInfected());
        
        femaleJoeyDiseasedRecord(currentMonth) = sum(gender == female & ageInYears() < params.juvenileAge & isDiseased());
        femaleJuvenileDiseasedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.juvenileAge & ageInYears() < params.femaleYoungBreedingAge & isDiseased());
        femaleYoungBreederDiseasedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleYoungBreedingAge & ageInYears() < params.femaleDominantBreedingAge & isDiseased());
        femaleMatureBreederDiseasedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleDominantBreedingAge & ageInYears() < params.femaleOldAge & isDiseased());
        femaleOldDiseasedRecord(currentMonth) = sum(gender == female & ageInYears() >= params.femaleOldAge & isInfected());
        
        maleJoeyDiseasedRecord(currentMonth) = sum(gender == male & ageInYears() < params.juvenileAge & isDiseased());
        maleJuvenileDiseasedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.juvenileAge & ageInYears() < params.maleYoungBreedingAge & isDiseased());
        maleYoungBreederDiseasedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleYoungBreedingAge & ageInYears() < params.maleDominantBreedingAge & isDiseased());
        maleMatureBreederDiseasedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleDominantBreedingAge & ageInYears() < params.maleOldAge & isDiseased());
        maleOldDiseasedRecord(currentMonth) = sum(gender == male & ageInYears() >= params.maleOldAge & isDiseased());
        
        currentMonth = currentMonth + 1;
        stopFlag.simulatedRequiredYears = currentMonth >= monthsToSimulate;
        stopFlag.maxPermittedPopExceeded = length(dob) > calibrationParams.maxPermittedPopulation;
        stopFlag.allKoalasDead = isempty(dob) || allKoalasDeadFlag;
        stopFlag.prevalenceZeroWhenRequiredPositive = calibrationParams.prevalenceMustBeGTZero && currentMonth > 1 && infectedPopulationRecord(currentMonth-1) == 0;
    catch err
        stopFlag.error = true;
        crashError = err;
    end
end


%% RESULTS

%==================================
% POST-SIMULATION RESULTS
%==================================

% Gets annual records for output, from monthly records that have been kept
% during simulation.
records.populationRecord = populationRecord;
records.infectedPopulationRecord = infectedPopulationRecord;
records.diseasedPopulationRecord = diseasedPopulationRecord;
records.vaccinatedRecord = vaccinatedRecord;
records.incidenceRecord = incidenceRecord;
records.mothersWithYoungRecord = mothersWithYoungRecord;
records.potentialMothersRecord = potentialMothersRecord;
records.shouldBeHospitalized = shouldBeHospitalizedRecord;
records.shouldBeEuthanized = shouldBeEuthanizedRecord;
records.deathsRecord = deathsRecord;
records.vaccinationRecord = vaccinationRecord;
records.deathsByDiseaseRecord = deathsByDiseaseRecord;
records.deathsByEuthanasiaRecord = deathsByEuthanasiaRecord;
records.deathsMotherDiedRecord = deathsMotherDiedRecord;
records.deathsByOtherRecord = deathsByOtherRecord;
records.immigrantsEnteredRecord = immigrantsEnteredRecord;
records.emigrantsExitedRecord = emigrantsExitedRecord;

records.femaleJoeyPopulationRecord = femaleJoeyPopulationRecord;
records.femaleJuvenilePopulationRecord = femaleJuvenilePopulationRecord;
records.femaleYoungBreederPopulationRecord = femaleYoungBreederPopulationRecord;
records.femaleMatureBreederPopulationRecord = femaleMatureBreederPopulationRecord;
records.femaleOldPopulationRecord = femaleOldPopulationRecord;

records.maleJoeyPopulationRecord = maleJoeyPopulationRecord;
records.maleJuvenilePopulationRecord = maleJuvenilePopulationRecord;
records.maleYoungBreederPopulationRecord = maleYoungBreederPopulationRecord;
records.maleMatureBreederPopulationRecord = maleMatureBreederPopulationRecord;
records.maleOldPopulationRecord = maleOldPopulationRecord;

records.femaleJoeyInfectedRecord = femaleJoeyInfectedRecord;
records.femaleJuvenileInfectedRecord = femaleJuvenileInfectedRecord;
records.femaleYoungBreederInfectedRecord = femaleYoungBreederInfectedRecord;
records.femaleMatureBreederInfectedRecord = femaleMatureBreederInfectedRecord;
records.femaleOldInfectedRecord = femaleOldInfectedRecord;

records.maleJoeyInfectedRecord = maleJoeyInfectedRecord;
records.maleJuvenileInfectedRecord = maleJuvenileInfectedRecord;
records.maleYoungBreederInfectedRecord = maleYoungBreederInfectedRecord;
records.maleMatureBreederInfectedRecord = maleMatureBreederInfectedRecord;
records.maleOldInfectedRecord = maleOldInfectedRecord;

records.femaleJoeyDiseasedRecord = femaleJoeyDiseasedRecord;
records.femaleJuvenileDiseasedRecord = femaleJuvenileDiseasedRecord;
records.femaleYoungBreederDiseasedRecord = femaleYoungBreederDiseasedRecord;
records.femaleMatureBreederDiseasedRecord = femaleMatureBreederDiseasedRecord;
records.femaleOldDiseasedRecord = femaleOldDiseasedRecord;

records.maleJoeyDiseasedRecord = maleJoeyDiseasedRecord;
records.maleJuvenileDiseasedRecord = maleJuvenileDiseasedRecord;
records.maleYoungBreederDiseasedRecord = maleYoungBreederDiseasedRecord;
records.maleMatureBreederDiseasedRecord = maleMatureBreederDiseasedRecord;
records.maleOldDiseasedRecord = maleOldDiseasedRecord;

finalPopulation = length(dob);
if finalPopulation > 0
    finalPrevalence = sum(isInfected()) / finalPopulation;
else
    finalPrevalence = 0;
end
maxPopulation = max(populationRecord(1:currentMonth));
lastYearPopulationPeaked = find(populationRecord(1:currentMonth) == maxPopulation,1,'last');
minPopulation = min(populationRecord(1:currentMonth));
lastYearPopulationTroughed = find(populationRecord(1:currentMonth) == minPopulation,1,'last');
populationIncreasing = populationRecord(currentMonth) > minPopulation;

results.startingPopSize = startingKoalas;
results.finalPopulation = finalPopulation;
results.finalPrevalence = finalPrevalence;
results.maxPopulation = maxPopulation;
results.lastYearPopulationPeaked = lastYearPopulationPeaked;
results.minPopulation = minPopulation;
results.lastYearPopulationTroughed = lastYearPopulationTroughed;
results.totalInfections = totalInfections;
results.susceptibleKoalaYears = susceptibleKoalaMonths / 12;
results.snapshotMonth = snapshotMonth;
results.lastMonthOfSim = currentMonth - 1; % -1 because currentMonth is incremented at the end of the loop, before the while condition is tested.

if displayStats
    disp(['Popn after ' num2str(currentMonth/12) ' years is ' num2str(finalPopulation) '.']);
    disp(['This popn / original popn = ' num2str(finalPopulation/startingKoalas) '.']);
    disp(['This gives a doubling time of ' num2str(log(2)*1/(1/(currentMonth/12)*log(finalPopulation/startingKoalas))) ' years.']);
    disp([]);  
    
    disp(['Prevalence at population peak: ' num2str(infectedPopulationRecord(lastYearPopulationPeaked)/populationRecord(lastYearPopulationPeaked))]);
    disp(['Took ' num2str(toc) ' seconds.']);
    disp(['Total number of koalas who lived: ' num2str(lastNewKoalaID)]);
    
    plot([populationRecord(1:currentMonth); ...
        infectedPopulationRecord(1:currentMonth); ...
        vaccinatedRecord(1:currentMonth)]');
    axis([0 currentMonth+5 10^0 maxPopulation])
    pause
end



%% UTILITY FUNCTIONS


    function filterInfectedKoalas = isInfected()
        filterInfectedKoalas = infectionEnds > currentMonth;
    end

    function newIds = initialiseNewKoalas(numberOfNewKoalas,dobOffset)
        % dobOffset can be used to provide an offset so that joeys can be initialised
        % in one iteration of the time step but have a dob in a later time step
        % (to reflect the time of pregnancy).
        newIds = ((lastNewKoalaID + 1):(lastNewKoalaID + numberOfNewKoalas))';
        lastNewKoalaID = lastNewKoalaID + numberOfNewKoalas;
        % Add properties for all new koalas
        id = [id; newIds];
        dob = [dob; (dobOffset + currentMonth*ones(numberOfNewKoalas,1))];
        gendersOfNewKoalas = getGenders(numberOfNewKoalas);
        gender = [gender; gendersOfNewKoalas];
        naturalLifespansOfNewKoalas = getNaturalLifespan(params.cumulativeFemaleProbOfDyingBeforeThisMonth, params.cumulativeFemaleProbOfDyingBeforeThisMonth, gendersOfNewKoalas);
        dod = [dod; currentMonth*ones(numberOfNewKoalas,1) + naturalLifespansOfNewKoalas];
        naturalDod = [naturalDod; currentMonth*ones(numberOfNewKoalas,1) + naturalLifespansOfNewKoalas];
        infectionNumber = [infectionNumber; zeros(numberOfNewKoalas,1)];
        infectionEnds = [infectionEnds; zeros(numberOfNewKoalas,1)];
        resistanceEnds = [resistanceEnds; zeros(numberOfNewKoalas,1)];
        ageAtFirstParturation = [ageAtFirstParturation; NaN(numberOfNewKoalas,1)];
        joeysHad = [joeysHad; zeros(numberOfNewKoalas,1)];
        vaccinationTime = [vaccinationTime; nan(numberOfNewKoalas,1)];
        joey = [joey;  nan(numberOfNewKoalas,1)];
        leavesHospital = [leavesHospital; zeros(numberOfNewKoalas,1)];
        diseaseStageCEmerges = [diseaseStageCEmerges; nan(numberOfNewKoalas,1)];
        diseaseStageBEmerges = [diseaseStageBEmerges; nan(numberOfNewKoalas,1)];
        diseaseStageAEmerges = [diseaseStageAEmerges; nan(numberOfNewKoalas,1)];
        breedsNextForNewKoalas = nan(numberOfNewKoalas,1);
        breedsNextForNewKoalas(gendersOfNewKoalas == female) = currentMonth + dobOffset + 12*params.femaleYoungBreedingAge;
        breedsNext = [breedsNext; breedsNextForNewKoalas];
        infectionStarted = [infectionStarted; nan(numberOfNewKoalas,1)];
        weightTrackParamA = [weightTrackParamA;  getWeightTracksForNewJoeys(numberOfNewKoalas)];
    end

    function g = getGenders(n)
        g = rand(n,1) < params.b;
    end

    function g = getInfectiousness()
        g = zeros(size(dob));
        g( isInfected() ) = 1 / params.peakInfectiousnessMultiplier; % Normal infectiousness
        g( isInfected() ...
            & (currentMonth - infectionStarted <= params.peakInfectiousnessDuration ...
            | (isDiseased() & rand(length(dob),1) < params.probabilityOfHighSheddingIfDiseased)) ) = 1;
    end

    function setUpNewInfections(filterNewlyInfectedKoalas)
        if sum(filterNewlyInfectedKoalas) > 0
            % Infection can kill, be cleared, or never be cleared.
            % Fatally infected koalas die within the current year;
            % koalas who clear the infection are infected for a time and then
            % have resistance for a time after that; koalas who control their
            % infection do not recover, but therefore do not get repeat
            % infections.
            newInfectionsThisIteration = newInfectionsThisIteration + sum(filterNewlyInfectedKoalas);
            
            infectionNumber(filterNewlyInfectedKoalas) = infectionNumber(filterNewlyInfectedKoalas) + 1;
            
            determineNewDisease(filterNewlyInfectedKoalas);
            % For koalas who will clear infection, set the time the infection
            % ends and the time the resistance ends.
            fateVector2 = rand(length(dob),1);
            filterKoalasWhoWillClearInfection = filterNewlyInfectedKoalas & fateVector2 < params.pr;
            infectionEnds(filterKoalasWhoWillClearInfection) = currentMonth + getMonthsBeforeClearance(sum(filterKoalasWhoWillClearInfection));
            resistanceEnds(filterKoalasWhoWillClearInfection) = currentMonth + ...
                getMonthsBeforeClearance(sum(filterKoalasWhoWillClearInfection)) + getResistanceDuration(sum(filterKoalasWhoWillClearInfection));
            % For koalas who will control but not clear infection, set
            % infection to resolve the year after they die.
            filterKoalasWhoWillNeverClearInfection = filterNewlyInfectedKoalas & ~filterKoalasWhoWillClearInfection;
            infectionEnds(filterKoalasWhoWillNeverClearInfection) = dod(filterKoalasWhoWillNeverClearInfection) + 1;
        end
    end

    function determineNewDisease(filterKoalas)
        if sum(filterKoalas) > 0
            reductionDueToVaccine = 0;
            if vaccineProtocol.preventsWhat == 1 || vaccineProtocol.preventsWhat == 2 || vaccineProtocol.preventsWhat == 3
                reductionDueToVaccine = calculateReductionDueToVaccine();
            end
            filterKoalasWhoWillDevelopDiseaseStageB = filterKoalas & rand(length(dob),1) < ( R(params.probabilityOfDiseaseStageBDeveloping,infectionNumber) .* (1 - reductionDueToVaccine) );
            filterKoalasWhoWillDevelopDiseaseStageA = filterKoalas & rand(length(dob),1) < ( R(params.probabilityOfDiseaseStageADeveloping,infectionNumber) .* (1 - reductionDueToVaccine) );
            filterKoalasWhoWillDie = filterKoalas & rand(length(dob),1) < ( R(params.probabilityOfInfectionKilling,infectionNumber) .* (1 - reductionDueToVaccine) );
            dod(filterKoalasWhoWillDie) = min(  dod(filterKoalasWhoWillDie),  currentMonth + getMonthsUntilInfectionKills(sum(filterKoalasWhoWillDie))  );
            infectionEnds(filterKoalasWhoWillDie) = dod(filterKoalasWhoWillDie) + 1;
            diseaseStageCEmerges(filterKoalasWhoWillDie) = min( diseaseStageCEmerges(filterKoalasWhoWillDie), currentMonth + params.monthsUntilDiseaseEmerges );
            % Handle koalas who will develop disease stage B (which is
            % sterility in females).
            diseaseStageBEmerges(filterKoalasWhoWillDevelopDiseaseStageB) = min( diseaseStageBEmerges(filterKoalasWhoWillDevelopDiseaseStageB), currentMonth + params.monthsUntilDiseaseEmerges);
            % Handle koalas who will develop disease stage A (which is possible
            % temporary infertility in females).
            diseaseStageAEmerges(filterKoalasWhoWillDevelopDiseaseStageA) = min( diseaseStageAEmerges(filterKoalasWhoWillDevelopDiseaseStageA), currentMonth + params.monthsUntilDiseaseEmerges);
        end
    end

    function g = getMonthsBeforeClearance(numKoalas)
        g = randi([params.monthsBeforeClearanceLowerBound params.monthsBeforeClearanceUpperBound],numKoalas,1);
    end

    function g = getResistanceDuration(numKoalas)
        g = randi([params.resistanceDurationMonthsLowerBound params.resistanceDurationMonthsUpperBound],numKoalas,1);
    end

    function g = getMonthsUntilInfectionKills(numKoalas)
        g = randi([params.monthsUntilInfectionKillsLowerBound params.monthsUntilInfectionKillsUpperBound],numKoalas,1);
    end

    function cureKoalas(filterKoalasToCure)
        if sum(filterKoalasToCure) > 0
            infectionEnds(filterKoalasToCure) = currentMonth;
            resistanceEnds(filterKoalasToCure) = currentMonth + params.resistanceDuration;
            dod(filterKoalasToCure) = naturalDod(filterKoalasToCure);
        end
    end

    function cureDiseaseCKoalas(filterKoalasToCure)
        % This function is only used for culling scenarios. In the
        % vaccination paper, koalas with disease C are always euthanized
        % and so never treated.
        if sum(filterKoalasToCure) > 0
            infectionEnds(filterKoalasToCure) = currentMonth;
            resistanceEnds(filterKoalasToCure) = currentMonth + params.resistanceDuration;
        end
    end


    function P = calculateReductionDueToVaccine()
        P = vaccineProtocol.initialEfficacy * exp(log(1/2)/(12*vaccineProtocol.halfLife) * (currentMonth - vaccinationTime));
        P(isnan(P)) = 0;
    end

    function r = calculateReductionDueToResistance()
        r = zeros(length(dob),1);
        r(resistanceEnds > currentMonth) = params.rr;
    end

    function a = ageInYears()
        a = ((currentMonth - dob) / 12);
    end

    function goToHospital(filterKoalaPatients)
        if sum(filterKoalaPatients) > 0
            filterJoeysOfThesePatients = joeysOfTheseMothers(filterKoalaPatients);
            leavesHospital(filterKoalaPatients & filterJoeysOfThesePatients) = currentMonth + params.timeInHospital;
            cureKoalas(filterKoalaPatients & filterJoeysOfThesePatients);
        end
    end

    function r = R(p,infectionNumberForTheseKoalas)
        % Certain events become more likely the more re-infections a koala
        % has had. This function uses odds ratios a2 and a3 to calculate
        % the increase in probability from p for the current infection.
        rr = [0 p p*params.a2/(1-p+p*params.a2) p*params.a3/(1-p+p*params.a3)]';
        r = rr(min(length(rr),infectionNumberForTheseKoalas+1));
    end

    function snapshot =  takeSnapshot()
        snapshot.id = id;
        snapshot.dob = dob;
        snapshot.naturalDod = naturalDod;
        snapshot.gender = gender;
        snapshot.dod = dod;
        snapshot.infectionNumber = infectionNumber;
        snapshot.infectionEnds = infectionEnds;
        snapshot.resistanceEnds = resistanceEnds;
        snapshot.ageAtFirstParturation = ageAtFirstParturation;
        snapshot.joeysHad = joeysHad;
        snapshot.vaccinationTime = vaccinationTime;
        snapshot.joey = joey;
        snapshot.leavesHospital = leavesHospital;
        snapshot.breedsNext = breedsNext ;
        
        snapshot.diseaseStageCEmerges = diseaseStageCEmerges;
        snapshot.diseaseStageBEmerges = diseaseStageBEmerges;
        snapshot.diseaseStageAEmerges = diseaseStageAEmerges;
        snapshot.infectionStarted = infectionStarted;
        snapshot.weightTrackParamA = weightTrackParamA;
        
        snapshot.currentMonth = currentMonth-1; % currentMonth-1 because takeSnapshot takes a snapshot of the population as it stood at the end of the previous iteration,
        % and so the records that correspond to the snapshot are those for
        % currentMonth-1.
        snapshot.randStreamState = rng;
        snapshot.paramSetNum = paramsIndex;
        
        
    end

    function g = getCalendarMonth(monthNumber)
        % monthNumber = 1 -> g = 1
        % ...
        % monthNumber = 12 -> g = 12
        % monthNumber = 13 -> g = 1
        % and so on.
        g = mod(monthNumber - 1 + calendarOffsetFromStartingPop, 12) + 1;
    end

    function importPopulation()
        calendarOffsetFromStartingPop = startingPopulation.currentMonth;
        id = startingPopulation.id;
        lastNewKoalaID = max(id);
        dob = startingPopulation.dob;
        naturalDod = startingPopulation.naturalDod;
        gender = startingPopulation.gender;
        joey = startingPopulation.joey;
        vaccinationTime = startingPopulation.vaccinationTime;
        ageAtFirstParturation = startingPopulation.ageAtFirstParturation;
        joeysHad = startingPopulation.joeysHad;
        if noInfection == true
            dod = startingPopulation.naturalDod;
            infectionNumber = zeros(lastNewKoalaID,1);
            infectionEnds = zeros(lastNewKoalaID,1);
            resistanceEnds = zeros(lastNewKoalaID,1);
        else
            dod = startingPopulation.dod;
            infectionNumber = startingPopulation.infectionNumber;
            infectionEnds = startingPopulation.infectionEnds;
            resistanceEnds = startingPopulation.resistanceEnds;
        end
        leavesHospital = zeros(length(id),1);
        breedsNext = startingPopulation.breedsNext;
        diseaseStageCEmerges = startingPopulation.diseaseStageCEmerges;
        diseaseStageBEmerges = startingPopulation.diseaseStageBEmerges;
        diseaseStageAEmerges = startingPopulation.diseaseStageAEmerges;
        infectionStarted = startingPopulation.infectionStarted;
        weightTrackParamA = startingPopulation.weightTrackParamA;
        
        if isfield(startingPopulation, 'randStreamState')
            rng(startingPopulation.randStreamState);
        end
    end

    function filterVector = indexToFilter(indexVector)
        filterVector = false(length(dob),1);
        filterVector(indexVector) = true;
    end

    function filter = isDiseased()
        filter = (diseaseStageBEmerges <= currentMonth) ...
            | (diseaseStageAEmerges <= currentMonth & isInfected()) ...
            | (diseaseStageCEmerges <= currentMonth);
    end

    function infertile = isInfertileOrSterile()
        infertile = (diseaseStageBEmerges <= currentMonth) ... % Sterility
            | (diseaseStageAEmerges <= currentMonth & isInfected()); % Temporary infertility
    end

    function filter = needsToGoToHospital()
        filter = (diseaseStageAEmerges <= currentMonth & isInfected()) | (diseaseStageBEmerges <= currentMonth) ...
            | (diseaseStageCEmerges <= currentMonth);
    end

    function filter = needsToBeEuthanized()
        filter = (diseaseStageCEmerges <= currentMonth);
    end

    function euthanize(filterKoalasToEuthanize)
        filterMarkedForDeath = filterMarkedForDeath | filterKoalasToEuthanize;
    end

    function J = joeysOfTheseMothers(filterMothers)
        J = ismember(id,joey(filterMothers));
    end

    function filterMothers = mothersOfTheseJoeys(filterJoeys)
        filterMothers = ismember(joey,id(filterJoeys));
    end

    function joeysBecomeIndependent(filterJoeysWhoBecomeIndependent)
        
        filterTheirMothers = mothersOfTheseJoeys(filterJoeysWhoBecomeIndependent);
        joey(filterTheirMothers) = NaN;
        
        breedsNext(filterTheirMothers) = currentMonth + 1;
        
    end

    function killKoalas(filterKoalasToKill)
        % This function should only be called once per iteration.
        if killKoalasFnCalledFlag == true
            error('Function killKoalas has been called more than once this iteration.')
        else
            killKoalasFnCalledFlag = true;
            if sum(filterKoalasToKill) > 0
                % If a joey dies, her mother is able to breed again the following
                filterMothersOfDyingJoeys = mothersOfTheseJoeys(filterKoalasToKill);
                
                breedsNext(filterMothersOfDyingJoeys) = currentMonth + 1;
                
                
                % If a mother dies, her joey should die too.
                filterJoeysOfDyingMothers = joeysOfTheseMothers(filterKoalasToKill);
                deathsMotherDiedRecord(currentMonth) = sum(filterJoeysOfDyingMothers & ~filterKoalasToKill);
                filterKoalasToKillIncJoeys = filterKoalasToKill | filterJoeysOfDyingMothers;
                
                joey(filterMothersOfDyingJoeys) = NaN;
                
                id(filterKoalasToKillIncJoeys) = [];
                dob(filterKoalasToKillIncJoeys) = [];
                naturalDod(filterKoalasToKillIncJoeys) = [];
                gender(filterKoalasToKillIncJoeys) = [];
                dod(filterKoalasToKillIncJoeys) = [];
                infectionNumber(filterKoalasToKillIncJoeys) = [];
                infectionEnds(filterKoalasToKillIncJoeys) = [];
                resistanceEnds(filterKoalasToKillIncJoeys) = [];
                ageAtFirstParturation(filterKoalasToKillIncJoeys) = [];
                joeysHad(filterKoalasToKillIncJoeys) = [];
                vaccinationTime(filterKoalasToKillIncJoeys) = [];
                leavesHospital(filterKoalasToKillIncJoeys) = [];
                diseaseStageCEmerges(filterKoalasToKillIncJoeys) = [];
                diseaseStageBEmerges(filterKoalasToKillIncJoeys) = [];
                diseaseStageAEmerges(filterKoalasToKillIncJoeys) = [];
                breedsNext(filterKoalasToKillIncJoeys) = [];
                
                infectionStarted(filterKoalasToKillIncJoeys) = [];
                joey(filterKoalasToKillIncJoeys) = [];
                weightTrackParamA(filterKoalasToKillIncJoeys) = [];
                
                deathsRecord(currentMonth) = sum(filterKoalasToKillIncJoeys);
            end
        end
    end

    function removeEmigrants(filterEmigrants)
        % This function should only be called once per iteration.
        if removeEmigrantsFnCalledFlag == true
            error('Function removeEmigrants has been called more than once this iteration.')
        else
            removeEmigrantsFnCalledFlag = true;
            if sum(filterEmigrants) > 0
                filterMothersOfEmigratingJoeys = mothersOfTheseJoeys(filterEmigrants);
                filterJoeysOfEmigratingMothers = joeysOfTheseMothers(filterEmigrants);
                if sum(filterMothersOfEmigratingJoeys) > 0 || sum(filterJoeysOfEmigratingMothers) > 0
                    error('At least one mother and/or joey was selected for emigration')
                end
                
                joey(filterEmigrants) = NaN;
                
                id(filterEmigrants) = [];
                dob(filterEmigrants) = [];
                naturalDod(filterEmigrants) = [];
                gender(filterEmigrants) = [];
                dod(filterEmigrants) = [];
                infectionNumber(filterEmigrants) = [];
                infectionEnds(filterEmigrants) = [];
                resistanceEnds(filterEmigrants) = [];
                ageAtFirstParturation(filterEmigrants) = [];
                joeysHad(filterEmigrants) = [];
                vaccinationTime(filterEmigrants) = [];
                leavesHospital(filterEmigrants) = [];
                diseaseStageCEmerges(filterEmigrants) = [];
                diseaseStageBEmerges(filterEmigrants) = [];
                diseaseStageAEmerges(filterEmigrants) = [];
                breedsNext(filterEmigrants) = [];
                
                infectionStarted(filterEmigrants) = [];
                joey(filterEmigrants) = [];
                weightTrackParamA(filterEmigrants) = [];
                
            end
        end
    end


    function boostFromMating(filterKoalasToBoost)
        if sum(filterKoalasToBoost) > 0
            boost(filterKoalasToBoost);
        end
    end

    function vaccinate(filterKoalasToVaccinate)
        if sum(filterKoalasToVaccinate) > 0
            % Infected koalas are cured before vaccination (although they retain their resistance).
            if vaccineProtocol.usingAntibiotics
                cureKoalas(filterKoalasToVaccinate);
            else
                if vaccineProtocol.cureEfficacy && (vaccineProtocol.preventsWhat == 0 || vaccineProtocol.preventsWhat == 1 || vaccineProtocol.preventsWhat == 3)
                    cureKoalas(filterKoalasToVaccinate & rand(size(dob)) < vaccineProtocol.initialEfficacy);
                end
            end
            filterKoalasBeingVaccinatedForFirstTime = filterKoalasToVaccinate & isnan(vaccinationTime);
            vaccinationTime(filterKoalasBeingVaccinatedForFirstTime) = currentMonth;
            filterKoalasBeingBoosted = filterKoalasToVaccinate & ~filterKoalasBeingVaccinatedForFirstTime;
            boost(filterKoalasBeingBoosted)
        end
    end

    function g = getBaseMaleOrFemaleTransmissionProbability()
        g = params.tf * ones(length(dob),1);
        g(gender == male) = params.tm;
    end

    function bodyScore = getBodyScore()
        bodyScore = bodyScoreParams.intercept ...
            + ageInYears() * bodyScoreParams.ageCoefficient ...
            + (isInfected() | isDiseased()) * bodyScoreParams.isInfectedOrDiseasedCoefficient ...
            + (gender == male) * bodyScoreParams.isMaleCoefficient;
    end

    function trueOrFalse = isBreedingSeason(month)
        calendarMonth = getCalendarMonth(month);
        trueOrFalse = ...
            (params.highJoeyBirthSeasonStart <= params.highJoeyBirthSeasonFinish && (calendarMonth >= params.highJoeyBirthSeasonStart && calendarMonth <= params.highJoeyBirthSeasonFinish)) ...
            || (params.highJoeyBirthSeasonStart > params.highJoeyBirthSeasonFinish && not(calendarMonth > params.highJoeyBirthSeasonFinish && calendarMonth < params.highJoeyBirthSeasonStart));
    end

    function newWeights = getWeightTracksForNewJoeys(numJoeys)
        newWeights = datasample(reproductiveSuccessStruct.weightTrackParamADistn, numJoeys);
    end

    function weights = getWeights()
        weights = weightTrackParamA .* (1 ./ (1 + exp(reproductiveSuccessStruct.weightTrackParamB*(ageInYears()))) - 0.5 + 0.001);
        % s = P(1) * (1 ./ (1 + exp(P(2)*(x))) - 0.5 + 0.001);
    end

    function relativeMatingProb = getRelativeMatingProb()
        relativeMatingProb = interp1q(weightToReprodSuccessWeight', weightToReprodSuccessReprodSuccess', (getWeights()));
    end

    function filterIsInHospital = isInHospital()
        filterIsInHospital = leavesHospital > currentMonth;
    end

    function boost(filterKoalasBeingBoosted)
        % When a koala's vaccine is boosted by being re-vaccinated,
        % an effective proportional increase in efficacy is applied
        % by moving the time of original vaccination forward
        % into the future - this is okay as the vaccine
        % effectiveness is calculated based on the interval between
        % the current year and the vaccination time.
        if sum(filterKoalasBeingBoosted) > 0 && vaccineProtocol.boostType ~= 0 > 0
                      
            currentEfficacy = calculateReductionDueToVaccine();
            if vaccineProtocol.boostType == 1 % Up to initial efficacy
                newCurrentEfficacy = currentEfficacy + (vaccineProtocol.initialEfficacy - currentEfficacy) * vaccineProtocol.boostAmount;
            else
                if vaccineProtocol.boostType == 2 % Up to 100%
                    newCurrentEfficacy = currentEfficacy + (1 - currentEfficacy) * vaccineProtocol.boostAmount;
                else
                    if vaccineProtocol.boostType == 3 % Multiple of current amount, up to initial efficacy
                        newCurrentEfficacy = min(vaccineProtocol.initialEfficacy, currentEfficacy * vaccineProtocol.boostAmount);
                    else
                        if vaccineProtocol.boostType == 4 % Multiple of current amount, up to 100%
                            newCurrentEfficacy = min(1, currentEfficacy * vaccineProtocol.boostAmount);
                        end
                    end
                end
            end
            vaccinationTime(filterKoalasBeingBoosted) = currentMonth - vaccineProtocol.halfLife*12 * log( newCurrentEfficacy(filterKoalasBeingBoosted) / vaccineProtocol.initialEfficacy ) / log(1/2);
            
        end
    end

    function addImmigrants(numImmigrants)
        if numImmigrants > 0
            filterImmigrants = false(size(filterEligibleForImmigration));
            filterImmigrants(randsample(find(filterEligibleForImmigration), numEmigrants, true)) = true;
            numberOfNewKoalas = sum(filterImmigrants);
            immigrantsEnteredRecord(currentMonth) = numberOfNewKoalas;
           
            % Add properties for all new koalas
            newIds = ((lastNewKoalaID + 1):(lastNewKoalaID + numberOfNewKoalas))';
            lastNewKoalaID = lastNewKoalaID + numberOfNewKoalas;
            id = [id; newIds];
            dob = [dob; currentMonth + startingPopulation.dob(filterImmigrants)];
            gender = [gender; startingPopulation.gender(filterImmigrants)];
            dod = [dod; currentMonth+startingPopulation.dod(filterImmigrants)];
            naturalDod = [naturalDod; currentMonth+startingPopulation.naturalDod(filterImmigrants)];
            infectionNumber = [infectionNumber; startingPopulation.infectionNumber(filterImmigrants)];
            infectionEnds = [infectionEnds; currentMonth+startingPopulation.infectionEnds(filterImmigrants)];
            resistanceEnds = [resistanceEnds; currentMonth+startingPopulation.resistanceEnds(filterImmigrants)];
            ageAtFirstParturation = [ageAtFirstParturation; startingPopulation.ageAtFirstParturation(filterImmigrants)];
            joeysHad = [joeysHad; startingPopulation.joeysHad(filterImmigrants)];
            vaccinationTime = [vaccinationTime; nan(numberOfNewKoalas,1)];
            joey = [joey;  nan(numberOfNewKoalas,1)];
            leavesHospital = [leavesHospital; zeros(numberOfNewKoalas,1)];
            diseaseStageCEmerges = [diseaseStageCEmerges; currentMonth+startingPopulation.diseaseStageCEmerges(filterImmigrants)];
            diseaseStageBEmerges = [diseaseStageBEmerges; currentMonth+startingPopulation.diseaseStageBEmerges(filterImmigrants)];
            diseaseStageAEmerges = [diseaseStageAEmerges; currentMonth+startingPopulation.diseaseStageAEmerges(filterImmigrants)];
            breedsNext = [breedsNext; currentMonth*ones(numberOfNewKoalas,1)];
            infectionStarted = [infectionStarted; currentMonth+startingPopulation.infectionStarted(filterImmigrants)];
            weightTrackParamA = [weightTrackParamA;  startingPopulation.weightTrackParamA(filterImmigratns)];
        end
    end

    function filterIsEligibleForMigration = isEligibleForMigration()
       filterIsEligibleForMigration = isnan(joey) & ~joeysOfTheseMothers(true(size(dob)));
    end
end

