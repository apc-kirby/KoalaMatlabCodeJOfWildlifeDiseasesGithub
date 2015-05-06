function [legendHandles, legendText, hVacPop] = plotOneTimeCourse(oldLegendHandles, legendText, baseParams, recordsVaccine, ...
    vaccineNumber, yAxisMax, plotColors, isShowInf, isShowDisease, rangeOption, yearsToShow, legendPrefixes, ...
    recordsNoVaccinePast, yearsOfPast, zeroYearOfActualData, isPlotSmoothedTimeCourse, popOrPrev, ...
    isShowYear, legendLocation, plotParams)

% [legendHandles, legendText, hVacPop] = plotOneTimeCourse(oldLegendHandles, legendText, baseParams, recordsVaccine, ...
%    vaccineNumber, yAxisMax, plotColors, isShowInf, isShowDisease, rangeOption, yearsToShow, legendPrefixes, ...
%    recordsNoVaccinePast, yearsOfPast, zeroYearOfActualData, isPlotSmoothedTimeCourse, popOrPrev, ...
%    isShowYear, legendLocation, plotParams)
% Plots the time course for one single interventions.
%
% oldLegendHandles: Legend handles, to which a new one will be added.
% legendText: Text to appear in legend.
% baseParams: Model 'metaparameters'.
% recordsVaccine: Intervention results.
% vaccineNumber: ID of intervention to plot.
% yAxisMax: Maximum of Y axis.
% plotColors: Format of line to plot.
% isShowInf: Flag indicating whether to show the numbers of infected koalas.  
% isShowDisease: Flag indicating whether to show the numbers of diseased koalas.  
% rangeOption: Specifies how ranges are to be displayed. Options are 'UseConfi', 'Lines', 'None'.
% yearsToShow: 
% legendPrefixes: Prefix to be added to legend text.
% recordsNoVaccinePast: 'No intervention' results for past.
% yearsOfPast: Number of years of past to display.
% zeroYearOfActualData: Real-world year considered to be 'year zero' in the
% model.
% isPlotSmoothedTimeCourse: Flag indicating whether to plot smoothed or
% actual time courses.
% popOrPrev: Whether to plot population sizes or prevalence levels. Options
% are 'pop' or 'prev'.
% isShowYear: Flag indicating whether to show the real-world year on the X
% axis.
% legendLocation: Legend location.
% plotParams: Struct of general parameters to use for plotting.
%
% legendHandles: Legend handles updated for plot made in this function.
% legendText: Legend text updated with for plot made in this function.
% hVacPop: Handle of plot made in this function.

if ~any(strcmp({'pop','prev','incidence','incidencePerKoala','disease'}, popOrPrev))
    error('Argument popOrPrev must have value pop, prev, incidence, incidencePerKoala or disease.')
end
if strcmp('UseConfi',rangeOption)
    isUseConfi = true;
    isUsePercentileLines = true;
else
    if strcmp('Lines',rangeOption)
        isUseConfi = false;
        isUsePercentileLines = true;
    else
        if strcmp('None',rangeOption)
            isUseConfi = false;
            isUsePercentileLines = false;
        else
            error(['Unknown rangeOption: "' rangeOption '".'])
        end
    end
end

if isShowYear
    actualYearToAddIfNecessary = zeroYearOfActualData;
else
    actualYearToAddIfNecessary = 0;
end
flagProbablyExceededMaxPop = false;

areaEdgeColor = 'none';
numOfLeadingElementsToIgnore = 2;
whichQuantiles = [5 50 95];

if ~isempty(recordsNoVaccinePast)
    yearZeroPop = recordsNoVaccinePast.popRecordMatrix(:,end);
    yearZeroInf = recordsNoVaccinePast.infRecordMatrix(:,end);
    yearZeroDis = recordsNoVaccinePast.diseasedRecordMatrix(:,end);
    yearZeroPrev = 100 * double(recordsNoVaccinePast.infRecordMatrix(:,end)) ./ recordsNoVaccinePast.popRecordMatrix(:,end);
    yearZeroIncidence = recordsNoVaccinePast.incidenceRecordMatrix(:,end);
    yearZeroDiseasePrev = 100 * double(recordsNoVaccinePast.diseasedRecordMatrix(:,end)) ./ recordsNoVaccinePast.popRecordMatrix(:,end);
    if strcmp('pop', popOrPrev)
        yearZeroPlotVal = yearZeroPop;
    elseif strcmp('prev', popOrPrev)
        yearZeroPlotVal = yearZeroPrev;
    elseif strcmp('incidence', popOrPrev)
        yearZeroPlotVal = yearZeroIncidence;
    elseif strcmp('incidencePerKoala', popOrPrev);
        yearZeroPlotVal = double(yearZeroIncidence) ./ double(yearZeroPop);
    elseif strcmp('disease', popOrPrev);
        yearZeroPlotVal = yearZeroDiseasePrev;
    end
    yearsOfSimulatedPast = min(yearsOfPast, size(recordsNoVaccinePast.popRecordMatrix(:,3:end), 2)/12);
    popRecordMatrixPast = recordsNoVaccinePast.popRecordMatrix(:, (end - yearsOfSimulatedPast*12 + 1):end);
    infRecordMatrixPast = recordsNoVaccinePast.infRecordMatrix(:, (end - yearsOfSimulatedPast*12 + 1):end);
    diseasedRecordMatrixPast = recordsNoVaccinePast.diseasedRecordMatrix(:, (end - yearsOfSimulatedPast*12 + 1):end);
    incidenceRecordMatrixPast = recordsNoVaccinePast.incidenceRecordMatrix(:, (end - yearsOfSimulatedPast*12 + 1):end);
    incidencePerKoalaRecordMatrixPast = double(incidenceRecordMatrixPast) ./ double(popRecordMatrixPast);
    prevRecordMatrixPast = 100 * double(infRecordMatrixPast) ./ double(popRecordMatrixPast);
    diseasedPrevRecordMatrixPast = 100 * double(diseasedRecordMatrixPast) ./ double(popRecordMatrixPast);
    noVaccinePastMonths = ((-1 * ((size(popRecordMatrixPast,2)-1))):1:0) / 12;
    if strcmp('pop', popOrPrev)
        upperPrctiles = prctile(popRecordMatrixPast, 95);
        medianPrctiles = prctile(popRecordMatrixPast, 50);
        lowerPrctiles = prctile(popRecordMatrixPast, 5);
    elseif strcmp('prev', popOrPrev)
        upperPrctiles = prctile(prevRecordMatrixPast, 95);
        medianPrctiles = prctile(prevRecordMatrixPast, 50);
        lowerPrctiles = prctile(prevRecordMatrixPast, 5);
    elseif strcmp('incidence', popOrPrev)
        upperPrctiles = prctile(incidenceRecordMatrixPast, 95);
        medianPrctiles = prctile(incidenceRecordMatrixPast, 50);
        lowerPrctiles = prctile(incidenceRecordMatrixPast, 5);   
    elseif strcmp('incidencePerKoala', popOrPrev)
        upperPrctiles = prctile(incidencePerKoalaRecordMatrixPast, 95);
        medianPrctiles = prctile(incidencePerKoalaRecordMatrixPast, 50);
        lowerPrctiles = prctile(incidencePerKoalaRecordMatrixPast, 5);
    elseif strcmp('disease', popOrPrev)
        upperPrctiles = prctile(diseasedPrevRecordMatrixPast, 95);
        medianPrctiles = prctile(diseasedPrevRecordMatrixPast, 50);
        lowerPrctiles = prctile(diseasedPrevRecordMatrixPast, 5);   
    end
    plotQuantiles((-(yearsOfSimulatedPast*12 - 1):0)/12, [upperPrctiles; medianPrctiles; lowerPrctiles], plotColors.popColor, plotColors.popLineStyle);
    
end

xAxisMonths = ((1:(size(recordsVaccine.popRecordMatrix,2)-2))) / 12;

if strcmp('pop', popOrPrev)
    plotRecordMatrixThisVaccine = recordsVaccine.popRecordMatrix(recordsVaccine.popRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end);
elseif strcmp('prev', popOrPrev)
    plotRecordMatrixThisVaccine = 100 * double(recordsVaccine.infRecordMatrix(recordsVaccine.infRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end)) ...
        ./ ...
        double(recordsVaccine.popRecordMatrix(recordsVaccine.popRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end));
elseif strcmp('incidence', popOrPrev)
    plotRecordMatrixThisVaccine = recordsVaccine.incidenceRecordMatrix(recordsVaccine.incidenceRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end);
elseif strcmp('incidencePerKoala', popOrPrev)
    plotRecordMatrixThisVaccine = double(recordsVaccine.incidenceRecordMatrix(recordsVaccine.incidenceRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end)) ...
        ./ ...
    double(recordsVaccine.popRecordMatrix(recordsVaccine.popRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end));
elseif strcmp('disease', popOrPrev)
    plotRecordMatrixThisVaccine = 100 * double(recordsVaccine.diseasedRecordMatrix(recordsVaccine.diseasedRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end)) ...
        ./ ...
        double(recordsVaccine.popRecordMatrix(recordsVaccine.popRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end));
end
if isUseConfi
    popUpper = prctile(single(plotRecordMatrixThisVaccine), 95);
    popMedian = prctile(single(plotRecordMatrixThisVaccine), 50);
    popLower = prctile(single(plotRecordMatrixThisVaccine), 5);
    hVacPop = confi( xAxisMonths , popMedian, popUpper, popLower, plotColors.popColor, plotColors.lineWidth, areaEdgeColor); hold on;
else
    hVacPop = plotQuantiles([0 xAxisMonths], ...
        getQuantiles([yearZeroPlotVal plotRecordMatrixThisVaccine], ...
        whichQuantiles, 0),plotColors.popColor, plotColors.popLineStyle); hold on;
end
if isShowInf
    hVacInf = plotQuantiles([0 xAxisMonths], ...
        getQuantiles([yearZeroInf recordsVaccine.infRecordMatrix(recordsVaccine.infRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end)], ...
        [50 50 50], 0), plotColors.infColor, plotColors.infLineStyle);
    if ~isempty(recordsNoVaccinePast)
        plot((-(yearsOfSimulatedPast*12 - 1):0)/12 + actualYearToAddIfNecessary, prctile(infRecordMatrixPast, 50), 'r');
    end
else
    hVacInf = [];
end
if isShowDisease
    hVacDis = plotQuantiles([0 xAxisMonths], ...
        getQuantiles([yearZeroDis recordsVaccine.diseasedRecordMatrix(recordsVaccine.diseasedRecordMatrix(:,1)==vaccineNumber,(numOfLeadingElementsToIgnore+1):end)], ...
        [50 50 50], 0), plotColors.disColor, plotColors.disLineStyle);
else
    hVacDis = [];
end
hold on;
if isPlotSmoothedTimeCourse
    smoothedTimeCourse = getQuantileTimeCourseForThisScenario(recordsVaccine, vaccineNumber, 50);
    plot((1:length(smoothedTimeCourse))/12, smoothedTimeCourse);
end

if ~exist('recordsNoVaccinePast','var')
    axis([0+actualYearToAddIfNecessary yearsToShow+actualYearToAddIfNecessary 0 yAxisMax])
else
    axis([-yearsOfPast+actualYearToAddIfNecessary yearsToShow+actualYearToAddIfNecessary 0 yAxisMax])
end
set(gca,'Color',[1.0 1.0 1.0]);
set(gcf,'Color',[1.0 1.0 1.0]);
set(gca, 'fontsize', baseParams.fontSize);
box off;

if isShowInf
    legendVacPop = [legendPrefixes ',' char(10) '  total population'];
    legendVacInf = [legendPrefixes ',' char(10) '  infected population'];
    legendVacDis = [legendPrefixes ',' char(10) '  diseased population'];
else
    legendVacPop = legendPrefixes;
end

plotHandleArray = hVacPop;
plotLegendCellArray = {legendVacPop};
if isShowInf
    plotHandleArray = [plotHandleArray hVacInf];
    plotLegendCellArray{end+1} = legendVacInf;
end
if isShowDisease
end
legendHandles = [oldLegendHandles plotHandleArray];
if isempty(legendText)
    legendText = plotLegendCellArray;
else
    legendText = [legendText plotLegendCellArray];
end
legend(legendHandles, legendText, 'Location', legendLocation)

if isShowYear
    hXlabel = xlabel('Year');
else
    hXlabel = xlabel('Years since start of program')
end
if strcmp('pop', popOrPrev)
    hYlabel = ylabel({'','Number of koalas'});
elseif strcmp('prev', popOrPrev)
    hYlabel = ylabel({'','Infection prevalence (%)'});
elseif strcmp('incidence', popOrPrev)
    hYlabel = ylabel('Number of new infections');
elseif strcmp('incidencePerKoala', popOrPrev)
    hYlabel = ylabel('Number of new infections per koala');
elseif strcmp('disease', popOrPrev)
    hYlabel = ylabel('Disease prevalence (%)');
end
alpha(0.3);
set(gca, 'FontSize', baseParams.fontSize)
set(hXlabel, 'FontSize', baseParams.fontSize)
set(hYlabel, 'FontSize', baseParams.fontSize)

    function h = plotQuantiles(xVals, quantilesMatrix,colour,lineStyle)
        if isUsePercentileLines
            plot(xVals + actualYearToAddIfNecessary,quantilesMatrix(1,:),':','Color',colour,'LineStyle',lineStyle); hold on
            plot(xVals + actualYearToAddIfNecessary,quantilesMatrix(3,:),':','Color',colour,'LineStyle',lineStyle);
        end
        h = plot(xVals + actualYearToAddIfNecessary,quantilesMatrix(2,:),'LineWidth',plotColors.lineWidth,'Color',colour,'LineStyle',lineStyle);
    end

    function g = getQuantiles(recordMatrix, whichQuantiles, numOfLeadingElementsToIgnore)
        g = prctile(single(recordMatrix(:,(numOfLeadingElementsToIgnore+1):end)), whichQuantiles);
    end
end