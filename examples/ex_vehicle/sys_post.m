%% The post function
function xp = sys_post(x, u)

    if nargin ~= 2
        error('Invalid input !');
    end 
    
    if size(x) ~= [1 7]
        error('Invalid size of x !');
    end     
    if size(u) ~= [1 2]
        error('Invalid size of x !');
    end         
        
    % sampling time
    Ts = 0.1;

    % kinematic model for small velocities ?
    if abs(x(4)) < 0.1
        %wheelbase
        lwb = 2.578912800000000; 

        % rhs of $\dot x = f(x,u)$
        f(1) = x(4)*cos(x(5));
        f(2) = x(4)*sin(x(5));
        f(3) = u(1);
        f(4) = u(2);
        f(5) = x(4)/lwb*tan(x(3));
        f(6) = u(2)*lwb*tan(x(3)) + x(4)/(lwb*cos(x(3))^2)*u(1);
        f(7) = 0;
    else

        % params
        mu = 1.048900000000000;
        C_Sf = 20.898083706740398; 
        C_Sr = 20.898083706740398; 
        lf = 1.156195706400000;
        lr = 1.422717093600000;
        h = 0.613730040000000;
        m = 1.093295233467405e+03;
        I = 1.791599530012286e+03;
        g = 9.81;

        % rhs of $\dot x = f(x,u)$
        f(1) = x(4)*cos(x(7) + x(5));
        f(2) = x(4)*sin(x(7) + x(5));
        f(3) = u(1);
        f(4) = u(2);
        f(5) = x(6);
        f(6) = -mu*m/(x(4)*I*(lr+lf))*(lf^2*C_Sf*(g*lr-u(2)*h) + lr^2*C_Sr*(g*lf + u(2)*h))*x(6) ...
            +mu*m/(I*(lr+lf))*(lr*C_Sr*(g*lf + u(2)*h) - lf*C_Sf*(g*lr - u(2)*h))*x(7) ...
            +mu*m/(I*(lr+lf))*lf*C_Sf*(g*lr - u(2)*h)*x(3);
        f(7) = (mu/(x(4)^2*(lr+lf))*(C_Sr*(g*lf + u(2)*h)*lr - C_Sf*(g*lr - u(2)*h)*lf)-1)*x(6) ...
            -mu/(x(4)*(lr+lf))*(C_Sr*(g*lf + u(2)*h) + C_Sf*(g*lr-u(2)*h))*x(7) ...
            +mu/(x(4)*(lr+lf))*(C_Sf*(g*lr-u(2)*h))*x(3); 
    end    
    % post state for the given Ts
    xp = x + Ts.*f;
    
end