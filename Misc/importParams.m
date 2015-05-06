function paramsStruct = importParams(paramSetsFile, paramsFieldNamesFile)

% paramsStruct = importParams(paramSetsFile, paramsFieldNamesFile)
% Imports parameter sets and attaches parameter names.
%
% paramSetsFile: Name of file with parameter sets.
% paramsFieldNamesFile: Name of file with parameter names.
%
% paramStruct: Struct with parameter sets and names.

    [~, paramsStruct.paramsFieldNames] = importfile1(paramsFieldNamesFile);
    paramsStruct.paramsMatrix = csvreadFromResultsDir(paramSetsFile);
end