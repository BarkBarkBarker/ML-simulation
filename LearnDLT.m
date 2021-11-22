% number of hidden neurons in layers
%n = 50;
%n = [10, 10];
n = [30, 20, 10, 5, 1];

% get network with sigmoid activation
net = feedforwardnet(n);

% training function (LM - with validation; BR - without, 1000 epochs)
%net.trainFcn = 'trainlm';
net.trainFcn = 'trainbr';

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

output = round(net(data_'));
diff = output - status';
diff_abs = abs(diff);
error_percent = 100*length(diff_abs(diff_abs>0))/length(data)
fprintf('False activation take %g%%\n',length(diff(diff==1))/length(diff)*100)
fprintf('Non-triggering take %g%%\n',length(diff(diff==-1))/length(diff)*100)
% output = round(net(data_SEP'));
% diff = abs(output - status_SEP');
% error_percent = 100*length(diff(diff>0))/length(data)
