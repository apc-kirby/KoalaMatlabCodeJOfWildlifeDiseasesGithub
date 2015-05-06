function createAgeSchematic

% createAgeSchematic
% Creates the age schematic diagram.

female = 1;
male = 2;
vertOffsetSubscript = -1.5;
vertOffsetNoSubscript = -1.5;
ageMonths{female} = [8 12 24 144 240];
ageMonthsDisplay{female} = [8 12 24 62 70];
ageLabels{female} = {'Pouch emergence', 'Becomes independent juvenile (\its_{f,1}\rm)', 'Becomes adult (\its_{2}\rm)', 'Becomes ''old'' (\its_{3}\rm)', 'Maximum age (dies)'};
textVertOffset{female} = [vertOffsetNoSubscript vertOffsetSubscript vertOffsetSubscript vertOffsetSubscript vertOffsetNoSubscript];
fertilityMonths{female} =  [18 36];
fertilityLabels{female} = {'Becomes fertile with low fertility', 'Fertility becomes normal'};
ageMonths{male} = [8 12 48 120 240];
ageMonthsDisplay{male} = [8 12 48 60 70];
ageLabels{male} = {'Pouch emergence', 'Becomes independent juvenile (\its_{m,1}\rm)', 'Becomes adult (\its_{2}\rm)', 'Becomes ''old'' (\its_{3}\rm)', 'Maximum age (dies)'};
textVertOffset{male} = [vertOffsetNoSubscript vertOffsetSubscript vertOffsetSubscript vertOffsetSubscript vertOffsetNoSubscript];
maxAge = max(max(ageMonthsDisplay{female}), max(ageMonthsDisplay{male}));
maxOfAxis = maxAge + 5;
axisBreaks{female} = [mean([fertilityMonths{female}(end) ageMonthsDisplay{female}(end-1)]) ...
    mean([ageMonthsDisplay{female}(end-1) ageMonthsDisplay{female}(end)])];
axisBreaks{male} = [mean([ageMonthsDisplay{male}(end-2) ageMonthsDisplay{male}(end-1)]) ...
    mean([ageMonthsDisplay{male}(end-1) ageMonthsDisplay{male}(end)])];
axisBreakHeight = 1;
axisColor = 'k';
lineDist = 5;

clf
hAxes(female) = axes('Position', [0.125 0.1 0.4 0.8]);
hAxes(male) = axes('Position', [0.7 0.1 0.4 0.8]);
for indSex = 1:2
    line([0 0], [0 maxOfAxis], 'Color', axisColor, 'Parent', hAxes(indSex))
    for indAge = length(ageMonths{indSex}):-1:1
        line([-lineDist 0], [ageMonthsDisplay{indSex}(indAge) ageMonthsDisplay{indSex}(indAge)], 'Color', axisColor, 'Parent', hAxes(indSex))
        text(-lineDist, textVertOffset{indSex}(indAge) + ageMonthsDisplay{indSex}(indAge), [ageLabels{indSex}(indAge) ' '], 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right', 'Interpreter', 'tex', 'BackgroundColor', 'white', 'Parent', hAxes(indSex))
        text(0, ageMonthsDisplay{indSex}(indAge), num2str(ageMonths{indSex}(indAge)), 'HorizontalAlignment', 'center', 'BackgroundColor', 'white', 'Parent', hAxes(indSex))
    end
    if indSex == female
        for indFertility = 1:length(fertilityMonths{indSex})
            line([lineDist 0], [fertilityMonths{indSex}(indFertility) fertilityMonths{indSex}(indFertility)], 'Color', axisColor, 'Parent', hAxes(indSex))
            text(lineDist, fertilityMonths{indSex}(indFertility), fertilityLabels{indSex}(indFertility), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', 'BackgroundColor', 'white', 'Parent', hAxes(indSex))
            text(0, fertilityMonths{indSex}(indFertility), num2str(fertilityMonths{indSex}(indFertility)), 'HorizontalAlignment', 'center', 'BackgroundColor', 'white', 'Parent', hAxes(indSex))
        end
    end
    for indBreaks = 1:length(axisBreaks{indSex})
        line([0 0], [axisBreaks{indSex}(indBreaks)-axisBreakHeight/2 axisBreaks{indSex}(indBreaks)+axisBreakHeight/2], 'Color', 'white', 'Parent', hAxes(indSex))
        line([-axisBreakHeight axisBreakHeight], [axisBreaks{indSex}(indBreaks) axisBreaks{indSex}(indBreaks)+axisBreakHeight], 'Color', axisColor, 'Parent', hAxes(indSex))
        line([-axisBreakHeight axisBreakHeight], [axisBreaks{indSex}(indBreaks)-axisBreakHeight axisBreaks{indSex}(indBreaks)], 'Color', axisColor, 'Parent', hAxes(indSex))
    end
    text(0, maxOfAxis, 'Months', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Parent', hAxes(indSex))
    % Draw a triangle arrowhead at the top of the axis line.
    patch([0 -axisBreakHeight/2 axisBreakHeight/2], [maxOfAxis maxOfAxis-axisBreakHeight maxOfAxis-axisBreakHeight], axisColor, 'Parent', hAxes(indSex))
    axis(hAxes(indSex), [-30 30 0 maxAge+10])
    axis(hAxes(indSex), 'off')
end
text(0, maxOfAxis+5, 'Life stages, female (annual prob. of surviving)', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 11, 'Parent', hAxes(female))
text(-15, maxOfAxis+5, 'Life stages, male (annual prob. of surviving)', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 11, 'Parent', hAxes(male))
end