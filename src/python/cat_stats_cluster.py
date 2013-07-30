#!/usr/bin/python

import sys
import string
from os import system,popen,getcwd
from os.path import basename, abspath, dirname
from glob import glob
from cat_stats_stuff import cat_stats

outdirs = sys.argv[1:]
delete_files = False
if '--delete' in outdirs:
    pos =outdirs.index( '--delete')
    del( outdirs[ pos ] )
    delete_files = True

pwd = getcwd()

scripts_path = dirname( abspath( sys.argv[0] ) )

which_files_to_cat = {}

for outdir in outdirs:

    chdir( outdir )
    globfiles_all = glob( '*/stats*txt' )

    dirnames = map( lambda x:basename(x), globfiles_all )
    cat_stats( dirnames )

    chdir( pwd )

    if ( delete_files ): # remove dirs.
        dirs_to_delete = []
        for file in globfiles_all:
            if not dirname( file ) in dirs_to_delete: dirs_to_delete.append( dirname(file) )
        command = 'rm -rf '+string.join( dirs_to_delete  )
        system( command )

        # clogs up system -- and will affect any future runs...
        command = 'rm -rf dagMAPSEEKER.*'
        system( command )

