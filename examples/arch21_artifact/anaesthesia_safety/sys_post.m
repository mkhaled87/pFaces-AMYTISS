%% The post function
function xp = sys_post(x, u, w)
    if nargin >= 2

        A = [0.8192, 0.0341, 0.0126, 0.0165, 0.9822, 0.0001, 0.0009, 1e-4, 0.9989];
        B = [0.1105, 0.0012, 0.0001];
        
        x0 = x(1);
        x1 = x(2);
        x2 = x(3);
        u0 = u(1);
        
        xx0 = x0*A(0+1) + x1*A(1+1) + x2*A(2+1) + u0*B(0+1);
        xx1 = x0*A(3+1) + x1*A(4+1) + x2*A(5+1) + u0*B(1+1);
        xx2 = x0*A(6+1) + x1*A(7+1) + x2*A(8+1) + u0*B(2+1);        
        
        xp = [xx0 xx1 xx2];

    else
        error('Invalid input !');
    end
end