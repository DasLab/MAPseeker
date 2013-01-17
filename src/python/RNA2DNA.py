#!/usr/bin/python

from sequence_util import RNA2DNA,read_fasta,write_fasta
from sys import argv

def Help():
    argv[0] + " <fasta file with RNA sequences>  [-add_T7] "

if len( argv ) < 0:
    Help()

ADD_T7_PROMOTER = False
if ( "-add_T7" in argv ):
    pos = argv.index( "-add_T7" )
    del( argv[ pos ] )
    ADD_T7_PROMOTER = True
    print "Will prepend T7 promoter sequence"

fasta_file = argv[1]
( tags, seqs ) = read_fasta( fasta_file )

if ADD_T7_PROMOTER:
    seqs = map( lambda x: "TTCTAATACGACTCACTATA"+x, seqs )

seqs_DNA = RNA2DNA( seqs )
outfile = fasta_file.replace( '.fasta','_DNA.fasta')
write_fasta( tags, seqs_DNA, outfile )
print "Created: ", outfile
