%% Description:
% Test to define / animate a bicycle Model in MatCarAnim
% --> Define a platform-System with 
%               - 2 carUnits
%               - 1 world3D 
%  in MatCarAnim.
%
% See also: addpathMatCarAnim, newCarAnim, createAnimWindow, newCarUnit,
% newWorld3D, redrawCarAnim
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

addpath('../');
addpath('../CarUnit');

% clear all
close all
clc

%% Init
% constant distances
l_1 = 1;
l_2 = 2;
l_3 = 2.6;
b_1 = 6;
b_2 = 0.4;
b_3 = 1.7;
b_4 = 3;
b_5 = 3;
rgb_gray = [0.8 0.8 0.8];

% variables
delta_1_0 = 0/180*pi;
delta_2_0 = 0/180*pi;

%% Define System:
% Use MatCarAnim-Toolbox-functions, call the initializing function at
% ./addpathMatCarAnim

% Create new CarAnim-Struct
carAnim = newCarAnim('name','CarAnim_Test');

% Create an Animation-Window
carAnim = createAnimWindow(carAnim);
set(gca,'color','none'); %Disable axes-background-color
% view([0,1,0]); %set viewpoint to x=0,y=1,z=0

% Ground
% ground = cube3D('pos',[0 0 -0.01],'lengths',[25 25 0.02],'rgb_faces',[0.9 0.9 0.9]);
ground = draw_chessboard(-12,12,-12,12,0,1,[0.9 0.9 0.9],[1 1 1]);

% New Car-unit: Tractor
[carAnim id1] = newCarUnit(carAnim,'r_cg',[0 0 1.325], ...
                                   'delta_f',delta_1_0, ...
                                   'z_axes',1, ...
                                   'l_f',l_1, ...
                                   'l_h',l_2, ...
                                   'l_r',l_3,...
                                   'rgb_cube','b',...
                                   'flag_SngTrack',false);
% New Car-unit: Trailor
[carAnim id2] = newCarUnit(carAnim,'delta_r',[0, 0, delta_2_0], ...
                                   'flag_frontWheel',0, ...
                                   'z_axes',1, ...
                                   'r_cg',[-l_2-b_1, 0, 1.325], ...
                                   'l_f',b_1, ...
                                   'l_r',[b_2 b_3 b_4] , ...
                                   'd_r', carAnim.units.(id1).d_r, ...
                                   'l_cr',b_4 + b_5, ...
                                   'l_cf',b_1, ...
                                   'scale',carAnim.units.(id1).scale, ...
                                   'rgb_w_r',{rgb_gray,rgb_gray,'g'},...
                                   'rgb_cube','r');   
                               
%% Run test
x_test = 1*[0.05:0.05:5];
for idx = 1:length(x_test)
% Update position (Trafo etc.) and draw it
carAnim = updateCarUnitStruct(carAnim,id1,'r_cg',carAnim.units.(id1).r_cg0 + [x_test(idx) 0 0]);
carAnim = updateCarUnitStruct(carAnim,id2,'r_cg',carAnim.units.(id2).r_cg0 + [x_test(idx) 0 0]);
% Redraw object
redrawCarAnim(carAnim);
pause(0.03)
end %for
