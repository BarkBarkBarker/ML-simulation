clear
clc

% load data and separate data related to SEP model
data = load('data/data_unfiltered.mat').data;
%data = [load('data/data.mat').data, load('data/data_test.mat').data];

UI = [];

phases = [];

for index = 1:length(data)
    UI(end+1, 1:6) = [data(index).U, data(index).I]; %#ok<SAGROW>
    if ~isempty(fieldnames(data(index).fault_params))
        switch string(data(index).fault_params(1).value)
            case "AG"
                phases(end+1) = 1;
            case "BG"
                phases(end+1) = 2;
            case "CG"
                phases(end+1) = 3;
        end
    else
        phases(end+1) = 0;
    end
end

data_ = [real(UI), imag(UI)];

phases = phases';


n = [20];

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
[net,tr] = train(net, data_', phases');

% count error percentage

output = round(net(data_'));
diff = output - phases';
diff_abs = abs(diff);
error_percent = 100*length(diff_abs(diff_abs>0))/length(data)
fprintf('False activation take %g%%\n',length(diff(diff>0))/length(diff)*100)
fprintf('Non-triggering take %g%%\n',length(diff(diff<0))/length(diff)*100)
hold on
plot(diff)

