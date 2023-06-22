function part3_mitigation_calculation_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,tf_write_movelist_excel)

location_table=table([1:1:length(folder_names)]',folder_names)


%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_neighborhood_status]=initialize_or_load_neighborhood_status_rev1(app,folder_names);
zero_idx=find(cell2mat(cell_neighborhood_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_itm_folder_names=folder_names(zero_idx);
    num_folders=length(temp_itm_folder_names)


    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Before Multi Folder Loop). . .'))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    array_rand_folder_idx=randsample(num_folders,num_folders,false);

    if parallel_flag==1
        [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Mitigation: ',num_folders);    %%%%%%% Create ParFor Waitbar
    end

    for folder_idx=1:1:num_folders

        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.

        %%%%%%%Load
        [cell_neighborhood_status]=initialize_or_load_neighborhood_status_rev1(app,folder_names);
        sim_folder=temp_itm_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_neighborhood_status(:,1),sim_folder)==1);

        if cell_neighborhood_status{temp_cell_idx,2}==0
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

            %%%%%%Check for COMPLETE file
            complete_filename=strcat(data_label1,'_MitigationMoveList_complete.mat'); %%%This is a marker for me
            [var_exist_complete]=persisent_file_exist_app(app,complete_filename);
            if var_exist_complete==2
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
                %[cell_neighborhood_status]=update_neighborhood_cell_rev1(app,folder_names,sim_folder);
            else

                %%%%%%%%%%%%%%%%%Persistent Load the other variables
                disp_progress(app,strcat('Loading Sim Data . . . '))
                retry_load=1;
                while(retry_load==1)
                    try
                        disp_progress(app,strcat('Loading Sim Data . . . '))
                        load(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
                        temp_data=base_polygon;
                        clear base_polygon;
                        base_polygon=temp_data;
                        clear temp_data;

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

                        load(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
                        temp_data=min_ant_loss;
                        clear min_ant_loss;
                        min_ant_loss=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_radar_height.mat'),'radar_height')
                        temp_data=radar_height;
                        clear radar_height;
                        radar_height=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')
                        temp_data=radar_threshold;
                        clear radar_threshold;
                        radar_threshold=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_radar_beamwidth.mat'),'radar_beamwidth')
                        temp_data=radar_beamwidth;
                        clear radar_beamwidth;
                        radar_beamwidth=temp_data;
                        clear temp_data;

                        % % %      tic;
                        % % %      load(strcat(data_label1,'_sim_cell_bs_data.mat'),'sim_cell_bs_data')
                        % % %      toc; %%%%%%%%%3 seconds
                        %%%1) LaydownID
                        %%%2) FCCLicenseID
                        %%%3) SiteID
                        %%%4) SectorID
                        %%%5) SiteLatitude_decDeg
                        %%%6) SiteLongitude_decDeg
                        %%%7) SE_BearingAngle_deg
                        %%%8) SE_AntennaAzBeamwidth_deg
                        %%%9) SE_DownTilt_deg  %%%%%%%%%%%%%%%%%(Check for Blank)
                        %%%10) SE_AntennaHeight_m
                        %%%11) SE_Morphology
                        %%%12) SE_CatAB
                        %%%%%%%%%%13) NLCD idx
                        %%%%%%%%%14) EIRP (no mitigations)
                        %%%%%%%%%15) EIRP (mitigations)

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move list
                disp_progress(app,strcat('Starting the Move List . . . '))
                [num_ppts,~]=size(base_protection_pts);
                %%%%%%%%%%%%%%%%Don't worry about single vs multi point
                %%%%%%%%%%%%%%%%now.

                if parallel_flag==1  %%%%%%%%%%%%Double Check for par
                    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                end

                   %%%%First check if there are mitigation EIRPs (column 8)
                %%%%%%%%If there is no mitigation EIRPs, all of these will be NaNs (column 8)
                if ~all(isnan(sim_array_list_bs(:,8)))
                    file_name_union_move_miti_off=strcat(data_label1,'_mitigation_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    file_name_union_move_miti_miti=strcat(data_label1,'_mitigation_union_mitigation_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    [file_union_move_exist_mit1]=persistent_var_exist_with_corruption(app,file_name_union_move_miti_off);
                    [file_union_move_exist_mit2]=persistent_var_exist_with_corruption(app,file_name_union_move_miti_off);

                    if file_union_move_exist_mit1==2 && file_union_move_exist_mit2==2

                    else
                      %%%The File Does not exist, we will calculate it
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                        if parallel_flag==1
                            disp_progress(app,strcat('Starting the Parfor Move List'))
                            [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Mitigation Move List: ',num_ppts);    %%%%%%% Create ParFor Waitbar
                            parfor point_idx=1:num_ppts
                                pre_sort_mitigation_movelist_rev6_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                                hWaitbarMsgQueue.send(0);
                            end
                            delete(hWaitbarMsgQueue);
                            close(hWaitbar);
                        end

                        %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                        %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                        cell_mitigation_move_list_turn_off_data=cell(num_ppts,1);  %%%%%%%%%Off
                        cell_mitigation_move_list_mitigation_data=cell(num_ppts,1);    %%%%%%Mitigations
                        for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                            point_idx                    
                            [off_list_bs,mitigation_list_bs,mitigation_sort_sim_array_list_bs,mitigation_sort_bs_idx]=pre_sort_mitigation_movelist_rev6_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                            cell_mitigation_move_list_turn_off_data{point_idx}=off_list_bs;
                            cell_mitigation_move_list_mitigation_data{point_idx}=mitigation_list_bs;
                        end
                        toc;

                        mitigation_union_turn_off_list_data=unique(vertcat(cell_mitigation_move_list_turn_off_data{:}),'rows');
                        mitigation_union_mitigation_list_data=unique(vertcat(cell_mitigation_move_list_mitigation_data{:}),'rows');

                        %%%%%%%%First check if there are any overlap between the off and mitigation list.
                        %%%%%%%%%Change them to just the off list
                        [C,ia,ib]=intersect(mitigation_union_turn_off_list_data,mitigation_union_mitigation_list_data,'rows');

                        %%%%%%%%%C = A(ia) and C = B(ib).
                        all(mitigation_union_turn_off_list_data(ia,5)==mitigation_union_mitigation_list_data(ib,5))
                        
                        %%%%%%Cut ib from B
                        size(mitigation_union_mitigation_list_data)
                        mitigation_union_mitigation_list_data(ib,:)=[];
                        size(mitigation_union_mitigation_list_data)

                        %%%%%%%%'Export the union move List of the Base Stations'
                        mitigation_union_turn_off_list_data(1,:)
                        [~,sort_union_idx]=sort(mitigation_union_turn_off_list_data(:,5));
                        table_union_move_list_off=array2table(mitigation_union_turn_off_list_data(sort_union_idx,[1,2,3,5,6,7,9]));
                        table_union_move_list_off.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'EIRP'};
                        tic;
                        writetable(table_union_move_list_off,strcat(data_label1,'_Union_Move_List_Mitigation.xlsx'),'Sheet','Turn_Off');
                        toc;

                        %%%%%%%%'Export the union move List of the Base Stations'
                        mitigation_union_mitigation_list_data(1,:)
                        [~,sort_union_idx]=sort(mitigation_union_mitigation_list_data(:,5));
                        miti_eirp=mitigation_union_mitigation_list_data(:,9)-mitigation_union_mitigation_list_data(:,15);
                        table_union_move_list_miti=array2table(horzcat(mitigation_union_mitigation_list_data(sort_union_idx,[1,2,3,5,6,7]),miti_eirp));
                        table_union_move_list_miti.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'Mitigation_EIRP'};
                        tic;
                        writetable(table_union_move_list_miti,strcat(data_label1,'_Union_Move_List_Mitigation.xlsx'),'Sheet','Mitigation');
                        toc;


                         %%%%%%%%%%Maybe add those still on, but don't show the entire 600km radius
                         miti_off_data=unique(vertcat(mitigation_union_turn_off_list_data,mitigation_union_mitigation_list_data),'rows');                
                        [C_on,ia_on,ib_on]=intersect(sim_array_list_bs,miti_off_data,'rows');
                        on_list_bs=sim_array_list_bs;
                        on_list_bs(ia_on,:)=[];  %%%%%%%Cut ia from A

                        size(sim_array_list_bs)
                        size(on_list_bs)
                        size(miti_off_data)

                        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %                     %%%%%%%%%Make some graphics
                        %%%%%%%%%%%%%%Calculate the Max Turn Off Distance
                        nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                        [idx_knn]=knnsearch(nnan_base_polygon,mitigation_union_turn_off_list_data(:,[1:2]),'k',1); %%%Find Nearest Neighbor
                        base_knn_array=nnan_base_polygon(idx_knn,:);
                        knn_dist_bound=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),mitigation_union_turn_off_list_data(:,1),mitigation_union_turn_off_list_data(:,2)));%%%%Calculate Distance
                        max_knn_dist_off=ceil(max(knn_dist_bound))

                        %%%%%%%%%%%%%%Calculate the Max Mitigation Distance
                        nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                        [idx_knn]=knnsearch(nnan_base_polygon,mitigation_union_mitigation_list_data(:,[1:2]),'k',1); %%%Find Nearest Neighbor
                        base_knn_array=nnan_base_polygon(idx_knn,:);
                        knn_dist_bound=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),mitigation_union_mitigation_list_data(:,1),mitigation_union_mitigation_list_data(:,2)));%%%%Calculate Distance
                        max_knn_dist_miti=ceil(max(knn_dist_bound))

                       
                        %%%close all;  %%%%%%[close all] creates problems in the app
                        f3=figure;
                        hold on;
                        plot(mitigation_union_mitigation_list_data(:,2),mitigation_union_mitigation_list_data(:,1),'dy','LineWidth',2)
                        plot(mitigation_union_turn_off_list_data(:,2),mitigation_union_turn_off_list_data(:,1),'sr','LineWidth',2)
                        plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                        grid on;
                        plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                        temp_axis=axis;
                        %%%%%%%%%%Replot for the right "layering"
                        plot(on_list_bs(:,2),on_list_bs(:,1),'og','LineWidth',2)
                        plot(mitigation_union_mitigation_list_data(:,2),mitigation_union_mitigation_list_data(:,1),'dy','LineWidth',2)
                        plot(mitigation_union_turn_off_list_data(:,2),mitigation_union_turn_off_list_data(:,1),'sr','LineWidth',2)
                        plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                        title({strcat('Max Turn Off Distance:',num2str(max_knn_dist_off),'km'),strcat('Max Mitigation Distance:',num2str(max_knn_dist_miti),'km')})
                        plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                        axis(temp_axis)
                        filename1=strcat(data_label1,'_Off_Mitigation.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)
                        close(f3)

                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_union_move_miti_off,'mitigation_union_turn_off_list_data')
                                save(file_name_union_move_miti_miti,'mitigation_union_mitigation_list_data')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of the mitigations (COA 1 & 2) Move List/Union Function

                %%%%%%%%%%Save
                [var_exist_complete]=persisent_file_exist_app(app,complete_filename);
                if var_exist_complete==2
                    %%%%%Nothing
                else
                    retry_save=1;
                    while(retry_save==1)
                        try
                            complete=NaN(1);
                            %save(complete_filename,'complete')
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%Single Location Should be complete at this point

            if parallel_flag==1
                multi_hWaitbarMsgQueue.send(0);
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
            %%%%%%%%Update the Cell
            %[cell_neighborhood_status]=update_neighborhood_cell_rev1(app,folder_names,sim_folder);
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


end