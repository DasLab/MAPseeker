function print_it( fid, output_text );
%  print_it( fid, output_text );
%
% silly helper function -- prints to command line window and to text file (specified by fid )
%
if ~exist( 'fid', 'var' ) fid = 0; end;
fprintf( output_text );

if ( fid > 0 )
  fprintf( fid, output_text );
end