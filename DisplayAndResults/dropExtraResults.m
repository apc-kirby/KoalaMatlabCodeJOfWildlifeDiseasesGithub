function [recordsVaccine, scenarioParamsMatrix] = dropExtraResults(recordsVaccine, scenarioParamsMatrix, scenarioLabels, dropStruct)

% [recordsVaccine, scenarioParamsMatrix] = dropExtraResults(recordsVaccine, scenarioParamsMatrix, scenarioLabels, dropStruct)
% Return intervention results with results for specified intervention
% scenarios discarded.
%
% recordsVaccine: Intervention scenario results.
% scenarioParamsMatrix: Intervention parameters, in matrix form.
% scenarioLabels: Intervention parameter names.
% dropStruct: Struct indicatating the intervention parameter names and
% values that should be discarded.
%
% recordsVaccine: Trimmed intervention results.
% scenarioParamsMatrix: Trimmed scenario parameters, in matrix form.

filterToDrop = true(size(scenarioParamsMatrix, 1), 1);
[cleanScenarioLabelsCells, ~] = getCleanScenarioLabels(scenarioLabels);

theFieldnames = fieldnames(dropStruct);
for indField = 1:length(theFieldnames)
    theField = theFieldnames{indField};
    theFieldCol = strcmp(lower(theField), cleanScenarioLabelsCells);
    filterToDrop = filterToDrop & ismember(scenarioParamsMatrix(:, theFieldCol), dropStruct.(theField));
end
scenarioNumsToDrop = scenarioParamsMatrix(filterToDrop, 1);
disp(['Dropping ' num2str(length(scenarioNumsToDrop)) ' scenarios...'])
scenarioParamsMatrix(filterToDrop,:) = [];
recordFieldnames = fieldnames(recordsVaccine);
for indField = 1:length(recordFieldnames)
   tempRecord = recordsVaccine.(recordFieldnames{indField});
   tempRecord(ismember(tempRecord(:,1), scenarioNumsToDrop),:) = [];
   recordsVaccine.(recordFieldnames{indField}) = tempRecord;
end
disp([num2str(size(scenarioParamsMatrix,1)) ' scenarios remain.'])
end