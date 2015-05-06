function bodyScoreParams = setupBodyScoreParams(data,textdata)

% bodyScoreParams = setupBodyScoreParams(data,textdata)
% Creates a struct of the body score parameter names and their values.
% 
% data: Numerical data for body score parameters.
% textdata: Text data for body score parameters.
%
% bodyScoreParams: Struct of the body score parameter names and their
% values.

    for ind = 1:length(data)
        bodyScoreParams.(textdata{ind,1}) = data(ind);
    end


end