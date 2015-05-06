function [plotHandleArray, plotLegendCellArray] = plotDataTimeCourse(actualData, zeroYearOfActualData, actualYearToAddIfNecessary, plotHandleArray, plotLegendCellArray, legendLocation, plotColors)

% [plotHandleArray, plotLegendCellArray] = plotDataTimeCourse(actualData, zeroYearOfActualData, actualYearToAddIfNecessary, plotHandleArray, plotLegendCellArray, legendLocation, plotColors)
% Plots data (as opposed to modelling results).
%
% actualData: Data to plot.
% zeroYearOfActualData: Real-world year considered to be 'year zero' of
% simulations.
% actualYearToAddIfNecessary: Years to be added to X axis.
% plotHandleArray: Array of plot handles, so that this one can be added.
% plotLegendCellArray: Array of legends, so that this one can be added.
% legendLocation: Location of legend.
% plotColors: Color and style of data on plot.
%
% plotHandleArray: Array of plot handles.
% plotLegendCellArray: Array of legends.

hData = plot(actualData.years - zeroYearOfActualData + actualYearToAddIfNecessary, actualData.pops, 'xk', 'MarkerSize', 10, 'LineWidth', plotColors.lineWidth); hold on;
plotHandleArray = [plotHandleArray hData];
plotLegendCellArray{end+1} = 'Koala Coast data';
legend(plotHandleArray, plotLegendCellArray, 'Location', legendLocation)
end