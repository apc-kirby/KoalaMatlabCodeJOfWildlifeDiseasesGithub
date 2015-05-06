function paramIndex = getParamIndices(fields)

% paramIndex = getParamIndices(fields)
% Creates a struct that gives the index of the field.
% 
% field: Parameter names.
%
% paramIndex: Struct with fields that are the parameter names and values
% that are the indices of those parameter names.

    for ind = 1:length(fields)
            paramIndex.(fields{ind}) = ind;
    end
        
end