function data = csvreadFromResultsDir(fileName)

% data = csvreadFromResultsDir(fileName)
% Reads a file from the results directory.
%
% fileName: File name.
%
% data: Data from the file.

    data = csvread([getResultsDir() fileName]);
end