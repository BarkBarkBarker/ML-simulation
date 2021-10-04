clear
clc
close all

% name of file to export data
file_name = 'data.mat';

% number of points in range of ground and phase resistance
N = 2;

% auxiliary value for displaying time 
t_start_iteration = tic;

models = ["GridN1", "GridN3", "GridN2", "GridN4"];
combinations = ["AG", "BG", "CG"];

Ron = logspace(-9,1,N);
Rg = logspace(-9,1,N);

SimFunc.GeneratorCollector(file_name, models, combinations, Ron, Rg, false);
