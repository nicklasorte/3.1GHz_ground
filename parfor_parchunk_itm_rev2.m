function [ITM_Pathloss,ITM_prop_mode]=parfor_parchunk_itm_rev2(app,cell_sim_chuck_idx,sub_point_idx,sim_array_list_bs,base_protection_pts,sim_number,data_label1,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Parchunk ParWrapper
sub_idx=cell_sim_chuck_idx{sub_point_idx};
sub_sim_array_list_bs=sim_array_list_bs(sub_idx,:);
sim_pt=base_protection_pts(point_idx,:);

%%%%%%Check/Calculate path loss
file_name_pathloss=strcat('sub_',num2str(sub_point_idx),'_ITM_Pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
file_name_propmode=strcat('sub_',num2str(sub_point_idx),'_ITM_Prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
[var_exist1]=persistent_var_exist_with_corruption(app,file_name_pathloss);
[var_exist2]=persistent_var_exist_with_corruption(app,file_name_propmode);
if var_exist1==0 || var_exist2==0
    %%%%[ITM_Pathloss]=ITMP2P_pathfix_rev1(app,sub_sim_array_list_bs,sim_pt,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag);
    [ITM_Pathloss,ITM_prop_mode]=ITMP2P_mechanism_rev3(app,sub_sim_array_list_bs,sim_pt,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag);
    %%%%%%Persistent Save
    [var_exist2]=persistent_var_exist_with_corruption(app,file_name_pathloss);
    if var_exist2==0
        retry_save=1;
        while(retry_save==1)
            try
               save(file_name_propmode,'ITM_prop_mode')
               save(file_name_pathloss,'ITM_Pathloss')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    end
end

%%%%%%Load
[var_exist3]=persistent_var_exist_with_corruption(app,file_name_pathloss);
if var_exist3==2
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_pathloss,'ITM_Pathloss')
            load(file_name_propmode,'ITM_prop_mode')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of Wrapper

end