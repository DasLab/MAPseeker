function rdat = MAPseeker_to_rdat_by_primer( filename, name, D, D_err, primer_info, RNA_info, comments, annotations, INCLUDE_ZERO_IN_SEQPOS );
%
% rdat = MAPseeker_data_to_rdat_by_primer( filename, name, D, D_err, primer_info, RNA_info, comments );
%
%  filename  = name of file to output to disk
%  name      = will show up in NAME field of RDAT -- short description of RNA whos variants are tested.
%  D     = Matrix of data
%  D_err = Matrix of data errors
%  RNA_info = Object with RNA names, sequences, and potentially structures
%  comments = comments to put in RDAT
%  annotations = any annotations to include in ANNOTATION.
%
% (C) R. Das, 2013
%

if nargin == 0; help( mfilename ); return; end;
if ~exist( 'INCLUDE_ZERO_IN_SEQPOS' ) INCLUDE_ZERO_IN_SEQPOS = 0; end;
rdat = {};

for i = 1:length(D)
  filename_by_primer = strrep( filename, '.rdat', sprintf( '.%d.rdat', i) );
  rdat{i} = MAPseeker_to_rdat( filename_by_primer, name, D(i), D_err(i), primer_info(i), RNA_info, comments, annotations, INCLUDE_ZERO_IN_SEQPOS );
end

