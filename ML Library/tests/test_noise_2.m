
% define seed
seed = 12345;
if exist('rng')
    rng(seed);
else
    randn('seed', seed);
    rand('seed', seed);
end

% define simulation parameters
stdDevs = [0, 0.1, 0.2, 0.5, 1];
Ns = [10, 30, 100];
M = 1000;

% get dimensions
num_stdDevs = numel(stdDevs);
num_Ns = numel(Ns);

% allocate output array
meanAbsErr = zeros(num_stdDevs, num_Ns, M);

% loop by smoothness factors (aka stdDev)
for k = 1:num_stdDevs
    
    % get k-th 'stdDev'
    stdDev = stdDevs(k);
    
    % loop by number of interpolation points
    for l = 1:num_Ns
        
        % get l-th 'N'
        N = Ns(l);
        
        % loop by experiments
        for m = 1:M
            
            % prepape random interpolation data
            x = unique(rand(N, 1));
            y = 2*rand(size(x))-1;
            
            % build model
            mdl = learn(x, y, [], stdDev);
            
            % build prediction
            yp = predict(mdl, x);
            
            % compute and store mean abs error
            meanAbsErr(k, l, m) = mean(abs(yp - y));
            
            % print progress
            disp([k, l, m]);
            
        end % loop by m
        
    end % loop by l
    
end % loop by k

% save results
save('test_noise_2_results.mat', 'seed', ...
     'meanAbsErr', 'stdDevs', 'Ns', 'M', '-v7');
