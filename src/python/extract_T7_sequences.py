#!/usr/bin/python
from sequence_util import read_fastq, reverse_complement
from sys import argv

fastq_file1 = argv[1]
fastq_file2 = argv[2]

MAX_READS = 10000;
fastq1 = read_fastq( fastq_file1, MAX_READS )
fastq2 = read_fastq( fastq_file2, MAX_READS )

T7promoter = 'TTCTAATACGACTCACTATA';
N = len( T7promoter)

assert( len( fastq1 ) == len( fastq2 ) )

for i in range( len( fastq2 ) ):
    if ( fastq2[ i ][ :N ] == T7promoter ):
        print fastq2[ i ], reverse_complement( fastq1[i] )

