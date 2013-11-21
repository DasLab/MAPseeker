function [ D_show, seqpos, ligpos, r, D_show_error, r_name ]  = get_D_smooth( rdat_file, MODE );

% [ D_show, seqpos, ligpos, r, D_show_error, r_name ]  = get_D_smooth( rdat_file, MODE );
%
%

if ischar( rdat_file )
  r_name = rdat_file;

  % already calculated?
  cohcoa_filename = get_cohcoa_filename( rdat_file );
  if MODE == 1 & exist( cohcoa_filename ) 
    r = read_rdat_file( cohcoa_filename );
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
ligpos   = get_ligpos( r );
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
    %[Q, Q_err ] = cohcoa_from_reactivity( r, r_name );
    [Q, Q_err ] = cohcoa_classic( r, r_name );
    figure(h);clf;
  end

  Q_scaling = figure_out_Q_scaling( Q ) / 30;
  D_show         = Q_scaling * Q;
  D_show_error   = Q_scaling * Q_err;
  seqpos = seqpos( 1:length(ligpos) );

  %[D_show, D_show_error, seqpos ] = crossZscore( r );
  %D_show = D_show/4;
  %D_show_error = D_show_error/4;  
  %Q_scaling = figure_out_Q_scaling( D_show )/60;
  %D_show         = Q_scaling * D_show;
  %D_show_error   = Q_scaling * D_show_error;
  
elseif (MODE == 2)
  [ D_show, D_err ] = latte(r);
  % Some data thresholding and scaling mainly for compatibility with plotting.
  D_scaling = 120;
  cutoff = 0.5 * ( mean(mean(D_show)) + std(std(D_show)) );
  D_show(D_show < cutoff) = 0;
  D_show = D_show * D_scaling;
  D_show_error = D_err * D_scaling;
elseif ( MODE == 3)

  % Use Clarence's Z-score pipeline, which takes in reactivities.
  %D_err = r.reactivity_error;
  [ D_correct, D_correct_err ] = determine_corrected_reactivity( D, 1.0);
  
  [D_show, D_show_error] = get_MOHCAseq_zscores( D_correct, D_correct_err, 0.0 );

  %D_show = 4 * D_correct;
  %D_show_err = 4 * D_correct_err;
  
  %clf
  %errorbar( D_show(:,170), D_show_error(:,170) );
  %pause

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
  D_show = D_show - 0.1*threshold;
else
  error( sprintf('Unrecognized MODE: %d\n', MODE) );
end

