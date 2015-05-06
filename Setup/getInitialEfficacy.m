function initialEff = getInitialEfficacy(scalingFactor)

% initialEff = getInitialEfficacy(scalingFactor)
% One of a pair of functions that allows vaccine efficacy and half-life to
% be jointly determined using a single scaling factor.
%
% scalingFactor: Indicates how far between the initial efficacy minimum and
% maximum the actual initial efficacy should be.
%
% initialEff: Initial efficacy as determined by scaling factor.

    maxInitialEff = 0.888; % With a half-life of 10 years, this produces an average efficacy of 0.75 over 5 years.
    minInitialEff = 0.4852; % With a half-life of 5 years, this produces an average efficacy of 0.35 over 5 years.
    initialEff = scalingFactor * (maxInitialEff - minInitialEff) + minInitialEff;

end