function reportSummaryStatistics(recordsVaccine_normal, bestScenarioID, treatmentOnlyScenarioID)

% reportSummaryStatistics(recordsVaccine_normal, bestScenarioID, treatmentOnlyScenarioID)
% Reports some summary statistics for use in the manuscript text.
%
% recordsVaccine_normal: Intervention records.
% bestScenarioID: ID of the 'best' intervention.
% treatmentOnlyScenarioID: ID of the treat only intervention.

noInterventionID = 0;

baseParams = getBaseParamsAndSetPath();

disp('Loading pre-run good params indexes...')
% Import pre-determined goodParamsIndexes
load([getResultsDir() baseParams.chosenParamsIndexesForVaccineFile '.mat']); % Variable is chosenGoodParamsIndexes
allGoodParamsIndexes = chosenGoodParamsIndexes;
disp(['Loaded ' num2str(length(allGoodParamsIndexes)) ' pre-run good params indexes.']);
goodParamsIndexes = allGoodParamsIndexes;

popRecordMatrix = recordsVaccine_normal.popRecordMatrix;
infRecordMatrix = recordsVaccine_normal.infRecordMatrix;
% Output some vaccine scenario summary statistics.
lastRecordedMonth = size(popRecordMatrix, 2) - 1;
scenarioIDs = unique(popRecordMatrix(:,1));
nSimsPopulationWentExtinct = [scenarioIDs nan(length(scenarioIDs),1)];
minPopAtEnd = [scenarioIDs nan(length(scenarioIDs),1)];
for indScenario = 1:length(scenarioIDs);
    theScenarioID = scenarioIDs(indScenario);
    nSimsPopulationWentExtinct(indScenario, 2) = sum(popRecordMatrix(popRecordMatrix(:,1)==theScenarioID, lastRecordedMonth) == 0);
    minPopAtEnd(indScenario, 2) = min(popRecordMatrix(popRecordMatrix(:,1)==theScenarioID,lastRecordedMonth));
end
infGoesToZeroMonthForBestScenario = nan(length(goodParamsIndexes),1);
monthBestScenarioPopOvertakesTreatmentOnlyPop = nan(length(goodParamsIndexes),1);
monthBestScenarioPopOvertakesNoInterventionPop = nan(length(goodParamsIndexes),1);
for indSim = 1:length(goodParamsIndexes);
    theParamsIndex = goodParamsIndexes(indSim);
    infGoesToZeroMonthForBestScenario(indSim) = find( ...
        infRecordMatrix(infRecordMatrix(:,1)==bestScenarioID & infRecordMatrix(:,2)==theParamsIndex,3:end) == 0, ...
        1, 'first');
    theMonthBestScenarioOvertakesTreatmentOnlyPop = find( ...
        popRecordMatrix(popRecordMatrix(:,1)==bestScenarioID & popRecordMatrix(:,2)==theParamsIndex,3:end) > popRecordMatrix(popRecordMatrix(:,1)==treatmentOnlyScenarioID & popRecordMatrix(:,2)==theParamsIndex,3:end), ...
        1, 'first');
    if ~isnan(theMonthBestScenarioOvertakesTreatmentOnlyPop)
        monthBestScenarioPopOvertakesTreatmentOnlyPop(indSim) = ...
            theMonthBestScenarioOvertakesTreatmentOnlyPop;
    end
    theMonthBestScenarioOvertakesNoInterventionPop = find( ...
        popRecordMatrix(popRecordMatrix(:,1)==bestScenarioID & popRecordMatrix(:,2)==theParamsIndex,3:end) > popRecordMatrix(popRecordMatrix(:,1)==noInterventionID & popRecordMatrix(:,2)==theParamsIndex,3:end), ...
        1, 'first');
    if ~isnan(theMonthBestScenarioOvertakesNoInterventionPop)
        monthBestScenarioPopOvertakesNoInterventionPop(indSim) = ...
            theMonthBestScenarioOvertakesNoInterventionPop;
    end
end
disp(['Smallest month in which there are zero infected koalas for best scenario (ID ' num2str(bestScenarioID) ') is ' num2str(min(infGoesToZeroMonthForBestScenario)) ' (year ' num2str(min(infGoesToZeroMonthForBestScenario)/12) ').'])
disp(['Largest month in which there are zero infected koalas for best scenario (ID ' num2str(bestScenarioID) ') is ' num2str(max(infGoesToZeroMonthForBestScenario)) ' (year ' num2str(max(infGoesToZeroMonthForBestScenario)/12) ').'])
disp(['Smallest month in which best scenario (ID ' num2str(bestScenarioID) ') has more koalas than treatment-only scenario is ' num2str(min(monthBestScenarioPopOvertakesTreatmentOnlyPop)) ' (year ' num2str(min(monthBestScenarioPopOvertakesTreatmentOnlyPop)/12) ').'])
disp(['Largest month in which best scenario (ID ' num2str(bestScenarioID) ') has more koalas than treatment-only scenario is ' num2str(max(monthBestScenarioPopOvertakesTreatmentOnlyPop)) ' (year ' num2str(max(monthBestScenarioPopOvertakesTreatmentOnlyPop)/12) ').'])
disp(['Smallest month in which best scenario (ID ' num2str(bestScenarioID) ') has more koalas than no-intervention scenario is ' num2str(min(monthBestScenarioPopOvertakesNoInterventionPop)) ' (year ' num2str(min(monthBestScenarioPopOvertakesNoInterventionPop)/12) ').'])
disp(['Largest month in which best scenario (ID ' num2str(bestScenarioID) ') has more koalas than no-intervention scenario is ' num2str(max(monthBestScenarioPopOvertakesNoInterventionPop)) ' (year ' num2str(max(monthBestScenarioPopOvertakesNoInterventionPop)/12) ').'])

end