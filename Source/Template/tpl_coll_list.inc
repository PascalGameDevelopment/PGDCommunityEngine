(*
 * List interface.
 * List is an ordered collection.
 * Elements can be accessed, inserted and removed by their position in the list (zero-based index).
 * Performance of the operations may vary and depends on implementation.
 *)

  {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating collection part of interface'}{$ENDIF}
  {$I tpl_coll_collection.inc}

  {/ Returns the element at the specified position in the list. 
     Throws an error on invalid index if dsRangeCheck was included in the list options before instantiation. }
  function Get(Index: __CollectionIndexType): {$I _T.inc};
  {/ Replaces the element at the specified position in the list with the specified element.
     Returns the element previously at the specified position.
     Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
  function Put(Index: __CollectionIndexType; const Value: {$I _T.inc}): {$I _T.inc};
  {/ Inserts the element at the specified position in the list shifting the element currently at that
     position (if any) and any subsequent elements to the right.
     Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
  procedure Insert(Index: __CollectionIndexType; const Value: {$I _T.inc});
  {/ Removes the element at the specified position in the list shifting any subsequent elements to the left.
     Returns the element that was removed from the list.
     Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
  function RemoveBy(Index: __CollectionIndexType): {$I _T.inc};
  {/ Returns the index of the first occurrence of the specified element in the list,
     or -1 if the list does not contain the element. }
  function IndexOf(const e: {$I _T.inc}): __CollectionIndexType;
  {/ Returns the index of the last occurrence of the specified element in the list,
     or -1 if the list does not contain the element. }
  function LastIndexOf(const e: {$I _T.inc}): __CollectionIndexType;

  // Values retrieved by index
  property Values[Index: __CollectionIndexType]: {$I _T.inc} read Get; default;

