clear;
clc;
close all;
close all force;
app=NaN(1);
format shortG
top_start_clock=clock;
folder1='C:\Local Matlab Data\3.1GHz'  %%%%%Folder where all the matlab code is placed.
cd(folder1)
addpath(folder1)
pause(0.1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Model Inputs
rev_folder='C:\Local Matlab Data\3.1GHz\Github_Ground\Rev106'
parallel_flag=0%1%0%1%0%1%0%1%0%1%0%1 %%%%%0 --> serial, 1 --> parallel
 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RandStream('mt19937ar','Seed','shuffle') 
%%%%%%Create a random number stream using a generator seed based on the current time. 
%%%%%%It is usually not desirable to do this more than once per MATLAB session as it may affect the statistical properties of the random numbers MATLAB produces.
%%%%%%%%We do this because the compiled app sets all the random number stream to the same, as it's running on different servers. Then the servers hop to each folder at the same time, which is not what we want.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Toolbox Check (Sims can run without the Parallel Toolbox)
[workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,num_folders]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%If we have it, start the parpool.
disp_progress(app,strcat(rev_folder,'--> Starting Parallel Workers . . . [This usually takes a little time]'))
tic;
[poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
toc;

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

        load('agg_check_mc_size.mat','agg_check_mc_size')
        temp_data=agg_check_mc_size;
        clear agg_check_mc_size;
        agg_check_mc_size=temp_data;
        clear temp_data;

        load('agg_check_mc_percentile.mat','agg_check_mc_percentile')
        temp_data=agg_check_mc_percentile;
        clear agg_check_mc_percentile;
        agg_check_mc_percentile=temp_data;
        clear temp_data;

        load('agg_check_reliability.mat','agg_check_reliability')
        temp_data=agg_check_reliability;
        clear agg_check_reliability;
        agg_check_reliability=temp_data;
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
        retry_load=1
        pause(0.1)
    end
end


tf_write_movelist_excel=1%0%1%0%1%0%1
'Note, as the number of base stations increases, the time to write the excel files increases.'


num_chunks=24;  %%%%%%%%%This number needs to be set right here to not create possible mismatch error.
% %%%%The idea is to set the num_chunks to the maximum number of cores for one server.
%%%%%%But the number can't be based on the actual number of cores for the
%%%%%%server it is running on, because some servers have a different number
%%%%%%of cores, which would change the number of chunks.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ITM 
string_prop_model='ITM'
part1_calc_pathloss_itm_or_tirem_rev4(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,num_chunks)
propagation_clean_up_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,workers,string_prop_model,num_chunks)
part2_movelist_calculation_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model)
part2b_movelist_EXCEL_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_write_movelist_excel)
part3_mitigation_movelist_calculation_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TIREM
%%%%%%%%%%%%Note that TIREM seems to run a bit slower than ITM.
[tf_tirem]=check_tirem_rev1(app)
if tf_tirem==1
    string_prop_model='TIREM'
    part1_calc_pathloss_itm_or_tirem_rev4(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,num_chunks)
    propagation_clean_up_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,workers,string_prop_model,num_chunks)
    part2_movelist_calculation_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model);
    part2b_movelist_EXCEL_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_write_movelist_excel);
    part3_mitigation_movelist_calculation_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model);
end


if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_progress(app,strcat('Sim Done'))





end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end
'Done'

