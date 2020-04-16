function varargout = coordTrafoCarUnit(carAnim,id, varargin)
% do a coordinate-transformation of the whole CarUnit and
% store Coordinates in .X_ .Y_ .Z_ , .X_j_, ... .X_l_, ... .Z_l_
% 
% Input arguments
% -----------------------
% Mandatory:
% carAnim ......... CarAnim-Struct
% id .............. carUnit.ID
% 
% Optional arguments are to be passed in pairs {default value}:
% z_angle ......... rotationangle around z-axe {0}
% x_angle ......... rotationangle around x-axe
% v_trans ......... vector of translation shift {[0 0 0]}
% v_rot ........... point of rotation
% mainobjName ..... the name of the main-object {units}
%
% Output arguments
% -----------------------
% varargout ....... carAnim
%
% Call Examples
% -----------------------
% carAnim_ = coordTrafoCarUnit(carAnim,id, ...
%     'v_xdir',v12,...
%     'v_trans',v1-v1_0,...
%     'v_rot', v1_0);
%
% See also: coordTrafo, updateCarUnitStruct
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
z_angle = 0;
x_angle = 0;
v_trans = [0 0 0];
v_rot = [0 0 0];

mainobjName = 'units';
    
% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'v_trans'
            v_trans = varargin{h_};
        case 'z_angle'
            z_angle = varargin{h_};
        case 'x_angle'
            x_angle = varargin{h_};
        case 'v_rot'
            v_rot = varargin{h_};
        case 'mainobjname'
            mainobjName = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

%% Work

% tranform all object coordinates from current id
fnames = fieldnames(carAnim.(mainobjName).(id)); 
% !!Be careful!! it is a Java String Object and a convertion with char() is neccessary

for idx=1:1:length(fnames)
    fname = char(fnames(idx));
    obj = carAnim.(mainobjName).(id).(fname);
    if iscell(obj) 
        for idx_cell = 1:length(obj)
            obj{idx_cell} = coordTrafo_obj(obj{idx_cell},z_angle,x_angle,v_trans,v_rot);
        end %for
    else
        obj = coordTrafo_obj(obj,z_angle,x_angle,v_trans,v_rot);
    end
    % Return
    carAnim.(mainobjName).(id).(fname) = obj;
end % for
    
% Return
varargout{1} = carAnim;
end %function

function obj = coordTrafo_obj(obj,z_angle,x_angle,v_trans,v_rot)

% Handle cylinder-mantle and general coordiantes 
    %/ Check existence of fields /if is a struct?
    if isfield(obj,'X') && isfield(obj,'Y') && isfield(obj,'Z')
        % Init transformed coordinates
        obj.X_ = []; obj.Y_ = []; obj.Z_ = [];
        
        if isfield(obj,'delta') && isfield(obj,'omega') && isfield(obj,'r1')  && isfield(obj,'r2')
            %obj is a wheel: apply spin and steer trafo: omega & delta
            % turning Trafo
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X, obj.Y, obj.Z, ...
                'y_angle',obj.omega,...
                'v_rot', (obj.r1+obj.r1)/2); 
            % steering Trafo
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X_, obj.Y_, obj.Z_, ...
                'z_angle',obj.delta, ...
                'v_rot', (obj.r1+obj.r1)/2); 
            % roll Trafo
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X_, obj.Y_, obj.Z_, ...
                'x_angle',x_angle);
             % Trafo with X_ Y_ Z_
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X_, obj.Y_, obj.Z_, ...
                'z_angle',z_angle,...
                'v_trans',v_trans,...
                'v_rot', v_rot);
        else % roll Trafo
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X, obj.Y, obj.Z, ...
                'x_angle',x_angle); 
            % normal Trafo
            [obj.X_ obj.Y_ obj.Z_] = coordTrafoAngles(obj.X_, obj.Y_, obj.Z_, ...
                'z_angle',z_angle,...
                'v_trans',v_trans,...
                'v_rot', v_rot); 
        end %end
    end
    % Handle areas-coordinates
    if isfield(obj,'X_j') && isfield(obj,'Y_j') && isfield(obj,'Z_j')
        % Init transformed coordinates
        obj.X_j_ = []; obj.Y_j_ = []; obj.Z_j_ = [];
        
        % Trafo
        for j = 1:1:length(obj.X_j)
            if isfield(obj,'delta') && isfield(obj,'omega') && isfield(obj,'r1')  && isfield(obj,'r2')
                %obj is a wheel: apply spin and steer trafo: omega & delta
                % turning Trafo
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles(obj.X_j{j}, obj.Y_j{j}, obj.Z_j{j}, ...
                    'y_angle',obj.omega,...
                    'v_rot', (obj.r1+obj.r1)/2); 
                % steering Trafo
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles(obj.X_j_{j}, obj.Y_j_{j}, obj.Z_j_{j}, ...
                    'z_angle',obj.delta, ...
                    'v_rot', (obj.r1+obj.r1)/2); 
                % roll Trafo
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles(obj.X_j_{j}, obj.Y_j_{j}, obj.Z_j_{j}, ...
                    'x_angle',x_angle);
                 % Trafo with X_ Y_ Z_
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles(obj.X_j_{j}, obj.Y_j_{j}, obj.Z_j_{j}, ...
                    'z_angle',z_angle,...
                    'v_trans',v_trans,...
                    'v_rot', v_rot);
            else % roll Trafo
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles( ...
                    obj.X_j{j}, obj.Y_j{j}, obj.Z_j{j}, ...
                    'x_angle',x_angle);
                % normal Trafo
                [obj.X_j_{j} obj.Y_j_{j} obj.Z_j_{j}] = coordTrafoAngles( ...
                    obj.X_j{j}, obj.Y_j{j}, obj.Z_j{j}, ...
                    'z_angle',z_angle,...
                    'v_trans',v_trans,...
                    'v_rot', v_rot);
            end %if
        end % for
    end

    % Handle lines-coordinates
    if isfield(obj,'X_l') && isfield(obj,'Y_l') && isfield(obj,'Z_l')
        % Init transformed coordinates
        obj.X_l_ = []; obj.Y_l_ = []; obj.Z_l_ = [];
        
        % Trafo
        for l = 1:1:length(obj.X_l)
            if isfield(obj,'delta') && isfield(obj,'omega') && isfield(obj,'r1')  && isfield(obj,'r2')
                %obj is a wheel: apply spin and steer trafo: omega & delta
                % turning Trafo
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles(obj.X_l{l}, obj.Y_l{l}, obj.Z_l{l}, ...
                    'y_angle',obj.omega,...
                    'v_rot', (obj.r1+obj.r1)/2); 
                % steering Trafo
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles(obj.X_l_{l}, obj.Y_l_{l}, obj.Z_l_{l}, ...
                    'z_angle',obj.delta, ...
                    'v_rot', (obj.r1+obj.r1)/2); 
                % roll Trafo
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles(obj.X_l_{l}, obj.Y_l_{l}, obj.Z_l_{l}, ...
                    'x_angle',x_angle);
                % Trafo with X_ Y_ Z_
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles(obj.X_l_{l}, obj.Y_l_{l}, obj.Z_l_{l}, ...
                    'z_angle',z_angle,...
                    'v_trans',v_trans,...
                    'v_rot', v_rot);
            else % normal Trafo
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles( ...
                    obj.X_l{l}, obj.Y_l{l}, obj.Z_l{l}, ...
                    'x_angle',x_angle);
                % normal Trafo
                [obj.X_l_{l} obj.Y_l_{l} obj.Z_l_{l}] = coordTrafoAngles( ...
                    obj.X_l_{l}, obj.Y_l_{l}, obj.Z_l_{l}, ...
                    'z_angle',z_angle,...
                    'v_trans',v_trans,...
                    'v_rot', v_rot);
            end %if
        end % for
    end

    % Handle text-coordinates
    if isfield(obj,'X_t') && isfield(obj,'Y_t') && isfield(obj,'Z_t')
        % Init transformed coordinates
        obj.X_t_ = []; obj.Y_t_ = []; obj.Z_t_ = [];
        
        % Trafo
        for t = 1:1:length(obj.X_t)
            % roll trafo
            [obj.X_t_{t} obj.Y_t_{t} obj.Z_t_{t}] = coordTrafoAngles( ...
                obj.X_t{t}, obj.Y_t{t}, obj.Z_t{t}, ...
                'x_angle',x_angle);
            % yaw trafo
            [obj.X_t_{t} obj.Y_t_{t} obj.Z_t_{t}] = coordTrafoAngles( ...
                obj.X_t_{t}, obj.Y_t_{t}, obj.Z_t_{t}, ...
                'z_angle',z_angle,...
                'v_trans',v_trans,...
                'v_rot', v_rot);
        end % for
    end
    
    % Handle patches
    if isfield(obj,'vertices')
        % roll Trafo
        [vX_ vY_ vZ_] = coordTrafoAngles( ...
            obj.vertices(:,1), obj.vertices(:,2), obj.vertices(:,3), ...
            'x_angle',x_angle);
        % yaw Trafo
        [vX_ vY_ vZ_] = coordTrafoAngles( ...
            vX_, vY_, vZ_, ...
            'z_angle',z_angle,...
            'v_trans',v_trans,...
            'v_rot', v_rot);
        obj.vertices_(:,1) = vX_;
        obj.vertices_(:,2) = vY_;
        obj.vertices_(:,3) = vZ_;
    end %if
end %function
