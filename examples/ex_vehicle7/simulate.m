clear all;
close all;
clc;


x0 = [0 0 0.2 1 1 0 0];
us = [1.0 deg2rad(10)];

T = size(us, 1);
  
xs = x0;
for k=1:50
    x = sys_post(xs(k,:),us(1,:));
    xs = [xs; x];
end


figure;
hold on;
plot(xs(:,1),xs(:,2),'-*');

figure;
hold on;
for k=1:7
    subplot(7,1,k);
    plot(xs(:,k))
end
