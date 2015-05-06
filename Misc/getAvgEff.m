function avgEffs = getAvgEff(initialEffs, halfLives)

% avgEffs = getAvgEff(initialEffs, halfLives)
% Vaccine paper reports vaccine efficacies averaged over 5 years. This
% function performs that averaging.
%
% initialEffs: Vaccine initial efficacies.
% halfLives: Vaccine half-lives.
%
% avgEffs: Efficacy averaged over 5 years.

yearsToAvgOver = 5;
avgEffs = (initialEffs .* halfLives / log(1/2) .* ((1/2).^(yearsToAvgOver ./ halfLives) - 1)) ./ yearsToAvgOver;

end