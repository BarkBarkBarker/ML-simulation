clear
clc
close all




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       all variable parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_name = "data.mat"; % name of file to export data
%models = ["Test1_1","Test1_2","Test1_3","Test2_1","Test2_2",]; 
models = "Test1_1";
combinations = ["AG", "BG", "CG"]; % combinations of phases to fault 
Ron = [5e-3, 1, 10000]; % fault resitance
Rg = [5e-3, 1, 10000]; % ground resitance
blocks_random = true; % choose random blocks for fault
N = 1; % number of random blocks to fault in model
permutate = true; % permutations of load power
N_repeat = 75; % number of repetitions for idle state
filter = true; % do filtration of foreign faults 


  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          run to get idle data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate idle state with permutations of power, repeated N_repeat time
% for models = ["Test2_1","Test2_2",]
%     file_name = [strcat(models, ".mat"), strcat(models, "_unfiltered.mat")];
%     SimFunc.DataGenerator(file_name, models, 'idle', permutate, N_repeat); 
% end
%file_name = ["data.mat", "data_unfiltered.mat"];
%N_repeat = 500;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              run to get fault data in random selection mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state and pick N random blocks from every model

%SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              run to get fault data in brute selection mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state for every block in every model

% blocks_random = false;
% SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               run to get fault data without filtration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state if selective protection isn't needed

% file_name = 'data_unfiltered.mat';
% filter = false;
% SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            run to get two data files w and w\o filtration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state if selective protection isn't needed

for folder = ["data/Single Phase-Ground IN/", "data/Single Phase-Ground GN/", "data/Single Phase-Phase IN/","data/Single Phase-Phase GN/"]
    for models = ["GridN1", "GridN2", "GridN3", "GridN4", "Test1_1", "Test1_2", "Test1_3", "Test2_1", "Test2_2"]

        load_system(strcat('models/',models))
        
        if contains(folder, "IN")
            set_param(strcat(models, '/Source Zn'), 'Resistance', '1e6') %ISOLATED
        else
            set_param(strcat(models, '/Source Zn'), 'Resistance', '1e-3') %GROUNDED
        end

        
        if contains(folder, "Phase-Phase")
            combinations = ["AB", "BC", "AC"]; % combinations of phases to fault
            Ron = [5e-3, 0.01, 1, 100, 10000]; % fault resitance
            Rg = [1]; % ground resitance
            N = 50;
        else
            combinations = ["AG", "BG", "CG"]; % combinations of phases to fault
            Ron = [5e-3, 1, 10000]; % fault resitance
            Rg = [5e-3, 1, 10000]; % ground resitance
            N = 5;
        end
        
        
        file_name = [strcat(folder, models, ".mat"), strcat(folder, models, "_unfiltered.mat")];
        filter = false; % if 2 files specified doesn't matter
        
        SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);
        file_name = [strcat(folder, models, ".mat"), strcat(folder, models, "_unfiltered.mat")];
        SimFunc.DataGenerator(file_name, models, 'idle', permutate, N_repeat); 
    end


    
end

for folder = ["Phase-Ground IN/", "Phase-Ground GN/", "Phase-Phase IN/","Phase-Phase GN/"]
    data = [];
    for models = ["GridN1", "GridN2", "GridN3", "GridN4", "Test1_1", "Test1_2", "Test1_3", "Test2_1", "Test2_2"]
        
        data = [data, load(strcat("data/Single ", folder, models, ".mat")).data];
        
        
    end
    
    save(strcat("data/Multiple ", folder, "Grids_Test.mat"), "data")
end

results = struct;
flag = 1;
for folder = ["Single Phase-Ground IN/", "Single Phase-Ground GN/", "Single Phase-Phase IN/","Single Phase-Phase GN/"]
    for models = ["GridN1", "GridN2", "GridN3", "GridN4", "Test1_1", "Test1_2", "Test1_3", "Test2_1", "Test2_2"]

        [error, net] = SimFunc.LearnDLT([30, 10, 5], strcat(folder, models, ".mat"), true);
        type = char(folder);
        results(flag).folder = type(13:end-1);
        results(flag).model = models;
        results(flag).error = error;
        results(flag).net = net;
        flag = flag+1;

    end
end
save('Net_50_30_20_10_5_all.mat', 'results')

