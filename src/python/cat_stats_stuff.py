#!/usr/bin/python

import sys
import string
from os import system,popen
from os.path import basename, abspath, dirname
from glob import glob


def cat_stats( dirnames ):

    globfiles_all = []
    for dirname in dirnames:
        globfiles_all = globfiles_all + glob( dirname + '/stats*.txt' )

    basenames = map( lambda x:basename(x), globfiles_all )
    basenames = set( basenames )

    print basenames

    for filename in basenames:

        globfiles = []
        for dirname in dirnames:
            globfiles = globfiles + glob( dirname + '/'+filename )

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

        final_file = filename
        fid = open( final_file, 'w' )
        for row in N:
            for m in row: fid.write( '%11.4f' % m )
            fid.write( '\n' )
        fid.close()

        print 'Created: ', basename(final_file)

