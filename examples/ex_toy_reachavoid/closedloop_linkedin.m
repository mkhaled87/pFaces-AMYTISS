% configurations for the simulation
addpath('../../interface/');
filename = 'toy2d.raw';
x0s = [-6 -6; ...
       -6 -5; ...
       -6 -4; ...
       -5 -6; ...
       -5 -5; ...
       -5 -4; ...
       -4 -6; ...
       -4 -5; ...
       -4 -4];
    
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
avoid_hr = str2double(split(toy2dDataFile.getMetadataElement('avoid-hyperrect'),','))';
avoid_hyper_rect = [avoid_hr(1:2:end); avoid_hr(2:2:end)];
ss_hyper_rect = [ss_lb; ss_ub];

% simulate/plot
close all;
clc;
figure;
hold on;
subplot(1,2,1);
rectangle('Position',[target_hr(1) target_hr(3) (target_hr(2)-target_hr(1)) (target_hr(4)-target_hr(3))], 'FaceColor', 'blue' ,'LineWidth',3);
text(target_hr(1)+0.3, target_hr(3)+1.5,'Target', 'FontSize', 20, 'Color', 'White')
rectangle('Position',[avoid_hr(1) avoid_hr(3) (avoid_hr(2)-avoid_hr(1)) (avoid_hr(4)-avoid_hr(3))], 'FaceColor', 'red' ,'LineWidth',3);
text(avoid_hr(1)+0.5, avoid_hr(3)+1.5,'Avoid', 'FontSize', 20, 'Color', 'White')
xlabel('X','FontSize', 20);
ylabel('Y','FontSize', 20);
title(['System position trajectory'], 'FontSize', 20);
axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)])
grid on;
hold on;

subplot(1,2,2);
axis([0 16 -3 3])
xlabel('Time','FontSize', 20);
ylabel('Noise','FontSize', 20);
title(['Noise on X (black) and Y (green) axes '], 'FontSize', 20);
hold on;


% load the robor image
[robot, map, alphachannel] = imread('figs/robot.png');
robot_width = 3;
robot_hight = 3;
robot_obj = [];
noise_plots = [];

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
        x = sys_post(xs(end,:) + 0.5.*noise,us(end,:), 0);
        
        if t==0 && ~isempty(noise_plots)
            delete(noise_plots);
            noise_plots = [];
        end
        xs = [xs; x];
        subplot(1,2,2);
        p = bar(t,noise(1),'FaceColor','k', 'BarWidth', 0.5);
        noise_plots = [noise_plots; p];
        hold on
        p = bar(t+0.5,noise(2),'FaceColor','g', 'BarWidth', 0.5);
        noise_plots = [noise_plots; p];
        hold on
        drawnow();


        subplot(1,2,1);
        hold on
        if t ==0
            plot(xs(1,1), xs(1,2), '*b');
        end
        plot(xs(end-1:end,1), xs(end-1:end,2), 'o-b');
        if ~isempty(robot_obj)
            delete(robot_obj);
        end
        robot_obj = image(flipud(robot), 'XData', [xs(end,1)-robot_width/2 xs(end,1)+robot_width/2], 'YData', [xs(end,2)-robot_hight/2 xs(end,2)+robot_hight/2], 'AlphaData', alphachannel);
        drawnow();
        
        if(isInsideHyberRect(x,target_hyper_rect))
            disp(['Simulation #' num2str(k) ': target reached at step ' num2str(t) '!']);
            reached = true;
            break;
        end
        if(isInsideHyberRect(x,avoid_hyper_rect))
            disp(['Simulation #' num2str(k) ': reached avoid set !']);
            reached = true;
            break;
        end        
    end        
end


