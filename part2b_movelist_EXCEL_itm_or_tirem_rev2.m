function part2b_movelist_EXCEL_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_write_movelist_excel)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function: 
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_ML_excel_status.mat')  
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_ML_excel_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename)
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);
    
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Move List--Writing Excel). . .',string_prop_model))
    %%%%reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    

    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Move List Excel: ',num_folders);    %%%%%%% Create ParFor Waitbar
        
    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        
        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);
        temp_cell_idx
        
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
                disp_progress(app,strcat('Starting the Move List Excel Writing. . . '))
                [num_ppts,~]=size(base_protection_pts)

                if parallel_flag==1  %%%%%%%%%%%%Double Check to start the parpool
                    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                end

                if strcmp(string_prop_model,'TIREM')
                    if length(move_list_reliability)>1
                        %%%%%%%%%TIREM only does single "reliability"
                        %%%%%This will make it so we aren't doing duplicate
                        %%%%%calculations and thinking that we are doing a
                        %%%%%calculation that really isn't being done.
                        move_list_reliability=50;
                    end
                    if move_list_reliability~=50
                        %%%%%TIREM only does "50", can't do 10% or 1%, etc.
                        move_list_reliability=50;
                    end
                end


                    %%%%%%%%%%%Make a Table for each protection point
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                    %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                    %%%'To prevent the possibility of memory issues, may need to write the excel file right here after each point. But then we cant parfor the calculation. Just load in all the data after the calculation.'
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        [move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,array_bs_azi_data,sort_full_Pr_dBm,sorted_array_fed_azi_data,sorted_array_mc_pr_dbm]=pre_sort_movelist_rev6_string_prop_model_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model);
                        %%[move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,array_bs_azi_data,sort_full_Pr_dBm,sorted_array_fed_azi_data,sorted_array_mc_pr_dbm]=pre_sort_movelist_rev5_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%Load propagation for the Output Excel File
                        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                        file_name_prop_mode=strcat(string_prop_model,'_prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_pathloss,'pathloss')
                                load(file_name_prop_mode,'prop_mode')
                                retry_load=0;
                            catch
                                retry_load=1;
                                pause(1)
                            end
                        end

                        %%%%%%%%%%Clean up the prop_mode
                        if strcmp(string_prop_model,'TIREM')
                            num_cells=length(prop_mode);
                            cell_prop_mode=cell(num_cells,1);
                            for prop_idx=1:1:num_cells
                                temp_structure=prop_mode{prop_idx};
                                cell_prop_mode{prop_idx}=temp_structure.PropagationMode;
                            end
                        end
                        if strcmp(string_prop_model,'ITM')
                            num_cells=length(prop_mode);
                            cell_prop_mode=cell(num_cells,1);
                            for prop_idx=1:1:num_cells
                                num_prop_mode=prop_mode(prop_idx);
                                if num_prop_mode==0
                                    temp_prop_mode='LOS';
                                elseif num_prop_mode==4
                                    temp_prop_mode='Single Horizon';
                                elseif num_prop_mode==5
                                    temp_prop_mode='Difraction Double Horizon';
                                elseif num_prop_mode==8
                                    temp_prop_mode='Double Horizon';
                                elseif num_prop_mode==9
                                    temp_prop_mode='Difraction Single Horizon';
                                elseif num_prop_mode==6
                                    temp_prop_mode='Troposcatter Single Horizon';
                                elseif num_prop_mode==10
                                    temp_prop_mode='Troposcatter Double Horizon';
                                elseif num_prop_mode==333
                                    temp_prop_mode='Error';
                                else
                                    'Undefined Propagation Mode'
                                    pause;
                                end
                                cell_prop_mode{prop_idx}=temp_prop_mode;
                            end
                        end

                        sort_cell_prop_mode=cell_prop_mode(sort_bs_idx);

                        %%%%%%%% Cut the reliabilities that we will use for the move list
                        size(pathloss)
                        [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
                        [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
                        if strcmp(string_prop_model,'TIREM')
                            % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
                        else
                            pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
                        end
                        size(pathloss)
                        temp_sort_pathloss=pathloss(sort_bs_idx,:);
                        temp_sort_Pr_dBm=sort_full_Pr_dBm;
                        [~,pr_width]=size(sort_full_Pr_dBm);
                        if pr_width>1
                            'Need to change how we save the Pr_dBm in the spreadsheet'
                            pause;
                        end

                        temp_sorted_list_data=sort_sim_array_list_bs;
                        [num_tx,~]=size(sort_sim_array_list_bs);
                        sim_pt=base_protection_pts(point_idx,:);
                        sorted_array_bs_azi_data=array_bs_azi_data(sort_bs_idx,:);
                        %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel
                        % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
                        %%%%%%%9) EIRP dBm:         array_bs_eirp
                        %%%%%%%10) AAS (Vertical) dB Reduction: (Downtilt)   %%%%%%%%Downtilt dB Value for Rural/Suburban/Urban
                        %%%%%%%%%11)Clutter
                        %%%%%%%%%12)Network Loading and TDD (dB)
                        %%%%%%%%%13)FDR (dB)
                        %%%%%%%%%14)Polarization (dB)
                        %%%%%%%%%15)Mitigation Reduction (dB)


                        %%%%%%%%%%Make a table: 
                        % %%%%%%%%1) 1Uni_Id
                        % %%%%%%%%2) 2BS_Latitude_DD 
                        % %%%%%%%%3) 3BS_Longitude_DD 
                        % %%%%%%%%4) 4BS_Height_m 
                        % %%%%%%%%5) 5Fed_Latitude_DD 
                        % %%%%%%%%6) 6Fed_Longitude_DD
                        % %%%%%%%%7) 7Fed_Height_m
                        % %%%%%%%%8) 8BS_EIRP_dBm
                        % %%%%%%%%9) 9BS_Downtilt_Loss_dB
                        %%%%%%%%%% 10BS_to_Fed_Azimuth_Degrees
                        %%%%%%%%%% 11BS_Sector_Azi_Degrees
                        %%%%%%%%%% 12BS_Azi_Diff_Degrees
                        %%%%%%%%%% 13Mod_BS_Azi_Diff_Degrees
                        %%%%%%%%%% 14BS_Horizonal_Off_Axis_Gain_dB
                        % %%%%%%%% 15Clutter_dB
                        %%%%%%%%%% 16Path_Loss_dB
                        % %%%%%%%% 17NetworkLoading_TDD_Loss_dB
                        %%%%%%%%%% 18FDR_dB
                        % %%%%%%%% 19Polarization_Mismatch_Loss_dB
                        % %%%%%%%% 20PowerReceived_dBm_No_Fed_Ant
                        %%%%%%%%%% 21TF_Turn_Off
                        % %%%%%%%% 22Propagation_Mode

                        array_excel_data=horzcat(temp_sorted_list_data(:,5),temp_sorted_list_data(:,[1,2,3]),sim_pt.*ones(num_tx,1),radar_height.*ones(num_tx,1),temp_sorted_list_data(:,[9,10]),sorted_array_bs_azi_data,temp_sorted_list_data(:,[11]),temp_sort_pathloss,temp_sorted_list_data(:,[12,13,14]),temp_sort_Pr_dBm);
                        array_excel_data(move_list_turn_off_idx,end+1)=1;  %%%%%%%%%%%This is just the turn off idx for the single point calculated
                        array_excel_data([1:10],:)
                        size(array_excel_data)
                        

                        %%%%%%%%Double check the Calculation (Indexs will change due to more data added)
                        %%%%%%%%%%Full EIRP - BS_Downtilt + BS_Azi_Gain -
                        %%%%%%%%%%Clutt - Network Load - FDR - Pol_Mismatch
                        %%%%%%indy_Pr_dBm=temp_sorted_list_data(:,4)-temp_sort_ITM+sorted_array_bs_azi_data(:,end);
                        indy_Pr_dBm=temp_sorted_list_data(:,9)-temp_sorted_list_data(:,10)-temp_sorted_list_data(:,11)-temp_sorted_list_data(:,12)-temp_sorted_list_data(:,13)-temp_sorted_list_data(:,14)-temp_sort_pathloss+sorted_array_bs_azi_data(:,end);

                        % % % %                         indy_adjusted_EIRP=temp_sorted_list_data(:,9)-temp_sorted_list_data(:,10)-temp_sorted_list_data(:,11)-temp_sorted_list_data(:,12)-temp_sorted_list_data(:,13)-temp_sorted_list_data(:,14);
                        % % % %                         horzcat(indy_adjusted_EIRP(1),temp_sorted_list_data(1,4))

                        horzcat(temp_sort_Pr_dBm(1),indy_Pr_dBm(1))
                        temp_sort_Pr_dBm(1)-indy_Pr_dBm(1)
                        if ~all(round(temp_sort_Pr_dBm,2)==round(indy_Pr_dBm,2))
                            mismatch_idx=find(temp_sort_Pr_dBm~=indy_Pr_dBm)
                            %horzcat(round(temp_sort_Pr_dBm(mismatch_idx),2),round(indy_Pr_dBm(mismatch_idx),2))
                            horzcat(temp_sort_Pr_dBm(mismatch_idx(1)),indy_Pr_dBm(mismatch_idx(1)))
                            'Double check link budet'
                            pause;
                        end


                        if tf_write_movelist_excel==1
                            table_move_list=horzcat(array2table(array_excel_data),cell2table(sort_cell_prop_mode));
                            table_move_list.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'BS_Downtilt_Loss_dB' 'BS_to_Fed_Azimuth_Degrees' 'BS_Sector_Azi_Degrees' 'BS_Azi_Diff_Degrees' 'Mod_BS_Azi_Diff_Degrees' 'BS_Horizonal_Off_Axis_Gain_dB' 'Clutter_dB' 'Path_Loss_dB' 'NetworkLoading_TDD_Loss_dB' 'FDR_dB' 'Polarization_Mismatch_Loss_dB' 'PowerReceived_dBm_No_Fed_Ant' 'TF_Turn_Off' 'Propagation_Mode'};
                            disp_progress(app,strcat('2 minutes to write Excel Files . . . '))


                            tic;
                            writetable(table_move_list,strcat(data_label1,'_Point',num2str(point_idx),'_Link_Budget_',string_prop_model,'.xlsx'));
                            toc;
                        end

                        %%%%%%%%%%%Calculate the Aggregate interference for
                        %%%%%%%%%%%each azimuth and with each base station
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Make this a subfunction
                        tic;
                        [sorted_agg_pr_dBm]=calculate_azimuth_aggregate_rev1(app,radar_beamwidth,min_ant_loss,base_protection_pts,point_idx,sim_array_list_bs,sort_bs_idx,norm_aas_zero_elevation_data,temp_sort_pathloss);
                        toc;
                        if tf_write_movelist_excel==1
                            table_azi_agg_data=array2table(sorted_agg_pr_dBm);
                            tic;
                            writetable(table_azi_agg_data,strcat(data_label1,'_Point',num2str(point_idx),'_Aggregate_Azimuth_',string_prop_model,'.xlsx'));
                            toc;  %%%%%%41 Seconds
                        end

                        tic;
                        [num_rows,num_azi]=size(sorted_agg_pr_dBm)
                        color_set=flipud(plasma(num_rows));
                        f1=figure;
                        hold on;
                        %%%%%%%Only plot 100 rows (38k rows takes too long)
                        if num_rows<100
                            row_step=1
                        else
                            row_step=floor(num_rows/100)
                        end
                        for row_idx=1:row_step:num_rows
                            plot(sorted_agg_pr_dBm(row_idx,:)','Color',color_set(row_idx,:))
                        end
                         plot(sorted_agg_pr_dBm(1,:)','-k')
                        yline(radar_threshold,'-k','LineWidth',2)
                        title(strcat('Aggregate Interference'))
                        grid on;
                        xlabel('Azimuth')
                        xticks(0:30:num_azi)
                        x_azi_label=(0:30:num_azi)*360/num_azi;
                        xticklabels(x_azi_label)
                        ylabel('Aggregate Interference [dBm]')
                        filename1=strcat(data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Full_Aggregate_Azimuth.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)
                        close(f1)
                        toc;

                        tic;
                        f1=figure;
                        hold on;
                        for row_idx=(max(move_list_turn_off_idx)+1):row_step:num_rows
                            plot(sorted_agg_pr_dBm(row_idx,:)','Color',color_set(row_idx,:))
                        end
                        yline(radar_threshold,'-k','LineWidth',2)
                        title(strcat('Aggregate Interference Post Turn Off'))
                        grid on;
                        xlabel('Azimuth')
                        xticks(0:30:num_azi)
                        x_azi_label=(0:30:num_azi)*360/num_azi;
                        xticklabels(x_azi_label)
                        ylabel('Aggregate Interference [dBm]')
                        filename1=strcat(data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Post_TurnOff_Aggregate_Azimuth.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)
                        close(f1)
                        toc;


                        if strcmp(string_prop_model,'TIREM')
                            unique(sort_cell_prop_mode)
                            los_idx=find(contains(sort_cell_prop_mode,'LOS'));
                            dif_idx=find(contains(sort_cell_prop_mode,'DIF'));
                            tro_idx=find(contains(sort_cell_prop_mode,'TRO'));
                        end
                        if strcmp(string_prop_model,'ITM')
                            unique(sort_cell_prop_mode)
                            los_idx=find(contains(sort_cell_prop_mode,'LOS'));
                            dif_idx=find(contains(sort_cell_prop_mode,'Difraction'));
                            tro_idx=find(contains(sort_cell_prop_mode,'Troposcatter'));
                        end


                        %%%%%%%%%%%Find those base stations to be kept on
                        %%close all; %%%%%%%%%%%This is closing the waitbar.
                        num_labels=3;
                        color_set3=flipud(plasma(num_labels));
                        f1=figure;
                        hold on;
                        plot(sort_sim_array_list_bs(los_idx,2),sort_sim_array_list_bs(los_idx,1),'o','Color',color_set3(1,:),'MarkerFaceColor',color_set3(1,:))
                        plot(sort_sim_array_list_bs(dif_idx,2),sort_sim_array_list_bs(dif_idx,1),'o','Color',color_set3(2,:),'MarkerFaceColor',color_set3(2,:))
                        plot(sort_sim_array_list_bs(tro_idx,2),sort_sim_array_list_bs(tro_idx,1),'o','Color',color_set3(3,:),'MarkerFaceColor',color_set3(3,:))
                        plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                        title(strcat('Propagation Mode:',string_prop_model))
                        cell_bar_label=cell(7,1);
                        cell_bar_label{2}='LOS';
                        cell_bar_label{4}='DIF';
                        cell_bar_label{6}='TRO';
                        bar_tics=linspace(0,1,7);
                        h = colorbar('Location','eastoutside','Ticks',bar_tics,'TickLabels',cell_bar_label);
                        colormap(f1,color_set3)
                        grid on;
                        plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                        filename1=strcat(data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_PropMode.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)
                        close(f1)

  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%These were never really helpful
% % % % %                         %%%%%Only do it for point_idx==1
% % % % %                         if point_idx==1
% % % % %                             fed_azi_loss=sorted_array_fed_azi_data;
% % % % %                             table_fed_azi_data=array2table(fed_azi_loss);
% % % % %                             tic;
% % % % %                             writetable(table_fed_azi_data,strcat(data_label1,'_Point',num2str(point_idx),'_Fed_Azi_Ant_Loss.xlsx'));
% % % % %                             toc;  %%%%%%41 Seconds
% % % % % 
% % % % % 
% % % % %                             azi_pr_dBm=round(sorted_array_mc_pr_dbm,2);
% % % % %                             table_mc_pr_dbm=array2table(azi_pr_dBm);
% % % % %                             tic;
% % % % %                             writetable(table_mc_pr_dbm,strcat(data_label1,'_Point',num2str(point_idx),'_Pr_dBm_Azi.xlsx'));
% % % % %                             toc; %%%%%%%%%60 seconds
% % % % %                             pause(0.1)
% % % % %                         end
                    end


                 %%%%%%%%%%%%%%%%%%%%%%%%%%End of Write Excel
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