function [goodParams,noInfectionRecords,populationSnapshots] = runNoInfectionSims(paramsMatrix,paramsFieldNames,paramsWithoutRanges,~,calibrationParams, ...
    lengthOfResults,maxPermittedPopulation,minSnapshotSize,bodyScoreParams,totalKoalas,isRetainResults, recordVarType, reproductiveSuccessStruct)

% [goodParams,noInfectionRecords,populationSnapshots] = runNoInfectionSims(paramsMatrix,paramsFieldNames,paramsWithoutRanges,~,calibrationParams, ...
%    lengthOfResults,maxPermittedPopulation,minSnapshotSize,bodyScoreParams,totalKoalas,isRetainResults, recordVarType, reproductiveSuccessStruct)
% Performs demographic calibration by running simulations without infection and collecting the results.
%
% paramsMatrix: Parameter sets.
% paramsFieldNames: Parameter names.
% paramsWithoutRanges: Names and values of parameters without ranges.
% calibrationParams: 'Metaparameters' used in calibration.
% lengthOfResults: Length of results data.
% maxPermittedPopulation: Maximum population allowed before simulation
% halts.
% minSnapshotSize: Population required before snapshot of population will
% be taken.
% bodyScoreParams: Parameters used to caculate body score.
% totalKoalas: Number of koalas at start of simulations.
% isRetainResults: Flag for whether to retain or discard results.
% recordVarType: Data type used to store records.
% reproductiveSuccessStruct: Struct governing mating weights.
%
% goodParams: IDs of parameter sets that passed demographic calibration.
% noInfectionRecords: Simulation summary statistics.
% populationSnapshots: Snapshots of populations that passed calibration,
% which can be used for subsequent simulations.

goodParams = [];
populationSnapshots = [];
numberOfParamSets = size(paramsMatrix,1);
goodParamsFilter = false(numberOfParamSets,1);

lengthOfExtraInfoInResults = 3; % Scenario number (0 here as this is the 'no vaccine' case), parameter set number, weighting (measure of success).

resultsArray = cell(numberOfParamSets,1);
popRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
infRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
incidenceRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
diseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
vaccinatedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);

if isRetainResults
    femaleJoeyPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleJuvenilePopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleYoungBreederPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleMatureBreederPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleOldPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    
    maleJoeyPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleJuvenilePopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleYoungBreederPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleMatureBreederPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleOldPopulationRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    
    femaleJoeyInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleJuvenileInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleYoungBreederInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleMatureBreederInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleOldInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    
    maleJoeyInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleJuvenileInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleYoungBreederInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleMatureBreederInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleOldInfectedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    
    femaleJoeyDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleJuvenileDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleYoungBreederDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleMatureBreederDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    femaleOldDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    
    maleJoeyDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleJuvenileDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleYoungBreederDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleMatureBreederDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
    maleOldDiseasedRecordMatrix = zeros(  numberOfParamSets, 2 + 12*calibrationParams.yearsToSimulate);
end



paramsPerParfor = 8;
numOuterIterations = ceil(numberOfParamSets / paramsPerParfor);
for indOuter = 1:numOuterIterations
    first = (indOuter-1) * paramsPerParfor + 1;
    last = min(numberOfParamSets, paramsPerParfor*indOuter);
    % parfor goes here
    parfor paramInd = first:last
        thisSimTic = tic;
        disp(['Running no-infection simulation ' num2str(paramInd) ' of ' num2str(numberOfParamSets) '...']);
        % Run no-vaccine sims.
        [results,populationSnapshot,records,stopFlag] = ...
            modelMonthly(paramsMatrix(paramInd,:),paramsFieldNames,paramsWithoutRanges,false,false,totalKoalas,calibrationParams.yearsToSimulate,[],[],[],true, ...
            calibrationParams,true,bodyScoreParams, false, reproductiveSuccessStruct);
        clear results.snapshotRecord
        
        populationDidNotShrink = false;
        doublingTimeOK = false;
        
        popAtAssumedStableYear = double(records.populationRecord(calibrationParams.minYearsBeforeSnapshot*12));
        populationDidNotShrink = popAtAssumedStableYear <= results.finalPopulation;
        
        if any(results.finalPopulation == 0)
            lastMonthWithNonZeroPop = find(records.populationRecord > 0,1,'last');
            finalPopForDeterminingHalfLife = double(records.populationRecord(lastMonthWithNonZeroPop));
            monthsEffectivelySimulated = lastMonthWithNonZeroPop - calibrationParams.minYearsBeforeSnapshot*12;
        else
            monthsEffectivelySimulated = calibrationParams.yearsToSimulate*12 - calibrationParams.minYearsBeforeSnapshot*12;
            finalPopForDeterminingHalfLife = double(results.finalPopulation);
        end
        doublingTimeInMonths = double(monthsEffectivelySimulated) * log(2) / log( double(finalPopForDeterminingHalfLife) / double(popAtAssumedStableYear) );
        doublingTimeInYears = doublingTimeInMonths / 12;
        doublingTimeOK = doublingTimeInYears <= calibrationParams.maxDoublingTime && doublingTimeInYears >= calibrationParams.minDoublingTime;
        
        successForThisInd = populationDidNotShrink && doublingTimeOK;
        
        if successForThisInd
            goodParamsFilter(paramInd) = true;
            populationSnapshots = [populationSnapshots; populationSnapshot];
        end
        weightForTheseParams = successForThisInd;
        
        results.paramsIndex = paramInd;
        results.paramIndThisInd = successForThisInd;
        results.populationDidNotShrink = populationDidNotShrink;
        results.doublingTimeOK = doublingTimeOK;
        
        resultsArray{paramInd} = results;
        popRecordMatrix(paramInd,:) = [0 paramInd records.populationRecord];
        infRecordMatrix(paramInd,:) = [0 paramInd records.infectedPopulationRecord];
        incidenceRecordMatrix(paramInd,:,:) = [ 0 paramInd records.incidenceRecord];
        diseasedRecordMatrix(paramInd,:,:) = [ 0 paramInd records.diseasedPopulationRecord];
        vaccinatedRecordMatrix(paramInd,:,:) = [ 0 paramInd records.vaccinatedRecord];
        
        if isRetainResults
            femaleJoeyPopulationRecordMatrix(paramInd,:) = [0 paramInd records.femaleJoeyPopulationRecord];
            femaleJuvenilePopulationRecordMatrix(paramInd,:) = [0 paramInd records.femaleJuvenilePopulationRecord];
            femaleYoungBreederPopulationRecordMatrix(paramInd,:) = [0 paramInd records.femaleYoungBreederPopulationRecord];
            femaleMatureBreederPopulationRecordMatrix(paramInd,:) = [0 paramInd records.femaleMatureBreederPopulationRecord];
            femaleOldPopulationRecordMatrix(paramInd,:) = [0 paramInd records.femaleOldPopulationRecord];
            
            maleJoeyPopulationRecordMatrix(paramInd,:) = [0 paramInd records.maleJoeyPopulationRecord];
            maleJuvenilePopulationRecordMatrix(paramInd,:) = [0 paramInd records.maleJuvenilePopulationRecord];
            maleYoungBreederPopulationRecordMatrix(paramInd,:) = [0 paramInd records.maleYoungBreederPopulationRecord];
            maleMatureBreederPopulationRecordMatrix(paramInd,:) = [0 paramInd records.maleMatureBreederPopulationRecord];
            maleOldPopulationRecordMatrix(paramInd,:) = [0 paramInd records.maleOldPopulationRecord];
            
            femaleJoeyInfectedRecordMatrix(paramInd,:) = [0 paramInd records.femaleJoeyInfectedRecord];
            femaleJuvenileInfectedRecordMatrix(paramInd,:) = [0 paramInd records.femaleJuvenileInfectedRecord];
            femaleYoungBreederInfectedRecordMatrix(paramInd,:) = [0 paramInd records.femaleYoungBreederInfectedRecord];
            femaleMatureBreederInfectedRecordMatrix(paramInd,:) = [0 paramInd records.femaleMatureBreederInfectedRecord];
            femaleOldInfectedRecordMatrix(paramInd,:) = [0 paramInd records.femaleOldInfectedRecord];
            
            maleJoeyInfectedRecordMatrix(paramInd,:) = [0 paramInd records.maleJoeyInfectedRecord];
            maleJuvenileInfectedRecordMatrix(paramInd,:) = [0 paramInd records.maleJuvenileInfectedRecord];
            maleYoungBreederInfectedRecordMatrix(paramInd,:) = [0 paramInd records.maleYoungBreederInfectedRecord];
            maleMatureBreederInfectedRecordMatrix(paramInd,:) = [0 paramInd records.maleMatureBreederInfectedRecord];
            maleOldInfectedRecordMatrix(paramInd,:) = [0 paramInd records.maleOldInfectedRecord];
            
            femaleJoeyDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.femaleJoeyDiseasedRecord];
            femaleJuvenileDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.femaleJuvenileDiseasedRecord];
            femaleYoungBreederDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.femaleYoungBreederDiseasedRecord];
            femaleMatureBreederDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.femaleMatureBreederDiseasedRecord];
            femaleOldDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.femaleOldDiseasedRecord];
            
            maleJoeyDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.maleJoeyDiseasedRecord];
            maleJuvenileDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.maleJuvenileDiseasedRecord];
            maleYoungBreederDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.maleYoungBreederDiseasedRecord];
            maleMatureBreederDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.maleMatureBreederDiseasedRecord];
            maleOldDiseasedRecordMatrix(paramInd,:) = [0 paramInd records.maleOldDiseasedRecord];
        end
        
        disp(['   No-infection simulation ' num2str(paramInd) ' ended. Success: ' bool2str(successForThisInd) '. Took ' num2str(toc(thisSimTic)) ' seconds.']);
        disp(['     ' num2str(paramInd) ': populationDidNotShrink: ' bool2str(populationDidNotShrink)])
        disp(['     ' num2str(paramInd) ': doublingTimeOK: ' bool2str(doublingTimeOK)])
    end
end

goodParams = find(goodParamsFilter == true);

noInfectionRecords.results = cell2mat(resultsArray);
noInfectionRecords.popRecordMatrix = popRecordMatrix;
noInfectionRecords.infRecordMatrix = infRecordMatrix;
noInfectionRecords.incidenceRecordMatrix = incidenceRecordMatrix;
noInfectionRecords.diseasedRecordMatrix = diseasedRecordMatrix;
noInfectionRecords.vaccinatedRecordMatrix = vaccinatedRecordMatrix;

if isRetainResults
    noInfectionRecords.femaleJoeyPopulationRecordMatrix = femaleJoeyPopulationRecordMatrix;
    noInfectionRecords.femaleJuvenilePopulationRecordMatrix = femaleJuvenilePopulationRecordMatrix;
    noInfectionRecords.femaleYoungBreederPopulationRecordMatrix = femaleYoungBreederPopulationRecordMatrix;
    noInfectionRecords.femaleMatureBreederPopulationRecordMatrix = femaleMatureBreederPopulationRecordMatrix;
    noInfectionRecords.femaleOldPopulationRecordMatrix = femaleOldPopulationRecordMatrix;
    
    noInfectionRecords.maleJoeyPopulationRecordMatrix = maleJoeyPopulationRecordMatrix;
    noInfectionRecords.maleJuvenilePopulationRecordMatrix = maleJuvenilePopulationRecordMatrix;
    noInfectionRecords.maleYoungBreederPopulationRecordMatrix = maleYoungBreederPopulationRecordMatrix;
    noInfectionRecords.maleMatureBreederPopulationRecordMatrix = maleMatureBreederPopulationRecordMatrix;
    noInfectionRecords.maleOldPopulationRecordMatrix = maleOldPopulationRecordMatrix;
    
    noInfectionRecords.femaleJoeyInfectedRecordMatrix = femaleJoeyInfectedRecordMatrix;
    noInfectionRecords.femaleJuvenileInfectedRecordMatrix = femaleJuvenileInfectedRecordMatrix;
    noInfectionRecords.femaleYoungBreederInfectedRecordMatrix = femaleYoungBreederInfectedRecordMatrix;
    noInfectionRecords.femaleMatureBreederInfectedRecordMatrix = femaleMatureBreederInfectedRecordMatrix;
    noInfectionRecords.femaleOldInfectedRecordMatrix = femaleOldInfectedRecordMatrix;
    
    noInfectionRecords.maleJoeyInfectedRecordMatrix = maleJoeyInfectedRecordMatrix;
    noInfectionRecords.maleJuvenileInfectedRecordMatrix = maleJuvenileInfectedRecordMatrix;
    noInfectionRecords.maleYoungBreederInfectedRecordMatrix = maleYoungBreederInfectedRecordMatrix;
    noInfectionRecords.maleMatureBreederInfectedRecordMatrix = maleMatureBreederInfectedRecordMatrix;
    noInfectionRecords.maleOldInfectedRecordMatrix = maleOldInfectedRecordMatrix;
    
    noInfectionRecords.femaleJoeyDiseasedRecordMatrix = femaleJoeyDiseasedRecordMatrix;
    noInfectionRecords.femaleJuvenileDiseasedRecordMatrix = femaleJuvenileDiseasedRecordMatrix;
    noInfectionRecords.femaleYoungBreederDiseasedRecordMatrix = femaleYoungBreederDiseasedRecordMatrix;
    noInfectionRecords.femaleMatureBreederDiseasedRecordMatrix = femaleMatureBreederDiseasedRecordMatrix;
    noInfectionRecords.femaleOldDiseasedRecordMatrix = femaleOldDiseasedRecordMatrix;
    
    noInfectionRecords.maleJoeyDiseasedRecordMatrix = maleJoeyDiseasedRecordMatrix;
    noInfectionRecords.maleJuvenileDiseasedRecordMatrix = maleJuvenileDiseasedRecordMatrix;
    noInfectionRecords.maleYoungBreederDiseasedRecordMatrix = maleYoungBreederDiseasedRecordMatrix;
    noInfectionRecords.maleMatureBreederDiseasedRecordMatrix = maleMatureBreederDiseasedRecordMatrix;
    noInfectionRecords.maleOldDiseasedRecordMatrix = maleOldDiseasedRecordMatrix;
end

end