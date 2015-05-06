function [cumulativeFemaleProbOfDyingBeforeThisYear,cumulativeMaleProbOfDyingBeforeThisYear] = getLifespanProbabilitiesMonthly(params, paramInd)

% [cumulativeFemaleProbOfDyingBeforeThisYear,cumulativeMaleProbOfDyingBeforeThisYear] = getLifespanProbabilitiesMonthly(params, paramInd)
% Set up vector of mortalities for each month
% (i.e. probablity of dying in that month having lived through previous month).
%
% params: Parameter sets.
% paramInd: The index of the particular parameter set to use.
%
% cumulativeFemaleProbOfDyingBeforeThisYear: Cumulative probabilities of
% dying before each year, for females.
% cumulativeMaleProbOfDyingBeforeThisYear: Cumulative probabilities of
% dying before each year, for males.

maxAge = params.maxAge;

% maleMortalityThisYear has one element per (potential) month of life, but
% there is no chance of dying while in pouch (that probability is built into conception probability), 
% so zero first few elements.
maleMortalityThisYear = zeros(toMonths(maxAge),1);
maleMortalityThisYear(   (toMonths(params.pouchEmergeAge)+1):toMonths(params.juvenileAge)   ) = ...
    getMonthlyMortalityFromTotalMortality(1-params.dependentSurvivorship, toMonths(params.juvenileAge) - (toMonths(params.pouchEmergeAge)) );
maleMortalityThisYear(   (toMonths(params.juvenileAge)+1):toMonths(params.maleAdultAge)    ) = getMonthlyMortalityFromAnnualMortality(1-params.maleJuvenileSurvivorship);
maleMortalityThisYear(   (toMonths(params.maleAdultAge)+1):toMonths(params.maleOldAge)   ) = getMonthlyMortalityFromAnnualMortality(1-params.adultSurvivorship);
maleMortalityThisYear(   (toMonths(params.maleOldAge)+1):end   ) = getMonthlyMortalityFromAnnualMortality(1-params.oldSurvivorship);

% Set up vector of probabilities of living to and dying on that year
maleProbOfDyingBeforeThisYear = zeros(size(maleMortalityThisYear));
for ind=1:length(maleProbOfDyingBeforeThisYear)
    maleProbOfDyingBeforeThisYear(ind) = maleMortalityThisYear(ind) * prod(1 - maleMortalityThisYear(1:(ind-1)));
end
cumulativeMaleProbOfDyingBeforeThisYear = cumsum(maleProbOfDyingBeforeThisYear);
cumulativeMaleProbOfDyingBeforeThisYear(end) = 1;

femaleMortalityThisYear = zeros(toMonths(maxAge),1);
femaleMortalityThisYear(   (toMonths(params.pouchEmergeAge)+1):toMonths(params.juvenileAge)   ) = ...
    getMonthlyMortalityFromTotalMortality(1-params.dependentSurvivorship, toMonths(params.juvenileAge) - (toMonths(params.pouchEmergeAge)) );
femaleMortalityThisYear(   (toMonths(params.juvenileAge)+1):toMonths(params.femaleAdultAge)    ) = getMonthlyMortalityFromAnnualMortality(1-params.femaleJuvenileSurvivorship);
femaleMortalityThisYear(   (toMonths(params.femaleAdultAge)+1):toMonths(params.femaleOldAge)   ) = getMonthlyMortalityFromAnnualMortality(1-params.adultSurvivorship);
femaleMortalityThisYear(   (toMonths(params.femaleOldAge)+1):end   ) = getMonthlyMortalityFromAnnualMortality(1-params.oldSurvivorship);

% Set up vector of probabilities of living to and dying on that year
femaleProbOfDyingBeforeThisYear = zeros(size(femaleMortalityThisYear));
for ind=1:length(femaleProbOfDyingBeforeThisYear)
    femaleProbOfDyingBeforeThisYear(ind) = femaleMortalityThisYear(ind) * prod(1 - femaleMortalityThisYear(1:(ind-1)));
end
cumulativeFemaleProbOfDyingBeforeThisYear = cumsum(femaleProbOfDyingBeforeThisYear);
cumulativeFemaleProbOfDyingBeforeThisYear(end) = 1;

    function monthlyMortality = getMonthlyMortalityFromAnnualMortality(annualMortality) 
       monthlyMortality = 1 - (1 - annualMortality)^(1/12);
    end

    function monthlyMortality = getMonthlyMortalityFromTotalMortality(annualMortality, numberOfMonths) 
       monthlyMortality = 1 - (1 - annualMortality)^(1/numberOfMonths);
    end

    function months = toMonths(years)
        months = floor(years * 12);
    end

end