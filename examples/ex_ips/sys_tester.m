x0 = [0.0 0.0 0.1 0.0];
u0 = 2;

tau = 0.02;

tmax = 20;
xold = x0;
u = u0;
x_evo = [x0];
t_evo = [0];
for t=0:tmax
    xnew = sys_post(xold, u);
    x_evo = [x_evo; xnew];
    t_evo = [t_evo; t];
    xold = xnew;
end

t_evo = tau*t_evo;

subplot(4,1,1)
plot(t_evo', x_evo(:,1))

subplot(4,1,2)
plot(t_evo', x_evo(:,2))

subplot(4,1,3)
plot(t_evo', x_evo(:,3))

subplot(4,1,4)
plot(t_evo', x_evo(:,4))