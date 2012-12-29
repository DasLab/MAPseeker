#define SEQAN_PROFILE // enable time measurements
#include <seqan/misc/misc_cmdparser.h>
#include <tr1/unordered_map>
#include <seqan/file.h>
#include <iostream>
#include <seqan/find.h>
#include <seqan/index.h>
#include <seqan/store.h>
#include <seqan/basic.h>
#include <sstream>
#include <string>
#include <stdio.h>

using namespace seqan;
std::string IntToStr( int n )
{
    std::ostringstream result;
    result << n;
    return result.str();
}

// could put following in util file?
void RNA2DNA( String<char> & seq );

// could package into a little class:
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags );

int try_exact_match( CharString & seq1, CharString & cseq, unsigned & perfect );
int try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect );

int try_DP_match_expt_ids( std::vector< CharString > & short_expt_ids, CharString & expt_id_in_read1 );

//The known library of sequences is stored as a StringSet called THaystacks
//We will generate an index against this file to make the search faster
typedef StringSet<CharString> THaystacks;

//A hashmap is used to map the experimental ids to the descriptive labels
typedef std::tr1::unordered_map<std::string, std::string> hashmap;

//Versioning information
inline void
_addVersion(CommandLineParser& parser) {
    ::std::string rev = "$Revision: 0001 $";
    addVersionLine(parser, "Version 1.1 (27 December 2012) Revision: " + rev.substr(11, 4) + "");
}

int main(int argc, const char *argv[]) {
//All command line arguments are parsed using SeqAn's command line parser
    CommandLineParser parser;
    _addVersion(parser);

    addTitleLine(parser, "                                                 ");
    addTitleLine(parser, "*************************************************");
    addTitleLine(parser, "* MAP-Seeker                                    *");
    addTitleLine(parser, "* (c) Copyright 2012, JP Bida, R. Das           *");
    addTitleLine(parser, "* (c) Copyright 2013, R. Das                    *");
    addTitleLine(parser, "*************************************************");
    addTitleLine(parser, "                                                 ");

    addUsageLine(parser, "-c <constant sequence> -1 <miseq output1> -2 <miseq output2> -l <library> -b <experimental barcodes> -n <sequence id length> -d <0/1 output type>");

    addSection(parser, "Main Options:");
    addOption(parser, addArgumentText(CommandLineOption("c", "cseq", "Constant sequence", OptionType::String), "<DNA sequence>"));
    addOption(parser, addArgumentText(CommandLineOption("1", "miseq1", "miseq output [read 1] containing primer ids",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("2", "miseq2", "miseq output [read 2] containing 3' ends",OptionType::String), "<FASTAQ FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("l", "library", "library of sequences to align against", OptionType::String),"<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("b", "barcodes", "fasta file containing experimental barcodes", OptionType::String), "<FASTA FILE>"));
    addOption(parser, addArgumentText(CommandLineOption("o", "outfile", "output filename", (int)OptionType::String, "out.fasta"), "<Filename>"));
    addOption(parser, addArgumentText(CommandLineOption("n", "sid.length", "sequence id length", OptionType::Int), "<Int>"));
    addOption(parser, addArgumentText(CommandLineOption("d", "debug", "full output =1 condensed output=0", OptionType::Int), "<Int>"));
    //    adapterSequence = "";

    if (argc == 1)
    {
        shortHelp(parser, std::cerr);	// print short help and exit
        return 0;
    }

    if (!parse(parser, argc, argv, ::std::cerr)) return 1;
    if (isSetLong(parser, "help") || isSetLong(parser, "version")) return 0;	// print help or version and exit

//This isn't required but shows you how long the processing took
    SEQAN_PROTIMESTART(loadTime);
    std::string file1,file2,file3,file4,outfile;

//cseq is the constant region between the experimental id and the sequence id
//in the Das lab this is the tail2 sequence AAAGAAACAACAACAACAAC
    String<char> cseq="";
    getOptionValueLong(parser, "cseq",cseq);
    getOptionValueLong(parser, "miseq1",file1);
    getOptionValueLong(parser, "miseq2",file2);
    getOptionValueLong(parser, "library",file3);
    getOptionValueLong(parser, "barcodes",file4);
    getOptionValueLong(parser, "outfile",outfile);
    int seqid_length=-1;
    int debug=0;
    getOptionValueLong(parser,"sid.length",seqid_length);
    getOptionValueLong(parser,"debug",debug);

//Opening the output file and returning an error if it can't be opened
    FILE * oFile;
    oFile = fopen(outfile.c_str(),"w");

    MultiSeqFile multiSeqFile1;
    MultiSeqFile multiSeqFile2;
    MultiSeqFile multiSeqFile3;
    MultiSeqFile multiSeqFile4; //barcode patterns
    if (!open(multiSeqFile1.concat, file1.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile2.concat, file2.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile3.concat, file3.c_str(), OPEN_RDONLY) ) return 1;
    if (!open(multiSeqFile4.concat, file4.c_str(), OPEN_RDONLY) ) return 1;
    if (cseq=="" || seqid_length==-1 )  return 1;

//The SeqAn library has a built in file parser that can guess the file format
//we use the AutoSeqFormat option for the MiSeq, Library, and barcode files

    //MiSeq File1
    AutoSeqFormat format1;
    guessFormat(multiSeqFile1.concat, format1);
    split(multiSeqFile1, format1);

    //MiSeq File2
    AutoSeqFormat format2;
    guessFormat(multiSeqFile2.concat, format2);
    split(multiSeqFile2, format2);

    //Library
    AutoSeqFormat format3;
    guessFormat(multiSeqFile3.concat, format3);
    split(multiSeqFile3, format3);

    //Barcodes
    AutoSeqFormat format4;
    guessFormat(multiSeqFile4.concat, format4);
    split(multiSeqFile4, format4);

    std::cout << "Reading un sequence files took: " << SEQAN_PROTIMEDIFF(loadTime) << " seconds." << std::endl;

    if(length(multiSeqFile1)!=length(multiSeqFile2)) {
        std::cout << "MiSeq input files contain different number of sequences" << std::endl;
        return 1;
    } else {
        std::cout << "Total Pairs: " << length(multiSeqFile1) << ":" << length(multiSeqFile2) << std::endl;
    }

//Getting the total number of sequences in each of the files
//The two MiSeq files should match in the number of sequences
//They should also be in the same order
    unsigned seqCount1 = length(multiSeqFile1);
    unsigned seqCount3 = length(multiSeqFile3);
    unsigned seqCount4 = length(multiSeqFile4);
    int unmatchedtail=0;
    int unmatchedlib=0;

// FRAGMENT(read_sequences)
    String<char> seq1;
    String<char> seq1id;
    String<char> seq2;
    String<char> seq3;
    String<char> seq3id;
    String<char> seq4;
    String<char> seq4id;
    CharString qual1;
    CharString qual2;
    CharString id1;
    CharString id2;
    THaystacks haystacks_rna_library, haystacks_expt_ids;

    std::cout << "Getting " << seqCount4 << " Barcodes.. " << std::endl;

    hashmap idmap;
    std::vector<int> eidlen;
    int max_eidlen=0;

    std::vector< String<char> > full_expt_ids, short_expt_ids;
    ///////////////////////////////////////////////////
    // create a haystack to search with barcodes.
    ///////////////////////////////////////////////////
    for(unsigned j=0; j< seqCount4; j++) {
      assignSeqId(seq4id, multiSeqFile4[j], format4);    // read sequence
      assignSeq(seq4, multiSeqFile4[j], format4);    // read sequence

      // following may not be use any more...
      String< char > full_expt_id = cseq;
      append( full_expt_id, seq4 ); // later directly read in primers...
      std::cout << "PRIMER SEQUENCE WITH ID: " << full_expt_id << std::endl;
      full_expt_ids.push_back( full_expt_id );

      short_expt_ids.push_back( seq4 );
      appendValue(haystacks_expt_ids, seq4 );
    }
    //    Index<THaystacks> index_expt_ids(haystacks_expt_ids);
    Finder<Index<THaystacks> > finder_expt_id(haystacks_expt_ids);

    //If barcodes are of different lengths print the lengths here
    std::cout << "Barcode Lengths(max=" << max_eidlen <<"):" << std::endl;
    for(int i=0; i<eidlen.size(); i++) {
        std::cout << "length: " << eidlen[i] << std::endl;
    }

// Index library sequences for alignment
    unsigned max_rna_len( 0 );
    std::cout << "Indexing Sequences(N=" << seqCount3 << ")..";
    for(unsigned j=0; j< seqCount3; j++) {
        assignSeq(seq3, multiSeqFile3[j], format3);    // read sequence
	RNA2DNA( seq3 );
        appendValue(haystacks_rna_library, seq3);
	if ( max_rna_len < length( seq3 ) ) max_rna_len = length( seq3 );
    }
    //    Index<THaystacks> index(haystacks_rna_library);
    Finder<Index<THaystacks> > finder_sequence_id( haystacks_rna_library );
    std::cout << "completed" << std::endl;
    std::cout << "RNA sequence Lengths(max=" << max_rna_len <<"):" << std::endl;

    // initialize a histogram recording the counts [convenient for plotting in matlab, R, etc.]
    std::vector< unsigned > sequence_counts( max_rna_len,0);
    std::vector< std::vector< unsigned > > bunch_of_sequence_counts( seqCount3+1, sequence_counts);
    std::vector< std::vector< std::vector < unsigned > > > all_count( seqCount4, bunch_of_sequence_counts);

    // keep track of how many sequences pass through each filter
    std::vector< unsigned > counter_counts;
    std::vector< std::string > counter_tags;
    unsigned perfect=0;

    std::cout << "Running alignment" << std::endl;

    SEQAN_PROTIMESTART(alignTime); // reset counter.
    if ( debug) std::cout << "Output should be appearing in " << outfile.c_str() << std::endl;

    for (unsigned i = 0; i < seqCount1; ++i)
    {

      ////////////////////////////////////////////////////////////////
      // Get the next forward and reverse read...
      ////////////////////////////////////////////////////////////////
      assignSeq(seq1, multiSeqFile1[i], format1);    // read sequence
      assignQual(qual1, multiSeqFile1[i], format1);  // read ascii quality values
      assignSeqId(id1, multiSeqFile1[i], format1);   // read sequence id

      assignSeq(seq2, multiSeqFile2[i], format2);    // read sequence
      assignQual(qual2, multiSeqFile2[i], format2);  // read ascii quality values
      assignSeqId(id2, multiSeqFile2[i], format2);   // read sequence id

      reverseComplement(seq1);

      unsigned counter_idx( 0 ); // will keep track of which filter we pass.
      record_counter( "total", counter_idx, counter_counts, counter_tags );

      ////////////////////////////////////////////////////////////////
      ////////////////////////////////////////////////////////////////
      int pos1( -1 ), constant_sequence_begin_pos( -1 ), expt_idx( -1 );

      ///////////////////////////////////////////////////////////////////////////////////////////
      // Look for the constant region (primer binding site) -- JP's trick.
      // In future could do multi-pattern search for multiple primers ... in that
      // case, we'll have to rewrite this code unfortunately.
      ///////////////////////////////////////////////////////////////////////////////////////////
      //pos1 = try_exact_match( seq1, cseq, perfect );  //  interesting -- DPsearch (see next) is no slower than available exact matches.
      if ( pos1 < 0 ) pos1 = try_DP_match( seq1, cseq, perfect ); // allows for 2 mismatches

      if ( pos1 < 0 ) continue;
      record_counter( "found primer binding site", counter_idx, counter_counts, counter_tags );

      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // Look for experimental ID (expt ID that follows constant primer binding site, and is coded by reverse transcription primer)
      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      // first look for exact match -- should be super-fast, as using index.
      String<char> expt_id_in_read1 = suffix(seq1,(pos1+1));
      if ( find( finder_expt_id, expt_id_in_read1 ) )	expt_idx = beginPosition(finder_expt_id).i1;
      clear( finder_expt_id );

      if ( expt_idx < 0) expt_idx = try_DP_match_expt_ids( short_expt_ids, expt_id_in_read1 );

      // this avoids findBegin, but assumes no indels in constant primer binding sequence
      if ( constant_sequence_begin_pos < 0 ) constant_sequence_begin_pos = pos1 - length( cseq);

      if( expt_idx < 0 ) continue;
      record_counter( "found expt ID site", counter_idx, counter_counts, counter_tags );

      ////////////////////////////////////////////////////////////////////////////////////////
      // Look for the sequence ID (i.e., the identifier sequence at the 3' end of the RNA)
      // in a region of seqid nucleotides before the constant (primer-binding) site.
      // seqid is the (minimum) length of the barcode...
      ////////////////////////////////////////////////////////////////////////////////////////
      int min_pos = constant_sequence_begin_pos - seqid_length + 1;
      if (min_pos < 0)	 min_pos=0;
      String<char> sequence_id_region_in_sequence1=infixWithLength(seq1,min_pos,seqid_length);
      // We append the primer binding site to make sure that the search will be over actual barcode regions (adjoining the constant sequence) from the RNA library.
      append(sequence_id_region_in_sequence1,cseq);


      Pattern<CharString> pattern_sequence_id_in_read1(sequence_id_region_in_sequence1); // this is now the 'needle' -- look for this sequence in the haystack of potential sequence IDs

      // crap, cannot handle inexact matches off indexed library... may want to try DP instead?
      //Pattern<String<char>, MyersUkkonen > pattern_sequence_id_in_read1( sequence_id_region_in_sequence1 );
      //setScoreLimit( pattern_sequence_id_in_read1, 0);

      if( find(finder_sequence_id, pattern_sequence_id_in_read1)) { // wait, shouldn't we try *all* possibilities?
	// seq3 contains the RNA library sequences
	int sid_idx = beginPosition(finder_sequence_id).i1;

	// what is the DNA?
	assignSeq(seq3, multiSeqFile3[sid_idx], format3); // read sequence of the RNA
	append( seq3, short_expt_ids[ expt_idx ] ); // experimental ID, added  in MAP-seq protocol as part of reverse transcription primer
	append( seq3, adapterSequence ); // piece of illumina DNA, added in MAP-seq protocol as part of reverse transcription primer

	//	assignSeqId(seq3id,multiSeqFile3[sid_idx], format3); // read the ID of the RNA -- is this used anymore?

	record_counter( "found RNA sequence", counter_idx, counter_counts, counter_tags );

	////////////////////////////////////////////////////////////////////////////////////////
	// Look for the second read to determine where the reverse transcription stop is.
	////////////////////////////////////////////////////////////////////////////////////////
	RNA2DNA( seq3 );
	Finder<String<char> > finder_in_specific_sequence(seq3);

	Pattern<String<char>, MyersUkkonen> pattern_sequence2(seq2);

	// Switch following to DP? would be more forgiving to indels.
	// also, would be good to use Quality information -- MAQ style.
	int const EDIT_DISTANCE_SCORE_CUTOFF = -2;
	setScoreLimit(pattern_sequence2, EDIT_DISTANCE_SCORE_CUTOFF);//Edit Distance used to be -10! not very stringent.

	int mpos( -1), mscr( EDIT_DISTANCE_SCORE_CUTOFF - 1 );

	// Here, looking for best score -- but assuming that we've nailed the right RNA sequence (which may not be the case).
	while (find(finder_in_specific_sequence, pattern_sequence2)) {
	  int cscr=getScore(pattern_sequence2);

	  if(cscr > mscr) {
	    mscr=cscr;
	    mpos=position( finder_in_specific_sequence ); //end position. Or do I want begin position?
	  }

	}

	if (mpos < 0) continue;
	record_counter( "found match in sequence", counter_idx, counter_counts, counter_tags );

	mpos=mpos - length(seq2); // what?

	if(debug==1) {
	  //	    fprintf(oFile,"%s,%s,%s,%s,%d,%d,%s,%s\n",toCString(id1),toCString(id2),edescr.c_str(),toCString(seq3id),(mpos+1),mscr,toCString(seq2),toCString(seq3));
	}
	else {
	  // need to replace this with a histogram... or save a vector of information (perhaps with weights?) that we histogram below.
	  //fprintf(oFile,"%s,%s,%d,%d\n",edescr.c_str(),toCString(seq3id),(mpos+1),mscr);
	  if ( mpos < -1 ) mpos = -1;
	  all_count[ expt_idx ][ sid_idx ][ mpos+1 ]++;
	}

      } else {
	unmatchedlib++;
	//fprintf(uFile,"%s,%s,%d,%d,%s,%s\n",mid,uid,seq1id);
      }
      clear(finder_sequence_id);

    }
    std::cout << "Aligning " << seqCount1 << " sequences took " << SEQAN_PROTIMEDIFF(alignTime);
    std::cout << " seconds." << std::endl << std::endl;
    std::cout << "Total Sequence Pairs: " << length(multiSeqFile1) << std::endl;
    std::cout << "Perfect constant sequence matches: " << perfect << std::endl;
    std::cout << "Unmatched Lib: " << unmatchedlib << std::endl;

    std::cout << std::endl;
    std::cout << "Purification table" << std::endl;
    for ( unsigned i = 0; i < counter_counts.size(); i++ ){
      std::cout << counter_counts[i] << " " << counter_tags[i] << std::endl;
    }
    std::cout << std::endl;

    //////////////////////////////////////////////////////
    //  output matrices with stored counts.
    //////////////////////////////////////////////////////
    for ( unsigned i = 0; i < seqCount4; i++ ){
      char stats_outFileName[ 50 ];
      sprintf( stats_outFileName, "stats_ID%d.txt", i+1 ); // index by 1.
      std::cout << "Outputting counts to: " << stats_outFileName << std::endl;
      FILE * stats_oFile;
      stats_oFile = fopen( stats_outFileName,"w");
      for ( unsigned j = 0; j < seqCount3; j++ ){
    	for ( unsigned k = 0; k < max_rna_len; k++ ){
    	  fprintf( stats_oFile, " %d", all_count[i][j][k] );
    	}
    	fprintf( stats_oFile, "\n");
      }
      fclose( stats_oFile );
    }

    return 0;
}

/////////////////////////////////////
void RNA2DNA( String<char> & seq ){
 seqan::Iterator<seqan::String<char> >::Type it = begin(seq);
 seqan::Iterator<seqan::String<char> >::Type itEnd = end(seq);

 while (it != itEnd) {
   if (*it == 'U') *it = 'T';
   ++it;
 }
}

/////////////////////////////////////
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags ){

  if (counter_idx >= counter_tags.size() ) {
    counter_tags.push_back( tag );
    counter_counts.push_back( 0 );
  }
  counter_counts[ counter_idx ]++;
  counter_idx++;
  //  std::cout << "counter_idx: " << counter_idx << std::endl;
}


/////////////////////////////////////////////////////////////////////////////
int
try_exact_match( CharString & seq1, CharString & cseq, unsigned & perfect ){

  int pos1( -1 );

  // try exact match with indexing
  // indexed is slow [though this might be fast if I index everything at once...]
  //Index<CharString> index( seq1 );
  //	Finder< Index<CharString> > finder( index );
  //	if ( find( finder, cseq ) ) pos1 = position( finder );

  Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
  Pattern<String<char>, Horspool > pattern_constant_sequence( cseq );
  if( find(finder_constant_sequence, pattern_constant_sequence) ) pos1 = position( finder_constant_sequence );

  if (pos1 > -1 ) perfect++;

  return pos1; // no position found
}



/////////////////////////////////////////////////////////////////////////////
int
try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect ){

  int pos1( -1 );

  Finder<String<char> > finder_constant_sequence(seq1); // this is what to search.
  //Set options for gap, mismatch,deletion
  int score_cutoff( -2 ), best_score( score_cutoff-1 );
  Pattern<String<char>, DPSearch<SimpleScore> > pattern_constant_sequence_DP(cseq,SimpleScore(0, -2, -1));

  // Find best match in case there are several.
  while( find(finder_constant_sequence, pattern_constant_sequence_DP, score_cutoff)) {
    if(getScore(pattern_constant_sequence_DP) > best_score) {
      best_score=getScore(pattern_constant_sequence_DP);
      pos1=position(finder_constant_sequence);

      if ( best_score == 0 ) break; // early exit if we have an exact match already.
      // go to beginning of primer binding site
      // following is slow, and compared to simply decrementing by the length of the primer binding site (assume no indel),
      //  only adds ~1% to number of reads discovered.
      // findBegin( finder_constant_sequence, pattern_constant_sequence, best_score );
      // constant_sequence_begin_pos = beginPosition( finder_constant_sequence ) - 1;
    }
  }

  if( best_score == 0 ) perfect++;

  return pos1;
}

///////////////////////////////////////////////////////////////////////////////
int
try_DP_match_expt_ids( std::vector< CharString > & short_expt_ids, CharString & expt_id_in_read1 ){

  // use DP to allow mismatches
  int score_cutoff( -2 ), best_score( score_cutoff-1 ), expt_idx( -1 );
  for ( unsigned n = 0; n < short_expt_ids.size(); n++ ){

    Finder<String<char> > finder_one_expt_id( expt_id_in_read1 );

    // could we save some time by preconstructing patterns?
    String<char> & ndl = short_expt_ids[n]; // this is the needle. const doesn't seem to work.
    //Set options for gap, mismatch, deletion. Again, should make these variables.
    Pattern<String<char>, DPSearch<SimpleScore> > pattern_expt_id(ndl,SimpleScore(0, -2, -1));

    best_score = score_cutoff - 1;

    while ( find( finder_one_expt_id, pattern_expt_id, score_cutoff )) { // shoud set score cutoff (-2) to be a variable.
      // for now assume no ties are possible -- perhaps in future output warning, or discard ambiguous.
      int score = getScore( pattern_expt_id );
      if ( score >= best_score) {
	best_score = score;
	// slow  -- see note on findBegin in try_DP_match()
	//  while( findBegin( finder_expt_id, pattern_expt_id, score ) ){
	//    constant_sequence_begin_pos = beginPosition(finder_expt_id) - 1;
	//  }
	expt_idx = n;
      }
      if ( score == 0 ) break; // best possible score.
    }
  }

  return expt_idx;
}

