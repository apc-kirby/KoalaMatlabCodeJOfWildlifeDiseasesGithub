function addPaths()

% addPaths
% Adds paths for the various subfolders containing the model code.

codeDir = pwd; % pwd should be '[...]/[code directory]/Launch'.
parentCodeDir = codeDir(1:(end-6)); % Get rid of 'Launch'.
addpath([parentCodeDir '\Setup'], [parentCodeDir '\RunSims'], [parentCodeDir '\Models'], [parentCodeDir '\Misc'], [parentCodeDir '\DisplayAndResults']);
end