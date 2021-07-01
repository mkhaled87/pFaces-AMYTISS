function varargout = axisRotation(x,v,alpha)
% Application of a Rotation matrix from axis and angle to any point 'x' 
% in 3D.
% For some calculations, it is helpful to be able to rotate a 
% coordinate 'x' arround a given axis 'v' with the angle alpha.
%
% Input arguments
% -----------------------
% Mandatory:
% x ............... point which should be rotated
% v ............... vector of axis from rotation
% alpha ........... angle of rotation [rad]
% 
% Optional arguments are to be passed in pairs {default value}:
% ................. 
%
% Output arguments
% -----------------------
% r ............... rotated vector 
%
% Call Examples
% -----------------------
% h = axisRotation(x,v,alpha)
%
% See also: coordTrafo, norm, dot, cross
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% Work
% nomalize n --> norm(n)=1
n = 1/norm(v)*v;

% Rotation matrix from axis and angle (see Wikipedia: Rotation matrix)
r = n*dot(n,x) + cos(alpha)*cross(cross(n,x),n) + sin(alpha)*cross(n,x);

% Return
varargout{1} = r;
end