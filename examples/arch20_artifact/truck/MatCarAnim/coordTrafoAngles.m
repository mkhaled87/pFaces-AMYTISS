function varargout = coordTrafoAngles(X,Y,Z, varargin)
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
% v_rot ........... point of application of the rotation {[0 0 0]}
% x_angle ......... rotation angle arround x-axes {0}
% y_angle ......... rotation angle arround y-axes {0}
% z_angle ......... rotation angle arround z-axes {0}
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
%     'x_angle',pi/2,...
%     'v_trans',v_trans);
%
% See also: axisRotation, norm, cross, dot
%
%  Author:     Johannes Stoerkle
%  Date:       13.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
v_trans = [0 0 0];
v_rot = [0 0 0];
x_angle = 0;
y_angle = 0;
z_angle = 0;

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'v_trans'
            v_trans = varargin{h_};
        case 'x_angle'
            x_angle = varargin{h_};
        case 'y_angle'
            y_angle = varargin{h_};
        case 'z_angle'
            z_angle = varargin{h_};
        case 'v_rot'
            v_rot = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

T_PTR = T_Matrix_YawPitchRoll(x_angle,y_angle,z_angle);

%% Apply Rotation with shifted rotation position
% r_ = T_PTR*r
for row=1:1:size(X,1)
    for col=1:1:size(X,2)    
        v_ = T_PTR*[X(row,col)-v_rot(1); ...
                    Y(row,col)-v_rot(2); ...
                    Z(row,col)-v_rot(3)];
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
varargout{4} = T_PTR(:,1);
varargout{5} = T_PTR(:,2);
varargout{6} = T_PTR(:,3);
end %function

function T_PTR = T_Matrix_YawPitchRoll(Psi,Theta,Phi)
% Rotation-Matrix of Yaw-Pitch-Roll
% http://en.wikipedia.org/wiki/Euler_angles

% X_1 Y_2 Z_3
T_PTR = [ ...
    cos(Theta)*cos(Phi), -cos(Theta)*sin(Phi), sin(Theta); ...
    cos(Psi)*sin(Phi) + cos(Psi)*sin(Theta)*sin(Phi), ...
    cos(Psi)*cos(Phi) - sin(Psi)*sin(Theta)*sin(Phi), ...
    -cos(Theta)*sin(Psi); ...
    sin(Psi)*sin(Phi) - cos(Psi)*cos(Phi)*sin(Theta), ...
    cos(Phi)*sin(Psi) + cos(Psi)*sin(Theta)*sin(Phi), ...
    cos(Psi)*cos(Theta)];

% % Z_1 Y_2 X_3
% T_PTR = [ ...
%     cos(Psi)*cos(Theta), ...
%     cos(Psi)*sin(Theta)*sin(Phi) - cos(Phi)*sin(Psi), ...
%     sin(Psi)*sin(Phi) + cos(Psi)*cos(Phi)*sin(Theta); ...
%     cos(Theta)*sin(Psi), ...
%     cos(Psi)*cos(Phi) + sin(Psi)*sin(Theta)*sin(Phi), ...
%     cos(Psi)*sin(Theta)*sin(Phi) - cos(Psi)*sin(Phi); ...
%     -sin(Theta), cos(Theta)*sin(Phi), cos(Theta)*cos(Phi)];

% (http://de.wikipedia.org/wiki/Eulersche_Winkel)
% T_PTR = [ ...
%    -cos(Theta)*cos(Phi), cos(Theta)*sin(Phi), -sin(Theta); ...
%     sin(Psi)*sin(Theta)*cos(Phi) - cos(Psi)*sin(Phi), ...
%     sin(Psi)*sin(Theta)*sin(Phi) + cos(Psi)*cos(Phi), ...
%     sin(Psi)*cos(Theta); ...
%     cos(Psi)*sin(Theta)*cos(Phi) + sin(Psi)*sin(Theta), ...
%     cos(Psi)*sin(Theta)*sin(Phi) - sin(Psi)*cos(Phi), ...
%     cos(Psi)*cos(Theta)];
end %function