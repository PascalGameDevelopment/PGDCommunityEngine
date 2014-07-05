(**
 * This file used internally.
 * Collection interface.
 * Collection is a group of elements. Can be ordered or not.
 * Elements can be accessed, inserted and removed by their position in the list (zero-based index).
 * Performance of the operations may vary and depends on implementation.
 *)

  // Returns the number of elements in the collection
  function GetCount(): __CollectionIndexType;
  // Returns True if the collection contains no elements
  function IsEmpty(): Boolean;
  // Returns True if the collection contains the specified element
  function Contains(const e: {$I _T.inc}): Boolean;
  // Calls the delegate for each element in the collection
  procedure ForEach(Delegate: {$I _Dg.inc}; Data: Pointer);
  {/ Ensures that the collection contains the specified element.
     Returns True if the element was successfully added or False if the collection
     already contains the element and duplicates are not allowed.
     Otherwise the method should raise an error. /}
  function Add(const e: {$I _T.inc}): Boolean;
  {/ Removes a single instance of the specified element from the collection.
     Returns True if the collection contained the element./}
  function Remove(const e: {$I _T.inc}): Boolean;
  // Removes all elements from the collection
  procedure Clear();

  // Number of elements in the collection
  property Count: __CollectionIndexType read GetCount;