function h = draw_chessboard(x_start,x_end,y_start,y_end,z_val,accuray,rgb_1,rgb_2,varargin)
% Draw a chessboard.
%
% Input arguments
% -----------------------
% Mandatory:
% x_start ......... startposition of the x-coordinate
% x_end ........... startposition of the x-coordinate
% y_start ......... startposition of the y-coordinate
% y_end ........... startposition of the y-coordinate
% accuray ......... accuray of the pattern-mesh size
% rgb_1 ........... rgb-color of first color
% rgb_2 ........... rgb-color of second color
%
% Optional arguments are to be passed in pairs {default value}:
% -----------------------
% edgecolor ....... edgecolor {'none'}
%
% Call Examples
% -----------------------
%    draw_chessboard(1,6,1,6,0,0.5,[0 0 0],[1 1 1])
%
% See also: patch , colormap
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

edgecolor = 'none';
% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'edgecolor'
            edgecolor = lower(varargin{h_}); 
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end


%accuray = 1;
delta_x = x_end-x_start;
delta_y = y_end-y_start;
countx =  round(min(delta_x,delta_y)*accuray)+1;
% check whether is uneven
if mod(countx,2) == 0 
    countx = countx+1;
end
county = countx;
x = x_start:delta_x/(countx-1):x_end; 
y = y_start:delta_y/(countx-1):y_end; 
z = z_val*ones(countx,county); 
c=z;
c(1:2:size(c,1)*size(c,2))=1; 

%figure(1); clf; 
hold on
h = surf(x,y,z,c,'FaceColor','flat','edgecolor',edgecolor); 
colormap([rgb_1 ; rgb_2])
hold off
% colormap('default')

end % function
%% test
% % corners 
% verts =[0 0;
%         0 1; ...
%         1 1; ...
%         1 0];
% faces = [ ...
%         1  2  3; ...
%         1  3  4];
% 
% FaceVertexCData = zeros(size(verts,1),3);
% rgb_color = [0 1 0];
% for idx=1:size(verts,1)
%     FaceVertexCData(idx,:) = rgb_color;
% end
% 
% % define patch
% patch('Vertices',verts,...
%           'Faces',faces,...
%           'FaceVertexCData',FaceVertexCData,'FaceColor','flat',...
%           'EdgeColor',rgb_color);
