function data = get_WOA_local(data_site, track, depth_bnds, ocean_var)
%
% UPDATED FROM get_WOA2018_local.m TO APPLY TO WOA2023 DATASET.
% UPDATED 11/13/24 by TM to move to WOA2023.
%
% PURPOSE: 
%   Extract a subset from the monthly WOAyyyy climatology for a given
%   variable and then interpolate data along the provided track.
%
% USAGE:
%   data = get_WOA_local(data_site, track, depth_bnds, ocean_var)
% ***********************************************************************

plot_it = 0; % 0 to turn off plotting

ST_path    = '';  
NUT_path   = '';   
fn_str     = 'woa23_XXX_VNN_01.nc'; % File template

% VARIABLES EXTRACTION TABLE
WOA_info(1,:) = {'nitrate'    , 'n', NUT_path, 'all', 'NO3'};
WOA_info(2,:) = {'oxygen'     , 'o', NUT_path, 'all', 'O2' };
WOA_info(3,:) = {'phosphate'  , 'p', NUT_path, 'all', 'PO4'};
WOA_info(4,:) = {'silicate'   , 'i', NUT_path, 'all', 'Si' };
WOA_info(5,:) = {'temperature', 't', ST_path , 'A5B2', 'T' };
WOA_info(6,:) = {'salinity'   , 's', ST_path , 'A5B2', 'S' };
WOA_info(7,:) = {'o2sat'      , 'O', NUT_path, 'all', 'O2sat'};
WOA_info(8,:) = {'AOU'        , 'A', NUT_path, 'all', 'AOU'};
month_label = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' ...
               'Oct' 'Nov' 'Dec'};

% ***********************************************************************
% CHECK INPUTS
% ***********************************************************************
s1 = ['ocean_var must be a character string from this list: ', ...
      'T S O2 O2sat NO3 Si PO4 AOU'];  
s2 = 'Check track input: must have 3 rows or columns [SDN Lat Lon]';
s3 = ' Check depth range input: should be [min_depth max_depth]';

[r,c] = size(track);
if r ~= 3 && c ~= 3
    disp(s2)
    return
end
if r == 3 && c ~= 3
    track = track'; % now n x 3
end
if length(depth_bnds) ~= 2 || depth_bnds(1) > depth_bnds(2)
    disp(s3)
    return
end
if ~ischar(ocean_var) 
    disp(s1)
    return
end
var_ind = find(strcmp(ocean_var, WOA_info(:,5)) == 1);
if isempty(var_ind) 
    disp(s1)
    return
end

% SDN LAT LON
t1 = track(:,2) == -1e10; 
track(t1,2:3) = NaN;
clear t1

% CONVERT LON TO -180 to +180 IF NECESSARY
t1 = track(:,3) > 180; 
track(:,3) = track(:,3) - (t1*360);

% CHECK FOR -180 / +180 MERIDIAN TRACK CROSSING
cross180 = 0;
if max(abs(diff(track(:,3)))) > 340 
    disp('Trackline crosses +180 / -180 meridian')
    cross180 = 1; 
    t1 = track(:,3) < 0; 
    lon_bnds = [max(track(t1,3)) min(track(~t1,3))]; 
else
    lon_bnds = [min(track(:,3)) max(track(:,3))]; 
end
lat_bnds = [min(track(:,2)) max(track(:,2))]; 
clear s1 s2 r c t1

% ***********************************************************************
% BUILD DATA PATH AND SANITIZE FOR NETCDF (\ -> /)
% ***********************************************************************
target_subfolder = WOA_info{var_ind,1};

if contains(data_site, target_subfolder)
    data_path = data_site;
else
    data_path = fullfile(data_site, target_subfolder);
end

if ~endsWith(data_path, filesep) && ~endsWith(data_path, '/')
    data_path = [data_path, filesep];
end

data_path = strrep(data_path, '\', '/');

fn_template = regexprep(fn_str, 'V', WOA_info{var_ind,2}); 
fn_template = regexprep(fn_template, 'XXX', WOA_info{var_ind,4});
var_name    = [WOA_info{var_ind,2}, '_an']; 
annual_flag = 0;

for i = 1:12 % STEP THROUGH MONTHLY CLIMATOLOGIES
    fname = regexprep(fn_template, 'NN', num2str(i, '%02.0f')); 
    full_nc_path = [data_path, fname];
    
    % Fallback if file on disk lacks .nc extension
    if ~exist(full_nc_path, 'file') && exist(strip(full_nc_path, 'right', 'nc'), 'file')
        full_nc_path = regexprep(full_nc_path, '\.nc$', '');
    end

    if ~exist(full_nc_path, 'file')
        error('get_WOA_local:FileNotFound', 'WOA monthly file not found: %s', full_nc_path);
    end

    try
        ds = ncdataset(full_nc_path);
        use_nctoolbox = true;
    catch
        use_nctoolbox = false;
    end
    
    % GET EXTRACTION INDICES
    if i == 1 
        if use_nctoolbox
            z   = double(ds.data('depth'));
            lat = double(ds.data('lat'));
            lon = double(ds.data('lon'));
        else
            z   = double(ncread(full_nc_path, 'depth'));
            lat = double(ncread(full_nc_path, 'lat'));
            lon = double(ncread(full_nc_path, 'lon'));
        end
        
        z_ind1 = find(z <= depth_bnds(1), 1, 'last');
        if isempty(z_ind1), z_ind1 = 1; end
        
        z_ind2 = find(z >= depth_bnds(2), 1, 'first');
        if isempty(z_ind2)
            z_ind2 = length(z);
            annual_flag = 1;
        end
        Z = z(z_ind1:z_ind2); 
        
        lat_ind1 = find(lat <= lat_bnds(1), 1, 'last');
        lat_ind2 = find(lat >= lat_bnds(2), 1, 'first');
        if isempty(lat_ind1), lat_ind1 = 1; end
        if isempty(lat_ind2), lat_ind2 = length(lat); end
        LAT = lat(lat_ind1:lat_ind2); 
        
        x_track = track(:,3); 
        if cross180 == 0
            lon_ind1 = find(lon <= lon_bnds(1), 1, 'last');
            lon_ind2 = find(lon >= lon_bnds(2), 1, 'first');
            if isempty(lon_ind1), lon_ind1 = 1; end
            if isempty(lon_ind2), lon_ind2 = length(lon); end
            LON = lon(lon_ind1:lon_ind2); 
            x   = LON; 
        else 
            lon_ind1 = find(lon <= lon_bnds(2), 1, 'last');
            lon_ind2 = find(lon >= lon_bnds(1), 1, 'first');
            nlon     = length(lon);
            LON      = lon([lon_ind1:nlon, 1:lon_ind2]);
            t1       = LON < 0;
            x        = LON + (t1 * 360); 
            t1       = x_track < 0;
            x_track  = x_track + t1 * 360;
        end
        
        d = ones(12, length(Z), length(LAT), length(LON)); 
    end
  
    if cross180 == 0
        if use_nctoolbox
            raw_slice = double(ds.data(var_name,...
                [1, z_ind1, lat_ind1, lon_ind1],...
                [1, z_ind2, lat_ind2, lon_ind2]));
        else
            start_vec = [lon_ind1, lat_ind1, z_ind1, 1];
            count_vec = [(lon_ind2-lon_ind1+1), (lat_ind2-lat_ind1+1), (z_ind2-z_ind1+1), 1];
            raw_slice = permute(double(ncread(full_nc_path, var_name, start_vec, count_vec)), [4, 3, 2, 1]);
        end
        d(i,:,:,:) = reshape(raw_slice, [1, length(Z), length(LAT), length(LON)]);
    else 
        if use_nctoolbox
            d1 = double(ds.data(var_name,...
                [1, z_ind1, lat_ind1, lon_ind1],...
                [1, z_ind2, lat_ind2, nlon]));  
            d2 = double(ds.data(var_name,...
                [1, z_ind1, lat_ind1, 1],...
                [1, z_ind2, lat_ind2, lon_ind2]));
        else
            start1 = [lon_ind1, lat_ind1, z_ind1, 1];
            count1 = [(nlon-lon_ind1+1), (lat_ind2-lat_ind1+1), (z_ind2-z_ind1+1), 1];
            d1 = permute(double(ncread(full_nc_path, var_name, start1, count1)), [4, 3, 2, 1]);

            start2 = [1, lat_ind1, z_ind1, 1];
            count2 = [lon_ind2, (lat_ind2-lat_ind1+1), (z_ind2-z_ind1+1), 1];
            d2 = permute(double(ncread(full_nc_path, var_name, start2, count2)), [4, 3, 2, 1]);
        end
        
        d1 = reshape(d1, [1, length(Z), length(LAT), (nlon - lon_ind1 + 1)]);
        d2 = reshape(d2, [1, length(Z), length(LAT), lon_ind2]);
        d(i,:,:,:) = cat(4, d1, d2); 
    end
end

if annual_flag == 1 
    fname = regexprep(fn_template, 'NN', '00'); 
    full_nc_path = [data_path, fname];
    
    if ~exist(full_nc_path, 'file') && exist(strip(full_nc_path, 'right', 'nc'), 'file')
        full_nc_path = regexprep(full_nc_path, '\.nc$', '');
    end
    
    if use_nctoolbox
        ds = ncdataset(full_nc_path);
        z  = double(ds.data('depth'));
    else
        z  = double(ncread(full_nc_path, 'depth'));
    end
    
    z_ind3 = find(z > Z(end), 1, 'first');
    z_ind4 = find(z >= depth_bnds(2), 1, 'first');
    if isempty(z_ind4), z_ind4 = length(z); end
    
    Z1 = z(z_ind3:z_ind4); 
    d3 = ones(12, length(Z1), length(LAT), length(LON));
    
    if cross180 == 0
        if use_nctoolbox
            raw_slice = double(ds.data(var_name,...
                [1, z_ind3, lat_ind1, lon_ind1],...
                [1, z_ind4, lat_ind2, lon_ind2]));
        else
            start_vec = [lon_ind1, lat_ind1, z_ind3, 1];
            count_vec = [(lon_ind2-lon_ind1+1), (lat_ind2-lat_ind1+1), (z_ind4-z_ind3+1), 1];
            raw_slice = permute(double(ncread(full_nc_path, var_name, start_vec, count_vec)), [4, 3, 2, 1]);
        end
        d3(1,:,:,:) = reshape(raw_slice, [1, length(Z1), length(LAT), length(LON)]);
    else 
        if use_nctoolbox
            d4 = double(ds.data(var_name,...
                [1, z_ind3, lat_ind1, lon_ind1],...
                [1, z_ind4, lat_ind2, nlon]));  
            d5 = double(ds.data(var_name,...
                [1, z_ind3, lat_ind1, 1],...
                [1, z_ind4, lat_ind2, lon_ind2]));
        else
            start1 = [lon_ind1, lat_ind1, z_ind3, 1];
            count1 = [(nlon-lon_ind1+1), (lat_ind2-lat_ind1+1), (z_ind4-z_ind3+1), 1];
            d4 = permute(double(ncread(full_nc_path, var_name, start1, count1)), [4, 3, 2, 1]);

            start2 = [1, lat_ind1, z_ind3, 1];
            count2 = [lon_ind2, (lat_ind2-lat_ind1+1), (z_ind4-z_ind3+1), 1];
            d5 = permute(double(ncread(full_nc_path, var_name, start2, count2)), [4, 3, 2, 1]);
        end
        
        d4 = reshape(d4, [1, length(Z1), length(LAT), (nlon - lon_ind1 + 1)]);
        d5 = reshape(d5, [1, length(Z1), length(LAT), lon_ind2]);
        d3(1,:,:,:) = cat(4, d4, d5); 
    end
    
    for i = 2:12
        d3(i,:,:,:) = d3(1,:,:,:);
    end
    d = cat(2, d, d3);  
    Z = [Z; Z1];
end

clear z_ind1 z_ind2 lat_ind1 lat_ind2 lon_ind1 lon_ind2 t1 nlon lat lon z 

% ***********************************************************************
% INTERPOLATE WOA ALONG FLOAT TRACK
% ***********************************************************************
stations = size(track, 1); 
[Y, ~, ~, ~, ~, ~] = datevec(track(:,1)); 
yrday    = track(:,1) - datenum(Y,1,1);   
WOA_day  = (datenum(2014,1:12,15))' - datenum(2014,1,0); 
d_interp = ones(length(Z), stations) * NaN; 

for i = 1:stations
    if isnan(track(i,2)) 
        continue
    end
    
    t1 = find(WOA_day < yrday(i), 1, 'last'); 
    if isempty(t1) 
        t1 = 1; t2 = 12;
        wt = (yrday(i) + 15) / 30; 
    elseif t1 == 12 
        t2 = 1;
        wt = (365 - yrday(i) + 15) / 30; 
    else
        t2 = t1 + 1;
        dx  = WOA_day(t2) - WOA_day(t1); 
        dx1 = yrday(i) - WOA_day(t1);
        wt  = (dx - dx1) ./ dx;
    end
    
    lat1 = find(LAT <= track(i,2), 1, 'last'); 
    if isempty(lat1), lat1 = 1; end
    lat2 = min(lat1 + 1, length(LAT));
    if lat1 == lat2
        lat_wt = 1;
    else
        dx     = LAT(lat2) - LAT(lat1); 
        dx1    = track(i,2) - LAT(lat1);
        lat_wt = (dx - dx1) ./ dx; 
    end
    
    lon1 = find(x <= x_track(i), 1, 'last'); 
    if isempty(lon1), lon1 = 1; end
    lon2 = min(lon1 + 1, length(x));
    if lon1 == lon2
        lon_wt = 1;
    else
        dx     = x(lon2) - x(lon1); 
        dx1    = x_track(i) - x(lon1);
        lon_wt = (dx - dx1) ./ dx; 
    end
    
    sub_d1 = squeeze(d(t1, :, lat1:lat2, lon1:lon2));
    sub_d2 = squeeze(d(t2, :, lat1:lat2, lon1:lon2));
    
    D3 = sub_d1 * wt + sub_d2 * (1 - wt);
    if ndims(D3) < 3
        D3 = reshape(D3, [length(Z), (lat2-lat1+1), (lon2-lon1+1)]);
    end
    
    t_NaN = squeeze(sum(isnan(D3), 1) > 0);
    if sum(t_NaN(:)) ~= 0
        valid_mask = ~t_NaN;
        valid_profs = D3(:, valid_mask);
        if ~isempty(valid_profs)
            d_interp(:,i) = mean(valid_profs, 2, 'omitnan');
        end
        continue 
    end
    
    if lat1 == lat2
        D2 = squeeze(D3(:,1,:));
    else
        D2 = squeeze(D3(:,1,:) * lat_wt + D3(:,2,:) * (1 - lat_wt));
    end
    
    if lon1 == lon2
        d_interp(:,i) = D2;
    else
        d_interp(:,i) = (D2(:,1) * lon_wt + D2(:,2) * (1 - lon_wt));
    end
end

% FUNCTION OUTPUT
data.d = d_interp;
data.Z = Z;
data.z = Z;