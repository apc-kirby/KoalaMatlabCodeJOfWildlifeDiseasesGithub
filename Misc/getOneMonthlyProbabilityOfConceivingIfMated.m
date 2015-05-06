function monthlyProbabilityOfConceivingIfMated = getOneMonthlyProbabilityOfConceivingIfMated(params)

% monthlyProbabilityOfConceivingIfMated = getOneMonthlyProbabilityOfConceivingIfMated(params)
% Generates a vector of probabilities of conceiving if a mating event
% occurs, with one probability for each month.
% 
% params: Model parameters.
%
% monthlyProbabilityOfConceivingIfMated: Vector of probabilities of
% conceiving if a mating event occurs, with one probability for each month.

birthMonthPercentsNonNormalised = [18	14	15	9	6	4	2	2	1	3	9	16]; %Southeast Queensland
birthMonthPercentsNormalised = birthMonthPercentsNonNormalised / sum(birthMonthPercentsNonNormalised);
monthlyProbabilityOfConceivingIfMated = params.monthlyProbInBreedingSeasonOfMatingProducingYoung/max(birthMonthPercentsNormalised) * birthMonthPercentsNormalised([2:12 1]);

end