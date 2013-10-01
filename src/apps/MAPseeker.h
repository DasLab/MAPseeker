#include <seqan/find.h>
#include <seqan/find.h>
#include <seqan/index.h>
#include <seqan/store.h>
#include <seqan/basic.h>

using namespace seqan;

//The known library of sequences is stored as a StringSet called THaystacks
//We will generate an index against this file to make the search faster
typedef StringSet<CharString> THaystacks;

int
get_number_of_matching_residues( std::vector< CharString > const & seq_primers );

// could put following in util file?
void RNA2DNA( String<char> & seq );
int findchar( String<char> & seq, char c );

// could package into a little class:
void record_counter( std::string const tag,
		     unsigned & counter_idx,
		     std::vector< unsigned > & counter_counts,
		     std::vector< std::string > & counter_tags );

int try_exact_match( CharString & seq1, CharString & cseq, unsigned & perfect );
int try_exact_match( CharString & seq1, CharString & cseq );
int try_DP_match( CharString & seq1, CharString & cseq, unsigned & perfect );
int try_DP_match_expt_ids( std::vector< CharString > & short_expt_ids, CharString & expt_id_in_read1 );

bool
get_next_variant( CharString const & seq, CharString & seq_var, unsigned & variant_counter, unsigned const & seqid_length );

void
check_for_star_sequence( CharString & seq_from_library,
			 std::vector< CharString > & sequences_before_star,
			 std::vector< CharString > & sequences_after_star,
			 std::vector< unsigned > & star_sequence_ids,
			 unsigned const j );


void
figure_out_expt_IDs( std::string const & file_primers,
		     std::string const & file_expt_id,
		     std::vector< String<char> > & short_expt_ids,
		     THaystacks & haystacks_expt_ids,
		     CharString & cseq,
		     CharString & adapterSequence );

void
read_in_fastq( MultiSeqFile & multiSeqFile1,
	       AutoSeqFormat & format1,
	       std::string const & file1,
	       unsigned & seqCount1 );

void
check_unique_id(  std::vector< String<char> > const & rna_library_vector_RC,
		  CharString const & cseq,
		  unsigned & seqid_length,
		  unsigned const & max_rna_len  );

void
disambiguate_possible_sids( std::vector< unsigned > & possible_sids,
			    std::vector< unsigned > const & possible_begpos,
			    unsigned const min_pos,
			    CharString const & seq1,
			    std::vector< CharString > const & RNA_sequences );

void
check_for_short_insert( CharString const & adapterSequence2,
			CharString const & cseq,
			unsigned const & constant_sequence_begin_pos,
			unsigned const & seqid_length,
			CharString & seq1,
			Finder<Index<THaystacks> > & finder_sequence_id,
			std::vector< unsigned > & possible_sids,
			bool const & align_null,
			bool & verbose,
			unsigned & nullLigation );

void
find_possible_sids( std::vector< unsigned > & possible_sids,
		    std::vector< unsigned > & possible_begpos,
		    Finder<Index<THaystacks> > & finder_sequence_id,
		    CharString & sequence_id_region_in_sequence1 );

void
check_for_extra_junk_using_star_sequences(
					  std::vector< unsigned > & possible_sids,
					  std::vector< CharString > & sequences_with_extra_junk,
					  bool & extra_junk_mode,
					  Finder<Index<THaystacks> > & finder_sequence_id,
					  CharString & seq1,
					  unsigned const & constant_sequence_begin_pos,
					  std::vector< CharString > const & sequences_before_star,
					  std::vector< CharString > const & sequences_after_star,
					  std::vector< unsigned > const & star_sequence_ids );

void
output_stats_files( std::vector< std::vector< std::vector < double > > > const & all_count,
		    std::string const & outpath);

bool
already_saved( std::vector< unsigned > const & mpos_vector,
	       std::vector< unsigned > const & sid_vector,
	       unsigned const & mpos,
	       unsigned const & sid );
