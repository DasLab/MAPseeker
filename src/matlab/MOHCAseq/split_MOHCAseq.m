function [D_split] = split_MOHCAseq( D, seqlengths )

%%%
%%%   This is a helper function for analyzing MOHCA-Seq data. The array of
%%%   reactivities (D) output by quick_look_MAPseeker separates the
%%%   sequencing data by the sequencing primer used for reverse
%%%   transcription but does not separate the subsets of reactivities
%%%   assigned to each RNA used to generate the fragment library using
%%%   get_frag_library.
%%%
%%%   This script accepts a cell array of reactivities (D) and an array of
%%%   RNA sequence lengths (seqlengths) and splits each cell in D
%%%   (corresponding to all data assigned to each primer) into n cells,
%%%   where n is the number of sequence lengths specified by the user. The
%%%   values of seqlengths determines the subsets of data sorted into each
%%%   new cell.  
%%%
%%%
%%%   INPUTS:
%%%     D:          Array or cell array of reactivities, output by MAPseeker 
%%%     seqlengths: Array of sequence lengths in the same order as the RNA sequences in the RNA_sequences.fasta used to generate the fragment library 
%%%
%%% (C) Clarence Cheng, 2013


D_split = {};

for i = 1:length(D)
    
    n = 1;
    
    for j = 1:length(seqlengths)
        
        m = n + seqlengths(j)
        D_split{j,i} = D{1,i}(:,n:m);
        n = m+1
        
    end
    
end
