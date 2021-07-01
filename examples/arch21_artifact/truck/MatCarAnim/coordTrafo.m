function varargout = coordTrafo(X,Y,Z, varargin)
% Do a coordinate - transformation of X,Y,Z items, with the translation
% v_trans and the new x-direction v_xdir (rotation). The output n1
% will be in direction of v_xdir, n2 will be in the x-y-plane and n3 will
% be orthogonal to n1 & n2.
%
% Input arguments
% -----------------------
% Mandatory:
% X ............... skalar, vector or Matrix of x-coordinates
% Y ............... skalar, vector or Matrix of y-coordinates
% Z ............... skalar, vector or Matrix of z-coordinates
% 
% Optional arguments are to be passed in pairs {default value}:
% v_trans ......... vector of translation shift {[0 0 0]}
% v_xdir .......... direction of new x-axe (rotated) {[1 0 0]}
% v_rot ........... point of application of the rotation {[0 0 0]}
%
% xi_base ......... x-base of incomming coordinates {[1 0 0]}
% yi_base ......... y-base of incomming coordinates {[0 1 0]}
% zi_base ......... z-base of incomming coordinates {[0 0 1]}
%
% alpha ........... angle of rotation arround n1 [rad]
%
% Output arguments
% -----------------------
% X_ .............. skalar, vector or Matrix of new x-coordinates
% Y_ .............. skalar, vector or Matrix of new y-coordinates
% Z_ .............. skalar, vector or Matrix of new z-coordinates
% n1 .............. new x-base-vector
% n2 .............. new y-base-vector
% n3 .............. new z-base-vector
%
% Call Examples
% -----------------------
% [X_ Y_ Z_ n1 n2 n3] = coordTrafo(X,Y,Z, ...
%     'v_xdir',v_xdir,...
%     'v_trans',v_trans);
%
% [X_ Y_ Z_ n1 n2 n3] = coordTrafo(X,Y,Z, ...
%     'v_xdir',v_xdir,...
%     'v_trans',v_trans,...
%     'v_rot',v_rot,...
%     'alpha',alpha);
%
% See also: axisRotation, norm, cross, dot
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
v_trans = [0 0 0];
v_rot = [0 0 0];
v_xdir = [1 0 0];
alpha = 0;

% base of incomming coordinates
xi = [1 0 0];
yi = [0 1 0];
zi = [0 0 1];

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'v_trans'
            v_trans = varargin{h_};
        case 'v_xdir'
            v_xdir = varargin{h_};
        case 'v_rot'
            v_rot = varargin{h_};
        case 'xi_base'
            xi = varargin{h_};
        case 'yi_base'
            yi = varargin{h_};
        case 'zi_base'
            zi = varargin{h_};
        case 'alpha'
            alpha = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

% Ensure noralizes base
xi = 1/norm(xi)*xi;
yi = 1/norm(yi)*yi;
zi = 1/norm(zi)*zi;

% Check dimensions
if size(X,1)~=size(Y,1) && size(X,1)~=size(Z,1) && ...
        size(X,2)~=size(Y,2) && size(X,2)~=size(Z,2)
    error('Dimension of X,Y,Z must agree!')
end

%Init output Matrises
X_ = zeros(size(X));
Y_ = zeros(size(X));
Z_ = zeros(size(X));

%% transform base xi, yi, zi --> with v_xdir --> n1, n2, n3
% [x y z]' = x*xi' + y*xi' + z*xi';
% [x_ y_ z_]' = x*n1 + y*n2 + z*n3;
% n1 is the normalized vector in direction of v
% n2 is in x-y-plane (linear depend) and orthogonal to n1 (skalar-product)
% n3 is othogonal to n1 & n2 (cross-product)

% --- n1 ---
% nomalize n1 --> norm(n1)=1
n1 = 1/norm(v_xdir)*v_xdir;

% --- n2 ---
% n2 = lambda1*x + lambda2*y    % and
% n2*n1' = 0;                   %-->
if dot(xi,n1) ~= 0
    lambda2 = 1;
    lambda1 = -lambda2 * dot(yi,n1) / ...
                         dot(xi,n1);
    n2_ = lambda1*xi + lambda2*yi;
    % nomalize n2 --> norm(n2)=1
    n2 = 1/norm(n2_)*n2_;
else
    if n1(3)==0
        n2 = -xi;
    else
        n2 = xi;
    end %if
end
% Do rotation around n1 if userdefined
if alpha ~= 0
    n2 = axisRotation(n2,n1,alpha);
end
% othogonal-test
% dot(n2,n1)

% --- n3 ---
n3 = cross(n1,n2);
% --> norm(n3)=1

%% Apply Rotation From Trafo: xi, yi, zi --> with v_xdir --> n1, n2, n3
% [x y z]' = x*xi' + y*xi' + z*xi';
% [x_ y_ z_]' = x*n1' + y*n2' + z*n3';

for row=1:1:size(X,1)
    for col=1:1:size(X,2)     
        v_ = (X(row,col)-v_rot(1))*n1 + (Y(row,col)-v_rot(2))*n2 + ...
            (Z(row,col)-v_rot(3))*n3;
        X_(row,col)=v_(1);
        Y_(row,col)=v_(2);
        Z_(row,col)=v_(3);
    end %for
end %for

%% Apply Translation
for row=1:1:size(X,1)
    for col=1:1:size(X,2)
        X_(row,col)= X_(row,col) + v_trans(1) + v_rot(1);
        Y_(row,col)= Y_(row,col) + v_trans(2) + v_rot(2);
        Z_(row,col)= Z_(row,col) + v_trans(3) + v_rot(3);
    end %for
end %for

varargout{1} = X_;
varargout{2} = Y_;
varargout{3} = Z_;
varargout{4} = n1;
varargout{5} = n2;
varargout{6} = n3;
end