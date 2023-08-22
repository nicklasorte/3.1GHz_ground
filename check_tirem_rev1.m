function [tf_tirem]=check_tirem_rev1(app)


    try
        %%%%%%%%%%%%%'If you get an error here, move the Tirem dlls to here'
        tiremSetup('C:\USGS\TIREM5')  %%%%%%%%%This to the folder of the TIREM dlls
        tf_tirem=1;
    catch
        tf_tirem=0;
    end

end