% Sub: addpathMatCarAnim
% This file provides the installation of the Matlab-Toolbox 'MatCarAnim'
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

addpath(genpath('D:\Eigene_Dateien\MATLAB\Toolboxes\MatCarAnim'))


% find the location of this function
thisfilePath = mfilename('fullpath'); 
parts = regexp(thisfilePath, filesep, 'split');
MatCarAnim_dir = fullfile(filesep,parts{1:end-1},filesep);

% add all paths of the OM-Sim folder
addpath(genpath(MatCarAnim_dir))

% clean up
clear thisfilePath parts MatCarAnim_dir

% % adapt default color properties, because it has changed since R2014b
% set(groot,'DefaultFigureColormap',jet)                       % colorbar
% close(gcf)
% set(groot,'DefaultAxesColorOrder',[0 0 1; 0 .5 0; 1 0 0; ... % linecolors
%                                     0 .75 .75; .75 0 .75; ...
%                                     .75 .75 0; .25 .25 .25])