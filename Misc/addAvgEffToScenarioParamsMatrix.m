function [scenarioParamsMatrixWithAvgEff, scenarioLabelsWithAvgEff] = addAvgEffToScenarioParamsMatrix(scenarioParamsMatrix, scenarioLabels)

% [scenarioParamsMatrixWithAvgEff, scenarioLabelsWithAvgEff] = addAvgEffToScenarioParamsMatrix(scenarioParamsMatrix, scenarioLabels)
% Used to augment half-life and initial efficacy scenario parameters to
% scenario parameter matrix when they are both being determined using a
% single scaling factor parameter.
% 
% scenarioParamsMatrix: Scenario parameters matrix.
% scenarioLabels: Names of scenario parameters.
%
% scenarioParamsMatrixWithAvgEff: Augmented scenario parameter matrix.
% scenarioLabelsWithAvgEff: Augmented scenario parameter names.

scenarioParamsMatrixWithAvgEff = scenarioParamsMatrix;
scenarioParamsMatrixWithAvgEff(:,end+1) = getAvgEff(...
    scenarioParamsMatrix(:,strcmp('Initial efficacy',scenarioLabels)), ...
    scenarioParamsMatrix(:,strcmp('Half-life',scenarioLabels)));
scenarioLabelsWithAvgEff = scenarioLabels;
scenarioLabelsWithAvgEff{end+1} = 'Avg eff';
end