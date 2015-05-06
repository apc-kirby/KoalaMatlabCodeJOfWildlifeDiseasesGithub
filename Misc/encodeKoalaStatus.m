function b = encodeKoalaStatus(female, infected, diseaseA, diseaseB, diseaseC)

% b = encodeKoalaStatus(female, infected, diseaseA, diseaseB, diseaseC)
% Encodes information about a koala stored in several variables in one
% variable.
%
% female: Boolean: true if koala is female, false if male.
% infected: Boolean: true if koala is infected, false otherwise.
% diseaseA: Boolean: true if koala has disease A, false otherwise.
% diseaseB: Boolean: true if koala has disease B, false otherwise.
% diseaseC: Boolean: true if koala has disease C, false otherwise.
%
% b: Single variable storing all the information in the input variables.

    b = female + 2 * infected + 4 * diseaseA + 8 * diseaseB + 16 * diseaseC;

end