% configurations for the simulation
addpath('../interface/');
filename = 'int5_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);


% plotting the prbabilites as bars on 2d grid
x_width = str2double(split(toy2dDataFile.getMetadataElement('x-width'),','))';


min_p = 1.0;
max_p = 0.0;
indicies = 0:1:x_width-1;
V = zeros(1,length(indicies));
for x_flat = indicies
    p = vlist.getVElement(x_flat);
    if p>max_p
        max_p = p;
    end
    if p<max_p
        min_p = p;
    end
    V(x_flat+1) = p;
end

target_p = 0.8;
volume = length(V(V >= target_p))/length(V);
disp(['Volume% (P>=' num2str(target_p) ') = ' num2str(volume*100) '%'])
disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);


