function [cell_neighborhood_status]=update_neighborhood_cell_rev1(app,folder_names,sim_folder)

        %%%%%%%Load
        [cell_neighborhood_status]=initialize_or_load_neighborhood_status_rev1(app,folder_names);
        
        %%%%%Find the idx
        temp_cell_idx=find(strcmp(cell_neighborhood_status(:,1),sim_folder)==1);

        %%%%%%%Update the Cell
        cell_neighborhood_status{temp_cell_idx,2}=1;
        
        %%%%%Save the Cell
        file_name_cell=strcat('cell_neighborhood_status.mat');
        retry_save=1;
        while(retry_save==1)
            try
                save(file_name_cell,'cell_neighborhood_status')
                retry_save=0;
            catch
                retry_save=1;
                pause(0.1)
            end
        end
end