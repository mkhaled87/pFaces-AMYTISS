addpath('../../interface/');
x_src = [0 0];
u = [0.7 0.8];

close all;

figure;
hold on;
mdp_plot_transition('toy2d.raw', x_src, u, 'max'); 
view(30,30); 
axis([-1 10 -1 10]);
set(gca,'xtick',[-1:10]);
set(gca,'ytick',[-1:10]);

figure;
hold on;
mdp_plot_transition('toy2d_with_w.raw', x_src, u, 'min'); 
view(30,30); 
axis([-1 10 -1 10]);
set(gca,'xtick',[-1:10]);
set(gca,'ytick',[-1:10]);

figure;
hold on;
mdp_plot_transition('toy2d_with_w.raw', x_src, u, 'max'); 
view(30,30); 
axis([-1 10 -1 10]);
set(gca,'xtick',[-1:10]);
set(gca,'ytick',[-1:10]);