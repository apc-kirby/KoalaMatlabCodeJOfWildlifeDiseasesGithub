function scenarioParams = setupScenarioParams23012015_23Culling()

% scenarioParams = setupScenarioParams23012015_23Culling()
% Produces the struct of intervention parameters used to simulate the
% culling scenarios.
%
% scenarioParams: Struct of intervention parameters.

male = 0;
female = 1;

scenarioParams.capturesByMonthAdjustment = 0; 

scenarioParams.proportionLocateable = [1-0.16];
scenarioParams.cull = [7 8 11 13 14 15 16 17];
% 0 = no culling
% 1 = cull by body score
% 2 = cull by disease and infection, prioritised by severity
% 3 = cull by infection
% 4 = cull by disease (not infection), prioritised by severity
% 5 = cull by disease stage C only
% 6 = cull with any koala eligible
% 7 = cull by disease and infection, no prioritising
% 8 = cull by disease, no prioritising
% 9 = target both diseased and infected: cull diseased, antibiotics to infected
% 10 = random selection, with diseased culled and antibiotics to all others
% 11 = target both diseased and infected: cull disease stage B & C, antibiotics to disease stage A and infected
% 12 = target both diseased and infected: cull disease stage C, antibiotics to disease stage A & B and infected
% 13 = target both diseased and infected: no culling, antibiotics to disease stage A & B & C and infected
% 14 = Cull disease stage B (females only) & C, no prioritising
% 15 = 'Cull and treat': Cull disease stage B (females only) & C; antibiotics to infected, no prioritising.
% 16 = 'Treat only': Antibiotics to disease stage B (females only) & C & infected, no prioritising.
% 17 = 'Cull only': Cull disease stage B (females only) & C & infected, no prioritising.
scenarioParams.preventsWhat = [-1];          % -1 = prevents nothing, and cannot cure existing infection
                                             % 0 = prevents infection, and can cure existing infection
                                             % 1 = prevents disease, and
                                             % can cure existing infection
                                             % 2 = prevents disease, but
                                             % cannot cure existing
                                             % infection
                                             % 3 = prevents infection, prevents disease, and can cure existing infection
scenarioParams.halfLife = [0]; % halfLife and initialEfficacy are deprecated; they will both be generated using effAndHalfLifeScalingParam.
scenarioParams.initialEfficacy = [0]; % halfLife and initialEfficacy are deprecated; they will both be generated using effAndHalfLifeScalingParam.
scenarioParams.effAndHalfLifeScalingParam = [0];
scenarioParams.cureEfficacy = logical([0]); % 0 = none
                                                   % 1 = cures at the same
                                                   % level as initial
                                                   % efficacy
scenarioParams.usingAntibiotics = logical([0]);
scenarioParams.boostType = [4];    % 0 = no boost
                                            % 1 = boost as portion of
                                            % difference between current
                                            % efficacy and initial efficacy
                                            % 2 = boost as portion of
                                            % difference between current
                                            % efficacy and 100%
                                            % 3 = boost as multiplier of
                                            % current efficacy, to max of
                                            % initial efficacy
                                            % 4 = boost as multiplier of
                                            % current efficacy, to max of
                                            % 100%
scenarioParams.boostAmount = [1]; 
scenarioParams.boostFromMating = logical([0]);
scenarioParams.targetUnvaccinatedKoalas = logical([0]);
% Any koala
scenarioParams.groups(1,1).minAge = 0;
scenarioParams.groups(1,1).maxAge = 100;
scenarioParams.groups(1,1).gender = [0 1];
scenarioParams.groups(1,1).mothersOnly = false;
scenarioParams.groups(1,1).motherAndJoeyAsSet = true;
scenarioParams.groups(1,1).minWeight = 0;

scenarioParams.numberOfCapturesByMonth{1} = repmat(135 * [1 0 0 0 0 0 1 0 0 0 0 0], [1 50]); 
scenarioParams.numberOfCapturesByMonth{2} = repmat(round(0.5*135) * [1 0 0 0 0 0 1 0 0 0 0 0], [1 50]); 
scenarioParams.numberOfCapturesByMonth{3} = repmat(round(0.25*135) * [1 0 0 0 0 0 1 0 0 0 0 0], [1 50]); 

scenarioParams.emigrationsByMonth = { ...
    zeros(1,12*50) };
    
scenarioParams.antibioticEfficacy = [1 0.8];
end

