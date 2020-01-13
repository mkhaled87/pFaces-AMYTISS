%% The post function
function xp = sys_post(x, u, w)
    if nargin == 2
        xx1 = x(1) + 2*u(1)*cos(u(2));
        xx2 = x(2) + 2*u(1)*sin(u(2));
    elseif nargin == 3
        xx1 = x(1) + 2*u(1)*cos(u(2)) + w(1);
        xx2 = x(2) + 2*u(1)*sin(u(2)) + w(1);
    else
        error('Invalid input !');
    end
    xp = [xx1 xx2];
end