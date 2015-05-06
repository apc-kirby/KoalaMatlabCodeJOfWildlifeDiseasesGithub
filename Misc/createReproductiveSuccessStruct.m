function reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams)

% reproductiveSuccessStruct = createReproductiveSuccessStruct(baseParams)
% Generates a struct containing masses and corresponding male reproductive
% success weights.
%
% baseParams: Struct of the simulation 'metaparameters'.
%
% reproductiveSuccessStruct: Struct of masses and reproductive success weights.

allWeightToReprodSuccessWeight = importfile1(baseParams.weightToReprodSuccessWeightFile);
allWeightToReprodSuccessReprodSuccess = importfile1(baseParams.weightToReprodSuccessReprodSuccessFile);
% x and y ranges of imported curves may not cover the full range of koala
% weights, so add (0 kg,0) and (20 kg,[final relative prob]) to each curve. 
reproductiveSuccessStruct.allWeightToReprodSuccessWeight = ...
    [zeros(size(allWeightToReprodSuccessWeight,1),1) allWeightToReprodSuccessWeight(:,1)-0.1 allWeightToReprodSuccessWeight 20*ones(size(allWeightToReprodSuccessWeight,1),1)];
reproductiveSuccessStruct.allWeightToReprodSuccessReprodSuccess = ...
    [zeros(size(allWeightToReprodSuccessReprodSuccess,1),2) allWeightToReprodSuccessReprodSuccess allWeightToReprodSuccessReprodSuccess(:, end)];

[data, textdata] = importfile1(baseParams.weightTrackParamsFile);
reproductiveSuccessStruct.weightTrackParamB = data(1);
reproductiveSuccessStruct.weightTrackParamADistn = data(2:end);

end