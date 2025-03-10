% configurations for the simulation
addpath('../../interface/');
filename = 'toy2d.raw';
x0 = [0 0];
num_simulations = 100;

% reading values from the date file
toy2dDataFile = DataFile(filename, true, true);
ss_dim = str2double(split(toy2dDataFile.getMetadataElement('ss-dimension'),','));
is_dim = str2double(split(toy2dDataFile.getMetadataElement('is-dimension'),','));
ss_lb = str2double(split(toy2dDataFile.getMetadataElement('ss-lower-point'),','))';
ss_ub = str2double(split(toy2dDataFile.getMetadataElement('ss-upper-point'),','))';
ss_eta = str2double(split(toy2dDataFile.getMetadataElement('ss-eta'),','))';
is_lb = str2double(split(toy2dDataFile.getMetadataElement('is-lower-point'),','))';
is_ub = str2double(split(toy2dDataFile.getMetadataElement('is-upper-point'),','))';
time_steps = str2double(toy2dDataFile.getMetadataElement('time-steps'));
sigma = readCovarianceMatrix(toy2dDataFile);
safe_hyper_rect = [ss_lb; ss_ub];

% simulate/plot
close all;
clc;
figure;
hold on;
xss =[];
for k=1:num_simulations
    xs = [x0];
    us = []; 
    x = x0;
    for t=0:time_steps-1

        % get input for state [not aware of noise]
        u = getControlAction(toy2dDataFile, x, t)';
        us = [us; u];

        % but, the system suffers a noise [with N(mu, sigma)]
        % set mu=0 to get the noise's amplitude and add it to x
        noise = mvnrnd([0 0], sigma);
        x = sys_post(xs(end,:) + noise,us(end,:), 0);
        xs = [xs; x];
        
        failed = false;
        if(~isInsideHyberRect(x,safe_hyper_rect))
            disp(['Simulation #' num2str(k) ': failed!']);
            failed = true;
        end
        if(failed)
            continue;
        end
        
    end
    for d = 1:ss_dim
        subplot(max(ss_dim,is_dim),2,2*d-1);
        hold on;
        plot(0:time_steps, xs(:,d), 'b');
    end
    for d = 1:is_dim
        subplot(max(ss_dim,is_dim),2,2*d);
        hold on;
        plot(0:time_steps-1, us(:,d), 'b');        
    end    
    disp(['Simulation #' num2str(k) ': passed!']);
    
    xss(k,:,:) = xs;
end

for d = 1:ss_dim
    subplot(max(ss_dim,is_dim),2,2*d-1);
    axis([0 time_steps ss_lb(d) ss_ub(d)]);
    xlabel('Time');
    ylabel(['x' num2str(d)]);
    title(['State (x' num2str(d) ') trajectory for ' num2str(num_simulations) ' simulations']);
    grid on;
end
for d = 1:is_dim
    subplot(max(ss_dim,is_dim),2,2*d);
    axis([0 time_steps is_lb(d) is_ub(d)]);
    xlabel('Time');
    ylabel(['u' num2str(d)]);
    title(['Input (u' num2str(d) ') sequence for ' num2str(num_simulations) ' simulations']);
    grid on;
end
    

figure;
hold on;
plot(x0(1), x0(2), '*k');
for k=1:num_simulations
    plot(xss(k,:,1), xss(k,:,2), 'b');
end
xlabel('x1');
ylabel('x2');
title(['System position trajectory for ' num2str(num_simulations) ' simulations']);

% finalize
axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)])
set(gca,'xtick',[ss_lb(1):ss_eta(1):ss_ub(1)]-ss_eta(1)/2);
set(gca,'ytick',[ss_lb(2):ss_eta(2):ss_ub(2)]-ss_eta(2)/2);
grid on;
