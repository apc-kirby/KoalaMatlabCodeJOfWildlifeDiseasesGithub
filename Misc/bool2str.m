function string = bool2str(bool)

% string = bool2str(bool)
% Returns a meaningful string representation of a boolean variable.
%
% bool: Boolean variable.
%
% string: String representation of bool.

if bool
    string = 'true';
else
    if ~bool
        string = 'false';
    end
end
end