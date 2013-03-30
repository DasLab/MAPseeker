#!/usr/bin/python

from sys import argv

def Help():
    print
    print argv[0], ' EteRNAfile'
    print
    exit()

if len( argv ) < 2: Help()

ADD_P4P6 = False
if '-addP4P6' in argv: ADD_P4P6 = True

EteRNAfile = argv[1]

outfile1 = 'RNA_sequences.fasta'
outfile2 = 'RNA_structures.fasta'
fid1 = open( outfile1, 'w')
fid2 = open( outfile2, 'w')

# get names of constructs
lines = open( EteRNAfile ).readlines()

if len( lines ) == 1:
    lines = lines[0].split( '\r' )

if ADD_P4P6:
    lines.append( '0\tP4-P6 domain, Tetrahymena ribozyme\t0\tGGCCAAAGGCGUCGAGUAGACGCCAACAACGGAAUUGCGGGAAAGGGGUCAACAGCCGUUCAGUACCAAGUCUCAGGGGAAACUUUGAGAUGGCCUUGCAAAGGGUAUGGUAAUAAGCUGACGGACAUGGUCCUAACCACGCAGCCAAGUCCUAAGUCAACAGAUCUUCUGUUGAUAUGGAUGCAGUUCAAAACCAAACCGUCAGCGAGUAGCUGACAAAAAGAAACAACAACAACAAC\tP4-P6 with double reference hairpin\t.......((((((.....))))))...........((((((...((((((.....(((.((((.(((..(((((((((....)))))))))..((.......))....)))......)))))))....))))))..)).))))((...((((...(((((((((...)))))))))..))))...)).............((((((.....))))))......................\n' )


tag_map = {}
for line in lines:
    cols = line.replace('\n','').split( '\t' );
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
