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
    Ts = 0.100;

    % decide a good solving step for this syste based on Ts
    % this is to be chosen imperically for each system and we use
    % matlab's ODE45 solver as a reference for error
    divider = 200;
    
    % now we have new Ts
    Ts = Ts / divider;
    
    xp = x;
    for k=1:divider
        % kinematic model for small velocities ?
        if abs(xp(4)) < 0.1
            %wheelbase
            lwb = 2.578913; 

            % rhs of $\dot x = f(x,u)$
            f(1) = xp(4)*cos(xp(5));
            f(2) = xp(4)*sin(xp(5));
            f(3) = u(1);
            f(4) = u(2);
            f(5) = xp(4)/lwb*tan(xp(3));
            f(6) = u(2)*lwb*tan(xp(3)) + xp(4)/(lwb*cos(xp(3))^2)*u(1);
            f(7) = 0;
        else

            % params
            mu = 1.048900;
            C_Sf = 20.898084; 
            C_Sr = 20.898084; 
            lf = 1.156195;
            lr = 1.422717;
            h = 0.613730;
            m = 1.093295e+03;
            I = 1.791599e+03;
            g = 9.81;

            % rhs of $\dot x = f(x,u)$
            f(1) = xp(4)*cos(xp(7) + xp(5));
            f(2) = xp(4)*sin(xp(7) + xp(5));
            f(3) = u(1);
            f(4) = u(2);
            f(5) = xp(6);
            f(6) = -mu*m/(xp(4)*I*(lr+lf))*(lf^2*C_Sf*(g*lr-u(2)*h) + lr^2*C_Sr*(g*lf + u(2)*h))*xp(6) ...
                +mu*m/(I*(lr+lf))*(lr*C_Sr*(g*lf + u(2)*h) - lf*C_Sf*(g*lr - u(2)*h))*xp(7) ...
                +mu*m/(I*(lr+lf))*lf*C_Sf*(g*lr - u(2)*h)*xp(3);
            f(7) = (mu/(xp(4)^2*(lr+lf))*(C_Sr*(g*lf + u(2)*h)*lr - C_Sf*(g*lr - u(2)*h)*lf)-1)*xp(6) ...
                -mu/(xp(4)*(lr+lf))*(C_Sr*(g*lf + u(2)*h) + C_Sf*(g*lr-u(2)*h))*xp(7) ...
                +mu/(xp(4)*(lr+lf))*(C_Sf*(g*lr-u(2)*h))*xp(3); 
        end    
        
        % post state for the given Ts
        xp = xp + Ts.*f;
    end
    
end