% configurations for the simulation
addpath('../../interface/');
filename = 'Brownian_V.raw';
toy2dDataFile = DataFile(filename, true, true);

% making an a object of V values
vlist = amytissVList(toy2dDataFile);

% Make quantizers
[ss_quantizer, is_quantizer] = makeQuantizers(toy2dDataFile);

% extract probability at x=1.0
x_conc = 1.0;
x_flat = ss_quantizer.flatten(ss_quantizer.symbolize(x_conc));
p = vlist.getVElement(x_flat);
fprintf('Probability for x=1.0 is %e\n', p);

% detexct fist non-zero prop
if p==0.0
    x_conc = 1.0;
    p = 0.0;
    while p == 0.0
        x_conc = x_conc + 0.1;
        x_flat = ss_quantizer.flatten(ss_quantizer.symbolize(x_conc));
        p = vlist.getVElement(x_flat);
    end
    fprintf('Probability for x=%f (flat=%d) is %e\n', x_conc, x_flat, p);
end


