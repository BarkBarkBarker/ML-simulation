% =================================================================== %
% Machine Learning Package (c) 2016-2018 Alexei Merkushev             %
% Date of creation: 13.10.2016                                        %
% Date of modification: 17.07.2018                                    %
% =================================================================== %

% ------------------------------------------------------------------- %
% implementation of Bahvalov function                                 %
% ------------------------------------------------------------------- %
function y = bahvalov( x, varargin )

    % input arguments:
    %   x - input value (distance in multidimensional space);
    %   t - optional "t" parameter;
    %   n - optional "n" parameter;
    %
    % output arguments:
    %   y - output value (correlation messure);

    % determine "t" parameter
    if nargin >= 2 && ~isempty(varargin{1})
        t = varargin{1};
    else
        t = 1e6;
    end
    
    % determine "n" parameter
    if nargin >= 3 && ~isempty(varargin{2})
        n = varargin{2};
    else
        n = 1e6;
    end
    
    % evaluation
    x = x .* x;          % obtain distance square
    y = x .* log(x / t); % evaluate logarithmic term
    y(x==0) = 0;         % regularization for zero
    y = y + n;           % fulfill evaluation
    
    % calibration
    ln_t = log(t);                    % logarithm of "t" parameter
    Ck = n / ((2 * n - ln_t) * ln_t); % evaluate calibration coefficient (D1 is assumed to be 1)
    y = Ck * y;                       % apply calibration
    
end
