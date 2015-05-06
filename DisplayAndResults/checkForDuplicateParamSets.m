function duplicateParamNums = checkForDuplicateParamSets(records)

% duplicateParamNums = checkForDuplicateParamSets(records)
%
% Checks that no parameter sets have been simulated more than they should
% have been.
%
% records: Simulation results.
%
% duplicateParamNums: IDs of parameter sets that have been simulated more
% than they should have been.

nScenarios = length(unique(records.popRecordMatrix(:,1)));
theFieldnames = fieldnames(records);
duplicateParamNums = [];
for indField = 1:length(theFieldnames)
    theField = theFieldnames{indField};
    recordMatrix = records.(theField);
    paramNums = unique(recordMatrix(:,2));
    paramNumInstances = -99 + zeros(size(paramNums));
    for indParam = 1:length(paramNums)
        paramNumInstances(indParam) = sum(recordMatrix(:,2)==paramNums(indParam));
    end
    duplicateParamNumsByField.(theField) = paramNums(paramNumInstances > nScenarios);
    disp(['In ' theField ', the following param nums appeared more than ' num2str(nScenarios) ' times:'])
    disp(duplicateParamNumsByField.(theField)');
    duplicateParamNums = union(duplicateParamNums, duplicateParamNumsByField.(theField));
end
end