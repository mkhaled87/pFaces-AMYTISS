classdef amytissXUBag
    %XUBAG Summary ofthis class goes here
    %   Detailed explanation goes here
    
    % The bag contents:
    %  __________________
    % |  concrete_t P_min[NUM_REACH_STATES]          (when is_p_saved is true)
    % |  concrete_t P_max[NUM_REACH_STATES]          (when is_p_saved is true)
    % |  concrete_t V_INT;
    % |  char IS_CONTROL[NUM_CONTROL_BYTES];
    %  ------------------
    % NUM_CONTROL_BYTES = ceil(time_steps/8)
    %
    properties
        is_safe_or_reach
        
        P_min_idx
        P_max_idx
        P1_min_idx
        P0_min_idx
        V_int_idx
        Is_Control_idx
        
        bag_size
        is_p_saved
        num_reach_states
        time_steps
        x_width
        u_width
        reach_set_lb
        reach_set_ub
        num_control_bytes
        
        xu_idx
        bag_idx
        bag_data
        
        concrete_data_type
        concrete_data_size
    end
    
    methods(Static)
        function v = getValueFromArray(array, start_idx, data_type, data_type_size)
            bytes = array(start_idx+1:start_idx+data_type_size);
            v = typecast(uint8(bytes), data_type);            
        end
    end
    
    methods
        function obj = amytissXUBag(pfacesDataOnject, x_flat, u_flat)
            % base data from the meta data
            obj.bag_size = str2double(pfacesDataOnject.getMetadataElement('xu-bag-size'));
            obj.is_p_saved = strcmp('true', pfacesDataOnject.getMetadataElement('is-p-saved'));
            obj.num_reach_states = str2double(pfacesDataOnject.getMetadataElement('num-reach-states'));
            obj.time_steps = str2double(pfacesDataOnject.getMetadataElement('time-steps'));
            obj.x_width = str2double(pfacesDataOnject.getMetadataElement('x-width'));
            obj.u_width = str2double(pfacesDataOnject.getMetadataElement('u-width'));
            obj.is_safe_or_reach = strcmp(pfacesDataOnject.getMetadataElement('specs-type'),'safe');
            
            obj.reach_set_lb = str2double(split(pfacesDataOnject.getMetadataElement('org-cutting-region-lb'),','))';
            obj.reach_set_ub = str2double(split(pfacesDataOnject.getMetadataElement('org-cutting-region-ub'),','))';
            
            if (x_flat >= obj.x_width) || (u_flat >= obj.u_width)
                error('XUBag::XUBag: invalid x_sym or u_sym value, one exceeds the number of symbols.');
            end
            
            obj.xu_idx = x_flat*obj.u_width + u_flat;
            obj.bag_idx = obj.xu_idx*obj.bag_size;
            obj.bag_data = pfacesDataOnject.getBlock(obj.bag_idx, obj.bag_size);
            obj.num_control_bytes = ceil(double(obj.time_steps)/8.0);
            
            obj.concrete_data_type = pfacesDataOnject.getMetadataElement('concrete-data-name');
            obj.concrete_data_size = str2double(pfacesDataOnject.getMetadataElement('concrete-data-size'));
            
            if(strcmp(obj.concrete_data_type, 'float'))
                obj.concrete_data_type = 'single';
            end

            if(~strcmp(obj.concrete_data_type, 'single') && ~strcmp(obj.concrete_data_type, 'double'))
                error('XUBag::XUBag: As concrete data types, MATLAB only supports float and double');
            end   
            
            if obj.is_p_saved
                if obj.is_safe_or_reach
                    obj.P_min_idx = 0;
                    obj.P_max_idx = obj.P_min_idx + obj.num_reach_states*obj.concrete_data_size;                
                    obj.V_int_idx = obj.P_max_idx + obj.num_reach_states*obj.concrete_data_size;
                    obj.P0_min_idx = 'invalid';
                    obj.P1_min_idx = 'invalid';
                else
                    obj.P0_min_idx = 0;
                    obj.P1_min_idx = obj.P0_min_idx + obj.concrete_data_size;
                    obj.V_int_idx = obj.P1_min_idx + obj.num_reach_states*obj.concrete_data_size;                    
                    obj.P_min_idx = 'invalid';
                    obj.P_max_idx = 'invalid';
                end
            else
                obj.P_min_idx = 'invalid';
                obj.P_max_idx = 'invalid';     
                obj.P0_min_idx = 'invalid';
                obj.P1_min_idx = 'invalid';                     
                obj.V_int_idx = 0;                
            end
            
            if obj.num_control_bytes > 0
                obj.Is_Control_idx = obj.V_int_idx + obj.concrete_data_size;
            else
                obj.Is_Control_idx = 'invalid';
            end    
        end
        
        function outputArg = getSize(obj)
            outputArg = obj.bag_size;
        end
        function i = getIndex(obj)
            i = obj.bag_idx;
        end
        
        function p = getPmin(obj, reach_state_idx)
            if ~obj.is_safe_or_reach
                error('This bag is for reachability and has no Pmin.');
            end
            
            if obj.is_p_saved
                if(reach_state_idx >= obj.num_reach_states)
                    error('reach_state_idx exceeds number of reach states.');
                end
                idx = obj.P_min_idx + reach_state_idx*obj.concrete_data_size;
                p = amytissXUBag.getValueFromArray(obj.bag_data, idx, obj.concrete_data_type, obj.concrete_data_size);
            else
                error('Pmin is not stored in the file.');
            end
        end
        
        function p = getPmax(obj, reach_state_idx)
            if ~obj.is_safe_or_reach
                error('This bag is for reachability and has no Pmax.');
            end
            
            if obj.is_p_saved                
                if(reach_state_idx >= obj.num_reach_states)
                    error('reach_state_idx exceeds number of reach states.');
                end
                idx = obj.P_max_idx + reach_state_idx*obj.concrete_data_size;
                p = amytissXUBag.getValueFromArray(obj.bag_data, idx, obj.concrete_data_type, obj.concrete_data_size);            
            else
                error('Pmax is not stored in the file.');
            end
        end
        
        function p = getP0min(obj)
            if obj.is_safe_or_reach
                error('This bag is for safety and has no P0min.');
            end
            
            if obj.is_p_saved                
                idx = obj.P0_min_idx;
                p = amytissXUBag.getValueFromArray(obj.bag_data, idx, obj.concrete_data_type, obj.concrete_data_size);
            else
                error('P0min is not stored in the file.');
            end
        end    

        function p = getP1min(obj, reach_state_idx)
            if obj.is_safe_or_reach
                error('This bag is for safety and has no P1min.');
            end
            
            if obj.is_p_saved
                if(reach_state_idx >= obj.num_reach_states)
                    error('reach_state_idx exceeds number of reach states.');
                end
                idx = obj.P1_min_idx + reach_state_idx*obj.concrete_data_size;
                p = amytissXUBag.getValueFromArray(obj.bag_data, idx, obj.concrete_data_type, obj.concrete_data_size);
            else
                error('Pmin is not stored in the file.');
            end
        end        
        
        function p = getVint(obj)
            idx = obj.V_int_idx;
            p = amytissXUBag.getValueFromArray(obj.bag_data, idx, obj.concrete_data_type, obj.concrete_data_size);                        
        end
        
        function tf = isControlFlagged(obj, time_index)
            if obj.num_control_bytes > 0
                
                if time_index >= obj.time_steps
                    error('time_index exeeds number of time steps.');
                end
                
                byte_idx = obj.Is_Control_idx + floor(time_index/8);
                byte = obj.bag_data(1+byte_idx);
                bit_idx = mod(time_index,8);
                mask = bitshift(1,bit_idx);
                tf = logical(bitand(mask,byte));
            else
                error('The data file has no controller stored in it.')
            end
        end        
    end
end

