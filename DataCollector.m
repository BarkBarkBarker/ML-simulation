clear
clc
close all




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       all variable parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_name = "data.mat"; % name of file to export data
models = ["GridN4", "GridN3", "GridN2", "GridN1"]; 
combinations = ["AG", "BG", "CG"]; % combinations of phases to fault 
Ron = [5e-3, 0.1, 1, 100, 1000, 10000]; % fault resitance
Rg = [5e-3, 0.1, 1, 100, 1000, 10000]; % ground resitance
blocks_random = true; % choose random blocks for fault
N = 20; % number of random blocks to fault in model
permutate = true; % permutations of load power
N_repeat = 50; % number of repetitions for idle state
filter = true; % do filtration of foreign faults 




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          run to get idle data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate idle state with permutations of power, repeated N_repeat time

file_name = ["data.mat", "data_unfiltered.mat"];
SimFunc.DataGenerator(file_name, models, 'idle', permutate, N_repeat); 





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              run to get fault data in random selection mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state and pick N random blocks from every model

% SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              run to get fault data in brute selection mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate fault state for every block in every model

% blocks_random = false;
% SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);





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

% file_name = ["data.mat", "data_unfiltered.mat"];
% filter = false;
% N = 1;
% SimFunc.DataGenerator(file_name, models, 'fault', permutate, combinations, Ron, Rg, filter, blocks_random, N);





