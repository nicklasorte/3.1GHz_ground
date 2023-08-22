function propagation_clean_up_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,workers,string_prop_model,num_chunks)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function: 
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_chunk_cleanup_status.mat')  
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_chunk_cleanup_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);
    
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Path Loss Calculation). . .',string_prop_model))
    %%%reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Pathloss Clean Up: ',num_folders);    %%%%%%% Create ParFor Waitbar
        
    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        
        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
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
                    sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
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
            
            %%%%%%Check for the complete_filename
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

                         
                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                

                % %%%%%%%%%%%%%%Calculate Path Loss (Parallel Chunks)
                   %%%%%%Parchunk even if we have no parpool
                [num_pts,~]=size(base_protection_pts);
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                disp_progress(app,strcat('Starting the Parfor Calculate Path Loss'))               

                [num_bs,~]=size(sim_array_list_bs);
                chuck_size=floor(num_bs/num_chunks);
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

                [hWaitbar_cleanup,hWaitbarMsgQueue_cleanup]= ParForWaitbarCreateMH_time('Path Loss Clean Up: ',num_pts*num_chunks);    %%%%%%% Create ParFor Waitbar, this one covers points and chunks

                for point_idx=1:1:num_pts
                    file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat')
                    file_name_prop_mode=strcat(string_prop_model,'_prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat')

                    %%%%Check if it's there
                    [var_exist1]=persistent_var_exist_with_corruption(app,file_name_pathloss);
                    [var_exist2]=persistent_var_exist_with_corruption(app,file_name_prop_mode);

                    tf_file_check_loop=1;
                    while(tf_file_check_loop==1)
                        try
                            [var_exist1]=persistent_var_exist_with_corruption(app,file_name_pathloss);
                            [var_exist2]=persistent_var_exist_with_corruption(app,file_name_prop_mode);
                            pause(0.1);
                        catch
                            pause(0.1)
                        end
                         if var_exist1==2 && var_exist2==2
                             tf_file_check_loop=0;
                         else
                             disp_progress(app,strcat('The files dont exist and we should not delete the subchunks. Wait for other servers to catch up.'))
                             pause(1)
                         end
                    end


                    if var_exist1==2 && var_exist2==2
                        %%%%%%%%%Loop for deleting
                        for sub_point_idx=1:num_chunks  
                            file_name_pathloss=strcat('sub_',num2str(sub_point_idx),'_',string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                             [var_exist3]=persistent_var_exist_with_corruption(app,file_name_pathloss);
                             if var_exist3==2
                                 retry_delete=1;
                                 while(retry_delete==1)
                                     try
                                         delete(file_name_pathloss)
                                         pause(0.1);
                                         retry_delete=0;
                                     catch
                                         retry_delete=1;
                                         pause(0.1)
                                     end
                                 end
                             end

                            file_name_propmode=strcat('sub_',num2str(sub_point_idx),'_',string_prop_model,'_prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                            [var_exist4]=persistent_var_exist_with_corruption(app,file_name_propmode);
                            if var_exist4==2
                                retry_delete=1;
                                while(retry_delete==1)
                                    try
                                        delete(file_name_propmode)
                                        pause(0.1);
                                        retry_delete=0;
                                    catch
                                        retry_delete=1;
                                        pause(0.1)
                                    end
                                end
                            end
                            hWaitbarMsgQueue_cleanup.send(0);
                        end
                    else
                        disp_progress(app,strcat('Error: While Loop did not work. The files dont exist and we should not delete the subchunks.'))
                        pause;
                    end
                end
                delete(hWaitbarMsgQueue_cleanup);
                close(hWaitbar_cleanup);
 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        comp_list=NaN(1);
                        save(complete_filename,'comp_list')
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


end