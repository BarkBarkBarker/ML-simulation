num = 40;
x = unique(rand(num, 1));
y = sin(2*pi*x) + 0.25*sin(6*pi*x);
model = learn(x, y);
if ~isempty(model)
    X = (-2:0.01:2).';
    Y = predict(model, X);
    plot(X, Y, 'b');
    hold on
    plot(x, y, 'rx');
end
    