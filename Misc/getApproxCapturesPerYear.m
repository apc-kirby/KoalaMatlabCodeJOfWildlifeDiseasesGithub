function approxCapturesPerYear = getApproxCapturesPerYear(vaccineFn)

% approxCapturesPerYear = getApproxCapturesPerYear(vaccineFn)
% Determines the approximate number of koalas that would be captured each
% year under the intervention.
%
% vaccineFn: Function used to setup intervention parameters.
%
% approxCapturesPerYear: Approximate captures per year.

vaccineParams = vaccineFn();
nCaptures = length(vaccineParams.numberOfCapturesByMonth);
approxCapturesPerYear = -1 + zeros(1, nCaptures);
for indScenario = 1:nCaptures
   approxCapturesPerYear(indScenario) = 12 * mean(vaccineParams.numberOfCapturesByMonth{indScenario});
end
end