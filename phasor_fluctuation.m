clear
clc


% load data and separate data related to SEP model
data = load('data.mat').data;
%data = load('data_unfiltered.mat').data;

UI_SEP = [];
UI = [];
status_SEP = [];
status = [];
models = '';

SEP = 'GridN1';

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


% number of hidden neurons in layers
% n = 15;
n = [10, 10];
%n = [30, 20, 10, 5, 1];

% get network with sigmoid activation
net = feedforwardnet(n);

% training function (LM - with validation; BR - without, 1000 epochs)
net.trainFcn = 'trainlm';
%net.trainFcn = 'trainbr';

% parameters of dividing dataset
net.divideFcn = 'dividerand';
net.divideMode = 'sample'; 
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

% loss function
net.performFcn = 'mse';

%train
[net,tr] = train(net, data_', status');

% count error percentage
output = round(net(data_SEP'));
diff = abs(output - status_SEP');
error_percent_source = 100*length(diff(diff>0))/length(output)


error_percent = [];

percents = 0.1:0.1:3;

for perm_percent = percents
    error_percent = [error_percent, fluct(perm_percent, error_percent_source, UI_SEP, status_SEP, net)];
end
plot(percents, error_percent)
xlabel('percent fluctuation')
ylabel('error diff[%]')

function error_percent = fluct(perm_percent, error_percent_source, UI_SEP, status_SEP, net)
    for i = 1:length(UI_SEP)
       magnitudes(1:3) = abs(UI_SEP(i, 1:3));
       angle = rand * 2 * pi;
       UI_fluct(i, 1:3) = UI_SEP(i, 1:3) + perm_percent*mean(magnitudes)*(cos(angle) + 1i*sin(angle));
       UI_fluct(i, 4:6) = UI_SEP(i, 4:6);
    end

    data_fluct = [real(UI_fluct), imag(UI_fluct)];


    output = round(net(data_fluct'));
    diff = abs(output - status_SEP');
    error_percent = 100*length(diff(diff>0))/length(output) - error_percent_source;
end




