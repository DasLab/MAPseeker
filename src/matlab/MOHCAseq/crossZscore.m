function [Z, Z_err, seqpos, D_symm] = crossZscore( r, ok_res );
% [Z, Z_err, seqpos, D_symm] = crossZscore( r, ok_res );
%
% Z-score based 'resculpting' of map, e.g., from COHCOA analysis.
%
% Inputs
%  r      = rdat file
%  ok_res = sequence positions over which to compute mean and stdev for Z-scores
%
% Outputs
%  Z     = output matrix of Z-scores
%  Z_err = output matrix of Z-score errors
%  seqpos         = output vector of sequence positions
%  D_symm         = original data, symmetrized.
%
% (C) Rhiju Das, 2013.

if ischar( r ); r = read_rdat_file( r ); end;
if ~exist( 'ok_res', 'var' ) ok_res = r.seqpos( 11:end-10) ; end;

seqpos = r.seqpos;
ligpos = get_ligpos( r );

D     = max(r.reactivity, 0);
D_err = r.reactivity_error;
D     = symmetrize( D, seqpos, ligpos );
D_err = symmetrize( D_err, seqpos, ligpos );

SEQ_SEP = 7;
[max_i, mean_i, std_i, points_i ] = get_comparison_point_info( D,  seqpos, ligpos, ok_res, SEQ_SEP );
[max_j, mean_j, std_j, points_j ] = get_comparison_point_info( D', ligpos, seqpos, ok_res, SEQ_SEP );

for i = 1:length(seqpos)
  for j = 1:length(ligpos)
        
    % Z-score style...
    comparison_points = [ points_i{i}, points_j{j} ];
    m = mean( comparison_points );
    s = std( comparison_points );
    Z(i,j)     = ( D(i,j) - m )/s;
    Z_err(i,j) = ( D_err(i,j) )/s;
    
    %Z_i = ( D(i,j) - mean_i(i) )/std_i(i);
    %Z_j = ( D(i,j) - mean_j(j) )/std_j(j);
    %Z(i,j) = mean( [Z_i, Z_j] );
    
    %Z(i,j) = D(i,j) / (0.5*( max_i(i)+ max_j(j) ) );
    %Z(i,j) = D(i,j) / max( max_i(i), max_j(j) );
  end
end

%Z = max( Z, 0 );

image( seqpos, ligpos, 10 * Z' );
colormap( 1 - gray(100));
set(gcf, 'PaperPositionMode','auto','color','white');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function max_i_window = window_max( max_i );

max_i_window = max_i;
N = length( max_i );
for i = 2:N-1;  max_i_window(i) = max( max_i(i-1:i+1) ); end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [max_i, mean_i, std_i, points_i ] = get_comparison_point_info( D, seqpos, ligpos, ok_res, SEQ_SEP );

ok_pos = [];
for i = ok_res; ok_pos = [ok_pos, find( ligpos == i ) ]; end;

max_i  = zeros(length(seqpos),1);
mean_i = zeros(length(seqpos),1);
std_i  = zeros(length(seqpos),1);
for i = 1:length( seqpos )
  gp = find( abs( ligpos - i ) > SEQ_SEP );
  gp = intersect( gp, ok_pos );
  gp = intersect( gp, find( ~isnan(D(i,:)) ) );
  p = D(i,gp);
  if ~isempty( p )
    max_i(i)    = max( p );
    mean_i(i)   = mean( p );
    std_i(i)    = std( p );
  end
  points_i{i} = p;
    
end

