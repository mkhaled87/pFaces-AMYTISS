function [carAnim id]= newCarUnit(carAnim,varargin)
% Specify and draw a new car unit (bicycle-model / Single-track model) 
% with default geometric values in percent, which are adjustable.
%
% Extention: flag_SngTrack = 1 --> axis with one wheel (Single-track model)
%            flag_SngTrack = 0 --> axis with two wheels
% 
% 
% Input arguments
% -----------------------
% Mandatory:
% carAnim ......... CarAnim-Struct
% 
% Optional arguments are to be passed in pairs {default value}:
% r_cg ............ Position of center of gravity (c.g.) {[0; 0; 0.275]}
% psi ............. Angle-of-attack (yaw angle) {0}
% phi ............. Angle around the longitudial axis (roll angle) {0}
% delta_f ......... steering angle of front wheel {0}
% delta_r ......... steering angle of rear wheels {0}
%
% --- geometric values in Percent % :
% l_f ............. array of distances from c.g. to front wheels {0.5}
% l_r ............. array of distances from c.g. to rear wheels {1}
% l_g ............. geometric wheelbase {l_f+l_r}
% l_h ............. distance from c.g. to hitch {[]}
% l_cf ............ distance from c.g. to front end {l_f*1.2%}
% l_cr ............ distance from c.g. to back end {l_r*1.2%}
% d_f ............. array of diameters front wheels {0.25%} 
% d_r ............. array of diameters of rear wheels {d_f}
% w_f ............. width of front wheel {0.08%}
% w_r ............. width of rear wheel {w_f}
% z_axes .......... distance of c.g. to axes in direction of z {0.25}
% flag_frontWheel . flag to create a front wheel {1}
% wheelProfile .... number of the wheel profile which should be used {1}
% flag_SngTrack ... flag to determine if the drawn unit shows a
%                   single-track model (axis=single wheel) or represents 
%                   axes with two wheels {1} 
% width_car ....... width of car-unit (used for cube_lengths and 
%                   non-single-track units with flag_SngTrack=0){1%}
% cube_lengths .... lengths [lx ly lz] of the cube {()}
% cube_shift ...... vector to shift the center of the cube against the c.g. 
%                   [x y z] {()}
% accuracy ........ ratio for the accuracy of the displayed Animation, for
%                   >1 then radius become smoother, longer calculation-time
%                   <1 then radius become sharper, shorter calculation-time
%                   {=1 --> N=20 points, defining a circle; =2 --> N=40)
%
% --- figure-settings & Colors:
% xlim ............ fixed x-axis range {auto}
% ylim ............ fixed y-axis range {auto}
% zlim ............ fixed z-axis range {auto}
% bound_LineWidth . LineWidth of the wheel-bound {1}
% bound_LineColor . LineColor of the wheel-bound {'k'}
% bound_isDrawn ... Flag, whether the wheel-bound-line should be drawn {1}
% rgb_w_f ......... cell-variable of Colors of front wheels {'g'}
% rgb_w_r ......... cell-variable of Colors of rear wheels {'g'}
% rgbEdge_w_f ..... cell-variable of Colors of front wheel edges{'k'}
% rgbEdge_w_r ..... cell-variable of Colors of rear wheel edges {'k'}
% FaceAlpha_w_f ... cell-variable FaceAlpha of front wheels {1}
% FaceAlpha_w_r ... cell-variable FaceAlpha of rear wheels {1}
% flag_Ksys ....... flag to draw a Ksys in the c.g. {1}
% rgb_Ksys ........ color of Ksys {'r'}
% rgb_body ........ face color of body {'b'}
% FaceAlpha_body .. FaceAlpha of body {1}
% rgb_cube ........ color of cube {}
% FaceAlpha_cube .. FaceAlpha of cube {0.1}
% rgb_hitch ....... color of hitch {'y'}
% scale ........... userdefined scale factor {l_r}
%
%
% Output arguments
% -----------------------
% carAnim ......... CarAnim-Struct
% id .............. carUnit.id
%
% Call Examples
% -----------------------
% [carAnim id1] = newCarUnit(carAnim);
% [carAnim id1] = newCarUnit(carAnim,'l_r',[0.6 0.8], ...
%                                    'l_h',0.95, ...
%                                    'delta_r', [20/180*pi 30/180*pi]);
% [carAnim id1] = newCarUnit(carAnim,'z_axes',1, ...
%                                    'r_cg',[0 0 1.325], ...
%                                    'l_f',l_1, ...
%                                    'l_h',l_2, ...
%                                    'l_r',l_3, ...
%                                    'rgb_cube','b');
% [carAnim id2] = newCarUnit(carAnim,'flag_frontWheel',0, ...
%                                    'z_axes',1, ...
%                                    'r_cg',[-l_2-b_1, 0, 1.325], ...
%                                    'l_f',b_1, ...
%                                    'l_r',[b_2 b_3 b_4] , ...
%                                    'd_r', carAnim.units.(id1).d_r, ...
%                                    'l_cr',b_4 + b_5, ...
%                                    'l_cf',b_1, ...
%                                    'scale',carAnim.units.(id1).scale, ...
%                                    'rgb_cube','r', ...
%                                    'rgb_w_r',{rgb_gray,rgb_gray,'g'});  
%
% Description:  Car Unit (Single-track-Model)
% -----------------------
%
%                                   l_g
%                 <--------------------------------------->
%                         l_r                  l_f
%                 <------------------>|<------------------>
%       hitch
%         |
%         v
%             wheel_r                 |                 wheel_f
%    A      |---------|               |               |---------|     A
% w_r|  --O-|    x    |-------------- O-----> --------|    x    |--   | w_f
%    v      |---------|                c.g.           |---------|     v
%
%
%                     l_h                                 d_f
%          <------------------------->|                <------->
%                   l_cr                           l_cf
%       <---------------------------->|<-------------------------->
%
% For two rear wheels: l_rm = (l_r(1) + l_r(2))/2;  l_g = l_r + l_f
%
%
% See also: cylinder3D, sphere_cg, updateCarUnitStruct, redrawCarAnim
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   04.04.2013 J. Storkle (extention: flag_SngTrack)
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values

% Default Geometric Values in percent --> l_g = 100% = 1
l_f     = [];               %distance from c.g. to front wheel
l_cf    = [];               %distance from c.g. to front end
l_r     = [];               %distance from c.g. to rear wheel
l_cr    = [];               %distance from c.g. to back end
l_h     = [];               %distance from c.g. to hitch

d_f     = [];               %diameter front wheel {0.25}
w_f     = [];               %width of front wheel {0.08}

d_r     = d_f;              %diameter of rear wheel
w_r     = w_f;              %width of rear wheel

z_axes = [];                %distance of c.g. to axes in direction of z

r_cg = [];                  %Position of center of gravity (c.g.) {[0; 0; 0]}
psi = 0;                    %Angle-of-attack (yaw angle)
phi = 0;                    %Angle around the longitudial axis (roll angle) {0}
delta_f = 0;                %steering angle of front wheel
delta_r = 0;                %steering angle of rear wheels

flag_frontWheel = 1;        %flag to create a front wheel
wheelProfile = 1;           %number of the wheel profile which should be used
flag_SngTrack = 1;          %flag to determine if the drawn unit shows a
                            % single-track model (axis=single wheel)
width_car = [];             %width of car-unit {1*scale}
cube_lengths = [];          %lengths of cube size
cube_shift = [];            %cube shift

bound_LineWidth = 1;        %LineWidth of unit-bound
bound_LineColor = 'k';
bound_isDrawn = 1;

rgb_w_f{1} =   'g';            %face color of front wheel
rgbEdge_wheel_f{1} = 'k';
FaceAlpha_w_f = 1;

rgb_w_r{1} = [0.8,0.8,0.8]; %face color of rear wheel
rgbEdge_wheel_r{1} = 'k';
FaceAlpha_w_r = 1;

flag_Ksys = 1;              %flag to draw a Ksys in the c.g.
rgb_Ksys = 'r';             %color of Ksys
rgb_body = 'b';             %face color of body
FaceAlpha_body = 1;
rgb_hitch = 'y';            %color of hitch
rgb_cube = [];              %color of cube
FaceAlpha_cube = 0.1;

scale = [];
% General parameters for production of cylinder
accuracy = 1; %20 points

xlim_ = [];
ylim_ = [];
zlim_ = [];

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case {'r_cg'}
            r_cg = varargin{h_};
        case {'psi'}
            psi = varargin{h_};
        case {'phi'}
            phi = varargin{h_};
        case {'delta_f'}
            delta_f = varargin{h_};
        case {'delta_r'}
            delta_r = varargin{h_};
        case {'l_f'}
            l_f = varargin{h_};
        case {'l_cf'}
            l_cf = varargin{h_};
        case {'l_r'}
            l_r = varargin{h_};
        case {'l_cr'}
            l_cr = varargin{h_};
        case {'l_h'}
            l_h = varargin{h_};
        case {'d_f'}
            d_f = varargin{h_};
        case {'w_f'}
            w_f = varargin{h_};
        case {'d_r'}
            d_r = varargin{h_};
        case {'w_r'}
            w_r = varargin{h_};
        case {'z_axes'}
            z_axes = varargin{h_};
        case {'flag_frontwheel'}
            flag_frontWheel = varargin{h_};
        case {'wheelprofile'}
            wheelProfile = varargin{h_};
        case {'flag_sngtrack'}
            flag_SngTrack = varargin{h_};
        case {'width_car'}
            width_car = varargin{h_};
        case {'cube_lengths'}
            cube_lengths = varargin{h_};
        case {'cube_shift'}
            cube_shift = varargin{h_};
        case {'rgb_w_f'}
            rgb_w_f = varargin{h_};
        case {'rgbedge_wheel_f'}
            rgbEdge_wheel_f = varargin{h_};
        case {'facealpha_w_f'}
            FaceAlpha_w_f = varargin{h_};
        case {'rgb_w_r'}
            rgb_w_r = varargin{h_};
        case {'rgbedge_wheel_r'}
            rgbEdge_wheel_r = varargin{h_};
        case {'facealpha_w_r'}
            FaceAlpha_w_r = varargin{h_};
        case {'flag_ksys'}
            flag_Ksys = varargin{h_};    
        case {'rgb_ksys'}
            rgb_Ksys = varargin{h_};
        case {'rgb_body'}
            rgb_body = varargin{h_};
        case {'facealpha_body'}
            FaceAlpha_body = varargin{h_};
        case {'rgb_cube'}
            rgb_cube = varargin{h_};
        case {'facealpha_cube'}
            FaceAlpha_cube = varargin{h_};
        case {'rgb_hitch'}
            rgb_hitch = varargin{h_};
        case {'accuracy'}
            accuracy = varargin{h_};
        case {'bound_linewidth'}
            bound_LineWidth = varargin{h_};
        case {'bound_linecolor'}
            bound_LineColor = varargin{h_};
        case {'bound_isdrawn'}
            bound_isDrawn = varargin{h_};
        case {'xlim'}
            xlim_ = varargin{h_};
        case {'ylim'}
            ylim_ = varargin{h_};
        case {'zlim'}
            zlim_ = varargin{h_};
        case {'scale'}
            scale = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

%% Prepare inputs
% Calc position & direction values & scale
if ~isempty(l_r)
    l_rm = sum(l_r)/length(l_r);
else
    l_rm = 1;
    l_r = 1;
end % if
if isempty(scale)
   scale = l_rm; 
end

if isempty(l_f)
    l_f = 0.5;
    l_fm = 0.5;
else
    l_fm = sum(l_f)/length(l_f);
    l_f = l_f/scale;
end %if
l_g = l_fm + l_rm;

if ~isempty(l_h) % otherwise do  not draw a hitch
    l_h = l_h/scale;
end %if
for idx = 1:length(l_r)
    l_r(idx) = l_r(idx)/scale;
end % for
if isempty(l_cf)
    l_cf = l_f*1.3;
else
    l_cf = l_cf/scale;
end %if
if isempty(l_cr)
    l_cr = 1.3;
else
    l_cr = l_cr/scale;
end %if
if isempty(z_axes)
    z_axes = 0.25;
else
    z_axes = z_axes/scale;
end %if
if isempty(d_f)
    d_f = 0.25;
else 
    d_f = d_f/scale;
end
if isempty(w_f)
    w_f = 0.08;
else 
    w_f = w_f/scale;
end
if isempty(d_r)
    d_r = 0.25;
else 
    d_r = d_r/scale;
end
if isempty(w_r)
    w_r = 0.08;
else 
    w_r = w_r/scale;
end
if isempty(r_cg)
    r_cg = [0 0 z_axes+d_f/2];
else
    r_cg = r_cg/scale;
end %if

% ### check multi-front-wheels conditions
if length(l_f) ~= length(d_f)
    d_f = ones(1, length(l_f))*d_f(1);
end % if
if length(l_f) ~= length(w_f)
    w_f = ones(1, length(l_f))*w_f(1);
end % if
if length(l_f) ~= length(rgb_w_f)
    for idx = 1:length(l_f)
        rgb_w_f{idx} = rgb_w_f{1};
    end % for
end % if
if length(l_f) ~= length(rgbEdge_wheel_f)
    for idx = 1:length(l_f)
        rgbEdge_wheel_f{idx} = rgbEdge_wheel_f{1};
    end % for
end % if
if length(l_f) ~= length(FaceAlpha_w_f)
    FaceAlpha_w_f = ones(1, length(l_f))*FaceAlpha_w_f(1);
end % if
if length(l_f) ~= length(delta_f)
    delta_f = ones(1, length(l_f))*delta_f(1);
end % if

% ### check multi-rear-wheels conditions
if length(l_r) ~= length(d_r)
    d_r = ones(1, length(l_r))*d_r(1);
end % if
if length(l_r) ~= length(w_r)
    w_r = ones(1, length(l_r))*w_r(1);
end % if
if length(l_r) ~= length(rgb_w_r)
    for idx = 1:length(l_r)
        rgb_w_r{idx} = rgb_w_r{1};
    end % for
end % if
if length(l_r) ~= length(rgbEdge_wheel_r)
    for idx = 1:length(l_r)
        rgbEdge_wheel_r{idx} = rgbEdge_wheel_r{1};
    end % for
end % if
if length(l_r) ~= length(FaceAlpha_w_r)
    FaceAlpha_w_r = ones(1, length(l_r))*FaceAlpha_w_r(1);
end % if
if length(l_r) ~= length(delta_r)
    delta_r = ones(1, length(l_r))*delta_r(1);
end % if

if isempty(width_car)
    width_car = 1;
end %if
%% Prepare Graph-Objects 
% Wheel - CYLINDERS start/end vectors in unit-fixed coordinate system
%[2x wheel_f; 
% 2x wheel_r{1};
% 2x wheel_r{2}; ...]

X_c = []; Y_c = []; Z_c = []; %Init
if flag_frontWheel
    if flag_SngTrack
        % Single-Track-Model --> axis = one wheel
        for idx = 1:length(l_f)
            X_c = [X_c; l_f(idx),  l_f(idx)];
            Y_c = [Y_c; -w_f(idx)/2, w_f(idx)/2];
            Z_c = [Z_c; -z_axes,    -z_axes];
        end %for
    else
        % Multi-Track-Model --> axis = two wheels
        l_fNew = []; d_fNew = []; w_fNew = []; FaceAlpha_w_fNew = []; 
        delta_fNew = [];  rgb_w_fNew = []; rgbEdge_wheel_fNew = [];
        for idx = 1:length(l_f)
            X_c = [X_c; l_f(idx),  l_f(idx); l_f(idx),  l_f(idx)];
            Y_c = [Y_c; -w_f(idx)/2-width_car/2, w_f(idx)/2-width_car/2; 
                        -w_f(idx)/2+width_car/2, w_f(idx)/2+width_car/2];
            Z_c = [Z_c; -z_axes,    -z_axes; -z_axes,    -z_axes];
            %copy/extent the paramters for both wheels
            l_fNew = [l_fNew, l_f(idx), l_f(idx)]; 
            d_fNew = [d_fNew, d_f(idx), d_f(idx)];
            w_fNew = [w_fNew, w_f(idx), w_f(idx)];
            FaceAlpha_w_fNew = [FaceAlpha_w_fNew, FaceAlpha_w_f(idx), FaceAlpha_w_f(idx)];
            delta_o = acot(cot(delta_f(idx))+width_car/(2*l_g));
            delta_i = acot(cot(delta_f(idx))-width_car/(2*l_g));
            delta_fNew = [delta_fNew, delta_o, delta_i];
            rgb_w_fNew{idx*2-1} = rgb_w_f{idx};
            rgb_w_fNew{idx*2} = rgb_w_f{idx};
            rgbEdge_wheel_fNew{idx*2-1} = rgbEdge_wheel_f{idx};
            rgbEdge_wheel_fNew{idx*2} = rgbEdge_wheel_f{idx};
        end %for     
        l_f = l_fNew; % Return extented parameters
        d_f = d_fNew;
        w_f = w_fNew;
        FaceAlpha_w_f = FaceAlpha_w_fNew;
        delta_f = delta_fNew;
        rgb_w_f = rgb_w_fNew;
        rgbEdge_wheel_f = rgbEdge_wheel_fNew;
    end
else %no front axis
end %if

if flag_SngTrack
    % Single-Track-Model --> axis = one wheel
    for idx = 1:length(l_r)
        X_c = [X_c; -l_r(idx),  -l_r(idx)];
        Y_c = [Y_c; -w_r(idx)/2, w_r(idx)/2];
        Z_c = [Z_c; -z_axes,    -z_axes];
    end %for
else
    % Multi-Track-Model --> axis = two wheels
    l_rNew = []; d_rNew = []; w_rNew = []; FaceAlpha_w_rNew = []; 
    delta_rNew = [];  rgb_w_rNew = []; rgbEdge_wheel_rNew = [];
    for idx = 1:length(l_r)
        X_c = [X_c; -l_r(idx),  -l_r(idx); -l_r(idx),  -l_r(idx)];
        Y_c = [Y_c; -w_r(idx)/2-width_car/2, w_r(idx)/2-width_car/2; 
                    -w_r(idx)/2+width_car/2, w_r(idx)/2+width_car/2];
        Z_c = [Z_c; -z_axes,    -z_axes; -z_axes,    -z_axes];
        %copy/extent the paramters for both wheels
        l_rNew = [l_rNew, l_r(idx), l_r(idx)]; 
        d_rNew = [d_rNew, d_r(idx), d_r(idx)];
        w_rNew = [w_rNew, w_r(idx), w_r(idx)];
        FaceAlpha_w_rNew = [FaceAlpha_w_rNew, FaceAlpha_w_r(idx), FaceAlpha_w_r(idx)];
        delta_o = acot(cot(delta_r(idx))+width_car/(2*l_g));
        delta_i = acot(cot(delta_r(idx))-width_car/(2*l_g));
        delta_rNew = [delta_rNew, delta_i, delta_o]; % switch i and o because of rear-steered wheel
        rgb_w_rNew{idx*2-1} = rgb_w_r{idx};
        rgb_w_rNew{idx*2} = rgb_w_r{idx};
        rgbEdge_wheel_rNew{idx*2-1} = rgbEdge_wheel_r{idx};
        rgbEdge_wheel_rNew{idx*2} = rgbEdge_wheel_r{idx};
    end %for     
    l_r = l_rNew; % Return extented parameters
    d_r = d_rNew;
    w_r = w_rNew;
    FaceAlpha_w_r = FaceAlpha_w_rNew;
    delta_r = delta_rNew;
    rgb_w_r = rgb_w_rNew;
    rgbEdge_wheel_r = rgbEdge_wheel_rNew;
end %if

% Apply scale-factor
X_c = scale*X_c;
Y_c = scale*Y_c;
Z_c = scale*Z_c;

if bound_isDrawn
    % POLYLINES coordinates (bound)
    X_1=[l_cf, -l_cr];
    Y_1=zeros(1,length(X_1));
    Z_1=-z_axes*ones(1,length(X_1));

    % Apply scale-factor
    X_1 = scale*X_1;
    Y_1 = scale*Y_1;
    Z_1 = scale*Z_1;
end % if

%% Create & Draw Graph-Objects
figure(carAnim.fig.h_fig);
hold on
% Define carUnit-Properties
carAnim.units.count = carAnim.units.count + 1;
carUnit.Name = strcat('CarUnit_',num2str(carAnim.units.count));
carUnit.id = strcat('CarUnit_',num2str(carAnim.units.count));
id = carUnit.id;

%% Work: Draw
% KSYS in c.g.
if flag_Ksys
    carUnit.Ksys = visualKsys([1;0;0], [0;1;0], [0;0;1], ...
            'Color',rgb_Ksys, ...
            'Ksize',0.15*scale, ...
            'h_fig', carAnim.fig.h_fig, ...
            'name',carUnit.Name, ...
            'v_shiftName', -0.08*scale*ones(1,3));
end %if

% WHEELS (cylinders)
N=accuracy*16; %Define the number of points around the circumference
x2 = [0 1 0];

% front wheels
if flag_frontWheel
    for idx = 1:length(l_f)
        [cyl_R_f, cyl_lengths_f] = handleWheelProfile(wheelProfile,scale,d_f(idx),w_f(idx));
        carUnit.wheel_f{idx} = cylinder3D(cyl_R_f,N, ...
            [X_c(idx,1) Y_c(idx,1) Z_c(idx,1)], ...
            [X_c(idx,2) Y_c(idx,2) Z_c(idx,2)],...
            'lengths', cyl_lengths_f, ...
            'FaceColor', rgb_w_f{idx}, ...
            'EdgeColor',rgbEdge_wheel_f{idx}, ...
            'FaceAlpha',FaceAlpha_w_f(idx), ...
            'LineWidth', 1,...
            'r2',x2,...
            'theta_max',2*pi);
        carUnit.wheel_f{idx}.delta = delta_f(idx);
        carUnit.wheel_f{idx}.omega = 0;
        fprintf(strcat('A front wheel with the radius of %f was created.\n'),d_f(idx)*scale/2);
    end %for
    % rear wheels: all the rest coordinates are for the rear wheels
    X_c = X_c(length(l_f)+1:size(X_c,1),:);
    Y_c = Y_c(length(l_f)+1:size(Y_c,1),:);
    Z_c = Z_c(length(l_f)+1:size(Z_c,1),:);
end % if

% rear wheels
for idx = 1:length(l_r)
    [cyl_R_r, cyl_lengths_r] = handleWheelProfile(wheelProfile,scale,d_r(idx),w_r(idx));
    carUnit.wheel_r{idx} = cylinder3D(cyl_R_r,N, ...
        [X_c(idx,1) Y_c(idx,1) Z_c(idx,1)], ...
        [X_c(idx,2) Y_c(idx,2) Z_c(idx,2)],...
        'lengths', cyl_lengths_r,...
        'FaceColor', rgb_w_r{idx}, ...
        'EdgeColor',rgbEdge_wheel_r{idx}, ...
        'FaceAlpha',FaceAlpha_w_r(idx), ...
        'LineWidth', 1,...
        'r2',x2,...
        'theta_max',2*pi);
    carUnit.wheel_r{idx}.delta = delta_r(idx);
    carUnit.wheel_r{idx}.omega = 0;
    fprintf(strcat('A rear wheel with the radius of %f was created.\n'),d_r(idx)*scale/2);
end % for
    
% Store additional info in structure
carUnit.l_f = l_f;
carUnit.l_r = l_r;
carUnit.l_g = l_g;
carUnit.l_h = l_h;
carUnit.l_f = l_f;
carUnit.d_f = d_f*scale;
carUnit.d_r = d_r*scale;
carUnit.w_f = w_f*scale;
carUnit.w_r = w_r*scale;

% BODY (sphere_cg)
% Sphere --> center of gravity (c.g.)
[X, Y, Z, handles, FaceColors] = sphere_cg(...
            'r',0.06*scale, ...
           'accuracy',accuracy,...
           'rgb_dark',rgb_body,...
           'rgb_light','w', ...
           'drawFlag',1,...
           'FaceAlpha',FaceAlpha_body);
for idx=1:length(handles)
    carUnit.body{idx}.h_mantle = handles(idx);
    carUnit.body{idx}.color = FaceColors{idx};
    carUnit.body{idx}.X = X{idx};
    carUnit.body{idx}.Y = Y{idx};
    carUnit.body{idx}.Z = Z{idx};
end %for

% CUBE
if ~isempty(rgb_cube) % draw the cube only, if user gives an color
    if isempty(cube_lengths) || length(cube_lengths)~=3
        % width_car = {1}
        cube_lengths = scale*[(X_1(1)-X_1(2))/scale width_car 0.9];
    else
        %cube_lengths(2) = width_car;
    end
    if isempty(cube_shift)
        cube_shift = [0 0 0];
    end %if
    carUnit.cube2 = cube3D('pos',[(X_1(1)+X_1(2))/2 0 0]+cube_shift, ...
                       'lengths',cube_lengths, ...
                       'rgb_faces',rgb_cube, ...
                       'FaceAlpha',FaceAlpha_cube);
end %if

% HITCH (sphere)
if ~isempty(l_h)
    [X, Y, Z] = sphere(10*accuracy);
    r_hitch = [-l_h, 0, -z_axes];
    X = (X*0.03 + r_hitch(1))*scale;
    Y = (Y*0.03 + r_hitch(2))*scale;
    Z = (Z*0.03 + r_hitch(3))*scale;
    carUnit.hitch.h_mantle = surf(X,Y,Z,'FaceColor', rgb_hitch, ...
                                        'EdgeColor','none');
    carUnit.hitch.color = rgb_hitch;
    carUnit.hitch.X = X;
    carUnit.hitch.Y = Y;
    carUnit.hitch.Z = Z;
end %if

% BOUND
if bound_isDrawn
    % POLYLINES (bound) & Store coordinates
    l.h_line = line(X_1,Y_1,Z_1,'Color','k','LineWidth',bound_LineWidth,...
        'Color',bound_LineColor);
    l.X_l{1} = X_1;
    l.Y_l{1} = Y_1;
    l.Z_l{1} = Z_1;
    carUnit.bound = l;
end %if

hold off
axis equal
if ~isempty(xlim_)
    set(carAnim.fig.h_axe,'xlim',xlim_);
end
if ~isempty(ylim_)
    set(carAnim.fig.h_axe,'ylim',ylim_);
end
if ~isempty(zlim_)
    set(carAnim.fig.h_axe,'zlim',zlim_);
end

% save carUnit
carUnit.scale = scale;   %scale value
carUnit.r_cg0 = r_cg*scale;    %position of center of gravity
carUnit.r_cg = r_cg*scale;     %position of center of gravity
carUnit.psi0 = psi;      %angle-of-attack (yaw angle)
carUnit.psi = psi;       %angle-of-attack (yaw angle)
carUnit.phi0 = phi;      %roll angle
carUnit.phi = phi;       %roll angle
carUnit.width_car = width_car*scale;
carAnim.units.(carUnit.id) = carUnit;
fprintf(strcat('The car-unit <%s> was created!\n'),carUnit.id);

%% Update position (Trafo etc.) and draw it
carAnim = updateCarUnitStruct(carAnim,carUnit.id);
%% Redraw object
redrawCarAnim(carAnim,'id',carUnit.id);

end % END OF FUNCTION

function [cyl_R, cyl_lengths] = handleWheelProfile(wheelProfile,scale,d_f,w_f)
    switch wheelProfile
        case 1
            % wheel profile: flat
            cyl_R = scale*d_f/2;
            cyl_lengths = scale*w_f;
        case 2
            % wheel profile: extended
            cyl_R = scale*[0.9*d_f/2, d_f/2, d_f/2, 0.9*d_f/2];
            cyl_lengths = scale*[0.15*w_f, 0.7*w_f, 0.15*w_f];
        case 3
            % wheel profile: more extended
            cyl_R = scale*[0.2*d_f/2, 0.2*d_f/2, 0.9*d_f/2, d_f/2, d_f/2, 0.9*d_f/2, 0.2*d_f/2, 0.2*d_f/2];
            cyl_lengths = scale*[0.05*w_f, 0, 0.1*w_f, 0.7*w_f, 0.1*w_f, 0, 0.05*w_f];
        otherwise
        	warning('The wheel profile number <%g> is not available!',wheelProfile)
    end % end
end