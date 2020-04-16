function varargout = sphere_cg(varargin)
% The sphere_cg function generates the x-, y-, and z-coordinates of 
% eighth sphere parts for use with surf and mesh. It should characterize a
% center of gravity. If no ouput argument is expected, the sphere_cg will 
% be drawn.
%
% Optional arguments are to be passed in pairs {default value}:
% r ............... radius {1}
% accuracy ........ ratio for the accuracy of the displayed sphere, for
%                   >1 then radius become smoother, longer calculation-time
%                   <1 then radius become sharper, shorter calculation-time
%                   {=1 --> N=10 points, defining a circle; =2 --> N=20)
% N ............... Number of faces at each eighth part (~accuracy) {10}
% drawFlag ........ flag, whether the sphere should always be drawn {0}
% rgb_light ....... color of light eighth parts {[0.9 0.9 0.9]}
% rgb_dark ........ color of darkt eighth parts {k}
% FaceAlpha ....... FaceAlpha of the body
%
% Output arguments
% -----------------------
% varargout ....... [X, Y, Z, handles, FaceColors]
%
% Call Examples
% -----------------------
% sphere_cg;
% sphere_cg('r',5,'accuracy',0.5);
% [X Y Z] = sphere_cg('N',20);
% [X Y Z] = sphere_cg('N',20,'drawFlag',1);
%
% See also: sphere
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

r = 1;
accuracy = 1;

handles = [];
FaceColors = [];

N = [];
drawFlag = 0;
FaceAlpha = 1;
rgb_dark = 'k';
rgb_light = [0.9 0.9 0.9];

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case {'r'}
            r = varargin{h_};
        case 'accuracy'
            accuracy = varargin{h_};
        case {'n'}
            N = varargin{h_};
        case {'drawflag'}
            drawFlag = varargin{h_};
        case {'rgb_dark'}
            rgb_dark = varargin{h_};
        case {'rgb_light'}
            rgb_light = varargin{h_};
        case {'facealpha'}
            FaceAlpha = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

if isempty(N)
    N = accuracy *10;
end %if

% positiv y
idx = 1;
[theta,phi] = meshgrid(linspace(0,pi/2,N),linspace(-pi/2,0,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(1) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_dark,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(0,pi/2,N),linspace(0,pi/2,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(2) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_light,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(pi/2,pi,N),linspace(0,pi/2,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(4) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_dark,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(pi/2,pi,N),linspace(-pi/2,0,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(3) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_light,'EdgeColor','none')

% negative y

idx = idx+1;
[theta,phi] = meshgrid(linspace(0,pi/2,N),linspace(0,pi/2,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = -r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(6) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_dark,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(0,pi/2,N),linspace(-pi/2,0,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = -r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(5) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_light,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(pi/2,pi,N),linspace(-pi/2,0,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = -r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(7) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_dark,'EdgeColor','none')

idx = idx+1;
[theta,phi] = meshgrid(linspace(pi/2,pi,N),linspace(0,pi/2,N));
X{idx} = r.*cos(theta).*cos(phi);
Y{idx} = -r.*sin(theta).*cos(phi);
Z{idx} = r.*sin(phi);
%h(8) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_light,'EdgeColor','none')

if (drawFlag == 1) || (nargout == 0) % draw sphere, if no output-arg is expected
    % Create new figure or use current
    if isempty(findall(0,'Type','Figure'))
        figure;
        set(gca,'color','none'); %Disable axes-background-color
    else
        %clf;
            end
    hold on
        
    %Draw sphere-parts
    for idx = 1:2:7
        handles(idx) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_dark, ...
                                                 'EdgeColor','none',...
                                                 'FaceAlpha',FaceAlpha);
        FaceColors{idx} = rgb_dark;
    end % for
    for idx = 2:2:8
        handles(idx) = surf(X{idx},Y{idx},Z{idx},'FaceColor', rgb_light,...
                                                 'EdgeColor','none',...
                                                 'FaceAlpha',FaceAlpha);
        FaceColors{idx} = rgb_light;
    end % for
    %Print out handles and colors
    axis equal
end % if
varargout{1} = X;
varargout{2} = Y;
varargout{3} = Z;
varargout{4} = handles;
varargout{5} = FaceColors;
end
  