To initialize a simulation, run the file "initialize_sim_folder_ground_based_rev4_github_check.m"

This will create a simulation folder "Rev104" that has a Fort Sill Example.

Then run the file "init_run_sim_folder_ground_based_rev1_github_check.m"

This will perform the calculation.

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


