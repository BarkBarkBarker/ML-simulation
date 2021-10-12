% =================================================================== %
% Machine Learning Package (c) 2016 Alexei Merkushev                  %
% Date of creation: 13.10.2016                                        %
% Date of modification: 14.10.2016                                    %
% =================================================================== %

% ------------------------------------------------------------------- %
% machine prediction routine for serieses                             %
% ------------------------------------------------------------------- %
function [ series, model ] = predict_series( series, wnd, iter, varargin )
    
    % input arguments:
    %   series - source series (row-vector);
    %   wnd - window size in samples;
    %   iter - number of prediction iterations;
    %   fnc - optional core function;
    %
    % output arguments:
    %   series - supplemented series (row-vector);
    %   model - prediction model;
    
    % TODO: also consider higher-order derivatives here
    
    % obtain discrete derivative
    deriv = diff(series);
    
    % prepare interpolation data
    ttl_num = length(deriv);
    num = ttl_num - wnd - 1;
    x = zeros(num, wnd);
    y = zeros(num, 1);
    for k = 1:num
        l = k + wnd;
        x(k, :) = deriv(k:(l - 1));
        y(k) = deriv(l);
    end
    
    % learning
    if nargin >= 4 && ~isempty(varargin{1})
        model = learn(x, y, varargin{1});
    else
        model = learn(x, y);
    end
    
    % prediction of discrete derivatives
    deriv = [deriv, zeros(1, iter)];
    for k = 1:iter
        l = ttl_num + k - 1;
        deriv(l + 1) = predict(model, deriv((l - wnd + 1):l));
    end
    
    % append prediction to a series
    series = [series, series(end) + cumsum(deriv((end - iter + 1):end))];
    
end