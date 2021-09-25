classdef SimFunc
    %SIMFUNC (simulation functions) is class-collection of functions to
    %simulate faults in simulink
    
    
    properties(Constant)
       show_time = true; 
    end
    
    methods(Static)
        
        function AddSource(model)
        % AddSource Adding Source to model if it wasn't there
        % (note in directory should be 'source.slx' with source blocks
        % Parameters:
        %   model [string/char] - name of simulink model without file format

            
            t1 = tic;
            
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
            
            
            load_system('source')
            
            % add blocks of source from 'source.slx'
            line_handle = add_block('source/Line 1', [model,'/Line'], 'MakeNameUnique','on');
            source_pc1_handle = add_block('source/Source PC1_TT2', [model,'/Source PC1_TT2']);           
            source_zn_handle = add_block('source/Source Zn', [model,'/Source Zn']);
            ground_handle = add_block('source/Ground',[model,'/Ground'], 'MakeNameUnique','on');
            
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



            % add block and move next to connected one
            connect_handle = get_param([model,'/',connect_to], 'Handle');
            fault_handle = add_block('sps_lib/Power Grid Elements/Three-Phase Fault', [model,'/',name]);
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


        function scopes = RunSim(model)
        % Run simulink model and get data from scopes
        % Parameters:
        %   model[string/char] - name of simulink model
        % Return:
        %   scopes[array of struct] - data received from scopes after simulation


            % run simulink
            t1 = tic;
            
            fprintf(2, '\nSTARTED COMPUTATION of %s.slx\n', model)
            sim(model); 
            
            if SimFunc.show_time
                fprintf('\nSimulation computed in %f sec\n', toc(t1))
            end

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
            
            % check if connect lines exist then delete (empty lines marks 
            % as [-1 -1 -1]
            
            if ~(get_param(handle,'LineHandles').LConn == [-1 -1 -1]) %#ok<BDSCA>
                delete_line(get_param(handle,'LineHandles').LConn)
            end
            
            delete_block(handle)
            
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
        
        
        
    end
end

