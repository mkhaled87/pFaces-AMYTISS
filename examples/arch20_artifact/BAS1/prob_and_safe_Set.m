% configurations for the simulation
addpath('../../../interface/');
filename = 'bas_V.raw';
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

min_p = 1.0;
max_p = 0.0;
points2d = [];
safe_set_limit = 0.9;
for x_flat = 0:1:x_width-1
    
    x_conc = ss_quantizer.desymbolize(ss_quantizer.unflatten(x_flat));
    
    p = vlist.getVElement(x_flat);
    if p>max_p
        max_p = p;
    end
    if p<max_p
        min_p = p;
    end
    
    if p >= safe_set_limit
        points2d = [points2d; [x_conc(1) x_conc(2)]];
    end    
end

disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);


plot(points2d(:,1), points2d(:,2), 'r*');
axis([17 24 17 24])
legend(['Safe-set with Prob. = ' num2str(safe_set_limit)])


