% =================================================================== %
% Perturbation Study Tools ...                                        %
% ... (c) 2018 A. Merkushev, E. Danilogorskaya                        %
% perturbPhasors.m                                                    %
% =================================================================== %

% ------------------------------------------------------------------- %
% perturbate phasors routine                                          %
% ------------------------------------------------------------------- %
function x = perturbPhasors( x, level )
    
    % input arguments:
    %   x     - initial phasors;
    %   level - perturbation level;
    % 
    % output arguments:
    %   x - perturbated phasors;
    
    % apply perturbation
    x = x + level * norm(x) * randComplex(size(x));
    
end
