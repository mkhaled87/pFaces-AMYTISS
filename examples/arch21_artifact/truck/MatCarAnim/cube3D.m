function varargout = cube3D(varargin)
% A function to produce cube-coordinates based on the patch-command.
% At the end the cube can be drawn ('isDrawn',1).
% 
% Input arguments
% -----------------------
% Mandatory:
% 
% Optional arguments are to be passed in pairs {default value}:
% pos ............. position of the cube-midpoint{[0 0 0]}
% lengths ......... lengths [lx ly lz] of the cube{[1 1 1]}
% rgb_faces ....... Color of cube {[0.5 0.5 0.5]}
% FaceAlpha ....... Transparency 0...1 of the cube-faces {0}
% EdgeColor ....... Color of Edge / Mesh {'k'}
% isDrawn ......... Flag for drawing the cube with the <patch>-function, 
%                   (otherwise do it yourself with 
%                   <patch('Vertices',vertices,'Faces',faces,...
%                    'FaceVertexCData',rgb_cube,'FaceColor','flat'>) {1};
%
% Output arguments
% -----------------------
% varargout ....... struct with handle and geomety-infos
%
% Call Examples
% -----------------------
% cube1 = cube3D
% cube2 = cube3D('pos',[1 1 1],'lengths',[1 2 3],'rgb_faces','g')
%
% See also: patch, ColorSpec
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values

% midpoint
pos = [0 0 0];
lengths = [1 1 1]; 
rgb_faces = [0.5 0.5 0.5];
EdgeColor = 'k';
FaceAlpha = 1;
isDrawn = 1;

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'pos'
            pos = varargin{h_};
        case 'lengths'
            lengths = varargin{h_};
        case {'rgb_faces'}
            rgb_faces = varargin{h_};
        case {'edgecolor'}
            EdgeColor = varargin{h_};
        case {'facealpha'}
            FaceAlpha = varargin{h_};
        case {'isdrawn'}
            isDrawn = varargin{h_};
        otherwise
        error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

x = pos(1);
y = pos(2);
z = pos(3);

wx = lengths(1)/2;
wy = lengths(2)/2;
wz = lengths(3)/2;

% corners of the cube
vertices(:,1)=[x-wx;x+wx;x+wx;x-wx;x-wx;x+wx;x+wx;x-wx]; 
vertices(:,2)=[y-wy;y-wy;y+wy;y+wy;y-wy;y-wy;y+wy;y+wy]; 
vertices(:,3)=[z-wz;z-wz;z-wz;z-wz;z+wz;z+wz;z+wz;z+wz]; 

% define faces
faces = [1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8;1 2 3 4;5 6 7 8]; 

% define color
FaceVertexCData = zeros(6,3);
if ischar(rgb_faces)
    rgb_faces = colorspec2rgb(rgb_faces);
end 
for idx=1:6
    FaceVertexCData(idx,:) = rgb_faces;
end

% store all
cube.vertices = vertices;
cube.faces = faces;

if isDrawn
    % plot cube 
    cube.h_patch = patch('Vertices',vertices,...
          'Faces',faces,...
          'FaceVertexCData',FaceVertexCData,...
          'FaceColor','flat',...
          'FaceAlpha',FaceAlpha,...
          'EdgeColor',EdgeColor);
    cube.FaceVertexCData = FaceVertexCData;
    cube.FaceAlpha = FaceAlpha;
    cube.FaceColor = 'flat';
    cube.EdgeColor = EdgeColor;
    axis equal
end %if

% Return
varargout{1} = cube;
end %function
  