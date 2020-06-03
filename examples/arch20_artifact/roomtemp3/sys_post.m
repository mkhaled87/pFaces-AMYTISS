%% The post function
function xp = sys_post(x, u, w)
    if nargin == 2

        eta = 0.20;
        beta = 0.022;
        gamma = 0.05; 
        a = 1.0 - 2.0*eta - beta;
        T_h = 50.0;
        T_e = -1.0;
        
        x0 = x(1);
        x1 = x(2);
        x2 = x(3);
        u0 = u(1);
        u1 = u(2);
        
        xx0 = (a - gamma*u0)*x0 + eta*(x1 + x2) + gamma*T_h*u0 + beta*T_e;
        xx1 = a*x1 + eta*(x0 + x2) + beta*T_e;
        xx2 = (a - gamma*u1)*x2 + eta*(x0 + x1) + gamma*T_h*u1 + beta*T_e;
        
        xp = [xx0 xx1 xx2];

    else
        error('Invalid input !');
    end
end