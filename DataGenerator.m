clear
clc
close all

% name of file to export data
file_name = 'data.mat';

% arrays to compute
models = ["GridN4", "GridN3", "GridN2", "GridN1"];

combinations = ["AG", "BG", "CG"];

Ron = logspace(-9,1,5);

Rg = logspace(-9,1,5);

% number of random blocks in model
N = 20;

% number of repetitions for idle state
N_repeat = 10;

% calculate fault state and pick all possible blocks from every model
%SimFunc.DataGenerator(file_name, models, 'fault', true, combinations, Ron, Rg, false); 


% calculate idle state with permutations of power, repeated N_repeat time
%SimFunc.DataGenerator(file_name, models, 'idle', true, N_repeat); 


 % calculate fault state and pick N random blocks from every model
SimFunc.DataGenerator(file_name, models, 'fault', true, combinations, Ron, Rg, true, N);