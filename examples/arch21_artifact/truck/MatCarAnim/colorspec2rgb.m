function rgb = colorspec2rgb(colorspecStr)
% Converts a string of ColorSpec to the acconrding rgb-value
% See also: colormap, floor, rem, strfind
%
%  Author:     Johannes Stoerkle
%  Date:       23.01.2013
%  Modified:   
%
% - MatCarAnim - 
% Car Animation-Toolbox for Matlab
% 2013, ETH Zurich - Swiss Federal Institute of Technology Zurich

rgb = rem(floor((strfind('kbgcrmyw', colorspecStr) - 1) * [0.25 0.5 1]), 2);
end %function