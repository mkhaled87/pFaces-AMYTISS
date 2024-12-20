% configurations for the simulation
addpath('../../interface/');
filename = 'toy2d.raw';
x0s = [-2 -2; ...
       -2 -1; ...
       -2  0; ...
       -1 -2; ...
       -1 -1; ...
       -1  0; ...
        0 -2; ...
        0 -1; ...
        0  0];
    
num_simulations = size(x0s,1);

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
target_hr = str2double(split(toy2dDataFile.getMetadataElement('target-hyperrect'),','))';
target_hyper_rect = [target_hr(1:2:end); target_hr(2:2:end)];
ss_hyper_rect = [ss_lb; ss_ub];

% simulate/plot
close all;
clc;
figure;
hold on;
rectangle('Position',[target_hr(1) target_hr(3) (target_hr(2)-target_hr(1)) (target_hr(4)-target_hr(3))], 'FaceColor', 'blue' ,'LineWidth',3);

for k=1:num_simulations
    x = x0s(k,:);
    xs = [x];
    us = [];   
    reached = false;
    for t=0:time_steps-1
        
        if(~isInsideHyberRect(x,ss_hyper_rect))
            disp(['Simulation #' num2str(k) ': state went out of SS!']);
            reached = true;
            break;
        end        

        % get input for state [not aware of noise]
        u = getControlAction(toy2dDataFile, x, t)';
        us = [us; u];

        % but, the system suffers a noise [with N(mu, sigma)]
        % set mu=0 to get the noise's amplitude and add it to x
        noise = mvnrnd([0 0], sigma);
        x = sys_post(xs(end,:) + noise,us(end,:), 0);
        xs = [xs; x];


        if(isInsideHyberRect(x,target_hyper_rect))
            disp(['Simulation #' num2str(k) ': target reached at step ' num2str(t) '!']);
            reached = true;
            break;
        end
    end
    if ~reached
        disp(['Simulation #' num2str(k) ': target not reached within ' num2str(time_steps) ' steps !']);
        plot(xs(1,1), xs(1,2), '*r');
        plot(xs(:,1), xs(:,2), 'o-r');  
    else
        plot(xs(1,1), xs(1,2), '*b');
        plot(xs(:,1), xs(:,2), 'o-b');  
    end  
end

xlabel('x1');
ylabel('x2');
title(['System position trajectory for ' num2str(num_simulations) ' simulations']);

% finalize
axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)])
set(gca,'xtick',[ss_lb(1):ss_eta(1):ss_ub(1)]-ss_eta(1)/2);
set(gca,'ytick',[ss_lb(2):ss_eta(2):ss_ub(2)]-ss_eta(2)/2);
grid on;
