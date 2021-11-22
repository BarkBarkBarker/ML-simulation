% =================================================================== %
% Perturbation Study Tools ...                                        %
% ... (c) 2018 A. Merkushev, E. Danilogorskaya, ...                   %
% ... P. Markovskiy, A. Vasilev                                       %
% perturbLoads.m                                                      %
% =================================================================== %

% ******************************************************************* %
% Note: The routine below perturbates load matrices of target nodes   %
%       of specified grid model                                       %
% ******************************************************************* %

% ------------------------------------------------------------------- %
% perturbate loads of target nodes in Nets-OO model                   %
% ------------------------------------------------------------------- %
function pv = perturbLoads( net, tgt_nodes, level )
    
    % input arguments:
    %   net       - target grid model handle;
    %   tgt_nodes - cell-array of target nodes ids;
    %   level     - perturbation level;
    % 
    % output arguments:
    %   pv - vector of actual perturbations;
    %   
    % note:
    %   the function directly operates on target grid model handle;
    
    % build transformation matrices
    [F_inv, F] = park_matrices();
    
    % fill perturbation vector
    pv = level * randComplex(size(tgt_nodes));
    
    % apply perturbations of given level to load matrices
    for k = 1:numel(pv)
        
        % retrieve k-th node
        nodek = net.findNode(tgt_nodes{k});
              
        % redefine impedance
        Lm = F_inv * nodek.load * F;            % transform to modal framework
        Lm = Lm .* diag(1 + [pv(k), pv(k), 0]); % apply perturbations
        L = F * Lm * F_inv;                     % transform back to phase framework
        nodek.setLoad(L);                       % assign perturbated load
        
    end % loop by target nodes

end % END OF function
