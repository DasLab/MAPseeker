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
// Author: David Weese <david.weese@fu-berlin.de>
// ==========================================================================

#ifndef SEQAN_HEADER_INDEX_ESA_STREE_H
#define SEQAN_HEADER_INDEX_ESA_STREE_H

namespace SEQAN_NAMESPACE_MAIN
{

/**
.Spec.VSTree Iterator:
..cat:Index
..summary:Abstract iterator for suffix trees.
..signature:Iter<TContainer, VSTree<TSpec> >
..general:Class.Iter
..param.TContainer:Type of the container that can be iterated.
...type:Spec.IndexEsa
...metafunction:Metafunction.Container
..param.TSpec:The specialization type.
..remarks:This iterator is a pointer to a node in the suffix tree (given by the enhanced suffix array @Spec.IndexEsa@).
Every node can uniquely be mapped to an interval of the suffix array containing all suffixes of the node's subtree.
This interval and some extra information constitute the @Metafunction.VertexDescriptor@ returned by the @Function.value@ function of the iterator.
..include:seqan/index.h
..example
...text:This code shows how an index can be used with iterators to achieve a pre-order tree like traversal
in DFS of the text "tobeornottobe". In order to do so a Top-Down History iterator is used.
...file:demos/index/index_iterator.cpp
...output:

be
beornottobe
e
eornottobe
nottobe
o
obe
obeornottobe
ornottobe
ottobe
rnottobe
t
tobe
tobeornottobe
ttobe
*/
/*!
 * @class VSTreeIterator VSTree Iterator
 * 
 * @extends Iter
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Abstract iterator for string trees, where string trees are trees constructed from a string.
 * 
 * @signature Iter<TContainer, VSTree<TSpec> >
 * 
 * @tparam TSpec The specialization type.
 * @tparam TContainer Type of the container that can be iterated. Types:
 *                    @link IndexDfi @endlink, @link IndexEsa @endlink, @link IndexWotd @endlink, @link FMindex @endlink
 * 
 * @section Remarks
 * 
 * This iterator is a pointer to a node in the string tree of a given text. Depending on the index this can either be a
 * suffix or prefix tree/trie.  Every node can uniquely be mapped to an interval of suffices or prefixes.
 *
 * Default virtual string tree iterators depending on the @link Index @endlink
 * <table border="1">
 * <tr>
 *   <td>IndexSa</td>
 *   <td>Virtual suffix trie iterator</td>
 * </tr>
 * <tr>
 *   <td>IndexEsa</td>
 *   <td>Virtual suffix tree iterator</td>
 * </tr>
 * <tr>
 *   <td>IndexWotd</td>
 *   <td>Virtual suffix tree iterator</td>
 * </tr>
 * <tr>
 *   <td>IndexDfi</td>
 *   <td>Virtual suffix tree iterator</td>
 * </tr>
 * <tr>
 *   <td>FMIndex</td>
 *   <td>Virtual prefix trie iterator</td>
 * </tr>
 * </table>
 *
 * @section Example 
 *
 * This code shows how an index can be used with iterators to achieve a pre-order tree like traversal
 * in DFS of the text "tobeornottobe". In order to do so a Top-Down History iterator is used.
 *
 * @include demos/index/index_iterator.cpp
 * @code{.txt}
 * 
 * be
 * beornottobe
 * e
 * eornottobe
 * nottobe
 * o
 * obe
 * obeornottobe
 * ornottobe
 * ottobe
 * rnottobe
 * t
 * tobe
 * tobeornottobe
 * ttobe
 */

	template < typename TIndex, typename TSpec >
    struct Value< Iter< TIndex, VSTree<TSpec> > > {
		typedef typename VertexDescriptor<TIndex>::Type Type;
	};
 
	template < typename TIndex, typename TSpec >
	struct Size< Iter< TIndex, VSTree<TSpec> > > {
		typedef typename Size<TIndex>::Type Type;
	};
 
	template < typename TIndex, typename TSpec >
	struct Position< Iter< TIndex, VSTree<TSpec> > > {
		typedef typename Position<TIndex>::Type Type;
	};

    template < typename TSpec >
    struct EdgeLabel {};

    template < typename TIndex, typename TSpec >
    struct EdgeLabel< Iter< TIndex, VSTree<TSpec> > > {
		typedef typename Infix< typename Fibre<TIndex, FibreText>::Type const >::Type Type;
	};

/**
.Spec.TopDown Iterator:
..cat:Index
..general:Spec.VSTree Iterator
..summary:Iterator for virtual trees that can go down and right beginning from the root.
..signature:Iterator<TContainer, TopDown<TSpec> >::Type
..signature:Iter<TContainer, VSTree< TopDown<TSpec> > >
..param.TContainer:Type of the container that can be iterated.
...type:Spec.IndexEsa
...metafunction:Metafunction.Container
..param.TSpec:The specialization type.
..remarks:If not copy-constructed the @Spec.TopDown Iterator@ starts in the root node of the virtual tree.
..remarks:Note that the virtual tree can either be a virtual suffix tree or a virtual prefix tree. The suffix tree is shown in Figure 1 and is implemented with the @Spec.IndexDfi@, @Spec.IndexEsa@ and @Spec.IndexWotd@. In contrast the @Spec.FMIndex@ implements a prefix trie shown in Figure 2.
..include:seqan/index.h

.Memfunc.TopDown Iterator#Iterator
..class:Spec.TopDown Iterator
..summary:Constructor
..signature:Iterator(index[, vertexDesc])
..signature:Iterator(iterator)
..param.index:An index object.
..param.vertexDesc:The vertex descriptor of a node the iterator should start in.
The iterator starts in the root node by default.
..param.iterator:Another TopDown iterator. (copy constructor)
...type:Spec.TopDown Iterator
...type:Spec.TopDownHistory Iterator
..remarks:If not copy-constructed the @Spec.TopDown Iterator@ starts in the root node of the virtual tree.
..remarks:Note that the virtual tree can either be a virtual suffix tree or a virtual prefix tree. The suffix tree is shown in Figure 1 and is implemented with the @Spec.IndexDfi@, @Spec.IndexEsa@ and @Spec.IndexWotd@. In contrast the @Spec.FMIndex@ implements a prefix trie shown in Figure 2.
*/
/*!
 * @class TopDownIterator Top Down Iterator
 * 
 * @extends VSTreeIterator
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Iterator for virtual trees/tries that can go down and right beginning from the root.
 * 
 * @signature template <typename TIndex, typename TSpec>
 *            Iter<TContainer, VSTree< TopDown<TSpec> > >
 * 
 * @tparam TSpec The specialization type.
 * @tparam TIndex Type of the container that can be iterated. Types: @link IndexDfi @endlink, @link IndexEsa @endlink,
 *                @link IndexWotd @endlink, @link FMIndex @endlink, @link IndexSa @endlink
 * 
 * @section Remarks
 * 
 * If not copy-constructed the @link TopDownIterator @endlink starts in the root node of the virtual tree/trie.
 * 
 * @section Note 
 *
 * Instead of using the class Iter directly we recommend to use the result of the metafunction 
 * Iterator&t;TContainer, TopDown&lt;TSpec&gt; &gt;::Type (which is Iter&lt;TContainer, VSTree&lt;TopDown&lt;TSpec&gt; &gt; &gt;).
 */
/*!
 * @fn TopDownIterator::Iterator
 * 
 * @brief Constructor
 * 
 * @signature Iterator(index[, vertexDesc])
 * @signature Iterator(iterator)
 * 
 * @param index An index object.
 * @param iterator Another TopDown iterator. (copy constructor) Types: TopDown
 *                 Iterator, TopDownHistory Iterator
 * @param vertexDesc The vertex descriptor of a node the iterator should start
 *                   in. The iterator starts in the root node by default.
 * 
 * @section Remarks
 * 
 * If not copy-constructed the @link TopDownIterator @endlink starts in the
 * root node of the virtual tree.
 */

	template < typename TIndex, class TSpec >
	class Iter< TIndex, VSTree< TopDown<TSpec> > > 
	{
	public:

		typedef typename VertexDescriptor<TIndex>::Type	TVertexDesc;
		typedef Iter									iterator;

		TIndex const	*index;		// container of all necessary tables
		TVertexDesc		vDesc;		// current interval in suffix array and
									// right border of parent interval (needed in goRight)

		// pseudo history stack (to go up at most one node)
		TVertexDesc		_parentDesc;

//____________________________________________________________________________

        Iter() : index() {}
        
		Iter(TIndex &_index):
			index(&_index)
		{
			_indexRequireTopDownIteration(_index);
			goRoot(*this);
		}

		Iter(TIndex &_index, MinimalCtor):
			index(&_index),
			vDesc(MinimalCtor()),
            _parentDesc(MinimalCtor()) {}

        // NOTE(esiragusa): _parentDesc is unitialized
		Iter(TIndex &_index, TVertexDesc const &_vDesc):
			index(&_index),
			vDesc(_vDesc)
		{
			_indexRequireTopDownIteration(_index);
		}

        template <typename TSpec2>
		Iter(Iter<TIndex, VSTree<TopDown<TSpec2> > > const &_origin):
			index(&container(_origin)),
			vDesc(value(_origin)),
			_parentDesc(nodeUp(_origin)) {}

//____________________________________________________________________________

        template <typename TSpec2>
		inline Iter const &
		operator = (Iter<TIndex, VSTree<TopDown<TSpec2> > > const &_origin)
		{
			index = &container(_origin);
			vDesc = value(_origin);
			_parentDesc = nodeUp(_origin);
			return *this;
		}
	};


/**
.Spec.TopDownHistory Iterator:
..cat:Index
..general:Spec.TopDown Iterator
..summary:String tree iterator that can go down, right, and up. Supports depth-first search.
..signature:Iterator<TContainer, TopDown< ParentLinks<TSpec> > >::Type
..signature:Iter<TContainer, VSTree< TopDown< ParentLinks<TSpec> > > >
..param.TContainer:Type of the container that can be iterated.
...type:Spec.IndexEsa
...metafunction:Metafunction.Container
..implements:Concept.ForwardIteratorConcept
..param.TSpec:The specialization type. Specifies the depth-first search mode.
...type:Tag.DFS Order.tag.Preorder
...type:Tag.DFS Order.tag.PreorderEmptyEdges
...type:Tag.DFS Order.tag.Postorder
...type:Tag.DFS Order.tag.PostorderEmptyEdges
..remarks:If not copy-constructed the @Spec.TopDownHistory Iterator@ starts in the root node of the string tree.
Depending on the depth-first search mode the root is not the first DFS node. To go to the first DFS node use @Function.goBegin@.
..remarks:Note that the virtual tree can either be a virtual suffix tree or a virtual prefix tree. The suffix tree is shown in Figure 1 and is implemented with the @Spec.IndexDfi@, @Spec.IndexEsa@ and @Spec.IndexWotd@. In contrast the @Spec.FMIndex@ implements a prefix trie shown in Figure 2.
..include:seqan/index.h

.Memfunc.TopDownHistory Iterator#Iterator
..class:Spec.TopDownHistory Iterator
..summary:Constructor
..signature:Iterator(index)
..signature:Iterator(iterator)
..param.index:An index object.
..param.iterator:Another TopDownHistory iterator. (copy constructor)
...type:Spec.TopDownHistory Iterator
..remarks:If not copy-constructed the @Spec.TopDownHistory Iterator@ starts in the root node of the suffix tree.
..remarks:Note that the virtual tree can either be a virtual suffix tree or a virtual prefix tree. The suffix tree is shown in Figure 1 and is implemented with the @Spec.IndexDfi@, @Spec.IndexEsa@ and @Spec.IndexWotd@. In contrast the @Spec.FMIndex@ implements a prefix trie shown in Figure 2.
*/
/*!
 * @class TopDownHistoryIterator Top Down History Iterator
 * 
 * @implements ForwardIteratorConcept
 * 
 * @extends TopDownIterator
 * 
 * @headerfile seqan/index.h
 * 
 * @brief String tree iterator that can go down, right, and up. Supports depth-
 *        first search.
 * 
 * @signature template <typename TIndex, typename TSpec> 
 *            Iter<TIndex, VSTree<TopDown<ParentLinks<TSpec> > > >
 * 
 * @tparam TSpec Specifies the depth-first search mode.  Types: @link DFS Order @endlink
 * @tparam TIndex Type of the container that can be iterated. Types: @link IndexDfi @endlink, @link IndexEsa @endlink,
 *                @link IndexWotd @endlink, @link FMIndex @endlink, @link IndexSa @endlink
 *
 * @section Note Instead of using the class Iter directly we recommend to use the result of the metafunction 
 *               Iterator&lt;TContainer, TopDown&lt;ParentLinks&lt;TSpec&gt; &gt; &gt;::Type (which is Iter&lt;TContainer, VSTree&lt;ParentLinks&lt;TopDown&lt;TSpec&gt; &gt; &gt; &gt;).
 *
 * 
 * @section Remarks
 * 
 * If not copy-constructed the @link TopDownHistoryIterator @endlink starts in the root node of the string tree.
 * Depending on the depth-first search mode the root is not the first DFS node. To go to the first DFS node use @link
 * goBegin @endlink.
 * @section Example
 *
 * @link DemoConstraintIterator @endlink
 */
/*!
 * @fn TopDownHistoryIterator::Iterator
 * 
 * @brief Constructor
 * 
 * @signature Iterator(index)
 * @signature Iterator(iterator)
 * 
 * @param index An index object.
 * @param iterator Another TopDownHistory iterator. (copy constructor) Types:
 *                 TopDownHistory Iterator
 * 
 * @section Remarks
 * 
 * If not copy-constructed the @link TopDownHistoryIterator @endlink starts in
 * the root node of the string tree.
 */

	template < typename TVSTreeIter >
	struct HistoryStackEntry_;
	
	template <typename TSize>
	struct HistoryStackEsa_
	{
		Pair<TSize> range;		// current SA interval of hits
		HistoryStackEsa_() {}
		template <typename TSize_>
		HistoryStackEsa_(Pair<TSize_> const &_range): range(_range) {}
	};

	template < typename TIndex, typename TSpec >
	struct HistoryStackEntry_< Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > >
	{
		typedef HistoryStackEsa_<typename Size<TIndex>::Type>	Type;
	};

	template < typename TIndex, class TSpec >
	class Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > >:
		public Iter< TIndex, VSTree< TopDown<> > >
	{
	public:

		typedef Iter< TIndex, VSTree< TopDown<> > >		TBase;
		typedef	typename HistoryStackEntry_<Iter>::Type	TStackEntry;
		typedef String<TStackEntry, Block<> >			TStack;
		typedef Iter									iterator;

		TStack			history;	// contains all previously visited intervals (allows to go up)

//____________________________________________________________________________

        Iter() :
            TBase()
        {}

		Iter(TIndex &_index):
			TBase(_index) {}

		Iter(TIndex &_index, MinimalCtor):
			TBase(_index, MinimalCtor()) {}

		Iter(Iter const &_origin):
			TBase((TBase const &)_origin),
			history(_origin.history) {}

//____________________________________________________________________________

		inline Iter const &
		operator = (Iter const &_origin)
		{
			*(TBase*)(this) = _origin;
			history = _origin.history;
			return *this;
		}
	};

//    //TODO(weese): define concepts somewhere else
//    SEQAN_CONCEPT(ParentLinksConcepts,(T))
//    {
//        SEQAN_CONCEPT_USAGE(ParentLinksConcepts)
//        {
//            goUp(a);
//        }
//    private:
//        T a;
//    };
//    
//    template <typename TIndex, class TSpec>
//    SEQAN_CONCEPT_IMPL(Iter<TIndex,VSTree<TopDown<ParentLinks<TSpec> > > >, (ParentLinksConcepts));

/**
.Spec.BottomUp Iterator:
..cat:Index
..general:Spec.VSTree Iterator
..summary:Iterator for an efficient postorder depth-first search in a suffix tree.
..signature:Iterator<TContainer, BottomUp<TSpec> >::Type
..signature:Iter<TContainer, VSTree< BottomUp<TSpec> > >
..param.TContainer:Type of the container that can be iterated.
...type:Spec.IndexEsa
...metafunction:Metafunction.Container
..implements:Concept.ForwardIteratorConcept
..param.TSpec:The specialization type.
..include:seqan/index.h

.Memfunc.BottomUp Iterator#Iterator
..class:Spec.BottomUp Iterator
..summary:Constructor
..signature:Iterator(index)
..signature:Iterator(iterator)
..param.index:An index object.
..param.iterator:Another BottomUp iterator. (copy constructor)
...type:Spec.BottomUp Iterator
..remarks:If not copy-constructed the @Spec.BottomUp Iterator@ starts in the first DFS node, which is the left-most leaf of the suffix tree.
*/
/*!
 * @class BottomUpIterator Bottom Up Iterator
 * 
 * @implements ForwardIteratorConcept
 * 
 * @extends VSTreeIterator
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Iterator for an efficient postorder depth-first search in a virtual string tree.
 * 
 * @signature template <typename TIndex, typename TSpec>
 *            Iter<TContainer, VSTree< BottomUp<TSpec> > >
 * 
 * @tparam TSpec The specialization type.
 * @tparam TIndex Type of the container that can be iterated.
 *
 * @section Note 
 *
 * Instead of using the class Iter directly we recommend to use the result of the metafunction 
 * Iterator&lt;TContainer, BottomUp&lt;TSpec&gt; &gt;::Type (which is Iter&lt;TContainer, VSTree&lt;BottomUp&lt;TSpec&gt; &gt; &gt;).
 * 
 * @fn Bottom Up Iterator::Iterator
 * 
 * @brief Constructor
 * 
 * @signature Iterator(index)
 * @signature Iterator(iterator)
 * 
 * @param index An index object.
 * @param iterator A Bottom Up Iterator.
 * 
 * @section Remarks
 * 
 * If not copy-constructed the @link BottomUpIterator @endlink starts in the first DFS node, which is the left-most leaf
 * of the virtual string tree.
 */

	template < typename TIndex, typename TSpec >
	struct HistoryStackEntry_< Iter< TIndex, VSTree< BottomUp<TSpec> > > >
	{
		typedef HistoryStackEsa_<typename Size<TIndex>::Type>	Type;
	};

	template < typename TIndex, typename TSpec >
	class Iter< TIndex, VSTree< BottomUp<TSpec> > > 
	{
	public:

		typedef typename VertexDescriptor<TIndex>::Type	TVertexDesc;
		typedef typename Size<TIndex>::Type				TSize;
		typedef	typename HistoryStackEntry_<Iter>::Type	TStackEntry;
		typedef String<TStackEntry, Block<> >			TStack;
		typedef Iter									iterator;

		TIndex	const	*index;			// container of all necessary tables
		TVertexDesc		vDesc;			// current interval in suffix array and
										// right border of parent interval (unused here)
		TSize			lValue;			// current l-value
		TStack			history;		// contains all left borders of current l-intervals (== left borders of history intervals)

//____________________________________________________________________________

        Iter() :
            index(),
            lValue(0)
        {}

		Iter(TIndex &_index):
			index(&_index),
			vDesc(MinimalCtor()),
			lValue(0)
		{
			_indexRequireBottomUpIteration(_index);
			goBegin(*this);
		}

		Iter(TIndex &_index, MinimalCtor):
			index(&_index),
			vDesc(MinimalCtor()),
			lValue(0) {}

		Iter(Iter const &_origin):
			index(&container(_origin)),
			vDesc(value(_origin)),
			lValue(_dfsLcp(_origin)),
			history(_origin.history) {}

//____________________________________________________________________________

		inline Iter const &
		operator = (Iter const &_origin)
		{
			index = &container(_origin);
			vDesc = _origin.vDesc;
			lValue = _origin.lValue;
			history = _origin.history;
			return *this;
		}
	};


	//////////////////////////////////////////////////////////////////////////////
	// Iterator wrappers
	//////////////////////////////////////////////////////////////////////////////

	template <typename TObject, typename TSpec>
	struct Iterator< TObject, BottomUp<TSpec> > {
		typedef Iter< TObject, VSTree< BottomUp<TSpec> > > Type;
	};

	template <typename TObject, typename TSpec>
	struct Iterator< TObject, TopDown<TSpec> > {
		typedef Iter< TObject, VSTree< TopDown<TSpec> > > Type;
	};




	template < typename TIndex, typename TSpec >
	inline void _dumpHistoryStack(Iter<TIndex, VSTree<TSpec> > &it) {
		for(typename Size<TIndex>::Type i = 0; i < length(it.history); ++i)
			::std::cerr << it.history[i].range << '\t';
		::std::cerr << value(it) << ::std::endl;
	}

	template <typename TText, typename TSpec>
	inline void
	_dump(Index<TText, IndexEsa<TSpec> > &index)
	{
		::std::cout << "  SA" << ::std::endl;
		for(unsigned i=0; i < length(indexSA(index)); ++i)
			::std::cout << i << ":  " << indexSA(index)[i] << "  " << suffix(indexText(index), indexSA(index)[i]) << ::std::endl;

		::std::cout << ::std::endl << "  LCP" << ::std::endl;
		for(unsigned i=0; i < length(indexLcp(index)); ++i)
			::std::cout << i << ":  " << indexLcp(index)[i] << ::std::endl;

		::std::cout << ::std::endl << "  Childtab" << ::std::endl;
		for(unsigned i=0; i < length(indexChildtab(index)); ++i)
			::std::cout << i << ":  " << indexChildtab(index)[i] << ::std::endl;

		::std::cout << ::std::endl;
	}


//////////////////////////////////////////////////////////////////////////////

	template < typename TIndex, typename TSpec >
	inline bool _dfsReversedOrder(Iter<TIndex, VSTree< BottomUp<TSpec> > > &it) {
        return lcpAt(_dfsRange(it).i2 - 1, container(it)) > back(it.history).range.i2;
	}

	// standard push/pop handlers of lcp-dfs-traversal
	template < typename TIndex, typename TSpec, typename TSize >
	inline void _dfsOnPop(Iter<TIndex, VSTree< BottomUp<TSpec> > > &it, TSize const) {
        _dfsRange(it).i1 = back(it.history).range.i1;
		_dfsLcp(it) = back(it.history).range.i2;
		pop(it.history);
	}

	template < typename TIndex, typename TSpec, typename TElement >
	inline void _dfsOnPush(Iter<TIndex, VSTree< BottomUp<TSpec> > > &it, TElement const &e) {
		appendValue(it.history, e);
	}

	template < typename TIndex, typename TSpec >
	inline void _dfsOnLeaf(Iter<TIndex, VSTree< BottomUp<TSpec> > > &it) {
		_setSizeInval(_dfsLcp(it));
	}


//////////////////////////////////////////////////////////////////////////////
// postorder bottom up iterator (dfs)

	template < typename TIndex, typename TSpec, typename THideEmptyEdges >
	inline void goNextImpl(
		Iter<TIndex, VSTree< BottomUp<TSpec> > > &it, 
		VSTreeIteratorTraits<Postorder_, THideEmptyEdges> const) 
	{
		TIndex const &index = container(it);
		do {
			// postorder dfs via lcp-table
			if (isRoot(it)) {
				_dfsClear(it);
				return;
			}
			
			if (_dfsRange(it).i2)
			{
				typedef typename Size<TIndex>::Type TSize;
				typedef typename Iter<TIndex, VSTree< BottomUp<TSpec> > >::TStackEntry TStackEntry;
				TStackEntry	_top_ = back(it.history);
				TSize		lcp_i = lcpAt(_dfsRange(it).i2 - 1, index);

				if (lcp_i < _top_.range.i2) {
					_dfsOnPop(it, lcp_i);
					if (nodePredicate(it)) return;
					else continue;
				}

				if (lcp_i > _top_.range.i2) {
					_top_.range.i1 = _dfsRange(it).i1;
					_top_.range.i2 = lcp_i;
					_dfsOnPush(it, _top_);
				}

	// innerer Knoten:
	// wenn kein Pop, aber Push -> begehe mind. 2. Teilbaum irgendeines Vorfahrs
	// wenn kein Pop, kein Push -> verlasse mind. zweites Kindblatt
	// wenn Pop, aber kein Push -> verlasse Wurzel des mind. 2.Teilbaums
	// wenn Pop und Push        -> verlasse ersten Teilbaum (sieht Vater zum ersten Mal und pusht jenen)

	// wenn nach Pop ein Pop folgen wuerde	-> Vater ist Top of Stack
	// wenn nach Pop ein Push folgen wuerde	-> Vater erst beim Push auf Stack (-> zwischenspeichern)
			}

			// last lcp entry (== 0) causes removal of toplevel interval
			if ((_dfsRange(it).i1 = _dfsRange(it).i2++) == length(index)) {
				_dfsOnPop(it, 0);
				_dfsRange(it).i2 = _dfsRange(it).i1;
			} else {
				// skip $ leafs (empty edges)
				if (THideEmptyEdges::VALUE &&
					suffixLength(saAt(_dfsRange(it).i1, index), index) == lcpAt(_dfsRange(it).i1, index))
					continue;

				_dfsOnLeaf(it);
	// Blatt:
	// wenn danach kein Pop, aber Push -> Vater wird erst noch gepusht
	// wenn danach Pop				   -> Vater ist Top des Stack
			}
			if (nodePredicate(it)) return;
		} while (true);
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.repLength:
..summary:Returns the length of the substring representing the path from root to $iterator$ node.
..cat:Index
..signature:repLength(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:The length of the sequence returned by @Function.representative@
...type:Metafunction.Size|Size type of the underlying index
..include:seqan/index.h
..example
...text:The following code shows a simple example how the function @Function.repLength@ is used.
...file:demos/index/index_begin_range_goDown_representative_repLength.cpp
...output:The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
*/
/*!
 * @fn VSTreeIterator#repLength
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the length of the substring representing the path from root to <tt>iterator</tt> node.
 * 
 * @signature TSize repLength(iterator)
 * 
 * @param iterator An iterator of a string tree. Types: @link VSTreeIterator @endlink
 * 
 * @return TSize The length of the sequence returned by @link representative
 *               @endlink The return type is the result of the metafunction @link Size @endlink of the underlying 
 *               index.
 * 
 * @link DemoMummy @endlink
 * @link DemoSupermaximalRepeats @endlink
 * @link DemoMaximalUniqueMatches @endlink
 */
	template < typename TIndex, typename TSpec >
	inline typename Size<TIndex>::Type 
	repLength(Iter< TIndex, VSTree<BottomUp<TSpec> > > const &it) 
	{
		typename Size<TIndex>::Type lcp;
		if (!_isSizeInval(lcp = it.lValue))
			return lcp;
		else
			return suffixLength(getOccurrence(it), container(it));
	}


	template < typename TIndex, typename TSize >
	inline typename Size<TIndex>::Type
	repLength(TIndex const &index, VertexEsa<TSize> const &vDesc) 
	{
		if (_isLeaf(vDesc)) return suffixLength(saAt(vDesc.range.i1, index), index);
		if (_isRoot(vDesc)) return 0;

		// get l-value of suffix array range
		TSize lval = _getUp(vDesc.range.i2, index);
		if (!(vDesc.range.i1 < lval && lval < vDesc.range.i2))
			lval = _getDown(vDesc.range.i1, index);
		
		// retrieve the longest-common-prefix length of suffices in range
		return lcpAt(lval - 1, index);
	}

	template < typename TIndex, typename TSpec >
	inline typename Size<TIndex>::Type
	repLength(Iter< TIndex, VSTree<TopDown<TSpec> > > const &it) 
	{
		return repLength(container(it), value(it));
	}

//////////////////////////////////////////////////////////////////////////////

/**
.Function.nodeDepth:
..summary:Returns the zero-based node depth of the $iterator$ node.
..cat:Index
..signature:nodeDepth(iterator)
..class:Spec.TopDownHistory Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDownHistory Iterator
..returns:The length of the path from root to $iterator$ node, e.g. 0 is returned for the root node.
...type:Metafunction.Size|Size type of the underlying index
..include:seqan/index.h
*/
/*!
 * @fn TopDownHistoryIterator#nodeDepth
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the zero-based node depth of the <tt>iterator</tt> node.
 * 
 * @signature TSize nodeDepth(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TSize The length of the path from root to <tt>iterator</tt> node,
 *               e.g. 0 is returned for the root node. The type of the result
 *               is the result of the metafunction @link Size @endlink of the underlying index.
 */

	template < typename TIndex, typename TSpec >
	inline typename Size<TIndex>::Type
	nodeDepth(Iter< TIndex, VSTree<TopDown<ParentLinks<TSpec> > > > const &it) 
	{
		return length(it.history);
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.parentRepLength:
..summary:Returns the length of the substring representing the path from root to $iterator$'s parent node.
..cat:Index
..signature:parentRepLength(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:The length of the sequence returned by @Function.representative@ of the parent node.
...type:Metafunction.Size|Size type of the underlying index
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#parentRepLength
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the length of the substring representing the path from root to <tt>iterator</tt>'s parent node.
 * 
 * @signature TSize parentRepLength(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TReturn The length of the sequence returned by @link representative @endlink of the parent node. The result
 *                 type is the resultof the metafunction @link Size @endlink of the underlying index.
 */

	template < typename TIndex, typename TSpec >
	inline typename Size<TIndex>::Type
	parentRepLength(Iter< TIndex, VSTree<TopDown<TSpec> > > const &it) 
	{
		return repLength(container(it), nodeUp(it));
	}


//////////////////////////////////////////////////////////////////////////////
/**
.Function.emptyParentEdge:
..summary:Returns $true$ iff the edge label from the $iterator$ node to its parent is empty.
..cat:Index
..signature:bool emptyParentEdge(iterator)
..classSpec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:$true$ if @Function.parentEdgeLength@$ returns 0, otherwise $false$.
...type:Metafunction.Size|Size type of the underlying index
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#emptyParentEdge
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns <tt>true</tt> iff the edge label from the <tt>iterator</tt>
 *        node to its parent is empty.
 * 
 * @signature bool emptyParentEdge(iterator)
 * 
 * @param iterator An iterator of a string tree. Types: @link TopDownIterator @endlink
 * 
 * @return TReturn <tt>true</tt> if @link parentEdgeLength @endlink<tt> returns 0, otherwise </tt>false$. 
 */

	template < typename TIndex, typename TSpec >
	inline bool
	emptyParentEdge(Iter< TIndex, VSTree<TopDown<TSpec> > > const &it) 
	{
		// the following is more efficient than 
		// return parentEdgeLength(it) == 0;
		TIndex const &index = container(it);
		typename SAValue<TIndex>::Type pos = getOccurrence(it);
		return getSeqOffset(pos, stringSetLimits(index)) + parentRepLength(it)
			== sequenceLength(getSeqNo(pos, stringSetLimits(index)), index);
	}


//////////////////////////////////////////////////////////////////////////////
/**
.Function.lca:
..summary:Returns the last common ancestor of two tree nodes.
..cat:Index
..signature:bool lca(a, b, result)
..class:Spec.TopDownHistory Iterator
..param.a:The first node.
...type:Spec.TopDownHistory Iterator
..param.b:The second node.
...type:Spec.TopDownHistory Iterator
..param.result:A reference to the resulting lca node.
...type:Spec.TopDownHistory Iterator
..returns:$false$ if the lca of $a$ and $b$ is the root node, otherwise $true$.
..include:seqan/index.h
*/
/*!
 * @fn TopDownHistoryIterator#lca
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the last common ancestor of two tree nodes.
 * 
 * @signature bool lca(a, b, result)
 * 
 * @param a The first node. Types: @link TopDownHistoryIterator @endlink
 * @param b The second node. Types: @link TopDownHistoryIterator @endlink
 * @param result A reference to the resulting lca node. Types: @link TopDownHistoryIterator @endlink 
 * 
 * @return TReturn <tt>false</tt> if the lca of <tt>a</tt> and <tt>b</tt> is the root node, otherwise <tt>true</tt>.
 */

	template < typename TIndex, class TSpec1, class TSpec2 >
	inline bool lca(
		Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec1> > > > &a, 
		Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec2> > > > &b, 
		Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec1> > > > &_lca)
	{
		typedef Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec1> > > > TIter;
		typename TIter::TStack::const_iterator iA;
		typename TIter::TStack::const_iterator iB;

		typedef typename Size<TIndex>::Type TSize;

		typename HistoryStackEntry_<TIter>::Type hA, hB;

		// push current intervals
		hA = value(a).range;
		hB = value(b).range;
		appendValue(a.history, hA);
		appendValue(b.history, hB);

		TSize s = min(length(a.history), length(b.history)), i0 = 0;
		
		while (s) {
			TSize m = s / 2;
			iA = begin(a.history, Standard()) + i0 + m;
			iB = begin(b.history, Standard()) + i0 + m;
			if ((*iA).range == (*iB).range) {
				i0 += m + 1;
				s -= m + 1;
			} else
				s = m;
		}

		_lca.history = prefix(a.history, i0);

		// pop current intervals
		pop(a.history);
		pop(b.history);
		goUp(_lca);

		return i0;
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.lcp:
..summary:Returns the length of the longest-common-prefix of two suffix tree nodes.
..cat:Index
..signature:lcp(a, b)
..class:Spec.TopDownHistory Iterator
..param.a:The first node.
...type:Spec.TopDownHistory Iterator
..param.b:The second node.
...type:Spec.TopDownHistory Iterator
..returns:The lcp-length of $a$ and $b$.
..include:seqan/index.h
*/
/*! 
 * @fn TopDownHistoryIterator#lcp
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the length of the longest-common-prefix of two suffix tree
 *        nodes.
 * 
 * @signature TSize lcp(a, b)
 * 
 * @param a The first node. Types: @link TopDownHistoryIterator @endlink
 * @param b The second node. Types: @link TopDownHistoryIterator @endlink
 * 
 * @return TSize The lcp-length of <tt>a</tt> and <tt>b</tt>. The type of the result is the result of the metafunction
 *               @link Size @endlink of the @link Index @endlink of the iterator
 */
	// return the lcp of a and b by seeking the lca of them
	template < typename TIndex, class TSpec1, class TSpec2 >
	inline typename Size<TIndex>::Type lcp(
		Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec1> > > > &a, 
		Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec2> > > > &b) 
	{
		typedef Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec1> > > > TIter;
		typename TIter::TStack::const_iterator iA;
		typename TIter::TStack::const_iterator iB;

		typedef typename Size<TIndex>::Type TSize;

		typename HistoryStackEntry_<TIter>::Type hA, hB;

		// push current intervals
		hA = value(a).range;
		hB = value(b).range;
		appendValue(a.history, hA);
		appendValue(b.history, hB);

		TSize s = min(length(a.history), length(b.history)), i0 = 0;
		
		while (s) {
			TSize m = s / 2;
			iA = begin(a.history, Standard()) + i0 + m;
			iB = begin(b.history, Standard()) + i0 + m;
			if ((*iA).range == (*iB).range) {
				i0 += m + 1;
				s -= m + 1;
			} else
				s = m;
		}

		TSize _lcp = (i0 > 0)? repLength(container(a), TDesc(a.history[i0 - 1], 0)): 0;

		// pop current intervals
		pop(a.history);
		pop(b.history);

		return _lcp;
	}

//////////////////////////////////////////////////////////////////////////////
///.Function.container.param.iterator.type:Spec.VSTree Iterator

	template < typename TIndex, class TSpec >
	inline TIndex const & 
	container(Iter< TIndex, VSTree<TSpec> > const &it) { 
		return *it.index; 
	}

	template < typename TIndex, class TSpec >
	inline TIndex & 
	container(Iter< TIndex, VSTree<TSpec> > &it) { 
		return *const_cast<TIndex*>(it.index); 
	}


//////////////////////////////////////////////////////////////////////////////
///.Function.value.param.object.type:Spec.VSTree Iterator

	template < typename TIndex, class TSpec >
	inline typename VertexDescriptor<TIndex>::Type & 
	value(Iter< TIndex, VSTree<TSpec> > &it) { 
		return it.vDesc;
	}

	template < typename TIndex, class TSpec >
	inline typename VertexDescriptor<TIndex>::Type const & 
	value(Iter< TIndex, VSTree<TSpec> > const &it) { 
		return it.vDesc;
	}

//////////////////////////////////////////////////////////////////////////////
// property map interface

/**
.Function.resizeVertexMap:
..cat:Index
..signature:resizeVertexMap(index, pm)
..param.index:An index with a suffix tree interface.
...type:Spec.IndexEsa
..include:seqan/index.h
*/
/*!
 * @fn Index#resizeVertexMap
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Initializes a vertex map.
 * 
 * @signature void resizeVertexMap(index, pm)
 * 
 * @param index An index with a suffix tree interface. Types: @link IndexEsa @endlink, @link IndexWotd @endlink
 * @param pm An External Property Map. Types: @link ExternalPropertyMap @endlink
 * 
 * @see resizeEdgeMap
 */
	template < typename TText, typename TSpec, typename TPropertyMap >
	inline void
	resizeVertexMap(
		Index<TText, TSpec> const& index, 
		TPropertyMap & pm)
	{
		resize(pm, 2 * length(index), Generous());
	}
/* // different interface compared to resizeVertexMap(graph, ...)
	template < typename TText, typename TSpec, typename TPropertyMap, typename TProperty >
	inline void
	resizeVertexMap(
		Index<TText, TSpec> const& index, 
		TPropertyMap & pm,
		TProperty const & prop)
	{
		resize(pm, 2 * length(index), prop, Generous());
	}
*/
	template < typename TSize >
	inline typename Id< VertexEsa<TSize> const >::Type
	_getId(VertexEsa<TSize> const &desc) 
	{
		TSize i2 = getValueI2(desc.range);
		if (_isSizeInval(i2) || i2 == desc.parentRight)
			// desc is the right-most child -> use left interval border
			return 2 * getValueI1(desc.range);
		else
			// desc is not the right-most child -> use right interval border
			// ensure that it doesn't collide with the left borders
			return 2 * getValueI2(desc.range) - 1;
	}

	template < typename TSize >
	inline typename Id< VertexEsa<TSize> >::Type
	_getId(VertexEsa<TSize> &desc) 
	{
		return _getId(const_cast<VertexEsa<TSize> const &>(desc));
	}


//////////////////////////////////////////////////////////////////////////////
/**
.Function.getOccurrence:
..summary:Returns an occurrence of the @Function.representative@ substring or a q-gram in the index text.
..cat:Index
..signature:getOccurrence(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:A position where the @Function.representative@ of $iterator$ occurs in the text (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $SAValue<TIndex>::Type$.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#getOccurrence
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns an occurrence of the @link representative @endlink substring in the index text.
 *
 * @signature TSAValue getOccurrence(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TSAValue A position where the @link representative @endlink of <tt>iterator</tt> occurs in the text. The
 * return type is the result of the metafunction @link SAValue @endlink of the index type of the iterator.
 */

	template < typename TIndex, class TSpec >
	inline typename SAValue<TIndex>::Type 
	getOccurrence(Iter< TIndex, VSTree<TSpec> > const &it)
	{
		return saAt(value(it).range.i1, container(it));
	}


//////////////////////////////////////////////////////////////////////////////
/**
.Function.countOccurrences:
..summary:Returns the number of occurrences of @Function.representative@ substring or a q-gram in the index text.
..cat:Index
..signature:countOccurrences(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:The number of positions where the @Function.representative@ of $iterator$ occurs in the text (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $Size<TIndex>::Type$.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#countOccurrences
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the number of occurrences of @link representative @endlink
 *        substring in the index text.
 *
 * @signature TSize countOccurrences(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TSize The number of positions where the @link representative @endlink of <tt>iterator</tt> occurs in the
 *               text. The return type is the result of the metafunction @link Size @endlink of the index type of the
 *               iterator.

 * @section Remarks
 * 
 * The necessary index tables are built on-demand via @link indexRequire @endlink if index is not <tt>const</tt>.
 * 
 * @section Examples
 *
 * @link DemoSupermaximalRepeats @endlink
 * @link DemoIndexCountChildren @endlink
 */

	template < typename TIndex, class TSpec >
	inline typename Size<TIndex>::Type 
	countOccurrences(Iter< TIndex, VSTree<TSpec> > const &it) 
	{
		if (_isSizeInval(value(it).range.i2))
			return length(indexSA(container(it))) - value(it).range.i1;
		else
			return value(it).range.i2 - value(it).range.i1;
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.range:
..summary:Returns the suffix array interval borders of occurrences of @Function.representative@ substring or a q-gram in the index text.
..cat:Index
..signature:range(iterator)
..class:Spec.VSTree Iterator
..class:Class.Index
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:All positions where a substring occurs in the text (see @Tag.ESA Index Fibres.EsaText@) 
are stored in a contiguous range of the suffix array.
$range$ returns begin and end position of this range for occurrences of @Function.representative@.
If $iterator$'s container type is $TIndex$ the return type is $Pair<Size<TIndex>::Type>.
..include:seqan/index.h
..example
...text:The following code shows a simple example how the function @Function.range@ is used.
...file:demos/index/index_begin_range_goDown_representative_repLength.cpp
...output:The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
*/
/*!
 * @fn VSTreeIterator#range
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the suffix array interval borders of occurrences of @link representative @endlink substring in the
 *        index text.
 * 
 * @signature Pair<TSize> range(iterator)
 * 
 * @param iterator An iterator of a string tree/trie.
 * 
 * @return TReturn All positions where a substring occurs in the text are stored in a contiguous range of the suffix
 *                 array. <tt>range</tt> returns begin and end position of this range for occurrences of @link 
 *                 representative @endlink. The type is @link Pair @endlink<@link Size @endlink< <tt>TIndex<tt> > >
 *                 with TIndex being the index type of the iterator.
 *
 * @section Remarks
 * 
 * The necessary index tables are built on-demand via @link indexRequire @endlink if index is not <tt>const</tt>.
 */
	template < typename TText, typename TSpec, typename TDesc >
	inline Pair<typename Size<Index<TText, TSpec> >::Type>
	range(Index<TText, TSpec> const &index, TDesc const &desc)
	{
		if (_isSizeInval(desc.range.i2))
			return Pair<typename Size<Index<TText, TSpec> >::Type>(desc.range.i1, length(indexSA(index)));
		else
			return desc.range;
	}

	template < typename TIndex, typename TSpec >
	inline Pair<typename Size<TIndex>::Type>
	range(Iter<TIndex, VSTree<TSpec> > const &it)
	{
		if (_isSizeInval(value(it).range.i2))
			return Pair<typename Size<TIndex>::Type>(value(it).range.i1, length(indexSA(container(it))));
		else
			return value(it).range;
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.getOccurrences:
..summary:Returns all occurrences of the @Function.representative@ substring or a q-gram in the index text.
..cat:Index
..signature:getOccurrences(iterator)
..classSpec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:All positions where the @Function.representative@ of $iterator$ occurs in the text (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $Infix<Fibre<TIndex, EsaSA>::Type const>::Type$.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#getOccurrences
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns all occurrences of the @link representative @endlink substring in the index text.
 * 
 * @signature Infix<TSA> getOccurrences(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return Infix<TSA> All positions where the @link representative @endlink of <tt>iterator</tt> occurs in the text.
 *                    Type @link Infix @endlink<@link Fibre @endlink <TIndex, FibreSA>::Type>. 
 * 
 * @section Remarks
 * 
 * The necessary index tables are built on-demand via @link indexRequire @endlink if index is not <tt>const</tt>.
 * 
 * @section Example
 *
 * @link DemoMummy @endlink
 * @link DemoSupermaximalRepeats
 * @link DemoMaximalUniqueMatches
 *
 * @see isUnique
 * @see getFrequency
 * @see isPartiallyLeftExtensible
 * @see isLeftMaximal
 * @see orderOccurrences
 */

	template < typename TIndex, class TSpec >
	inline typename Infix< typename Fibre<TIndex, FibreSA>::Type const >::Type 
	getOccurrences(Iter< TIndex, VSTree<TSpec> > const &it) 
	{
		if (_isSizeInval(value(it).range.i2))
			return infix(indexSA(container(it)), value(it).range.i1, length(indexSA(container(it))));
		else
			return infix(indexSA(container(it)), value(it).range.i1, value(it).range.i2);
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.alignment:
..summary:Returns an alignment of the occurrences of the @Function.representative@ substring in the index text.
..cat:internal
..signature:alignment(iterator)
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:A local alignment corresponding to the seed of the $iterator$.
..remarks:The @Function.representative@ must uniquely occur in every sequence (e.g. in Mums), 
otherwise the seed returned is one many.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#alignment
 *
 * @brief Returns an alignment of the occurrences of the @link representative @endlink substring in the index text.
 *
 * @deprecated Internal
 *
 * @signature Align alignment(iterator)
 *
 * @param iterator An iterator of a string tree.
 * 
 * @return Align A local alignment corresponding to the seed of the <tt>iterator<tt>.
 *
 * @section Remark 
 *
 * The function @link representative @endlink must uniquely occur in every sequence (e.g. in Mums), 
 * otherwise the seed returned is one many. The return type is a @link Align @endlink object.
 */

	template < typename TString, typename TSSetSpec, typename TIndexSpec, class TSpec >
	inline Align<TString, ArrayGaps>
	alignment(Iter< Index< StringSet<TString, TSSetSpec>, TIndexSpec >, VSTree<TSpec> > &it) 
	{
		typedef Index< StringSet<TString, TSSetSpec>, TIndexSpec > TIndex;
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type TOccs;
		typedef typename Iterator<TOccs, Standard>::Type TIter;

		Align<TString, ArrayGaps> align;
		TIndex &index = container(it);
		resize(rows(align), length(indexText(index)));	// resize alignment to number of sequences
		TOccs occs = getOccurrences(it);
		typename Size<TIndex>::Type repLen = repLength(it);
		TIter occ = begin(occs, Standard()), occEnd = end(occs, Standard());
		while (occ != occEnd) {
			typename Size<TIndex>::Type seqNo = getSeqNo(*occ, stringSetLimits((TIndex const&)index));
			typename Size<TIndex>::Type seqOfs = getSeqOffset(*occ, stringSetLimits((TIndex const&)index));
			setSource(row(align, seqNo), value(indexText(index), seqNo), seqOfs, seqOfs + repLen);
			++occ;
		}
		return align;
	}
/*
	template < typename TString, typename TConcSpec, typename TIndexSpec, class TSpec >
	inline typename Align<TString const, ArrayGaps>
	alignment(Iter< Index< StringSet<TString, Owner<ConcatDirect<TConcSpec> > >, TIndexSpec >, VSTree<TSpec> > const &it) 
	{
		typedef Index< StringSet<TString, Owner<ConcatDirect<TConcSpec> > >, TIndexSpec > TIndex;
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type TOccs;
		typedef typename Iterator<TOccs, Standard>::Type TIter;

		Align<TString const, ArrayGaps> align;
		TIndex const &index = container(it);
		resize(rows(align), length(indexText(index)));	// resize alignment to number of sequences
		TOccs occs = getOccurrences(it);
		typename Size<TIndex>::Type repLen = repLength(it);
		TIter occ = begin(occs, Standard()), occEnd = end(occs, Standard());
		while (occ != occEnd) {
			typename Size<TIndex>::Type seqNo = getSeqNo(*occ, stringSetLimits(index));
			typename Size<TIndex>::Type globOfs = posGlobalize(*occ, stringSetLimits(index));
			setSource(row(align, seqNo), concat(indexText(index)), globOfs, globOfs + repLen);
			++occ;
		}
		return align;
	}
*/
	template < typename TString, typename TConcSpec, typename TIndexSpec, class TSpec >
	inline Align<TString, ArrayGaps>
	alignment(Iter< Index< StringSet<TString, Owner<ConcatDirect<TConcSpec> > >, TIndexSpec >, VSTree<TSpec> > &it) 
	{
		typedef Index< StringSet<TString, Owner<ConcatDirect<TConcSpec> > >, TIndexSpec > TIndex;
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type TOccs;
		typedef typename Iterator<TOccs, Standard>::Type TIter;

		Align<TString, ArrayGaps> align;
		TIndex &index = container(it);
		resize(rows(align), length(indexText(index)));	// resize alignment to number of sequences
		TOccs occs = getOccurrences(it);
		typename Size<TIndex>::Type repLen = repLength(it);
		TIter occ = begin(occs, Standard()), occEnd = end(occs, Standard());
		while (occ != occEnd) {
			typename Size<TIndex>::Type seqNo = getSeqNo(*occ, stringSetLimits((TIndex const&)index));
			typename Size<TIndex>::Type globOfs = posGlobalize(*occ, stringSetLimits((TIndex const&)index));
			setSource(row(align, seqNo), concat(indexText(index)), globOfs, globOfs + repLen);
			++occ;
		}
		return align;
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.getOccurrencesBwt:
..summary:Returns the characters left beside all occurrence of the @Function.representative@ substring in the index text.
..cat:Index
..signature:getOccurrencesBwt(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:All positions where the @Function.representative@ of $iterator$ occurs in the text (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $Infix<Fibre<TIndex, EsaBwt>::Type const>::Type$.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#getOccurrencesBwt
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the characters left beside all occurrence of the @link
 *        VSTreeIterator#representative @endlink substring in the index text.
 * 
 * @signature getOccurrencesBwt(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn All positions where the @link VStreeIterator#representative @endlink of
 *                 <tt>iterator</tt> occurs in the text.
 *
 *                 If <tt>iterator</tt>'s container
 *                 type is <tt>TIndex</tt> the return type is
 *                 <tt>Infix<Fibre<TIndex, EsaBwt>::Type const>::Type</tt>.
 */
	template < typename TIndex, class TSpec >
	inline typename Infix< typename Fibre<TIndex, EsaBwt>::Type const >::Type 
	getOccurrencesBwt(Iter< TIndex, VSTree<TSpec> > const &it) 
	{
		if (_isSizeInval(value(it).range.i2))
			return infix(indexBwt(container(it)), value(it).range.i1, length(indexSA(container(it))));
		else
			return infix(indexBwt(container(it)), value(it).range.i1, value(it).range.i2);
	}

//////////////////////////////////////////////////////////////////////////////
/**
.Function.representative:
..summary:Returns a substring representing the path from root to $iterator$ node.
..cat:Index
..signature:representative(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a string tree.
...type:Spec.VSTree Iterator
..returns:An @Spec.InfixSegment@ of the text of an index (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $Infix<Fibre<TIndex, EsaText>::Type const>::Type$.
..include:seqan/index.h
..example
...text:The following code shows a simple example how the @Function.range@ is used.
...file:demos/index/index_begin_range_goDown_representative_repLength.cpp
...output:The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
*/
/*!
 * @fn VSTreeIterator#representative
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns a substring representing the path from root to <tt>iterator</tt> node.
 * 
 * @signature Infix<TSting> representative(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return Infix<TSting> An @link InfixSegment @endlink of the text of an index. The type is Infix<Fibre<TIndex, FibreText>::Type>::Type.
 * 
 * @section Examples
 *
 * @link DemoMummy @endlink
 * @link DemoSupermaximalRepeats @endlink
 * @link DemoConstraintIterator @endlink
 * @link DemoMaximalRepeats @endlink
 * @link DemoMaximalUniqueMatches @endlink
 */

	template < typename TIndex, class TSpec >
	inline typename Infix< typename Fibre<TIndex, FibreText>::Type const >::Type 
	representative(Iter< TIndex, VSTree<TSpec> > const &it) 
	{
		return infixWithLength(indexText(container(it)), getOccurrence(it), repLength(it));
	}


//////////////////////////////////////////////////////////////////////////////
/**
.Function.countChildren:
..summary:Count the number of children of a tree node.
..cat:Index
..signature:countChildren(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:The number of children of a tree node.
If $iterator$'s container type is $TIndex$, the return type is $Size<TIndex>::Type$.
..include:seqan/index.h
..example.code:
 
 // this code is in seqan/index/index_esa_stree.h
 
 typedef Index< String<char> > TMyIndex;
 TMyIndex myIndex(myString);
 
 Iterator< TMyIndex, TopDown<ParentLinks<PreorderEmptyEdges> > >::Type tdIterator(myIndex);
 Size<TMyIndex>::Type count;
 
 while (!atEnd(tdIterator)) {
 // We print out the representatives of all nodes that have more than 3 children and the number of occurrences.
 count = countChildren(tdIterator);
 if (count >= 3)
 {
     ::std::cout << "Representative " << representative(tdIterator) << " has " <<  count << " children  and " << countOccurrences(tdIterator) << " Occurrences " << ::std::endl;
 
     ++tdIterator;
 }

*/
/*!
 * @fn VSTreeIterator#countChildren
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Count the number of children of a tree node.
 * 
 * @signature TSize countChildren(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TSize The number of children of a tree node. The type is the result of @link Size @endlink of the index type
 *               of the iterator.
 *  
 * @section Examples
 * 
 * @code{.cpp}
 * // this code is in seqan/index/index_esa_stree.h
 *
 *  typedef Index< String<char> > TMyIndex;
 *  TMyIndex myIndex(myString);
 *
 *  Iterator< TMyIndex, TopDown<ParentLinks<PreorderEmptyEdges> > >::Type tdIterator(myIndex);
 *  Size<TMyIndex>::Type count;
 *
 *  while (!atEnd(tdIterator)) {
 *  // We print out the representatives of all nodes that have more than 3 children and the number of occurrences.
 *  count = countChildren(tdIterator);
 *  if (count >= 3)
 *  {
 *      ::std::cout << "Representative " << representative(tdIterator) << " has " <<  count << " children  and " << countOccurrences(tdIterator) << " Occurrences " << ::std::endl;
 *
 *      ++tdIterator;
 *  }
 * @endcode
 * @link DemoIndexCountChildren @endlink
 */
	template < typename TIndex, typename TSpec >
	inline typename Size<TIndex>::Type 
	countChildren(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		typedef Iter<TIndex, VSTree<TSpec> >					TIter;
		typedef typename GetVSTreeIteratorTraits<TIter>::Type	TTraits;
		
		Iter<TIndex, VSTree<TopDown<TTraits> > > temp(it);
		typename Size<TIndex>::Type numChildren = 0; 
		if (goDown(temp))
		{
			++numChildren;
			while (goRight(temp)) ++numChildren;
		}
		return numChildren;
	}

	template < typename TText, typename TIndexSpec, typename TSpec >
	inline typename Size<Index<TText, IndexEsa<TIndexSpec> > >::Type 
	countChildren(Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree<TSpec> > const &it) 
	{
		typedef Index<TText, IndexEsa<TIndexSpec> >			TIndex;
		typedef Iter<TIndex, VSTree<TSpec> >					TIter;
		typedef typename GetVSTreeIteratorTraits<TIter>::Type	TTraits;
		typedef typename TTraits::HideEmptyEdges				THideEmptyEdges;

		if (_isLeaf(it, EmptyEdges())) return 0;

		typedef typename Size<TIndex>::Type TSize;
		TIndex const &index = container(it);
		TSize lcp = repLength(it);
		TSize result = (isRoot(it))? 0: 1;

		// check if child has an empty edge (same representative as its parent)
		typename SAValue<TIndex>::Type pos = getOccurrence(it);
		if (THideEmptyEdges::VALUE && getSeqOffset(pos, stringSetLimits(index)) + lcp == sequenceLength(getSeqNo(pos, stringSetLimits(index)), index))
			--result;	// if so, don't count

		// get l-Value between first and second child
		TSize i = _getUp(value(it).range.i2, index);
		if (!(value(it).range.i1 < i && i < value(it).range.i2))
			i = _getDown(value(it).range.i1, index);

		if (THideEmptyEdges::VALUE)
		{
			// only count children with non-empty parent edges (different representative than its parent)
			pos = saAt(i, index);
			if (getSeqOffset(pos, stringSetLimits(index)) + lcp != sequenceLength(getSeqNo(pos, stringSetLimits(index)), index))
				++result;
		} else
			++result;

		// try to get next l-Value
		while (_isNextl(i, index)) 
		{
			i = _getNextl(i, index);
			if (THideEmptyEdges::VALUE)
			{
				// only count children with non-empty parent edges (different representative than its parent)
				pos = saAt(i, index);
				if (getSeqOffset(pos, stringSetLimits(index)) + lcp != sequenceLength(getSeqNo(pos, stringSetLimits(index)), index))
					++result;
			} else
				++result;
		}
		return result;
	}
    
	// get the interval of SA of the subtree under the edge beginning with character c
	template < typename TText, class TIndexSpec, class TSpec, typename TValue >
	inline bool 
	_getNodeByChar(
		Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree<TSpec> > const &it, 
		TValue c, 
		typename VertexDescriptor< Index<TText, IndexEsa<TIndexSpec> > >::Type &childDesc)
	{
		typedef Index<TText, IndexEsa<TIndexSpec> >		TIndex;
		typedef typename Size<TIndex>::Type					TSize;
        typedef typename Fibre<TIndex, EsaSA>::Type const  TSA;
		typedef typename Value<TSA>::Type                   TSAValue;

		if (_isLeaf(it, EmptyEdges())) return false;

		Pair<TSize> child(value(it).range.i1, _getUp(value(it).range.i2, container(it)));
		if (!(value(it).range.i1 < child.i2 && child.i2 < value(it).range.i2))
			child.i2 = _getDown(value(it).range.i1, container(it));

		TSize _lcp = lcpAt(child.i2 - 1, container(it));
        TIndex const &index = container(it);
        TText const &text = indexText(index);

        TSAValue pos = saAt(child.i1, container(it));
		if (posAddAndCheck(pos, _lcp, text) && (textAt(pos, container(it)) == c)) 
        {
			childDesc.range = child;
			childDesc.parentRight = value(it).range.i2;
			return true;
		}
		child.i1 = child.i2;
		while (_isNextl(child.i2, container(it))) 
		{
			child.i2 = _getNextl(child.i2, container(it));
            pos = saAt(child.i1, container(it));
			if (posAddAndCheck(pos, _lcp, text) && (textAt(pos, container(it)) == c)) 
            {
				childDesc.range = child;
				childDesc.parentRight = value(it).range.i2;
				return true;
			}
			child.i1 = child.i2;
		}

		if (!isRoot(it)) {
            pos = saAt(child.i1, container(it));
			if (posAddAndCheck(pos, _lcp, text) && (textAt(pos, container(it)) == c))
            {
				childDesc.range.i1 = child.i1;
				childDesc.range.i2 = childDesc.parentRight = value(it).range.i2;
				return true;
			}
		}
		return false;
	}


/**
.Function.nodePredicate:
..summary:If $false$ this node will be skipped during the bottom-up traversal.
..cat:Index
..signature:bool nodePredicate(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:
..include:seqan/index.h
*/
//TODO(singer): Why only bottom-up???
/*!
 * @fn VSTreeIterator#nodePredicate
 * 
 * @headerfile seqan/index.h
 * 
 * @brief If <tt>false</tt> this node will be skipped during the bottom-up traversal.
 * 
 * @signature bool nodePredicate(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return bool Returns whether or not the node will be skipped. 
 * 
 * @link DemoConstraintIterator @endlink
 */

	template < typename TIndex, class TSpec >
	inline bool
	nodePredicate(Iter<TIndex, TSpec> &)
	{
		return true;
	}


/**
.Function.nodeHullPredicate:
..summary:If $false$ this node and its subtree is concealed.
..cat:Index
..signature:bool nodeHullPredicate(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#nodeHullPredicate
 * 
 * @headerfile seqan/index.h
 * 
 * @brief If <tt>false</tt> this node and its subtree is concealed.
 * 
 * @signature bool nodeHullPredicate(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return bool Returns whether or not a subtree is concealed.
 * 
 * @link DemoConstraintIterator @endlink
 */

	template < typename TIndex, class TSpec >
	inline bool
	nodeHullPredicate(Iter<TIndex, TSpec> &)
	{
		return true;
	}

//____________________________________________________________________________

/**
.Function.goRoot:
..summary:Move iterator to the root node.
..cat:Index
..signature:goRoot(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..include:seqan/index.h
..example
...text:The following code shows a simple example how the @Function.range@ is used.
...file:demos/index/index_begin_range_goDown_representative_repLength.cpp
...output:The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
*/
/*!
 * @fn VSTreeIterator#goRoot
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Move iterator to the root node.
 * 
 * @signature void goRoot(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 */

	template < typename TText, typename TIndexSpec, class TSpec >
	inline void goRoot(Iter<Index<TText, TIndexSpec>, VSTree<TSpec> > &it) 
	{
		_historyClear(it);
		clear(it);							// start in root node with range (0,infty)
		if (!empty(indexSA(container(it))))
            _setSizeInval(value(it).range.i2);	// infty is equivalent to length(index) and faster to compare
	}

//____________________________________________________________________________

/**
.Function.Index#begin
..summary:Returns an iterator pointing to the root node of the virtual string tree/trie of an index. The only exception are @Tag.DFS Order.Postorder@ iterators, where begin returns an iterator pointing to the leftmost node in the tree/trie.
..signature:begin(index, tag)
..class:Class.Index
..param.index:The index to be traversed
...type:Spec.IndexEsa
...type:Spec.IndexDfi
...type:Spec.IndexWotd
...type:Spec.FMIndex
...type:Spec.IndexSa
..param.tag:The specialisation of the iterator to be returned by the function.
...type:Spec.VSTree Iterator
..returns:Returns an iterator pointing to the root not of the virtual suffix tree of the index.
...type:nolink:$The result of Iterator<Index<TText, TIndexSpec>, TSpec >::Type$
..example
...text:The following example shows the usage of the @Function.begin@ function. Note that in the first case @Function.begin@ returns an iterator pointing to the root node, while in the second case @Function.begin@ returns a pointer to the left most node.
...file:demos/index/index_begin_atEnd_representative.cpp
...output:
A
AA
ATAA
TA
TAA
TATAA
--------------------------------
AA
ATAA
A
TAA
TATAA
TA

*/
//TODO(singer): The summary is not entirely true!!!
/*!
 * @fn Index#begin
 * 
 * @brief Returns an iterator pointing to the root not of the virtual suffix tree of the index.
 * 
 * @signature TIterator begin(index, tag)
 * 
 * @param index The index to be traversed. Types: @link IndexEsa @endlink, @link IndexDfi @endlink, @link IndexWotd
 *              @endlink, @link FMIndex @endlink
 * @param tag The specialisation of the iterator to be returned by the function.
 *            Types: @link VSTreeIterator @endlink
 * 
 * @return TIterator Returns an iterator pointing to the root not of the virtual string tree of the index. The type is
 * the result of Iterator<Index<TText, TIndexSpec>, TSpec >::Type
 * @section Example
 * 
 * The following example shows the usage of the @Function.begin@ function. Note that in the first case @Function.begin@
 * returns an iterator pointing to the root node, while in the second case @Function.begin@ returns a pointer to the
 * left most node.
 * @include demos/index/index_begin_atEnd_representative.cpp
 * @code{.txt}
 * A
 * AA
 * ATAA
 * TA
 * TAA
 * TATAA
 * --------------------------------
 * AA
 * ATAA
 * A
 * TAA
 * TATAA
 * TA
 * 
 * @endcode
 */
	template < typename TText, typename TIndexSpec, class TSpec >
	inline typename Iterator<Index<TText, TIndexSpec>, TSpec >::Type
	begin(Index<TText, TIndexSpec> &index, TSpec const)
	{
		typedef Iter<Index<TText, TIndexSpec>, VSTree<TSpec> >	TIter;
		typedef typename GetVSTreeIteratorTraits<TIter>::Type	TTraits;

        typename Iterator<Index<TText, TIndexSpec>, TSpec>::Type it(index);

        if (IsSameType<typename TTraits::DfsOrder, Postorder_>::VALUE) {
            while (goDown(it)) ;
        }

		return it;
	}

	template < typename TText, typename TIndexSpec, class TSpec >
    inline typename Iterator<Index<TText, TIndexSpec>, BottomUp<TSpec> >::Type
    begin(Index<TText, TIndexSpec> &index, BottomUp<TSpec> const)
    {
        return typename Iterator<Index<TText, TIndexSpec>, BottomUp<TSpec> >::Type(index);
    }

///.Function.goBegin.param.iterator.type:Spec.BottomUp Iterator
///.Function.goBegin.class:Spec.BottomUp Iterator
///.Function.goBegin.param.iterator.type:Spec.TopDownHistory Iterator
///.Function.goBegin.class:Spec.TopDownHistory Iterator
	template < typename TText, typename TIndexSpec, class TSpec >
	inline void goBegin(Iter<Index<TText, TIndexSpec>, VSTree<TSpec> > &it) 
	{
		typedef Iter<Index<TText, TIndexSpec>, VSTree<TSpec> >	TIter;
		typedef typename GetVSTreeIteratorTraits<TIter>::Type	TTraits;
		typedef typename TTraits::HideEmptyEdges				THideEmptyEdges;

		goRoot(it);

		if (IsSameType<typename TTraits::DfsOrder, Postorder_>::VALUE) {
			while (goDown(it)) ;
			return;
		}

		// if root doesn't suffice predicate, do a dfs-step
		if ((THideEmptyEdges::VALUE && emptyParentEdge(it)) || !nodeHullPredicate(it))
			goNext(it);
	}

	template < typename TText, typename TIndexSpec, class TSpec >
	inline void goBegin(Iter<Index<TText, IndexEsa<TIndexSpec> >, VSTree< BottomUp<TSpec> > > &it) 
	{
		typedef Index<TText, IndexEsa<TIndexSpec> >		TIndex;
		typedef Iter<TIndex, VSTree< BottomUp<TSpec> > >	TIter;
		//typedef typename VertexDescriptor<TIndex>::Type		TVertexDesc;
		typedef typename Size<TIndex>::Type					TSize;
		typedef	Pair<TSize>									TStackEntry;

		_dfsClear(it);
		clear(it);							// start in root node with range (0,infty)
		if (!empty(indexSA(container(it)))) {
			_dfsOnPush(it, TStackEntry(0,0));
			goNextImpl(it, typename GetVSTreeIteratorTraits< TIter >::Type());
		}
	}

//____________________________________________________________________________

///.Function.end.param.object.type:Class.Index
///.Function.end.class:Class.Index
	template < typename TText, typename TIndexSpec, class TSpec >
	inline typename Iterator<Index<TText, TIndexSpec>, TSpec >::Type
	end(Index<TText, TIndexSpec> &index, TSpec const) 
	{
		return typename Iterator< 
			Index<TText, TIndexSpec>, 
			TSpec
		>::Type (index, MinimalCtor());
	}

///.Function.goEnd.param.iterator.type:Spec.BottomUp Iterator
///.Function.goEnd.class:Spec.BottomUp Iterator
///.Function.goEnd.param.iterator.type:Spec.TopDownHistory Iterator
///.Function.goEnd.class:Spec.TopDownHistory Iterator
	template < typename TText, typename TIndexSpec, class TSpec >
	inline void goEnd(Iter<Index<TText, IndexEsa<TIndexSpec> >, VSTree<TSpec> > &it) 
	{
		_historyClear(it);
		clear(it);
	}

	template < typename TText, typename TIndexSpec, class TSpec >
	inline void goEnd(Iter<Index<TText, IndexEsa<TIndexSpec> >, VSTree< BottomUp<TSpec> > > &it) 
	{
		_dfsClear(it);
		clear(it);
	}

//____________________________________________________________________________

///.Function.goNext.param.iterator.type:Spec.BottomUp Iterator
///.Function.goNext.class:Spec.BottomUp Iterator
///.Function.goNext.param.iterator.type:Spec.TopDownHistory Iterator
///.Function.goNext.class:Spec.TopDownHistory Iterator

	template < typename TIndex, typename TSpec >
	inline void goNext(Iter<TIndex, VSTree<TSpec> > &it) {
		goNext(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree<TSpec> > >::Type());
	}

	template < typename TIndex, typename TSpec, typename TTraits >
	inline void goNext(Iter<TIndex, VSTree<TSpec> > &it, TTraits const traits) {
		goNextImpl(it, traits);
	}

	template < typename TIndex, typename TSpec >
	inline void goNextRight(Iter<TIndex, VSTree<TSpec> > &it) {
		goNextRight(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree<TSpec> > >::Type());
	}

	template < typename TIndex, typename TSpec, typename TTraits >
	inline void goNextRight(Iter<TIndex, VSTree<TSpec> > &it, TTraits const traits) {
		goNextRightImpl(it, traits);
	}

	template < typename TIndex, typename TSpec >
	inline void goNextUp(Iter<TIndex, VSTree<TSpec> > &it) {
		goNextUp(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree<TSpec> > >::Type());
	}

	template < typename TIndex, typename TSpec, typename TTraits >
	inline void goNextUp(Iter<TIndex, VSTree<TSpec> > &it, TTraits const traits) {
		goNextUpImpl(it, traits);
	}


/**
.Function.goDown:
..summary:Iterates down one edge or a path in a tree.
..cat:Index
..signature:bool goDown(iterator)
..signature:bool goDown(iterator, char)
..signature:bool goDown(iterator, text[, lcp])
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..param.char:$iterator$ goes down the edge beginning with $char$.
..param.text:$iterator$ goes down the path representing $text$. If $text$ ends within an edge, $iterator$ will point to the child-end of this edge.
..param.lcp:A reference of a size type. When $goDown$ returns, $lcp$ contains the length of the longest-common-prefix of $text$ and a path beginning at the $iterator$ node.
...type:Class.String
...type:Class.Segment
..remarks:$goDown(iterator)$ goes down the leftmost edge in the suffix tree, i.e. the edge beginning with the lexicographically smallest character.
..returns:$true$ if the edge or path to go down exists, otherwise $false$.
...type:nolink:bool
..include:seqan/index.h
..example
...text:The following code shows a simple example how the function @Function.goDown@ is used.
...file:demos/index/index_begin_range_goDown_representative_repLength.cpp
...output:The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
*/
//TODO(singer): The lcp stuff need to be adapted
/*!
 * @fn TopDownIterator#goDown
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Iterates down one edge or a path in a tree.
 * 
 * @signature bool goDown(iterator)
 * @signature bool goDown(iterator, char)
 * @signature bool goDown(iterator, text[, lcp])
 * 
 * @param char <tt>iterator</tt> goes down the edge beginning with <tt>char</tt>.
 * @param text <tt>iterator</tt> goes down the path representing <tt>text</tt>.  If <tt>text</tt> ends within an edge,
 *             <tt>iterator</tt> will point to the child-end of this edge.
 * @param lcp A reference of a size type. When <tt>goDown</tt> returns, <tt>lcp</tt> contains the length of the
 *            longest-common-prefix of <tt>text</tt> and a path beginning at the <tt>iterator</tt> node.  Types: String, Segment
 * @param iterator An iterator of a tree. Types: @link TopDownIterator @endlink, @link RightArrayBinaryTreeIterator
 *        @endlink
 * 
 * @return TReturn <tt>true</tt> if the edge or path to go down exists, otherwise <tt>false</tt>.
 * 
 * @section Remarks
 * 
 * <tt>goDown(iterator)</tt> goes down the leftmost edge in the tree, i.e. the edge beginning with the lexicographically
 * smallest character.
 * 
 * @section Example
 *
 * The following code shows a simple example how the function @link goDown @endlink is used.
 * @include demos/index/index_begin_range_goDown_representative_repLength.cpp
 * @code{.txt}
 * The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
 * The string ISSI occurs 2 times in MISSISSIPPI and has 4 characters.
 * @endcode
 */
    //////////////////////////////////////////////////////////////////////////////
	// unified history stack access for goDown(..)

	template < typename TIndex, class TSpec >
	inline void 
	_historyClear(Iter< TIndex, VSTree<TSpec> > &) {}


    template < typename TIndex, class TSpec >
    inline void
    _historyClear(Iter< TIndex, VSTree< TopDown<TSpec> > > &it)
    {
        it._parentDesc = value(it);
    }

    template < typename TIndex, class TSpec >
    inline void
    _historyClear(Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it)
    {
        clear(it.history);
    }
/*
	template < typename TText, class TIndexSpec, class TSpec >
	inline void 
	_historyPush(Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree<TSpec> > &it) 
	{
		value(it).parentRight = value(it).range.i2;
	}
*/	template < typename TText, class TIndexSpec, class TSpec >
	inline void 
	_historyPush(Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown<TSpec> > > &it) 
	{
		it._parentDesc = value(it);
		value(it).parentRight = value(it).range.i2;
	}
	template < typename TText, class TIndexSpec, class TSpec >
	inline void 
	_historyPush(Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown< ParentLinks<TSpec> > > > &it) 
	{
		typedef Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown< ParentLinks<TSpec> > > > TIter;
		typename HistoryStackEntry_<TIter>::Type h;
		h.range = value(it).range;

		value(it).parentRight = value(it).range.i2;
		appendValue(it.history, h);
	}


	// standard down/right/up handlers of top-down-traversal
	template < typename TIndex, typename TSpec >
	inline void _onGoDown(Iter<TIndex, VSTree< TopDown<TSpec> > > &) {}

	template < typename TIndex, typename TSpec >
	inline void _onGoRight(Iter<TIndex, VSTree< TopDown<TSpec> > > &) {}

	template < typename TIndex, typename TSpec >
	inline void _onGoUp(Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &) {}


    //////////////////////////////////////////////////////////////////////////////
	// goDown

	// go down the leftmost edge (including empty $-edges)
	template < typename TText, class TIndexSpec, class TSpec, typename TDfsOrder >
	inline bool _goDown(
		Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown<TSpec> > > &it,
		VSTreeIteratorTraits<TDfsOrder, False> const)
	{
		typedef Index<TText, IndexEsa<TIndexSpec> >	TIndex;

		if (_isLeaf(it, EmptyEdges())) return false;
		_historyPush(it);

		TIndex const &index = container(it);

		typename Size<TIndex>::Type lval = _getUp(value(it).range.i2, index);
		if (!(value(it).range.i1 < lval && lval < value(it).range.i2))
			lval = _getDown(value(it).range.i1, index);
		value(it).range.i2 = lval;
		return true;
	}

    template <typename TIterator>
    struct IsParentLinks_: public False {};

    template <typename TIndex, typename TSpec>
    struct IsParentLinks_< Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > >: public True {};

    
    template <typename TIndex, typename TSpec, typename TVertexDesc>
    inline void
    _setParentNodeDescriptor(Iter<TIndex, VSTree< TopDown<TSpec> > > &it,
                             TVertexDesc const &desc)
    {
        it._parentDesc = desc;
    }

    template <typename TIndex, typename TSpec, typename TVertexDesc>
    inline void
    _setParentNodeDescriptor(Iter<TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &,
                             TVertexDesc const &)
    {
    }
    
	// go down the leftmost edge (skip empty $-edges)
	template < typename TText, class TIndexSpec, class TSpec, typename TDfsOrder >
	inline bool _goDown(
		Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown<TSpec> > > &it,
		VSTreeIteratorTraits<TDfsOrder, True> const)
	{
        typedef Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown<TSpec> > >   TIter;
		typedef Index<TText, IndexEsa<TIndexSpec> >                                     TIndex;
        typedef typename VertexDescriptor<TIndex>::Type                                 TVertexDesc;
		
		if (_isLeaf(it, HideEmptyEdges())) return false;

        // save parent descriptor if we need to restore it
        TVertexDesc oldParentDesc;
        if (!IsParentLinks_<TIter>::VALUE)
            oldParentDesc = nodeUp(it);

        _historyPush(it);

		TIndex const &index = container(it);

        typename Size<TIndex>::Type rangeLeft = value(it).range.i1;
		typename Size<TIndex>::Type lval = _getUp(value(it).range.i2, index);
		if (!(rangeLeft < lval && lval < value(it).range.i2))
			lval = _getDown(rangeLeft, index);

        // skip the all empty edges
		typename Size<TIndex>::Type lcp = lcpAt(lval - 1, index);
        while (suffixLength(saAt(rangeLeft, index), index) <= lcp)
            ++rangeLeft;

        // if we skipped some empty edges, get the next l-value to set range.i2
        if (value(it).range.i1 != rangeLeft)
        {
            value(it).range.i1 = rangeLeft;
            if (_isNextl(rangeLeft, index))
				lval = _getNextl(rangeLeft, index);
			else
				lval = value(it).parentRight;
        }
        value(it).range.i2 = lval;

        if (!nodeHullPredicate(it))
        {
            if (!goRight(it))
            {
                _goUp(it);
                _setParentNodeDescriptor(it, oldParentDesc);
                return false;
            }
        }
		return true;
	}

	// go down the leftmost edge
	template < typename TIndex, class TSpec >
	inline bool goDown(Iter< TIndex, VSTree< TopDown<TSpec> > > &it) {
		if (_goDown(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree< TopDown<TSpec> > > >::Type())) {
			_onGoDown(it);
			return true;
		} else
			return false;
	}


    //////////////////////////////////////////////////////////////////////////////
	// goDown a specific edge (chosen by the first character)

	// go down the edge beginning with c (returns false iff this edge doesn't exists)
	template < typename TIndex, class TSpec, typename TValue >
	inline bool _goDownChar(Iter< TIndex, VSTree< TopDown<TSpec> > > &it, TValue c) 
	{
		typename VertexDescriptor<TIndex>::Type nodeDesc;
		if (_getNodeByChar(it, c, nodeDesc)) {
			_historyPush(it);
			value(it) = nodeDesc;
			return true;
		}
		return false;
	}

	// go down the path corresponding to pattern
	// lcp is the longest prefix of pattern and path
	template < typename TIndex, typename TSpec, typename TString, typename TSize >
	inline bool
	_goDownString(
		Iter< TIndex, VSTree< TopDown<TSpec> > > &node,
		TString const &pattern, 
		TSize &lcp) 
	{
		typedef typename Fibre<TIndex, FibreText>::Type const		TText;
		typedef typename Infix<TText>::Type							TInfix;
		typedef typename Iterator<TInfix, Standard>::Type			IText;
		typedef typename Iterator<TString const, Standard>::Type	IPattern;
		
		IPattern p_begin = begin(pattern, Standard()), p_end = end(pattern, Standard());
		IText t_begin, t_end;

		if (p_begin == p_end) {
			lcp = 0;
			return true;
		}

		TSize parentRepLen = repLength(node);
		// go down the edge beginning with a pattern character
		while (_goDownChar(node, *p_begin))
		{
			TInfix t = representative(node);
			t_begin = begin(t, Standard()) + parentRepLen;
			t_end = end(t, Standard());

			while (t_begin != t_end && p_begin != p_end) 
			{
				// compare each character along the edge
				if (*p_begin != *t_begin) {
					lcp = p_begin - begin(pattern, Standard());
					return false;
				}
				++t_begin;
				++p_begin;
			}

			// was the whole pattern found?
			if (p_begin == p_end) {
				lcp = length(pattern);
				return true;
			}
			parentRepLen = length(t);
		}
		lcp = p_begin - begin(pattern, Standard());
		return false;
	}

	template < typename TIndex, typename TSpec, typename TObject >
	inline bool 
	_goDownObject(
		Iter< TIndex, VSTree< TopDown<TSpec> > > &it, 
		TObject const &obj,
		False)
	{
		return _goDownChar(it, obj);
	}

	template < typename TIndex, typename TSpec, typename TObject >
	inline bool 
	_goDownObject(
		Iter< TIndex, VSTree< TopDown<TSpec> > > &it, 
		TObject const &obj,
		True)
	{
		typename Size<TIndex>::Type dummy;
		return _goDownString(it, obj, dummy);
	}


	// public interface for goDown(it, ...)
	template < typename TIndex, typename TSpec, typename TObject >
	inline bool
	goDown(
		Iter< TIndex, VSTree< TopDown<TSpec> > > &it, 
		TObject const &obj) 
	{
		return _goDownObject(it, obj, typename IsSequence<TObject>::Type());
	}

	template < typename TIndex, typename TSpec, typename TString, typename TSize >
	inline bool 
	goDown(
		Iter< TIndex, VSTree< TopDown<TSpec> > > &it, 
		TString const &pattern,
		TSize &lcp)
	{
		return _goDownString(it, pattern, lcp);
	}

		
/**
.Function.goUp:
..summary:Iterates up one edge to the parent in a tree.
..cat:Index
..signature:goUp(iterator)
..class:Spec.TopDownHistory Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDownHistory Iterator
..returns:$true$ if the iterator could be moved, otherwise $false$.
...type:nolink:bool
..include:seqan/index.h
..example
...text:The following code shows how the function @Function.goUp@ is used.
...file:demos/index/index_iterator.cpp
...output:be
beornottobe
e
eornottobe
nottobe
o
obe
obeornottobe
ornottobe
ottobe
rnottobe
t
tobe
tobeornottobe
ttobe
*/
/*!
 * @fn TopDownHistoryIterator#goUp
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Iterates up one edge to the parent in a tree/trie.
 * 
 * @signature bool goUp(iterator)
 * 
 * @param iterator An iterator of a string tree/trie.
 * 
 * @return bool <tt>true</tt> if the iterator could be moved, otherwise <tt>false</tt>.
 *
 * @section Example
 *
 * The following code shows how the function @link goUp @endlink is used.
 * @include demos/index/index_iterator.cpp
 * @code{.txt}
 * be
 * beornottobe
 * e
 * eornottobe
 * nottobe
 * o
 * obe
 * obeornottobe
 * ornottobe
 * ottobe
 * rnottobe
 * t
 * tobe
 * tobeornottobe
 * ttobe
 * 
 * @endcode
 */
	// go up one edge (returns false if in root node)
	// can be used at most once, as no history stack is available
	template < typename TIndex, class TSpec >
	inline bool 
	_goUp(Iter< TIndex, VSTree< TopDown<TSpec> > > &it) 
	{
		if (!isRoot(it)) {
			value(it) = it._parentDesc;
			return true;
		}
		return false;
	}

	// go up one edge (returns false if in root node)
	template < typename TIndex, class TSpec >
	inline bool 
	_goUp(Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it) 
	{
		if (!empty(it.history)) {
			value(it).range = back(it.history).range;
			pop(it.history);
			if (!empty(it.history))
				value(it).parentRight = back(it.history).range.i2;	// copy right boundary of parent's range
			return true;
		}
		return false;
	}

	// go up one edge
	template < typename TIndex, class TSpec >
	inline bool goUp(Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it) {
		if (_goUp(it)) {
			_onGoUp(it);
			return true;
		} else
			return false;
	}

/**
.Function.nodeUp:
..summary:Returns the vertex descriptor of the parent node.
..cat:Index
..signature:nodeUp(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:The vertex descriptor of the parent node. The type is $VertexDescriptor<TIndex>::Type$.
If $iterator$ points at the root node, the vertex descriptor of $iterator$ ($value(iterator)$) is returned.
...type:Metafunction.VertexDescriptor
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#nodeUp
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the vertex descriptor of the parent node.
 * 
 * @signature TVertexDiscriptor nodeUp(iterator)
 * 
 * @param iterator An iterator of a string tree/trie.
 * 
 * @return TReturn The vertex descriptor of the parent node. The type is @link VertexDescriptor @endlink of TIndex. If
 *                 <tt>iterator</tt> points at the root node, the vertex descriptor of it is returned.
 */

	// return vertex descriptor of parent's node
	template < typename TIndex, class TSpec >
	inline typename VertexDescriptor<TIndex>::Type
	nodeUp(Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > const &it) 
	{
		if (!empty(it.history))
        {
			typename Size<TIndex>::Type parentRight = 0;
			if (length(it.history) >= 2)
				parentRight = topPrev(it.history).range.i2;
			return typename VertexDescriptor<TIndex>::Type(back(it.history).range, parentRight);
		} else
			return value(it);
	}

	// nodeUp adaption for non-history iterators
	// ATTENTION: Do not call nodeUp after a goDown that returned false (or after _goUp)!
	template < typename TIndex, class TSpec >
	inline typename VertexDescriptor<TIndex>::Type const &
	nodeUp(Iter< TIndex, VSTree< TopDown<TSpec> > > const &it) 
	{
		return it._parentDesc;
	}

/**
.Function.goRight:
..summary:Iterates to the next sibling in a tree.
..cat:Index
..signature:goRight(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:$true$ if the iterator could be moved, otherwise $false$.
...type:nolink:bool
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#goRight
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Iterates to the next sibling in a tree.
 * 
 * @signature bool goRight(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return bool <tt>true</tt> if the iterator could be moved, otherwise <tt>false</tt>.
 */
	// go right to the lexic. next sibling
	template < typename TText, class TIndexSpec, class TSpec, typename TDfsOrder, typename THideEmptyEdges >
	inline bool _goRight(
		Iter< Index<TText, IndexEsa<TIndexSpec> >, VSTree< TopDown<TSpec> > > &it, 
		VSTreeIteratorTraits<TDfsOrder, THideEmptyEdges> const) 
	{
		typedef Index<TText, IndexEsa<TIndexSpec> > TIndex;

		if (isRoot(it)) return false;		

		typename Size<TIndex>::Type right = value(it).parentRight;
		if (_isSizeInval(right)) right = length(indexSA(container(it)));

		do {
			if (value(it).range.i2 == right)				// not the right-most child?
				return false;

			if (_isNextl(value(it).range.i2, container(it))) 
			{
				value(it).range.i1 = value(it).range.i2;	// go right
				value(it).range.i2 = _getNextl(value(it).range.i2, container(it));
			} else {
				value(it).range.i1 = value(it).range.i2;	// now it is the right-most child
				value(it).range.i2 = value(it).parentRight;
			}

		} while ((THideEmptyEdges::VALUE && emptyParentEdge(it)) || !nodeHullPredicate(it));
		return true;
	}

	// go down the leftmost edge
	template < typename TIndex, class TSpec >
	inline bool goRight(Iter< TIndex, VSTree< TopDown<TSpec> > > &it) {
		if (_goRight(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree< TopDown<TSpec> > > >::Type())) {
			_onGoRight(it);
			return true;
		} else
			return false;
	}

/**
.Function.parentEdgeLength:
..summary:Returns the length of the edge from the $iterator$ node to its parent.
..cat:Index
..signature:parentEdgeLength(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:The returned value is equal to $length(parentEdgeLabel(iterator))$.
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#parentEdgeLength
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the length of the edge from the <tt>iterator</tt> node to its parent.
 * 
 * @signature TSize parentEdgeLength(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TSize The returned value is equal to <tt>length(parentEdgeLabel(iterator))</tt> and its type is the result of
 *               the metafunction @link Size @endlink of the underlying index.
 */
	template < typename TIndex, class TSpec >
	inline typename Size< TIndex >::Type
	parentEdgeLength(Iter< TIndex, VSTree< TopDown<TSpec> > > const &it) 
	{
		return repLength(it) - parentRepLength(it);
	}

/**
.Function.parentEdgeLabel:
..summary:Returns a substring representing the edge from an $iterator$ node to its parent.
..cat:Index
..signature:parentEdgeLabel(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:An @Spec.InfixSegment@ of the text of an index (see @Tag.ESA Index Fibres.EsaText@).
If $iterator$'s container type is $TIndex$ the return type is $Infix<Fibre<TIndex, EsaText>::Type const>::Type$.
..include:seqan/index.h
*/
/*!
 * @fn TopDownIterator#parentEdgeLabel
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns a substring representing the edge from an <tt>iterator</tt> node to its parent.
 * 
 * @signature TEdgeLabel parentEdgeLabel(iterator)
 * 
 * @param iterator An iterator of a string tree/trie.
 * 
 * @return TEdgeLabel Returns a substring representing the edge from an <tt>iterator</tt> node to its parent.
 *                    and its type is the result of the metafunction @link EdgeLabel @endlink of the iterator.
 */

	template < typename TIndex, class TSpec >
    inline typename EdgeLabel< Iter< TIndex, VSTree<TSpec> > >::Type
	parentEdgeLabel(Iter< TIndex, VSTree< TopDown<TSpec> > > const &it)
	{
		return infixWithLength(
			indexText(container(it)), 
			posAdd(getOccurrence(it), parentRepLength(it)),
			parentEdgeLength(it));
	}

/**
.Function.parentEdgeFirstChar:
..summary:Returns the first character of the edge from an $iterator$ node to its parent.
..cat:Index
..signature:parentEdgeFirstChar(iterator)
..class:Spec.TopDown Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.TopDown Iterator
..returns:A single character of type $Value<TIndex>::Type$ which is identical to $Value<Fibre<TIndex, EsaRawText>::Type>::Type$.
..include:seqan/index.h
*/
//TODO(singer): EsaRawText
/*!
 * @fn TopDownIterator#parentEdgeFirstChar
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the first character of the edge from an <tt>iterator</tt> node to its parent.
 * 
 * @signature TValue parentEdgeFirstChar(iterator)
 * 
 * @param iterator An iterator of a string tree.
 * 
 * @return TValue A single character of type <tt>Value&lt;TIndex&gt;::Type</tt> which is identical to
 *                 <tt>Value&lt;Fibre&lt;TIndex, EsaRawText&gt;::Type&gt;::Type</tt>.
 */

	template < typename TIndex, class TSpec >
	inline typename Value<TIndex>::Type 
	parentEdgeFirstChar(Iter< TIndex, VSTree<TSpec> > const &it) 
	{
		return infixWithLength(
			indexText(container(it)),
			posAdd(getOccurrence(it), parentRepLength(it)),
			1)[0];
	}

    template < typename TIndex, class TSpec >
	inline void _clear(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		value(it) = typename VertexDescriptor<TIndex>::Type(MinimalCtor());
    }

	template < typename TIndex, class TSpec >
	inline void clear(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		_clear(it);
    }

	template < typename TIndex, class TSpec >
	inline void _dfsClear(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		clear(it.history);
    }


    //////////////////////////////////////////////////////////////////////////////
	// dfs traversal for ParentLink iterators

	template < typename TIndex, typename TSpec, typename THideEmptyEdges >
	inline void goNextImpl(
		Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it, 
		VSTreeIteratorTraits<Preorder_, THideEmptyEdges> const)
	{
		// preorder dfs
		do {
			if (!goDown(it) && !goRight(it))
				while (goUp(it) && !goRight(it)) {}
			if (isRoot(it)) {
				clear(it);
				return;
			}
		} while (!nodePredicate(it));
	}

	template < typename TIndex, typename TSpec, typename THideEmptyEdges >
    inline void goNextRightImpl(
		Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it, 
		VSTreeIteratorTraits<Preorder_, THideEmptyEdges> const tag)
    {
        // preorder dfs
        if (!goRight(it))
            while (goUp(it) && !goRight(it)) {}
        if (isRoot(it)) {
            clear(it);
            return;
        }
        if (!nodePredicate(it))
            goNextImpl(it, tag);
    }

	template < typename TIndex, typename TSpec, typename THideEmptyEdges >
    inline void goNextUpImpl(
		Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it, 
		VSTreeIteratorTraits<Preorder_, THideEmptyEdges> const tag)
    {
        // preorder dfs
        while (goUp(it) && !goRight(it)) {}
        if (isRoot(it)) {
            clear(it);
            return;
        }
        if (!nodePredicate(it))
            goNextImpl(it, tag);
    }




	template < typename TIndex, typename TSpec, typename THideEmptyEdges >
	inline void goNextImpl(
		Iter< TIndex, VSTree< TopDown< ParentLinks<TSpec> > > > &it, 
		VSTreeIteratorTraits<Postorder_, THideEmptyEdges> const)
	{
		// postorder dfs
		do {
			if (goRight(it))
				while (goDown(it)) ;
			else
				if (!goUp(it)) {
					clear(it);
					return;
				}
		} while (!nodePredicate(it));
	}

    //////////////////////////////////////////////////////////////////////////////
	// boolean functions

	template < typename TIndex, class TSpec >
	inline bool eof(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		return !value(it).range.i2;
	}

	template < typename TIndex, class TSpec >
	inline bool eof(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		return !value(it).range.i2;
	}

	template < typename TIndex, class TSpec >
	inline bool empty(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		return !value(it).range.i2;
	}

	template < typename TIndex, class TSpec >
	inline bool empty(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		return !value(it).range.i2;
	}

//..concept:Concept.ContainerConcept
/**
.Function.VSTree Iterator#atEnd
..class:Spec.VSTree Iterator
..concept:Concept.RootedIteratorConcept
..cat:Iteration
..summary:Determines whether an virtual string tree iterator is at the end position.
..signature:bool atEnd(iterator)
..param.iterator:An iterator.
...type:Spec.BottomUp Iterator
...type:Spec.TopDownHistory Iterator
...concept:Concept.RootedIteratorConcept
..returns:$true$ if $iterator$ points behind the last item of the container, otherwise $false$.
..include:seqan/index.h
..example
...text:The following example shows the usage of the @Function.atEnd@ function. 
...file:demos/index/index_begin_atEnd_representative.cpp
...output:
A
AA
ATAA
TA
TAA
TATAA
--------------------------------
AA
ATAA
A
TAA
TATAA
TA

*/

/*!
 * @fn VSTreeIterator#atEnd
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Determines whether an virtual string tree iterator is at the end position.
 * 
 * @signature bool atEnd(iterator)
 * 
 * @param iterator An iterator.
 * 
 * @return TReturn <tt>true</tt> if <tt>iterator</tt> points behind the last item of the container, otherwise
 *                 <tt>false</tt>.
 * 
 * @section Examples
 * 
 * The following example shows the usage of the @link atEnd @endlink function.
 * @include demos/index/index_begin_atEnd_representative.cpp
 * @code{.txt}
 * A 
 * AA
 * ATAA
 * TA
 * TAA
 * TATAA
 * --------------------------------
 * AA
 * ATAA
 * A
 * TAA
 * TATAA
 * TA
 *
 */

///.Function.atEnd.param.iterator.type:Spec.BottomUp Iterator
///.Function.atEnd.class:Spec.BottomUp Iterator
///.Function.atEnd.param.iterator.type:Spec.TopDownHistory Iterator
///.Function.atEnd.class:Spec.TopDownHistory Iterator

	template < typename TIndex, class TSpec >
	inline bool atEnd(Iter<TIndex, VSTree<TSpec> > &it) 
	{
		return !value(it).range.i2;
	}

	template < typename TIndex, class TSpec >
	inline bool atEnd(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		return !value(it).range.i2;
	}

/**
.Function.isRoot:
..summary:Test whether a tree iterator points to the root node.
..cat:Index
..signature:bool isRoot(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a tree.
...type:Spec.VSTree Iterator
..returns:$true$ if $iterator$ points to the root of the tree, otherwise $false$.
...type:nolink:bool
..include:seqan/index.h
..example
...text:The following example shows the usage of the @Function.isRoot@ function. 
...file:demos/index/index_begin_atEnd_representative_bottomUp.cpp
...output:AA
ATAA
A
TAA
TATAA
TA
*/
/*!
 * @fn VSTreeIterator#isRoot
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether a tree iterator points to the root node.
 * 
 * @signature bool isRoot(iterator)
 * 
 * @param iterator An iterator of a tree.
 * 
 * @return TReturn <tt>true</tt> if <tt>iterator</tt> points to the root of the tree, otherwise <tt>false</tt>.
 * @section Example
 *
 * The following example shows the usage of the @Function.isRoot@ function. 
 * @include demos/index/index_begin_atEnd_representative_bottomUp.cpp
 * code{.txt}
 * output:AA
 * ATAA
 * A
 * TAA
 * TATAA
 * TA
 * @endcode
 */
	template < typename TIndex, class TSpec >
	inline bool isRoot(Iter<TIndex, VSTree< BottomUp<TSpec> > > const &it) 
	{
		return empty(it.history);
	}

	template < typename TIndex, class TSpec >
	inline bool isRoot(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		return _isRoot(value(it));
	}

	template < typename TSize >
	inline bool _isRoot(VertexEsa<TSize> const &value) 
	{
//IOREV _notio_
		return _isSizeInval(value.range.i2);
	}

/**
.Function.isRightTerminal:
..summary:Test whether iterator points to a suffix.
..cat:Index
..signature:bool isRightTerminal(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:$true$ if $iterator$ points to the node representing a suffix, otherwise $false$.
...type:nolink:bool
..remarks:Every leaf is also a right terminal (see @Function.isLeaf@), but not vice versa.
..include:seqan/index.h
*/
//TODO(singer): Note the case for trie or FM Index
/*!
 * @fn VSTreeIterator#isRightTerminal
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether iterator points to a suffix.
 * 
 * @signature bool isRightTerminal(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn <tt>true</tt> if <tt>iterator</tt> points to the node representing a suffix, otherwise
 *                 <tt>false</tt>. Types: <tt>bool<tt>
 * 
 * @section Remarks
 * 
 * Every leaf is also a right terminal (see @link isLeaf @endlink), but not vice versa.
 */

	template < typename TIndex, class TSpec >
	inline bool isRightTerminal(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		// do we reach a leaf in a suffix tree with trailing '$'
		typename SAValue<TIndex>::Type pos = getOccurrence(it);
		TIndex const &index = container(it);
		typename StringSetLimits<typename Host<TIndex>::Type const>::Type &limits = stringSetLimits(index);

		return (getSeqOffset(pos, limits) + repLength(it) 
			== sequenceLength(getSeqNo(pos, limits), index));
	}

/**
.Function.isLeftMaximal:
..summary:Test whether the occurrences of an iterator's @Function.representative@ mutually differ in the character left of the hits.
..cat:Index
..signature:bool isLeftMaximal(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:$true$ if there are at least two different characters left of the occurrences, otherwise $false$.
...type:nolink:bool
..see:Function.getOccurrences
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#isLeftMaximal
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether the occurrences of an iterator's @link representative @endlink mutually differ in the character
 *        left of the hits.
 * 
 * @signature bool isLeftMaximal(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn <tt>true</tt> if there are at least two different characters left of the occurrences, otherwise
 *                 <tt>false</tt>. Types: <tt>bool<tt>
 * 
 * @see getOccurrences
 */

	template < typename TIndex, class TSpec >
	inline bool isLeftMaximal(Iter<TIndex, VSTree<TSpec> > const &it)
	{
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type	TOccs;
		typedef typename Infix< typename Fibre<TIndex, EsaBwt>::Type const >::Type	TOccsBWT;
		typedef typename Value< typename Fibre<TIndex, EsaBwt>::Type const >::Type	TValue;

		typedef typename Iterator<TOccs, Standard>::Type	TIter;
		typedef typename Iterator<TOccsBWT, Standard>::Type TIterBWT;
		
		TIndex const &index = container(it);
		typename StringSetLimits<typename Host<TIndex>::Type const>::Type &limits = stringSetLimits(index);

		TOccs occs = getOccurrences(it);
		TOccsBWT bwts = getOccurrencesBwt(it);

		TIter oc = begin(occs, Standard()), ocEnd = end(occs, Standard());
		TIterBWT bw = begin(bwts, Standard());

		if (oc == ocEnd) return true;
		if (posAtFirstLocal(*oc, limits)) return true;

		TValue seen = *bw;
		++oc; 
		++bw;
		if (oc == ocEnd) return true;

		do {
			if (posAtFirstLocal(*oc, limits)) return true;
			if (seen != *bw) return true;
			++oc;
			++bw;
		} while (oc != ocEnd);

		return false;
	}

/**
.Function.isPartiallyLeftExtensible:
..summary:Test whether the characters left of the two occurrences of @Function.representative@ are equal.
..cat:Index
..signature:bool isPartiallyLeftExtensible(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:$true$ if there are at least two different characters left of the occurrences, otherwise $false$.
..see:Function.getOccurrences
..include:seqan/index.h
*/
/*!
 * @fn VSTree Iterator#isPartiallyLeftExtensible
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether the characters left of the two occurrences of @link representative @endlink are equal.
 * 
 * @signature bool isPartiallyLeftExtensible(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn <tt>true</tt> if there are at least two different characters left of the occurrences, otherwise
 *                 <tt>false</tt>.
 * 
 * @see getOccurrences
 */
	template < typename TIndex, class TSpec, typename TSet >
	inline bool isPartiallyLeftExtensible(Iter<TIndex, VSTree<TSpec> > const &it, TSet &charSet)
	{
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type	TOccs;
		typedef typename Infix< typename Fibre<TIndex, EsaBwt>::Type const >::Type	TOccsBWT;
		typedef typename Value< typename Fibre<TIndex, EsaBwt>::Type const >::Type	TValue;

		typedef typename Iterator<TOccs, Standard>::Type	TIter;
		typedef typename Iterator<TOccsBWT, Standard>::Type TIterBWT;
		
		TIndex const &index = container(it);
		typename StringSetLimits<typename Host<TIndex>::Type const>::Type &limits = stringSetLimits(index);

		clear(charSet);

		TOccs occs = getOccurrences(it);
		TOccsBWT bwts = getOccurrencesBwt(it);

		TIter oc = begin(occs, Standard()), ocEnd = end(occs, Standard());
		TIterBWT bw = begin(bwts, Standard());

		while (oc != ocEnd) {
			if (!posAtFirstLocal(*oc, limits)) {
				TValue c = *bw;
				if (in(c, charSet)) return true;
				insert(c, charSet);
			}
			++oc;
			++bw;
		}

		return false;
	}

	template < typename TIndex, class TSpec >
	inline bool isPartiallyLeftExtensible(Iter<TIndex, VSTree<TSpec> > const &it)
	{
		typename Set<typename Value<TIndex>::Type>::Type set;
		return isPartiallyLeftExtensible(it, set);
	}

/**
.Function.isUnique:
..summary:Test whether the @Function.representative@ occurs only once in every sequence.
..cat:Index
..signature:bool isUnique(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:$true$ if there are at least two different characters left of the occurrences, otherwise $false$.
...type:nolink:bool
..see:Function.getOccurrences
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#isUnique
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether the @link representative @endlink occurs only once in every sequence.
 * 
 * @signature bool isUnique(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn <tt>true</tt> if there are at least two different characters left of the occurrences, otherwise
 *                 <tt>false</tt>. Types: <tt> bool <tt>
 * 
 * @see getOccurrences
 */

	template < typename TIndex, class TSpec, typename TSet >
	inline bool isUnique(Iter<TIndex, VSTree<TSpec> > const &it, TSet &set)
	{
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type TOccs;
		typedef typename Iterator<TOccs, Standard>::Type TIter;
		typedef typename Size<TIndex>::Type TSize;

		TIndex const &index = container(it);

		clear(set);

		TOccs occs = getOccurrences(it);
		TIter oc = begin(occs, Standard()), ocEnd = end(occs, Standard());

		while (oc != ocEnd) {
			TSize seqNo = getSeqNo(*oc, stringSetLimits(index));
			if (in(seqNo, set)) return false;
			insert(seqNo, set);
			++oc;
		}

		return true;
	}

	template < typename TIndex, class TSpec >
	inline bool isUnique(Iter<TIndex, VSTree<TSpec> > const &it) {
		VectorSet_<
			typename Size<TIndex>::Type,
			Alloc<> 
		> set(countSequences(container(it)));
		return isUnique(it, set);
	}

/**
.Function.getFrequency:
..summary:Returns the number of sequences, which contain the @Function.representative@ as a substring.
..cat:Index
..signature:int getFrequency(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:The number of different sequences containing the @Function.representative@.
..see:Function.getOccurrences
..include:seqan/index.h
..example
...text:The following code how @Function.getFrequency@ is used. Note that the result of alternative 1 and 2 is the same, however alternative one copies a string which requires more memory.
...file:demos/index/index_getOccurrences_getFrequency_range_getFibre.cpp
...output:SSI occurs in 2 sequences.
Hit in sequence 0 at position 5
Hit in sequence 1 at position 4
Hit in sequence 0 at position 2
----------------------------
Hit in sequence 0 at position 5
Hit in sequence 1 at position 4
Hit in sequence 0 at position 2
*/
/*!
 * @fn VSTreeIterator#getFrequency
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Returns the number of sequences, which contain the @link
 *        representative @endlink as a substring.
 * 
 * @signature int getFrequency(iterator)
 * 
 * @param iterator An iterator of a suffix tree. Types: @link VSTreeIterator @endlink
 * 
 * @return TReturn The number of different sequences containing the @link
 *                 representative @endlink.
 * @section Example
 *
 * The following code how @link getFrequency @endlink is used. Note that the result of alternative 1 and 2 is the same,
 * however alternative one copies a string which requires more memory.
 * @include demos/index/index_getOccurrences_getFrequency_range_getFibre.cpp
 * @code{.txt}
 * SSI occurs in 2 sequences.
 * Hit in sequence 0 at position 5
 * Hit in sequence 1 at position 4
 * Hit in sequence 0 at position 2
 * ----------------------------
 * Hit in sequence 0 at position 5
 * Hit in sequence 1 at position 4
 * Hit in sequence 0 at position 2
 * @endcode
 * @see getOccurrences
 */

	template < typename TIndex, class TSpec, typename TSet >
	inline typename Size<TIndex>::Type
	getFrequency(Iter<TIndex, VSTree<TSpec> > const &it, TSet &set)
	{
		typedef typename Infix< typename Fibre<TIndex, EsaSA>::Type const >::Type TOccs;
		typedef typename Iterator<TOccs, Standard>::Type TIter;
		typedef typename Size<TIndex>::Type TSize;

		TIndex const &index = container(it);

		clear(set);

		TOccs occs = getOccurrences(it);
		TIter oc = begin(occs, Standard()), ocEnd = end(occs, Standard());

		int counter = 0;
		while (oc != ocEnd) {
			TSize seqNo = getSeqNo(*oc, stringSetLimits(index));
			if (!in(seqNo, set)) {
				++counter;
				insert(seqNo, set);
			}
			++oc;
		}

		return counter;
	}

	template < typename TIndex, class TSpec >
	inline typename Size<TIndex>::Type
	getFrequency(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		VectorSet_<
			typename Size<TIndex>::Type,
			Alloc<> 
		> set(countSequences(container(it)));
		return getFrequency(it, set);
	}

/**
.Function.childrenAreLeaves:
..summary:Test whether iterator points to a node with only leaf-children.
..cat:Index
..signature:bool childrenAreLeaves(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a suffix tree.
...type:Spec.VSTree Iterator
..returns:$true$ if $iterator$ points to an inner node of the tree, whose children are leaves. Otherwise it is $false$.
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#childrenAreLeaves
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether iterator points to a node with only leaf-children.
 * 
 * @signature bool childrenAreLeaves(iterator)
 * 
 * @param iterator An iterator of a suffix tree.
 * 
 * @return TReturn <tt>true</tt> if <tt>iterator</tt> points to an inner node of the tree, whose children are leaves.
 *                 Otherwise it is <tt>false</tt>.
 */
	template < typename TIndex, class TSpec >
	inline bool childrenAreLeaves(Iter<TIndex, VSTree<TSpec> > const &it) 
	{
		return countChildren(it) == countOccurrences(it);
	}

/**
.Function.isLeaf:
..summary:Test whether a tree iterator points to a leaf.
..cat:Index
..signature:bool isLeaf(iterator)
..class:Spec.VSTree Iterator
..param.iterator:An iterator of a tree.
...type:Spec.VSTree Iterator
..returns:$true$ if $iterator$ points to a leaf of the tree, otherwise $false$.
...type:nolink:bool
..include:seqan/index.h
*/
/*!
 * @fn VSTreeIterator#isLeaf
 * 
 * @headerfile seqan/index.h
 * 
 * @brief Test whether a tree iterator points to a leaf.
 * 
 * @signature bool isLeaf(iterator)
 * 
 * @param iterator An iterator of a tree.
 * 
 * @return TReturn <tt>true</tt> if <tt>iterator</tt> points to a leaf of the tree, otherwise <tt>false</tt>.
 * 
 * @link DemoIndexCountChildren @endlink
 */
	template < typename TSize >
	inline bool _isLeaf(VertexEsa<TSize> const &vDesc)
	{
//IOREV _notio_
		// is this a leaf?
		return vDesc.range.i1 + 1 >= vDesc.range.i2;
	}

	// is this a leaf? (including empty $-edges)
	template < typename TIndex, class TSpec, typename TDfsOrder >
	inline bool _isLeaf(
		Iter<TIndex, VSTree<TSpec> > const &it,
		VSTreeIteratorTraits<TDfsOrder, False> const)
	{
		return _isLeaf(value(it));
	}


    template <typename TIndex, typename TSpec>
    inline typename SAValue<TIndex>::Type
    _lastOccurrence(Iter<TIndex, VSTree<TSpec> > const &it)
    {
		return back(getOccurrences(it));
    }

    template <typename TText, typename TIndexSpec, typename TSpec>
    inline typename SAValue<Index<TText, IndexEsa<TIndexSpec> > >::Type
    _lastOccurrence(Iter<Index<TText, IndexEsa<TIndexSpec> >, VSTree<TSpec> > const &it)
    {
        if (_isSizeInval(value(it).range.i2))
            return back(indexSA(container(it)));
        else
			return saAt(value(it).range.i2 - 1, container(it));
    }

	// is this a leaf? (hide empty $-edges)
	template < typename TIndex, class TSpec, typename TDfsOrder >
	inline bool _isLeaf(Iter<TIndex, VSTree<TSpec> > const &it, VSTreeIteratorTraits<TDfsOrder, True> const)
	{
        typedef typename SAValue<TIndex>::Type  TOcc;

		if (_isLeaf(value(it))) return true;

		TIndex const &index = container(it);

		// get representative length (see repLength)
		typename Size<TIndex>::Type lcp = repLength(it);
        
		// if the last suffix in the interval is larger than the lcp,
        // not all outgoing edges are empty (uses lex. sorting)
		TOcc oc = _lastOccurrence(it);
        return getSeqOffset(oc, stringSetLimits(index)) + lcp == sequenceLength(getSeqNo(oc, stringSetLimits(index)), index);
	}

	template < typename TIndex, class TSpec >
	inline bool isLeaf(Iter<TIndex, VSTree<TSpec> > const &it)
	{
		return _isLeaf(it, typename GetVSTreeIteratorTraits< Iter<TIndex, VSTree<TSpec> > >::Type());
	}

	//////////////////////////////////////////////////////////////////////////////
	// (more or less) internal functions for accessing the childtab

	template < typename TSize, typename TIndex >
	inline bool _isNextl(TSize i, TIndex const &index) 
	{
//IOREV _notio_
		if (i >= length(index)) return false;
		TSize j = childAt(i, index);
		return (j > i) && lcpAt(j - 1, index) == lcpAt(i - 1, index);
	}

	template < typename TSize, typename TIndex >
	inline bool _isUp(TSize i, TIndex const &index) 
	{
//IOREV _notio_
		if (i >= length(index)) return false;
		TSize j = childAt(i, index);
		return (j <= i) && lcpAt(j - 1, index) > lcpAt(i - 1, index);
	}

	template < typename TSize, typename TIndex >
	inline TSize _getNextl(TSize i, TIndex const &index) 
	{
		return childAt(i, index);
	}

	template < typename TSize, typename TIndex >
	inline TSize _getUp(TSize i, TIndex const &index) 
	{
		if (!_isSizeInval(i))
			return childAt(i - 1, index);
		else
			return childAt(0, index);
	}

	template < typename TSize, typename TIndex >
	inline TSize _getDown(TSize i, TIndex const &index) 
	{
		return childAt(i, index);
	}


	//////////////////////////////////////////////////////////////////////////////
	// depth-first search 

	template < typename TIndex, class TSpec >
	inline Pair<typename Size<TIndex>::Type> &
	_dfsRange(Iter< TIndex, VSTree< BottomUp<TSpec> > > &it)
	{
		return value(it).range;
	}

	template < typename TIndex, class TSpec >
	inline Pair<typename Size<TIndex>::Type> const & 
	_dfsRange(Iter< TIndex, VSTree< BottomUp<TSpec> > > const &it) 
	{
		return value(it).range;
	}

	template < typename TIndex, class TSpec >
	inline typename Size<TIndex>::Type & _dfsLcp(Iter< TIndex, VSTree< BottomUp<TSpec> > > &it)
	{
		return it.lValue;
	}

	template < typename TIndex, class TSpec >
	inline typename Size<TIndex>::Type _dfsLcp(Iter< TIndex, VSTree< BottomUp<TSpec> > > const &it)
	{
		return it.lValue;
	}


}

#endif
