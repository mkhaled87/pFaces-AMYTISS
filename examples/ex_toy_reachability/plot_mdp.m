addpath('../../interface/');
x_src = [3 3];
u = [0.9 0.9];

close all;

figure;
hold on;
mdp_plot_transition('toy2d.raw', x_src, u); 
view(30,30); 
axis([-1 10 -1 10]);
set(gca,'xtick',[-1:10]);
set(gca,'ytick',[-1:10]);
title('Reachable states with their probabilities for (x,u,w=0)');