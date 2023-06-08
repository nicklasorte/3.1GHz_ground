function part1_calc_pathloss_3dot1GHz_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers)

location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_itm_status]=initialize_or_load_itm_status_rev1(app,folder_names)
zero_idx=find(cell2mat(cell_itm_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_itm_folder_names=folder_names(zero_idx)
    num_folders=length(temp_itm_folder_names)
    
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Path Loss Calculation). . .'))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    array_rand_folder_idx=randsample(num_folders,num_folders,false);
    %array_rand_folder_idx=256;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if parallel_flag==1
        [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder ITM: ',num_folders);    %%%%%%% Create ParFor Waitbar
    end
        
    
    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        
        %%%%%%%Load
        [cell_itm_status]=initialize_or_load_itm_status_rev1(app,folder_names);
        sim_folder=temp_itm_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_itm_status(:,1),sim_folder)==1);
        
        if cell_itm_status{temp_cell_idx,2}==0
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
                    %%%%%%%%%Exclusion Zone Function {WRAPPER}
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
            
            data_label1=sim_folder
            
            %%%%%%Check for the tf_complete_ITM file
            itm_complete_filename=strcat(data_label1,'_ITM_COMPLETE.mat'); %%%This is a marker for me
            [var_exist]=persistent_var_exist_with_corruption(app,itm_complete_filename);
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
                [cell_itm_status]=update_itm_cell_rev1(app,folder_names,sim_folder);
            else


                %%%%%%%%Calculate Path Loss
                %%%%%%%%%%%%%%%%CBSD Neighborhood Search Parameters
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

        

                        %%%%%load('radar_height.mat','radar_height')
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

                %%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate the pathloss
                func_calc_path_loss_single_list_rev1(app,base_protection_pts,parallel_flag,sim_number,sim_array_list_bs,reliability,confidence,radar_height,FreqMHz,Tpol,workers,data_label1)
                

                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        itm_comp_list=NaN(1);
                        save(itm_complete_filename,'itm_comp_list')
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
                [cell_itm_status]=update_itm_cell_rev1(app,folder_names,sim_folder);
            end
        end
        
        if parallel_flag==1
            multi_hWaitbarMsgQueue.send(0);
        end
        
    end
    
    if parallel_flag==1
        delete(multi_hWaitbarMsgQueue);
        close(multi_hWaitbar);
    end
end

disp_progress(app,strcat('Pathloss Calculations Completed'))