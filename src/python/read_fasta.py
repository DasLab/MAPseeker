#!/usr/bin/python

def read_fasta( fasta_file ):
    tags = []
    seqs = []
    seq_RCs = []
    lines = open( fasta_file ).readlines()
    for line in lines: # worst fasta reader in the world.
        line = line.replace( '\n','')
        if line[0] == '>':
            tags.append( line[1:] )
            continue
        if len( line ) > 1:
            seq = line[:-1]
            seqs.append( seq )
            seq_RC = reverse_complement( seq )
            seq_RCs.append( seq_RC )
    return ( tags, seqs, seq_RCs )
