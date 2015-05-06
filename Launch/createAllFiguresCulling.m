% createAllFiguresCulling
% Script that generates all the figures used in the paper, from the
% simulation results.

dbstop if error
resultsImgDir = '..\..\Manuscript (culling)\Journal of Wildlife Diseases\Figures and tables 09042015\';
resolutionStr = '-r600';
formatStr = '-dpng';
formatSuffixStr = '.png';
yearInQuestion = 15;
figureWidths = [8.9 12.0 13.6 18.3];
figureWidthIndexToUse = 2;

cullingResultsNum = 23;
baseParams = getBaseParamsAndSetPath();
[recordsVaccine_normalAll, scenarioParamsMatrix_normalAll, scenarioLabels_normal] = combineVaccineResults(baseParams.observedCurrentPop, cullingResultsNum);
[recordsVaccine_normal, scenarioParamsMatrix_normal] = ...
    dropExtraResults(recordsVaccine_normalAll, scenarioParamsMatrix_normalAll, scenarioLabels_normal, struct('numberofcapturesbymonth', [4 5]));
[recordsChosenParamsNoVaccine2000EndMonthsUneven, snapshotMonthsOfGoodParams] = getUsedNoVaccineResults(getBaseParamsForVisualisation(baseParams.observedCurrentPop, cullingResultsNum));
recordsChosenParamsNoVaccine2000 = adjustNoVaccineResultsSoEndIsSnapshotMonth(recordsChosenParamsNoVaccine2000EndMonthsUneven, snapshotMonthsOfGoodParams, 10);
koalaCoast = loadKoalaCoastPops(getBaseParamsForVisualisation(baseParams.observedCurrentPop, cullingResultsNum));

figWidth = 6;
figHeight = 4;
cullAndTreatID = cullingResultsNum*100000 + 6;
cullOnlyID = cullingResultsNum*100000 + 8;
treatOnlyID = cullingResultsNum*100000 + 7;
scenarioNumsToPlot = [cullAndTreatID cullOnlyID treatOnlyID];
scenarioNumsHalvedCaptureRate = scenarioNumsToPlot + 8;
scenarioNumsQuarteredCaptureRate = scenarioNumsToPlot + 16;
plotColors.vaccine(1).popColor = [77 175 74]/255;
plotColors.vaccine(2).popColor = [55 126 184]/255;
plotColors.vaccine(3).popColor = [152 78 163]/255;
plotColors.vaccine(4).popColor = [0.5 0.5 0.5];
plotColors.vaccine(5).popColor = [77 175 74]/255;
plotColors.vaccine(6).popColor = [55 126 184]/255;
plotColors.vaccine(7).popColor = [0.5 0.5 0.5];
subplotLetterXPop = 1985.5;
subplotLetterXPrev = 1989;
subplotLetterYPop = 7250;

scenarioNames = {'Cull or treat', 'Cull only', 'Treat only'};

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot, scenarioNames, 0, ...
    recordsChosenParamsNoVaccine2000, koalaCoast, 2014, 20, 20, 7000, 'pop', false, true, 'NorthEast', true, 'None', plotColors.vaccine, [], [], [])
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'Fig2popTimeCourses' );

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot, scenarioNames, 0, ...
    recordsChosenParamsNoVaccine2000, [], 2014, 20, 20, 60, 'prev', false, true, 'NorthEast', false, 'None', plotColors.vaccine, [], [], [])
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'Fig3prevTimeCourses');

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsHalvedCaptureRate, scenarioNames, 0, ...
    recordsChosenParamsNoVaccine2000, koalaCoast, 2014, 20, 20, 7000, 'pop', false, true, 'NorthEast', true, 'None', plotColors.vaccine, 'A', subplotLetterXPop, subplotLetterYPop)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'Fig4ApopTimeCoursesLowerCapture');

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsQuarteredCaptureRate, scenarioNames, 0, ...
    recordsChosenParamsNoVaccine2000, koalaCoast, 2014, 20, 20, 7000, 'pop', false, true, 'NorthEast', true, 'None', plotColors.vaccine, 'B', subplotLetterXPop, subplotLetterYPop)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'Fig4BpopTimeCoursesLowerCapture')

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot(1:2), scenarioNames(1:2), 0, ...
    recordsChosenParamsNoVaccine2000, koalaCoast, 2014, 20, 20, 7000, 'pop', false, true, 'NorthOutside', true, 'Lines', plotColors.vaccine(1:2), 'A', subplotLetterXPop, 9000)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'FigSupp2ApopTimeCoursesUncertainty')

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot(3), scenarioNames(3), 0, ...
    recordsChosenParamsNoVaccine2000, koalaCoast, 2014, 20, 20, 7000, 'pop', false, true, 'NorthOutside', true, 'Lines', plotColors.vaccine(3), 'B', subplotLetterXPop, 8400)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'FigSupp2BpopTimeCoursesUncertainty')

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot(1:2), scenarioNames(1:2), 0, ...
    recordsChosenParamsNoVaccine2000, [], 2014, 20, 20, 60, 'prev', false, true, 'NorthOutside', false, 'Lines', plotColors.vaccine(1:2), 'A', subplotLetterXPrev, 72)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'FigSupp3AprevTimeCoursesUncertainty');

createExampleTimeCoursesCulling(getBaseParamsForVisualisation(baseParams.observedCurrentPop,cullingResultsNum), recordsVaccine_normal, scenarioNumsToPlot(3), scenarioNames(3), 0, ...
    recordsChosenParamsNoVaccine2000, [], 2014, 20, 20, 60, 'prev', false, true, 'NorthOutside', false, 'Lines', plotColors.vaccine(3), 'B', subplotLetterXPrev, 68)
saveFigure([0 0 figureWidths(figureWidthIndexToUse) figureWidths(figureWidthIndexToUse)], resultsImgDir, 'FigSupp3BprevTimeCoursesUncertainty')

createAgeSchematic()
saveFigure([0 0 20 14], resultsImgDir, 'FigSupp1ageSchematic');

displayUsedParamRanges(recordsVaccine_normalAll)

reportSummaryStatistics(recordsVaccine_normal, cullAndTreatID, treatOnlyID)
