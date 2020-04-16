function Ksys = visualKsys(n1,n2,n3,varargin)
% visualize a Coordinate-system, defined by the normalized axis-vectors 
% n1,n2,n3
%
% Input arguments
% -----------------------
% Mandatory:
% n1,n2,n3 ........ normalized axis-vectors
% 
% Optional arguments are to be passed in pairs {default value}:
% h_fig ........... handle of a figure
% h_line .......... handles of existing n-axe-lines: [h_n1 h_n2 h_n3]
% h_text .......... handles of existing texts: [h_t1 h_t2 h_t3 h_tName]
% labels .......... user-defined text-labels {'n1','n2','n3','K_{sys}'}
% Color ........... axe-line color 'b'
% v_org ........... point of orgin of new coordinate-system
% name ............ name of coordinate-system label
% v_shiftName ..... shift-vector of Name
% Ksize ........... size of the coordinate-axis
%
% Output arguments
% -----------------------
% Ksys ............ struct with the properties of the coordinate system
%
% Call Examples
% -----------------------
% [h_fig h_n h_t] = visualKsys(n1, n2, n3);
%
% Ksys = visualKsys([1;0;0], [0;1;0], [0;0;1], ...
%             'v_org',[1;1;1], ...
%             'Color','r', ...
%             'Ksize',0.15*scale, ...
%             'h_fig', carAnim.fig.h_fig, ...
%             'labels',{'a1','a2','a3','name'})
%
% See also: line, text
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
h_fig = [];
h_line = [];
h_text = [];
color = 'b';
v_org = [0; 0; 0];
name = [];
h_tName = [];
Ksize = 1;
labels = [];
v_shiftName = [];

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'h_fig'
            h_fig = varargin{h_};
        case 'h_line'
            h_line = varargin{h_};
        case 'h_text'
            h_text = varargin{h_};
        case 'labels'
            labels = varargin{h_};
        case 'h_tname'
            h_tName = varargin{h_};
        case 'color'
            color = varargin{h_};
        case 'v_org'
            v_org = varargin{h_};
        case 'name'
            name = varargin{h_};
        case 'v_shiftname'
            v_shiftName = varargin{h_};
        case 'ksize'
            Ksize = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

%% Work:
% visualize:
if ~isempty(h_fig)
    if ishandle(h_fig)
        figure(h_fig);
    else
        h_fig=figure;
    end %if
else
    h_fig=figure;
end

% label the Initial-Coordiante-System
xlabel('x');
ylabel('y');
zlabel('z');

% check dim of n1 n2 n3
if size(n1,1) == 1 && size(n1,2) == 3
    n1 = n1';
elseif size(n1,1) == 3 && size(n1,2) == 1
    % n1 = n1;
else
    error('The dimension of n1 is wrong. It must be a 3-dim column-vector!');
end
if size(n2,1) == 1 && size(n2,2) == 3
    n2 = n2';
elseif size(n2,1) == 3 && size(n2,2) == 1
    % n2 = n2;
else
    error('The dimension of n2 is wrong. It must be a 3-dim column-vector!');
end
if size(n3,1) == 1 && size(n3,2) == 3
    n3 = n3';
elseif size(n3,1) == 3 && size(n3,2) == 1
    % n3 = n3;
else
    error('The dimension of n3 is wrong. It must be a 3-dim column-vector!');
end

% normalize n1 n2 n3
if norm(n1) ~= 1
    n1 = 1/norm(n1)*n1;
end %if
if norm(n2) ~= 1
    n2 = 1/norm(n2)*n2;
end %if
if norm(n3) ~= 1
    n3 = 1/norm(n3)*n3;
end %if

% shiftvector for position of labeling new axes
v_shift = [n1,n2,n3]*[0.1; 0.1; 0.1]*Ksize;

if isempty(v_shiftName)
    v_shiftName = -2*v_shift;
end %if
% coordinates of sys-axes with respect to the Isys
I_n1 = v_org+n1*Ksize;
I_n2 = v_org+n2*Ksize;
I_n3 = v_org+n3*Ksize;

% v_shift = [n1-v_org',n2-v_org',n3-v_org']*[0.03; 0.03; 0.03];

% Def line coordinates
X_l{1} = [v_org(1) I_n1(1)];
Y_l{1} = [v_org(2) I_n1(2)];
Z_l{1} = [v_org(3) I_n1(3)];
X_l{2} = [v_org(1) I_n2(1)];
Y_l{2} = [v_org(2) I_n2(2)];
Z_l{2} = [v_org(3) I_n2(3)];
X_l{3} = [v_org(1) I_n3(1)];
Y_l{3} = [v_org(2) I_n3(2)];
Z_l{3} = [v_org(3) I_n3(3)];
% Def text coordinates
X_t{1} = v_shift(1) + I_n1(1);
Y_t{1} = v_shift(2) + I_n1(2);
Z_t{1} = v_shift(3) + I_n1(3);
label{1} = 'n1';
X_t{2} = v_shift(1) + I_n2(1);
Y_t{2} = v_shift(2) + I_n2(2);
Z_t{2} = v_shift(3) + I_n2(3);
label{2} = 'n2';
X_t{3} = v_shift(1) + I_n3(1);
Y_t{3} = v_shift(2) + I_n3(2);
Z_t{3} = v_shift(3) + I_n3(3);
label{3} = 'n3';
% Ksys-main-label 
X_t{4} = v_org(1)+v_shiftName(1);
Y_t{4} = v_org(2)+v_shiftName(2);
Z_t{4} = v_org(3)+v_shiftName(3);
label{4} = 'K_{sys}';
if ~isempty(labels)
    if length(labels) == 4
        label = labels; % User user-defined labels
    end %if
end %if

if isempty(h_line) || isempty(h_text) || isempty(h_tName)
    % plot new axes and add text-labels
    for idx = 1:3
        h_line(idx) = line(X_l{idx}, Y_l{idx}, Z_l{idx},'Color',color);
        h_text(idx) = text(X_t{idx}, Y_t{idx}, Z_t{idx},label{idx},...
        'Color',color);
    end %for

    % Ksys-main-label 
    if ~isempty(name)
        label{4} = name; 
    end % if
    h_text(4) = text(X_t{4}, Y_t{4}, Z_t{4},label{4},'Color',color);
    
else %change existing axe-lines and text-label positions
    if length(h_line) == 3 && length(h_text) == 3 && length(h_tName) == 1
        if ishandle(h_n(1)) && ishandle(h_n(2)) && ishandle(h_n(3)) && ...
                ishandle(h_text(1)) && ishandle(h_text(2)) && ishandle(h_text(3)) ...
                && ishandle(h_tName)
            % change axes-lines
            for idx = 1:3
                set(h_line(idx),'XData',X_l{idx},'YData', Y_l{idx}, ...
                    'ZData', Z_l{idx},'Color',color);
                set(h_text(idx),'Position', ...
                    [X_t{idx}, Y_t{idx}, Z_t{idx}],...
                    'Color',color);
            end %for
            
            % change text label
            if ~isempty(name)
                label{4} = name; 
                set(h_text(4),'String', label{4});
            end %if
            % change main-text-position
            set(h_text(4),'Position', [X_t{4}, Y_t{4}, Z_t{4}],'Color',color);
        else
            error('The h_line & h_text & h_tName -elements must be line and text handles!');
        end
    else
        error('The number of h_line & h_text -elements must be 3 and h_tName must be specified!');
    end %if
end %if

% output:
Ksys.h_line = h_line;
Ksys.X_l = X_l;
Ksys.Y_l = Y_l;
Ksys.Z_l = Z_l;
Ksys.X_t = X_t;
Ksys.Y_t = Y_t;
Ksys.Z_t = Z_t;
Ksys.h_text = h_text;
Ksys.label = label;
Ksys.color = color;

end