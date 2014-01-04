function peak_list = get_peaks( rdat_file, pdb_file, thres_factor )
%
%   INPUTS
%         rdat_file:  Name of rdat file to read in, or rdat structure
%     (optional)
%         pdb_file:   Name of PDB file to read in (optional)
%         thres_factor:   Number of standard deviations above the mean to use as threshold for finding peaks 
%
%   OUTPUTS
%         peak_list:  Text file with list of peak indices to use as modeling constraints 
%
% 1. Read in RDAT
% 2. Filter data - remove NaN, negative data, and peaks >1 stdev above mean
% 3. Find peaks using fastpeakfind, excluding up to 6 nt off the diagonal
% 4. Plot peaks on data (image with jet colormap); include simulated contours if .pdb model provided  
% 5. Output image with peaks, output peak list
%
% (C) Clarence Cheng, 2013

D_sim_a = []; dist_matrix = []; rad_res = []; hit_res = [];
if exist( 'pdb_file', 'var' );  [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb_file ); end
if ischar(rdat_file)
    r = read_rdat_file(rdat_file);
else
    r = rdat_file;
end

% Assign data and plotting axis limits
D = transpose(r.reactivity);    % transpose so that don't need to later
ligpos = get_ligpos(r);
seqpos = r.seqpos;

% Mask data: if value is NaN or negative, set to 0; if value is > mean+1stdev, set to 0 
D_mask = D;
D_mask(isnan(D)) = 0;
D_mask( D < 0 ) = 0;
stdev = std(nonzeros(D_mask));
avg = mean(nonzeros(D_mask));
D_mask( D > avg + stdev ) = 0;

% Don't search for peaks in diagonal
D_mask = tril(D_mask, -6);

% Set threshold
if exist( 'thres_factor' );
    thres = avg + stdev/thres_factor;
else
    thres = (max([min(max(D_mask,[],1))  min(max(D_mask,[],2))])) ;
end

% Find peaks
[pks, pksmat] = FastPeakFind(D_mask, thres);
peak_list(:,1) = pks(1:2:end) + r.offset;
peak_list(:,2) = pks(2:2:end) + r.offset+1;
pks_out = reshape(transpose(peak_list),[],1);

% Save peak list as text file
filename = [rdat_file '.PeakList.txt'];
fid = fopen(filename, 'w');      % open a text file for reading in the peaks
fprintf(fid,'%1.0f  %1.0f\n', pks_out);
fclose(fid);

% Plot results
figure(1); hold on;
image(seqpos, ligpos, D*20); colormap(jet); axis image; set(gca,'YDir','reverse');
scatter(peak_list(:,1), peak_list(:,2), 'm', 'fill');
print_save_figure(figure(1), [rdat_file '.Peak'], 'Figures', 1);

if exist( 'pdb_file', 'var' )
    figure(2); hold on;
    image(seqpos, ligpos, D*20); colormap(jet); axis image; set(gca,'YDir','reverse');
    scatter(peak_list(:,1), peak_list(:,2), 'm', 'fill');
    contour(rad_res, hit_res, tril(D_sim_a), 1/15, 'linewidth', 1.5, 'linecolor', [0.75 0.75 0.75] );
    contour(rad_res, hit_res, tril(D_sim_a), 1/30, 'linewidth', 1.5, 'linecolor', [0.5 0.5 0.5] );
    print_save_figure(figure(2), [rdat_file '.PeakSim'], 'Figures', 1);
end







