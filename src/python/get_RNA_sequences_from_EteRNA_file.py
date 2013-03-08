#!/usr/bin/python

from sys import argv

def Help():
    print
    print argv[0], ' EteRNAfile'
    print
    exit()

if len( argv ) < 2: Help()

EteRNAfile = argv[1]

outfile1 = 'RNA_sequences.fasta'
outfile2 = 'RNA_structures.fasta'
fid1 = open( outfile1, 'w')
fid2 = open( outfile2, 'w')

# get names of constructs
lines = open( EteRNAfile ).readlines()
tag_map = {}
for line in lines:
    cols = line[:-1].split( '\t' );
    header = '> '+cols[0]+'\t'+ cols[1] + '\t' + cols[4]
    sequence = cols[3]
    structure = cols[5]

    fid1.write( header+'\n')
    fid1.write( sequence+'\n\n')

    fid2.write( header+'\n')
    fid2.write( sequence+'\n')
    fid2.write( structure+'\n\n')

fid1.close()
fid2.close()


print 'Created: ', outfile1
print 'Created: ', outfile2
