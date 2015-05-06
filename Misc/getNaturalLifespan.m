function naturalLifespans = getNaturalLifespan(cumulativeMortalitiesFemale, cumulativeMortalitiesMale, genders)

% naturalLifespans = getNaturalLifespan(cumulativeMortalitiesFemale, cumulativeMortalitiesMale, genders)
% Generates lifespans for a number of koalas equal to length(genders).
%
% genders: Vector of genders of the koalas.
%
% naturalLifespans: Generated lifespans.

    male = 0;
    female = 1;
    
    numKoalas = length(genders);
    naturalLifespansFemale = ones(numKoalas, 1);
    naturalLifespansMale = ones(numKoalas, 1);
    randVector = rand(numKoalas, 1);
    for ind = 1:(length(cumulativeMortalitiesFemale)-1)
        naturalLifespansFemale = naturalLifespansFemale + (randVector > cumulativeMortalitiesFemale(ind));
        naturalLifespansMale = naturalLifespansFemale + (randVector > cumulativeMortalitiesMale(ind));
    end
    
    naturalLifespans = naturalLifespansFemale;
    naturalLifespans(genders == male) = naturalLifespansMale(genders == male);

end