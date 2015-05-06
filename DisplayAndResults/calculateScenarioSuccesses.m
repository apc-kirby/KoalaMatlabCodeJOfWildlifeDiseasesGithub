function scenarioSuccesses = calculateScenarioSuccesses(recordsVaccine, yearInQuestion)

% scenarioSuccesses = calculateScenarioSuccesses(recordsVaccine, yearInQuestion)
% For each intervention, calculates the proportion of simulation that met
% some specified criteria.
%
% recordsVaccine: Intervention simulation results.
% yearInQuestions: Year for which success should be evaluated.
%
% scenarioSuccesses: N x 2 matrix of success, where in each row the first
% element is the intervention ID and the second element is the proportion
% of simulations for which the success criteria were met.

% Logic to determine successes should be hard-coded here.
monthInQuestion = 12*yearInQuestion;
beatThreshold = recordsVaccine.popRecordMatrix(:, 2+monthInQuestion) >= recordsVaccine.popRecordMatrix(:, 2+1);
scenarioNums = unique(recordsVaccine.popRecordMatrix(:,1));
nScenarios = length(scenarioNums);
nParams = length(unique(recordsVaccine.popRecordMatrix(:,2)));
scenarioSuccesses = double([scenarioNums -99+zeros(nScenarios,1)]);
for indScenario = 1:nScenarios
    if mod(indScenario, 100) == 0
        disp(['Calculating success for scenario ' num2str(indScenario) ' of ' num2str(nScenarios) '...'])
    end
    thisScenario = scenarioNums(indScenario);
    filterThisScenario = ismember(recordsVaccine.popRecordMatrix(:,1), thisScenario);
    nSuccessesForThisScenario = sum(beatThreshold(filterThisScenario));
    scenarioSuccesses(indScenario,2) = nSuccessesForThisScenario / nParams;
end

end