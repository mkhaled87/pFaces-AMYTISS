%% The post function
function x_post = sys_post(x, u, w)
    if nargin >= 2    
        Tau = 0.1;      % sampling_time for next state computation
        
        % solve th ode at Tau
        [ts, x_posts]=ode45(@sys_ode,[0 Tau], x, [], u);
    
        % return 
        x_post = x_posts(end,:);
    else
        error('Invalid input !');
    end
end

% Identfied ranges:
% sS:
%   ET:  1       1       0.05      0.05
%   UB: -50     -5      -0.5      -0.3
%   LB:  50      5       0.5       0.3

% iS:
%   ET:   1      0.05
%   UB:  60     -0.3
%   LB:  80      0.3

% prob_time: 10 to 50

function dx = sys_ode(t,x,u)

    L   = 1.5;      % Wheel base of the truck (from rear axle to front axle)
    d1  = 4.5;      % distance between rear axle of the trailer and the rear axle of the truck
    
    % states
    x0 = x(1);      % x
    x1 = x(2);      % y
    x2 = x(3);      % th_truck
    x3 = x(4);      % th_trailer 
    
    % inputs
    u0 = u(1);      % u_speed
    u1 = u(2);      % u_steer_angle
    
    
    % convert speed from kmh to mps
    u0 = u0*1000/3600;
    
    
    % the dynamics come from here:
    % http://planning.cs.uiuc.edu/node661.html#77556
    dx0 = u0*cos(x2);
    dx1 = u0*sin(x2);
    dx2 = (u0/L)*tan(u1);
    dx3 = (u0/d1)*sin(x3-x2);
    
    dx = [dx0; dx1; dx2; dx3];
    
end





