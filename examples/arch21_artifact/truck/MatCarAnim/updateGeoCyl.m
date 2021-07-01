function h_fig = updateGeoCyl(h_fig,cylStruct,varargin)
% update geometry of current cylStruct-object (closed cylinder3D), in figure
% 'h_fig'
% 
% Input arguments
% -----------------------
% Mandatory:
% h_fig ........... handle of current figure
% cylStruct ....... cylStruct-object (closed Cylinder)
% 
% Optional arguments are to be passed in pairs {default value}:
% ................. 
%
% Output arguments
% -----------------------
% h_fig ........... h_fig
%
% Call Examples
% -----------------------
% piston = updateGeoCyl(h_fig,piston,'Color','g'); 
%
% See also: newCarUnit, updateCarUnitStruct
%
%  Author:     Johannes Stoerkle
%  Date:       12.02.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% set default values
%color = [];
% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case {'color','facecolor'}
            % - feel free to edit --;
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

%% Work
%figure(h_fig)

% MANTLE
if isfield(cylStruct, 'h_mantle') && isfield(cylStruct, 'X_')  ...
        && isfield(cylStruct, 'Y_') && isfield(cylStruct, 'Z_')
    
    % Set gemetry
    set(cylStruct.h_mantle,'XData',cylStruct.X_,'YData',cylStruct.Y_,'ZData',cylStruct.Z_);
    
    % Set Color
    if isfield(cylStruct, 'C')
        set(cylStruct.h_mantle,'CData',cylStruct.C);
    elseif isfield(cylStruct, 'color')
        set(cylStruct.h_mantle,'FaceColor',cylStruct.color);
    end
end %if

% AREA
if isfield(cylStruct, 'h_area') && isfield(cylStruct, 'X_j_')  ...
        && isfield(cylStruct, 'Y_j_') && isfield(cylStruct, 'Z_j_')
    
    % Set gemetry
    for idx=1:1:length(cylStruct.h_area)
        if ishandle(cylStruct.h_area(idx))
            set(cylStruct.h_area(idx),'XData',cylStruct.X_j_{idx},...
                'YData',cylStruct.Y_j_{idx},'ZData',cylStruct.Z_j_{idx});

            % Set Color
            if isfield(cylStruct, 'color')
                set(cylStruct.h_area(idx),'FaceColor',cylStruct.color);
            end
        end %if
    end %for
end %if

% LINE
if isfield(cylStruct, 'h_line') && isfield(cylStruct, 'X_l_')  ...
        && isfield(cylStruct, 'Y_l_') && isfield(cylStruct, 'Z_l_')
    % Set gemetry
    for idx=1:1:length(cylStruct.h_line)
        set(cylStruct.h_line(idx),'XData',cylStruct.X_l_{idx},...
            'YData',cylStruct.Y_l_{idx},'ZData',cylStruct.Z_l_{idx});
        if isfield(cylStruct,'LineColor')
            set(cylStruct.h_line(idx),'Color',cylStruct.LineColor);
        end %if
    end % for
end %if

% Return h_fig;
end %function