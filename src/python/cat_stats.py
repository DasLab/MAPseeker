#!/usr/bin/python

import sys
import string
from os import system,popen
from os.path import basename, abspath, dirname
from glob import glob

outdirs = sys.argv[1:]
delete_files = False
if '--delete' in outdirs:
    pos =outdirs.index( '--delete')
    del( outdirs[ pos ] )
    delete_files = True

scripts_path = dirname( abspath( sys.argv[0] ) )

which_files_to_cat = {}

for outdir in outdirs:

    globfiles_all = glob( outdir+'/*/stats*txt' )

    basenames = map( lambda x:basename(x), globfiles_all )
    basenames = set( basenames )

    print basenames

    for filename in basenames:
        globfiles = glob( outdir+'/*/'+filename )
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

        final_file = outdir+'/'+filename
        fid = open( final_file, 'w' )
        for row in N:
            for m in row: fid.write( '%11.4f' % m )
            fid.write( '\n' )
        fid.close()

        system( 'cp %s ./' % final_file )
        print 'Created: ', basename(final_file)

    if ( delete_files ): # remove dirs.
        dirs_to_delete = []
        for file in globfiles_all:
            if not dirname( file ) in dirs_to_delete: dirs_to_delete.append( dirname(file) )
        command = 'rm -rf '+string.join( dirs_to_delete  )
        system( command )

        # clogs up system -- and will affect any future runs...
        command = 'rm -rf dagMAPSEEKER.*'
        system( command )

