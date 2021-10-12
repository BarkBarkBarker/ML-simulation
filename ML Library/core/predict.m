% =================================================================== %
% Machine Learning Package (c) 2016 Alexei Merkushev                  %
% Date of creation: 13.10.2016                                        %
% Date of modification: 14.10.2016                                    %
% =================================================================== %

% ------------------------------------------------------------------- %
% machine prediction routine                                          %
% ------------------------------------------------------------------- %
function Y = predict( model, X )
    
    % input arguments:
    %   model - structure, representing a model,
    %           with at least the following fields:
    %               x - input points;
    %               fnc - core function;
    %               coef - coefficient array (column-vector);
    %   X - input points (column-vector of row-vectors);
    %
    % output arguments:
    %   Y - output values (column-vector);

    % extract model data
    x = model.x;
    fnc = model.fnc;
    coef = model.coef;
    
    % preallocate array of output values
    num = size(X, 1);
    Y = zeros(num, 1);
    
    % interpolation loop
    for k = 1:num
        % retrieve current point
        X_k = X(k, :);
        % accumulate value for current point
        val = 0;
        for l = 1:size(x, 1)
            val = val + coef(l) * fnc(norm(X_k - x(l, :)));
        end
        % store value
        Y(k) = val;
    end
    
end