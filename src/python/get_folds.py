#!/usr/bin/python

from os import system
from sys import argv

def Help():
    print argv[0]+' <input fasta file> [<output fasta file with Vienna structures>]'
    print
    exit()

if len( argv)<2:
    Help()

RNA_fasta_file = argv[1]

outfile = 'RNA_structures.fasta'
if len( argv ) > 2:
    outfile = argv[2]

command = 'RNAfold < %s > %s' % ( RNA_fasta_file, outfile )
print( command )
system( command )

command = 'rm *ss.ps'
print command
system( command )

print "Created", outfile
