function [ D_smooth, seqpos, ligpos, r, D_smooth_error, r_name ]  = get_D_smooth( rdat_file, MODE );

if ischar( rdat_file )
  r_name = rdat_file;

  % already calculated?
  iterfit_x_filename = get_iterfit_filename( rdat_file );
  if MODE == 1 & exist( iterfit_x_filename ) 
    r = read_rdat_file( iterfit_x_filename );
    Q     = r.reactivity;
    Q_err = r.reactivity_error;
  else
    r = read_rdat_file( r_name );
  end
else
  r = rdat_file;
  r_name = r.name;
end


clf;

D        = r.reactivity;
ligpos   = str2num( char(get_tag( r, 'lig_pos' )) );
seqpos   = r.seqpos;
sequence = r.sequence;

% signal-to-noise estimate is mean(error)/mean(counts), and seems to 
% correspond well to visual estimate of how noisy the data sets are.
mean_rel_error = mean( r.reactivity_error( find( r.reactivity_error > 0 ) ) ) / mean(r.reactivity( find( r.reactivity > 0 )) );

% placeholder value for Z-score & repsub pipelines.
D_show_error = 0*D + mean_rel_error;

if ( MODE == 1 | MODE == 0)

  if ~exist( 'Q', 'var' )
    h = gcf;
    figure(2)
    [Q, Q_err ] = iterfit_x( r, r_name );
    figure(h);clf;
  end

  Q_scaling = figure_out_Q_scaling( Q ) / 20;

  D_show         = Q_scaling * Q;
  D_show_error   = Q_scaling * Q_err;
  threshold = 0.0;
  seqpos = seqpos( 1:length(ligpos) );

elseif (MODE == 2)
  [ D_show, D_err ] = latte(r);
  % Some data thresholding and scaling mainly for compatibility with plotting.
  D_scaling = 50;
  cutoff = mean(mean(D_show)) + 0.0*std(std(D_show));
  D_show(D_show < cutoff) = 0;
  D_show = D_show * D_scaling;
  D_err = D_err * D_scaling;
  threshold = 0.0;
elseif ( MODE == 3)

  % Use Clarence's Z-score pipeline, which takes in reactivities.
  %D_err = r.reactivity_error;
  [ D_correct, D_correct_err ] = determine_corrected_reactivity( D, 1.0);
  D_show = get_MOHCAseq_zscores( D_correct, D_correct_err, 0.0 );
  threshold = 0.5;

elseif ( MODE == 4 | MODE == 5)

  % 'repsub' pipeline.
  N_RNA = size(D,2);

  % use average reverse transcription profile over RNAs that got cut in 3' flanking sequences to provide a 
  % reference to stuff that isn't the contact map.
  refcols = N_RNA+[-12:-2];
  [D_norm, ref_profile] = normalize_to_RNA( D, refcols );
  
  % normalized each 'row' (reverse transcription profile) based on match of observed window to 
  % corresponding window in reference profile.
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

  % reweights so that data from regions that are radical-source-rich are pushed back down
  % to the level of other regions.
  if MODE == 5
    mod_profile = repmat( smooth( ref_profile ), 1, N_RNA);
    mod_profile = mod_profile / mean( mod_profile(  find( ~isnan( mod_profile) ) ) );
    D_correct_for_mod = D_backsub ./ mod_profile; 
    D_show = D_correct_for_mod;
  end;
  
  D_show_ref = max(D_show(:,refcols ),0);
  threshold = mean( std( D_show_ref ) );
else
  error( sprintf('Unrecognized MODE: %d\n', MODE) );
end

% Removing noise for pretty plots. Note that this will have negative values, but
% those will not be displayed on image.
D_smooth = D_show - 0.1*threshold;
D_smooth_error = D_show_error;
