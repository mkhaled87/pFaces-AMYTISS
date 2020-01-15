%% The post function
function xp = sys_post(x, u, w)
    if nargin == 2

        eta = 0.30;
        beta = 0.022;
        gamma = 0.05; 
        a = 1.0 - 2.0*eta - beta;
        T_h = 50.0;
        T_e = -1.0;
        
        x0 = x(1);
        x1 = x(2);
        x2 = x(3);
        x3 = x(4);
        x4 = x(5);
        u0 = u(1);
        u1 = u(2);
        

        xx0 = (a - gamma*u0)*x0 + eta*(x4 + x1) + gamma*T_h*u0 + beta*T_e;
        xx1 = a*x1 + eta*(x0 + x2) + beta*T_e;
        xx2 = (a - gamma*u1)*x2 + eta*(x1 + x3) + gamma*T_h*u1 + beta*T_e;
        xx3 = a*x3 + eta*(x2 + x4) + beta*T_e;
        xx4 = a*x4 + eta*(x3 + x0) + beta*T_e;
        
        xp = [xx0 xx1 xx2 xx3 xx4];

    else
        error('Invalid input !');
    end
end