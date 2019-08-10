% hyper rect = [lb_vector; ub_vector]
function yesno = isInsideHyberRect(test_element, intervals_set)

    % LB Test
    passed = true;
    for d=1:length(test_element)
        if (test_element(d) < intervals_set(1,d))
            passed = false;
            break;
        end
    end
    if(~passed)
        yesno = false;
        return;
    end     
    
    % UB Test
    passed = true;
    for d=1:length(test_element)
        if (test_element(d) > intervals_set(2,d))
            passed = false;
            break;
        end
    end
    if(~passed)
        yesno = false;
        return;
    end    
    
    yesno = true;
end