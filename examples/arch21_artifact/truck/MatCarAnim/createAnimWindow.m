function carAnim = createAnimWindow(carAnim,varargin)
% Create a new figure or take current an name it 'MatcarAnim'
%
% Input arguments
% -----------------------
% Mandatory:
% carAnim ......... carAnim-Struct (created with newCarAnim)
% 
% Optional arguments are to be passed in pairs {default value}:
% h_fig ........... handle of an existing figure {gcf}
% Name ............ Name of animation-window {MatcarAnim}
% subplot ......... creates the MatcarAnim-visualisation in the subplot
%                   according the subplot-function parameters [m,n,p] {[]}
% colorbar ........ Creates an colorbar with the given limit [cLow, cHigh]
% flag_clf ........ clear current figure [1]
%                   
%
% Output arguments
% -----------------------
% carAnim ......... carAnim-Struct
%
% Call Examples
% -----------------------
% carAnim = createAnimWindow(carAnim);
% carAnim2 = createAnimWindow(carAnim,'subplot',[m,n,p]);
%
% See also: newCarAnim, newCarUnit, figure, subplot
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default Values
h_fig = [];
subplot_ = [];
colorbar_ = [];
flag_clf = 1;

% Name of figure
if isfield(carAnim.fig,'name')
    if ~isempty(carAnim.fig.name) && ~strcmp(carAnim.fig.name,'')
        figName = carAnim.fig.name;
    else
       figName = 'MatCarAnim'; 
    end %if
else
    figName = 'MatCarAnim';
end %if

for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'h_fig'
            h_fig = varargin{h_};
        case 'name'
            figName = varargin{h_};
        case 'subplot'
            subplot_ = varargin{h_};
        case 'colorbar'
            colorbar_ = varargin{h_};
        case 'flag_clf'
            flag_clf = varargin{h_};
        otherwise
            if(checkVarargin_)
                error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
            end
    end
end

%% work
if ~exist('carAnim','var')
    error('Input argument "carAnim" is undefined!')
end %if
if isempty(h_fig)
    % If figure not exists
    if isempty(findobj('name',figName)) 
        %Create new figure
        figure('name',figName,'numbertitle','off');
        h_fig = gcf;
    else %obtain figure-handle
        h_fig = findobj('name',figName);
        figure(h_fig);
        if flag_clf
            clf
        end
    end
else
    if ~ishandle(h_fig) 
        warning(['The given figure-handle <h_fig> is not an existing handle,', ...
        ' a new figure will be produced!']);
        %Create new figure
        figure('name',figName,'numbertitle','off');
        h_fig = gcf;
    else %Rename and refresh Figure
        figure(h_fig);
        if flag_clf
            clf
        end
        set(h_fig,'name',figName,'numbertitle','off');
    end  
end

if ~isempty(subplot_)
    if length(subplot_) >= 3
        m = subplot_(1);
        n = subplot_(2);
        p = subplot_(3:length(subplot_));
        h_subplot = subplot(m,n,p);
    else
        warning(['Wrong subplot input parameter! ' ...
            'Expected: subplot = [m,n,p]! The subplot will be ignored!'])
    end
end %if

if ~isempty(colorbar_) && length(colorbar_) == 2
    colorbar
    set(gca, 'CLim', colorbar_);   
end %if

hold on
xlabel('x')
ylabel('y')
zlabel('z')
axis equal
hold off

% store Properties
carAnim.fig.name = figName;
carAnim.fig.h_fig = gcf;
carAnim.fig.h_axe = gca;
end
