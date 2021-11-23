% =================================================================== %
% Perturbation Study Tools ...                                        %
% ... (c) 2018 A. Merkushev, E. Danilogorskaya, P. Markovskiy         %
% perturbZint.m                                                       %
% =================================================================== %

% ******************************************************************* %
% Note: The routine below perturbates internal impedances of target   %
%       lines of specified grid model                                 %
% ******************************************************************* %

% ------------------------------------------------------------------- %
% perturbate line parameters of target lines in Nets-OO model         %
% ------------------------------------------------------------------- %
function pv = perturbZint( net, tgt_lines, level )
    
    % input arguments:
    %   net       - target grid model handle;
    %   tgt_lines - target lines descriptor;
    %   level     - perturbation level;
    % 
    % output arguments:
    %   pv - vector of actual perturbations;
    %   
    % note:
    %   the function directly operates on target grid model handle;
    
    % fill perturbation vector
    pv = level * randComplex(size(tgt_lines.ids));
    
    % apply perturbations to internal impedance of given level
    for k = 1:numel(pv)
        
        % retrieve k-th line
        linek = net.findLine(tgt_lines.ids{k});
        
        % redefine internal impedance
        Zint_k = (1.0 + pv(k)) * linek.Zint(0.0);
        linek.setZG(@(x)Zint_k * ones(size(x)), linek.Zext, linek.G);
        
    end % loop by target lines

end % END OF function
