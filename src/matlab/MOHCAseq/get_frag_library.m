function [ frag_lib_seqs, frag_lib_heads, frag_lib_seqs_tail ] = get_frag_library( rna_seqs_FL, tail_sequence_file )

%%% [ frag_lib_heads, frag_lib_seqs_tail ] = get_frag_library( rna_seqs_FL, tail_sequence_file );
%%%
%%%   Read in a file of full-length RNA sequence(s) ("rna_seqs_FL") and the
%%%   sequence of the DNA tail ligated on after RNA fragmentation
%%%   ("tail_sequence_file"). Output is a library of sequence fragments starting
%%%   from the 5'-end and covering the first n nucleotides of the input RNA
%%%   sequences, where n ranges from 0 to the length of the input RNA
%%%   sequence; the sequence of the DNA tail is appended to each output
%%%   sequence. 
%%%
%%%   This library ("RNA_sequences.fasta") is used as an input to the
%%%   MAPseeker software to analyze RNAs probed by chemical mapping
%%%   techniques and read out by deep sequencing.
%%%
%%%  INPUTS
%%%     rna_seqs_FL:    A file in fasta format containing headers and the full-length sequences of each RNA of interest. [default: 'MOHCA.fasta']
%%%     tail_sequence_file:  A file in fasta format containing a header and the sequence of the DNA tail ligated to RNA fragments
%%%                     after hydroxyl radical fragmentation and end-repair. [default: CUGUAGGCACCAUCAAU]
%%%
%%%  OUTPUTS
%%%     frag_library.fasta: The script saves a fasta format file containing
%%%          headers and sequences for RNA fragments starting at the 5'-end
%%%          and ending at each nucleotide in the full-length sequence, with
%%%          the DNA tail sequence appended.
%%%     frag_lib_heads: Headers used to create the frag_library fasta file.
%%%          Each header is in the format "RNAname_Tailname_length", where
%%%          length is counted from the 5'-end.
%%%     frag_lib_seqs_tail: Sequences used to create the frag_library fasta
%%%          file. Each sequence is a subset of the corresponding RNA
%%%          sequence, starting from the 5'-end and increasing in 1 nt
%%%          intervals. The sequence of the ligated DNA tail is appended to
%%%          each fragment sequence.
%%%
%%%
%%%
%%% (C) Clarence Cheng, 2013

%% defaults
if ~exist( 'rna_seqs_FL', 'var' ); rna_seqs_FL = 'MOHCA.fasta'; end;

%% Read fasta format to get names and sequences of full-length RNAs

% Read full-length RNA sequences and headers, as well as sequence and header of DNA tail, from .fasta files
[rna_heads, rna_seqs] = fastaread(rna_seqs_FL);

if ~exist( 'tail_sequence_file', 'var' ); 
  tail_seq= 'CUGUAGGCACCAUCAAU'; 
  tail_head = 'univ';
else
  if exist( tail_sequence_file, 'file' )
    [tail_head, tail_seq] = fastaread(tail_sequence_file);
  else 
    tail_seq = tail_sequence_file;
    tail_head = 'tail';
  end
end

% Separate elements of rna_heads into separate cells in rna_tags
if ~iscellstr(rna_heads)
    rna_heads = {rna_heads};
end

rna_tags = {};
offset = zeros( length( rna_heads ), 1 );
for i = 1:length(rna_heads)
    rna_tags{i} = split_string(rna_heads{i}, sprintf('\t'));

    % look for offset tag
    offset_string = get_tag_from_string( rna_heads{i}, 'offset' );
    if length( offset_string ) > 0; offset(i) = str2num( offset_string ); end;
end


% Convert rna_heads and rna_seqs to cell arrays of strings
rna_heads = cellstr(rna_heads);
rna_seqs = cellstr(rna_seqs);

% Loop over number of full-length RNA sequences (in rna_heads) and for
% each, loop over the length of the sequence, building header and sequence
% cell arrays for the fragment library.
    
frag_lib_heads = {};
frag_lib_seqs = {};

%rna_tags{i}

for i = 1:length(rna_heads)
    
    for j = 1:length(rna_seqs{i})+1
        lig_pos = j + offset(i);
        frag_lib_heads = [frag_lib_heads sprintf('%s-%s\tlig_pos:%d\t%s',...
						 char(rna_tags{i}(1)),...
						 char(tail_head),...
						 lig_pos,...
						 join_string(rna_tags{i}(2:end),sprintf('\t')))];    % Create headers
        if j == 1
            frag_lib_seqs = [frag_lib_seqs ' '];                                % First line of each set of sequence fragments is ' '
        else
            frag_lib_seqs = [frag_lib_seqs rna_seqs{i}(1:j-1)];                 % Create sequences
        end
    end

    lig_pos = length( rna_seqs{i} ) + 1 + 1 + offset(i);
    frag_lib_heads =  [frag_lib_heads sprintf('%s-STAR-%s\tlig_pos:%d\t%s',...
					      char(rna_tags{i}(1)),...
					      char(tail_head),...
					      lig_pos,...
					      join_string(rna_tags{i}(2:end),sprintf('\t')))];    % Create headers
   
    frag_lib_seqs = [frag_lib_seqs [rna_seqs{i},'*']];                 % Create 'STAR' sequence -- wild card for heterogeneous 3' ends.
    
end

frag_lib_seqs_tail = strcat(frag_lib_seqs, tail_seq);                           % Append DNA tail sequence to each RNA fragment sequence

for i = 1:length(frag_lib_seqs)
    if frag_lib_seqs_tail{i}(1) == ' '
        frag_lib_seqs_tail{i}(1) = '';                                                  % Delete space at beginning of first (_1) sequence
    end
end

RNA_sequences_file = 'RNA_sequences.fasta';
fprintf( 'Generating from %s: %s\n', rna_seqs_FL, RNA_sequences_file );
if exist( RNA_sequences_file ); delete( RNA_sequences_file ); end;
fastawrite_noNL( RNA_sequences_file, frag_lib_heads, frag_lib_seqs_tail );    % Write headers and sequences to fragment library .fasta file








