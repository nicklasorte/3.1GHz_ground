function parfor_wrapper_calc_pathloss_single_list_rev1(app,base_protection_pts,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx,data_label1)

sim_pt=base_protection_pts(point_idx,:);

%%%%%%Check/Calculate path loss
file_name_pathloss=strcat('ITM_Pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
[var_exist]=persistent_var_exist_with_corruption(app,file_name_pathloss);
if var_exist==0
    [ITM_Pathloss]=ITMP2P_pathfix_rev1(app,sim_array_list_bs,sim_pt,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag);
    %%%%%%Persistent Save
    [var_exist2]=persistent_var_exist_with_corruption(app,file_name_pathloss);
    if var_exist2==0
        retry_save=1;
        while(retry_save==1)
            try
                save(file_name_pathloss,'ITM_Pathloss')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    end
end
        
 
end