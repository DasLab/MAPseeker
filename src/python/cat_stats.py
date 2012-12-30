#!/usr/bin/python

import sys
import string
from os import system,popen
from os.path import basename, abspath, dirname
from glob import glob

outdirs = sys.argv[1:]

scripts_path = dirname( abspath( sys.argv[0] ) )

which_files_to_cat = {}

for outdir in outdirs:

    globfiles = glob( outdir+'/*/stats*txt' )

    basenames = map( lambda x:basename(x), globfiles )
    basenames = set( basenames )

    print basenames

    for basename in basenames:
        globfiles = glob( outdir+'/*/'+basename )
        N = []
        for file in globfiles: # probably could use pickle or something.
            lines = open( file ).readlines()
            for i in range( len( lines ) ):
                line = lines[i]
                cols = string.split( line )
                if len( N ) <= i:
                    zero_vector = []
                    if len( zero_vector ) == 0:
                        for col in cols: zero_vector.append( 0.0 )
                    N.append( zero_vector )
                for m in range(len(cols)):
                    k = float(cols[m])
                    N[i][m] += k

        final_file = outdir+'/'+basename
        fid = open( final_file, 'w' )
        for row in N:
            for m in row: fid.write( '%8.1f' % m )
            fid.write( '\n' )
        fid.close()
        print 'Created: ', final_file
