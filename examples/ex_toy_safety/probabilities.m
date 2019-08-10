% configurations for the simulation
addpath('../../interface/');
filename = 'toy2d_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);


% plotting the prbabilites as bars on 2d grid
ss_lb = str2double(split(toy2dDataFile.getMetadataElement('ss-lower-point'),','))';
ss_ub = str2double(split(toy2dDataFile.getMetadataElement('ss-upper-point'),','))';
ss_eta = str2double(split(toy2dDataFile.getMetadataElement('ss-eta'),','))';
[ss_quantizer, is_quantizer] = makeQuantizers(toy2dDataFile);

figure;
hold on;
bar_width = ss_eta(1)/2;
min_p = 1.0;
max_p = 0.0;
for x1 = ss_lb(1):ss_eta(1):ss_ub(1)
    for x2 = ss_lb(2):ss_eta(2):ss_ub(2)
        x_conc = [x1 x2];
        x_flat = ss_quantizer.flatten(ss_quantizer.symbolize(x_conc));
        p = vlist.getVElement(x_flat);
        if p>max_p
            max_p = p;
        end
        if p<min_p
            min_p = p;
        end        
        drawbar(x_conc(1), x_conc(2), p, bar_width);
    end
end

% finalize
axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)]);
set(gca,'xtick',[ss_lb(1):ss_eta(1):ss_ub(1)]-ss_eta(1)/2);
set(gca,'ytick',[ss_lb(2):ss_eta(2):ss_ub(2)]-ss_eta(2)/2);
grid on;


disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);


