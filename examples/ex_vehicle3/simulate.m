clear all;
close all;
clc;


x0 = [-2.5 -2.5 0];
us = [3.0 deg2rad(15)];

T = size(us, 1);
  
xs = x0;
for k=1:30    
    x = sys_post(xs(k,:),us(1,:));
    xs = [xs; x];
end


figure;
hold on;
plot(xs(:,1),xs(:,2),'-*');

figure;
hold on;
for k=1:3
    subplot(3,1,k);
    plot(xs(:,k))
end
