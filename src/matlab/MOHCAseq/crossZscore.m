function [D_resculpt, D_resculpt_err, seqpos, D_symm] = crossZscore( r, ok_res );
% [D_resculpt, D_resculpt_err, seqpos, D_symm] = crossZscore( r, ok_res );
%
% Z-score based 'resculpting' of map, e.g., from COHCOA analysis.
% Note that this removes some data so that the matrix is square with
%  seqpos = ligpos.
%
% Inputs
%  r      = rdat file
%  ok_res = sequence positions over which to compute mean and stdev for Z-scores
%
% Outputs
%  D_resculpt     = output matrix of Z-scores
%  D_resculpt_err = output matrix of Z-score errors
%  seqpos         = output vector of sequence positions
%  D_symm         = original data, symmetrized.
%
% (C) Rhiju Das, 2013.

if ischar( r ); r = read_rdat_file( r ); end;

seqpos = r.seqpos;
ligpos = get_ligpos( r );

D = max( r.reactivity( 2:end, 1:end-1), 0 );
D_err = r.reactivity_error( 2:end, 1:end-1);

seqpos = r.seqpos( 2:end );
ligpos = ligpos( 1:end-1);
assert( all(seqpos == ligpos') );
N = length( seqpos );

if ~exist( 'ok_res' ) ok_res = seqpos; end;

for i = 1:N
  for j = 1:(i-1)
    D(i,j)     = D(j,i);
    D_err(i,j) = D_err(j,i);
  end
end

D_symm = D;
ok_pos = [];
for i = ok_res; ok_pos = [ok_pos, find( seqpos == i ) ]; end;

SEQ_SEP = 5;
[max_i, mean_i, std_i, points_i ] = get_comparison_point_info( D, seqpos, ok_pos, SEQ_SEP );
[max_j, mean_j, std_j, points_j ] = get_comparison_point_info( D', seqpos, ok_pos, SEQ_SEP );

for i = 1:N
  for j = 1:N
        
    % Z-score style...
    comparison_points = [ points_i{i}, points_j{j} ];
    m = mean( comparison_points );
    s = std( comparison_points );
    D_resculpt(i,j)     = ( D(i,j) - m )/s;
    D_resculpt_err(i,j) = ( D_err(i,j) - m )/s;
    
    %Z_i = ( D(i,j) - mean_i(i) )/std_i(i);
    %Z_j = ( D(i,j) - mean_j(j) )/std_j(j);
    %D_resculpt(i,j) = mean( [Z_i, Z_j] );
    
    %D_resculpt(i,j) = D(i,j) / (0.5*( max_i(i)+ max_j(j) ) );
    %D_resculpt(i,j) = D(i,j) / max( max_i(i), max_j(j) );
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function max_i_window = window_max( max_i );

max_i_window = max_i;
N = length( max_i );
for i = 2:N-1;  max_i_window(i) = max( max_i(i-1:i+1) ); end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [max_i, mean_i, std_i, points_i ] = get_comparison_point_info( D, seqpos, ok_pos, SEQ_SEP );

N = length( seqpos );
for i = 1:N
  gp = find( abs( [1:N] - i ) > SEQ_SEP );
  gp = intersect( gp, ok_pos );
  max_i(i) = max( D(i,gp) );
  mean_i(i) = mean( D(i,gp) );
  std_i(i) = std( D(i,gp) );
  points_i{i} = D(i,gp );
end
