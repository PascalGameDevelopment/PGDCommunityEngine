(*
  Template vector collection
  Interface part
  (C) George Bakhtadze
Usage:
  type
    _VectorValueType = <some type>;
    {$MESSAGE 'Instantiating TIntegerVector interface'}
    {$I tpl_coll_vector.inc}

    T<xxx>Vector = _GenVector;
    
  implementation

    // Optional equals function:
    [function _VectorEquals(v1, v2: _VectorValueType): Boolean;
    begin
      Result := v1 = v2;
    end;]

    // a compiler message with explanation which type is being instantiated would be very helpful:
    {$MESSAGE 'Instantiating TIntegerVector'}
    {$I tpl_coll_vector.inc}    
*)

{$IF Declared(_VectorOptions)}
  {$I tpl_coll_vector_opt.inc}
{$IFEND}

{$IFNDEF _VECTORIMPL}     // Interface

  {$IF not Declared(__CollectionIndexType)}
    __CollectionIndexType = Integer;
  {$IFEND}

  {$I _T.inc} = _VectorValueType;
  // Vector for each delegate
  _VectorDelegate = function(const e: _VectorValueType; Data: Pointer): Boolean of object;
  {$I _Dg.inc} = _VectorDelegate;
  _IGenVector = interface
    {$IFDEF TPL_HINTS}{$MESSAGE 'Instantiating _IGenVector interface for a template vector type'}{$ENDIF}
    {$I tpl_coll_list.inc}
  end;
  // Advance template type instance counter to reuse it in other template collection classes
  {$DEFINE _GEN_CNT_ADV}
  {$I _T.inc}

  // Generic vector template. Unit which use this inclde should use CETemplate unit also.
  _GenVector = class(CETemplate.TTemplateInterface, _IGenVector)
  {$IFDEF HAS_STRICT}strict{$ENDIF} protected
    // Values container
    FValues: array of _VectorValueType;
    // Current capacity of the vector
    FCapacity,
    // Number of entries
    FCount: __CollectionIndexType;
    procedure SetValue(Index: __CollectionIndexType; const e: _VectorValueType); {$I inline.inc}
    procedure SetCapacity(const ACapacity: __CollectionIndexType);
  public
    constructor Create(); overload;
    constructor Create(const Capacity: __CollectionIndexType); overload;
    constructor Create(const arr: array of _VectorValueType); overload;

    // Increases the capacity of the list to ensure that it can hold at least the number of elements specified
    procedure EnsureCapacity(ACount: __CollectionIndexType); {$I inline.inc}

    { Collection interface }

    // Returns the number of elements in the collection
    function GetCount(): __CollectionIndexType; {$I inline.inc}
    // Returns True if the collection contains no elements
    function IsEmpty(): Boolean; {$I inline.inc}
    // Returns True if the collection contains the specified element
    function Contains(const e: _VectorValueType): Boolean;
    // Calls the delegate for each element in the collection
    procedure ForEach(Delegate: _VectorDelegate; Data: Pointer);
    // Appends the element as the last element of the vector and returns True
    function Add(const e: _VectorValueType): Boolean; {$I inline.inc}
    {/ Removes the specified element from the collection.
       Returns True if the collection contained the element./}
    function Remove(const e: _VectorValueType): Boolean;
    // Removes all elements from the collection
    procedure Clear(); {$I inline.inc}
    // Number of elements
    property Count: __CollectionIndexType read FCount;

    { List interface }

    {/ Returns the element at the specified position in the list.
       Throws an error on invalid index if dsRangeCheck was included in the list options before instantiation. }
    function Get(Index: __CollectionIndexType): _VectorValueType; {$I inline.inc}
    {/ Replaces the element at the specified position in the list with the specified element.
       Returns the element previously at the specified position.
       Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
    function Put(Index: __CollectionIndexType; const e: _VectorValueType): _VectorValueType; {$I inline.inc}
    {/ Inserts the element at the specified position in the list shifting the element currently at that
       position (if any) and any subsequent elements to the right.
       Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
    procedure Insert(Index: __CollectionIndexType; const e: _VectorValueType);
    {/ Removes the element at the specified position in the list shifting any subsequent elements
       to the left.
       Returns the element that was removed from the list. }
    function RemoveBy(Index: __CollectionIndexType): _VectorValueType; {$I inline.inc}
    {/ Returns the index of the first occurrence of the specified element in the list,
       or -1 if the list does not contain the element. }
    function IndexOf(const e: _VectorValueType): __CollectionIndexType; {$I inline.inc}
    {/ Returns the index of the last occurrence of the specified element in the list,
       or -1 if the list does not contain the element. }
    function LastIndexOf(const e: _VectorValueType): __CollectionIndexType; {$I inline.inc}
    // Values retrieved by index
    property Values[Index: __CollectionIndexType]: _VectorValueType read Get write SetValue; default;

    // Number of elements which the collection able to hold without memory allocations
    property Capacity: __CollectionIndexType read FCapacity write SetCapacity;

  end;

  {$DEFINE _VECTORIMPL}
{$ELSE}


  {$IF not Declared(_VectorDefaultCapacity)}
  const _VectorDefaultCapacity = 16;
  {$IFEND}
  {$IF not Declared(_VectorCapacityStep)}
  const _VectorCapacityStep = 16;
  {$IFEND}


  procedure _GenVector.SetValue(Index: __CollectionIndexType; const e: _VectorValueType);
  begin
    {$IFDEF _RANGECHECK}
      if (Index < 0) or (Index >= FCount) then Assert(False, 'Range check error');
    {$ENDIF}
    FValues[Index] := e;
  end;

  procedure _GenVector.SetCapacity(const ACapacity: __CollectionIndexType);
  begin
    FCapacity := ACapacity;
    SetLength(FValues, Ord(FCapacity));
    if FCount > FCapacity then FCount := FCapacity;
  end;

  constructor _GenVector.Create();
  begin
    Create(_VectorDefaultCapacity);
  end;

  constructor _GenVector.Create(const Capacity: __CollectionIndexType);
  begin
    inherited Create();
    SetCapacity(Capacity);
  end;

  constructor _GenVector.Create(const arr: array of _VectorValueType);
  var i: Integer;
  begin
    FCount := Length(arr);
    SetCapacity(FCount);
    for i := 0 to High(FValues) do FValues[i] := arr[i];
  end;

  procedure _GenVector.EnsureCapacity(ACount: __CollectionIndexType);
    function __MaxI(V1, V2: __CollectionIndexType): __CollectionIndexType; {$I inline.inc}
    begin
      Result := V1 * Ord(V1 >= V2) + V2 * Ord(V1 < V2);
    end;
  begin
    if ACount > FCapacity then SetCapacity(__MaxI(ACount, FCapacity + _VectorCapacityStep));
    Assert(FCapacity >= ACount, 'Capacity low');
  end;

  function _GenVector.GetCount(): __CollectionIndexType;
  begin
    Result := FCount;
  end;

  function _GenVector.IsEmpty(): Boolean;
  begin
    Result := FCount = 0;
  end;

  function _GenVector.Contains(const e: _VectorValueType): Boolean;
  begin
    Result := IndexOf(e) >= 0;
  end;

  procedure _GenVector.ForEach(Delegate: _VectorDelegate; Data: Pointer);
  var i: Integer;
  begin
    for i := 0 to FCount-1 do Delegate(FValues[i], Data);
  end;

  function _GenVector.Add(const e: _VectorValueType): Boolean;
  begin
    EnsureCapacity(FCount+1);
    FValues[FCount] := e;
    Result := True;
    Inc(FCount);
  end;

  function _GenVector.Remove(const e: _VectorValueType): Boolean;
  var ind: __CollectionIndexType;
  begin
    ind := IndexOf(e);
    Result := ind >= 0;
    if Result then RemoveBy(ind);
  end;

  // Removes all elements from the collection
  procedure _GenVector.Clear();
  begin
    FCount := 0;
  end;

  function _GenVector.Get(Index: __CollectionIndexType): _VectorValueType;
  begin
    {$IFDEF _RANGECHECK}
      if (Index < 0) or (Index >= FCount) then Assert(False, 'Range check error');
    {$ENDIF}
    Result := FValues[Index];
  end;

  function _GenVector.Put(Index: __CollectionIndexType; const e: _VectorValueType): _VectorValueType;
  begin
    Result := Get(Index);
    SetValue(index, e);
  end;

  procedure _GenVector.Insert(Index: __CollectionIndexType; const e: _VectorValueType);
  var i: __CollectionIndexType;
  begin
    {$IFDEF _RANGECHECK}
      if (Index < 0) or (Index >= FCount) then Assert(False, 'Range check error');
    {$ENDIF}
    EnsureCapacity(FCount+1);
    for i := FCount-1 downto Index+1 do
      FValues[i] := FValues[i-1];
    FValues[Index] := e;
    Inc(FCount);
  end;

  function _GenVector.RemoveBy(Index: __CollectionIndexType): _VectorValueType;
  var i: __CollectionIndexType;
  begin
    {$IFDEF _RANGECHECK}
      if (Index < 0) or (Index >= FCount) then Assert(False, 'Range check error');
    {$ENDIF}
    Result := FValues[Index];
    for i := Index to FCount-2 do
      FValues[i] := FValues[i+1];
    Dec(FCount);
  end;

  function _GenVector.IndexOf(const e: _VectorValueType): __CollectionIndexType;
  begin
    Result := 0;
    while (Result < FCount) do
      {$IF Declared(_VectorEquals)}
        if _VectorEquals(FValues[Result], e) then Break else Inc(Result);
      {$ELSE}
        if (FValues[Result] = e) then Break else Inc(Result);
      {$IFEND}

    if Result >= FCount then Result := -1;
  end;

  function _GenVector.LastIndexOf(const e: _VectorValueType): __CollectionIndexType;
  begin
    Result := FCount-1;
    while (Result >= 0) do
      {$IF Declared(_VectorEquals)}
        if _VectorEquals(FValues[Result], e) then Break else Dec(Result);
      {$ELSE}
        if (FValues[Result] = e) then Break else Dec(Result);
      {$IFEND}
  end;

  {$UNDEF _VECTORIMPL}
{$ENDIF}
