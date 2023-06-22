Example code to show the ground-based calculation.
==========================================================================
==========================================================================

IMPORTANT: THIS IS NOT THE CODE BEING USED BY DOD IN THE PATHSS STUDY
Note: Some things have been simplified for understanding to the reader and to decrease the computational time.
The simplifications are noted. The simplifications do not result in a large delta-dB.

Note that ITM is being used, instead of TIREM. 
To run TIREM, an additional matlab toolbox and TIREM license need to be purchased.
To remove the variable of different terrain databases, a 3 arc-second database is available. 
In most cases, this simplification to a lower resolution terrain database results in a minimum delta-db difference.

Note: Some input parameters are placeholders and do not reflect the input parameters used in the DoD Pathss Study. 
Placeholder values try to provide a close-enough parameter to illustrate the analysis methodology.

========================================================================== 
==========================================================================


To initialize a simulation, run the file "initialize_sim_folder_ground_based_rev4_github_check.m"

This will create a simulation folder "Rev104" that has a Fort Sill Example. (This might be hard to run on a desktop computer.)

A more simplified simulation can be done by running the file "initialize_sim_folder_ground_based_rev4_github_check_slim.m"

This will create the simulation folder "Rev105" that has a Fort Sill Example.

Then run the file "init_run_sim_folder_ground_based_rev1_github_check.m"

This will perform the calculation.

==========================================================================

Military Installation Information is Publicly Available:

https://catalog.data.gov/dataset/tiger-line-shapefile-2019-nation-u-s-military-installation-national-shapefile

==========================================================================

The simulation will output Excel files that contain all the Link Budget information, so that the calculations can be checked.

For Example: to check the power received (from each Base Station to the Federal System):

[Column T (FtSill_GB1_Point1_Link_Budget.xlsx)] – [Federal Antenna Loss (FtSill_GB1_Point1_Fed_Azi_Ant_Loss.xlsx)] = [(FtSill_GB1_Point1_Pr_dBm_Azi.xlsx)]

In this example, there are 240 azimuths that the federal system is pointing. (0-360 with a 1.5 degreee step size.)

To calculate the aggregate interferece, for each azimuth, in [FtSill_GB1_Point1_Pr_dBm_Azi.xlsx], the column "IH", a "1" indicates that the Base Station will be be turned-off. A "0" indicates that a Base Station can transmit.

Copy the sheet, cut the rows of Base Stations that need to be turned off, convert from dBm to Watts, sum each column (which is a discrete azimuth), and convert back to dBm.

==========================================================================

There is an option to run the simulation with the parallel toolbox. (If you have it.)

https://www.mathworks.com/products/parallel-computing.html

The "parallel" functions relate to the simulation points for a specific location.

For example, if a server has 24 cores, but there are only 10 protection points for a specific location, only 10 cores will be used.

Parallel functions include: Pathloss, Movelist, Movelist with Mitigation, and Aggregate Check.

==========================================================================

To run ITM (propagation model) you'll need to download some files (6GBs: Too big to upload here.) 

https://sfc.doc.gov/w/f-4209b4bd-c19b-41aa-b8ba-a9d10c453fe3

(Contant nlasorte@ntia.gov if you can't access the terrain database files.)

(Keeping the same terrain database removes one factor that causes differences between the results.) 

(Place all the files from the Terrain Folder ("USGS") to the following path --> C:\USGS


=========================================================================================

Another way to calculate path loss with ITM is through the Matlab Longley-Rice propagation model. (This option will be added soon.)

https://www.mathworks.com/help/antenna/ref/rfprop.longleyrice.html

Note: You will need the Antenna Toolbox.

https://www.mathworks.com/products/antenna.html

(Note that this uses the Matlab Terrain Database --> gmted2010)

https://www.mathworks.com/help/map/access-basemaps-terrain-geographic-globe.html

By default, the geographic globe uses terrain data hosted by MathWorks and derived from the GMTED2010 model by the USGS and NGA. 
You need an active internet connection to access this terrain data, and you cannot download it.

TIREM can also be calculated through Matlab.

https://www.mathworks.com/help/antenna/ref/rfprop.tirem.html


======================================================================================

If you don't have the Parallel Toolbox, you can still leverage the parallel function on a server with Matlab Runtime.

https://www.mathworks.com/products/compiler/matlab-runtime.html

Download the R2022b (9.13) release and install on your machine.

Let me know if you are doing this and I will compile the app for you.

======================================================================================

If you can't download the ITM code and Terrain Database (6GB) and don't have the antenna toolbox, there is a matlab runtime version available that allows you to run the analysis.

https://www.mathworks.com/products/compiler/matlab-runtime.html

Download the R2022b (9.13) release and install on your machine.

When you run the analysis, you will still need an active internet connection to access the Matlab terrain data.

In this case, a basic version of Matlab is only needed to initalize the simulation parameters.

Let me know if you are doing this and I will compile the app for you.


