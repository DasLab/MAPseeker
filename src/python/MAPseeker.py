#!/usr/bin/python

from optparse import OptionParser
from sequence_util import reverse_complement, reverse_complements, read_fasta, RNA2DNA, get_max_length, read_fastq


parser = OptionParser()
parser.add_option( "-1", dest="fastq_file1", default='PhiX_S1_L001_R1_001.fastq')
parser.add_option( "-2", dest="fastq_file2", default='PhiX_S1_L001_R2_001.fastq')
parser.add_option( "-r", "--rna", dest="rna_fasta_file", default="RNA_sequences.fasta")
parser.add_option( "-a", "--adapter", dest="adapter_sequence_file", default="AdapterSequence.fasta")
parser.add_option( "-p", "--primers", dest="primer_fasta_file", default="primers.fasta")
parser.add_option( "-N", "--MAX_READS", dest="MAX_READS", default=0,type="int")
( options, args ) = parser.parse_args()

RNA_fasta_file = options.rna_fasta_file
AdapterSequenceFile = options.adapter_sequence_file
fastq_file1 = options.fastq_file1
fastq_file2 = options.fastq_file2
primer_fasta_file = options.primer_fasta_file
MAX_READS = options.MAX_READS

# this is confusing -- this is the 'internal barcode' at the 3' end of the RNA.
# last block should specify primer site (will act as filter sequence!)
barcode_lengths = [7,4,8,20]

######################################
# read in RNA sequences
(tags, RNAs )  = read_fasta( RNA_fasta_file )
RNAs_RC = reverse_complements( RNAs )
DNAs = RNA2DNA( RNAs )
L = get_max_length( RNAs )

# Need to know adapter sequence, since it will get ligated right before ID code in RTB000, etc.
(tags,seqs) = read_fasta( AdapterSequenceFile )
AdapterSequence = seqs[0]


# Read in primer sequences
(tags_primer, primers ) = read_fasta( primer_fasta_file )

# decompose primer sequences into
# Adapter, ID (the primer's barcode, usually indexing the solution condition or modifier), and then the RT primer.
# assume actual priming portion is shared in all cases! n will be the primer 'boundary'
found_distinct = 0
for n in range( 1,len( AdapterSequence )):
    primer_nt = ''
    for primer in primers:
        if len(primer_nt) == 0:  primer_nt = primer[ -n ]
        if primer[ -n ] != primer_nt:
            found_distinct = 1
            break
    if found_distinct: break
assert( found_distinct )
n = n-1 # it was the previous one that was the last shared site
print 'Shared primer site is this many nucleotides: ', n

IDs = []
for primer in primers:
    assert( primer.find( AdapterSequence ) > -1 )
    ID = primer.replace( AdapterSequence, '' )
    ID = ID[:(-n)]
    IDs.append( ID )

print 'Primer IDs: ', IDs
IDs_RC = reverse_complements( IDs )

# assume fixed length for now -- later come up with a clever scheme
# to test other IDs.
ID_length = get_max_length( IDs )
print 'ID_length: ',  ID_length

##########################################################
# make lists of unique tags at each barcode position.
# go ahead and use the reverse complement, since that's
# what comes out of current MAP-seq protocol
#

offset = 1

# at each position 'block', make list of unique sequences
barcode_sets = []
barcode_set_dicts = []

# how to get from each barcode index back to an actual RNA sequence (may be degenerate, so this contains lists of indexes)
barcode_mappings = []

barcode_starts = []
barcode_stops = []
for m in barcode_lengths[::-1]:

    barcode_start = offset
    barcode_stop  = offset + m - 1

    barcode_starts.append( barcode_start )
    barcode_stops.append( barcode_stop )

    barcode_set = []
    barcode_set_dict = {}
    barcode_mapping = []

    for i in range( len( RNAs_RC) ):
        seq = RNAs_RC[i]

        barcode = seq[ barcode_start-1: barcode_stop]

        if barcode not in barcode_set:
            barcode_set.append( barcode )

        n = barcode_set.index( barcode )

        barcode_set_dict[ barcode ] = n+1

        if len( barcode_mapping ) < len( barcode_set ):
            #print len( barcode_mapping ), len( barcode_set )
            barcode_mapping.append( [] )
            assert( len( barcode_mapping ) == len( barcode_set ) )

        # when recording sequence number, use 1-indexed numbering
        barcode_mapping[ n ].append( i+1 )

    barcode_sets.append( barcode_set )
    barcode_set_dicts.append( barcode_set_dict )
    barcode_mappings.append( barcode_mapping )

    offset += m

#for i in range( len( barcode_sets ) ):    print barcode_sets[i][0], len( barcode_sets[i][0] ), len( barcode_sets[i] )

print 'Done parsing RNA sequences and figuring out RNA barcodes'

# was testing to see what craziness there was... 1000116-1, 1000123-1
#  may not have worked... ordering error based on expert sequences not
# being formatted correctly -- both are Aaron Coey's sequences.
# ['GTTGTTGTTGTTGTTTCTTTT', 'GTTGTTGTTGTTGTTTTTTTT', 'GTTGTTGTTGTTGTTTGGCGG']
#print tags[ barcode_mappings[0][1][0] ]


# Good, time to read fastq files
fastq1 = read_fastq( fastq_file1, MAX_READS )
fastq2 = read_fastq( fastq_file2, MAX_READS )

# testing code speed-up
barcode_sets_unordered = map( lambda x:set(x), barcode_sets )

# assume fastq1 contains 'reverse' reads with IDs and tail2
#

# perhaps this should be the inner loop -- look for any match as an 'anchor', then work our way out. would also be robust to frameshifts.

# might be much faster to use reg exp? or some hash map trick?
def get_sequence_distance( seq1, seq2, CUTOFF ):
    seqdist = 0
    #assert( len( seq1 ) == len( seq2 ) )
    for (n,c) in enumerate( seq1 ):
        seqdist +=  ( c != seq2[n] )
        if ( seqdist > CUTOFF ): break
    return seqdist

def get_idx( seqblock, seq_set, seq_set_unordered):
    idx = 0
    if ( seqblock in seq_set_unordered ):
        idx = seq_set.index( seqblock ) + 1
    return idx

# use dicts for speed? didn't help...
def get_idx_from_dict( seqblock, seq_set_dict, seq_set_unordered ):
    idx = 0
    if ( seqblock in seq_set_unordered ):
        idx = seq_set_dict[ seqblock ]
    return idx

def get_barcode_idx( x, i, offset ):
    barcode_set     = barcode_sets[ i ]
    barcode_set_unordered     = barcode_sets_unordered[ i ]
    barcode_set_dict= barcode_set_dicts[ i ]
    barcode_start   = barcode_starts[ i ] + offset
    barcode_stop    = barcode_stops[ i ]  + offset
    barcode_mapping = barcode_mappings[ i ]

    seqblock = x[barcode_start-1:barcode_stop]

    #idx = get_idx( seqblock, barcode_set, barcode_set_unordered )
    idx = get_idx_from_dict( seqblock, barcode_set_dict, barcode_set_unordered )

    possible_sequences = []
    if ( idx > 0 ): possible_sequences = barcode_mapping[ idx-1 ]

    return (idx, possible_sequences,seqblock)

counter_tags = []
def record_count( counter, num_sequences, tag):
    if counter >= len( num_sequences ):
        num_sequences.append( 0 )
        counter_tags.append( tag )

    num_sequences[ counter ] += 1
    counter += 1

    return counter

ID_MATCH_CUTOFF = 2
SEQ2_MATCH_CUTOFF = 4

num_sequences = []
RNA_matches = []

########################################################
for m in range( len( fastq1) ):

    seq1 = fastq1[m]

    counter = 0
    counter = record_count( counter, num_sequences, 'total')

    # primer binding site -- better be there!
    ( idx, possible_sequences, seqblock ) = get_barcode_idx( seq1, 0, ID_length )
    if ( idx == 0 ): continue  # nothing there.
    counter = record_count( counter, num_sequences, 'primer binding site')

    # ID block ('barcodes' like RTB000, RTB001, etc.)
    seqblock = seq1[:ID_length]
    ID_matches = []
    for i in range( len( IDs ) ):
        seqdist = get_sequence_distance( seqblock, IDs[i], ID_MATCH_CUTOFF )
        ID_matches.append( [seqdist, i+1] )

    ID_matches.sort()
    ID_idx = ID_matches[0][1]
    seqdist = ID_matches[0][0]

    if ( seqdist > ID_MATCH_CUTOFF ):
        #print 'Problem? ', IDs[ ID_idx-1 ], ' has ',seqdist,' mismatches'
        continue
    counter = record_count( counter, num_sequences, 'Primer ID match')

    # Now look for match to barcode.
    # Again, this could be far more robust, allowing for at least one
    #  mismatch, for example.
    ( idx, possible_sequences, seqblock ) = get_barcode_idx( seq1, 1, ID_length )
    ( idx_alt, possible_sequences_alt, seqblock_alt ) = get_barcode_idx( seq1, 3, ID_length )
    possible_sequences = possible_sequences + possible_sequences_alt

    if len( possible_sequences ) == 0:  continue
    counter = record_count( counter, num_sequences, 'RNA barcode match')

    #possible_sequences = set( possible_sequences ) # just keep unique ones.
    possible_sequences.reverse() # this is a silly hack to get therm1, which shares a barcode with one of the eterna player project libraries -- oops.

    # now need to figure out where the RT stopped.
    seq2 = fastq2[m]

    seqblock_best = 0
    seqdist_best = len( seq2 )
    RTstop_idx_all = []
    for RNA_idx in possible_sequences:
        # what's the sequence, including primer and ID site?
        DNA_sequence = DNAs[ RNA_idx-1 ] + IDs_RC[ ID_idx-1 ] + reverse_complement( AdapterSequence )

        # this will be slow (brute force) -- will it be rate limiting?
        RTstop_matches = []
        for n in range( len( DNA_sequence ) - len(seq2) ):
            seqblock = DNA_sequence[ n:n+len(seq2) ]
            seqdist = get_sequence_distance( seqblock, seq2, SEQ2_MATCH_CUTOFF )
            RTstop_matches.append( [seqdist, n] )
        RTstop_matches.sort()
        RTstop_idx = RTstop_matches[0][1]
        seqdist    = RTstop_matches[0][0]

        # what if there are a bunch of positions with this seqdist? best to distribute uniformly, right?

        if ( seqdist > SEQ2_MATCH_CUTOFF ):
            if (seqdist < seqdist_best ):
                seqdist_best = seqdist
                n = RTstop_idx
                seqblock_best = DNA_sequence[ n:n+len(seq2) ]
                continue #  not considered a match
        else:
            #n = RTstop_idx
            #seqblock = DNA_sequence[ n:n+len(seq2) ]
            #print 'Match: ', seq2, '  to ', seqblock, ' with dist: ', seqdist
            for n in range( len( RTstop_matches ) ):
                if ( RTstop_matches[n][0] > seqdist ): break
                RTstop_idx_all.append( RTstop_matches[n][1] )
            break

    if len( RTstop_idx_all ) == 0:
        #print 'No match: ', seq2, ' has ',seqdist_best,' mismatches to',seqblock_best
        continue

    counter = record_count( counter, num_sequences, 'Found RT stop match')

    weight = 1.0 / len( RTstop_idx_all )
    for RTstop_idx in RTstop_idx_all:
        RNA_matches.append( [ ID_idx, RNA_idx, RTstop_idx, weight ] )

#print RNA_matches

print
print 'Purification table:'
for i in range( len( num_sequences ) ):
    print '%8d %s' % (num_sequences[i], counter_tags[i])


stats = []
ID_total = []
for n in range( len( IDs ) ):
    stats.append( [] )
    ID_total.append( 0 )
    for m in range( len( RNAs ) ):
        stats[n].append( [] )
        for q in range( L+1 ):
            stats[n][m].append( 0.0 )

for i in range( len( RNA_matches ) ):

    RNA_match = RNA_matches[i]
    ID_idx     = RNA_match[0]
    RNA_idx    = RNA_match[1]
    RTstop_idx = RNA_match[2]
    weight     = RNA_match[3]

    if RNA_match[0] == 0 or RNA_match[0] > len(stats):
        print 'Problem in ID idx ', RNA_match[0], len(stats)
        continue
    if RNA_match[1] == 0 or RNA_match[1] > len(stats[ RNA_match[0]-1 ]):
        print 'Problem in RNA idx ', RNA_match[1], len(stats[ RNA_match[0]-1 ])
        continue
    if RNA_match[2] < 0 or RNA_match[2] >= len(stats[ RNA_match[0]-1 ][ RNA_match[1]-1 ]):
        print 'Problem in stop idx ', RNA_match[2], len(stats[ RNA_match[0]-1 ][ RNA_match[1]-1 ])
        continue

    stats[ ID_idx-1 ][ RNA_idx-1 ][ RTstop_idx ] += weight
    ID_total[ ID_idx-1 ] += weight

print
print "ID breakdown"
for n in range( len( IDs ) ):
    print  "%7d %s" % ( ID_total[n], tags_primer[n] )

print

for n in range( len( IDs ) ):

    filename = 'stats_ID%d.txt' % (n+1)
    fid = open( filename, 'w' )

    for m in range( len( RNAs ) ):
        for q in range( L+1 ):
            fid.write( '%8.1f' % stats[n][m][q] )
        fid.write( '\n' )
    fid.close()
    print 'Output: ', filename
