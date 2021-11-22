% =================================================================== %
% Perturbation Study Tools ...                                        %
% ... (c) 2018 A. Merkushev, E. Danilogorskaya, P. Markovskiy         %
% randComplex.m                                                       %
% =================================================================== %

% ******************************************************************* %
% Note: The routine below generates random complex numbers uniformly  %
%       distributed in circle of unit radius in complex plane         %
% ******************************************************************* %

% ------------------------------------------------------------------- %
% generate random complex scalar / vector / matrix                    %
% ------------------------------------------------------------------- %
function res = randComplex( varargin )
    
    % input arguments:
    %   varargin - same argument list as in 'rand' routine;
    % 
    % output arguments:
    %   res - output complex random scalar / vector / matrix;
    
    % compute output argument
    res = sqrt(rand(varargin{:})) .* exp(2i*pi*rand(varargin{:}));
    
end % END OF function
