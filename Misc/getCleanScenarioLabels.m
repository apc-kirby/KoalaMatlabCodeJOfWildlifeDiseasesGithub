function [cleanScenarioLabelsCell, cleanScenarioLabelsStruct] = getCleanScenarioLabels(scenarioLabels)

% [cleanScenarioLabelsCell, cleanScenarioLabelsStruct] = getCleanScenarioLabels(scenarioLabels)
% Returns versions of scenario labels that are suitable for use as struct
% field names.
%
% scenarioLabels: Intervention parameter names.
%
% cleanScenarioLabelsCell: Field-name-suitable intervention parameter
% names, in cell form.
% cleanScenarioLabelsStruct: Field-name-suitable intervention parameter
% names, in struct form.

cleanScenarioLabelsCell = cell(size(scenarioLabels));
for indVacParam = 1:length(scenarioLabels)
    cleanLabel = lower(regexprep(scenarioLabels{indVacParam}, '[ \-\(\)]', ''));
    cleanScenarioLabelsCell{indVacParam} = cleanLabel;
    cleanScenarioLabelsStruct.(cleanLabel) = NaN;
end