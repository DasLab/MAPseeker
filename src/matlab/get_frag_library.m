function [ frag_lib_heads, frag_lib_seqs_tail ] = get_frag_library( rna_sequences, tail_sequence )

% [ frag_lib_heads, frag_lib_seqs_tail ] = get_frag_library( rna_sequences, tail_sequence );
%
%   Read in a file of RNA sequences ("rna_sequences") and the sequence of
%   the DNA tail ligated on after RNA fragmentation ("tail_sequence").
%   Output is a library of sequence fragments starting from the 5'-end and
%   covering the first n nucleotides of the input RNA sequences, where n
%   ranges from 0 to the length of the input RNA sequence; the sequence of
%   the DNA tail is appended to each output sequence.
%
%   This library ("frag_library.fasta") can be an input to the MAPseeker
%   software for analysis of RNA sequences read out by deep sequencing.
%
%   Inputs:
%       rna_sequences: A file in fasta format containing headers and the
%          full-length sequences of each RNA of interest.
%       tail_sequence: A file in fasta format containing a header and the
%          sequence of the DNA tail ligated to RNA fragments after hydroxyl
%          radical fragmentation and end-repair.
%
%   Outputs:
%       frag_library.fasta: The script saves a fasta format file containing
%          headers and sequences for RNA fragments starting at the 5'-end
%          and ending at each nucleotide in the full-length sequence, with
%          the DNA tail sequence appended.
%       frag_lib_heads: Headers used to create the frag_library fasta file.
%          Each header is in the format "RNAname_Tailname_length", where
%          length is counted from the 5'-end.
%       frag_lib_seqs_tail: Sequences used to create the frag_library fasta
%          file. Each sequence is a subset of the corresponding RNA
%          sequence, starting from the 5'-end and increasing in 1 nt
%          intervals. The sequence of the ligated DNA tail is appended to
%          each fragment sequence.
%
%
% (C) Clarence Cheng, 2013


%% Read fasta format to get names and sequences of full-length RNAs

% Read full-length RNA sequences and headers, as well as sequence and header of DNA tail, from .fasta files
[rna_heads, rna_seqs] = fastaread(rna_sequences);
[tail_head, tail_seq] = fastaread(tail_sequence);

% Convert rna_heads and rna_seqs to cell arrays of strings
rna_heads = cellstr(rna_heads);
rna_seqs = cellstr(rna_seqs);

% Loop over number of full-length RNA sequences (in rna_heads) and for
% each, loop over the length of the sequence, building header and sequence
% cell arrays for the fragment library.
    
frag_lib_heads = {};
frag_lib_seqs = {};

for i = 1:length(rna_heads)
    
    for j = 1:length(rna_seqs{i})+1
        frag_lib_heads = [frag_lib_heads strcat(rna_heads{i}, '_', tail_head, '_', num2str(j-1))];    % Create headers
        if j == 1
            frag_lib_seqs = [frag_lib_seqs ' '];                                % First line of each set of sequence fragments is ' '
        else
            frag_lib_seqs = [frag_lib_seqs rna_seqs{i}(1:j-1)];                 % Create sequences
        end
    end
    
end

frag_lib_seqs_tail = strcat(frag_lib_seqs, tail_seq);                           % Append DNA tail sequence to each RNA fragment sequence

frag_lib_seqs_tail{1}(1) = '';                                                  % Delete space at beginning of first (_0) sequence

fastawrite_noNL( 'frag_library.fasta', frag_lib_heads, frag_lib_seqs_tail );    % Write headers and sequences to fragment library .fasta file







