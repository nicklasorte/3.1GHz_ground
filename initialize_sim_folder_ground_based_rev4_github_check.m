clear;
clc;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Local Matlab Data\3.1GHz\Github_Ground' %%%%C:\Local Matlab Data\3.1GHz'; %%%%%Folder where all the matlab code is placed.
cd(folder1)
addpath(folder1)
%%addpath('C:\Local Matlab Data')
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Example code to show the ground based calculation.
% % % % %%%%%%%IMPORTANT: THIS IS NOT THE CODE BEING USED BY DOD IN THE PATHSS STUDY
% % % % %%%%%%%Note: Some things have been simplified for understanding to the reader and to decrease the computational time.
% % % % %%%%%%%The simplifications are noted. The simplifications do not results in a large delta-dB.
% % % % %%%%%%%
% % % % %%%%%%%Note that ITM is being used, instead of TIREM. 
% % % % %%%%%%%To run TIREM, additional matlab toolbox and TIREM license need to be purchased.
% % % % %%%%%%%To remove the variable of different terrain databases, a 3 arc-second database is available. 
% % % % %%%%%%%In most cases, this simplification to a lower resolution terrain database results in a minimumal delta-db difference.
% % % % %%%%%%%
% % % % %%%%%%%Note: Some input parameters are placeholders and do not reflect the input parameters used in the DoD Pathss Study. 
% % % % %%%%%%%Placeholder values try to provide a close-enough parameter to illustrate the analysis methodology.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%1) Azimuth -180~~180
%%%2) Rural
%%%3) Suburban
%%%4) Urban
%%%%AAS Reduction in Gain to Max Gain (0dB is 0dB reduction, which equates to the make antenna gain of 25dB)
%%%%Need to normalize to zero after the "downtilt reductions" are calculated
%%%%To simplify the data, this is gain at the horizon. 50th Percentile
load('aas_zero_elevation_data.mat','aas_zero_elevation_data')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the 5G Deployment: Randomized Real
tic;
disp_progress(app,'Loading Randomized Real . . .')
load('cell_err_data.mat','cell_err_data') %%%%%%%%Placeholder of the 5G deployment
cell_bs_data=cell_err_data;
toc; %%%%%%%5 Seconds
%%%%%%%%%%For an alternate deployment, we just need a latitude/longitude for base station locations.
%%%%%%%%%%
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
rev=104; %%%%%%Example Simulation of Fort Sill and the Randomized Real
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Federal System Inputs (Similar to the CBRS DPA Inputs)
radar_threshold=-145; %%%%%Radar interference threshold -144dBm/10MHz [Placeholder]: Similar to the CBRS Threshold
radar_height=5; %%%%5 meters
radar_beamwidth=3; %%%%%%3 degrees
min_ant_loss=40; %%%%%%%%Main to side gain: 40dB
fdr_dB=3; %%%%%%%%[placeholder value] (This is calculated with the receiver IF selectivity and RF Emission Mask) [ITU 337: https://www.itu.int/rec/R-REC-SM.337/en]
pol_mismatch=1.5; %%%%%%%%%%The loss associated with the mismatch of the interferer and receiver antenna polarizations (e.g. 1.5 dB)
        %%%%%%%%%%%%Simplified Federal System Antenna Pattern: Normalized
        %%%%%%%%%%%Note, this is not STATGAIN
        % % % [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_ant_loss);
        % % % close all;
        % % % figure;
        % % % hold on;
        % % % plot(radar_ant_array(:,1),radar_ant_array(:,2))
        % % % grid on;
%%%%%%%%%%%%%%%%%%Federal Location
%%%%%%% Simplification --> A single point will be used (single point)
%%%%%%% [Multi-Point increases run time.] Not a large delta - dB for smaller operational areas.  However, dependent on the single point, specifically terrain for the propagation model.
tf_single_pt=0%1%0%1;  %%%%%%%%%Multi-point to be filled in later. 
ft_sill_idx=find(contains(cell_military_installations_data(:,1),'Ft Sill'));  %%%%%%%%Fort Sill
base_polygon=cell2mat(cell_military_installations_data(ft_sill_idx,[2,3])')';
base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);  %%%%%%%%Remove the NaNs (In some cases, there are multiple "areas". Need to insert the code here to handle the multi-poly cases.)
point_spacing_km=5; %%%%%%km. A rule of thumb, point spacing should be about 1/10th of maximum turnoff distance. 50km turnoff distance --> 5km point spacing
fort_sill=horzcat(34.73694444,-98.49194444,24);  %%%%%%Lat/Lon/Radius km

if tf_single_pt==1
    poly_base=polyshape(base_polygon(:,2),base_polygon(:,1));
    [centroid_lon,centroid_lat]=centroid(poly_base);  %%%%%%%%%%%%%%%%%%%%%%%%%%%For this example, the radar is assumed to be operating at the centroid of the base.
    sim_pt=horzcat(centroid_lat,centroid_lon);
    centroid_latlon=horzcat(centroid_lat,centroid_lon);

    % % close all;
    % % figure;
    % % hold on;
    % % plot(poly_base)
    % % plot(centroid_lon,centroid_lat,'or','LineWidth',3)
else
    %%%%%%%%%Multi-point code to be inserted in later. 
    %%%%%%%%%Either base_polygon line sampling or the 4-Point Circle.

    %%%%%%'Draw a circle, intersect with the base'
    [cir_lat,cir_lon]=scircle1(fort_sill(1),fort_sill(2),km2deg(fort_sill(3)));
    poly_circle=polyshape(cir_lon,cir_lat);
    poly_base=polyshape(base_polygon(:,2),base_polygon(:,1));
    poly_int=intersect(poly_base,poly_circle);

    close all;
    figure;
    hold on;
    plot(poly_base,'FaceColor','b')
    plot(poly_circle,'FaceColor','r')
    plot(poly_int,'FaceColor','k','FaceAlpha',1)
    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
    pause(0.1)

    no_holes_poly_base=rmholes(poly_int);
    border_base_bound=fliplr(no_holes_poly_base.Vertices);
    border_base_bound=vertcat(border_base_bound,border_base_bound(1,:)); %%%%Close the circle

    %%%%%%%Resample border_base_bound
    %%%%%%%%%Downsample each segment
        [temp_num_pts,~]=size(border_base_bound);
        dist_steps=NaN(temp_num_pts-1,1);
        for j=1:1:temp_num_pts-1
            dist_steps(j)=deg2km(distance(border_base_bound(j,1),border_base_bound(j,2),border_base_bound(j+1,1),border_base_bound(j+1,2)));
        end
          segment_dist_km=sum(dist_steps,"omitnan");
        line_steps=ceil(segment_dist_km/(min(dist_steps)))+1;
        up_sample_border_base_bound=curvspace_app(app,border_base_bound,line_steps);


    %%%%%%%%%Find the "corners"
    border_base_bound=up_sample_border_base_bound;
    base_k_idx=convhull(border_base_bound(:,2),border_base_bound(:,1));
    convex_base_bound=border_base_bound(base_k_idx,:);
    [centroid_lon,centroid_lat]=centroid(poly_int); 


    %%%%%%%%%%Find the distances between the centroid and the border_base_bound
    centroid_dist_km=deg2km(distance(centroid_lat,centroid_lon,border_base_bound(:,1),border_base_bound(:,2)));
    
    %%%%% find corners
    [pks,locs_idx] = findpeaks(centroid_dist_km,'SortStr','descend');


     %%%%%%%%Find the intersection of points on the convex hull and the peaks
     lon_idx=find(round(border_base_bound(:,2),4)==-98.7253);
     lat_idx=find(round(border_base_bound(:,1),4)==34.6383);
     pt_idx = intersect(lon_idx,lat_idx)
     pt_idx=pt_idx(1)


    close all;
    figure;
    hold on;
    plot(centroid_dist_km,'-k')
    plot(locs_idx,centroid_dist_km(locs_idx),'ob')
    text(locs_idx+.02,pks,num2str((1:numel(pks))'))
    plot(pt_idx,centroid_dist_km(pt_idx),'sr','LineWidth',2)
    grid on;

    figure;
    hold on;
    plot(poly_int)
    plot(centroid_lon,centroid_lat,'dg','LineWidth',3)
    plot(border_base_bound(locs_idx,2),border_base_bound(locs_idx,1),'ob')
    text(border_base_bound(locs_idx,2),border_base_bound(locs_idx,1),num2str((1:numel(pks))'))
    plot(border_base_bound(pt_idx,2),border_base_bound(pt_idx,1),'sr','LineWidth',2)
    grid on;

    %%%%%%C = A(ia) and C = B(ib).
    [int_convex_base,ia,ib]=intersect(convex_base_bound,border_base_bound,'rows');
   
    %%%%%%%Intersect between ib and locs_idx
    [int_idx]=intersect(locs_idx,ib)
    
    figure
    hold on;
    plot(convex_base_bound(:,2),convex_base_bound(:,1),'-b')
    plot(border_base_bound(int_idx,2),border_base_bound(int_idx,1),'ok')


    %%%%%%%%%%Split into 4 sections, note this changes for based on the geometry of the location.
    num_segments=4;
    four_corners_idx=sort(locs_idx(1:3))
    four_corners_idx=sort(vertcat(four_corners_idx,pt_idx))

    %%%%%%%'Add the 3 Peaks and the Fourth Point'
    [num_base_points,~]=size(border_base_bound);
    cell_bound_segments=cell(num_segments,1);
    for i=1:1:num_segments
        if i==num_segments
            start_idx=four_corners_idx(i);
            end_idx=four_corners_idx(1);
        else
            start_idx=four_corners_idx(i);
            end_idx=four_corners_idx(i+1);
        end
        
        %%%%Check if end_idx<start_idx
        if end_idx<start_idx
            %%%'Need to include the cross over'
            temp_pt_idx=horzcat(start_idx:1:num_base_points,1:1:end_idx);
        else
            temp_pt_idx=start_idx:1:end_idx;
        end
        temp_line=border_base_bound(temp_pt_idx,:);

        %%%%%%%%%Downsample each segment
        [temp_num_pts,~]=size(temp_line);
        dist_steps=NaN(temp_num_pts-1,1);
        for j=1:1:temp_num_pts-1
            dist_steps(j)=deg2km(distance(temp_line(j,1),temp_line(j,2),temp_line(j+1,1),temp_line(j+1,2)));
        end
        segment_dist_km=sum(dist_steps,"omitnan");
        line_steps=ceil(segment_dist_km/(point_spacing_km))+1;
        cell_bound_segments{i}=curvspace_app(app,temp_line,line_steps);
    end

    temp_sample_pts=vertcat(cell_bound_segments{:});
    uni_sample_pts=unique(temp_sample_pts,'rows');  %%%And row unique
    centroid_latlon=horzcat(centroid_lat,centroid_lon);
    sim_pt=vertcat(centroid_latlon,uni_sample_pts); %%%%%%%%Add the centroid for good luck
    sim_pt=unique(round(sim_pt,4),'rows');  %%%And row unique
    size(sim_pt)

    figure;
    hold on;
    plot(poly_int)
    plot(sim_pt(:,2),sim_pt(:,1),'ok')
    grid on;


% %         %%%%%%%%%%%%%%%%%%%%%%%Add internal Gridpoints: This is needed for areas with a high variation of terrain, for example Camp Pendleton
% %         grid_step_size=1; %%%%%%%%In some cases, this needs to be a smaller grid point spacing. Mainly Terrain Dependent.
% % 
% %           %%%%%%%%%%%Find min/max border coordinates
% %         minx=min(up_sample_border_base_bound(:,2));
% %         maxx=max(up_sample_border_base_bound(:,2));
% %         miny=min(up_sample_border_base_bound(:,1));
% %         maxy=max(up_sample_border_base_bound(:,1));
% %         x_pts=2;
% %         x_dist=grid_step_size+1;
% %         while(x_dist>grid_step_size)
% %             x_array=linspace(minx,maxx,x_pts);
% %             x_dist=deg2km(distance(miny,x_array(1),miny,x_array(2)));
% %             x_pts=x_pts+1;
% %         end
% %         
% %         y_pts=2;
% %         y_dist=grid_step_size+1;
% %         while(y_dist>grid_step_size)
% %             y_array=linspace(miny,maxy,y_pts);
% %             y_dist=deg2km(distance(y_array(1),minx,y_array(2),minx));
% %             y_pts=y_pts+1;
% %         end
% % 
% %         [x_grid,y_grid]=meshgrid(x_array,y_array);
% %         x_grid=reshape(x_grid,[],1);
% %         y_grid=reshape(y_grid,[],1);
% %         
% %         sample_pts=horzcat(y_grid,x_grid);
% %         
% %         %%%%%%%%%Only Keep the sample_pts inside the dpa
% %         [num_sample_pts,y1]=size(sample_pts);
% %         tf_inside=NaN(num_sample_pts,1);
% %         for i=1:1:num_sample_pts
% %             %disp_sub_progress(app,strcat(num2str(i/x1*100),'%'))
% %             tf_inside(i)=isinterior(poly_int,sample_pts(i,2),sample_pts(i,1));
% %         end
% %         inside_idx=find(tf_inside==1);
% %         sim_pt=vertcat(sim_pt,sample_pts(inside_idx,:));  %Add to sim_pts
% %         sim_pt=unique(round(sim_pt,4),'rows');  %%%And row unique
% % 
% %         size(sim_pt)
% % 
% %         figure;
% %         hold on;
% %         plot(poly_int)
% %         plot(sim_pt(:,2),sim_pt(:,1),'dr')
% %         grid on;



    'Check corners'
    pause(1);

end
cell_sim_data=cell(1,6);
%%%%%%%%1)Name, 2) Base Lat/Lon, 3) Radar Threshold, 4) Radar Height,
%%%%%%%%5)Radar Beamwidth, 6)min_ant_loss, 7) pol_mismatch 8) sim_pt, 
% %%%%%%9) FDR, 10) Sim Size (tailored for each location)
cell_dpa_geo=cell(1,18); %%%%%%%%Putting everything in here, just in case.
temp_loc_name=erase(cell_military_installations_data{ft_sill_idx,1}," ");  %%%Remove the Spaces
cell_sim_data{1}=strcat(temp_loc_name,'_','GB1'); %%%%%%Location Name and System Nomenclature
cell_sim_data{2}=base_polygon;
cell_sim_data{3}=radar_threshold; %%%%%Radar threshold for Webster Field
cell_sim_data{4}=radar_height; %%%Antenna Height (meters)
cell_sim_data{5}=radar_beamwidth;  %%%%%%%%%%%%%%Beamwidth
cell_sim_data{6}=min_ant_loss;  %%%%%%%%%%%%
cell_sim_data{7}=pol_mismatch;
cell_sim_data{8}=sim_pt;
cell_sim_data{9}=fdr_dB;
cell_sim_data{10}=sim_radius_km;
cell_sim_data{11}=centroid_latlon;
cell_sim_data{12}=reliability;
cell_sim_data{13}=confidence;
cell_sim_data{14}=FreqMHz;
cell_sim_data{15}=Tpol;
cell_sim_data{16}=building_loss;
cell_sim_data{17}=mc_percentile;
cell_sim_data{18}=mc_size;


%%%%%%%%Use the industry dB reductions
%%%%%%%%Show the COA1 and COA2 (mix) [30dB reductions?]
%%%%%%%%Binary Search with the optimized move list.


'Need to check if we could share the MITRE AAS Antenna dB Reductions'
'Maybe just those at the horizon for the azimuth range'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cell_sim_data



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

'Save all the link budget parameters in the folder because we will need them when we recreate the excel spread sheet (output).'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Saving the simulation files in a folder for the option to run from a server



%%%%%%%%%For Loop the Military Bases
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

    %%%%%%%%%%First, Filter the Commercial Deployment and save the sub-set
    base_polygon=temp_single_cell_sim_data{2};
    save(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
    sim_radius_km=temp_single_cell_sim_data{10};

    base_protection_pts=temp_single_cell_sim_data{8};
    save(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')

    radar_threshold=temp_single_cell_sim_data{3};
    save(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')

    radar_height=temp_single_cell_sim_data{4};
    save(strcat(data_label1,'_radar_height.mat'),'radar_height')

    radar_beamwidth=temp_single_cell_sim_data{5};
    save(strcat(data_label1,'_radar_beamwidth.mat'),'radar_beamwidth')

    min_ant_loss=temp_single_cell_sim_data{6};
    save(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')

    save(strcat(data_label1,'_centroid_latlon.mat'),'centroid_latlon')

    %%%%%%%%Sim Bound
    [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1);

    %%%%%%%Filter Base Stations that are within sim_bound
    tic;
    bs_inside_idx=find(inpolygon(array_bs_latlon(:,2),array_bs_latlon(:,1),sim_bound(:,2),sim_bound(:,1))); %Check to see if the points are in the polygon
    toc;
    size(bs_inside_idx)
    temp_sim_cell_bs_data=cell_bs_data(bs_inside_idx,:);

    figure;
    hold on;
    plot(array_bs_latlon(bs_inside_idx,2),array_bs_latlon(bs_inside_idx,1),'ob')
    plot(sim_bound(:,2),sim_bound(:,1),'-r','LineWidth',3)
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