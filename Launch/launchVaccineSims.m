% launchVaccineSims
dbstop if error

baseParams = getBaseParamsAndSetPath();
[thisMachineNum, fromParamSetNum, toParamSetNum, numberOfParameterSetsPerScenario] = getMachineNumber(baseParams);

recordVarType = 'uint32';
maxValuePermittedByRecordVarType = 2^32 - 1;

lengthOfResults = 11;

bodyScoreParams = loadBodyScoreParams(baseParams);

calibrationParamsVaccineSims = baseParams.calibrationParamsVaccineSims;

if calibrationParamsVaccineSims.maxPermittedPopulation > maxValuePermittedByRecordVarType
    error('Max permitted population is larger than max allowed value of record variable type.')
end

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
disp(['Will use good params indices ' num2str(fromParamSetNum) ' to ' num2str(toParamSetNum) ' (total param sets: ' num2str(numberOfParameterSetsPerScenario) ') on this machine.'])
goodParamsIndexes = allGoodParamsIndexes(fromParamSetNum:toParamSetNum);
disp(['  (Good params index ' num2str(fromParamSetNum) ' is param set no. ' num2str(goodParamsIndexes(1)) ', and good params index ' num2str(toParamSetNum) ...
    ' is param set no. ' num2str(goodParamsIndexes(end)) '.)']);
    
disp('Loading starting populations...')
load([getResultsDir() baseParams.startingPopulationsForVaccineFile '.mat']);
startingPopulationsForVaccineUnadjustedMonths = chosenStartingPopulationsForVaccine(fromParamSetNum:toParamSetNum);
startingPopulationsForVaccine = adjustDatesOfPopulationSnapshots(startingPopulationsForVaccineUnadjustedMonths);
disp('Loaded starting populations.')

disp(['Loading scenario parameters...'])
scenarioParams = baseParams.setupVaccineParamsFn();
disp('Scenario parameters loaded.')

if ~matlabpool('size');
    disp('Starting parallel Matlab...');
    matlabpool(min(numberOfParameterSetsPerScenario, 8));
end

firstVaccineYear = 1;
launchTicID = tic
disp('Running Cartesian product simulations with vaccines...')
[recordsVaccine, scenarioParamsMatrix, scenarioLabels, errorList, filterParamsThatWereCompleted] = ...
    runVaccineSims(goodParamsIndexes,scenarioParams,paramsStruct.paramsMatrix,paramsStruct.paramsFieldNames,paramsStruct.paramsWithoutRanges, ...
    firstVaccineYear,startingPopulationsForVaccine,lengthOfResults,calibrationParamsVaccineSims,bodyScoreParams,[],false,recordVarType, reproductiveSuccessStruct);
disp('All Cartesian product simulations finished.')
if ~all(filterParamsThatWereCompleted)
    disp('SOME PARAM SIMS FAILED because of out-of-memory parfor errors.')
    disp(['The FAILED parameters were:'])
    disp(num2str(goodParamsIndexes(~filterParamsThatWereCompleted)))
end
disp(['Vaccine simulations took ' num2str(toc(launchTicID)) ' seconds.'])

scenarioDetails.scenarioLabels = scenarioLabels;
scenarioDetails.scenarioParams = scenarioParams;
scenarioDetails.scenarioParamsMatrix = scenarioParamsMatrix;


% [LHSScenarioParams,LHSScenarioParamsIndexStruct,groups] = setupDummyLHSScenarioParams(scenarioParams,yearsToSimulateVaccine,numberOfLHSSamples,numberOfKoalas);
%
% disp('Running Latin hypercube simulations with vaccines...')
%
% launchTicID = tic
%
%
% [resultsMatrixLHS,recordMatrixLHSPop,recordMatrixLHSInf] = runLHSVaccineSims(goodParamsIndexes,LHSScenarioParams,LHSScenarioParamsIndexStruct,groups,paramsStructArray, ...
%     yearsToSimulateVaccine,firstVaccineYear,startingPopulationsWithInfection,lengthOfResults);
% disp('All Latin hypercube simulations finished.')
% disp(['Vaccine simulations took ' num2str(toc(launchTicID)) ' seconds.'])
% disp('')

% Save results
popRecordMatrix = recordsVaccine.popRecordMatrix;
infRecordMatrix = recordsVaccine.infRecordMatrix;
incidenceRecordMatrix = recordsVaccine.incidenceRecordMatrix;
diseasedRecordMatrix = recordsVaccine.diseasedRecordMatrix;
vaccinatedRecordMatrix = recordsVaccine.vaccinatedRecordMatrix;
mothersWithYoungRecordMatrix = recordsVaccine.mothersWithYoungRecordMatrix;
potentialMothersRecordMatrix = recordsVaccine.potentialMothersRecordMatrix;
deathsRecordMatrix = recordsVaccine.deathsRecordMatrix;
vaccinationRecordMatrix = recordsVaccine.vaccinationRecordMatrix;
deathsByDiseaseRecordMatrix = recordsVaccine.deathsByDiseaseRecordMatrix;
deathsByEuthanasiaRecordMatrix = recordsVaccine.deathsByEuthanasiaRecordMatrix;
deathsByOtherRecordMatrix = recordsVaccine.deathsByOtherRecordMatrix;
deathsMotherDiedRecordMatrix = recordsVaccine.deathsMotherDiedRecordMatrix;

results = recordsVaccine.results;
disp('Saving records and results...')
tic
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_popRecordMatrix.mat'],'popRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_infRecordMatrix.mat'],'infRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_incidenceRecordMatrix.mat'],'incidenceRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_diseasedRecordMatrix.mat'],'diseasedRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_vaccinatedRecordMatrix.mat'],'vaccinatedRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_mothersWithYoungRecordMatrix.mat'],'mothersWithYoungRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_potentialMothersRecordMatrix.mat'],'potentialMothersRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_deathsRecordMatrix.mat'],'deathsRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_vaccinationRecordMatrix.mat'],'vaccinationRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_deathsByDiseaseRecordMatrix.mat'],'deathsByDiseaseRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_deathsByEuthanasiaRecordMatrix.mat'],'deathsByEuthanasiaRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_deathsByOtherRecordMatrix.mat'],'deathsByOtherRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_deathsMotherDiedRecordMatrix.mat'],'deathsMotherDiedRecordMatrix')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_results.mat'],'results')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_scenarioDetails.mat'],'scenarioDetails')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_errorList.mat'],'errorList')
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_snapshotRecord.mat'],'-struct','recordsVaccine','snapshotRecord','-v7.3')
toc

snapshotRecordAgeInMonths = cell(size(recordsVaccine.snapshotRecord));
snapshotRecordEncodedStatus = cell(size(recordsVaccine.snapshotRecord));
for indRow = 1:size(recordsVaccine.snapshotRecord,1)
    for indCol = 1:size(recordsVaccine.snapshotRecord,2)
        snapshotRecordAgeInMonths{indRow,indCol} = recordsVaccine.snapshotRecord{indRow,indCol}.ageInMonths;
        snapshotRecordEncodedStatus{indRow,indCol} = recordsVaccine.snapshotRecord{indRow,indCol}.encodedStatus;
    end
end
tic
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_snapshotRecordAgeInMonths.mat'],'snapshotRecordAgeInMonths','-v7.3')
toc
tic
save([baseParams.resultsDir baseParams.vaccineResultsFileName '_' num2str(thisMachineNum) '_snapshotRecordEncodedStatus.mat'],'snapshotRecordEncodedStatus','-v7.3')
toc
disp('Finished saving records and results.')

matlabpool close
