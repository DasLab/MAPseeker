#!/usr/bin/python

from sys import argv

OligoOrder_file = 'Agilent_unique_eterna_short_sequences.txt'
More_info_file = 'unique_eterna_short_sequences.txt'

# silly flag to add "therm1" control sequence. probably should generalize this.
ADD_THERM1 = False
if "-add_therm1" in argv:
    pos = argv.index( "-add_therm1" )
    del( argv[ pos ] )
    ADD_THERM1 = True

if len( argv ) > 1:
    OligoOrder_file = argv[1]

if len( argv ) > 2:
    More_info_file = argv[2]

# get names of constructs
lines = open(More_info_file ).readlines()
tag_map = {}
for line in lines:
    cols = line[:-1].split( '\t' );
    tag_map[ cols[0] ] = cols[1]+'\t'+cols[4]

outfile = 'RNA_sequences.fasta'
fid = open( outfile, 'w')

lines = open( OligoOrder_file ).readlines()
for line in lines:
    cols = line[:-1].split()
    fid.write(  '> '+cols[0]+'\t'+tag_map[ cols[0][:-2] ]+'\n' )
    sequence = cols[1].replace('T','U').replace(' ','') + 'AAACAACAACAACAAC'
    fid.write( sequence+'\n\n')

# Add therm1
if ADD_THERM1:
    fid.write(  '> 999999\ttherm1\tcontrol\n' )
    fid.write( 'GGAAAAUAUUAAUUCUUUAAUAAAAACTATCCGTTCGCGGATAGAAAAGAAACAACAACAACAAC\n\n'.replace('T','U') )

fid.close()


print 'Created: ', outfile
