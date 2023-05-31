To run ITM (propagation model) you'll need to download some files (6GBs: Too big to upload here.) (Contant nlasorte@ntia.gov for access to files.)

(Keeping the same terrain database removes one factor that causes differences between the results.) 

(Place all the files from the Terrain Folder ("USGS") to the following path --> C:\USGS


Another way to calculate path loss with ITM is through the Matlab Longley-Rice propagation model.

https://www.mathworks.com/help/antenna/ref/rfprop.longleyrice.html

Note: You will need the Antenna Toolbox.

https://www.mathworks.com/products/antenna.html

(Note that this uses the Matlab Terrain Database --> gmted2010)

https://www.mathworks.com/help/map/access-basemaps-terrain-geographic-globe.html

By default, the geographic globe uses terrain data hosted by MathWorks and derived from the GMTED2010 model by the USGS and NGA. 
You need an active internet connection to access this terrain data, and you cannot download it.

TIREM can also be calculated through Matlab.

https://www.mathworks.com/help/antenna/ref/rfprop.tirem.html


