clear
clc
close all

% name of file to export data
file_name = 'data.mat';

% number of points in range of ground and phase resistance
N = 3;

% auxiliary value for displaying time 
t_start_iteration = tic;

flag = 0;
% main cycles 
for model = ["GridN2", "GridN3", "GridN1", "GridN4"]
    
    %load current model
    load_system('models/' + model)
    
    % try to add source to model
    try  %#ok<TRYNC>
        SimFunc.AddSource(model)     
    end
    
    % get cell of all blocks to connect fault block
    blocks = find_system(model,'BlockType','SubSystem');
    
    % get rid of model/ prefix and powergui block
    blocks(:) = erase(blocks(:), model + '/');
    blocks(strcmp(blocks, 'powergui')) = [];
    
    %combinations of phases fault
    combinations = ["AG", "BG", "CG"];
    
    
    for block_index = 1:length(blocks)
        
        for Ron = logspace(-9,1,N)
            
            for Rg = logspace(-9,1,N)
                
                for comb_index = 1:length(combinations)
                    
                    flag = flag + 1;
                    
                    % auxiliary value for displaying time 
                    t_last_iteration = toc(t_start_iteration);
                    
                    % Fault parameters
                    parameters = {  'phases', char(combinations(comb_index));...
                                    'Ron', num2str(Ron);... % range=1e-9 ... 10
                                    'Rg', num2str(Rg);... % range=1e-9 ... 10
                                    'Rs', 1;... % adjusts to the stability of the solution 
                                    'Cs', inf;... % adjusts to the stability of the solution 
                                    'FaultIn', char(blocks{block_index})  }; % block where fault happens
                    
                    % show info about current computation
                    if SimFunc.show_info_bar
                        clc
                        fprintf('\n Current porgress is %g/%g',flag, 4*length(blocks)*N^2*length(combinations))
                        fprintf('\nWorking on %s with fault on %s with parameters:\n', model, blocks{block_index})
                        disp(parameters)
                        
                        fprintf('\nLast iteration complete in %f sec \n', t_last_iteration)
                    end
                    
                    % auxiliary value for displaying time 
                    t_start_iteration = tic;
                    
                    % run iteration
                    SimFunc.GeneratorCollector(model, parameters, file_name)
                end
            end
        end
    end
    
    % close simulink model
    save_system('models/' + model)
    close_system('models/' + model)
        
end

