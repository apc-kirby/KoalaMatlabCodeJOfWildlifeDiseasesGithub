function startingPopOutput = determineOneRandomStartingPop(params, totalKoalas, reproductiveSuccessStruct, currentRandStreamState)

% startingPopOutput = determineOneRandomStartingPop(params, totalKoalas, reproductiveSuccessStruct, currentRandStreamState)
% Generates a starting population of koalas.
%
% params: Model parameters.
% totalKoalas: Number of koalas to generate.
% reproductiveSuccessStruct: Struct of reproductive success weights.
% currentRandStreamState: No longer used.
%
% startingPopOutput: Newly generated random population.

male = 0;
female = 1;
numPops = 1;

startingPopOutput.currentMonth = 0;

startingPopOutput.id = repmat((1:totalKoalas)', [1 numPops]);
startingPopOutput.vaccinationTime= nan(totalKoalas, numPops);
startingPopOutput.joeysHad= nan(totalKoalas, numPops);
startingPopOutput.ageAtFirstParturation= nan(totalKoalas, numPops);
startingPopOutput.joey= nan(totalKoalas, numPops);
startingPopOutput.infectionNumber= zeros(totalKoalas, numPops);
startingPopOutput.infectionEnds= zeros(totalKoalas, numPops);
startingPopOutput.resistanceEnds= nan(totalKoalas, numPops);
startingPopOutput.diseaseStageCEmerges= nan(totalKoalas, numPops);
startingPopOutput.diseaseStageBEmerges= nan(totalKoalas, numPops);
startingPopOutput.diseaseStageAEmerges= nan(totalKoalas, numPops);
startingPopOutput.infectionStarted= nan(totalKoalas, numPops);
startingPopOutput.breedsNext= zeros(totalKoalas, numPops);
startingPopOutput.weightTrackParamA = datasample(reproductiveSuccessStruct.weightTrackParamADistn, totalKoalas);

genderProbMatrix = params.b * ones(totalKoalas, 1);
startingPopOutput.gender = rand(totalKoalas, numPops) < genderProbMatrix;

lifespans = zeros(totalKoalas, numPops);
lifespans(:, 1) = getNaturalLifespan(params.cumulativeFemaleProbOfDyingBeforeThisMonth, ...
        params.cumulativeMaleProbOfDyingBeforeThisMonth, startingPopOutput.gender(:, 1));

startingPopOutput.currentAges = floor(rand(totalKoalas, 1) .* lifespans); % A number in the range [0, lifespan of the koala).
startingPopOutput.dob = -startingPopOutput.currentAges;
startingPopOutput.naturalDod = lifespans - startingPopOutput.currentAges;
startingPopOutput.dod = startingPopOutput.naturalDod;
        
end


