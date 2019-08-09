function [symDynamics, XXsymsPool, XsymsPool, UsymsPool] = readDynamicsSymbolic(exampleDataFile, ExtraXsymbols, ExtraUsymbols, IgnoresList, ReplacesList) 

    ss_dim = str2double(exampleDataFile.getMetadataElement('ss-dimension'));
    is_dim = str2double(exampleDataFile.getMetadataElement('is-dimension'));
    
    XXsymsPool = [];
    XsymsPool = [];
    UsymsPool = [];
    for k=1:ss_dim
        XXsymsPool = [XXsymsPool; sym(['xx' num2str(k-1)])];
        XsymsPool = [XsymsPool; sym(['x' num2str(k-1)])];
    end
    for k=1:is_dim
        UsymsPool = [UsymsPool; sym(['u' num2str(k-1)])];
    end
    
    if(nargin >= 2 && ~isempty(ExtraXsymbols))
        for i=1:length(ExtraXsymbols)
            XsymsPool = [XsymsPool; sym(ExtraXsymbols(i,:))];
        end
    end
    
    if(nargin >= 3 && ~isempty(ExtraUsymbols))
        for i=1:length(ExtraUsymbols)
            UsymsPool = [UsymsPool; sym(ExtraUsymbols(i,:))];
        end
    end
    
    symDynamics = [];
    for i=1:ss_dim
        xx_i_name = strcat('xx', num2str(i-1)); 
        xx_i_name = strcat(xx_i_name, '-post');
        
        xx_i_dynamics = exampleDataFile.getMetadataElement(xx_i_name);
        
        % remove ignores
        if(nargin >= 4 && ~isempty(IgnoresList))
            for j=1:size(IgnoresList,1)
                xx_i_dynamics = strrep(xx_i_dynamics,IgnoresList{j},'');
            end
        end
        
        % do replaces
        if(nargin >= 5 && ~isempty(ReplacesList))
            for j=1:size(ReplacesList,1)
                xx_i_dynamics = strrep(xx_i_dynamics,ReplacesList{j,1},ReplacesList{j,2});
            end            
        end        
        
        symDynamics = [symDynamics; evalin(symengine, xx_i_dynamics)];
    end
end

