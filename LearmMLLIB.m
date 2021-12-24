clear 
clc
close all

addpath('ML Library/core/');

%data = load('data_unfiltered.mat').data;
data = load('data/data.mat').data;

for index = 1:length(data)
    % fill matrix of input parameters to network 
    UI(index, 1:6) = [data(index).U, data(index).I]; %#ok<SAGROW>
end

% vector of answers
status = double([data(:).status]);

% proportion for train_dataset/total_dataset
props = 0.59:0.1:0.99;
accuracys = [];

for prop = props
    [accuracy, model] = calculate(prop, UI, status);
    accuracys = [accuracys, accuracy];
end
plot(props, accuracys)
xlabel('Dataset part taken')
ylabel('Error[%]')

function [accuracy, model] = calculate(train_proportion, UI, status)
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
    %result = predict(model, test_UI);
    result = round(predict(model, test_UI));
    
    % get difference in prediction and real answers
    result_error = abs(test_status-result);

%     plot(result_error)
%     xlabel('Index number')
%     ylabel('Error')
    
    accuracy = length(result_error(result_error>0))/length(result)*100;
    diff = test_status-result;
    fprintf('False activation take %g%%\n',length(diff(diff==1))/length(diff)*100)
    fprintf('Non-triggering take %g%%\n',length(diff(diff==-1))/length(diff)*100)

%     fprintf('MSE is %f\n', mse)
%     answers = abs(round(result_error));
%     
%     fprintf('Accuracy is %f%%\n', length(answers(answers>0))/length(result))
    
end

