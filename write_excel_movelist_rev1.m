function write_excel_movelist_rev1(app,num_ppts,move_list_reliability,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,radar_height)


                    %%%%%%%%%%%Make a Table for each protection point
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                    %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                    %%%'To prevent the possibility of memory issues, may need to write the excel file right here after each point. But then we cant parfor the calculation. Just load in all the data after the calculation.'
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        [move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,array_bs_azi_data,sort_full_Pr_dBm,sorted_array_fed_azi_data,sorted_array_mc_pr_dbm]=pre_sort_movelist_rev5_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%Load ITM for the Output Excel File
                        file_name_pathloss=strcat('ITM_Pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_pathloss,'ITM_Pathloss')
                                retry_load=0;
                            catch
                                retry_load=1;
                                pause(1)
                            end
                        end

                        %%%%%%%% Cut the reliabilities that we will use for the move list
                        [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
                        [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
                        temp_sort_ITM=ITM_Pathloss(sort_bs_idx,[rel_first_idx:rel_second_idx]);
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
                        
% % %                         %%%%%%%%%%Make a table: 1) BS Uni ID, 2) Lat 3)Lon, 4)BS Height, 5)Federal
% % %                         %%%%%%%%%%Lat, 6)Federal Lon, 7)radar_height 8)BS EIRP (Full) 9)BS Antenna Downtilt
% % %                         %%%%%%%%%%dB Vertical, 10)BS Antenna Azimuth Off-Axis, 11)Clutter,
% % %                         %%%%%%%%%%12)Propagation Path loss, 13) Network Loading and TDD, 14) FDR,
% % %                         %%%%%%%%%%15) Polarization Mismatch, 16)Pr_dBm
% % %                         %%%%%%%%%%17)TF Turn off
% % %                                                 % % % % %   Add
% % %                         % % % % % -bs sector azi
% % %                         % % % % % -bs to fed azi
% % %                         % % % % % -off axis azi, from the bs main beam (mod)
% % %                         % % % % % -horizontal bs off axis gain (already in the table)

                        array_excel_data=horzcat(temp_sorted_list_data(:,5),temp_sorted_list_data(:,[1,2,3]),sim_pt.*ones(num_tx,1),radar_height.*ones(num_tx,1),temp_sorted_list_data(:,[9,10]),sorted_array_bs_azi_data,temp_sorted_list_data(:,[11]),temp_sort_ITM,temp_sorted_list_data(:,[12,13,14]),temp_sort_Pr_dBm);
                        array_excel_data(move_list_turn_off_idx,end+1)=1;  %%%%%%%%%%%This is just the turn off idx for the single point calculated
                        array_excel_data([1:10],:)
                        
                        %%%%%%%%Double check the Calculation (Indexs will change due to more data added)
                        %%%%%%%%%%Full EIRP - BS_Downtilt + BS_Azi_Gain -
                        %%%%%%%%%%Clutt - Network Load - FDR - Pol_Mismatch
                        %%%%%%indy_Pr_dBm=temp_sorted_list_data(:,4)-temp_sort_ITM+sorted_array_bs_azi_data(:,end);
                        indy_Pr_dBm=temp_sorted_list_data(:,9)-temp_sorted_list_data(:,10)-temp_sorted_list_data(:,11)-temp_sorted_list_data(:,12)-temp_sorted_list_data(:,13)-temp_sorted_list_data(:,14)-temp_sort_ITM+sorted_array_bs_azi_data(:,end);

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

                        table_move_list=array2table(array_excel_data);
                        table_move_list.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'BS_Downtilt_Loss_dB' 'BS_to_Fed_Azimuth_Degrees' 'BS_Sector_Azi_Degrees' 'BS_Azi_Diff_Degrees' 'Mod_BS_Azi_Diff_Degrees' 'BS_Horizonal_Off_Axis_Gain_dB' 'Clutter_dB' 'Path_Loss_dB' 'NetworkLoading_TDD_Loss_dB' 'FDR_dB' 'Polarization_Mismatch_Loss_dB' 'PowerReceived_dBm_No_Fed_Ant' 'TF_Turn_Off'};
                        disp_progress(app,strcat('2 minutes to write Excel Files . . . '))


                        '3 sheets per sim point'
                        'Separate Excel Sheet Per Point'
                        tic;
                        writetable(table_move_list,strcat(data_label1,'_Point',num2str(point_idx),'_Link_Budget.xlsx'));
                        toc;

                        %%%%%Only do it for point_idx==1
                        if point_idx==1
                            fed_azi_loss=sorted_array_fed_azi_data;
                            table_fed_azi_data=array2table(fed_azi_loss);
                            tic;
                            writetable(table_fed_azi_data,strcat(data_label1,'_Point',num2str(point_idx),'_Fed_Azi_Ant_Loss.xlsx'));
                            toc;  %%%%%%41 Seconds


                            azi_pr_dBm=round(sorted_array_mc_pr_dbm,2);
                            table_mc_pr_dbm=array2table(azi_pr_dBm);
                            tic;
                            writetable(table_mc_pr_dbm,strcat(data_label1,'_Point',num2str(point_idx),'_Pr_dBm_Azi.xlsx'));
                            toc; %%%%%%%%%60 seconds
                            pause(0.1)
                        end
                    end

end