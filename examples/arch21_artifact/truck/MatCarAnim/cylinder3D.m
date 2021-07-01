function varargout = cylinder3D(R, N, r1, r2, varargin)
% A function to produce N-sided cylinder-coordinates based on the
% generator curve in the vector 'R'. The start & end points of the cylinder
% wil be defined by 'r1' and 'r2'. It is also possible to create only a 
% cylinder-cut/arg, starting at direction 'R2' with the angle 'theta_max'. 
% At the end the cylinder can be drawn ('isDrawn',1).
% 
% Input arguments
% -----------------------
% Mandatory:
% R ............... The vector of radii used to define the radius of
%                   the different segments of the cylinder.
% N ............... The number of points around the circumference.
% r1 .............. Vector of Start-position e.g. [0 0 0].
% r2 .............. Vector of End-position e.g. [1 0 0].
% 
% Optional arguments are to be passed in pairs {default value}:
% lengths ......... Vector of lengths for according radii {norm(r2-r1)/(m-1)}
% isClosed ........ Flag for generating bottom and top area {1}
% isLined ......... Flag for generating a bound-line {1}
% FaceColor ....... Color of cylinder {'g'}
% isGradColor ..... Apply a gradient-color
% EdgeColor ....... Color of Edge / Mesh {'none'}
% LineColor ....... Color of boundary-lines {'k'};
% LineWidth ....... Width of boundary-lines {1};
% isDrawn ......... Flag for drawing the cylinder with the <surf>-function, 
%                   (otherwise do it yourself with <surf(X,Y,Z)>) {1};
% FaceAlpha ....... Transparency 0...1 of the cilinder-faces {0}
% R2 .............. starting arg vector (linear independent vector (of v))
%                   {[0 -1 0]}
% theta_max ....... arg-angle of cylinder-circle-cut [rad] {2*pi}
%
% Output arguments
% -----------------------
% varargout ....... struct with handle and geomety-infos
%
% Call Examples
% -----------------------
% cylinder1 = cylinder3D([1 1.1 1.1 1 0.4 0.4],20,[1 0 0],[3 0 0],...
%             'lengths',[0.1 0.5 0.1 0 4]);
% cylinder2 = cylinder3D([1 1.1 1.1 1 0.4 0.4],20,[1 0 0],[3 0 0],...
%             'lengths',[0.1 0.5 0.1 0 4], ...
%             'FaceColor', 'y', ...
%             'LineWidth', 2, ...
%             'EdgeColor','k', ...
%             'R2', [0 0 1], ...
%             'theta_max', pi);
%
% See also: surf, line, ColorSpec
%
%  Author:     Johannes Stoerkle, Luigi Barone (small parts)
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich


%% set default values

% Default Values
lengths = [];
isClosed = 1;
isLined = 1;
FaceColor = 'g';
isGradColor = 0;
EdgeColor = 'none';
LineColor = 'k';
LineWidth = 1;
isDrawn = 1;
FaceAlpha = 1;

h_mantle = [];
h_area = [];
h_line = [];

% Parameters for cylinder-circle-cut
R2 = [0 -1 0];       % linear independent vector (of v)
theta_max = 2*pi;  
% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'lengths'
            lengths = varargin{h_};
        case 'isclosed'
            isClosed = varargin{h_};
        case 'islined'
            isLined = varargin{h_};
        case {'facecolor'}
            FaceColor = varargin{h_};
        case {'edgecolor'}
            EdgeColor = varargin{h_};
        case {'isgradcolor'}
            isGradColor = varargin{h_};
        case {'linecolor'}
            LineColor = varargin{h_};
        case {'linewidth'}
            LineWidth = varargin{h_};
        case {'isdrawn'}
            isDrawn = varargin{h_};
        case {'facealpha'}
            FaceAlpha = varargin{h_};
        case {'r2'}
            R2 = varargin{h_};
        case {'theta_max'}
            theta_max = varargin{h_};
        otherwise
        error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

% Set up an array of angles for the polygon.
theta = linspace(0,theta_max,N);

m = length(R);                 % Number of radius values supplied.

if m == 1                      % Only one radius value supplied.
    R = [R; R];                % Add a duplicate radius to make
    m = 2;                     % a cylinder.
end

X = zeros(m, N);               % Preallocate memory.
Y = zeros(m, N);
Z = zeros(m, N);
C = zeros(m, N);

x1=(r2-r1)/sqrt((r2-r1)*(r2-r1)');    %Normalized vector;
%cylinder axis described by: r(t)=r1+v*t for 0<t<1

% find linear independent vector (of v)
if rank([x1;R2]) == 1
    R2=[1 0 0];
end
if rank([x1;R2]) == 1
    R2=[0 0 1];
end
while rank([x1;R2]) == 1 %if linear dependent
    R2=rand(1,3); % find it randomly
end %if

if (R2*x1') == 0
    x2 = R2;
else
    x2 = x1-R2/(R2*x1');    %orthogonal vector to v
end %if
x2=x2/norm(x2);     %orthonormal vector to v
x3=cross(x1,x2);     %vector orthonormal to v and x2
x3=x3/norm(x3);

r1x=r1(1);r1y=r1(2);r1z=r1(3);
r2x=r2(1);r2y=r2(2);r2z=r2(3);
%vx=x1(1);vy=x1(2);vz=x1(3);
x2x=x2(1);x2y=x2(2);x2z=x2(3);
x3x=x3(1);x3y=x3(2);x3z=x3(3);

%time=linspace(0,1,m);
if isempty(lengths) || length(lengths)<m-1
    lengthsPos=linspace(0,1,m); %Generate cylinder-lengths automatically
else %Handle cylinder-lengths
    lengthsPos = 0;
    sum = 0;
    for idx=1:1:length(lengths)
        sum = sum + lengths(idx);
        lengthsPos = [lengthsPos sum];
    end
    lengthsPos = lengthsPos/sum; % calc in percent
end

% Calc Face-Mantle-Coordiantes
for j = 1 : m
  %t=time(j);
  t=lengthsPos(j);
  
  rx(j) = r1x+(r2x-r1x)*t;
  ry(j) = r1y+(r2y-r1y)*t;
  rz(j) = r1z+(r2z-r1z)*t;
  
  X(j, :) = rx(j)+R(j)*cos(theta)*x2x+R(j)*sin(theta)*x3x; 
  Y(j, :) = ry(j)+R(j)*cos(theta)*x2y+R(j)*sin(theta)*x3y; 
  Z(j, :) = rz(j)+R(j)*cos(theta)*x2z+R(j)*sin(theta)*x3z;
  if isGradColor
    C(j, :) = [N:-1:1];
  end
end

% top / bottom area
if isClosed==1 && N>2 %&& m==2
    X_j = [];
    Y_j = [];
    Z_j = [];
    for j = 1 : m
        X_C1=[];
        Y_C1=[];
        Z_C1=[];
        for idx = 2 : N+1
            X_C1=[X_C1 rx(j)];
            Y_C1=[Y_C1 ry(j)];
            Z_C1=[Z_C1 rz(j)];
        end

        X_idx=[];
        Y_idx=[];
        Z_idx=[];
        for idx = 2 : N %Number of cyrcle-nodes
            X_idx=[X_idx X(j,idx)];
            Y_idx=[Y_idx Y(j,idx)];
            Z_idx=[Z_idx Z(j,idx)];
        end %for
        X_idx=[X_idx X(j,2)];
        Y_idx=[Y_idx Y(j,2)];
        Z_idx=[Z_idx Z(j,2)];

        %Store Areas
        X_j{j}=[X_C1; X_idx];
        Y_j{j}=[Y_C1; Y_idx];
        Z_j{j}=[Z_C1; Z_idx];
    end %for
end %if

%Algorythm: draw triangles with surf-Command
%      p5
%   /   |  \
% p7 - p1 - p3
%       |  /
%      p2
%             p1=r1;
%             p2=[X(j,1) Y(j,1) Z(j,1)];
%             p3=[X(j,2) Y(j,2) Z(j,2)];
%             p5=[X(j,3) Y(j,3) Z(j,3)];
%             p7=[X(j,4) Y(j,4) Z(j,4)];
% 
%             X_=[p1(1) p1(1) p1(1) p1(1);...
%                 p2(1) p3(1) p5(1) p7(1)];
%             Y_=[p1(2) p1(2) p1(2) p1(2);...
%                 p2(2) p3(2) p5(2) p7(2)];
%             Z_=[p1(3) p1(3) p1(3) p1(3);...
%                 p2(3) p3(3) p5(3) p7(3)];
%             X = [X X_];
%             Y = [Y Y_];
%             Z = [Z Z_];

if isLined==1
    % Calc boundary-lines:
    for j = 1 : m
        X_l{j} = X(j,1:N);
        Y_l{j} = Y(j,1:N);
        Z_l{j} = Z(j,1:N);
    end %for
end %if

%Draw cylinder
if isDrawn==1
    hold on;
        % --- Mantle
        if isGradColor && ~isempty(C)
            h_mantle = surf(X,Y,Z,C,...
                'EdgeColor',EdgeColor,...
                'FaceAlpha',FaceAlpha);
        else
            h_mantle = surf(X,Y,Z,...
                'FaceColor',FaceColor,...
                'EdgeColor',EdgeColor,...
                'FaceAlpha',FaceAlpha);
        end %

        % --- Areas
        if isClosed==1
            % bottom & top - areas
            h_area = -1*ones(m,1);
            % bottom area
            h_area(1) = surf(X_j{1},Y_j{1},Z_j{1},...
            'FaceColor',FaceColor,...
            'EdgeColor',EdgeColor,...
            'FaceAlpha',FaceAlpha);
            % top area
            h_area(m) = surf(X_j{m},Y_j{m},Z_j{m},...
            'FaceColor',FaceColor,...
            'EdgeColor',EdgeColor,...
            'FaceAlpha',FaceAlpha);
        end %if
        
        if isLined==1
            %boundary-lines:
            h_line = zeros(m);
            for j = 1 : m
                h_line(j) = line(X_l{j},Y_l{j},Z_l{j},...
                    'Color',LineColor,'LineWidth',LineWidth);
            end %for
        end %if
        axis square;
    hold off;
end %if
% varargout
varargout{1}.R = R;
varargout{1}.N = N;
varargout{1}.r1 = r1;
varargout{1}.r2 = r2;

varargout{1}.color = FaceColor;

varargout{1}.x1 = x1;
varargout{1}.x2 = x2;
varargout{1}.x3 = x3;

if isDrawn==1
    varargout{1}.h_mantle = h_mantle;
    varargout{1}.h_area = h_area;
    varargout{1}.h_line = h_line;
end %if
varargout{1}.X = X;
varargout{1}.Y = Y;
varargout{1}.Z = Z;
if isGradColor
    varargout{1}.C = C;
end
if isClosed==1
    varargout{1}.X_j = X_j;
    varargout{1}.Y_j = Y_j;
    varargout{1}.Z_j = Z_j;
end %if
if isLined==1
    varargout{1}.X_l = X_l;
    varargout{1}.Y_l = Y_l;
    varargout{1}.Z_l = Z_l;
end
end %function
