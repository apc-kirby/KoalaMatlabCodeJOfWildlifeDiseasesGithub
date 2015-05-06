function koalaCoast = loadKoalaCoastPops(baseParams)

% koalaCoast = loadKoalaCoastPops(baseParams)
% Loads Koala Coast population data.
%
% baseParams: Model 'metaparameters'.
%
% koalaCoast: Koala Coast population data.

yearsAndPops = csvread([baseParams.resultsDir() baseParams.koalaCoastPopFile]);
koalaCoast.years = yearsAndPops(:,1);
koalaCoast.pops = yearsAndPops(:,2);
end



