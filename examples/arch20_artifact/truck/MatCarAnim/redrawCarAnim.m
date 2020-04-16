function carAnim = redrawCarAnim(carAnim,varargin)
% redraw all objects from carAnim, which contain cylinders
% and / or lines, surfaces, patches... (set coordinates X Y Z ...)
% 
% Input arguments
% -----------------------
% Mandatory:
% carAnim ......... carAnim-Struct
% 
% Optional arguments are to be passed in pairs {default value}:
% id .............. The ID of a sub object e.g. CarUnit_1
% xlim ............ fixed x-axis range {[]}
% ylim ............ fixed y-axis range {[]}
% zlim ............ fixed z-axis range {[]}
%
% Output arguments
% -----------------------
% carAnim ......... carAnim-Struct
%
% Call Examples
% -----------------------
% carAnim = redrawCarAnim(carAnim,...
%                 'xlim',[0 1],'ylim',[0 1],'zlim',[0 1]);
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
% Default Geometric Values
id_ = [];
xlim_ = [];
ylim_ = [];
zlim_ = [];

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case {'id'}
            id_ = varargin{h_};
        case {'xlim'}
            xlim_ = varargin{h_};
        case {'ylim'}
            ylim_ = varargin{h_};
        case {'zlim'}
            zlim_ = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

%% ReDraw Geo 
h_fig = carAnim.fig.h_fig;
figure(h_fig);

% loop all mainobjects
mainObjNames = fieldnames(carAnim); 
for Midx=1:length(mainObjNames)
    mainObjName = char(mainObjNames(Midx));
    if isstruct(carAnim.(mainObjName))
        % redraw all ids
        subObjNames = fieldnames(carAnim.(mainObjName)); 
        for Sidx=1:size(subObjNames,1)
            if isempty(id_)
                subObjName = char(subObjNames(Sidx));
            else %handle only given id
                subObjName = id_;
            end %if
            if isfield(carAnim.(mainObjName),subObjName)
                id = subObjName;
                if isstruct(carAnim.(mainObjName).(id))
                    % redraw all objects from current id
                    objNames = fieldnames(carAnim.(mainObjName).(id)); 
                    for idx=1:1:length(objNames)
                        fname = char(objNames(idx));
                        obj = carAnim.(mainObjName).(id).(fname);
                        if iscell(obj) 
                            for idx_cell = 1:length(obj)
                                Draw_obj(obj{idx_cell},h_fig);
                            end %for
                        else
                            Draw_obj(obj,h_fig);
                        end                       
                    end % for
                end %if isstruct
            end %if isfield
            if ~isempty(id_)
                break
            end %if
        end %for Sub
    end %if isstruct
end %for Main

% FIGURE
if ~isempty(xlim_) && ~isempty(ylim_) && ~isempty(zlim_)
set(carAnim.fig.h_axe,'xlim',xlim_,'ylim',ylim_,'zlim',zlim_);
end %if
refresh(carAnim.fig.h_fig);

end % END OF drawHydCal

function Draw_obj(obj,h_fig)
    % Handle cylinder-mantle and general coordiantes 
    %/ Check existence of fields / if is a struct?
    if isfield(obj,'h_mantle') && isfield(obj,'color') ...
            && isfield(obj,'X_') && isfield(obj,'Y_') && isfield(obj,'Z_')
        updateGeoCyl(h_fig, obj); 
    end
    % Handle area-coordinates
    if isfield(obj,'h_area') && isfield(obj,'color') ...
             && isfield(obj,'X_j_') && isfield(obj,'Y_j_') && isfield(obj,'Z_j_')
        updateGeoCyl(h_fig, obj); 
    end
    % Handle line-coordinates
    if isfield(obj,'h_line') && isfield(obj,'X_l_') && isfield(obj,'Y_l_') && isfield(obj,'Z_l_')
        updateGeoCyl(h_fig, obj); 
    end
    % Handle text-coordinates
    if isfield(obj,'h_text') && isfield(obj,'X_t') && isfield(obj,'Y_t') && isfield(obj,'Z_t')
        for idx_t = 1:length(obj.h_text)
            set(obj.h_text(idx_t),'Position',[obj.X_t_{idx_t} obj.Y_t_{idx_t} obj.Z_t_{idx_t}]); 
        end %for
    end
    % Handle patch-coordinates
    if isfield(obj,'h_patch') && isfield(obj,'vertices_')
        set(obj.h_patch,'Vertices',obj.vertices_); 
    end                        
end %function