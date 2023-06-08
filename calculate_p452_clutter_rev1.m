function [clutter_table]=calculate_p452_clutter_rev1(app,FreqMHz)

        freq_ghz=FreqMHz/1000;
        %%%%%%%%Save a Separate CatB Clutter and a CatA Clutter
        clutter_ant_height=1:0.1:100;
        clutter_table=vertcat(NaN(4,length(clutter_ant_height)),clutter_ant_height); %%%%%NLCD Type, Antenna Height

        %%%%%%%%%%ITU-R 452-Clutter
        %%%%%%%Dense Urban Clutter
        %disp_progress(app,strcat('Calculating Dense Clutter . . . '))
        dk=0.02;%%%%From Table 4
        ha_durban=25; %%%%%%From table of nominal clutter
        Ffc=0.25+0.375.*(1+tanh(7.5.*(freq_ghz-0.5)));
        Ah=10.25.*Ffc.*exp(-1.*dk).*(1-tanh(6.*((clutter_ant_height./ha_durban)-0.625)))-0.33;
        idx_zero=find(Ah<0);
        Ah(idx_zero)=0;
        dense_urban_clutter=Ah;
        clutter_table(4,:)=dense_urban_clutter;

        %%%%%%%Urban Clutter
        %disp_progress(app,strcat('Calculating Urban Clutter . . . '))
        dk=0.02;%%%%From Table 4
        ha_urban=20; %%%%%%From table of nominal clutter
        Ffc=0.25+0.375.*(1+tanh(7.5.*(freq_ghz-0.5)));
        Ah=10.25.*Ffc.*exp(-1.*dk).*(1-tanh(6.*((clutter_ant_height./ha_urban)-0.625)))-0.33;
        idx_zero=find(Ah<0);
        Ah(idx_zero)=0;
        urban_clutter=Ah;
        clutter_table(3,:)=urban_clutter;

        %%%%%%%Suburban Clutter
        %disp_progress(app,strcat('Calculating Suburban Clutter . . . '))
        dk=0.025;%%%%From Table 4
        ha_suburban=9; %%%%%%From table of nominal clutter
        Ah=10.25.*Ffc.*exp(-1.*dk).*(1-tanh(6.*((clutter_ant_height./ha_suburban)-0.625)))-0.33;
        idx_zero=find(Ah<0);
        Ah(idx_zero)=0;
        suburban_clutter=Ah;
        clutter_table(2,:)=suburban_clutter;

        %%%%%%%Rural Clutter
        %disp_progress(app,strcat('Calculating Rural Clutter . . . '))
        dk=0.1;%%%%From Table 4
        ha_rural=4; %%%%%%From table of nominal clutter
        Ah=10.25.*Ffc.*exp(-1.*dk).*(1-tanh(6.*((clutter_ant_height./ha_rural)-0.625)))-0.33;
        idx_zero=find(Ah<0);
        Ah(idx_zero)=0;
        rural_clutter=Ah;
        clutter_table(1,:)=rural_clutter;
        clutter_table=clutter_table';


end