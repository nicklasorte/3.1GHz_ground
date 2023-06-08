function func_calc_path_loss_single_list_rev1(app,base_protection_pts,parallel_flag,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,workers,data_label1)

% %%%%%%%%%%%%%%Calculate Path Loss
[num_pts,~]=size(base_protection_pts);
if parallel_flag==1
    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
    disp_progress(app,strcat('Starting the Parfor Calculate Path Loss'))
    [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Path Loss: ',num_pts);    %%%%%%% Create ParFor Waitbar
    parfor point_idx=1:num_pts
        parfor_wrapper_calc_pathloss_single_list_rev1(app,base_protection_pts,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx,data_label1)
        hWaitbarMsgQueue.send(0);
    end
    delete(hWaitbarMsgQueue);
    close(hWaitbar);
end

if parallel_flag==0
    disp_progress(app,strcat('Starting the ForLoop Calculate Path Loss'))
    for point_idx=1:1:num_pts
        parfor_wrapper_calc_pathloss_single_list_rev1(app,base_protection_pts,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx,data_label1)
    end
end

end