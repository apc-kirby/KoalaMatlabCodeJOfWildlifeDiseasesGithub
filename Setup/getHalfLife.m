function halfLife = getHalfLife(scalingFactor)

% halfLife = getHalfLife(scalingFactor)
% One of a pair of functions that allows vaccine efficacy and half-life to
% be jointly determined using a single scaling factor.
%
% scalingFactor: Indicates how far between the half-life minimum and
% maximum the actual half-life should be.
%
% halfLife: Half-life as determined by scaling factor.

    maxHalfLife = 10;
    minHalfLife = 5;
    halfLife = scalingFactor * (maxHalfLife - minHalfLife) + minHalfLife;

end