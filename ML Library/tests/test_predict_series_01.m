law_fnc = @(t)(sin(2*pi*t) + 0.25*sin(2*pi*3*sqrt(2)*t) + 0.1*t);

t = 0:0.02:16;
s = law_fnc(t);
learn_sz = 100;
learn_idx = 1:learn_sz;
[s2, m] = predict_series(s(learn_idx), ...
                         ceil(learn_sz/2), ...
                         length(s)-learn_sz);
plot(s2, 'b');
hold on;
plot(s, 'b.');
plot(s(learn_idx), 'rx');
legend('predict', 'real', 'learn');
hold off;