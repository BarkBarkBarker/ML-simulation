% =================================================================== %
% Machine Learning Package (c) 2016 Alexei Merkushev                  %
% Date of creation: 14.10.2016                                        %
% Date of modification: 19.04.2017 | 09.03.2018                       %
% =================================================================== %

% ******************************************************************* %
% note: call this script after using machine learning package to      %
%       remove from the search path all package-related directories   %
% ******************************************************************* %

% try to remove 'core' directory from the search path
try
    rmpath(genpath([pwd(), filesep(), 'core']));
catch
    error('Machine Learning package is not properly unloaded');
end
