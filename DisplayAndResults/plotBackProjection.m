function plotBackProjection(yearsOfPast, recordsNoVaccinePast, isShowYear, zeroYearOfActualData, plotColours, fnType)

% plotBackProjection(yearsOfPast, recordsNoVaccinePast, isShowYear, zeroYearOfActualData, plotColours, fnType)
% Plots a back projection using a specified functional form.
%
% yearsOfPast: Number of years into past to project and plot.
% recordsNoVaccinePast: 'No intervention' results for past.
% isShowYear: Flag indicating whether to show year or not.
% zeroYearOfActualData: Real-world year considered to be 'year zero' in the
% model.
% plotColours: Format of line to plot.
% fnType: Functional form used to calculate back projected values.

if isShowYear
    actualYearToAddIfNecessary = zeroYearOfActualData;
else
    actualYearToAddIfNecessary = 0;
end

yearsOfSimulatedPast = min(yearsOfPast, size(recordsNoVaccinePast.popRecordMatrix(:,3:end), 2)/12);
firstMonthOfSimulatedPast = -yearsOfSimulatedPast * 12 + 1;
lastMonthOfSimulatedPast = 0;
firstMonthOfBackProjection = -yearsOfPast * 12;
lastMonthOfBackProjection = firstMonthOfSimulatedPast;

popRecordMatrixPast = recordsNoVaccinePast.popRecordMatrix(:, (end - yearsOfSimulatedPast*12 + 1):end);
medianPrctiles = prctile(popRecordMatrixPast, 50);
popDecayRate = 1 / (length(medianPrctiles)-1) * log(medianPrctiles(end) / medianPrctiles(1));
exponentialBackProjectionFn = @(t) medianPrctiles(1) * exp(popDecayRate * (t - firstMonthOfSimulatedPast));

if strcmp('exponential', fnType)
    backProjectionFn = exponentialBackProjectionFn;
elseif strcmp('spline', fnType)
    yValAtFirstMonthOfBackProjection = 7000;
    yValAtLastMonthOfBackProjection = exponentialBackProjectionFn(lastMonthOfBackProjection);
    slopeAtFirstMonthOfBackProjection = 0;
    slopeAtLastMonthOfBackProjection = popDecayRate * exponentialBackProjectionFn(lastMonthOfBackProjection); % This is the derivative of the exponential back projection fn.
    deltaMonths = 5;
    yValForSpline0 = yValAtFirstMonthOfBackProjection - slopeAtFirstMonthOfBackProjection * deltaMonths;
    yValForSpline1 = yValAtLastMonthOfBackProjection + slopeAtLastMonthOfBackProjection * deltaMonths;
    backProjectionFn = @(t) spline( ...
        [firstMonthOfBackProjection-deltaMonths firstMonthOfBackProjection lastMonthOfBackProjection lastMonthOfBackProjection+deltaMonths], ...
        [yValForSpline0 yValAtFirstMonthOfBackProjection yValAtLastMonthOfBackProjection yValForSpline1], ...
        t);
end
yValsForBackProjection = backProjectionFn(firstMonthOfBackProjection:lastMonthOfBackProjection); % Here, month zero is the first month of simulated past.
disp(['At ' num2str(yearsOfPast) ' years in the past, back-projected number of koalas is ' num2str(backProjectionFn(firstMonthOfBackProjection)) '.'])
disp(['At ' num2str(-lastMonthOfBackProjection/12) ' years in the past, back-projected number of koalas is ' num2str(backProjectionFn(lastMonthOfBackProjection)) '.'])
plot((firstMonthOfBackProjection:lastMonthOfBackProjection)/12 + actualYearToAddIfNecessary, yValsForBackProjection, ...
    'Color', plotColours.popColor, 'LineStyle', plotColours.popLineStyle, 'LineWidth', plotColours.lineWidth); hold on

end