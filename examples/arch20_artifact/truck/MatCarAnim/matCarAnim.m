%% Description of MatCarAnim - Toolbox for Matlab (R2011 & higher)
% This toolbox provides several functions and *.m-files to animate single
% or multi-unit car (or tractor / trucks - trailer) combinations with 
% given trajectories of their center of gravity movements.
%
% Exemplary usage:
%   % Installation: add the toolbox-functions to the MATLAB search paths
%   addpathMatCarAnim;
%
%   % Create new CarAnim-Struct
%   carAnim = newCarAnim('name','CarAnim_Test');
% 
%   % Create an Animation-Window
%   carAnim = createAnimWindow(carAnim);
%
%   % New Car-unit: Tractor
%   [carAnim id1] = newCarUnit(carAnim);
%
%   (... Calc Simulation Results --> trajectories ...)
%
%   for idxPlot=1:length(psi_1)
%      % Update position (Trafo etc.) and draw it
%      carAnim = updateCarUnitStruct(carAnim,id1,'r_cg',r_1(:,idxPlot), ...
%                                           'psi',psi_1(idxPlot));
%      % Redraw object
%      redrawCarAnim(carAnim);
%
%      pause(0.05) % show the user the current figure
%   end
%
% See also: newCarAnim, createAnimWindow, newCarUnit
%
%  Author:     Johannes Stoerkle
%  Date:       07.03.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich