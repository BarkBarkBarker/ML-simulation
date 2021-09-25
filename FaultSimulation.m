clear
clc
close all

t_total = tic;


% Definition simulink model
model = 'GridN1'; 

% Fault parameters
parameters = {  'phases', 'CG';...
                'ts_1', 0.1;...
                'ts_2', 0.2;...
                'Ron', 1;...
                'Rg', 1;...
                'Rs', 1;...
                'Cs', inf  };

% load simulink model
load_system(model)
            
try 
    SimFunc.AddSource(model)     
catch source_error
    fprintf('Souce wasnt added because of: \n\n\t\"%s\"\n', source_error.message);
end


% Add Fault block 
fault = SimFunc.AddFault(model, 'Fault', 'R1');

% Set up parameters of Fault block
SimFunc.SetUpFault(fault, parameters)

% Run simulation and collect data from scopes

data = SimFunc.RunSim(model);

% Draw plots of phasors from scope#2 at t=0.5

SimFunc.DrawPhasor(data(2), 0.5)


% Delete created Fault block
SimFunc.DeleteFault(model, 'Fault')


% close simulink model
save_system(model)
close_system(model)

fprintf('\nTotal work time %f sec\n', toc(t_total)) 



% && contains([get_param(connect_handle,'PortConnectivity').Type], 'LConn1LConn2LConn3')
