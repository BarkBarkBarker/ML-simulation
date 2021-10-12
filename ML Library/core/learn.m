% =================================================================== %
% Machine Learning Package (c) 2016-2018 Alexei Merkushev             %
% Date of creation: 13.10.2016                                        %
% Date of modification: 18.07.2018                                    %
% =================================================================== %

% ******************************************************************* %
% Note: In fact 's' is not standard deviation in terms of 'y' units,  %
%       it is rather smoothness factor; in general case the following %
%       ratio controls smoothness s^2 / D1 (by default D1 = 1)        %
% ******************************************************************* %

% ------------------------------------------------------------------- %
% machine learning routine                                            %
% ------------------------------------------------------------------- %
function model = learn( x, y, varargin )
    
    % input arguments:
    %   x - input points (column-vector of row-vectors);
    %   y - output values (column-vector);
    %   fnc - optional core function;
    %   s - standard deviation (scalar or column-vector);
    %
    % output arguments:
    %   model - resulting model, represented by structure
    %           with the following fields:
    %               x - input points;
    %               fnc - core function;
    %               coef - coefficient array (column-vector);
    %               R - reciprocal of the condition number of A;
    
    % determine core function
    if nargin >= 3 && ~isempty(varargin{1})
        fnc = varargin{1};
    else
        fnc = @(dx)bahvalov(dx);
    end
    
    % determine standard deviation
    if nargin >= 4 && ~isempty(varargin{2})
        s = varargin{2};
    else
        s = 0.0; % exact interpolation by default
    end
    
    % build matrix
    num = size(x, 1);
    A = zeros(num, num);
    for k = 1:num
        x_k = x(k, :);
        A(k, k) = fnc(0.0);
        for l = (k+1):num
            val = fnc(norm(x_k - x(l, :)));
            A(k, l) = val;
            A(l, k) = val;
        end
    end
    if length(s) > 1
        A = A + diag(s .* s);
    else
        A = A + s * s * eye(size(A));
    end
    
    % determine coefficients
    if rank(A) < num
        coef = pinv(A) * y;
        R = 0;
    else
        [coef, R] = linsolve(A, y);
    end
    
    % define model
    model = struct('x', x, 'fnc', fnc, 'coef', coef, 'R', R);
    
end
