function paramsWithoutRanges = getParamsWithoutRanges(fields,mins,maxes)

% paramsWithoutRanges = getParamsWithoutRanges(fields,mins,maxes)
% Returns the names and values of parameters without a range (i.e., for
% which the minimum and the maximum are the same).
%
% fields: Parameter names.
% mins: Parameter minima.
% maxes: Parameter maxima.
%
% paramsWithoutRanges: Struct of names and values of parameters without a
% range.

filterParamsWithRanges = mins ~= maxes;
filterParamsWithoutRanges = ~filterParamsWithRanges;
minsWithoutRanges = mins(filterParamsWithoutRanges);
fieldsWithoutRanges = fields(filterParamsWithoutRanges);
for indFixedParam = 1:length(minsWithoutRanges)
    paramsWithoutRanges.(fieldsWithoutRanges{indFixedParam}) = minsWithoutRanges(indFixedParam);
end

end