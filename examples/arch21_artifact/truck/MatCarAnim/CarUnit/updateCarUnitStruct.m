function carAnim = updateCarUnitStruct(carAnim,id,varargin)
% update all items (cylinder3d,lines...) of the carUnit-struct 
% with the id <id>. The following options are applicable: 
% -> calc the rotation-angle of the wheels
% -> do coord-Trafo of all coordinates (with r_cg & psi)
% and store Coordinates in the carAnim-Struct.
%
% !! This function does NOT apply a ReDraw, but only prepare and change the
% carAnim-struct !!
% 
% Input arguments
% -----------------------
% Mandatory:
% carAnim ......... carAnim-Struct
% id .............. carUnit.id
% 
% Optional arguments are to be passed in pairs {default value}:
% r_cg ............ Position of center of gravity (c.g.) {carUnit.r_cg}
% psi ............. Angle-of-attack (yaw angle) {carUnit.psi}
% phi ............. Angle around the longitudial axis (roll angle) {carUnit.phi}
%
% Output arguments
% -----------------------
% carAnim ......... CarAnim-Struct
%
% Call Examples
% -----------------------
% carAnim = updateCarUnitStruct(carAnim,carUnit.id,...
%                 [1;1;1],45*pi/180,...
%                 'alpha',alpha);
%
% See also: newCarUnit, coordTrafoCarUnit
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
% Default Geometric Values
% obtain current car-unit
carUnit = carAnim.units.(id);

r_cg = carUnit.r_cg;
psi = carUnit.psi;
phi = carUnit.phi;

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case {'r_cg'}
            r_cg = varargin{h_};
        case {'psi'}
            psi = varargin{h_};
        case {'phi'}
            phi = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

carUnit.r_cg = r_cg;
carUnit.psi = psi;
carUnit.phi = phi;

%% Prepare wheel rotation angle (omega)
% calc way
if ~isfield(carUnit,'r_cg_last')
    carUnit.r_cg_last = carUnit.r_cg0; %Store initial position as old
end

% Calc the angle of the movement and compare to carUnit.psi to decide: turn
% wheels forward or backwards
x_way = r_cg(1) - carUnit.r_cg_last(1);
y_way = r_cg(2) - carUnit.r_cg_last(2);
psi_r = atan2(y_way,x_way);
if carUnit.psi<=(psi_r+pi/2) && carUnit.psi>=(psi_r-pi/2)
    %drive forwards: calc way
    dr_way = norm(carUnit.r_cg-carUnit.r_cg_last);
else
    %drive backwards
    dr_way = -norm(carUnit.r_cg-carUnit.r_cg_last);
end

% store r_cg for next step
carUnit.r_cg_last = carUnit.r_cg;

if isfield(carUnit,'wheel_f')
    for idx = 1:length(carUnit.wheel_f)
        carUnit.wheel_f{idx}.omega = carUnit.wheel_f{idx}.omega + dr_way/carUnit.d_f(idx);
        if isfield(carUnit.wheel_f{idx},'r_way')
            carUnit.wheel_f{idx}.r_way = carUnit.wheel_f{idx}.r_way + dr_way;
        else
            carUnit.wheel_f{idx}.r_way = 0;
        end
    end %for
end %if
for idx = 1:length(carUnit.wheel_r)
    carUnit.wheel_r{idx}.omega = ...
        carUnit.wheel_r{idx}.omega + dr_way/carUnit.d_r(idx);
    if isfield(carUnit.wheel_r{idx},'r_way')
        carUnit.wheel_r{idx}.r_way = carUnit.wheel_r{idx}.r_way + dr_way;
    else
        carUnit.wheel_r{idx}.r_way = 0;
    end
end %for
% Return
carAnim.units.(id) = carUnit;

%% Apply trafo
carAnim = coordTrafoCarUnit(carAnim,id, ...
    'z_angle',psi,......
    'x_angle',phi,...
    'v_trans',r_cg,...
    'v_rot',[0 0 0]); %r_cg

% carAnim.units.(id).r_cg = r_cg;

end % END OF drawHydCal