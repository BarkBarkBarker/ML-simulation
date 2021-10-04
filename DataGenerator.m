clear
clc
close all

% name of file to export data
file_name = 'data.mat';

% arrays to compute
models = ["GridN1", "GridN3", "GridN2", "GridN4"];

combinations = ["AG", "BG", "CG"];

Ron = logspace(-9,1,5);

Rg = logspace(-9,1,5);

N = 20;

SimFunc.GeneratorCollector(file_name, models, combinations, Ron, Rg, false); % pick all possible blocks from every model

SimFunc.GeneratorCollector(file_name, models, combinations, Ron, Rg, true, N); % pick N random blocks from every model
