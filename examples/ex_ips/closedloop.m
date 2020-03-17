% configurations for the simulation
addpath('../../interface/');
filename = 'ips.raw';

% initial state
x0_4d = [0 0 0 0];
x0_2d = [0 0];

% numbe of simulation
num_simulations = 20;

% reading values from the date file
% read data from raw file
toy2dDataFile = DataFile(filename, true, true);
% dimension of state space
ss_dim = str2double(split(toy2dDataFile.getMetadataElement('ss-dimension'),','));
% demension of input space
is_dim = str2double(split(toy2dDataFile.getMetadataElement('is-dimension'),','));
% lower bound of the state space
ss_lb = str2double(split(toy2dDataFile.getMetadataElement('ss-lower-point'),','))';
% upper bound of the state space
ss_ub = str2double(split(toy2dDataFile.getMetadataElement('ss-upper-point'),','))';
% size of grid in stste space
ss_eta = str2double(split(toy2dDataFile.getMetadataElement('ss-eta'),','))';
% lower bound of the input space
is_lb = str2double(split(toy2dDataFile.getMetadataElement('is-lower-point'),','))';
% upper bound of the input space
is_ub = str2double(split(toy2dDataFile.getMetadataElement('is-upper-point'),','))';
time_steps = str2double(toy2dDataFile.getMetadataElement('time-steps'));
% AMYTISS: Cov matrix
sigma = readCovarianceMatrix(toy2dDataFile);
% define safety envelope
safe_hyper_rect = [ss_lb; ss_ub];


if ss_dim == 4
    x0 = x0_4d;
else
    x0 = x0_2d;
end


% simulate/plot
close all;
clc;
figure;
hold on;
xss =[];

for k=1:num_simulations
    xs = x0;
    us = []; 
    x = x0;
    
    failed = false;
    for t=0:time_steps-1

        % get input for state [not aware of noise]
        u = getControlAction(toy2dDataFile, x, t)';
        us = [us; u];

        % but, the system suffers a noise [with N(mu, sigma)]
        % set mu=0 to get the noise's amplitude and add it to x
        noise = mvnrnd(zeros(size(x0)), sigma);
        if ss_dim == 4
            x = sys_post_4d(xs(end,:), us(end,:), 0) + noise;
        else
            x = sys_post_2d(xs(end,:), us(end,:), 0) + noise;
        end
        xs = [xs; x];
        
        if(~isInsideHyberRect(x,safe_hyper_rect))
            failed = true;
            break;
        end
    end

    
    % plot the evolution of each x and u
    for d = 1:ss_dim
        subplot(max(ss_dim,is_dim),1,d);
        hold on;
        if(failed)
            plot(0:length(xs(:,d))-1, xs(:,d), 'r');
        else
            plot(0:time_steps, xs(:,d), 'b');
        end
    end
    
    if(failed)
        disp(['Simulation #' num2str(k) ': failed!']);
        continue;
    else
        disp(['Simulation #' num2str(k) ': passed!']);
    end    
    
    xss(k,:,:) = xs;
end

% adding xlabel, ylabel, title etc. to the plot for each x and u
for d = 1:ss_dim
    subplot(max(ss_dim,is_dim),1,d);
    axis([0 time_steps ss_lb(d) ss_ub(d)]);
    xlabel('Time');
    ylabel(['x' num2str(d)]);
    title(['State (x' num2str(d) ') trajectory for ' num2str(num_simulations) ' simulations']);
    grid on;
end
