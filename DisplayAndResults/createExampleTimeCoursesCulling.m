function createExampleTimeCoursesCulling(baseParams, recordsVaccine, vaccineNumbers, scenarioNames, noVaccineNumber, ...
    recordsNoVaccine, actualData, zeroYearOfActualData, yearsOfFuture, yearsOfPast, yAxisMax, popOrPrev, isShowInf, ...
    isShowYear, legendLocation, isBackProject, rangeOption, tempPlotColors, subplotLetter, subplotLetterX, subplotLetterY)

% createExampleTimeCoursesCulling(baseParams, recordsVaccine, vaccineNumbers, scenarioNames, noVaccineNumber, ...
%    recordsNoVaccine, actualData, zeroYearOfActualData, yearsOfFuture, yearsOfPast, yAxisMax, popOrPrev, isShowInf, ...
%    isShowYear, legendLocation, isBackProject, rangeOption, tempPlotColors, subplotLetter, subplotLetterX, subplotLetterY)
% Plots intervention time courses.
%
% baseParams: Model 'metaparameters'.
% recordsVaccine: Intervention results.
% vaccineNumbers: IDs of interventions to plot.
% scenarioNames: Intervention names, for use in legend.
% noVaccineNumber: ID of 'no intervention'.
% recordsNoVaccine: 'No intervention' results.
% actualData: Population data (as opposed to model results).
% zeroYearOfActualData: Real-world year considered to be 'year zero' in the
% model.
% yearsOfFuture: Number of years of future to display.
% yearsOfPast: Number of years of past to display.
% yAxisMax: Maximum of Y axis.
% popOrPrev: Whether to plot population sizes or prevalence levels. Options
% are 'pop' or 'prev'.
% isShowInf: Flag indicating whether to show the numbers of infected koalas. 
% isShowYear: Flag indicating whether to show the real-world year on the X
% axis.
% legendLocation: Legend location.
% isBackProject: Flag indicating whether to display back-projected
% populations.
% rangeOption: Specifies how ranges are to be displayed. Options are 'UseConfi', 'Lines', 'None'.
% tempPlotColors: Colours to be used for the interventions.
% subplotLetter: Letter to indicate subfigure.
% subplotLetterX: X coordinate of subplot letter.
% subplotLetterY: Y coordinate of subplot letter.

% rangeOption 
plotColors.vaccine = tempPlotColors;
plotColors.vaccine(1).popLineStyle = '-';
plotColors.vaccine(2).popLineStyle = '-';
plotColors.vaccine(3).popLineStyle = '-';
plotColors.vaccine(4).popLineStyle = '-';
plotColors.vaccine(5).popLineStyle = '--';
plotColors.vaccine(6).popLineStyle = '--';
plotColors.vaccine(7).popLineStyle = '--';
for indPlotColorsVaccine = 1:length(plotColors.vaccine)
    plotColors.vaccine(indPlotColorsVaccine).infColor = plotColors.vaccine(indPlotColorsVaccine).popColor;
    plotColors.vaccine(indPlotColorsVaccine).vacColor = [0 1 0];
    plotColors.vaccine(indPlotColorsVaccine).disColor = plotColors.vaccine(indPlotColorsVaccine).popColor;
    plotColors.vaccine(indPlotColorsVaccine).disLineStyle = '-';
    plotColors.vaccine(indPlotColorsVaccine).infLineStyle = '-';
    plotColors.vaccine(indPlotColorsVaccine).lineWidth = 1;
end

plotColors.noVac.popColor = [228 26 28]/255;
plotColors.noVac.infColor = [1 0 0];
plotColors.noVac.popLineStyle = '-';
plotColors.noVac.infLineStyle = '-';
plotColors.noVac.lineWidth = 1;
plotColors.noVac.disColor = plotColors.noVac.popColor;
plotColors.noVac.disLineStyle = '-';

plotColors.data.lineWidth = 1;

isShowDisease = false;
plotParams = [];

clf
legendHandles = [];
legendText = [];

for indVaccine = 1:length(vaccineNumbers)
    if length(scenarioNames) == length(vaccineNumbers)
        thisScenarioName = scenarioNames{indVaccine};
    else
        thisScenarioName = ['Culling scenario ' num2str(vaccineNumbers(indVaccine))]
    end
    [legendHandles, legendText] = plotOneTimeCourse(legendHandles, legendText, baseParams, recordsVaccine, vaccineNumbers(indVaccine), yAxisMax, ...
        plotColors.vaccine(indVaccine), isShowInf, isShowDisease, ...
        rangeOption, yearsOfFuture, thisScenarioName, recordsNoVaccine, ...
        0, zeroYearOfActualData, false, popOrPrev, isShowYear, legendLocation, plotParams);
    hold on
end
[legendHandles, legendText, hNoInfectionPop] = plotOneTimeCourse(legendHandles, legendText, baseParams, recordsVaccine, noVaccineNumber, yAxisMax, plotColors.noVac, isShowInf, isShowDisease, ...
    rangeOption, yearsOfFuture, 'No intervention', recordsNoVaccine, ...
    yearsOfPast, zeroYearOfActualData, false, popOrPrev, isShowYear, legendLocation, plotParams);
uistack(hNoInfectionPop, 'bottom')
if isBackProject
    plotBackProjection(yearsOfPast, recordsNoVaccine, isShowYear, zeroYearOfActualData, plotColors.noVac, 'spline');
end
if ~isempty(actualData)
    if isShowYear
        actualYearToAddIfNecessary = zeroYearOfActualData;
    else
        actualYearToAddIfNecessary = 0;
    end
    [legendHandles, legendText] = plotDataTimeCourse(actualData, zeroYearOfActualData, actualYearToAddIfNecessary, legendHandles, legendText, legendLocation, plotColors.data);
end
% disp(['Reversal year of scenario ' num2str(successfulVaccineNumber) ' is ' num2str(getReversalTimeForOneScenario(recordsVaccine,successfulVaccineNumber, 50)/12) '.'])
if ~isempty(subplotLetter)
    text(subplotLetterX, subplotLetterY, subplotLetter, 'FontSize', 36)
end;
end