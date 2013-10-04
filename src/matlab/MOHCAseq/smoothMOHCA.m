function [D_smooth, seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, USE_Z_SCORE, MOD_CORRECT );
%% [D_smooth,seqpos, ligpos, r] = smoothMOHCA( rdat_file, pdb, USE_Z_SCORE, MOD_CORRECT );
%%
%% One-shot script to take MOHCA raw data (in rdat format) and any known 
%%  reference structure, and make a nice summary plot.
%% 
%% Inputs
%%  rdat_file   = rdat or cell of rdats (either filenames or actual data objects will work)
%%  pdb         = filename of pdb (or pdbstruct object from pdbread)
%%  USE_Z_SCORE = [Default 0] Use Z-score processing of reactivities (note that 
%%                 this script will apply attenuation correction for you). Otherwise
%%                 use 'repsub' processing based on subtracting data corresponding
%%                 to uncleaved RNA.
%%  MOD_CORRECT = [Default 1] In 'repsub' processing, apply a smooth correction to 
%%                 correct for attenuation and/or source distribution.
%%
%% Outputs 
%%  D_smooth    = matrix of output, averaged over all data sets.
%%  seqpos      = MOHCA stop positions of 5' ends (x-axis)
%%  ligpos      = MOHCA ligation positions at 3' ends (these are the cleavage 
%%                 positions + 1, corresponding to the sites actually attacked).
%%  r           = cell of rdats
%%
%% (C) R. Das, C. Cheng, 2013
%%

if nargin < 1; help( mfilename ); return; end;

clf;
set(gcf, 'PaperPositionMode','auto','color','white');

if ~exist( 'USE_Z_SCORE', 'var' ); USE_Z_SCORE = 0; end;
if ~exist( 'MOD_CORRECT', 'var' ); MOD_CORRECT = 1; end % only in use without Z-score

if ~iscell( rdat_file ) rdat_file = { rdat_file }; end;

D_sim_a = [];
if exist( 'pdb', 'var' );  [D_sim_a, rad_res, hit_res, dist_matrix, pdbstruct] = get_simulated_data( pdb ); end

cat_name = '';

r = {};
for i = 1:length( rdat_file )
  [all_D_smooth(:,:,i), seqpos, ligpos, r{i}, mean_rel_error(i) ] = get_D_smooth( rdat_file{i}, USE_Z_SCORE, MOD_CORRECT );  
  make_plot( squeeze( all_D_smooth(:,:,i) ), seqpos, ligpos, r{i}.name, dist_matrix, rad_res, hit_res, pdb, USE_Z_SCORE );

  if i > 1; cat_name = [cat_name, '\newline' ]; end
  cat_name = [cat_name, r{i}.name];
  if length( rdat_file ) > 1; pause; end;
end


weight = 1./mean_rel_error.^2
D_smooth_sum = 0*squeeze( all_D_smooth(:,:,1) ); 
weight_sum = 0;
for i = 1:length( rdat_file )
  D_smooth_sum = D_smooth_sum + squeeze(all_D_smooth(:,:,i))*weight(i);
  weight_sum = weight_sum + weight(i);
end
D_smooth = D_smooth_sum / weight_sum;

if ( length( rdat_file )  > 1 )
  make_plot( D_smooth, seqpos, ligpos, cat_name, dist_matrix, rad_res, hit_res, pdb, USE_Z_SCORE );
end

fprintf( 'Used Z-score: %d\n', USE_Z_SCORE );
if ~USE_Z_SCORE
  fprintf( 'Applied modification correction: %d\n', MOD_CORRECT );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function make_plot( D_smooth, seqpos, ligpos, name, ...
		    dist_matrix, rad_res, hit_res, pdb, ...
		    USE_Z_SCORE )

image( seqpos, ligpos, 80 * D_smooth );

gp = find( mod(seqpos,10) == 0 );
set(gca,'xtick',seqpos(gp) )
gp = find( mod(ligpos,10) == 0 );
set(gca,'ytick',ligpos(gp) )
set(gca,'xgrid','on','ygrid','on','fonts',12,'fontw','bold');
xlabel( 'Stop pos [5'']' ); ylabel( 'Lig pos [3'']');
hold on;

colormap( 1 - gray(100));
axis image;
contour_levels = [10, 15, 25, 35];
colorcode = [0 0 1; 0.3 0.3 1; 0.6 0.6 1; 0.8 0.8 1];
if ~isempty( dist_matrix );
  dist_matrix = smooth2d( dist_matrix );
  for i = 1:length( contour_levels )
    [c,h]=contour(rad_res, hit_res, tril(dist_matrix), ...
		  contour_levels(i) * [1 1],...
		  'color',colorcode(i,:) );
    legends{i} = sprintf( '%d Angstrom', contour_levels(i) );
  end
end

plot( ligpos([1 end]), ligpos( [1 end] ),'k','linew',2 );
hold off;

legend( legends );
title( strrep( name,'_','\_') );

if ( ~isempty( strfind( name, '\newline' ) ) ) name = 'COMBINED'; end;
epsfilename = [name,'.eps'];
if ( USE_Z_SCORE ) epsfilename = strrep( epsfilename,'.eps','.ZSCORE.eps'); end
fprintf( 'Outputting: %s\n', epsfilename );
print( '-depsc2', epsfilename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ D_smooth, seqpos, ligpos, r, mean_rel_error ]  = get_D_smooth( rdat_file, USE_Z_SCORE, MOD_CORRECT );

if ischar( rdat_file )
  r = read_rdat_file( rdat_file );
else
  r = rdat_file;
end

mean_rel_error = mean( r.reactivity_error ) / mean(r.reactivity);

clf;

D = r.reactivity;
ligpos = str2num( char(get_tag( r, 'lig_pos' )) );
seqpos = r.seqpos;

if USE_Z_SCORE
  %D_err = r.reactivity_error;
  [ D_correct, D_correct_err ] = determine_corrected_reactivity( D, 1.0);
  D_show = get_MOHCAseq_zscores( D_correct, D_correct_err, 0.0 );
  threshold = 0.5;
else

  N_RNA = size(D,2);
  refcols = N_RNA+[-12:-2];
  
  [D_norm, ref_profile] = normalize_to_RNA( D, refcols );
  
  D_norm( isnan( D_norm ) ) = 0.0;
  D_norm = D_norm/ mean( mean(D_norm) );
  D_repsub = D_norm  - repmat( mean(D_norm( :, refcols ),2), 1, N_RNA);
  
  % set background based on sliding window within each vertical column.
  gaussian_wide = fspecial('gaussian',[1,20],50); 
  D_backgd = filter2(gaussian_wide, max(D_repsub,0));
  D_backsub = D_repsub -  D_backgd;
  
  %D_show = D_backsub;
  %D_show = D_repsub;
  
  D_show = 10*D_norm;
  
  if MOD_CORRECT
    mod_profile = repmat( smooth( ref_profile ), 1, N_RNA);
    mod_profile = mod_profile / mean( mod_profile(  find( ~isnan( mod_profile) ) ) );
    D_correct_for_mod = D_backsub ./ mod_profile; 
    D_show = D_correct_for_mod;
  end;
  
  D_show_ref = max(D_show(:,refcols ),0);
  threshold = mean( std( D_show_ref ) );
end

D_smooth = smooth2d( D_show' - 0.2*threshold);