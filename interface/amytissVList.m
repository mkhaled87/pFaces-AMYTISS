classdef amytissVList    
    properties
        concrete_data_type
        concrete_data_size
        x_width
        
        V_data_size
        V_data
    end
    
    methods(Static)
        function v = getValueFromArray(array, start_idx, data_type, data_type_size)
            bytes = array(start_idx+1:start_idx+data_type_size);
            v = typecast(uint8(bytes), data_type);            
        end
    end    
    methods
        function obj = amytissVList(pfacesDataOnject)

            obj.concrete_data_type = pfacesDataOnject.getMetadataElement('concrete-data-name');
            obj.concrete_data_size = str2double(pfacesDataOnject.getMetadataElement('concrete-data-size'));
            obj.x_width = str2double(pfacesDataOnject.getMetadataElement('x-width'));

            if(strcmp(obj.concrete_data_type, 'float'))
                obj.concrete_data_type = 'single';
            end

            if(~strcmp(obj.concrete_data_type, 'single') && ~strcmp(obj.concrete_data_type, 'double'))
                error('XUBag::XUBag: As concrete data types, MATLAB only supports float and double');
            end   
            
            obj.V_data_size = obj.x_width*obj.concrete_data_size;
            obj.V_data = pfacesDataOnject.getBlock(0, obj.V_data_size);
        end
        
        function val = getVElement(obj, x_flat)
            if(x_flat >= obj.x_width || x_flat < 0)
                error('Invalid x_flat value !');
            end
            idx = x_flat*obj.concrete_data_size;
            val = amytissVList.getValueFromArray(obj.V_data, idx, obj.concrete_data_type, obj.concrete_data_size);
        end
    end
end

