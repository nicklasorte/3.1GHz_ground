function [mid]=pre_sort_binary_movelist_mitigations_rev3_app(app,move_list_turn_off_idx,mitigation_binary_sort_mc_watts,full_eirp_binary_sort_mc_watts,turn_off_size95,radar_threshold)


%%%%This code could be cleaner.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
%%%%%%First we check if everything else can be full power, if the first set is turned off.
%size(mitigation_binary_sort_mc_watts)
mitigation_binary_sort_mc_watts(move_list_turn_off_idx)=NaN(1,1);
%size(mitigation_binary_sort_mc_watts)

% % % % 'Check size'
% % % % pause;

full_eirp_binary_sort_mc_watts(move_list_turn_off_idx)=NaN(1,1);
mc_agg_dbm=pow2db(sum(full_eirp_binary_sort_mc_watts,"omitnan")*1000);

%%%%%%%%Custom "lo"
lo_mitigation=turn_off_size95;

if mc_agg_dbm>radar_threshold %%%Over Threshold, binary search
    hi=length(full_eirp_binary_sort_mc_watts);
    %%%lo=0;
    lo=lo_mitigation; %%%%%%%%Custom "lo"
    if hi-lo<=1
        mid=hi; %%%If it is 1, just turn everything off
    else
        while((hi-lo)>1) %%%Binary Search
            mid=ceil((hi+lo)/2);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%The mid is the cross over point between mitigation and full EIRP.
            temp_mc_pr_watts=full_eirp_binary_sort_mc_watts;
            mix_idx=1:1:mid;     %%%%Mix in the mitigations
            temp_mc_pr_watts(mix_idx)=mitigation_binary_sort_mc_watts(mix_idx);
            temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case


            %Re-calculate Aggregate Power
            binary_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);

            %horzcat(binary_mc_agg_dbm,mid)
            if binary_mc_agg_dbm<radar_threshold
                hi=mid;
            else
                lo=mid;
            end
        end
        mid=hi;
    end

    %%%%%%%Double check
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%The mid is the cross over point between mitigation and full EIRP.
    temp_mc_pr_watts=full_eirp_binary_sort_mc_watts;
    mix_idx=1:1:mid;     %%%%Mix in the mitigations
    temp_mc_pr_watts(mix_idx)=mitigation_binary_sort_mc_watts(mix_idx);
    temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case

    check_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);  %%%%%%Re-calculate Aggregate Power
    if check_mc_agg_dbm>radar_threshold
        'Binary Search Error'
        check_mc_agg_dbm
        pause;
    end
else
    %%%Move List is 0
    mid=0;
end

end