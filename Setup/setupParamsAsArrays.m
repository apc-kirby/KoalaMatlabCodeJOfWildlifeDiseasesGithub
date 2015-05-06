function [fields,mins,maxes] = setupParamsAsArrays(data,textdata)

% [fields,mins,maxes] = setupParamsAsArrays(data,textdata)
% Uses the data from parameter table file to generate parameter variables
% and their values.
%
% data: Numerical data from the parameter table file.
% textdata: Text data from the parameter table file.
%
% fields: Parameter names.
% mins: Parameter minima.
% maxes: Parameter maxima.

numberOfParamsWithRanges = 0;
numberOfParamsWithNoRange = 0;
currentEntry = 0;
for p = 3:size(textdata,1)
    if ~isempty(textdata{p,1}) && isletter(textdata{p,1}(1))
%         try
            currentEntry = currentEntry + 1;
            fields{currentEntry} = textdata{p,1};
            mins(currentEntry) = data(p-2,1);
            maxes(currentEntry) = data(p-2,2);
            if mins(currentEntry) == maxes(currentEntry)
                numberOfParamsWithNoRange = numberOfParamsWithNoRange + 1;
            else
                numberOfParamsWithRanges = numberOfParamsWithRanges + 1;
            end
%         catch err
%         end
    end
end

end