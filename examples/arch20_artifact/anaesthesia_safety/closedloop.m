% configurations for the simulation
addpath('../../../interface/');
filename = 'anaesthesia.raw';
x0 = [5 5 5];
num_simulations = 10;

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
        noise = mvnrnd(zeros(1,ss_dim), sigma);
        x = sys_post(xs(end,:) + noise,us(end,:));
        xs = [xs; x];
        
        failed = false;
        if(~isInsideHyberRect(x,safe_hyper_rect))
            disp(['Simulation #' num2str(k) ': failed!']);
            failed = true;
            break;
        end
    end 
    for d = 1:ss_dim
        subplot(max(ss_dim,is_dim),2,2*d-1);
        hold on;
        if(failed)
            plot(0:length(xs(:,d))-1, xs(:,d), 'r');
        else
            plot(0:time_steps, xs(:,d), 'b');
        end
    end
    for d = 1:is_dim
        subplot(max(ss_dim,is_dim),2,2*d);
        hold on;
        if(failed)
            plot(0:length(us(:,d))-1, us(:,d), 'r');        
        else
            plot(0:time_steps-1, us(:,d), 'b');        
        end
    end    
    if ~failed
        disp(['Simulation #' num2str(k) ': passed!']);
        xss(k,:,:) = xs;
    end
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