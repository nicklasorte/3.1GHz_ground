function part2_movelist_calculation_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,tf_write_movelist_excel)

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
        [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Move List: ',num_folders);    %%%%%%% Create ParFor Waitbar
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
            complete_filename=strcat(data_label1,'_MoveList_complete.mat'); %%%This is a marker for me
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
                %[cell_neighborhood_status]=update_neighborhood_cell_rev1(app,folder_names,sim_folder); %%%%%%%%%%%%%%%%%%No update for on the move list --> Update when we have the Aggregate check
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

                %%%%%%%%%%First check for the union move list
                %%%%%%%%%First, check to see if the union of the move list exists
                file_name_union_move=strcat(data_label1,'_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);
                if file_union_move_exist==0 %%%The File Does not exist, we will calculate it
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List



                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    if parallel_flag==1
                        disp_progress(app,strcat('Starting the Parfor Move List: Maybe 1-2 mins:(per point with 1 Monte Carlo Iteration)'))
                        [hWaitbar,hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Move List: ',num_ppts);    %%%%%%% Create ParFor Waitbar
                        parfor point_idx=1:num_ppts
                            pre_sort_movelist_rev5_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                            hWaitbarMsgQueue.send(0);
                        end
                        delete(hWaitbarMsgQueue);
                        close(hWaitbar);
                    end


                    %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                    %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                    %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                    %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                    cell_move_list_turn_off_data=cell(num_ppts,1);
                    cell_move_list_idx=cell(num_ppts,1);  %%%%%%%%%%This is used as a way to check.
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        [move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,~,~,~,~]=pre_sort_movelist_rev5_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                        cell_move_list_turn_off_data{point_idx}=sort_sim_array_list_bs(move_list_turn_off_idx,:);
                        cell_move_list_idx{point_idx}=unique(sim_array_list_bs(sort_bs_idx(move_list_turn_off_idx),5));
                        %%%%'To prevent the possibility of memory issues, may need to write the excel file right here after each point. But then we cant parfor the calculation. Just load in all the data after the calculation.'
                    end
                    toc;

                    array_uni_nick_id_move_list_idx=unique(vertcat(cell_move_list_idx{:}));
                    union_turn_off_list_data=unique(vertcat(cell_move_list_turn_off_data{:}),'rows');

                    if ~all(unique(union_turn_off_list_data(:,5))==array_uni_nick_id_move_list_idx)
                        'Might need to check the move list idx'
                        pause;
                    end

                    %%%%%%%%'Export the union move List of the Base Stations'
                    union_turn_off_list_data(1,:)
                    [~,sort_union_idx]=sort(union_turn_off_list_data(:,5));
                    table_union_move_list=array2table(union_turn_off_list_data(sort_union_idx,[1,2,3,5,6,7,9]));
                    table_union_move_list.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'EIRP'};
                    tic;
                    writetable(table_union_move_list,strcat(data_label1,'_Union_Move_List_OFF.xlsx'));
                    toc;

                    %%%%%%%%%Output the Excel Table Link Budgets

                    if tf_write_movelist_excel==1
                        write_excel_movelist_rev1(app,num_ppts,move_list_reliability,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,radar_height)
                    end

                    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %                     %%%%%%%%%Make some graphics
                    nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                    [idx_knn]=knnsearch(nnan_base_polygon,union_turn_off_list_data(:,[1:2]),'k',1); %%%Find Nearest Neighbor
                    base_knn_array=nnan_base_polygon(idx_knn,:);
                    knn_dist_bound=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),union_turn_off_list_data(:,1),union_turn_off_list_data(:,2)));%%%%Calculate Distance
                    max_knn_dist=ceil(max(knn_dist_bound))



                    %%%%%%%%%%Maybe add those still on, but don't show the entire 600km radius
                    [C_on,ia_on,ib_on]=intersect(sim_array_list_bs,union_turn_off_list_data,'rows');
                    on_list_bs=sim_array_list_bs;
                    on_list_bs(ia_on,:)=[];  %%%%%%%Cut ia from A


                    %%%%%%%%%%%Find those base stations to be kept on
                    %%close all; %%%%%%%%%%%This is closing the waitbar.
                    f1=figure;
                    hold on;
                    plot(union_turn_off_list_data(:,2),union_turn_off_list_data(:,1),'sr','LineWidth',2)
                    plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                    title(strcat('Max Turn Off Distance:',num2str(max_knn_dist),'km'))
                    grid on;
                    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    temp_axis=axis;
                    %%%%%%%%%%Replot for the right "layering"
                    plot(on_list_bs(:,2),on_list_bs(:,1),'og','LineWidth',2)
                    plot(union_turn_off_list_data(:,2),union_turn_off_list_data(:,1),'sr','LineWidth',2)
                    plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    axis(temp_axis)
                    filename1=strcat(data_label1,'_Off.png');
                    pause(0.1)
                    saveas(gcf,char(filename1))
                    pause(0.1)
                    close(f1)


                    f2=figure;
                    hold on;
                    histogram(knn_dist_bound)
                    grid on;
                    xlabel('Turn Off Distance [km]')
                    ylabel('Number of Occurrences')
                    filename1=strcat(data_label1,'_Histogram_Turn_Off_Distance.png');
                    pause(0.1)
                    saveas(gcf,char(filename1))
                    pause(0.1)
                    close(f2)

              

                    %%%%%%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(file_name_union_move,'union_turn_off_list_data')
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Can make this the simple move list/union Function (non-mitigations)

%                 %%%%%%%%%%Save
%                 [var_exist_complete]=persisent_file_exist_app(app,complete_filename);
%                 if var_exist_complete==2
%                     %%%%%Nothing
%                 else
%                     retry_save=1;
%                     while(retry_save==1)
%                         try
%                             complete=NaN(1);
%                             %save(complete_filename,'complete')
%                             pause(0.1);
%                             retry_save=0;
%                         catch
%                             retry_save=1;
%                             pause(0.1)
%                         end
%                     end
%                 end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%Single Location Should be complete at this point

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
            %[cell_neighborhood_status]=update_neighborhood_cell_rev1(app,folder_names,sim_folder); %%%%%%%%%%%%%%%%%No update for on the move list --> Update when we have the Aggregate check
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