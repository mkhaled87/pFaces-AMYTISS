%% The post function
function xp = sys_post(x, u, w)
    if nargin == 2 || nargin == 3
        T = 0.0018;
        v = 100;
        L = 0.5;
        q = 0.5;
        
        x0 = x(1);
        x1 = x(2);
        x2 = x(3);

        u0 = u(1);
        u1 = u(2);

        xx0  = (1-(T*v/L))*x0 + (T*v/L)*x2 + 6*u0;
        xx1  = (1-(T*v/L) - q)*x1 + (T*v/L)*x0;
        xx2  = (1-(T*v/L))*x2 + (T*v/L)*x1 + 8*u1; 
        
        xp = [xx0 xx1 xx2];
        
        % zero-level saturation 
        xp(xp < 0) = 0;
        
        if nargin == 3
            warning('This model assumes no disturbance and supplied w is ignored !');
        end
    else
        error('Invalid input !');
    end
end