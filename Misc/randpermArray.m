function R = randpermArray(A)

    % Randomly permutes elements of a vector.
    % 
    % A: Vector to be permuted.
    % 
    % R: Permuted vector.
    
    permutedIndexes = randperm(length(A));
    R = A(permutedIndexes);
end