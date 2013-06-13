function rdat = MAPseeker_to_rdat( filename, name, D, D_err, primer_info, RNA_info, comments, annotations );
%
% rdat = output_MAPseeker_data_to_rdat_file( filename, name, D, D_err, primer_info, RNA_info, comments );
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

if ~exist( 'output_workspace_to_rdat_file', 'file' )
  fprintf( '\nCannot find function output_workspace_to_rdat_file() ...\nWill not output RDAT: %s.\n', filename );
  fprintf( 'Install RDATkit and include   rdatkit/matlab_scripts/   in MATLAB path.\n\n' );
  return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reformat data to cell.
reactivity     = [];
reactivity_err = [];
data_annotations = {};

modifier_list = get_modifier_list(); % put this in rdatkit

if length( primer_info ) ~= length( D );   fprintf( 'Primer_info length does not match D length\n' ); return; end
if length( RNA_info )    ~= size( D{1}, 2 );  fprintf( 'RNA_info length does not match D length\n' ); return; end

JUST_ONE_RNA = (length( RNA_info ) == 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 0;
is_eterna = 0;
max_seq_len = 0;
for j = 1 : size( D{1}, 2 )

  for i = 1:length(D)

    % don't output nomod [will have counts of exactly zero] -- just check first row.
    if ( sum(D{i}(:,1)) == 0 ); continue; end;

    % parse primer tag -- look for information on modifier.
    primer_tag = primer_info(i).Header;
    primer_tag_cols = split_string( primer_tag, '\t' );
    if ~isempty(find( strcmp('NO_OUTPUT', primer_tag_cols) ) ) continue; end;
    
    count = count + 1;
    reactivity(:,count) = D{i}(:,j);
    reactivity_err(:,count) = D_err{i}(:,j);

    SN_ratio(count)   = estimate_signal_to_noise_ratio( reactivity(:,count), reactivity_err(:,count) );
    SN_classification = classify_signal_to_noise_ratio( SN_ratio(count) );

    modifier = '';
    ID = '';
    project_name = '';
    design_name = '';
    tag_cols = {};
    
    % parse RNA tag -- look for information on ID
    RNA_tag = RNA_info(j).Header;    
    RNA_tag_cols = split_string( RNA_tag, '\t' );
    if length( RNA_tag_cols ) == 3 & is_ID( RNA_tag_cols{1} ) % came from an eterna run?
      ID = RNA_tag_cols{1}; 
      if ID(1) == ' '; ID = ID(2:end); end; % space in FASTA file.
      design_name = RNA_tag_cols{3};
      project_name = RNA_tag_cols{2};
      is_eterna = 1;
    else
      tag_cols = [tag_cols, RNA_tag_cols]; % crap, may not work. Anyway...
    end

    for k = 1:length( primer_tag_cols )
      find_it = find( strcmp( primer_tag_cols{k}, modifier_list ) );
      if ~isempty( find_it )
	modifier = primer_tag_cols{k};
      else
	tag_cols = [tag_cols, primer_tag_cols{k}];
      end
    end    

    max_seq_len = max( max_seq_len, length( RNA_info(j).Sequence ) );

    data_annotation = {};
    if length( modifier    ) > 0;  data_annotation  = [data_annotation,  ['modifier:',modifier] ]; end;
    if length( design_name ) > 0;  data_annotation  = [data_annotation,  ['MAPseq:design_name:',design_name] ]; end;
    if length( project_name) > 0;  data_annotation  = [data_annotation,  ['MAPseq:project_name:',project_name] ]; end;
    if length( ID          ) > 0;  data_annotation  = [data_annotation,  ['MAPseq:ID:',ID] ]; end;
    if ~JUST_ONE_RNA
      data_annotation  = [data_annotation,  ['sequence:',RNA_info(j).Sequence] ];
      if isfield( RNA_info, 'Structure' ) & length(RNA_info(j).Structure) > 0; data_annotation = [ data_annotation, ['structure:',RNA_info(j).Structure] ];  end;
    end
    data_annotation = [data_annotation, ['signal_to_noise:',SN_classification,':',num2str(SN_ratio(count),'%8.3f') ] ];
    for  k = 1:length( tag_cols ) 
      tag_col = tag_cols{k};
      if isempty( strfind( tag_col, ':' ) )
	data_annotation  = [data_annotation,  ['MAPseq:tag:',tag_col] ];     
      else
	data_annotation  = [data_annotation,  tag_col ];     
      end
    end

    data_annotations{count} = data_annotation;
    
  end
end


fprintf( 'Maximum sequence length: %d\n', max_seq_len );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if JUST_ONE_RNA 
  sequence = RNA_info(1).Sequence;
  structure = RNA_info(1).Structure;
else
  sequence = ''; for k = 1:max_seq_len; sequence = [sequence,'X']; end;
  structure = strrep( sequence, 'X','.');
end  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
seqpos = [ 1 : size(reactivity,1) ];
offset = 0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% special -- P4-P6 has a known conventional numbering...
P4P6_double_ref_sequence = 'GGCCAAAGGCGUCGAGUAGACGCCAACAACGGAAUUGCGGGAAAGGGGUCAACAGCCGUUCAGUACCAAGUCUCAGGGGAAACUUUGAGAUGGCCUUGCAAAGGGUAUGGUAAUAAGCUGACGGACAUGGUCCUAACCACGCAGCCAAGUCCUAAGUCAACAGAUCUUCUGUUGAUAUGGAUGCAGUUCAAAACCAAACCGUCAGCGAGUAGCUGACAAAAAGAAACAACAACAACAAC';
if strcmp( sequence, P4P6_double_ref_sequence )
  fprintf( 'Recognized REFERENCE sequence as P4P6 with two hairpins!\n' );
  offset = 71;
  if length( structure ) == 0; structure = '.......((((((.....))))))...........((((((...((((((.....(((.((((.(((..(((((((((....)))))))))..((.......))....)))......)))))))....))))))..)).))))((...((((...(((((((((...)))))))))..))))...)).............((((((.....))))))......................'; end;
  seqpos = seqpos + offset;
elseif is_eterna
  comments = [comments, ['from data: ',name] ];
  name = 'EteRNA Cloud Lab';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if any annotations are shared across all data_annotations, move them up to the level of 'annotations'
% and remove them from data_annotations.
if ~exist( 'annotations', 'var') annotations = {}; end;
[annotations, data_annotations] = find_shared_annotations( annotations, data_annotations );

rdat = output_workspace_to_rdat_file( filename, name, sequence, offset, seqpos, reactivity, ...
				      structure, ...
				      annotations, data_annotations, ...
				      reactivity_err, ...
				      [],[],[], comments );

%rdat = show_rdat( filename );

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok = is_ID( tag );

tag = strrep( tag, 'WTF',''); % weird problem in some eterna IDs.
tag_cols = split_string( tag, '-' );
tag = tag_cols{1};

ok = 0;
if ~isempty( str2num( tag ) ) ok = 1; end;
  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if any annotations are shared across all data_annotations, move them up to the level of 'annotations'
% and remove them from data_annotations.
function [shared_annotations, data_annotations] = find_shared_annotations( input_annotations, data_annotations );

shared_annotations = data_annotations{1};

match = ones(  length( shared_annotations ), 1 );
for m = 1:length( shared_annotations )
  for k = 2:length( data_annotations )
    if sum( strcmp( shared_annotations{m}, data_annotations{k} ) ) == 0
      match(m) = 0; break;
    end
  end
end
shared_annotations = shared_annotations( find(match) );

% remove these shared annotations from data_annotations
for k = 1:length( data_annotations )
  for m = 1:length( shared_annotations )
    unique_pos = find( ~strcmp( data_annotations{k}, shared_annotations{m} ) );
    data_annotations{k} = data_annotations{k}( unique_pos );
  end
end

shared_annotations = [ shared_annotations, input_annotations ];
