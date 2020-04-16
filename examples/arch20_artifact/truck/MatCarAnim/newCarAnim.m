function carAnim = newCarAnim(varargin)
% Create new Car-Animation - object / structure
% 
% Input arguments
% -----------------------
% Mandatory:
% ................. 
% 
% Optional arguments are to be passed in pairs {default value}:
% Id .............. The identification of the new carAnim-struct {1}
% Name ............ The name of the new carAnim-struct {[]}
%
% Output arguments
% -----------------------
% carAnim ......... CarAnim-Struct
%
% Call Examples
% -----------------------
% carAnim = newCarAnim; 
%
% See also: createAnimWindow, newCarUnit
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

%% Create data-structure
carAnim = [];
% General
carAnim.id = 1;
carAnim.name = 'carAnim_1';
carAnim.fig.name = [];
carAnim.fig.h_fig = [];
carAnim.fig.h_axe = [];
% units
carAnim.units = {};
carAnim.units.count = 0;
% worlds
carAnim.worlds = {};
carAnim.worlds.count = 0;

%% set default values
% Default Values

% read optional parameters
for h_ = 2:2:length(varargin)
    switch lower(varargin{h_-1})
        case 'id'
            carAnim.id = varargin{h_};
        case {'name'}
            carAnim.name = varargin{h_};
            carAnim.fig.name = varargin{h_};
        otherwise
            error('Unknown Option ''%s''!',any2str(varargin{h_-1}));
    end
end

fprintf(strcat('--------------------------------------------',...
               '\n---------------- MatCarAnim ----------------',...
               '\n--------------------------------------------',...
               '\n--> Car-Animation-Toolbox for MATLAB - by J. Stoerkle',...
               '\n--------------------------------------------\n',...
                 'The car animation <%s> was created!\n'),carAnim.name);

end % function