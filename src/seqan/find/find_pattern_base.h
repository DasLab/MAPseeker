// ==========================================================================
//                 SeqAn - The Library for Sequence Analysis
// ==========================================================================
// Copyright (c) 2006-2013, Knut Reinert, FU Berlin
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Knut Reinert or the FU Berlin nor the names of
//       its contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL KNUT REINERT OR THE FU BERLIN BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
//
// ==========================================================================
// Author: Andreas Gogol-Doering <andreas.doering@mdc-berlin.de>
// ==========================================================================
// Definition of the class Pattern and supporting functions and
// metafunctions.
// ==========================================================================

#ifndef SEQAN_HEADER_FIND_PATTERN_BASE_H
#define SEQAN_HEADER_FIND_PATTERN_BASE_H


//////////////////////////////////////////////////////////////////////////////

namespace seqan {

//////////////////////////////////////////////////////////////////////////////

/*!
 * @class Pattern
 * @headerfile <seqan/find.h>
 * @brief Holds the needle and precprocessing data (depends on algorithm).
 *
 * @signature template <typename TNeedle[, typename TSpec]>
 *            class Pattern;
 *
 * @tparam TNeedle The needle type.  Types: @link TextConcept @endlink.
 * @tparam TSpec   The specializing type; gives the online algorithm to use for the search.  Defaults to the result of
 *                 @link DefaultPattern @endlink.
 *
 * @section Remarks
 *
 * If <tt>Needle</tt> is a StringSet then <tt>position(pattern)</tt> returns a pair with the index of the currently
 * matching needle and the position in the needle.
 */

/**
.Class.Pattern:
..summary:Holds the needle and preprocessing data (depends on algorithm).
..cat:Searching
..signature:Pattern<TNeedle[, TSpec]>
..param.TNeedle:The needle type.
...type:Class.String
..param.TSpec:The online-algorithm to search with.
...remarks:Leave empty for index-based pattern matching (see @Class.Index@).
...default:The result of @Metafunction.DefaultPattern@
..remarks:If $TNeedle$ is a set of strings, then $position(pattern)$ returns the index of the currently matching needle.
..include:seqan/find.h
*/

template < typename TNeedle, typename TSpec = typename DefaultPattern<TNeedle>::Type >
class Pattern;

//default implementation
template < typename TNeedle >
class Pattern<TNeedle, void>
{
public:
	typedef typename Position<TNeedle>::Type TNeedlePosition;

	Holder<TNeedle> data_host;
	TNeedlePosition data_begin_position;
	TNeedlePosition data_end_position;

	Pattern() {}

	template <typename TNeedle_>
	Pattern(TNeedle_ & ndl):
		data_host(ndl) {}

	template <typename TNeedle_>
	Pattern(TNeedle_ const & ndl):
		data_host(ndl) {}

};
//////////////////////////////////////////////////////////////////////////////

/*!
 * @mfn Pattern#Container
 * @brief Returns the needle type of the pattern.
 *
 * @signature Container<TPattern>::Type
 *
 * @tparam TPattern The pattern to query for its needle type.
 *
 * @return Type The needle type.
 */

template <typename TNeedle, typename TSpec>
struct Container< Pattern<TNeedle, TSpec> > {
	typedef TNeedle Type;
};

template <typename TNeedle, typename TSpec>
struct Container< Pattern<TNeedle, TSpec> const > {
	typedef TNeedle const Type;
};

/*!
 * @mfn Pattern#Host
 * @brief Returns the host type of the pattern.
 *
 * @signature Host<TPattern>::Type
 *
 * @tparam TPattern The pattern to query for its host type.
 *
 * @return Type The host type.
 */

///.Metafunction.Host.param.T.type:Class.Pattern
///.Metafunction.Host.class:Class.Pattern
template <typename TNeedle, typename TSpec>
struct Host< Pattern<TNeedle, TSpec> > {
	typedef TNeedle Type;
};

template <typename TNeedle, typename TSpec>
struct Host< Pattern<TNeedle, TSpec> const > {
	typedef TNeedle const Type;
};

/*!
 * @fn Pattern#Value
 * @brief Returns the value type of the underlying pattern.
 *
 * @signature Value<TPattern>::Type
 *
 * @tparam TPattern The Pattern to query.
 *
 * @return Type The value type.
 */

template <typename TPattern, typename TSpec>
struct Value< Pattern<TPattern, TSpec> > {
	typedef typename Value<TPattern>::Type Type;
};

/*!
 * @fn Pattern#Position
 * @brief Returns the position type of the underlying pattern.
 *
 * @signature Position<TPattern>::Type
 *
 * @tparam TPattern The Pattern to query.
 *
 * @return Type The position type.
 */

template <typename TPattern, typename TSpec>
struct Position< Pattern<TPattern, TSpec> > {
	typedef typename Position<TPattern>::Type Type;
};

/*!
 * @fn Pattern#Difference
 * @brief Returns the difference type of the underlying pattern.
 *
 * @signature Difference<TPattern>::Type
 *
 * @tparam TPattern The Pattern to query.
 *
 * @return Type The difference type.
 */

template <typename TPattern, typename TSpec>
struct Difference< Pattern<TPattern, TSpec> > {
	typedef typename Difference<TPattern>::Type Type;
};

/*!
 * @fn Pattern#Size
 * @brief Returns the size type of the underlying pattern.
 *
 * @signature Size<TPattern>::Type
 *
 * @tparam TPattern The Pattern to query.
 *
 * @return Type The size type.
 */

template <typename TPattern, typename TSpec>
struct Size< Pattern<TPattern, TSpec> > {
	typedef typename Size<TPattern>::Type Type;
};


//////////////////////////////////////////////////////////////////////////////

/*!
 * @fn Pattern#ScoringScheme
 * @brief Returns the scoring scheme type of an approximate search algorithm.
 *
 * @signature ScoringScheme<TPattern>::Type;
 *
 * @tparam TPattern The Pattern to query for its scoring scheme type.  Default: EditDistanceScore.
 */

/**
.Metafunction.ScoringScheme:
..summary:Returns the scoring scheme of an approximate searching algorithm.
..cat:Searching
..signature:ScoringScheme<TPattern>::Type
..param.TPattern:A @Class.Pattern@ type.
...type:Class.Pattern
..returns:The scoring scheme.
...default:@Shortcut.EditDistanceScore@
..include:seqan/find.h
*/

template <typename TNeedle>
struct ScoringScheme
{
	typedef EditDistanceScore Type;
};
template <typename TNeedle>
struct ScoringScheme<TNeedle const>:
	ScoringScheme<TNeedle>
{
};

//////////////////////////////////////////////////////////////////////////////

template <typename TNeedle, typename TSpec>
inline Holder<TNeedle> & 
_dataHost(Pattern<TNeedle, TSpec> & me) 
{ 
	return me.data_host;
}
template <typename TNeedle, typename TSpec>
inline Holder<TNeedle> & 
_dataHost(Pattern<TNeedle, TSpec> const & me) 
{
	return const_cast<Holder<TNeedle> &>(me.data_host);
}

//host access: see basic_host.h


//???TODO: Diese Funktion entfernen! (sobald setHost bei anderen pattern nicht mehr eine Art "assignHost" ist)
template <typename TNeedle, typename TSpec, typename TNeedle2>
inline void 
setHost(Pattern<TNeedle, TSpec> & me,
		TNeedle2 const & ndl) 
{
	 me.data_host = ndl; //assign => Pattern haelt eine Kopie => doof!
}
template <typename TNeedle, typename TSpec, typename TNeedle2>
inline void 
setHost(Pattern<TNeedle, TSpec> & me,
		TNeedle2 & ndl) 
{ 
	 me.data_host = ndl; //assign => Pattern haelt eine Kopie => doof!
}
//////////////////////////////////////////////////////////////////////////////

template <typename TNeedle, typename TSpec>
inline typename Position<Pattern<TNeedle, TSpec> >::Type & 
beginPosition(Pattern<TNeedle, TSpec> & me) 
{
	return me.data_begin_position;
}
template <typename TNeedle, typename TSpec>
inline typename Position<Pattern<TNeedle, TSpec> const >::Type & 
beginPosition(Pattern<TNeedle, TSpec> const & me) 
{
	return me.data_begin_position;
}


template <typename TNeedle, typename TSpec, typename TPosition>
inline void
setBeginPosition(Pattern<TNeedle, TSpec> & me, 
				 TPosition _pos) 
{
	me.data_begin_position = _pos;
}

//////////////////////////////////////////////////////////////////////////////

template <typename TNeedle, typename TSpec>
inline typename Position<Pattern<TNeedle, TSpec> >::Type & 
endPosition(Pattern<TNeedle, TSpec> & me) 
{
	return me.data_end_position;
}
template <typename TNeedle, typename TSpec>
inline typename Position<Pattern<TNeedle, TSpec> const >::Type & 
endPosition(Pattern<TNeedle, TSpec> const & me) 
{
	return me.data_end_position;
}

template <typename TNeedle, typename TSpec, typename TPosition>
inline void
setEndPosition(Pattern<TNeedle, TSpec> & me, 
			   TPosition _pos) 
{
	me.data_end_position = _pos;
}

//////////////////////////////////////////////////////////////////////////////

template <typename TNeedle, typename TSpec>
inline typename Infix<TNeedle>::Type 
segment(Pattern<TNeedle, TSpec> & me) 
{
	typedef typename Infix<TNeedle>::Type TInfix;
	return TInfix(host(me), me.data_begin_position, me.data_end_position);
}
template <typename TNeedle, typename TSpec>
inline typename Infix<TNeedle>::Type 
segment(Pattern<TNeedle, TSpec> const & me) 
{
	typedef typename Infix<TNeedle>::Type TInfix;
	return TInfix(host(me), me.data_begin_position, me.data_end_position);
}

//////////////////////////////////////////////////////////////////////////////

/*!
 * @fn Pattern#host
 * @brief Query a Pattern for its host.
 *
 * @signature THost host(pattern);
 *
 * @param[in] pattern The Pattern to query for its host.
 *
 * @return THost Reference to the host.
 */

///.Function.host.param.object.type:Class.Pattern
///.Function.host.class:Class.Pattern

template <typename TNeedle, typename TSpec>
inline typename Host<Pattern<TNeedle, TSpec> >::Type & 
host(Pattern<TNeedle, TSpec> & me)
{
SEQAN_CHECKPOINT
	return value(me.data_host);
}

template <typename TNeedle, typename TSpec>
inline typename Host<Pattern<TNeedle, TSpec> const>::Type & 
host(Pattern<TNeedle, TSpec> const & me)
{
SEQAN_CHECKPOINT
	return value(me.data_host);
}


//////////////////////////////////////////////////////////////////////////////

/*!
 * @fn Pattern#needle
 * @brief Returns the needle of a Pattern object (not implemented for some online-algorithms).
 *
 * @signature TNeedle needle(pattern);
 *
 * @param[in] pattern The Pattern to query for its needle.
 *
 * @return TNeedle Reference ot the needle object.
 *
 * @section Remarks
 *
 * TNeedle is the result of the Needle metafunction of TPattern.  This is an alias to the function Pattern#host.
 */

/**
.Function.needle:
..summary:Returns the needle of a @Class.Pattern@ object (not implemented for some online-algorithms).
..cat:Searching
..signature:needle(pattern)
..class:Class.Pattern
..param.pattern:The @Class.Pattern@ object to search with.
...type:Class.Pattern
..returns:The needle object to search for.
..remarks:The result type is @Metafunction.Needle@$<TPattern>::Type$ for pattern of type $TPattern$.
This is an alias to function @Function.host@ of the pattern function.
..see:Function.host
..include:seqan/find.h
*/
///.Function.host.remarks:Aliased to @Function.needle@ and @Function.haystack@ for classes @Class.Pattern@ and @Class.Finder@.


template < typename TObject >
inline typename Needle<TObject>::Type &
needle(TObject &obj) 
{
	return obj;
}

template < typename TObject >
inline typename Needle<TObject const>::Type &
needle(TObject const &obj) 
{
	return obj;
}


/*!
 * @fn Pattern#position
 * @brief Return the position of the last match in the pattern.
 *
 * @signature TPosition position(pattern);
 *
 * @param[in] pattern The Pattern to query for its position.
 *
 * @return TPosition The position of the last match in the pattern.
 */

///.Function.position.param.iterator.type:Class.Pattern
///.Function.position.class:Class.Pattern

template < typename TNeedle, typename TSpec >
inline typename Needle< Pattern<TNeedle, TSpec> >::Type &
needle(Pattern<TNeedle, TSpec> & obj) 
{
	return host(obj);
}

template < typename TNeedle, typename TSpec >
inline typename Needle< Pattern<TNeedle, TSpec> const>::Type &
needle(Pattern<TNeedle, TSpec> const & obj) 
{
	return host(obj);
}

/*!
 * @fn Pattern#setNeedle
 * @brief Sets the needle of a Pattern object and optionall induces preprocessing.
 *
 * @signature void setNeedle(pattern, needle);
 *
 * @param[in,out] pattern The pattern to set the needle for.
 * @param[in]     needle  The needle to set.
 */

/**
.Function.setNeedle:
..summary:Sets the needle of a @Class.Pattern@ object and optionally induces preprocessing.
..cat:Searching
..signature:setNeedle(pattern, needle)
..class:Class.Pattern
..param.pattern:The @Class.Pattern@ object to search with.
...type:Class.Pattern
..param.needle:The needle object to search for.
...type:Class.String
..include:seqan/find.h
*/

template < typename TNeedle, typename TSpec >
inline void
setNeedle(Pattern<TNeedle, TSpec> &obj, TNeedle const &ndl) {
	setHost(obj, ndl);
}


//____________________________________________________________________________

/*!
 * @fn Pattern#scoringScheme
 * @brief The scoring scheme used for finding or aligning.
 *
 * @signature TScoringScheme scoringScheme(pattern);
 *
 * @param[in] pattern The Pattern to query for its scoring scheme.
 *
 * @return TScoringScheme The scoring scheme of the pattern.
 */

/**.Function.scoringScheme
..cat:Searching
..summary:The @glos:Scoring Scheme|scoring scheme@ used for finding or aligning.
..signature:scoringScheme(obj)
..class:Class.Pattern
..param.obj:Object that holds a @glos:Scoring Scheme|scoring scheme@
...type:Class.Pattern
..returns:The @glos:Scoring Scheme|scoring scheme@ used in $obj$
...default:@Shortcut.EditDistanceScore@
..see:glos:Scoring Scheme|scoring scheme
..see:Metafunction.ScoringScheme
*/

template <typename TNeedle, typename TSpec>
inline typename ScoringScheme<Pattern<TNeedle, TSpec> >::Type 
scoringScheme(Pattern<TNeedle, TSpec> &)
{
SEQAN_CHECKPOINT
	return typename ScoringScheme<Pattern<TNeedle, TSpec> >::Type();
}
template <typename TNeedle, typename TSpec>
inline typename ScoringScheme<Pattern<TNeedle, TSpec> const>::Type 
scoringScheme(Pattern<TNeedle, TSpec> const &)
{
SEQAN_CHECKPOINT
	return typename ScoringScheme<Pattern<TNeedle, TSpec> const>::Type();
}

//____________________________________________________________________________

/*!
 * @fn Pattern#setScoringScheme
 * @brief Sets the scoring scheme used for finding or aligning.
 *
 * @signature void setScoringScheme(pattern, score);
 *
 * @param[in,out] pattern The pattern to set the scoring scheme for.
 * @param[in]     score   The scoring scheme to set.
 */

/**.Function.setScoringScheme
..cat:Searching
..summary:Sets the @glos:Scoring Scheme|scoring scheme@ used for finding or aligning.
..signature:setScoringScheme(obj, score)
..class:Class.Pattern
..param.obj:Object that holds a @glos:Scoring Scheme|scoring scheme@.
...type:Class.Pattern
..param.score:The new @glos:Scoring Scheme|scoring scheme@ used by $obj$.
..see:glos:Scoring Scheme|scoring scheme
..see:Function.scoringScheme
*/

template <typename TNeedle, typename TSpec, typename TScore2>
inline void
setScoringScheme(Pattern<TNeedle, TSpec> & /*me*/, 
				 TScore2 & /*score*/)
{
//dummy implementation for compatibility reasons
}
//////////////////////////////////////////////////////////////////////////////

}  // namespace seqan

#endif //#ifndef SEQAN_HEADER_...
