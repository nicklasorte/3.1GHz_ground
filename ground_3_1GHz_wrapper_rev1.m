function ground_3_1GHz_wrapper_rev1(app,rev_folder,parallel_flag,workers)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function to package
cd(rev_folder)
pause(0.1)
split_rev=strsplit(rev_folder,'\');
sim_string=strsplit(split_rev{end},'Rev');
sim_number=str2num(sim_string{end})
pause(0.1);
temp_files=dir(rev_folder);
dirFlags=[temp_files.isdir];
subFolders=temp_files(dirFlags);
subFolders(1:2)=[];
cell_subFolders=struct2cell(subFolders);
folder_names=cell_subFolders(1,:)';
num_folders=length(folder_names);

disp_progress(app,strcat(rev_folder,'--> Starting Parallel Workers . . . [This usually takes a little time]'))
tic;
[poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
toc;

%%%%%%%%%Next step
%%%%%%%%Load all the mat files in the main folder



%%%%%%%%%Next step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load all the mat files in the main folder
retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data . . . '))

        load('reliability.mat','reliability')
        temp_data=reliability;
        clear reliability;
        reliability=temp_data;
        clear temp_data;


        load('move_list_reliability.mat','move_list_reliability')
        temp_data=move_list_reliability;
        clear move_list_reliability;
        move_list_reliability=temp_data;
        clear temp_data;

        load('confidence.mat','confidence')
        temp_data=confidence;
        clear confidence;
        confidence=temp_data;
        clear temp_data;

        load('FreqMHz.mat','FreqMHz')
        temp_data=FreqMHz;
        clear FreqMHz;
        FreqMHz=temp_data;
        clear temp_data;

        load('Tpol.mat','Tpol')
        temp_data=Tpol;
        clear Tpol;
        Tpol=temp_data;
        clear temp_data;

        load('building_loss.mat','building_loss')
        temp_data=building_loss;
        clear building_loss;
        building_loss=temp_data;
        clear temp_data;

        load('mc_percentile.mat','mc_percentile')
        temp_data=mc_percentile;
        clear mc_percentile;
        mc_percentile=temp_data;
        clear temp_data;

        load('mc_size.mat','mc_size')
        temp_data=mc_size;
        clear mc_size;
        mc_size=temp_data;
        clear temp_data;

        load('sim_radius_km.mat','sim_radius_km')
        temp_data=sim_radius_km;
        clear sim_radius_km;
        sim_radius_km=temp_data;
        clear temp_data;

        load(strcat('cell_sim_data_',num2str(sim_number),'.mat'),'cell_sim_data')
        temp_data=cell_sim_data;
        clear cell_sim_data;
        cell_sim_data=temp_data;
        clear temp_data;

        load('array_bs_eirp_reductions.mat','array_bs_eirp_reductions') %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
        temp_data=array_bs_eirp_reductions;
        clear array_bs_eirp_reductions;
        array_bs_eirp_reductions=temp_data;
        clear temp_data;

        load('norm_aas_zero_elevation_data.mat','norm_aas_zero_elevation_data')
        %%%%1) Azimuth -180~~180
        %%%2) Rural
        %%%3) Suburban
        %%%4) Urban
        temp_data=norm_aas_zero_elevation_data;
        clear norm_aas_zero_elevation_data;
        norm_aas_zero_elevation_data=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1;
        pause(0.1)
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Part 1: Calculate Path Loss
part1_calc_pathloss_3dot1GHz_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers)
'Pathloss code only has the ITM option at this time.'
'Will add TIREM/Longly-Rice as other options, but those require the matlab antenna toolbox.'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Part 2: Calculate the Move List (No Mitigations)
tf_write_movelist_excel=1%0%%%%1
part2_movelist_calculation_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,tf_write_movelist_excel)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Part 3: Calculate the Move List (With Mitigations)
part3_mitigation_calculation_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,tf_write_movelist_excel)




'Next aggregate check'
'Will fill in this code later.'





if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_progress(app,strcat('Sim Done'))


end