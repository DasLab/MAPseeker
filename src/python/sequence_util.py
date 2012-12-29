#!/usr/bin/python

def reverse_complement( seq ):
    rc = { 'A':'T', 'T':'A', 'U':'A', 'C':'G', 'G':'C' }
    seq_out = ''
    for m in seq[::-1]:
        if m not in rc.keys():
            print m, 'is not in nucleic acid alphabet?'
            exit()
        else:
            seq_out += rc[m]
    return seq_out

def reverse_complements( seqs ):
    return   map( lambda x:reverse_complement( x ), seqs )

# super-dumb. Should fix this.
def read_fasta( fasta_file ):
    tags = []
    seqs = []
    lines = open( fasta_file ).readlines()
    for line in lines: # worst fasta reader in the world.
        if line[0] == '>':
            tags.append( line[1:-1] )
            continue
        if len( line ) > 1:
            seq = line[:-1]
            seqs.append( seq )
    return ( tags, seqs )

def write_fasta( tags, seqs, fasta_file ):
    fid = open( fasta_file, 'w' )
    assert( len( tags ) == len( seqs ) )
    for n in range(len(seqs)):
        fid.write( '>%s\n%s\n\n' % (tags[n], seqs[n] ) )
    fid.close()
    return

def RNA2DNA( RNAs ):
    return map( lambda x:x.replace('U','T'), RNAs )

def get_max_length( RNAs ):
    L = 0
    for RNA in RNAs:
        if len( RNA ) > L: L = len(RNA)
    return L

def read_fastq( fastq_file, MAX_READS = 0 ):
    fastq = []
    fid = open( fastq_file )
    line = ' '
    while line:
        line = fid.readline()
        if len( line ) < 1: continue
        if line[0] == '+':
            line = fid.readline()
            continue
        if line[0] == '@': continue # probably should read these tags in...
        fastq.append( line[:-1] )
        if MAX_READS > 0 and len( fastq ) >= MAX_READS: break
    print 'Finished reading: ',fastq_file, '    ',len(fastq),' reads'
    return fastq


