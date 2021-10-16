clear
clc
close all

t_total = tic;


% Definition and load simulink model
model = 'GridN1'; 

load_system(['models/',model])

% Fault parameters
parameters = {  'phases', 'CG';... % common fault (A/B/C) - G, also double faul
                'Ron', 1;... % range=1e-9 ... 10
                'Rg', 1;... % range=1e-9 ... 10
                'Rs', 1;... % adjusts to the stability of the solution 
                'Cs', inf;... % adjusts to the stability of the solution 
                'FaultIn', 'R1'  }; % block where fault
            
try 
    SimFunc.AddSource(model)     
catch source_error
    fprintf('Source wasnt added because of: \n\n\t\"%s\"\n', source_error.message);
end


% Add Fault block 
fault = SimFunc.AddFault(model, 'Fault', 'R1');

% Set up parameters of Fault block
SimFunc.SetUpFault(fault, parameters)

% Run simulation and collect data from scopes

raw_data = SimFunc.GetSimData(model, true);

% Save data in .mat file
% SimFunc.ExportData(model, parameters, raw_data, 'data.mat', 'Fault')

% Draw plots of phasors from scope#2

SimFunc.DrawPhasor(raw_data(2))


% Delete created Fault block
SimFunc.DeleteFault(model, 'Fault')


% close simulink model
save_system(['models/',model])
close_system(['models/',model])

fprintf('\nTotal work time %f sec\n', toc(t_total)) 