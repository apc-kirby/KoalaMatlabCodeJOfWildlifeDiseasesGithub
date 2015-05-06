function [goodParams,noVaccineRecords,populationSnapshots] = ...
    runNoVaccineSims(goodParamsIndexesNoInfection, ...
    paramsMatrix, paramsFieldNames, paramsWithoutRanges, ~,calibrationParams,lengthOfResults,initialPrevalence,bodyScoreParams,totalKoalas, isRetainResults, recordVarType, reproductiveSuccessStruct)

% [goodParams,noVaccineRecords,populationSnapshots] = ...
%    runNoVaccineSims(goodParamsIndexesNoInfection, ...
%    paramsMatrix, paramsFieldNames, paramsWithoutRanges, ~,calibrationParams,lengthOfResults,initialPrevalence,bodyScoreParams,totalKoalas, isRetainResults, recordVarType, reproductiveSuccessStruct)
% Performs disease calibration by running simulations with infection and collecting the results.
%
% goodParamsIndexesNoInfection: IDs of parameter sets that passed
% demographic calibration.
% paramsMatrix: Parameter sets.
% paramsFieldNames: Parameter names.
% paramsWithoutRanges: Names and values of parameters without ranges.
% calibrationParams: 'Metaparameters' used in calibration.
% lengthOfResults: Length of results data.
% initialPrevalence: Infection prevalence at start of simulations.
% bodyScoreParams: Parameters used to caculate body score.
% totalKoalas: Number of koalas at start of simulations.
% isRetainResults: Flag for whether to retain or discard results.
% recordVarType: Data type used to store records.
% reproductiveSuccessStruct: Struct governing mating weights.
%
% goodParams: IDs of parameter sets that passed disease calibration.
% noVaccineRecords: Simulation summary statistics.
% populationSnapshots: Snapshots of populations that passed calibration,
% which can be used for subsequent simulations.

filterGoodParams = false(size(goodParamsIndexesNoInfection));
numberOfGoodParams = length(goodParamsIndexesNoInfection);

resultsArray = cell(numberOfGoodParams,1);
popRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
infRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
incidenceRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
diseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
vaccinatedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);

if isRetainResults
    femaleJoeyPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenilePopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenilePopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldPopulationRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    femaleJoeyInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenileInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenileInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldInfectedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    femaleJoeyDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleJuvenileDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleYoungBreederDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleMatureBreederDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    femaleOldDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    
    maleJoeyDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleJuvenileDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleYoungBreederDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleMatureBreederDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
    maleOldDiseasedRecordMatrix = zeros(  numberOfGoodParams, 2 + 12*calibrationParams.yearsToSimulate, recordVarType);
end

populationSnapshots = [];

paramsPerParfor = 64;
numOuterIterations = ceil(length(goodParamsIndexesNoInfection) / paramsPerParfor);
for indOuter = 1:numOuterIterations
    first = (indOuter-1) * paramsPerParfor + 1;
    last = min(length(goodParamsIndexesNoInfection), paramsPerParfor*indOuter);
    % parfor goes here
    parfor paramInd = first:last
        
        % Run no-vaccine sims.
        thisSimTic = tic;
        disp(['Running no-vaccine simulation ' num2str(paramInd) ' of ' num2str(length(goodParamsIndexesNoInfection)) '...']);
        
        [results,populationSnapshot,records,stopFlag] = ...
            modelMonthly(paramsMatrix(goodParamsIndexesNoInfection(paramInd),:),paramsFieldNames,paramsWithoutRanges,false,false, ...
            totalKoalas,calibrationParams.yearsToSimulate,initialPrevalence, [], ...
            [],false,calibrationParams,true,bodyScoreParams, false, reproductiveSuccessStruct, goodParamsIndexesNoInfection(paramInd));
        
        if ~isempty(populationSnapshot)
            populationSnapshot.paramSetNum = goodParamsIndexesNoInfection(paramInd);
        end
        
        startingPopNums = double(results.startingPopSize);
        initialPopForDeterminingHalfLife = double(records.populationRecord(calibrationParams.assumedYearsBeforeStabilising*12));
        finalPops = double(results.finalPopulation);
        finalPopsAreZero = finalPops == 0;
        if any(finalPopsAreZero)
            lastMonthWithNonZeroPop = find(records.populationRecord > 0,1,'last');
            finalPopForDeterminingHalfLife = double(records.populationRecord(lastMonthWithNonZeroPop));
            monthsEffectivelySimulated = lastMonthWithNonZeroPop - calibrationParams.minYearsBeforeSnapshot*12;
        else
            monthsEffectivelySimulated = calibrationParams.yearsToSimulate*12 - calibrationParams.assumedYearsBeforeStabilising*12;
            finalPopForDeterminingHalfLife = double(finalPops);
        end

        halvingTimeInMonths = double(monthsEffectivelySimulated) .* log(1/2) ./ log(double(finalPopForDeterminingHalfLife) ./ double(initialPopForDeterminingHalfLife));
        halvingTimeInYears = halvingTimeInMonths / 12;

        infectionPrevalenceOK = false;
        diseasePrevalenceOK = false;
        halvingTimeOK = halvingTimeInYears <= calibrationParams.maxHalvingTime & halvingTimeInYears >= calibrationParams.minHalvingTime;
        
        populationNotZero = ~isempty(populationSnapshot);
        infectionPrevalencePresumedStableMonthsStart = NaN;
        infectionPrevalencePresumedStableMonthsEnd = NaN;
        diseasePrevalencePresumedStableMonthsStart = NaN;
        diseasePrevalencePresumedStableMonthsEnd = NaN;
        
        if populationNotZero
            
            nonZeroPopulationMonths = records.populationRecord ~= 0;
            infectionPrevalencePercentRecord = 100 * double(records.infectedPopulationRecord(nonZeroPopulationMonths)) ./ double(records.populationRecord(nonZeroPopulationMonths));
            snapshotInfectionPrevalencePercent = infectionPrevalencePercentRecord(populationSnapshot.currentMonth);
            infectionPrevalenceOK = snapshotInfectionPrevalencePercent <= calibrationParams.maxInfectionPrevPercent & snapshotInfectionPrevalencePercent >= calibrationParams.minInfectionPrevPercent;
            diseasePrevalencePercentRecord = 100 * double(records.diseasedPopulationRecord(nonZeroPopulationMonths)) ./ double(records.populationRecord(nonZeroPopulationMonths));
            diseasePrevalencePresumedStableMonthsStart = calibrationParams.assumedYearsBeforeStabilising*12;
            snapshotDiseasePrevalencePercent = diseasePrevalencePercentRecord(populationSnapshot.currentMonth);
            diseasePrevalenceOK = snapshotDiseasePrevalencePercent <= calibrationParams.maxDiseasePrevPercent &  snapshotDiseasePrevalencePercent >= calibrationParams.minDiseasePrevPercent;

        end
        
        successForThisInd = populationNotZero && infectionPrevalenceOK && diseasePrevalenceOK && halvingTimeOK;
        if (successForThisInd)
            filterGoodParams(paramInd) = true;
            populationSnapshots = [populationSnapshots; populationSnapshot];
        end
        
        disp(['   No-vaccine simulation ' num2str(paramInd) ' ended. Success: ' bool2str(successForThisInd) '. Took ' num2str(toc(thisSimTic)) ' seconds.']);
        disp(['     ' num2str(paramInd) ': populationNotZero: ' bool2str(populationNotZero)])
        disp(['     ' num2str(paramInd) ': infectionPrevalenceOK: ' bool2str(infectionPrevalenceOK)])
        for indDiseasePrev = 1:length(diseasePrevalenceOK)
            disp(['     ' num2str(paramInd) ': diseasePrevalenceOK (pop ' num2str(indDiseasePrev) ' of ' num2str(length(diseasePrevalenceOK)) '): ' bool2str(diseasePrevalenceOK(indDiseasePrev))])
        end
        disp(['     ' num2str(paramInd) ': halvingTimeOK: ' bool2str(halvingTimeOK)])
        
        results.paramsIndex = goodParamsIndexesNoInfection(paramInd);
        results.successForThisInd = successForThisInd;
        results.populationNotZero = populationNotZero;
        results.infectionPrevalenceOK = infectionPrevalenceOK;
        results.diseasePrevalenceOK = diseasePrevalenceOK;
        results.halvingTimeOK = halvingTimeOK;
        results.infectionPrevalencePresumedStableMonthsStart = infectionPrevalencePresumedStableMonthsStart;
        results.infectionPrevalencePresumedStableMonthsEnd = infectionPrevalencePresumedStableMonthsEnd;
        results.diseasePrevalencePresumedStableMonthsStart = diseasePrevalencePresumedStableMonthsStart;
        results.diseasePrevalencePresumedStableMonthsEnd = diseasePrevalencePresumedStableMonthsEnd;
        
        resultsArray{paramInd} = results;
        popRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.populationRecord];
        infRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.infectedPopulationRecord];
        incidenceRecordMatrix(paramInd,:,:) = [ 0 goodParamsIndexesNoInfection(paramInd) records.incidenceRecord];
        diseasedRecordMatrix(paramInd,:,:) = [ 0 goodParamsIndexesNoInfection(paramInd) records.diseasedPopulationRecord];
        vaccinatedRecordMatrix(paramInd,:,:) = [0 goodParamsIndexesNoInfection(paramInd) records.vaccinatedRecord];
        
        if isRetainResults
            femaleJoeyPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJoeyPopulationRecord];
            femaleJuvenilePopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJuvenilePopulationRecord];
            femaleYoungBreederPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleYoungBreederPopulationRecord];
            femaleMatureBreederPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleMatureBreederPopulationRecord];
            femaleOldPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleOldPopulationRecord];
            
            maleJoeyPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJoeyPopulationRecord];
            maleJuvenilePopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJuvenilePopulationRecord];
            maleYoungBreederPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleYoungBreederPopulationRecord];
            maleMatureBreederPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleMatureBreederPopulationRecord];
            maleOldPopulationRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleOldPopulationRecord];
            
            femaleJoeyInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJoeyInfectedRecord];
            femaleJuvenileInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJuvenileInfectedRecord];
            femaleYoungBreederInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleYoungBreederInfectedRecord];
            femaleMatureBreederInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleMatureBreederInfectedRecord];
            femaleOldInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleOldInfectedRecord];
            
            maleJoeyInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJoeyInfectedRecord];
            maleJuvenileInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJuvenileInfectedRecord];
            maleYoungBreederInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleYoungBreederInfectedRecord];
            maleMatureBreederInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleMatureBreederInfectedRecord];
            maleOldInfectedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleOldInfectedRecord];
            
            femaleJoeyDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJoeyDiseasedRecord];
            femaleJuvenileDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleJuvenileDiseasedRecord];
            femaleYoungBreederDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleYoungBreederDiseasedRecord];
            femaleMatureBreederDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleMatureBreederDiseasedRecord];
            femaleOldDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.femaleOldDiseasedRecord];
            
            maleJoeyDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJoeyDiseasedRecord];
            maleJuvenileDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleJuvenileDiseasedRecord];
            maleYoungBreederDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleYoungBreederDiseasedRecord];
            maleMatureBreederDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleMatureBreederDiseasedRecord];
            maleOldDiseasedRecordMatrix(paramInd,:) = [0 goodParamsIndexesNoInfection(paramInd) records.maleOldDiseasedRecord];
        end
        
    end
end

goodParams = goodParamsIndexesNoInfection(filterGoodParams);

noVaccineRecords.results = cell2mat(resultsArray);
noVaccineRecords.popRecordMatrix = popRecordMatrix;
noVaccineRecords.infRecordMatrix = infRecordMatrix;
noVaccineRecords.incidenceRecordMatrix = incidenceRecordMatrix;
noVaccineRecords.diseasedRecordMatrix = diseasedRecordMatrix;
noVaccineRecords.vaccinatedRecordMatrix = vaccinatedRecordMatrix;

if isRetainResults
    noVaccineRecords.femaleJoeyPopulationRecordMatrix = femaleJoeyPopulationRecordMatrix;
    noVaccineRecords.femaleJuvenilePopulationRecordMatrix = femaleJuvenilePopulationRecordMatrix;
    noVaccineRecords.femaleYoungBreederPopulationRecordMatrix = femaleYoungBreederPopulationRecordMatrix;
    noVaccineRecords.femaleMatureBreederPopulationRecordMatrix = femaleMatureBreederPopulationRecordMatrix;
    noVaccineRecords.femaleOldPopulationRecordMatrix = femaleOldPopulationRecordMatrix;
    
    noVaccineRecords.maleJoeyPopulationRecordMatrix = maleJoeyPopulationRecordMatrix;
    noVaccineRecords.maleJuvenilePopulationRecordMatrix = maleJuvenilePopulationRecordMatrix;
    noVaccineRecords.maleYoungBreederPopulationRecordMatrix = maleYoungBreederPopulationRecordMatrix;
    noVaccineRecords.maleMatureBreederPopulationRecordMatrix = maleMatureBreederPopulationRecordMatrix;
    noVaccineRecords.maleOldPopulationRecordMatrix = maleOldPopulationRecordMatrix;
    
    noVaccineRecords.femaleJoeyInfectedRecordMatrix = femaleJoeyInfectedRecordMatrix;
    noVaccineRecords.femaleJuvenileInfectedRecordMatrix = femaleJuvenileInfectedRecordMatrix;
    noVaccineRecords.femaleYoungBreederInfectedRecordMatrix = femaleYoungBreederInfectedRecordMatrix;
    noVaccineRecords.femaleMatureBreederInfectedRecordMatrix = femaleMatureBreederInfectedRecordMatrix;
    noVaccineRecords.femaleOldInfectedRecordMatrix = femaleOldInfectedRecordMatrix;
    
    noVaccineRecords.maleJoeyInfectedRecordMatrix = maleJoeyInfectedRecordMatrix;
    noVaccineRecords.maleJuvenileInfectedRecordMatrix = maleJuvenileInfectedRecordMatrix;
    noVaccineRecords.maleYoungBreederInfectedRecordMatrix = maleYoungBreederInfectedRecordMatrix;
    noVaccineRecords.maleMatureBreederInfectedRecordMatrix = maleMatureBreederInfectedRecordMatrix;
    noVaccineRecords.maleOldInfectedRecordMatrix = maleOldInfectedRecordMatrix;
    
    noVaccineRecords.femaleJoeyDiseasedRecordMatrix = femaleJoeyDiseasedRecordMatrix;
    noVaccineRecords.femaleJuvenileDiseasedRecordMatrix = femaleJuvenileDiseasedRecordMatrix;
    noVaccineRecords.femaleYoungBreederDiseasedRecordMatrix = femaleYoungBreederDiseasedRecordMatrix;
    noVaccineRecords.femaleMatureBreederDiseasedRecordMatrix = femaleMatureBreederDiseasedRecordMatrix;
    noVaccineRecords.femaleOldDiseasedRecordMatrix = femaleOldDiseasedRecordMatrix;
    
    noVaccineRecords.maleJoeyDiseasedRecordMatrix = maleJoeyDiseasedRecordMatrix;
    noVaccineRecords.maleJuvenileDiseasedRecordMatrix = maleJuvenileDiseasedRecordMatrix;
    noVaccineRecords.maleYoungBreederDiseasedRecordMatrix = maleYoungBreederDiseasedRecordMatrix;
    noVaccineRecords.maleMatureBreederDiseasedRecordMatrix = maleMatureBreederDiseasedRecordMatrix;
    noVaccineRecords.maleOldDiseasedRecordMatrix = maleOldDiseasedRecordMatrix;
end

end


