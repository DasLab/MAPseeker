function rdat = output_MAPseeker_data_to_rdat_file( filename, name, D_average, D_average_err, annotations, comments, data_annotations );
%
% rdat = output_MAPseeker_data_to_rdat_file( filename, name, D_average, D_average_err, annotations, comments, data_annotations/RNA_info );
%
%  filename  = name of file to output to disk
%  name      = will show up in NAME field of RDAT -- short description of RNA whos variants are tested.
%  D_average = Matrix of data
%
% (C) R. Das, 2013
%

if nargin==0; help( mfilename ); return; end;

fprintf( '\nWARNING! WARNING! WARNING! WARNING! \n' )
fprintf( 'WARNING! WARNING! WARNING! WARNING! \n' )
fprintf(  [mfilename, '\n is deprecated and will be removed soon\n'] );
fprintf( 'Consider using MAPseeker_to_rdat instead (or\n functionality within quick_look_MAPseeker)\n');
fprintf( 'WARNING! WARNING! WARNING! WARNING! \n' )
fprintf( 'WARNING! WARNING! WARNING! WARNING! \n\n' )

if nargin == 0; help( mfilename ); return; end;

seqpos = [0:size(D_average,2)-1];

% don't need to output fully extended band (at site "0") -- 
% its zero after processing
outbins = [2 : length(seqpos)]; 
seqpos_out = seqpos( outbins ); 
reactivity_out =  D_average(:,outbins)';
reactivity_err_out =  D_average_err(:,outbins)';

offset = 0; mutpos = [];

sequence = ''; for k = 1:(size(D_average,2)-1); sequence = [sequence,'X']; end;
structure = strrep( sequence, 'X','.');

if ~iscell( data_annotations ) % assume it is an RNA_info object
  RNA_info = data_annotations;
  data_annotations = {};
  for j = 1:length( RNA_info )
    tag = RNA_info(j).Header;    
    data_annotations{j} = { ['name:',tag],  ['sequence:',RNA_info(j).Sequence] };
  end
end

rdat = output_workspace_to_rdat_file( filename, name, sequence, offset, seqpos_out, reactivity_out, ...
			       mutpos, structure, ...
			       annotations, data_annotations, ...
			       reactivity_err_out, ...
			       [],[],[], comments );

rdat = show_rdat( filename );

