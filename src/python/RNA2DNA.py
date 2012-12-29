#!/usr/bin/python

from sequence_util import RNA2DNA,read_fasta,write_fasta
from sys import argv

fasta_file = argv[1]
( tags, seqs ) = read_fasta( fasta_file )
seqs_DNA = RNA2DNA( seqs )
write_fasta( tags, seqs_DNA, fasta_file.replace( '.fasta','_DNA.fasta') )
