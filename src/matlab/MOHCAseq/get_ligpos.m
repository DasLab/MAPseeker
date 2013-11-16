function ligpos = get_ligpos( r );
ligpos   = str2num( char(get_tag( r, 'lig_pos' )) );
