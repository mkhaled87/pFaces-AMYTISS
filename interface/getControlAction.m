function u_conc = getControlAction(pfacesDataFile, x_conc, time_idx)
    [ss_quantizer, is_quantizer] = makeQuantizers(pfacesDataFile);
    u_width = str2double(pfacesDataFile.getMetadataElement('u-width'));
    
    % quantize x
    x_flat = ss_quantizer.flatten(ss_quantizer.symbolize(x_conc));
    
    % for all u
    u_conc = [];
    for u_flat=0:u_width-1
        xuBag = amytissXUBag(pfacesDataFile, x_flat, u_flat);
        if(xuBag.isControlFlagged(time_idx))
            u_conc = is_quantizer.desymbolize(is_quantizer.unflatten(u_flat));
            break;
        end
    end
end

