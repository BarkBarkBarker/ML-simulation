% =================================================================== %
% Perturbation Study Tools ...                                        %
% ... (c) 2018 A. Merkushev, E. Danilogorskaya, P. Markovskiy         %
% perturbZseq.m                                                       %
% =================================================================== %

% ******************************************************************* %
% Note: The routine below perturbates modal impedances of target      %
%       lines of specified grid model                                 %
% ******************************************************************* %

% ------------------------------------------------------------------- %
% perturbate line parameters of target lines in Nets-OO model         %
% ------------------------------------------------------------------- %
function pv = perturbZseq( net, tgt_lines, level )
    
    % input arguments:
    %   net       - target grid model handle;
    %   tgt_lines - target lines descriptor;
    %   level     - perturbation level;
    % 
    % output arguments:
    %   pv - vector of actual perturbations ('+' and '0' in each row);
    %   
    % note:
    %   the function directly operates on target grid model handle;
    
    % build transformation matrices
    [F_inv, F] = park_matrices();
    
    % fill perturbation vector
    pv = level * randComplex(numel(tgt_lines.ids), 2);
    
    % apply perturbations to internal impedance of given level
    for k = 1:size(pv, 1)
        
        % retrieve k-th line
        linek = net.findLine(tgt_lines.ids{k});
              
        % redefine impedance
        Zm = F_inv * linek.Z * F;                            % transform to modal framework
        Zm = Zm .* diag(1 + [pv(k, 1), pv(k, 1), pv(k, 2)]); % apply perturbations
        Z = F * Zm * F_inv;                                  % transform back to phase framework
        linek.setZG(@(x)zeros(size(x)), Z, linek.G);         % assign perturbated impedances
        
    end % loop by target lines

end % END OF function
