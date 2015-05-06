function [paramsFieldNames,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,paramsWithoutRanges] = generateParamsStructBasics(fields,mins,maxes)

% [paramsFieldNames,minsInOrderOfFieldNames,maxesInOrderOfFieldNames,paramsWithoutRanges] = generateParamsStructBasics(fields,mins,maxes)
% Converts the parameter names, mins and maxes into more practical forms.
%
% fields: Parameter names.
% mins: Parameter minima.
% maxes: Parameter maxima.
%
% paramsFieldNames: Parameter names, reordered.
% minsInOrderOfFieldNames: Parameter minima, reordered.
% maxesInOrderOfFieldNames: Parameter maxima, reordered.
% paramsWithoutRanges: Names of parameters for which the minimum and
% maximum is equal.

filterParamsWithRanges = mins ~= maxes;
filterParamsWithoutRanges = ~filterParamsWithRanges;
minsWithoutRanges = mins(filterParamsWithoutRanges);
fieldsWithoutRanges = fields(filterParamsWithoutRanges);
for indFixedParam = 1:length(minsWithoutRanges)
    paramsWithoutRanges.(fieldsWithoutRanges{indFixedParam}) = minsWithoutRanges(indFixedParam);
end
paramsFieldNames = fields(filterParamsWithRanges);

minsInOrderOfFieldNames = mins(filterParamsWithRanges);
maxesInOrderOfFieldNames = maxes(filterParamsWithRanges);
end