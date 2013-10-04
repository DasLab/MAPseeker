function values = get_tag_from_string( header_string, tag );;

values = get_tag( split_string( header_string, sprintf('\t') ), tag );

