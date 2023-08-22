function part1_calc_ITM_pathloss_propmode_rev2(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers)

cell_status_filename='cell_itm_dll_status.mat'  
label_single_filename='imt_dll_status'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_itm_folder_names=folder_names(zero_idx)
    num_folders=length(temp_itm_folder_names)
    
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Path Loss Calculation). . .'))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Pathloss: ',num_folders);    %%%%%%% Create ParFor Waitbar
        
    
    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        
        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_itm_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);
        
        if cell_status{temp_cell_idx,2}==0
            %%%%%%%%%%Calculate
            retry_cd=1;
            while(retry_cd==1)
                try
                    cd(rev_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end
            
            retry_cd=1;
            while(retry_cd==1)
                try
                    sim_folder=temp_itm_folder_names{array_rand_folder_idx(folder_idx)};
                    cd(sim_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end
            
            disp_multifolder(app,sim_folder)
            data_label1=sim_folder;
            
            %%%%%%Check for the tf_complete_ITM file
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat'); %%%This is a marker for me
            [var_exist]=persistent_var_exist_with_corruption(app,complete_filename);
            if var_exist==2
                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end
                
                %%%%%%%%Update the Cell
                [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            else

                %%%%%%%%Calculate Path Loss
                %%%%%Persistent Load the other variables
                disp_progress(app,strcat('Loading Sim Data . . . '))
                retry_load=1;
                while(retry_load==1)
                    try
                        disp_progress(app,strcat('Loading Sim Data . . . '))
                        load(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')
                        temp_data=base_protection_pts;
                        clear base_protection_pts;
                        base_protection_pts=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
                        temp_data=sim_array_list_bs;
                        clear sim_array_list_bs;
                        sim_array_list_bs=temp_data;
                        clear temp_data;
                           % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation


                        load(strcat(data_label1,'_radar_height.mat'),'radar_height')
                        temp_data=radar_height;
                        clear radar_height;
                        radar_height=temp_data;
                        clear temp_data;
                         
                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end



                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate the pathloss
                %%%%func_calc_path_loss_single_list_rev1(app,base_protection_pts,parallel_flag,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,workers,data_label1)

                % %%%%%%%%%%%%%%Calculate Path Loss (Parallel Chunks)
                   %%%%%%Parchunk even if we have no parpool
                [num_pts,~]=size(base_protection_pts);
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                disp_progress(app,strcat('Starting the Parfor Calculate Path Loss'))

               
                if parallel_flag==0
                    num_chunks=10;
                elseif parallel_flag==1
                    num_chunks=workers; %%%%%%%%%%%%Number of workers is number of chunks
                end

                [num_bs,~]=size(sim_array_list_bs)
                chuck_size=ceil(num_bs/num_chunks);
                cell_sim_chuck_idx=cell(num_chunks,1);
                for sub_idx=1:1:num_chunks  %%%%%%Define the sim idxs
                    if sub_idx==num_chunks
                        start_idx=(sub_idx-1).*chuck_size+1;
                        stop_idx=num_bs;
                        temp_sim_idx=start_idx:1:stop_idx;
                    else
                        start_idx=(sub_idx-1).*chuck_size+1;
                        stop_idx=sub_idx.*chuck_size;
                        temp_sim_idx=start_idx:1:stop_idx;
                    end
                    cell_sim_chuck_idx{sub_idx}=temp_sim_idx;
                end
                %%%%%Check
                missing_idx=find(diff(horzcat(cell_sim_chuck_idx{:}))>1);
                num_idx=length(unique(horzcat(cell_sim_chuck_idx{:})));
                if ~isempty(missing_idx) || num_idx~=num_bs
                    'Error:Check Chunk IDX'
                    pause;
                end

                [hWaitbar_points,hWaitbarMsgQueue_points]= ParForWaitbarCreateMH_time('Path Loss Points: ',num_pts);    %%%%%%% Create ParFor Waitbar

                for point_idx=1:1:num_pts
                    file_name_pathloss=strcat('ITM_Pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                    file_name_prop_mode=strcat('ITM_prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');

                    %%%%Check if it's there
                    [var_exist1]=persistent_var_exist_with_corruption(app,file_name_pathloss);
                    [var_exist2]=persistent_var_exist_with_corruption(app,file_name_prop_mode);
                    if var_exist1==0 || var_exist2==0
                        if parallel_flag==1
                            [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Path Loss Chunks: ',num_chunks);    %%%%%%% Create ParFor Waitbar
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            parfor sub_point_idx=1:num_chunks  %%%%%%%%%Parfor
                                parfor_parchunk_itm_rev2(app,cell_sim_chuck_idx,sub_point_idx,sim_array_list_bs,base_protection_pts,sim_number,data_label1,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx);
                                hWaitbarMsgQueue.send(0);
                            end
                            delete(hWaitbarMsgQueue);
                            close(hWaitbar);
                        end

                        %%%%%%%%%Then Assemble with for loop

                        %%%%%%%%%Then Assemble with for loop
                        cell_itm_pathloss=cell(num_chunks,1);
                        cell_itm_mode=cell(num_chunks,1);
                        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Path Loss Chunks: ',num_chunks);    %%%%%%% Create ParFor Waitbar
                        for sub_point_idx=1:num_chunks  %%%%%%%%%Parfor
                            [cell_itm_pathloss{sub_point_idx},cell_itm_mode{sub_point_idx}]=parfor_parchunk_itm_rev2(app,cell_sim_chuck_idx,sub_point_idx,sim_array_list_bs,base_protection_pts,sim_number,data_label1,reliability,confidence,radar_height,FreqMHz,Tpol,parallel_flag,point_idx);
                            hWaitbarMsgQueue.send(0);
                        end
                        delete(hWaitbarMsgQueue);
                        close(hWaitbar);

                        ITM_Pathloss=vertcat(cell_itm_pathloss{:});
                        ITM_prop_mode=vertcat(cell_itm_mode{:});
                        % 0 LOS, 4 Single Horizon, 5 Difraction Double Horizon, 8 Double Horizon, 9 Difraction Single Horizon, 6 Troposcatter Single Horizon, 10 Troposcatter Double Horizon, 333 Error

                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_pathloss,'ITM_Pathloss')
                                save(file_name_prop_mode,'ITM_prop_mode')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(1)
                            end
                        end
                    end
                    hWaitbarMsgQueue_points.send(0);
                end
                delete(hWaitbarMsgQueue_points);
                close(hWaitbar_points);              


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        itm_comp_list=NaN(1);
                        save(complete_filename,'itm_comp_list')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end
                
                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end
                [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end
