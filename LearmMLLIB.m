clear 
clc
close all

addpath('ML Library/core/');

%data = load('data_unfiltered.mat').data;
data = load('data.mat').data;

for index = 1:length(data)
    % fill matrix of input parameters to network 
    UI(index, 1:6) = [data(index).U, data(index).I]; %#ok<SAGROW>
end

% vector of answers
status = double([data(:).status]);

% proportion for train_dataset/total_dataset
prop = 0.9;
mse = [];

[mse, model] = calculate(prop, UI, status);


function [mse, model] = calculate(train_proportion, UI, status)
% Auxillary function to do learning and predict of neural network
%
% Parameters:
%   train_proportion [float] - part of total dataset, that will uset to train
%
%   UI [array of floats] - input parameters of neural network (voltage
% and current
%
%   status [vector of floats/bool] - answers for input parameters
%
% Return:
%   mse [float] - mean squared error for prediction
    
    % index permutations
    shuffle = randperm(length(UI));
    
    % shuffled arrays
    UI_shuffled = UI(shuffle,:);
    status_shuffled = status(shuffle);

    % separate arrays into train and test parts
    train_UI = UI_shuffled(1:ceil(length(UI_shuffled)*train_proportion),:);
    train_status = status_shuffled(1:ceil(length(status_shuffled)*train_proportion))';

    test_UI = UI_shuffled(ceil(length(UI_shuffled)*train_proportion)+1:end,:);
    test_status = status_shuffled(ceil(length(UI_shuffled)*train_proportion)+1:end)';

    % learn model
    model = learn(train_UI, train_status);
    
    % do prediction
    result = predict(model, test_UI);
    
    % get difference in prediction and real answers
    result_error = test_status-result;

%     plot(result_error)
%     xlabel('Index number')
%     ylabel('Error')
    
    mse = mean(result_error.^2);

    fprintf('MSE is %f\n', mse)
    answers = abs(round(result_error));
    
    fprintf('Accuracy is %f%%\n', length(answers(answers>0))/length(result))
    
end

