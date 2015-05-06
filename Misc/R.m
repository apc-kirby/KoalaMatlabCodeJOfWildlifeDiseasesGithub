    function r = R(p,i,params)
    
    % r = R(p,i,params)
    % Returns probability of developing disease, allowing for greater
    % probability with multiple infections.
    % 
    % p: Probability of developing disease on first infection.
    % i: Number of infection.
    % params: Paramters struct.
    %
    % r: Probability of developing disease.
    
       rr = [0 p p*params.a2/(1-p+p*params.a2) p*params.a3/(1-p+p*params.a3)]';
       r = rr(min(length(rr),i+1));
    end