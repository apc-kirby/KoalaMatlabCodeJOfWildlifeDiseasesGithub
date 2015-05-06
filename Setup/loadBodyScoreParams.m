function bodyScoreParams = loadBodyScoreParams(baseParams)

% bodyScoreParams = loadBodyScoreParams(baseParams)
% Loads body score parameters from file.
%
% baseParams: Struct of simulation 'metaparameters'.
%
% bodyScoreParams: Struct of body score parameter names and values.

    [data, textdata] = importfile1(baseParams.bodyScoreParamsFile);
    for ind = 1:length(data)
       bodyScoreParams.(textdata{ind}) = data(ind); 
    end
end