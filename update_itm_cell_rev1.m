function [cell_itm_status]=update_itm_cell_rev1(app,folder_names,sim_folder)

        %%%%%%%Load
        [cell_itm_status]=initialize_or_load_itm_status_rev1(app,folder_names);
        
        %%%%%Find the idx
        temp_cell_idx=find(strcmp(cell_itm_status(:,1),sim_folder)==1);

        %%%%%%%Update the Cell
        cell_itm_status{temp_cell_idx,2}=1;
        
        %%%%%Save the Cell
        file_name_cell=strcat('cell_itm_status.mat');
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