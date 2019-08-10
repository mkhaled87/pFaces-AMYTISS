% configurations for the simulation
addpath('../interface/');
filename = 'traffic5_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);


% plotting the prbabilites as bars on 2d grid
x_width = str2double(split(toy2dDataFile.getMetadataElement('x-width'),','))';


min_p = 1.0;
max_p = 0.0;
for x_flat = 0:1:x_width-1
    p = vlist.getVElement(x_flat);
    if p>max_p
        max_p = p;
    end
    if p<max_p
        min_p = p;
    end        
end

disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);


