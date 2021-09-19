clear
clc
close all


% Definition simulink model
model = 'GridN1'; 

% Fault parameters
parameters = {  'phases', 'ACG';...
                'ts_1', 0.1;...
                'ts_2', 0.2;...
                'Ron', 1;...
                'Rg', 1;...
                'Rs', 1;...
                'Cs', inf  };

% load simulink model
load_system(model)
            
% Add Fault block 
fault = AddFault(model, 'Fault', 'Source PC1_TT2');

% Set up parameters of Fault block
SetUpFault(fault, parameters)

% Run simulation and collect data from scopes

data = RunSim(model);

% Draw plots of phasors from scope#2 at t=0.5
DrawPhasor(data(2), 0.5)

% Delete created Fault block
DeleteFault(model, 'Fault')


% close simulink model
save_system(model)
close_system(model)




function scopes = RunSim(model)
% Run simulink model and get data from scopes
% Parameters:
%   model[string/char] - name of simulink model
% Return:
%   scopes[array of struct] - data received from scopes after simulation

    
    % run simulink
    sim(model); 
    
    % get scopes data through their import names
    scopes_name = find_system(model,'BlockType','Scope');
    
    scopes = [];
    for index = 1:length(scopes_name)
        scope_ws_name = get_param(scopes_name{index}, 'DataLoggingVariableName');
        scopes = [scopes, eval(scope_ws_name)]; %#ok<AGROW>
    end
    
    
end


function DeleteFault(model, name)
% Delete added block with it's line
% Parameters:
%   model [string/char] - name of simulink model without file format
%   name [string/char] - name of Fault you want to delete


    handle = [model,'/',name];
    delete_line(get_param(handle,'LineHandles').LConn)
    delete_block(handle)
    
end


function fault_handle = AddFault(model, name, connect_to)
% AddFault adding Fault to model and return it's handle
% Parameters:
%   model [string/char] - name of simulink model without file format
%   name [string/char] - name of Fault you want to add
%   connect_to [string/char] - name of the block or line you want to connect 
    

    % add block and move next to connected one
    connect_handle = get_param([model,'/',connect_to], 'Handle');
    fault_handle = add_block('sps_lib/Power Grid Elements/Three-Phase Fault', [model,'/',name]);
    set_param(fault_handle, 'Position', get_param(connect_handle, 'Position')+[200,-100,200,-100])
    
    
    %add line to connected block
    fault_lc = get_param(fault_handle,'PortHandles').LConn;
    connect_rc = get_param(connect_handle,'PortHandles').RConn;
    add_line(model, connect_rc, fault_lc);
    
end


function SetUpFault(fault_handle, params)
% Set up fault block
% Parameters:
%   fault_handle[double] - handle of the fault block 
%   params[cell Nx2] - cell of N parameters and it's values you want to set


    % raise error if parameters in wrong format
    params_size = size(params);

    if params_size(2)~= 2
       error('Incorrect size of parameters cell, need Nx2'); 
    end
    
    if ~iscell(params)
        error('Incorrect format of parameters data, should be in cell')
    end

    
    % parse parameters
    unknown = [];
    for index = 1:length(params)
        if ~isstring(params{index,1}) && ~ischar(params{index,1})
            error('Name of parameters should be in string or char')
        end
        
        switch params{index,1}
           case 'phases'
               phases = params{index,2};
           case 'ts_1'
               ts1 = params{index,2};
           case 'ts_2'
               ts2 = params{index,2};
           case 'Ron'
               set_param(fault_handle, 'FaultResistance', string(params{index,2}))
           case 'Rg'
               set_param(fault_handle, 'GroundResistance', string(params{index,2}))
           case 'Rs'       
               set_param(fault_handle, 'SnubberResistance', string(params{index,2}))
           case 'Cs'
               set_param(fault_handle, 'SnubberCapacitance', string(params{index,2}))
           otherwise
               unknown = [unknown, params{index,2}]; %#ok<AGROW>
        end
    end
    
    set_param(fault_handle, 'SwitchTimes', mat2str([ts1, ts2]))
    
    
    % warning for unknown parameters
    if ~isempty(unknown) 
        warning('Unknown parameters: %s', unknown)
    end
    
    
    % check phases format
    if ~isstring(phases) && ~ischar(phases)
        error('Parameters of faulted phases should be string or char') 
    end
    
    
    % Set faults of phases
    for letter = ['A','B','C','G'] % possible parameters of phases (3 phases + ground)
        
        if letter == 'G'
            param_name = 'GroundFault'; % name for Ground
        else
            param_name = ['Fault', letter]; % name for phases
        end
        
        if contains(phases, letter) % change specified params
            set_param(fault_handle, param_name, 1)
        else
            set_param(fault_handle, param_name, 0)
        end
        
        phases(phases == letter) = [];
    end
    
    
    % check for invalid phases parameters
    if ~isempty(phases) 
        warning('Unknown fault parameters: %s', phases)
    end
        
end


function DrawPhasor(data, time)
% Draw phasors of current and voltage in subplot in new figure
% Parameters:
%   data[struct] - data of measured current and voltage from scopes
%   time[double] - time moment to show, if in data there no such value
%   closest will chosen


    % check if time moment are in data, else choose closest to it
    if isempty(find(data.time == time, 1))

        delta_time = abs(data.time - time);
        
        index = find(delta_time == min(delta_time));
    else
        index = find(data.time == time);
    end
    
    
    % separate data
    cur = data.signals(1).values(index,:);
    volt = data.signals(2).values(index,:);
    time = data.time(index);

    
    % do plots
    figure
    sgtitle(sprintf('%s, time=%f',data.blockName, time))
    
    subplot(1,2,1)
    compass(real(cur), imag(cur))
    title('Current')
    xlabel('Re(I)[A]')
    ylabel('Im(I)[A]')
    
    subplot(1,2,2)
    compass(real(volt), imag(volt))
    title('Voltage')
    xlabel('Re(U)[V]')
    ylabel('Im(U)[V]')
    
end

