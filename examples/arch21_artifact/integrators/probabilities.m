% configurations for the simulation
addpath('../interface/');
filename = 'int2_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);


% plotting the prbabilites as bars on 2d grid
ss_dim = str2double(split(toy2dDataFile.getMetadataElement('ss-dimension'),','))';
x_width = str2double(split(toy2dDataFile.getMetadataElement('x-width'),','))';
ss_steps = str2double(split(toy2dDataFile.getMetadataElement('ss-steps'),','))';
[ss_quantizer, is_quantizer] = makeQuantizers(toy2dDataFile);


min_p = 1.0;
max_p = 0.0;
indicies = 0:1:x_width-1;
V = zeros(1,length(indicies));
target_p = 0.8;
length_2d = ss_steps(1)*ss_steps(2);
V_2dslice = zeros(1,length_2d);
for x_flat = indicies
    p = vlist.getVElement(x_flat);
    if p>max_p
        max_p = p;
    end
    if p<max_p
        min_p = p;
    end
    V(x_flat+1) = p;
    
    % if p is beyond target_p, we record its 2d projection for later
    % calculation of the 2d-volume
    if p >= target_p
        x_sym = ss_quantizer.unflatten(x_flat);
        x2d_flat = x_sym(2)*ss_steps(1) + x_sym(1);
        V_2dslice(x2d_flat+1) = p;
    end
end
disp(['Min V = ' num2str(min_p)]);
disp(['Max V = ' num2str(max_p)]);

volume = length(V_2dslice(V_2dslice >= target_p))/length_2d;
disp(['Volume% (P>=' num2str(target_p) ') = ' num2str(volume*100) '%'])



