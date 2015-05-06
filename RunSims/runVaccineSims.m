function [vaccineRecords, scenarioParamsMatrix, scenarioLabels, errorList, filterParamsThatWereCompleted] = ...
    runVaccineSims(goodParamsIndexes,scenarioParams,paramsMatrix, paramsFieldNames, paramsWithoutRanges, ...
    firstVaccineYear,startingPopulations,lengthOfResults,calibrationParams,bodyScoreParams,totalKoalas,isRetainResults, recordVarType, reproductiveSuccessStruct)

% [vaccineRecords, scenarioParamsMatrix, scenarioLabels, errorList, filterParamsThatWereCompleted] = ...
%    runVaccineSims(goodParamsIndexes,scenarioParams,paramsMatrix, paramsFieldNames, paramsWithoutRanges, ...
%    firstVaccineYear,startingPopulations,lengthOfResults,calibrationParams,bodyScoreParams,totalKoalas,isRetainResults, recordVarType, reproductiveSuccessStruct)
% Simulations 'vaccination' (including culling, treatment etc.) interventions and collects the results.
%
% goodParamsIndexes: IDs of parameter sets that passed calibration.
% scenarioParams: Parameters of the intervention.
% paramsMatrix: Parameter sets.
% paramsFieldNames: Parameter names.
% paramsWithoutRanges: Names and values of parameters without ranges.
% firstVaccineYear: Year in which the intervention starts.
% startingPopulations: Population snapshots to use in simulations.
% lengthOfResults: Length of results data.
% calibrationParams: Metaparameters used for calibration.
% initialPrevalence: Infection prevalence at start of simulations.
% bodyScoreParams: Parameters used to caculate body score.
% totalKoalas: Number of koalas at start of simulations.
% isRetainResults: Flag for whether to retain or discard results.
% recordVarType: Data type used to store records.
% reproductiveSuccessStruct: Struct governing mating weights.
%
% vaccineRecords: Simulation summary statistics.
% scenarioParamsMatrix: Intervention parameters, in matrix form.
% scenarioLabels: Names of the intervention parameters.
% errorList: Cell array of errors that occured during simulations, causing
% them to end early.
% filterParamsThatWereCompleted: Mask of parameter set IDs to indicate
% those for which the simulations completed without error.

male = 0;
female = 1;

numberOfGoodParams = length(goodParamsIndexes);

% Create new variables to hold the elements of the struct scenarioParams.
% This is necessary so that these variables can be sliced in the parfor
% loop.
effAndHalfLifeScalingParam = scenarioParams.effAndHalfLifeScalingParam;
boostType = scenarioParams.boostType;
boostAmount = scenarioParams.boostAmount;
boostFromMating = scenarioParams.boostFromMating;
groups = scenarioParams.groups;
usingAntibiotics = scenarioParams.usingAntibiotics;
cureEfficacy = scenarioParams.cureEfficacy;
numberOfCapturesByMonth = scenarioParams.numberOfCapturesByMonth;
targetUnvaccinatedKoalas = scenarioParams.targetUnvaccinatedKoalas;
preventsWhat = scenarioParams.preventsWhat;
cull = scenarioParams.cull;
emigrationsByMonth = scenarioParams.emigrationsByMonth;
proportionLocateable = scenarioParams.proportionLocateable;

capturesByMonthAdjustment = scenarioParams.capturesByMonthAdjustment;

numberOfVaccineProtocols = ...
    length(effAndHalfLifeScalingParam) ...
    * length(boostType) ...
    * length(boostAmount) ...
    * length(boostFromMating) ...
    * length(groups) ...
    * length(usingAntibiotics) ...
    * length(cureEfficacy) ...
    * length(numberOfCapturesByMonth) ...
    * length(targetUnvaccinatedKoalas) ...
    * length(preventsWhat) ...
    * length(cull) ...
    * length(emigrationsByMonth) ...
    * length(proportionLocateable);

numberOfScenarioSims = numberOfVaccineProtocols * numberOfGoodParams;

scenarioLabels = {'Scenario number','Half-life','Initial efficacy','Number of captures by month','Boost type','Boost amount','Groups','Using antibiotics','Targeting unvaccinated koalas' ...
    , 'Cure efficacy','Boost from mating','Prevents pathology (not infection)','Culling','Emigrations by month','Proportion locateable'};
numberOfScenarioParams = length(scenarioLabels);
scenarioParamsMatrix = nan(numberOfVaccineProtocols, numberOfScenarioParams);
for indLocateable = 1:length(proportionLocateable)
    for indEmigrations = 1:length(emigrationsByMonth)
        for indEffAndHalfLifeScalingParam = 1:length(effAndHalfLifeScalingParam)
            for indDelivery = 1:length(numberOfCapturesByMonth)
                for indBoostType = 1:length(boostType)
                    for indBoostAmount = 1:length(boostAmount)
                        for indGroups = 1:length(groups)
                            for indAntibiotics = 1:length(usingAntibiotics)
                                for indTargetUnvaccinated = 1:length(targetUnvaccinatedKoalas)
                                    for indCureEff = 1:length(cureEfficacy)
                                        for indBoostFromMating = 1:length(boostFromMating)
                                            for indPreventsWhat = 1:length(preventsWhat)
                                                for indCull = 1:length(cull)
                                                    currentVaccineProtocolNumber = ...
                                                        indCull ...
                                                        + (indPreventsWhat-1)*length(cull) ...
                                                        + (indBoostFromMating-1)*length(preventsWhat)*length(cull) ...
                                                        + (indCureEff-1)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indTargetUnvaccinated-1)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indAntibiotics-1)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indGroups-1)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indBoostAmount-1)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indBoostType-1)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indDelivery-1)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indEffAndHalfLifeScalingParam-1)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indEmigrations-1)*length(effAndHalfLifeScalingParam)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                        + (indLocateable-1)*length(emigrationsByMonth)*length(effAndHalfLifeScalingParam)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull);
                                                    scenarioParamsMatrix(currentVaccineProtocolNumber,:) = [ ...
                                                        currentVaccineProtocolNumber ...
                                                        getHalfLife(effAndHalfLifeScalingParam(indEffAndHalfLifeScalingParam)) ...
                                                        getInitialEfficacy(effAndHalfLifeScalingParam(indEffAndHalfLifeScalingParam)) ...
                                                        capturesByMonthAdjustment + indDelivery ... % capturesByMonthAdjustment adjusts in case lower intensity schedules are skipped.
                                                        boostType(indBoostType) ...
                                                        boostAmount(indBoostAmount) ...
                                                        indGroups ...
                                                        usingAntibiotics(indAntibiotics) ...
                                                        targetUnvaccinatedKoalas(indTargetUnvaccinated) ...
                                                        cureEfficacy(indCureEff) ...
                                                        boostFromMating(indBoostFromMating) ...
                                                        preventsWhat(indPreventsWhat) ...
                                                        cull(indCull) ...
                                                        indEmigrations ...
                                                        proportionLocateable(indLocateable) ...
                                                        ];
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end



lengthOfExtraInfoInResults = 2; % Scenario number (0 here as this is the 'no vaccine' case), parameter set number.

errorList = cell(numberOfVaccineProtocols+1, numberOfGoodParams);
resultsArray = cell(numberOfVaccineProtocols+1, numberOfGoodParams);
snapshotRecordArray = cell(numberOfVaccineProtocols+1, numberOfGoodParams);
popRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
infRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
incidenceRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
diseasedRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
vaccinatedRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
mothersWithYoungRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
potentialMothersRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
deathsRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
vaccinationRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
deathsByDiseaseRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
deathsByEuthanasiaRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
deathsByOtherRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
deathsMotherDiedRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
emigrantsExitedRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
immigrantsEnteredRecordMatrix = zeros(  numberOfVaccineProtocols+1, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);

if isRetainResults
    femaleJoeyPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenilePopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenilePopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldPopulationRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    femaleJoeyInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenileInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenileInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldInfectedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    femaleJoeyDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenileDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenileDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldDiseasedRecordMatrix = zeros(  numberOfVaccineProtocols, numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
end

numberOfThisScenario = 0;

paramsPerParfor = 8;
numOuterIterations = ceil(numberOfGoodParams / paramsPerParfor);
filterParamsThatWereCompleted = true(numberOfGoodParams,1);
for indOuter = 1:numOuterIterations
    first = (indOuter-1) * paramsPerParfor + 1;
    last = min(numberOfGoodParams, indOuter * paramsPerParfor);
    % parfor goes here
    try
    parfor indParams = first:last
        
        tempErrorList = cell(numberOfVaccineProtocols+1,1);
        tempResultsArray = cell(numberOfVaccineProtocols+1,1);
        tempSnapshotRecordArray = cell(numberOfVaccineProtocols+1,1);
        tempPopRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempInfRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempIncidenceRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempVaccinatedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempMothersWithYoungRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempPotentialMothersRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDeathsRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempVaccinationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDeathsByDiseaseRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDeathsByEuthanasiaRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDeathsByOtherRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempDeathsMotherDiedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempEmigrantsExitedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        tempImmigrantsEnteredRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        
        if isRetainResults
            tempFemaleJoeyPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleJuvenilePopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleYoungBreederPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleMatureBreederPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleOldPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            
            tempMaleJoeyPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleJuvenilePopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleYoungBreederPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleMatureBreederPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleOldPopulationRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            
            tempFemaleJoeyInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleJuvenileInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleYoungBreederInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleMatureBreederInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleOldInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            
            tempMaleJoeyInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleJuvenileInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleYoungBreederInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleMatureBreederInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleOldInfectedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            
            tempFemaleJoeyDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleJuvenileDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleYoungBreederDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleMatureBreederDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempFemaleOldDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            
            tempMaleJoeyDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleJuvenileDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleYoungBreederDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleMatureBreederDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
            tempMaleOldDiseasedRecordMatrix = zeros(numberOfVaccineProtocols+1, 2 + 12*calibrationParams.yearsToSimulate);
        end
        
        % Run simulation without vaccine
        [results,~,records,stopFlag,snapshotRecord] = modelMonthly(paramsMatrix(goodParamsIndexes(indParams),:),paramsFieldNames,paramsWithoutRanges,false,false, ...
            [],calibrationParams.yearsToSimulate,[], [], ...
            startingPopulations(indParams),false,calibrationParams,false,bodyScoreParams, true, reproductiveSuccessStruct);
        
        tempResultsArray{end} = results;
        tempSnapshotRecordArray{end} = snapshotRecord;
        tempPopRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.populationRecord];
        tempInfRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.infectedPopulationRecord];
        tempIncidenceRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.incidenceRecord];
        tempDiseasedRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.diseasedPopulationRecord];
        tempVaccinatedRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.vaccinatedRecord];
        tempMothersWithYoungRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.mothersWithYoungRecord];
        tempPotentialMothersRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.potentialMothersRecord];
        tempDeathsRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.deathsRecord];
        tempVaccinationRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.vaccinatedRecord];
        tempDeathsByDiseaseRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.deathsByDiseaseRecord];
        tempDeathsByEuthanasiaRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.deathsByEuthanasiaRecord];
        tempDeathsByOtherRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.deathsByOtherRecord];
        tempDeathsMotherDiedRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.deathsMotherDiedRecord];
        tempEmigrantsExitedRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.emigrantsExitedRecord];
        tempImmigrantsEnteredRecordMatrix(end,:) = [0 goodParamsIndexes(indParams) records.immigrantsEnteredRecord];
        
        % Run simulations with vaccines
        for indLocateable = 1:length(proportionLocateable)
            for indEmigrations = 1:length(emigrationsByMonth)
                for indEffAndHalfLifeScalingParam = 1:length(effAndHalfLifeScalingParam)
                    for indDelivery = 1:length(numberOfCapturesByMonth)
                        for indBoostType = 1:length(boostType)
                            for indBoostAmount = 1:length(boostAmount)
                                for indGroups = 1:length(groups)
                                    for indAntibiotics = 1:length(usingAntibiotics)
                                        for indTargetUnvaccinated = 1:length(targetUnvaccinatedKoalas)
                                            for indCureEff = 1:length(cureEfficacy)
                                                for indBoostFromMating = 1:length(boostFromMating)
                                                    for indPreventsWhat = 1:length(preventsWhat)
                                                        for indCull = 1:length(cull)
                                                            thisSimTic = tic;
                                                            currentVaccineProtocolNumber = ...
                                                                indCull ...
                                                                + (indPreventsWhat-1)*length(cull) ...
                                                                + (indBoostFromMating-1)*length(preventsWhat)*length(cull) ...
                                                                + (indCureEff-1)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indTargetUnvaccinated-1)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indAntibiotics-1)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indGroups-1)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indBoostAmount-1)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indBoostType-1)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indDelivery-1)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indEffAndHalfLifeScalingParam-1)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indEmigrations-1)*length(effAndHalfLifeScalingParam)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull) ...
                                                                + (indLocateable-1)*length(emigrationsByMonth)*length(effAndHalfLifeScalingParam)*length(numberOfCapturesByMonth)*length(boostType)*length(boostAmount)*length(groups)*length(usingAntibiotics)*length(targetUnvaccinatedKoalas)*length(cureEfficacy)*length(boostFromMating)*length(preventsWhat)*length(cull);
                                                            currentScenarioSimNumber = (indParams-1)*numberOfVaccineProtocols + currentVaccineProtocolNumber;
                                                            
                                                            disp(['Running scenario simulation ' num2str(currentScenarioSimNumber) ' (parameter set ' num2str(indParams) ') of ' num2str(numberOfScenarioSims) '...'])
                                                            
                                                            vaccineProtocol = struct('halfLife',getHalfLife(effAndHalfLifeScalingParam(indEffAndHalfLifeScalingParam)),'initialEfficacy',getInitialEfficacy(effAndHalfLifeScalingParam(indEffAndHalfLifeScalingParam)), ...
                                                                'boostType',boostType(indBoostType), 'boostAmount',boostAmount(indBoostAmount), ...
                                                                'groups',groups(indGroups),'firstVaccineYear',firstVaccineYear, ...
                                                                'usingAntibiotics',usingAntibiotics(indAntibiotics),'cureEfficacy',cureEfficacy(indCureEff),'numberOfCapturesByMonth',numberOfCapturesByMonth(indDelivery), ...
                                                                'boostFromMating',boostFromMating(indBoostFromMating),'targetUnvaccinatedKoalas',targetUnvaccinatedKoalas(indTargetUnvaccinated), ...
                                                                'preventsWhat',preventsWhat(indPreventsWhat),'cull',cull(indCull),'emigrationsByMonth',emigrationsByMonth(indEmigrations), ...
                                                                'proportionLocateable',proportionLocateable(indLocateable));
                                                            
                                                            [results,~,records,stopFlag,snapshotRecord,crashError] = modelMonthly(paramsMatrix(goodParamsIndexes(indParams),:),paramsFieldNames,paramsWithoutRanges,false,false, ...
                                                                [],calibrationParams.yearsToSimulate,[], vaccineProtocol, ...
                                                                startingPopulations(indParams),false,calibrationParams,false,bodyScoreParams, true, reproductiveSuccessStruct);
                                                            
                                                            tempErrorList{currentVaccineProtocolNumber} = crashError;
                                                            tempResultsArray{currentVaccineProtocolNumber} = results;
                                                            tempSnapshotRecordArray{currentVaccineProtocolNumber} = snapshotRecord;
                                                            tempPopRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.populationRecord];
                                                            tempInfRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.infectedPopulationRecord];
                                                            tempIncidenceRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.incidenceRecord];
                                                            tempDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.diseasedPopulationRecord];
                                                            tempVaccinatedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.vaccinatedRecord];
                                                            tempMothersWithYoungRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.mothersWithYoungRecord];
                                                            tempPotentialMothersRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.potentialMothersRecord];
                                                            tempDeathsRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.deathsRecord];
                                                            tempVaccinationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.vaccinationRecord];
                                                            tempDeathsByDiseaseRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.deathsByDiseaseRecord];
                                                            tempDeathsByEuthanasiaRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.deathsByEuthanasiaRecord];
                                                            tempDeathsByOtherRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.deathsByOtherRecord];
                                                            tempDeathsMotherDiedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.deathsMotherDiedRecord];
                                                            tempEmigrantsExitedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.emigrantsExitedRecord];
                                                            tempImmigrantsEnteredRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.immigrantsEnteredRecord];
                                                            
                                                            if isRetainResults
                                                                tempFemaleJoeyPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJoeyPopulationRecord];
                                                                tempFemaleJuvenilePopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJuvenilePopulationRecord];
                                                                tempFemaleYoungBreederPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleYoungBreederPopulationRecord];
                                                                tempFemaleMatureBreederPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleMatureBreederPopulationRecord];
                                                                tempFemaleOldPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleOldPopulationRecord];
                                                                
                                                                tempMaleJoeyPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJoeyPopulationRecord];
                                                                tempMaleJuvenilePopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJuvenilePopulationRecord];
                                                                tempMaleYoungBreederPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleYoungBreederPopulationRecord];
                                                                tempMaleMatureBreederPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleMatureBreederPopulationRecord];
                                                                tempMaleOldPopulationRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleOldPopulationRecord];
                                                                
                                                                tempFemaleJoeyInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJoeyInfectedRecord];
                                                                tempFemaleJuvenileInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJuvenileInfectedRecord];
                                                                tempFemaleYoungBreederInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleYoungBreederInfectedRecord];
                                                                tempFemaleMatureBreederInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleMatureBreederInfectedRecord];
                                                                tempFemaleOldInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleOldInfectedRecord];
                                                                
                                                                tempMaleJoeyInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJoeyInfectedRecord];
                                                                tempMaleJuvenileInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJuvenileInfectedRecord];
                                                                tempMaleYoungBreederInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleYoungBreederInfectedRecord];
                                                                tempMaleMatureBreederInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleMatureBreederInfectedRecord];
                                                                tempMaleOldInfectedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleOldInfectedRecord];
                                                                
                                                                tempFemaleJoeyDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJoeyDiseasedRecord];
                                                                tempFemaleJuvenileDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleJuvenileDiseasedRecord];
                                                                tempFemaleYoungBreederDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleYoungBreederDiseasedRecord];
                                                                tempFemaleMatureBreederDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleMatureBreederDiseasedRecord];
                                                                tempFemaleOldDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.femaleOldDiseasedRecord];
                                                                
                                                                tempMaleJoeyDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJoeyDiseasedRecord];
                                                                tempMaleJuvenileDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleJuvenileDiseasedRecord];
                                                                tempMaleYoungBreederDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleYoungBreederDiseasedRecord];
                                                                tempMaleMatureBreederDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleMatureBreederDiseasedRecord];
                                                                tempMaleOldDiseasedRecordMatrix(currentVaccineProtocolNumber,:) = [currentVaccineProtocolNumber goodParamsIndexes(indParams) records.maleOldDiseasedRecord];
                                                            end
                                                                                                                        
                                                            disp(['   Finished scenario ' num2str(currentScenarioSimNumber) ' of ' num2str(numberOfScenarioSims) '. Took ' num2str(toc(thisSimTic)) ' seconds.'])
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        errorList(:,indParams) = tempErrorList;
        resultsArray(:,indParams) = tempResultsArray;
        snapshotRecordArray(:,indParams) = tempSnapshotRecordArray;
        popRecordMatrix(:,indParams,:) = tempPopRecordMatrix;
        infRecordMatrix(:,indParams,:) = tempInfRecordMatrix;
        incidenceRecordMatrix(:,indParams,:) = tempIncidenceRecordMatrix;
        diseasedRecordMatrix(:,indParams,:) = tempDiseasedRecordMatrix;
        vaccinatedRecordMatrix(:,indParams,:) = tempVaccinatedRecordMatrix;
        mothersWithYoungRecordMatrix(:,indParams,:) = tempMothersWithYoungRecordMatrix;
        potentialMothersRecordMatrix(:,indParams,:) = tempPotentialMothersRecordMatrix;
        deathsRecordMatrix(:,indParams,:) = tempDeathsRecordMatrix;
        vaccinationRecordMatrix(:,indParams,:) = tempVaccinationRecordMatrix;
        deathsByDiseaseRecordMatrix(:,indParams,:) = tempDeathsByDiseaseRecordMatrix;
        deathsByEuthanasiaRecordMatrix(:,indParams,:) = tempDeathsByEuthanasiaRecordMatrix;
        deathsByOtherRecordMatrix(:,indParams,:) = tempDeathsByOtherRecordMatrix;
        deathsMotherDiedRecordMatrix(:,indParams,:) = tempDeathsMotherDiedRecordMatrix;
        emigrantsExitedRecordMatrix(:,indParams,:) = tempEmigrantsExitedRecordMatrix;
        immigrantsEnteredRecordMatrix(:,indParams,:) = tempImmigrantsEnteredRecordMatrix;
        
        if isRetainResults
            femaleJoeyPopulationRecordMatrix(:,indParams,:) = tempFemaleJoeyPopulationRecordMatrix;
            femaleJuvenilePopulationRecordMatrix(:,indParams,:) = tempFemaleJuvenilePopulationRecordMatrix;
            femaleYoungBreederPopulationRecordMatrix(:,indParams,:) = tempFemaleYoungBreederPopulationRecordMatrix;
            femaleMatureBreederPopulationRecordMatrix(:,indParams,:) = tempFemaleMatureBreederPopulationRecordMatrix;
            femaleOldPopulationRecordMatrix(:,indParams,:) = tempFemaleOldPopulationRecordMatrix;
            
            maleJoeyPopulationRecordMatrix(:,indParams,:) = tempMaleJoeyPopulationRecordMatrix;
            maleJuvenilePopulationRecordMatrix(:,indParams,:) = tempMaleJuvenilePopulationRecordMatrix;
            maleYoungBreederPopulationRecordMatrix(:,indParams,:) = tempMaleYoungBreederPopulationRecordMatrix;
            maleMatureBreederPopulationRecordMatrix(:,indParams,:) = tempMaleMatureBreederPopulationRecordMatrix;
            maleOldPopulationRecordMatrix(:,indParams,:) = tempMaleOldPopulationRecordMatrix;
            
            femaleJoeyInfectedRecordMatrix(:,indParams,:) = tempFemaleJoeyInfectedRecordMatrix;
            femaleJuvenileInfectedRecordMatrix(:,indParams,:) = tempFemaleJuvenileInfectedRecordMatrix;
            femaleYoungBreederInfectedRecordMatrix(:,indParams,:) = tempFemaleYoungBreederInfectedRecordMatrix;
            femaleMatureBreederInfectedRecordMatrix(:,indParams,:) = tempFemaleMatureBreederInfectedRecordMatrix;
            femaleOldInfectedRecordMatrix(:,indParams,:) = tempFemaleOldInfectedRecordMatrix;
            
            maleJoeyInfectedRecordMatrix(:,indParams,:) = tempMaleJoeyInfectedRecordMatrix;
            maleJuvenileInfectedRecordMatrix(:,indParams,:) = tempMaleJuvenileInfectedRecordMatrix;
            maleYoungBreederInfectedRecordMatrix(:,indParams,:) = tempMaleYoungBreederInfectedRecordMatrix;
            maleMatureBreederInfectedRecordMatrix(:,indParams,:) = tempMaleMatureBreederInfectedRecordMatrix;
            maleOldInfectedRecordMatrix(:,indParams,:) = tempMaleOldInfectedRecordMatrix;
            
            femaleJoeyDiseasedRecordMatrix(:,indParams,:) = tempFemaleJoeyDiseasedRecordMatrix;
            femaleJuvenileDiseasedRecordMatrix(:,indParams,:) = tempFemaleJuvenileDiseasedRecordMatrix;
            femaleYoungBreederDiseasedRecordMatrix(:,indParams,:) = tempFemaleYoungBreederDiseasedRecordMatrix;
            femaleMatureBreederDiseasedRecordMatrix(:,indParams,:) = tempFemaleMatureBreederDiseasedRecordMatrix;
            femaleOldDiseasedRecordMatrix(:,indParams,:) = tempFemaleOldDiseasedRecordMatrix;
            
            maleJoeyDiseasedRecordMatrix(:,indParams,:) = tempMaleJoeyDiseasedRecordMatrix;
            maleJuvenileDiseasedRecordMatrix(:,indParams,:) = tempMaleJuvenileDiseasedRecordMatrix;
            maleYoungBreederDiseasedRecordMatrix(:,indParams,:) = tempMaleYoungBreederDiseasedRecordMatrix;
            maleMatureBreederDiseasedRecordMatrix(:,indParams,:) = tempMaleMatureBreederDiseasedRecordMatrix;
            maleOldDiseasedRecordMatrix(:,indParams,:) = tempMaleOldDiseasedRecordMatrix;
        end
        
    end
    catch err
        [~, machineName] = dos('hostname');
        sendEmailFromMatlab('acsthrowaway', 'throwthrow', 'acraig@kirby.unsw.edu.au', ['Matlab encountered an error in runVaccineSims on ' machineName(1:7) '.'], '')
        if strcmp(err.identifier, 'parallel:internal:SerializeBufferTooLarge')
            filterParamsThatWereCompleted(first:last) = false;
            disp(['Error ' err.identifier ' occurred while running sims for params ' num2str(first) ':' num2str(last) '.'])
        else
            throw(err)
        end
    end
end


vaccineRecords.results = cell2mat(reshape(resultsArray, [numberOfScenarioSims+numberOfGoodParams 1]));
vaccineRecords.snapshotRecord = snapshotRecordArray;
vaccineRecords.popRecordMatrix = reshape(popRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.infRecordMatrix = reshape(infRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.incidenceRecordMatrix = reshape(incidenceRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.diseasedRecordMatrix = reshape(diseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.vaccinatedRecordMatrix = reshape(vaccinatedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.mothersWithYoungRecordMatrix = reshape(mothersWithYoungRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.potentialMothersRecordMatrix = reshape(potentialMothersRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.deathsRecordMatrix = reshape(deathsRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.vaccinationRecordMatrix = reshape(vaccinationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.deathsByDiseaseRecordMatrix = reshape(deathsByDiseaseRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.deathsByEuthanasiaRecordMatrix = reshape(deathsByEuthanasiaRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.deathsByOtherRecordMatrix = reshape(deathsByOtherRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.deathsMotherDiedRecordMatrix = reshape(deathsMotherDiedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.emigrantsExitedRecordMatrix = reshape(emigrantsExitedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
vaccineRecords.immigrantsEnteredRecordMatrix = reshape(immigrantsEnteredRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);

if isRetainResults
    vaccineRecords.femaleJoeyPopulationRecordMatrix = reshape(femaleJoeyPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleJuvenilePopulationRecordMatrix = reshape(femaleJuvenilePopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleYoungBreederPopulationRecordMatrix = reshape(femaleYoungBreederPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleMatureBreederPopulationRecordMatrix = reshape(femaleMatureBreederPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleOldPopulationRecordMatrix = reshape(femaleOldPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    
    vaccineRecords.maleJoeyPopulationRecordMatrix = reshape(maleJoeyPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleJuvenilePopulationRecordMatrix = reshape(maleJuvenilePopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleYoungBreederPopulationRecordMatrix = reshape(maleYoungBreederPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleMatureBreederPopulationRecordMatrix = reshape(maleMatureBreederPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleOldPopulationRecordMatrix = reshape(maleOldPopulationRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    
    vaccineRecords.femaleJoeyInfectedRecordMatrix = reshape(femaleJoeyInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleJuvenileInfectedRecordMatrix = reshape(femaleJuvenileInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleYoungBreederInfectedRecordMatrix = reshape(femaleYoungBreederInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleMatureBreederInfectedRecordMatrix = reshape(femaleMatureBreederInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleOldInfectedRecordMatrix = reshape(femaleOldInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    
    vaccineRecords.maleJoeyInfectedRecordMatrix = reshape(maleJoeyInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleJuvenileInfectedRecordMatrix = reshape(maleJuvenileInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleYoungBreederInfectedRecordMatrix = reshape(maleYoungBreederInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleMatureBreederInfectedRecordMatrix = reshape(maleMatureBreederInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleOldInfectedRecordMatrix = reshape(maleOldInfectedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    
    vaccineRecords.femaleJoeyDiseasedRecordMatrix = reshape(femaleJoeyDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleJuvenileDiseasedRecordMatrix = reshape(femaleJuvenileDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleYoungBreederDiseasedRecordMatrix = reshape(femaleYoungBreederDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleMatureBreederDiseasedRecordMatrix = reshape(femaleMatureBreederDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.femaleOldDiseasedRecordMatrix = reshape(femaleOldDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    
    vaccineRecords.maleJoeyDiseasedRecordMatrix = reshape(maleJoeyDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleJuvenileDiseasedRecordMatrix = reshape(maleJuvenileDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleYoungBreederDiseasedRecordMatrix = reshape(maleYoungBreederDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleMatureBreederDiseasedRecordMatrix = reshape(maleMatureBreederDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
    vaccineRecords.maleOldDiseasedRecordMatrix = reshape(maleOldDiseasedRecordMatrix, [numberOfScenarioSims+numberOfGoodParams 2 + 12*calibrationParams.yearsToSimulate]);
end
