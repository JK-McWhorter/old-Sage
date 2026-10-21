function [handles, DATA] = get_LIR_CAN_ESPER(dirs,handles,DATA)
% function to calculate reference data for use in SAGE
% 10/25/21 - TM, incorporated Carter et al (2021) ESPER routine calls
% 03/30/23 - TM, added ESPER-MIX
% ********************************************************************
% GET CANYON NEURAL NETWORK, LINR & LIPHER APROXIMATIONs FOR NO3 AND PH
% NEED QC OXYGEN FOR THIS

% --- LOAD LIR / LIAR DATA FILES IF PRESENT ---
lir_file1 = fullfile(dirs.LIR, 'LIARv2files.mat');
lir_file2 = fullfile(dirs.LIR, 'LINR_files.mat');
lir_file3 = fullfile(dirs.LIR, 'LIPHR_files.mat');

if exist(lir_file1, 'file') == 2, load(lir_file1); end
if exist(lir_file2, 'file') == 2, load(lir_file2); end
if exist(lir_file3, 'file') == 2, load(lir_file3); end

if handles.info.qc_flag == 1
    d = handles.qc_data;
else
    d.hdr = {};
    d.data = [];
end

% Safely retrieve O2 data
if ~isempty(DATA.iO) && handles.info.qc_flag == 1
    if isfield(handles, 'new_qc_data') && ~isempty(handles.new_qc_data)
        O2data = handles.new_qc_data.data(:, DATA.iO(1));
    else
        O2data = handles.qc_data.data(:, DATA.iO(1));
    end
else
    O2data = [];
end

%% CANYON & CANYON-B ESTIMATES FOR NITRATE AND PH
if handles.info.qc_flag == 1 && ~isempty(DATA.iO)
    iSDN   = find(strcmp('SDN',d.hdr) == 1, 1);
    iLAT   = find(strcmp('Lat [°N]',d.hdr) == 1, 1);
    iLON   = find(strcmp('Lon [°E]',d.hdr) == 1, 1);
    
    try
        canyonB_no3 = CANYONB(d.data(:,iSDN),d.data(:,iLAT),d.data(:,iLON), ...
            d.data(:,DATA.iP(1)),d.data(:,DATA.iT(1)),d.data(:,DATA.iS(1)),O2data,{'NO3'});
        canyonB_ph = CANYONB(d.data(:,iSDN),d.data(:,iLAT),d.data(:,iLON), ...
            d.data(:,DATA.iP(1)),d.data(:,DATA.iT(1)),d.data(:,DATA.iS(1)),O2data,{'pH'});
        CBspec = canyonB_ph.pH + (canyonB_ph.pH*0.0404 - 0.3168);
        canyonB_ph.pH = CBspec;
        
        canyon_no3 = CANYON_jp(dirs,d.data(:,iSDN),d.data(:,iLAT),d.data(:,iLON), ...
            d.data(:,DATA.iP(1)),d.data(:,DATA.iT(1)),d.data(:,DATA.iS(1)),O2data,'NO3');
        canyon_ph = CANYON_jp(dirs,d.data(:,iSDN),d.data(:,iLAT),d.data(:,iLON), ...
            d.data(:,DATA.iP(1)),d.data(:,DATA.iT(1)),d.data(:,DATA.iS(1)),O2data,'PH');
            
        handles.canyon.hdr  = [d.hdr([1,2,6]),'canyon_no3','canyon_ph','canyonB_no3','canyonB_ph'];
        handles.canyon.data = [d.data(:,[1,2,6]), canyon_no3, canyon_ph, canyonB_no3.NO3, canyonB_ph.pH];
    catch ME
        fprintf('CANYON/CANYONB Error: %s\n', ME.message);
        handles.canyon = [];
    end
else
    handles.canyon = [];
end

DATA.C = handles.canyon;
if ~isempty(DATA.C)
    DATA.iCN   = find(strcmp('canyon_no3',DATA.C.hdr) == 1, 1);
    DATA.iCPH  = find(strcmp('canyon_ph',DATA.C.hdr) == 1, 1);
    DATA.iCBN  = find(strcmp('canyonB_no3',DATA.C.hdr) == 1, 1);
    DATA.iCBPH = find(strcmp('canyonB_ph',DATA.C.hdr) == 1, 1);
else
    DATA.iCN   = [];
    DATA.iCPH  = [];
    DATA.iCBN  = [];
    DATA.iCBPH = [];
end

%% LINR & LIPHR ESTIMATES FOR NITRATE AND PH
if handles.info.qc_flag == 1
    iZ_idx = DATA.iZ(1);
    
    % Extract Lon, Lat, Depth
    lons = real(d.data(:,3));
    lats = real(d.data(:,4));
    deps = real(d.data(:,iZ_idx));
    
    % Standardize Longitudes to [0, 360]
    lons = mod(lons, 360);
    
    % Standardize Latitudes to [-90, 90]
    lats(lats < -90 | lats > 90) = NaN;
    
    % Depths must be strictly positive for LIR routines
    deps(deps < 0) = NaN;
    
    LXXX_pos = [lons, lats, deps];
    
    MeasIDVec    = [1 7]; % PSAL, TEMP
    Measurements = real([d.data(:,DATA.iS(1)), d.data(:,DATA.iT(1))]);
    Equations    = 8; % S, Theta
    
    % Valid rows: No NaNs/Infs and positive depth values
    validRows_noO2 = ~any(isnan(LXXX_pos) | isinf(LXXX_pos), 2) & ...
                     ~any(isnan(Measurements) | isinf(Measurements), 2) & ...
                     LXXX_pos(:,3) > 0;
    
    if exist('LINR', 'file') == 2 && exist('LIPHR', 'file') == 2 && any(validRows_noO2)
        NO3_Est_noO2 = nan(size(d.data,1), 1);
        PH_Est_noO2  = nan(size(d.data,1), 1);
        
        pos_sub  = double(LXXX_pos(validRows_noO2,:));
        meas_sub = double(Measurements(validRows_noO2,:));
        
        try
            [NO3_tmp, ~, ~] = LINR(pos_sub, meas_sub, MeasIDVec, 'Equations', Equations);
            [PH_tmp, ~, ~]  = LIPHR(pos_sub, meas_sub, MeasIDVec, 'Equations', Equations, 'OAAdjustTF', false);
            
            NO3_Est_noO2(validRows_noO2) = NO3_tmp;
            PH_Est_noO2(validRows_noO2)  = PH_tmp;
            
            handles.LIRnoO2.hdr  = [d.hdr([1,2,6]),'LIRnoO2_no3','LIRnoO2_ph'];
            handles.LIRnoO2.data = [d.data(:,[1,2,6]), NO3_Est_noO2, PH_Est_noO2];
        catch ME
            fprintf('LINR/LIPHR noO2 Calculation Exception: %s\n', ME.message);
            handles.LIRnoO2.hdr  = {};
            handles.LIRnoO2.data = [];
        end
    else
        handles.LIRnoO2.hdr  = {};
        handles.LIRnoO2.data = [];
    end
    
    if ~isempty(DATA.iO) && exist('LINR', 'file') == 2 && exist('LIPHR', 'file') == 2
        MeasIDVec    = [1 6 7]; % PSAL, DOXY_ADJ, TEMP
        Measurements = real([d.data(:,DATA.iS(1)), O2data, d.data(:,DATA.iT(1))]);
        Equations    = 7; % S, Theta, AOU
        
        validRows_O2 = ~any(isnan(LXXX_pos) | isinf(LXXX_pos), 2) & ...
                       ~any(isnan(Measurements) | isinf(Measurements), 2) & ...
                       LXXX_pos(:,3) > 0;
        
        if any(validRows_O2)
            NO3_Est = nan(size(d.data,1), 1);
            PH_Est  = nan(size(d.data,1), 1);
            
            pos_sub  = double(LXXX_pos(validRows_O2,:));
            meas_sub = double(Measurements(validRows_O2,:));
            
            try
                [NO3_tmp, ~, ~] = LINR(pos_sub, meas_sub, MeasIDVec, 'Equations', Equations);
                [PH_tmp, ~, ~]  = LIPHR(pos_sub, meas_sub, MeasIDVec, 'Equations', Equations, 'OAAdjustTF', false);
                
                NO3_Est(validRows_O2) = NO3_tmp;
                PH_Est(validRows_O2)  = PH_tmp;
                
                handles.LIR.hdr  = [d.hdr([1,2,6]),'LIR_no3','LIR_ph'];
                handles.LIR.data = [d.data(:,[1,2,6]), NO3_Est, PH_Est];
            catch ME
                fprintf('LINR/LIPHR O2 Calculation Exception: %s\n', ME.message);
                handles.LIR.hdr  = {};
                handles.LIR.data = [];
            end
        else
            handles.LIR.hdr  = {};
            handles.LIR.data = [];
        end
    else
        handles.LIR.hdr  = {};
        handles.LIR.data = [];
    end
else
    handles.LIRnoO2.hdr  = {};
    handles.LIRnoO2.data = [];
    handles.LIR.hdr      = {};
    handles.LIR.data     = [];
end

clear canyon_no3 canyon_ph ptemp MeasIDVec Measurements Equations NO3_Est PH_Est Uncert_Est MinUncert_Equ

if isfield(handles, 'LIR') && ~isempty(handles.LIR.data)
    DATA.L = handles.LIR;
    DATA.iLN   = find(strcmp('LIR_no3',DATA.L.hdr) == 1, 1);
    DATA.iLPH  = find(strcmp('LIR_ph',DATA.L.hdr) == 1, 1);
else
    DATA.L.data = [];
    DATA.L.hdr  = {};
    DATA.iLN   = [];
    DATA.iLPH  = [];
end

if isfield(handles, 'LIRnoO2') && ~isempty(handles.LIRnoO2.data)
    DATA.LnoO2 = handles.LIRnoO2;
    DATA.iLN_noO2   = find(strcmp('LIRnoO2_no3',DATA.LnoO2.hdr) == 1, 1);
    DATA.iLPH_noO2  = find(strcmp('LIRnoO2_ph',DATA.LnoO2.hdr) == 1, 1);
else
    DATA.LnoO2.data = [];
    DATA.LnoO2.hdr  = {};
    DATA.iLN_noO2   = [];
    DATA.iLPH_noO2  = [];
end

%% ESPER ESTIMATES (Carter et al 2021)
handles.ESPER_LIR = struct('hdr', {{}}, 'data', []);
handles.ESPER_NN  = struct('hdr', {{}}, 'data', []);
handles.ESPER_MIX = struct('hdr', {{}}, 'data', []);

if handles.info.qc_flag == 1 && ~isempty(DATA.iO)
    DesireVar = [3,5]; % pH & nitrate
    OutCoords = LXXX_pos; % lon, lat, depth
    PredictorTypes = [1 2 6]; % PSAL, TEMP, DOXY_ADJ
    Measurements = real([d.data(:,DATA.iS(1)), d.data(:,DATA.iT(1)), O2data]);
    dvec = datevec(d.data(:,1));
    dec_yr = dvec(:,1) + (dvec(:,2)*30)/365 + dvec(:,3)/365;
    Equations = 7; % S, T, O2
    
    try
        if exist('ESPER_LIR', 'file') == 2
            [Estimates,~,~] = ESPER_LIR(DesireVar, OutCoords, Measurements,...
                PredictorTypes, 'Equations', Equations, 'EstDates', dec_yr);
            handles.ESPER_LIR.hdr  = [d.hdr([1,2,6]),'ESPER_LIR_no3','ESPER_LIR_ph'];
            handles.ESPER_LIR.data = [d.data(:,[1,2,6]), Estimates.nitrate, Estimates.pH];
        end
        
        if exist('ESPER_NN', 'file') == 2
            [Estimates,~] = ESPER_NN(DesireVar, OutCoords, Measurements,...
                PredictorTypes, 'Equations', Equations, 'EstDates', dec_yr);
            handles.ESPER_NN.hdr  = [d.hdr([1,2,6]),'ESPER_NN_no3','ESPER_NN_ph'];
            handles.ESPER_NN.data = [d.data(:,[1,2,6]), Estimates.nitrate, Estimates.pH];
        end
        
        if exist('ESPER_Mixed', 'file') == 2
            [Estimates,~] = ESPER_Mixed(DesireVar, OutCoords, Measurements,...
                PredictorTypes, 'Equations', Equations, 'EstDates', dec_yr);
            handles.ESPER_MIX.hdr  = [d.hdr([1,2,6]),'ESPER_MIX_no3','ESPER_MIX_ph'];
            handles.ESPER_MIX.data = [d.data(:,[1,2,6]), Estimates.nitrate, Estimates.pH];
        end
    catch ME
        fprintf('ESPER Calculation Exception: %s\n', ME.message);
    end
end

% Assign ESPER variables to DATA
DATA.ESPER_LIR = handles.ESPER_LIR;
if ~isempty(DATA.ESPER_LIR.data)
    DATA.iEL_N   = find(strcmp('ESPER_LIR_no3',DATA.ESPER_LIR.hdr) == 1, 1);
    DATA.iEL_PH  = find(strcmp('ESPER_LIR_ph',DATA.ESPER_LIR.hdr) == 1, 1);
else
    DATA.iEL_N   = [];
    DATA.iEL_PH  = [];
end

DATA.ESPER_NN = handles.ESPER_NN;
if ~isempty(DATA.ESPER_NN.data)
    DATA.iEN_N   = find(strcmp('ESPER_NN_no3',DATA.ESPER_NN.hdr) == 1, 1);
    DATA.iEN_PH  = find(strcmp('ESPER_NN_ph',DATA.ESPER_NN.hdr) == 1, 1);
else
    DATA.iEN_N   = [];
    DATA.iEN_PH  = [];
end

DATA.ESPER_MIX = handles.ESPER_MIX;
if ~isempty(DATA.ESPER_MIX.data)
    DATA.iEM_N   = find(strcmp('ESPER_MIX_no3',DATA.ESPER_MIX.hdr) == 1, 1);
    DATA.iEM_PH  = find(strcmp('ESPER_MIX_ph',DATA.ESPER_MIX.hdr) == 1, 1);
    DATA.reftemp = DATA.ESPER_MIX.data;
    DATA.reftag  = 'ESPER MIX';
else
    DATA.iEM_N   = [];
    DATA.iEM_PH  = [];
    DATA.reftag  = 'NOQC';
end
end