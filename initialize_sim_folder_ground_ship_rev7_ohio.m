clear;
clc;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Local Matlab Data\3.1GHz'; %%%%%Folder where all the matlab code is placed.
cd(folder1)
addpath(folder1)
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Ohio Example


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the 5G Deployment: Randomized Real
tic;
disp_progress(app,'Loading Randomized Real . . .')
load('cell_err_data.mat','cell_err_data') %%%%%%%%Placeholder of the 5G deployment
cell_bs_data=cell_err_data;
toc; %%%%%%%5 Seconds
%%%%%%%%%%For an alternate deployment, we just need a latitude/longitude for base station locations.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Variable Numes in the Pathss Spreadsheet
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

'Set up the code to pull the deployment from an excel spreadsheet'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the Military Installation
%%%%%%%%%%%%https://catalog.data.gov/dataset/tiger-line-shapefile-2019-nation-u-s-military-installation-national-shapefile
%%%%%%%%%%%%"The military installation boundaries in this release represent the updates the Census Bureau made in 2012 in collaboration with DoD."
disp_progress(app,'Loading Military Installation . . .')
tf_read_mil_shapefile=0;%1
mil_folder='C:\Local Matlab Data\3.1GHz\Github_Ground\tl_2019_us_mil';
mil_shape_filename='cell_military_installations_data.mat';
[cell_military_installations_data]=load_military_installation_shapefile_rev1(app,tf_read_mil_shapefile,mil_folder,folder1,mil_shape_filename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Simulation Input Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rev=212; %%%%%%Camp Sherman Example (with the shipborne format)
tf_ship=0;
tf_ground=1;
ground_pt=horzcat(39.35722222,-82.96305556)
mil_base_name='Camp Sherman'

mil_idx=find(contains(cell_military_installations_data(:,1),mil_base_name))  
cell_military_installations_data(mil_idx,:)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Propagation/Monte Carlo Model Inputs
FreqMHz=3100; %%%%%%%%MHz
freq_separation=0; %%%%%%%Co-channel
reliability=[1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,91,92,93,94,95,96,97,98,99]'; %%%A custom ITM range to interpolate from
confidence=50;
move_list_reliability=50;
Tpol=1; %%%polarization for ITM
building_loss=15; %%%%%%15dB
mc_size=1; %%%%%Number of Monte Carlo Iterations (for the Move List)
mc_percentile=100;%%%%%%%95; %%%%95th Percentile (Set to 100 since there is only 1 MC iteration.) (for the Move List)
sim_radius_km=600; %%%%%%%%Placeholder distance --> Simplification: This is an automated calculation, but requires additional processing time.
tf_clutter=1;
agg_check_mc_size=1000;
agg_check_mc_percentile=95;
agg_check_reliability=reliability;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Commercial Deployment Inputs [Note that these are CTIA recommendations]
array_bs_eirp=horzcat(75,72,72); %%%%%EIRP [dBm/10MHz] for Rural, Suburan, Urban
load('aas_zero_elevation_data.mat','aas_zero_elevation_data')
%%%%1) Azimuth -180~~180
%%%2) Rural
%%%3) Suburban
%%%4) Urban
%%%%AAS Reduction in Gain to Max Gain (0dB is 0dB reduction, which equates to the make antenna gain of 25dB)
%%%%Need to normalize to zero after the "downtilt reductions" are calculated
%%%%To simplify the data, this is gain at the horizon. 50th Percentile

tf_aas_mitre=1; %%%%%%%%%Use the MITRE AAS data at 0 degree Elevation
if tf_aas_mitre==1
    bs_down_tilt_reduction=abs(max(aas_zero_elevation_data(:,[2:4]))) %%%%%%%%Downtilt dB Value for Rural/Suburban/Urban
else  %%%%%%%Else use the CTIA recommendation
    bs_down_tilt_reduction=7; %%%%%%%%5G base stations are tilted downward (6-10 degrees). CTIA recommended 7dB
end

%%%%%%%%%Normalize to zero with the "downtilt reductions": 
%%%%%%%%%The off-axis azimuth loss is calculated in the simulation, all the other losses are rolled into the EIRP.
norm_aas_zero_elevation_data=horzcat(aas_zero_elevation_data(:,1),aas_zero_elevation_data(:,[2:4])+bs_down_tilt_reduction);
max(norm_aas_zero_elevation_data(:,[2:4])) %%%%%This should be [0 0 0]

close all;
figure;
hold on;
plot(norm_aas_zero_elevation_data(:,1),norm_aas_zero_elevation_data(:,2))
plot(norm_aas_zero_elevation_data(:,1),norm_aas_zero_elevation_data(:,3))
plot(norm_aas_zero_elevation_data(:,1),norm_aas_zero_elevation_data(:,4))
grid on;

network_loading_reduction=6.57; %%%%%% 30% base station loading factor + ¾ TDD activity factor = 22% -->That is a reduction of 6.57 dB 
eirp_spatial_load_share=0%%%%7; %%%%%EIRP distribution of Spatial Load share = 20% of the reduced conducted power -->  7 dB  (CTIA recommendation)

'Question: Is EIRP Spaital Load Sharing in the AAS MITRE Calculations? If so this will be a double counting.'

mitigation_dB=vertcat(0,30); %%%%% Beam Muting or PRB Blanking (or any other mitigation mechanism):  30 dB reduction
%%%%%%%%%%%%Consider have this be an array, 3dB step size, to get a more granular insight into how each 3dB mitigation reduces the coordination zone.

deployment_percentage=80 %%%%100;  80 --> 80%    %%%%%%From Values 1-100 for 1%-100%, Need to pull in the upsample Randomized Real to do 200%, 300%, 400%, 500% (and values in between).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Federal System Inputs (Similar to the CBRS DPA Inputs)

if tf_ship==1
    radar_height=50; %%%%50 meters
    fdr_dB=0; %%%%%%%%[placeholder value] (This is calculated with the receiver IF selectivity and RF Emission Mask) [ITU 337: https://www.itu.int/rec/R-REC-SM.337/en]
elseif tf_ground==1
    radar_height=4; %%%%meters
    fdr_dB=3; %%%%%%%%[placeholder value] (This is calculated with the receiver IF selectivity and RF Emission Mask) [ITU 337: https://www.itu.int/rec/R-REC-SM.337/en]
end

radar_threshold=-145; %%%%%Radar interference threshold -144dBm/10MHz [Placeholder]: Similar to the CBRS Threshold
radar_beamwidth=3; %%%%%%3 degrees
min_ant_loss=40; %%%%%%%%Main to side gain: 40dB
pol_mismatch=1.5; %%%%%%%%%%The loss associated with the mismatch of the interferer and receiver antenna polarizations (e.g. 1.5 dB)

%%%%%%%%%%%%Simplified Federal System Antenna Pattern: Normalized
%%%%%%%%%%%Note, this is not STATGAIN
% %         [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_ant_loss);
% %         close all;
% %         figure;
% %         hold on;
% %         plot(radar_ant_array(:,1),radar_ant_array(:,2))
% %         grid on;
% %         xlabel('Degrees')
% %         ylabel('Gain')
% %             filename1=strcat('Example_Ant_pattern.png');
% %     pause(0.1)
% %     saveas(gcf,char(filename1))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Federal Location
%%%%%%%Load in the 3.5GHz DPA points as a starting point for the simulation location of the shipborne radars.
if tf_ship==1
    tic;
    load('port_dpas.mat','port_dpas')
    load('downsampled_east10km.mat','downsampled_east10km')
    load('downsampled_west10km.mat','downsampled_west10km')
    load('us_cont.mat','us_cont')
    toc;

    line_points_spacing=1000; %%%%%%%%%km, can be minimum of 1km

    %%%%%%%%%%%%If you don't want to simulate a line or port, set the
    %%%%%%%%%%%%corresponding idx to:  west_idx=NaN(1,1);
    east_idx=1750;%%1:ceil(line_points_spacing):length(downsampled_east10km);  %%%%%%%%%%%%%NaN(1,1);
    west_idx=NaN(1,1); %%%1:ceil(line_points_spacing):length(downsampled_west10km);  %%%%%%%%%%%%%NaN(1,1);
    port_idx=NaN(1,1); %%%1:1:length(port_dpas);  %%%%%%%%%%%%%NaN(1,1);

    if ~isnan(east_idx)
        num_east_idx=length(east_idx)
        cell_east_sim_data=cell(num_east_idx,4);
        for i=1:1:num_east_idx
            cell_east_sim_data{i,1}=strcat('East_Point_',num2str(east_idx(i)),'_SB3'); %%%%%%Location Name and System Nomenclature (Shipborne #3)
            cell_east_sim_data{i,2}=downsampled_east10km(east_idx(i),:);
            cell_east_sim_data{i,3}=downsampled_east10km(east_idx(i),:);
            cell_east_sim_data{i,4}=downsampled_east10km(east_idx(i),:);
        end
    else
        cell_east_sim_data=cell(1,4);
        cell_east_sim_data=cell_east_sim_data(~cellfun(@isempty, cell_east_sim_data));
    end

    if ~isnan(west_idx)
        num_west_idx=length(west_idx)
        cell_west_sim_data=cell(num_west_idx,4);
        for i=1:1:num_west_idx
            cell_west_sim_data{i,1}=strcat('West_Point_',num2str(west_idx(i)),'_SB3'); %%%%%%Location Name and System Nomenclature (Shipborne #3)
            cell_west_sim_data{i,2}=downsampled_west10km(east_idx(i),:);
            cell_west_sim_data{i,3}=downsampled_west10km(east_idx(i),:);
            cell_west_sim_data{i,4}=downsampled_west10km(east_idx(i),:);
        end
    else
        cell_west_sim_data=cell(1,4);
        cell_west_sim_data=cell_west_sim_data(~cellfun(@isempty, cell_west_sim_data));
    end

    if ~isnan(port_idx)
        num_port_idx=length(port_idx)
        cell_port_sim_data=cell(num_port_idx,4);
        for i=1:1:num_port_idx
            cell_port_sim_data{i,1}=strcat(port_dpas{port_idx(i),1},'_SB3'); %%%%%%Location Name and System Nomenclature (Shipborne #3)
            base_polygon=port_dpas{port_idx(i),2};
            poly_base=polyshape(base_polygon(:,2),base_polygon(:,1));
            [centroid_lon,centroid_lat]=centroid(poly_base);
            centroid_latlon=horzcat(centroid_lat,centroid_lon);

            % %         poly_base=rmholes(poly_base);
            % %         border_base_bound=fliplr(poly_base.Vertices);
            % %         border_base_bound=vertcat(border_base_bound,border_base_bound(1,:)); %%%%Close the circle
            % %
            % %         %%%%%%%Resample border_base_bound
            % %         %%%%%%%%%Downsample each segment
            % %         [temp_num_pts,~]=size(border_base_bound);
            % %         dist_steps=NaN(temp_num_pts-1,1);
            % %         for j=1:1:temp_num_pts-1
            % %             dist_steps(j)=deg2km(distance(border_base_bound(j,1),border_base_bound(j,2),border_base_bound(j+1,1),border_base_bound(j+1,2)));
            % %         end
            % %         segment_dist_km=sum(dist_steps,"omitnan");
            % %         line_steps=ceil(segment_dist_km/(min(dist_steps)))+1;
            % %         up_sample_border_base_bound=curvspace_app(app,border_base_bound,line_steps);
            % %
            % %
            % %         %%%%%%%%%Find the "corners"
            % %         border_base_bound=up_sample_border_base_bound;

            base_k_idx=convhull(base_polygon(:,2),base_polygon(:,1));
            convex_base_bound=base_polygon(base_k_idx,:);

            % %         %%%%%%%%%%Maybe upsample the convex_base_bound, between the points
            % %         [temp_num_pts,~]=size(convex_base_bound)
            % %         convex_base_bound=curvspace_app(app,convex_base_bound,temp_num_pts*10);

            %%%%%%%%%%Find the distances between the centroid and the border_base_bound
            centroid_dist_km=deg2km(distance(centroid_lat,centroid_lon,convex_base_bound(:,1),convex_base_bound(:,2)));

            % % % %         figure;
            % % % %         hold on;
            % % % %         plot(centroid_dist_km,'-ok')

            %centroid_dist_km=deg2km(distance(centroid_lat,centroid_lon,border_base_bound(:,1),border_base_bound(:,2)));

            %%%%% find corners
            [pks,locs_idx] = findpeaks(centroid_dist_km,'SortStr','descend');

            close all;
            figure;
            hold on;
            plot(base_polygon(:,2),base_polygon(:,1),'-sb')
            plot(convex_base_bound(:,2),convex_base_bound(:,1),'-ok')
            plot(convex_base_bound(locs_idx,2),convex_base_bound(locs_idx,1),'or')
            %plot(border_base_bound(locs_idx,2),border_base_bound(locs_idx,1),'or')
            plot(centroid_latlon(2),centroid_latlon(1),'+k')
            grid on;
            pause(0.1)

            port_dpas{port_idx(i),1}
            %%sim_pts=convex_base_bound(locs_idx,:)
            sim_pts=convex_base_bound;  %%%%%%%%%%%%%%%%%%%For the first set, just do the convex hull points.
            size(sim_pts)

            cell_port_sim_data{i,2}=base_polygon;

            cell_port_sim_data{i,3}=centroid_latlon;
            cell_port_sim_data{i,4}=sim_pts; %%%%%%%%To reduce the calculation, the simulation point of the port is the centroid.
        end
    else
        cell_port_sim_data=cell(1,4);
        cell_port_sim_data=cell_port_sim_data(~cellfun(@isempty, cell_port_sim_data));
    end

    cell_sim_data=vertcat(cell_east_sim_data,cell_west_sim_data,cell_port_sim_data);
end
if tf_ground==1
    str_base_name= erase(mil_base_name," ");
    mil_idx=find(contains(cell_military_installations_data(:,1),mil_base_name))
    cell_military_installations_data(mil_idx,:)

    base_pts=cell2mat(cell_military_installations_data(mil_idx,[2,3])')';
    base_pts=base_pts(~isnan(base_pts(:,1)),:);
    base_polyshape=polyshape(base_pts(:,2),base_pts(:,1));
    [cent_lon,cent_lat]=centroid(base_polyshape)

    cell_sim_data=cell(1,10);
    cell_sim_data{1,1}=strcat(str_base_name,'_GB1'); %%%%%%Location Name and System Nomenclature
    cell_sim_data{1,2}=base_pts;
    cell_sim_data{1,3}=horzcat(cent_lat,cent_lon);
    cell_sim_data{1,4}=horzcat(cent_lat,cent_lon);

end



% % % % % 1) Name, 
% % % % % 2) base_polygon (Lat/Lon)
% % % % % 3) Centroid
% % % % % 4) sim_pts/base_protection_pts
% % % % % 5) Radar Threshold, 
% % % % % 6) Radar Height,
% % % % % 7) Radar Beamwidth, 
% % % % % 8) min_ant_loss, 
% % % % % 9) pol_mismatch 
% % % % % 10) FDR
cell_sim_data(:,5)=num2cell(radar_threshold); %%%%%Radar threshold for Webster Field
cell_sim_data(:,6)=num2cell(radar_height); %%%Antenna Height (meters)
cell_sim_data(:,7)=num2cell(radar_beamwidth);  %%%%%%%%%%%%%%Beamwidth
cell_sim_data(:,8)=num2cell(min_ant_loss);  %%%%%%%%%%%%
cell_sim_data(:,9)=num2cell(pol_mismatch);
cell_sim_data(:,10)=num2cell(fdr_dB);

cell_sim_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


'Need to add all the other factors into the cell_sim_data so that people can just exchange the cell_sim_data to create the seed files for the sims'



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create a Rev Folder
cd(folder1);
pause(0.1)
tempfolder=strcat('Rev',num2str(rev));
[status,msg,msgID]=mkdir(tempfolder);
rev_folder=fullfile(folder1,tempfolder);
cd(rev_folder)
pause(0.1)


%%%%%%%%%%%%%%%%%%%%%First, pull all the non-ITM terrain dB reductions in the base stations EIRP (excluding the federal antenna pattern)
array_bs_eirp_reductions=(array_bs_eirp-bs_down_tilt_reduction-network_loading_reduction-eirp_spatial_load_share-fdr_dB-pol_mismatch)-mitigation_dB; %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
array_bs_eirp_reductions



%%%%When we filter the deployment, we pull the (array_bs_eirp_reductions)
%%%%and also add the clutter calculated for each base station.

save(strcat('cell_sim_data_',num2str(rev),'.mat'),'cell_sim_data')
save('array_bs_eirp_reductions.mat','array_bs_eirp_reductions') %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
save('reliability.mat','reliability')
save('confidence.mat','confidence')
save('FreqMHz.mat','FreqMHz')
save('Tpol.mat','Tpol')
save('building_loss.mat','building_loss')
save('mc_percentile.mat','mc_percentile')
save('mc_size.mat','mc_size')
save('norm_aas_zero_elevation_data.mat','norm_aas_zero_elevation_data')
save('sim_radius_km.mat','sim_radius_km')
save('move_list_reliability.mat','move_list_reliability')
save('agg_check_mc_size.mat','agg_check_mc_size')
save('agg_check_mc_percentile.mat','agg_check_mc_percentile')
save('agg_check_reliability.mat','agg_check_reliability')
save('deployment_percentage.mat','deployment_percentage')

'Save all the link budget parameters in the folder because we will need them when we recreate the excel spread sheet (output).'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Saving the simulation files in a folder for the option to run from a server


%%%%%%%%%For Loop the Locations
[num_locations,~]=size(cell_sim_data)
base_id_array=1:1:num_locations; %%%%ALL
table([1:num_locations]',cell_sim_data(:,1))

array_bs_latlon=cell2mat(cell_bs_data(:,[5,6]));
for base_idx=1:1:num_locations
    strcat(num2str(base_idx/num_locations*100),'%')
    
    temp_single_cell_sim_data=cell_sim_data(base_idx,:)
    data_label1=temp_single_cell_sim_data{1}


    %%%%%%%%%Step 1: Make a Folder for this single Location/System
    cd(rev_folder);
    pause(0.1)
    tempfolder2=strcat(data_label1);
    [status,msg,msgID]=mkdir(tempfolder2);
    sim_folder=fullfile(rev_folder,tempfolder2);
    cd(sim_folder)
    pause(0.1)


    % % % % % 1) Name,
    % % % % % 2) base_polygon (Lat/Lon)
    % % % % % 3) Centroid
    % % % % % 4) sim_pts/base_protection_pts
    % % % % % 5) Radar Threshold,
    % % % % % 6) Radar Height,
    % % % % % 7) Radar Beamwidth,
    % % % % % 8) min_ant_loss,
    % % % % % 9) pol_mismatch
    % % % % % 10) FDR


    %%%%%%%%%%First, Filter the Commercial Deployment and save the sub-set
    base_polygon=temp_single_cell_sim_data{2};
    save(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
    %%%%sim_radius_km=temp_single_cell_sim_data{10};

    base_protection_pts=temp_single_cell_sim_data{4};
    save(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')

    radar_threshold=temp_single_cell_sim_data{5};
    save(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')

    radar_height=temp_single_cell_sim_data{6};
    save(strcat(data_label1,'_radar_height.mat'),'radar_height')

    radar_beamwidth=temp_single_cell_sim_data{7};
    save(strcat(data_label1,'_radar_beamwidth.mat'),'radar_beamwidth')

    min_ant_loss=temp_single_cell_sim_data{8};
    save(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')

    centroid_latlon=temp_single_cell_sim_data{3};
    save(strcat(data_label1,'_centroid_latlon.mat'),'centroid_latlon')


    figure;
    hold on;
    plot(base_protection_pts(:,2),base_protection_pts(:,1),'ok')
    grid on;
    size(base_protection_pts)
    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
    filename1=strcat('Operational_Area_',data_label1,'.png');
    pause(0.1)
    saveas(gcf,char(filename1))


    %%%%%%%%Sim Bound
    [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1);

    %%%%%%%Filter Base Stations that are within sim_bound
    tic;
    bs_inside_idx=find(inpolygon(array_bs_latlon(:,2),array_bs_latlon(:,1),sim_bound(:,2),sim_bound(:,1))); %Check to see if the points are in the polygon
    toc;
    size(bs_inside_idx)
    temp_sim_cell_bs_data=cell_bs_data(bs_inside_idx,:);


    %%%%%%%%%%%%Downsample deployment
    [num_inside,~]=size(bs_inside_idx)
    sample_num=ceil(num_inside*deployment_percentage/100)
    rng(rev+base_idx); %%%%%%%For Repeatibility
    rand_sample_idx=datasample(1:num_inside,sample_num,'Replace',false);
    size(temp_sim_cell_bs_data)
    temp_sim_cell_bs_data=temp_sim_cell_bs_data(rand_sample_idx,:);
    size(temp_sim_cell_bs_data)
    temp_lat_lon=cell2mat(temp_sim_cell_bs_data(:,[5,6]));


    figure;
    hold on;
    plot(temp_lat_lon(:,2),temp_lat_lon(:,1),'ob')
    plot(sim_bound(:,2),sim_bound(:,1),'-r','LineWidth',3)
    plot(base_protection_pts(:,2),base_protection_pts(:,1),'sr','Linewidth',4)
    grid on;
    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
    filename1=strcat('Sim_Area_Deployment_',data_label1,'.png');
    pause(0.1)
    saveas(gcf,char(filename1))

    %%%%%%%%%%Add an index for R/S/U (NLCD)
    rural_idx=find(contains(temp_sim_cell_bs_data(:,11),'R'));
    sub_idx=find(contains(temp_sim_cell_bs_data(:,11),'S'));
    urban_idx=find(contains(temp_sim_cell_bs_data(:,11),'U'));
    [num_bs,num_col]=size(temp_sim_cell_bs_data);
    array_ncld_idx=NaN(num_bs,1);
    array_ncld_idx(rural_idx)=1;
    array_ncld_idx(sub_idx)=2;
    array_ncld_idx(urban_idx)=3;
    cell_ncld=num2cell(array_ncld_idx);
   
    %%%%%%%%%%%%%%%%Calculate the clutter and assign the adjusted EIRP for each base station.
    %%%%array_bs_eirp_reductions  %%%%%%1)Rural, 2)Sub, 3)Urban
    clutter_dB=zeros(num_bs,1);
    if tf_clutter==1
        %%%%%%%%%Calculate p452
        [clutter_table]=calculate_p452_clutter_rev1(app,FreqMHz);
        %%%%%NLCD Type 1) Rural, 2)Suburban, 3) Urban, 4) Dense Urban, 5) Antenna Height [m]

        %%%%%%%%%%%%%%%Now find the associated clutter with each Transmitter
        array_ant_height=cell2mat(temp_sim_cell_bs_data(:,10));   %%%10) SE_AntennaHeight_m
        clutter_height_idx=nearestpoint_app(app,array_ant_height,clutter_table(:,5));
        for i=1:1:num_bs
            temp_nlcd_idx=array_ncld_idx(i);
            temp_height_idx=clutter_height_idx(i);
            clutter_dB(i)=clutter_table(temp_height_idx,temp_nlcd_idx);
        end
        unique(clutter_dB)
    else
        %%%%%%No clutter (clutter_dB is already zero)
    end

    array_eirp_bs=NaN(num_bs,2); %%%%%1)No Mitigations, 2)Mitigations --> 14 and 15 of cell
    for i=1:1:num_bs
        temp_nlcd_idx=array_ncld_idx(i);
        array_eirp_bs(i,:)=array_bs_eirp_reductions(:,temp_nlcd_idx)-clutter_dB(i);
    end
    cell_eirp1=num2cell(array_eirp_bs(:,1));
    cell_eirp2=num2cell(array_eirp_bs(:,2));
    sim_cell_bs_data=horzcat(temp_sim_cell_bs_data,cell_ncld,cell_eirp1,cell_eirp2);
    size(sim_cell_bs_data)

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

     tic;
     save(strcat(data_label1,'_sim_cell_bs_data.mat'),'sim_cell_bs_data')
     toc; %%%%%%%%%3 seconds


     %%%%%%%%%%%%%%%Also include the array of the list_catb (order) that we
     %%%%%%%%%%%%%%%usually use for the other sims. (As this will be used
     %%%%%%%%%%%%%%%for the path loss and move list.)

     sim_array_list_bs=horzcat(cell2mat(sim_cell_bs_data(:,[5,6,10,14,3])),array_ncld_idx,cell2mat(sim_cell_bs_data(:,[7,15])));
     [num_bs_sectors,~]=size(sim_array_list_bs);
     sim_array_list_bs(:,5)=1:1:num_bs_sectors;
     % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
     %%%%%%%%If there is no mitigation EIRPs, make all of these NaNs (column 8)

     %%%%%%%%%%%Put the rest of the Link Budget Parameters in this list

     %%%%%%%9) EIRP dBm:         array_bs_eirp
     sim_array_list_bs(rural_idx,9)=array_bs_eirp(1);
     sim_array_list_bs(sub_idx,9)=array_bs_eirp(2);
     sim_array_list_bs(urban_idx,9)=array_bs_eirp(3);

     %%%%%%%10) AAS (Vertical) dB Reduction: (Downtilt)   %%%%%%%%Downtilt dB Value for Rural/Suburban/Urban
     sim_array_list_bs(rural_idx,10)=bs_down_tilt_reduction(1);
     sim_array_list_bs(sub_idx,10)=bs_down_tilt_reduction(2);
     sim_array_list_bs(urban_idx,10)=bs_down_tilt_reduction(3);

     %%%%%%%%%11)Clutter
     sim_array_list_bs(:,11)=clutter_dB;

     %%%%%%%%%12)Network Loading and TDD (dB)
     sim_array_list_bs(:,12)=network_loading_reduction;

     %%%%%%%%%13)FDR (dB)
     sim_array_list_bs(:,13)=fdr_dB;

     %%%%%%%%%14)Polarization (dB)
     sim_array_list_bs(:,14)=pol_mismatch;


     %%%%%%%%%15)Mitigation Reduction (dB)
     sim_array_list_bs(:,15)=mitigation_dB(2);


     sim_array_list_bs(1,:)
     size(sim_array_list_bs)


     tic;
     save(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
     toc; %%%%%%%%%3 seconds

end



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

'DONE: Go run the sim folder with the function.'
