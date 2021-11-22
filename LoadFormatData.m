clear
clc

% load data and separate data related to SEP model
data = load('data.mat').data;
%data = [load('data.mat').data, load('data_test.mat').data];

UI_SEP = [];
UI = [];
status_SEP = [];
status = [];
models = '';

SEP = 'GridN0';

for index = 1:length(data)
    if contains(data(index).scope, SEP)
        UI_SEP(end+1, 1:6) = [data(index).U, data(index).I]; %#ok<SAGROW>
        status_SEP(end+1) = data(index).status;
    else
        UI(end+1, 1:6) = [data(index).U, data(index).I]; %#ok<SAGROW>
        status(end+1) = data(index).status;
        a = data(index).scope(1:6);
        if ~contains(models, a)
            % names of remaining models in data_
            models = strcat(models, a);
        end
    end
end
status = status';
status_SEP = status_SEP';

data_SEP = [real(UI_SEP), imag(UI_SEP)];
data_ = [real(UI), imag(UI)];



% load('model_test_compl.mat')
% data_SEP = data_;
% status_SEP = status;
% output = round(net(data_SEP'));
% diff = abs(output - status_SEP');
% error_percent = 100*length(diff(diff>0))/length(output)