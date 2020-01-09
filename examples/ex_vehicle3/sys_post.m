%% The post function
function xp = sys_post(x, u)

    if nargin ~= 2
        error('Invalid input !');
    end 
    
    if size(x) ~= [1 3]
        error('Invalid size of x !');
    end     
    if size(u) ~= [1 2]
        error('Invalid size of u !');
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
        % rhs of $\dot x = f(x,u)$
        f(1) = u(1)*cos(atan((tan(u(2))/2.0))+xp(3))/cos(atan((tan(u(2))/2.0)));
        f(2) = u(1)*sin(atan((tan(u(2))/2.0))+xp(3))/cos(atan((tan(u(2))/2.0)));
        f(3) = u(1)*tan(u(2)); 

        % postd state for the given Ts
        xp = xp + Ts.*f;
    end
    
end