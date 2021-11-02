classdef SimFunc
    %SIMFUNC (simulation functions) is class-collection of functions to
    %simulate faults in simulink
    
    
    properties(Constant)
        show_time = false;
        show_warnings = false;
        show_messages = false;
        show_info_bar = true;
        progress_bar_length = 40;
    end
    
    methods(Static)
        
        function [fault_handle, line_separate_point] = FaultInLineDecorator(model, fault_name, line_name)
        % FaultInLine is more complicated version of AddFault. It
        % adding Fault to block, if it line that longer then 100m separate line
        % into 2 parts at a random point and put fault between
        %
        % Parameters:
        %   model [string/char] - name of simulink model without file format
        %   fault_name [string/char] - name of Fault you want to add
        %   line_name [string/char] - name of line you want to connect
        %
        % Return:
        %   fault_handle[float] - handle to added Fault block
        %   line_separate_point[float] - if >0 then point of line
        %   separation ([0, 1]), if =(-1) then line wasn't separate

        % change type of model to char to avoid problems with names
            
            model = char(model);
            
            
            % if block is line get handle and length
            if strcmp(get_param(strcat(model, '/', line_name), 'MaskType'),'Distributed Parameters Line')
                line_handle = get_param(strcat(model, '/', line_name), 'Handle');
                line_length = str2double(get_param(line_handle, 'Length'));
            else
                fault_handle = SimFunc.AddFault(model, fault_name, line_name);
                line_separate_point = -1;
                return
            end
            
            % check if length of line less than 100m, then do common AddBlock
            if(line_length < 0.1) || ~contains(line_name, 'Line')
                fault_handle = SimFunc.AddFault(model, fault_name, line_name);
                line_separate_point = -1;
                return
            else
                
                % separate Line into 2 parts
                line_left_handle = line_handle;
                line_right_handle = add_block(strcat(model, '/', line_name), strcat(model, '/', line_name, 'Sep2'));
                set_param(strcat(model, '/', line_name), 'Name', strcat(line_name, 'Sep1'))
                set_param(line_right_handle, 'Position', get_param(line_left_handle, 'Position') + [0, 100, 0, 100]);
                
                % divide length of original line into 2
                line_separate_point = rand(1);
                
                set_param(line_left_handle, 'Length', num2str(line_length * line_separate_point))
                set_param(line_right_handle, 'Length', num2str(line_length * (1 - line_separate_point)))
                
                
                % get handles of blocks (connected to right side) to connect
                line_ports = get_param(line_handle, 'PortConnectivity');
                right_connect_handles = [];
                
                % 1-3 is left ports, 4-6 is right
                for i = 4:6
                    if ~isempty(line_ports(i).DstPort)
                        right_connect_handles = [right_connect_handles, line_ports(i).DstPort(1)]; %#ok<AGROW>
                    end
                end
                
                % add lines between two parts and right part with
                % continous
                
                if ~(get_param(line_handle,'LineHandles').RConn == [-1 -1 -1]) %#ok<BDSCA>
                    delete_line(get_param(line_handle,'LineHandles').RConn)
                end
                
                
                
                add_line(model, get_param(line_left_handle, 'PortHandles').RConn, get_param(line_right_handle, 'PortHandles').LConn)
                
                if ~isempty(right_connect_handles)
                    add_line(model, get_param(line_right_handle, 'PortHandles').RConn, right_connect_handles)
                end
                
                % add Fault block between ends of line (to right side of
                % left one)
                fault_handle = SimFunc.AddFault(model, fault_name, strcat(line_name, 'Sep1'));
            end
        end
        
        
        function FixLineSeparation(model)
        % FixLineSeparation searches the model for lines that been separated
        % and connects them back (this lines should contains Sep1 and Sep2
        % in names
        %
        % Parameters:
        %   model [string/char] - name of simulink model without file format
            
            
            load_system(model)
            
            % find subsytems with 'Sep1' and 'Sep2' in names, get it handles
            subsystems = find_system(model,'BlockType','SubSystem');
            for index = 1:length(subsystems)
                if contains(subsystems{index}, 'Sep1')
                    line1_handle = get_param(subsystems{index}, 'Handle');
                elseif contains(subsystems{index}, 'Sep2')
                    line2_handle = get_param(subsystems{index}, 'Handle');
                end
            end
            
            % warn if separated lines wasnt found
            if ~exist('line1_handle') || ~exist('line2_handle') %#ok<EXIST>
                if SimFunc.show_warnings
                    warning('Separated lines wasnt found')
                end
                return
            end
            
            % get handles of ports from right side block to connect then
            line_ports = get_param(line2_handle, 'PortConnectivity');
            right_connect_handles = [];
            
            % 1-3 is left ports, 4-6 is right
            
            for i = 4:6
                if ~isempty(line_ports(i).DstPort)
                    right_connect_handles = [right_connect_handles, line_ports(i).DstPort(1)]; %#ok<AGROW>
                end
            end
            
            % change length of resulted block as sum of initial blocks
            set_param(line1_handle, 'Length', num2str(str2double(get_param(line1_handle, 'Length'))+str2double(get_param(line2_handle, 'Length'))))
            
            % check if lines was connected to right part and delete them
            if ~(get_param(line2_handle,'LineHandles').LConn == [-1 -1 -1]) %#ok<BDSCA>
                delete_line(get_param(line2_handle,'LineHandles').LConn)
            end
            if ~(get_param(line2_handle,'LineHandles').RConn == [-1 -1 -1]) %#ok<BDSCA>
                delete_line(get_param(line2_handle,'LineHandles').RConn)
            end
            
            % delete right part of line
            delete_block(line2_handle)
            
            % delete 'Sep' from name
            set_param(line1_handle, 'Name', erase(get_param(line1_handle, 'Name'), 'Sep1'))
            
            % return initial connection
            
            if ~isempty(right_connect_handles)
                add_line(model, get_param(line1_handle, 'PortHandles').RConn, right_connect_handles)
            end
            
            
        end
        
        
        function AddSource(model)
        % AddSource Adding Source to model if it wasn't there
        % (note in directory should be 'source.slx' with source blocks
        % Parameters:
        %   model [string/char] - name of simulink model without file format
            
            t1 = tic;
            
            model = char(model);
            
            % check if there is no Sources in model and find the leftmost block
            subsystems = find_system(model,'BlockType','SubSystem');
            if ~isempty(subsystems)
                lower_x = inf;
                for index = 1:length(subsystems)
                    if contains(subsystems{index}, 'Source')
                        error('%s.slx already has source - %s', model, subsystems{index})
                    end
                    
                    % search of leftmost block except powergui
                    coordinates = get_param(subsystems{index}, 'Position');
                    if coordinates(1) < lower_x && ~contains(subsystems{index},'powergui')
                        lower_x = coordinates(1);
                        leftmost_block = subsystems{index};
                    end
                end
            else
                error('%s.slx has no block to connect source', model)
            end
            
            % get handle of block to connect, if has no empty ports - error
            connect_handle = get_param(leftmost_block, 'Handle');
            ports = get_param(connect_handle,'PortHandles');
            if ~isempty(ports.LConn)
                connect_ports = get_param(connect_handle,'PortHandles').LConn;
            else
                error('Leftmost block %s has no ports to connect with', leftmost_block)
            end
            
            
            load_system('models/source')
            
            % add blocks of source from 'source.slx'
            line_handle = add_block('source/Line 1', [model,'/Line'], 'MakeNameUnique','on');
            source_pc1_handle = add_block('source/Source PC1_TT2', [model,'/Source PC1_TT2']);
            source_zn_handle = add_block('source/Source Zn', [model,'/Source Zn']);
            ground_handle = add_block('source/Ground',[model,'/Ground'], 'MakeNameUnique','on');
            
            close_sysyem('models/source')
            
            % move blocks next to connected one
            set_param(line_handle, 'Position', get_param(connect_handle, 'Position') + [-120, 20, -120, -20]);
            set_param(source_pc1_handle, 'Position', get_param(line_handle, 'Position') + [-130, 0, -130, 0]);
            set_param(source_zn_handle, 'Position', get_param(source_pc1_handle, 'Position') + [-80, 35, -120, 75]);
            set_param(ground_handle, 'Position', get_param(source_zn_handle, 'Position') + [0, 120, 0, 80]);
            
            % get handles of ports
            source_pc1_R_ports = get_param(source_pc1_handle, 'PortHandles').RConn;
            source_pc1_L_port = get_param(source_pc1_handle, 'PortHandles').LConn;
            source_zn_TOP_port = get_param(source_zn_handle, 'PortHandles').RConn;
            source_zn_BOT_port = get_param(source_zn_handle, 'PortHandles').LConn;
            ground_port = get_param(ground_handle, 'PortHandles').LConn;
            line_R_ports = get_param(line_handle, 'PortHandles').RConn;
            line_L_ports = get_param(line_handle, 'PortHandles').LConn;
            
            %connect blocks with lines
            add_line(model, ground_port, source_zn_BOT_port)
            add_line(model, source_zn_TOP_port, source_pc1_L_port)
            add_line(model, source_pc1_R_ports, line_L_ports)
            add_line(model, line_R_ports, connect_ports)
            
            
            if SimFunc.show_time
                fprintf('\nSource added in %f sec\n', toc(t1))
            end
            
        end
        
        
        function fault_handle = AddFault(model, name, connect_to)
        % AddFault Adding Fault to model and return it's handle
        % Parameters:
        %   model [string/char] - name of simulink model without file format
        %   name [string/char] - name of Fault you want to add
        %   connect_to [string/char] - name of the block or line you want to connect
            
            t1 = tic;
            
            model = char(model);
            
            load_system(strcat('models/', model));
            load_system('models/fault');
            
            % add block and move next to connected one
            connect_handle = get_param(strcat(model,'/',connect_to), 'Handle');
            
            % load fault block from 'models/fault.slx' and add it
            
            fault_handle = add_block('fault/Three-Phase Fault', strcat(model,'/',name));
            
            set_param(fault_handle, 'Position', get_param(connect_handle, 'Position')+[200,-100,200,-100])
            
            
            %add line to connected block
            fault_lc = get_param(fault_handle,'PortHandles').LConn;
            
            ports = get_param(connect_handle,'PortHandles');
            
            %try connect to Right ports, if not exist then try Left ones
            if ~isempty(ports.RConn)
                connect_ports = get_param(connect_handle,'PortHandles').RConn;
            elseif ~isempty(ports.LConn)
                connect_ports = get_param(connect_handle,'PortHandles').LConn;
            else
                error('Block %s has no ports to connect with', connect_to)
            end
            
            
            add_line(model, connect_ports, fault_lc);
            
            if SimFunc.show_time
                fprintf('\nFault added in %f sec\n', toc(t1))
            end
            
            
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
                    case 'Ron'
                        set_param(fault_handle, 'FaultResistance', string(params{index,2}))
                    case 'Rg'
                        set_param(fault_handle, 'GroundResistance', string(params{index,2}))
                    case 'Rs'
                        set_param(fault_handle, 'SnubberResistance', string(params{index,2}))
                    case 'Cs'
                        set_param(fault_handle, 'SnubberCapacitance', string(params{index,2}))
                    case 'FaultIn'
                        continue
                    case 'LineSep'
                        continue
                    otherwise
                        unknown = [unknown, params{index,2}]; %#ok<AGROW>
                end
            end
            
            set_param(fault_handle, 'SwitchTimes', '[0.0 0.2]')
            
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
        
        
        function answer = CheckFaultBranch(model, block_handle, fault_in_handle)
            % CheckFaultBranch checking if current fault is in obedience
            % branch for the scope
            %
            % Parameters
            %    model [string] - name of model withoud .slx
            %
            %    block_handle [double] - handle of block to check
            %
            %    fault_in_handle [double] - handle of block, where fault happened
            %
            % Return
            %    answer [bool] - true <=> this fault don't obeys this block,
            %                    false <=> fault in branch of this block
            
            
            load_system(strcat('models/', model))
            
            block_ports = get_param(block_handle, 'PortConnectivity');
            
            
            
            if block_handle == fault_in_handle
                answer = false;
                return
            end
            
            answer = true;
            
            for i = 1:length(block_ports)
                
                % find Rconn, go through it and break
                if contains(block_ports(i).Type, 'RConn')
                    
                    if ~isempty(block_ports(i).DstBlock)
                        for subblock_handle = block_ports(i).DstBlock
                            % check if subblock is fault
                            if subblock_handle == fault_in_handle
                                answer = false;
                                return
                            end
                            % else if it is not other scope recursively
                            % repeat
                            
                            if ~strcmp(get_param(subblock_handle, 'MaskType'),'Three-Phase VI Measurement')
                                answer = answer * SimFunc.CheckFaultBranch(model, subblock_handle, fault_in_handle);
                            end
                            
                        end
                    else
                        % if there is no more connected block return
                        return
                    end
                    
                    break
                    
                end
                
            end
            
            
        end
        
        
        function [scopes, loads_set] = GetSimData(model, permutate)
            % GetSimData running simulation with permutations of loads
            % power (if permutate == true) and return scopes data and
            % parameters of loads in system
            %
            % Parameters
            %    model [string] - name of model without .slx
            %
            %    permutate [bool] -
            %
            % Return
            %    scopes [list of struct] - data with measured current and
            % voltage from scopes
            %
            %    loads_set [cell Nx3] - cell of values in format (load
            % name, load active power value, load inductive power value,)
            
            
            t1 = tic;
            
            if SimFunc.show_messages
                fprintf(2, '\nSTARTED COMPUTATION of %s.slx\n', model)
            end
            
            % try load if it wasn't called from GeneratorCollector
            load_system(strcat('models/', model))
            
            % get list of loads
            loads_start = find_system(model,'MaskType', 'Three-Phase Series RLC Load');
            
            if permutate
                for index = 1:length(loads_start)
                    
                    % define limits of random permutations
                    magnitude_range = [0.5, 1];
                    cos_range = [0.8, 1];
                    
                    % write initial values to set is back in the end
                    loads_start{index, 2} = get_param(loads_start{index,1}, 'ActivePower');
                    loads_start{index, 3} = get_param(loads_start{index,1}, 'InductivePower');
                    
                    % random number in range "random_range" to divide magnitude
                    rand_magn_part = magnitude_range(1) + rand*(magnitude_range(2)-magnitude_range(1));
                    
                    % random number in range [0.8, 1.0] to set cos of Re & Im
                    rand_cos = cos_range(1) + rand*(cos_range(2)-cos_range(1));
                    
                    % get value of current random magnitude
                    power_magn = rand_magn_part*sqrt(str2double(loads_start{index, 2})^2 + str2double(loads_start{index, 3})^2);
                    
                    % set power values according to angle and magnitude
                    loads_set{index, 1} = loads_start{index, 1};
                    loads_set{index, 2} = num2str(rand_cos * power_magn);
                    loads_set{index, 3} = num2str(sqrt(1-rand_cos^2) * power_magn);
                    
                    set_param(loads_start{index,1}, 'ActivePower', loads_set{index, 2});
                    set_param(loads_start{index,1}, 'InductivePower', loads_set{index, 3});
                    
                end
                
            else
                for index = 1:length(loads_start)
                    loads_set{index, 1} = loads_start{index, 1};
                    loads_set{index, 2} = get_param(loads_start{index,1}, 'ActivePower');
                    loads_set{index, 3} = get_param(loads_start{index,1}, 'InductivePower');
                end
            end
            
            conf = getActiveConfigSet(model);
            
            set_param(conf, 'SolverType', 'Fixed-step');
            set_param(conf, 'FixedStep', '0.2');
            set_param(conf, 'StartTime', '0');
            set_param(conf, 'StopTime', '0.2');
            set_param(conf, 'ReturnWorkspaceOutputs', 'on');
            
            simOut = sim(model, 0);
            if SimFunc.show_time
                fprintf('\nSimulation computed in %f sec\n', toc(t1))
            end
            
            % get scopes data through their import names
            scopes_name = find_system(model,'BlockType','Scope');
            
            scopes = [];
            for index = 1:length(scopes_name)
                scope_ws_name = get_param(scopes_name{index}, 'DataLoggingVariableName');
                scopes = [scopes, get(simOut, scope_ws_name)]; %#ok<AGROW>
            end
            
            if permutate
                % set initial values of power to loads
                for index = 1:length(loads_start)
                    set_param(loads_start{index,1}, 'ActivePower', loads_start{index,2})
                    set_param(loads_start{index,1}, 'InductivePower', loads_start{index,3})
                end
            end
            
            
        end
        
        
        function DeleteFault(model, name)
            % Delete added block with it's line
            % Parameters:
            %   model [string/char] - name of simulink model without file format
            %   name [string/char] - name of Fault you want to delete
            
            model = char(model);
            
            handle = [(model),'/',name];
            
            % check if connect lines exist then delete (empty lines marks
            % as [-1 -1 -1]
            
            if ~(get_param(handle,'LineHandles').LConn == [-1 -1 -1]) %#ok<BDSCA>
                delete_line(get_param(handle,'LineHandles').LConn)
            end
            
            delete_block(handle)
            
        end
        
        
        function DrawPhasor(data)
            % Draw phasors of current and voltage in subplot in new figure
            % Parameters:
            %   data[struct] - data of measured current and voltage from scopes
            
            % separate data
            cur = data.signals(1).values(:);
            volt = data.signals(2).values(:);
            time = 0;
            
            
            % do plots
            figure
            sgtitle(sprintf('%s, time=%f',data.blockName, time))
            
            subplot(1,2,1)
            cur_plot = compass(real(cur), imag(cur));
            cur_plot(1).Color = 'r';
            cur_plot(2).Color = 'b';
            cur_plot(3).Color = 'g';
            title('Current')
            xlabel('Re(I)[A]')
            ylabel('Im(I)[A]')
            
            subplot(1,2,2)
            volt_plot = compass(real(volt), imag(volt));
            volt_plot(1).Color = 'r';
            volt_plot(2).Color = 'b';
            volt_plot(3).Color = 'g';
            title('Voltage')
            xlabel('Re(U)[V]')
            ylabel('Im(U)[V]')
            
        end
        
        
        function overwrite_data = ExportData(model, params, raw_data, file_name, type, loads, varargin)
            % ExportData Doing export data from raw_data to 'file_name', with
            % unique id, created from parameters of model
            %
            % Parameters:
            %   model [string/char] - name of simulink model without file format
            %
            %   params[cell Nx2] - cell of N parameters and it's values set in
            % model
            %
            %   raw_data[list of struct] - data with measured current and
            % voltage from scopes
            %
            %   file_name [string/char] - full name of .mat file (name to
            % create or already existing) to read write data. If it empty data
            % should be taken from varargin
            %
            %   type [bool] - type of data, 'fault' or 'idle'
            %
            %   loads [cell Nx3] - cell of values in format (load
            % name, load active power value, load inductive power value,)
            %
            %   varargin{1} = filter [bool] - (IF TYPE == 'fault') flag to
            % activate filter on faults in foreign branches
            %               = data [array of struct] - data array, that will be
            % used if file_name is empty if filter didn't specified
            %
            %   varargin{2} = data [array of struct] - data array, that will be
            % used if file_name is empty if filter specified in varargin{1}
            %
            % Return:
            %   overwrite_data [array of struct] - overwrited data, that wasn't
            % saved (if file_name wasn't specified)
            %   overwrite_data = [] if file_name was specified and data saved
            
            
            model = char(model);
            
            % parse input parameters
            % if varargin{1} is boolean
            if numel(varargin) >= 1 && ~isempty(varargin{1}) && strcmp(type, 'fault') && isa(varargin{1},'logical')
                filter = varargin{1};
                % if varargin{1} is struct (data) and file_name is empty
            elseif numel(varargin) >= 1 && ~isempty(varargin{1}) && isempty(file_name) && isa(varargin{1},'struct')
                data = varargin{1};
            elseif numel(varargin) >= 1 && isempty(varargin{1}) && isempty(file_name)
                data = [];
                % if varargin{1} isn't specified but type is 'fault'
            elseif numel(varargin) >= 1 && isempty(varargin{1}) && strcmp(type, 'fault')
                warning('You selected fault mode and didnt specified if filter is needed. It will be turned off')
                filter = false;
            end
            
            if numel(varargin) >= 2 && ~isempty(varargin{2}) && isempty(file_name) && isa(varargin{2},'struct')
                data = varargin{2};
            elseif numel(varargin) >= 2 && isempty(varargin{2}) && isempty(file_name)
                data = [];
            end
            
            if strcmp(type, 'idle')
                filter = false;
            end
            
            % read file if it exist
            
            if ~isempty(file_name) && isfile(file_name)
                data = load(file_name).data;
            end
            
            % write every element of data
            for index = 1:length(raw_data)
                
                block_name = erase(raw_data(index).blockName, 'Scope ');
                scope_handle = get_param(block_name, 'Handle');
                
                for i = 1:length(params)
                    if strcmpi(params{i,1}, 'FaultIn')
                        if getSimulinkBlockHandle([model, '/', params{i,2}]) > 0
                            fault_in_handle =  get_param([model, '/', params{i,2}], 'Handle');
                        elseif getSimulinkBlockHandle([model, '/', params{i,2}, 'Sep1']) > 0
                            fault_in_handle =  get_param([model, '/', params{i,2}, 'Sep1'], 'Handle');
                        else
                            error('Unknown block with fault - %s',[model, '/', params{i,2}])
                        end
                        
                        break
                    end
                end
                
                if filter
                    if strcmpi(type, 'fault')  && ~SimFunc.CheckFaultBranch(model, scope_handle, fault_in_handle)
                        type_bool = true;
                    else
                        type_bool = false;
                    end
                else
                    if strcmpi(type, 'fault')
                        type_bool = true;
                    else
                        type_bool = false;
                    end
                end
                
                if ~isempty(params)
                    params_struct = cell2struct(params, {'name', 'value'}, 2);
                else
                    params_struct = struct();
                end
                
                loads_struct = cell2struct(loads, {'block', 'active_power', 'inductive_power'}, 2);
                
                get_data = struct(    'U', raw_data(index).signals(2).values(1,:), ...
                    'I', raw_data(index).signals(1).values(1,:), ...
                    'scope', raw_data(index).blockName, ...
                    'status', type_bool, ...
                    'fault_params', params_struct, ...
                    'loads', loads_struct);
                
                % check if data didn't duplicate (by params, loads and
                % scope columns)
                save_flag = true;
                
                for i = 1:length(data)
                    if isequaln(data(i).fault_params, get_data.fault_params) && isequaln(data(i).loads, get_data.loads) && isequal(data(i).scope, get_data.scope)
                        save_flag = false;
                    end
                end
                
                if save_flag
                    data = [data, get_data]; %#ok<AGROW>
                end
                
            end
            % save data into new .mat file or rewrite old
            
            % if need to save file return [] and do save
            if ~isempty(file_name) && isfile(file_name)
                save(file_name, 'data')
                overwrite_data = [];
                % else return data struct
            elseif isempty(file_name)
                overwrite_data = data;
            end
            
        end
        
        
        function DataGenerator(file_name, models, type, permutate, varargin)
            % GeneratorCollector is collection of functions launches to
            % generate data
            %
            % Parameters:
            %   file_name [(string/char) or (array string 1x2)] - full name of .mat file (name to
            % create or already existing) to write data; if two file names are
            % specified, the first one will be with filtred data, second with
            % unfiltred
            %
            %   models [array of string/char] - array of name of simulink model
            % without file format
            %
            %   type [char] - 'fault' or 'idle'
            %
            %   permutate [bool] - if true loads will have randomly permutated power
            %
            %   varargin{1} =
            %       1) if type == 'fault'
            %           = combinations_fault [array of string] - array of combinations to
            % fault in phases (like AG, BCG etc)
            %       2) if type == 'idle'
            %           = N_repeat [int] - number of repeat idle generation
            %
            %   varargin{2} = Ron_range [array of doubles] - array of values of Fault Resistance
            %
            %   varargin{3} = Rg_range [array of doubles] - array of values of Ground Resistance
            %
            %   varagrin{4} = filter [bool] - flag to use filter of faults in
            % foreign branches or not
            %
            %   varargin{5} = blocks_random [bool] - flag to use N(varargin) random blocks (True)
            % or compute for all blocks in model (False)
            %
            %   varargin{6} = N [int] - number of random blocks to compute
            %
            %
            
            
            if strcmpi(type, 'fault')
                % parse input paramters for fault state
                
                nvarargin = numel(varargin);
                if nvarargin >= 1 && ~isempty(varargin{1})
                    combinations_fault = varargin{1};
                elseif nvarargin >= 1 && isempty(varargin{1})
                    
                    if SimFunc.show_warnings
                        warning('You selected fault mode and didnt specified combinations of faults')
                    end
                    
                    combinations_fault = "AG";
                end
                
                if nvarargin >= 2 && ~isempty(varargin{2})
                    Ron_range = varargin{2};
                elseif nvarargin >= 2 && isempty(varargin{2})
                    
                    if SimFunc.show_warnings
                        warning('You selected fault mode and didnt specified Ron range')
                    end
                    
                    Ron_range = 1;
                end
                
                if nvarargin >= 3 && ~isempty(varargin{3})
                    Rg_range = varargin{3};
                elseif nvarargin >= 3 && isempty(varargin{3})
                    
                    if SimFunc.show_warnings
                        warning('You selected fault mode and didnt specified Rg range')
                    end
                    
                    Rg_range = 1;
                end
                
                if nvarargin >= 4 && ~isempty(varargin{4})
                    filter = varargin{4};
                else
                    filter = false;
                    if SimFunc.show_warnings
                        warning('You didnt specified if filtration is needed, it will stay FALSE')
                    end
                end
                
                if nvarargin >= 5 && ~isempty(varargin{5})
                    blocks_random = varargin{5};
                elseif nvarargin >= 5 && isempty(varargin{5})
                    
                    if SimFunc.show_warnings
                        warning('You selected fault mode and didnt specified if blocks should select randomly')
                    end
                    
                    blocks_random = true;
                end
                
                if nvarargin >= 6 && ~isempty(varargin{6})
                    N = varargin{6};
                elseif blocks_random && nvarargin == 5
                    
                    if SimFunc.show_warnings
                        warning('You selected random blocks and didnt specified how much blocks to take, 50% of max would be taken')
                    end
                    
                    N = -0.1;
                end
                
                
                % count number of iterations
                if ~blocks_random
                    
                    fprintf('Started loading of models\n')
                    
                    N_blocks = 0;
                    for model = models
                        load_system('models/' + model)
                        N_blocks = N_blocks + length(find_system(model,'BlockType','SubSystem'));
                    end
                    total_iterations = length(combinations_fault)*length(Ron_range)*length(Rg_range)*N_blocks;
                    
                    % check if N exist and integer
                elseif ~isempty(N) && (mod(N,1) == 0)
                    total_iterations = length(combinations_fault)*length(Ron_range)*length(Rg_range)*length(models)*N;
                    % checi if N exist but not integer
                elseif ~isempty(N)
                    % then N = 50% of blocks in each model
                    N = 0;
                    for model = models
                        load_system(strcat('models/', model))
                        subsystems = find_system(model,'BlockType','SubSystem');
                        subsystems(:) = erase(subsystems(:), model + '/');
                        subsystems(strcmp(subsystems, 'powergui')) = [];
                        
                        N = N + floor(0.5*length(subsystems));
                    end
                    total_iterations = length(combinations_fault)*length(Ron_range)*length(Rg_range)*length(models)*N;
                end
                
            end
            
            % parse input parameters for idle state
            if strcmpi(type, 'idle')
                nvarargin = numel(varargin);
                if nvarargin >= 1 && ~isempty(varargin{1})
                    N_repeat = varargin{1};
                elseif nvarargin >= 1 && isempty(varargin{1})
                    warning('You selected idle mode and didnt specified number of repeatance')
                    N_repeat = 1;
                end
                
                % get number total of iterations
                total_iterations = length(models)*N_repeat;
                
            end
            
            
            if SimFunc.show_info_bar
                clc
                fprintf('Started loading of models\n')
            end
            
            if SimFunc.show_info_bar && exist('total_iterations', 'var')
                fprintf('\nTotal number of iterations would be %f', total_iterations)
            end
            
            % flag to count iterations
            flag = 0;
            
            t_prev_iteration = tic;
            
            % run cycles
            for model = models
                load_system(strcat('models/', model))
                load_system('models/fault')
                
                % try to add source to model
                try  %#ok<TRYNC>
                    SimFunc.AddSource(model)
                end
                if strcmpi(type, 'fault')
                    
                    for combination = combinations_fault
                        for Ron = Ron_range
                            for Rg = Rg_range
                                
                                % separate powergui from blocks and delete name of
                                % model from block name
                                subsystems = find_system(model,'BlockType','SubSystem');
                                subsystems(:) = erase(subsystems(:), model + '/');
                                subsystems(strcmp(subsystems, 'powergui')) = [];
                                
                                % load data from file_name
                                if length(string(file_name)) == 1
                                    if isfile(file_name)
                                        data = load(file_name).data;
                                    else
                                        data = [];
                                    end
                                elseif length(string(file_name)) == 2
                                    if isfile(file_name)
                                        data1 = load(file_name(1)).data;
                                    else
                                        data1 = [];
                                    end
                                    
                                    if isfile(file_name)
                                        data2 = load(file_name(2)).data;
                                    else
                                        data2 = [];
                                    end
                                else
                                    error('File names are in wrong format, %s getted', file_name)
                                end
                                
                                % random generation
                                if blocks_random
                                    if isempty(N) || ~(mod(N,1) == 0)
                                        N = floor(0.5*length(find_system(model,'BlockType','SubSystem')));
                                    elseif (mod(N,1) == 0) && N > length(subsystems)
                                        N = length(subsystems);
                                    end
                                    
                                    for repeat = 1:N
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %              Random fault
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
                                        t_last_iteration=toc(t_prev_iteration);
                                        
                                        flag = flag + 1;
                                        
                                        block_name = subsystems{ceil(rand*length(subsystems))};
                                        
                                        t_prev_iteration = tic;
                                        
                                        % Add Fault block
                                        
                                        [fault, line_sep] = SimFunc.FaultInLineDecorator(model, 'Fault', block_name);
                                        % create parameters structure
                                        parameters = {  'phases', char(combination);...
                                            'Ron', num2str(Ron);... % range=1e-9 ... 10
                                            'Rg', num2str(Rg);... % range=1e-9 ... 10
                                            'Rs', 1;... % adjusts to the stability of the solution
                                            'Cs', inf;... % adjusts to the stability of the solution
                                            'FaultIn', block_name;... % block where fault happens
                                            'LineSep', line_sep   }; % line separation coefficient
                                        
                                        
                                        if SimFunc.show_info_bar
                                            clc
                                            
                                            fprintf('Current porgress is %g/%g\n',flag, total_iterations)
                                            
                                            % progress bar
                                            fprintf('[')
                                            for i = 1:floor(flag/total_iterations*SimFunc.progress_bar_length)
                                                fprintf(char(9632))
                                            end
                                            for i = 1:(SimFunc.progress_bar_length - floor(flag/total_iterations*SimFunc.progress_bar_length))
                                                fprintf(char(9633))
                                            end
                                            fprintf(']\n')
                                          
                                            fprintf('\nRunning in random-mode, %g blocks for model\n', N)
                                            fprintf('Working on %s with fault on %s with parameters:\n', model, block_name)
                                            disp(parameters)
                                            
                                            fprintf('\nPrevious step complete in %g sec \n', t_last_iteration)
                                            
                                        end
                                        
                                        % Set up parameters of Fault block
                                        SimFunc.SetUpFault(fault, parameters)
                                        
                                        % Run simulation and collect data from scopes
                                        
                                        [raw_data, loads] = SimFunc.GetSimData(model, permutate);
                                        
                                        
                                        % Save data without saving to file
                                        % (filename is empty)
                                        
                                        if length(string(file_name)) == 1
                                            data = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, filter, data);
                                        elseif length(string(file_name)) == 2
                                            data1 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, true, data1);
                                            data2 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, false, data2);
                                        end
                                        
                                        
                                        % Delete created Fault block and separate
                                        % line
                                        SimFunc.FixLineSeparation(model)
                                        SimFunc.DeleteFault(model, 'Fault')
                                        
                                        
                                        
                                    end
                                else
                                    for index = 1:length(subsystems)
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            Non-Random fault
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
                                        t_last_iteration=toc(t_prev_iteration);
                                        
                                        flag = flag + 1;
                                        
                                        t_prev_iteration = tic;
                                        
                                        block_name = subsystems{index};
                                        
                                        [fault, line_sep] = SimFunc.FaultInLineDecorator(model, 'Fault', block_name);
                                        
                                        % create parameters structure
                                        parameters = {  'phases', char(combination);...
                                            'Ron', num2str(Ron);... % range=1e-9 ... 10
                                            'Rg', num2str(Rg);... % range=1e-9 ... 10
                                            'Rs', 1;... % adjusts to the stability of the solution
                                            'Cs', inf;... % adjusts to the stability of the solution
                                            'FaultIn', block_name;... % block where fault happens
                                            'LineSep', line_sep   }; % line separation coefficient
                                        
                                        
                                        if SimFunc.show_info_bar
                                            clc
                                            
                                            fprintf('Current porgress is %g/%g\n',flag, total_iterations)
                                            
                                            % progress bar
                                            fprintf('[')
                                            for i = 1:floor(flag/total_iterations*SimFunc.progress_bar_length)
                                                fprintf(char(9632))
                                            end
                                            for i = 1:(SimFunc.progress_bar_length - floor(flag/total_iterations*SimFunc.progress_bar_length))
                                                fprintf(char(9633))
                                            end
                                            fprintf(']\n')
                                            
                                            fprintf('Running in non-random-mode\n')
                                            fprintf('Working on %s with fault on %s with parameters:\n', model, block_name)
                                            disp(parameters)
                                            
                                            fprintf('\nPrevious step complete in %f sec \n', t_last_iteration)
                                            
                                        end
                                        
                                        
                                        
                                        
                                        % Set up parameters of Fault block
                                        SimFunc.SetUpFault(fault, parameters)
                                        
                                        % Run simulation and collect data from scopes
                                        
                                        [raw_data, loads] = SimFunc.GetSimData(model, permutate);
                                        
                                        % Save data in .mat file
                                        
                                        if length(string(file_name)) == 1
                                            data = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, filter, data);
                                        elseif length(string(file_name)) == 2
                                            data1 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, filter, data1);
                                            data2 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, filter, data2);
                                        end
                                        
                                        % Delete created Fault block and separate
                                        % line
                                        SimFunc.FixLineSeparation(model)
                                        SimFunc.DeleteFault(model, 'Fault')
                                        
                                        
                                        
                                    end
                                end
                                if SimFunc.show_info_bar
                                    fprintf('Started saving data\n')
                                end
                                if length(string(file_name)) == 1
                                    save(file_name, 'data')
                                elseif length(string(file_name)) == 2
                                    data = data1;
                                    save(file_name(1), 'data')
                                    data = data2;
                                    save(file_name(2), 'data')
                                end
                            end
                        end
                    end
                    
                end
                
                if strcmpi(type, 'idle')
                    
                    % load data from file_name
                    if length(string(file_name)) == 1
                        if isfile(file_name)
                            data = load(file_name).data;
                        else
                            data = [];
                        end
                    elseif length(string(file_name)) == 2
                        if isfile(file_name)
                            data1 = load(file_name(1)).data;
                        else
                            data1 = [];
                        end

                        if isfile(file_name)
                            data2 = load(file_name(2)).data;
                        else
                            data2 = [];
                        end
                    else
                        error('File names are in wrong format, %s getted', file_name)
                    end
                    
                    for repeat = 1:N_repeat
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %                        Idle
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        t_last_iteration=toc(t_prev_iteration);
                        
                        flag = flag + 1;
                        
                        if SimFunc.show_info_bar
                            clc
                            fprintf('Current porgress is %g/%g\n',flag, total_iterations)
                            
                            % progress bar
                            fprintf('[')
                            for i = 1:floor(flag/total_iterations*SimFunc.progress_bar_length)
                                fprintf(char(9632))
                            end
                            for i = 1:(SimFunc.progress_bar_length - floor(flag/total_iterations*SimFunc.progress_bar_length))
                                fprintf(char(9633))
                            end
                            fprintf(']\n')
                                            
                            fprintf('Running in idle-mode, %g blocks for model\n', N_repeat)
                            fprintf('Working on %s \n', model)
                            fprintf('\nPrevious step complete in %g sec \n', t_last_iteration)
                            
                        end
                        
                        t_prev_iteration = tic;
                        
                        % Run simulation and collect data from scopes
                        
                        [raw_data, loads] = SimFunc.GetSimData(model, permutate);
                        
                        parameters = [];
                        
                        % Save data in .mat file
                        if length(string(file_name)) == 1
                            data = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, data);
                        elseif length(string(file_name)) == 2
                            data1 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, data1);
                            data2 = SimFunc.ExportData(model, parameters, raw_data, [], type, loads, data2);
                        end
                    end
                    
                end
                
                % save data
                if SimFunc.show_info_bar
                    fprintf('Started saving data\n')
                end
                if length(string(file_name)) == 1
                    save(file_name, 'data')
                elseif length(string(file_name)) == 2
                    data = data1;
                    save(file_name(1), 'data')
                    data = data2;
                    save(file_name(2), 'data')
                end
                
                %save model
                save_system(strcat('models/', model))
                close_system(strcat('models/', model))
                close_system('models/fault')
                
            end
            
        end
        
        
    end
end

