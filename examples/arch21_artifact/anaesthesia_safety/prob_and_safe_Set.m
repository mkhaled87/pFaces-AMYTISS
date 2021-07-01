close all
clear all
clc

% configurations for the simulation
addpath('../../../interface/');
filename = 'anaesthesia_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);

% Making quantizers
ss_lb = str2double(split(toy2dDataFile.getMetadataElement('ss-lower-point'),','))';
ss_ub = str2double(split(toy2dDataFile.getMetadataElement('ss-upper-point'),','))';
ss_eta = str2double(split(toy2dDataFile.getMetadataElement('ss-eta'),','))';
[ss_quantizer, is_quantizer] = makeQuantizers(toy2dDataFile);

% plotting the prbabilites as bars on 2d grid
x_width = str2double(split(toy2dDataFile.getMetadataElement('x-width'),','))';

figure;
hold on;
bar_width = ss_eta(1)/2;
min_p = 1.0;
max_p = 0.0;
cloud3d = [];
for x_flat = 0:1:x_width-1
    p = vlist.getVElement(x_flat);
    if p>max_p
        max_p = p;
    end
    if p<max_p
        min_p = p;
    end
    x_conc = ss_quantizer.desymbolize(ss_quantizer.unflatten(x_flat));
    
    if p >= 0.99
        cloud3d = [cloud3d; [x_conc(1) x_conc(2) x_conc(3)]];
    end
end

plot3(cloud3d(:,1), cloud3d(:,2), cloud3d(:,3), 'r*')
k = boundary(cloud3d,0.0);
trisurf(k, cloud3d(:,1), cloud3d(:,2), cloud3d(:,3),'Facecolor','blue', 'FaceAlpha',0.5)

% finalize
axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)]);
set(gca,'xtick',[ss_lb(1):ss_eta(1):ss_ub(1)]-ss_eta(1)/2);
set(gca,'ytick',[ss_lb(2):ss_eta(2):ss_ub(2)]-ss_eta(2)/2);
grid on;

disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);


