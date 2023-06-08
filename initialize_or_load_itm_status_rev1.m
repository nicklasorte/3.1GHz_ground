function [cell_itm_status]=initialize_or_load_itm_status_rev1(app,folder_names)

    file_name_cell=strcat('cell_itm_status.mat');
    [num_folders,~]=size(folder_names);
    [var_exist_cell]=persistent_var_exist_with_corruption(app,file_name_cell);
    if var_exist_cell==2 %%%%%%%%Load
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_cell,'cell_itm_status')
                retry_load=0;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
        [temp_size,~]=size(cell_itm_status);
        if temp_size>num_folders
            %%%%%%%%Nothing
        elseif temp_size<num_folders
            %%%%%Expand the cell
            disp_multifolder(app,'Pause for cell_itm_status expansion')
            pause;
            var_exist_cell=0;
        end
    end
    
    if var_exist_cell==0 %%%%%%%%Initilize and Save
        [num_folders,~]=size(folder_names);
        cell_itm_status=cell(num_folders,2); %%%%Name and 0/1
        cell_itm_status(:,1)=folder_names;
        zero_cell=cell(1);
        zero_cell{1}=0;
        cell_itm_status(:,2)=zero_cell;
        %%%%%%Save the initialize all_data_stats_binary
        retry_save=1;
        while(retry_save==1)
            try
                save(file_name_cell,'cell_itm_status')
                retry_save=0;
            catch
                retry_save=1;
                pause(0.1)
            end
        end
    end

end