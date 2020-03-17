%% The post function
function xp = sys_post_2d(x, u, w)
    g = 9.81;
    m = 0.1314;
    l = 0.68;
    B = 0.06;
    tau = 0.02;
    
    t = ((3.0*g)/(2.0*l)); 
    n = (3.0/(2.0*l)); 
    k = ((3.0*B)/(m*l*l));
    
    if nargin == 2
        xx1 = x(1) + tau*x(2);
        xx2 = (1-tau*k)*x(2) - tau*n*cos(x(1))*u(1) + tau*t*sin(x(1));
    elseif nargin == 3
        xx1 = x(1) + tau*x(2) + w(1);
        xx2 = (1-tau*k)*x(2) - tau*n*cos(x(1))*u(1) + tau*t*sin(x(1)) + w(1);
    else
        error('Invalid input !');
    end
    xp = [xx1 xx2];
end