function [profile, seqpos_out] = extract_profile( r, which_res );
%  [profile, seqpos_out] = extract_profile( r, which_res );
%
%  Takes specified column from rdat and outputs text file that can
%   be visualized in color_by_data() in pymol [see das lab pymol scripts
%   at https://github.com/DasLab/pymol_daslab].
%  The data are read up to the diagonal and across, i.e. along the row
%   or column corresponding to the specified residue depending on which
%   one contains data in MOHCA data sets (where stop pos < cleave pos ).
%
% Inputs:
%  r         = filename for rdat
%  which_res = one or more sequence positions 
%
% Outputs:
%  The script will produce a textfile like 'profile_135.txt'
%
%  profile    = profile extracted from data/
%  seqpos_out = sequence positions
%
% (C) R. Das, Stanford University, 2013
%
if ischar( r );  r = read_rdat_file( r );  end
SEQSEP = 5;

D = max( r.reactivity(), 0 );
ligpos = get_ligpos( r );
seqpos = r.seqpos;

count = 0;
for res = which_res
  count = count + 1;
  outfile = sprintf( 'profile_%d.txt', res );
  fid = fopen( outfile, 'w' );

  n = find( seqpos == res );
  for i = 1:n
    i_offset = min( i, n-SEQSEP );
    fprintf( fid, '%d %f\n', seqpos(i), D(i_offset,n) );
    seqpos_out(i) = seqpos(i);
    profile(i,count) = D(i_offset,n);
  end

  n = find( ligpos == res );
  N = size( D, 2 );
  for j = n+1:N
    j_offset = max( j, n+SEQSEP );
    fprintf( fid, '%d %f\n', ligpos(j), D(n,j_offset) );
    seqpos_out(j) = ligpos(j);
    profile(j,count) = D(n,j_offset);
  end

  fprintf( 'Created: %s\n', outfile );
  fclose( fid );
end

