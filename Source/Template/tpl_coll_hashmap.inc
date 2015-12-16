(*
  Generic hash table collection
  (C) George Bakhtadze
Usage - once per unit:
  type
    _HashMapKeyType = <some type>;
    _HashMapValueType = <some type>;
    {$I tpl_coll_hashmap.inc}

    T<xxx><yyy>HashMap = class(_GenHashMap)
    end;

  implementation

   [ function _HashMapHashFunc(const Key: _HashMapKeyType): __CollectionIndexType;
     begin
       Result := Ord(@Key);
     end;]

   [ function _HashMapKeyEquals(const Key1, Key2: _HashMapKeyType): Boolean;
     begin
       Result := Key1 = Key2;
     end;]

   [ function _HashMapValueEquals(const Value1, Value2: _HashMapValueType): Boolean;
     begin
       Result := Value1 = Value2;
     end;]

    {$I tpl_coll_hashmap.inc}

  // a compiler message with explanation which type is being instantiated would be very helpful:
  {$MESSAGE 'Instantiating TStringIntegerHashMap'}
  {$I tpl_coll_hashmap.inc}
*)

{$IFNDEF _HASHMAPIMPL}     // Interface

{$IFDEF IPASCAL_PARSING}
type
{$ENDIF}

  {$IF not Declared(__CollectionIndexType)}
    __CollectionIndexType = Integer;
  {$IFEND}

  // Hash map key location data structure
  _HashMapKeyLoc = packed record Index1, Index2: __CollectionIndexType; end;

  // Hash map key-value pair
  _HashMapPair = packed record Key: _HashMapKeyType; Value: _HashMapValueType; end;

  // Hash  map for each delegate
  _HashMapDelegate = procedure(const key: _HashMapKeyType; const value: _HashMapValueType; Data: Pointer) of object;

  // Data structure to store values of hash map
  _HashMapValueRec = packed record Count: __CollectionIndexType; Data: array of _HashMapPair; end;

  // Hash map keys collection type
  _HashMapKeys = array of _HashMapValueRec;

  _GenHashMap = class;

  (* Hash map keys forward iterator.
     No map modification protection or early fail. *)
  _GenHashMapKeyIterator = object
  private
    Map: _GenHashMap;
    BktI, DataI: __CollectionIndexType;
  public
    // Advances the iterator to next item and returns True on success or False if no items left
    function GoToNext(): Boolean;
    // Returns current item performing no iterator state changes
    function Current(): _HashMapKeyType; {$I inline.inc}
    // Returns True if there is more items
    function HasNext(): Boolean;
    // Advances the iterator to next item and returns it.
    // If no items left nil be returned for nullable collection (dsNullable option is defined) or error generated otherwise.
    function Next(): _HashMapKeyType;
  end;

  _GenHashMap = class
  {$IFDEF HAS_STRICT}strict{$ENDIF} private
    function GetLoadFactor(): Single;

  protected
    FValues: _HashMapKeys;
  {$IFDEF HAS_STRICT}strict{$ENDIF} protected
    // Capacity of the hash map. Should be a power of 2.
    FCapacity,
    // Capacity mask
    FMask: __CollectionIndexType;
    // Threshold of number of entries to capacity ratio after which capacity doubles. If zero automatic resizing doesn't occur.
    FMaxLoadFactor: Single;
    // Grow step of bucket array
    FBucketGrowStep: __CollectionIndexType;
    // Number of entries
    FCount: __CollectionIndexType;
    function GetIndexInBucket(const Key: _HashMapKeyType; out BucketIndex: __CollectionIndexType): __CollectionIndexType; {$I inline.inc}
    function GetValue(const Key: _HashMapKeyType): _HashMapValueType; {$I inline.inc}
    procedure SetValue(const Key: _HashMapKeyType; const Value: _HashMapValueType); {$I inline.inc}
    procedure SetCapacity(ACapacity: __CollectionIndexType);
  public
    constructor Create(); overload;
    // Create a map instance with the specified initial capacity
    constructor Create(Capacity: __CollectionIndexType); overload;
    destructor Destroy(); override;
    // Returns a forward iterator over map keys collection
    function GetKeyIterator(): _GenHashMapKeyIterator;

    // Sets value, returns True if there was value in the map for the key
    function PutValue(const Key: _HashMapKeyType; const Value: _HashMapValueType): Boolean; {$I inline.inc}
    // Returns True if the hash map contains the key
    function ContainsKey(const Key: _HashMapKeyType): Boolean; {$I inline.inc}
    // Returns True if the hash map contains the value
    function ContainsValue(const Value: _HashMapValueType): Boolean; {$I inline.inc}
    // Removes value, returns True if there was value in the map for the key
    function RemoveValue(const Key: _HashMapKeyType): Boolean; {$I inline.inc}

    // Calls a delegate for each value stored in the map
    procedure ForEach(Delegate: _HashMapDelegate; Data: Pointer);

    // Returns True if the collection contains no elements
    function IsEmpty(): Boolean; {$I inline.inc}
    // Removes all elements from the collection
    procedure Clear(); {$I inline.inc}

    // Values retrieved by pointer key
    property Values[const Key: _HashMapKeyType]: _HashMapValueType read GetValue write SetValue; default;
    // Determines hash function values range which is currently used.
    property Capacity: __CollectionIndexType read FCapacity;
    // Threshold of number of entries to capacity ratio after which capacity doubles. If zero automatic resizing doesn't occur.
    property MaxLoadFactor: Single read FMaxLoadFactor write FMaxLoadFactor;
    // Current number of entries to capacity ratio
    property LoadFactor: Single read GetLoadFactor;
    // Grow step of bucket array
    property BucketGrowStep: __CollectionIndexType read FBucketGrowStep write FBucketGrowStep;
    // Number of entries
    property Count: __CollectionIndexType read FCount;
    // Keys collection
    //property Keys: _HashMapKeys read FValues;
  end;

  {$DEFINE _HASHMAPIMPL}
{$ELSE}                    // Implementation

  {$IF Declared(_HashMapOptions)}
    {$I tpl_coll_hashmap_opt.inc}
  {$IFEND}


  {$IF not Declared(_HashMapDefaultCapacity)}
    const _HashMapDefaultCapacity = 16;
  {$IFEND}

  { _GenHashMapKeyIterator }
  function _GenHashMapKeyIterator.GoToNext(): Boolean;
  begin
    Result := False;
    Inc(DataI);
    while (BktI < Map.Capacity) and not Result do
      if DataI < Map.FValues[BktI].Count then
        Result := True
      else begin
        DataI := 0;
        Inc(BktI);
      end;
  end;

  function _GenHashMapKeyIterator.Current(): _HashMapKeyType;
  begin
    Result := Map.FValues[BktI].Data[DataI].Key;
  end;

  function _GenHashMapKeyIterator.HasNext(): Boolean;
  var lDataI, lBktI: __CollectionIndexType;
  begin
    Result := False;
    lDataI := DataI;
    lBktI  := BktI;
    Inc(lDataI);
    while (lBktI < Map.Capacity) and not Result do
      if lDataI < Map.FValues[lBktI].Count then
        Result := True
      else begin
        lDataI := 0;
        Inc(lBktI);
      end;
  end;

  {$WARN NO_RETVAL OFF}
  function _GenHashMapKeyIterator.Next(): _HashMapKeyType;
  begin
    if GoToNext then
      Result := Current
    else
    {$IFDEF _HashMapTypeNullable}
      Result := nil;
    {$ELSE}
      Assert(False, 'No more elements');
    {$ENDIF}
  end;
  {$WARN NO_RETVAL ON}

  { _GenHashMap }

  {$IF not Declared(_HashMapHashFunc)}
    function _HashMapHashFunc(const Key: Integer): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}

    function _HashMapHashFunc(const Key: Pointer): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}

    {$WARN UNSAFE_CAST OFF}
    function _HashMapHashFunc(const Key: TObject): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    {$WARN UNSAFE_CAST ON}

    function _HashMapHashFunc(const Key: TClass): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}

    {$DEFINE Hash_Key_Float}
    function _HashMapHashFunc(const Key: Single): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    function _HashMapHashFunc(const Key: Double): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    {$IFDEF HAS_TYPE_EXTENDED}
    function _HashMapHashFunc(const Key: Extended): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    {$ENDIF}

    {$DEFINE Hash_Key_String}
    function _HashMapHashFunc(const Key: ShortString): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    function _HashMapHashFunc(const Key: AnsiString): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    function _HashMapHashFunc(const Key: WideString): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
    {$IFDEF UNICODE}
      function _HashMapHashFunc(const Key: UnicodeString): NativeUInt; overload; {$I inline.inc}
      {$I tpl_hash_funcs.inc}
    {$ENDIF}

    {$DEFINE Hash_Key_PChar}
    function _HashMapHashFunc(Key: PAnsiChar): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}

    function _HashMapHashFunc(Key: PWideChar): NativeUInt; overload; {$I inline.inc}
    {$I tpl_hash_funcs.inc}
  {$IFEND}


  function _GenHashMap.GetIndexInBucket(const Key: _HashMapKeyType; out BucketIndex: __CollectionIndexType): __CollectionIndexType;
  begin
    BucketIndex := _HashMapHashFunc(Key) and FMask;
    Result := 0;
    while (Result < FValues[BucketIndex].Count) do
      {$IF Declared(_HashMapKeyEquals)}
        if _HashMapKeyEquals(FValues[BucketIndex].Data[Result].Key, Key) then Break else Inc(Result);
      {$ELSE}
        if (FValues[BucketIndex].Data[Result].Key = Key) then Break else Inc(Result);
      {$IFEND}
  end;

  function _GenHashMap.GetValue(const Key: _HashMapKeyType): _HashMapValueType;
  var
    Index, i: __CollectionIndexType;
  begin
    i := GetIndexInBucket(Key, index);

    if i < FValues[Index].Count then
      Result := FValues[Index].Data[i].Value
    else
    begin
      {$IFDEF _HashMapTypeNullable}
        Result := nil;
      {$ELSE}
        Assert(False, 'Key not found');
      {$ENDIF}
    end;
  end;

  function _GenHashMap.PutValue(const Key: _HashMapKeyType; const Value: _HashMapValueType): Boolean;
  var Index, i: __CollectionIndexType;
  begin
    i := GetIndexInBucket(Key, Index);

    if i = FValues[Index].Count then begin
      if Length(FValues[Index].Data) <= i then
        SetLength(FValues[Index].Data, Length(FValues[Index].Data) + FBucketGrowStep);
      FValues[Index].Data[i].Key := Key;
      FValues[Index].Count := i+1;
      Inc(FCount);
      Result := False;
    end else
      Result := True;

    FValues[Index].Data[i].Value := Value;

    if LoadFactor > FMaxLoadFactor then SetCapacity(FCapacity * 2);
  end;

  procedure _GenHashMap.SetValue(const Key: _HashMapKeyType; const Value: _HashMapValueType);
  begin
    PutValue(Key, Value);
  end;

  function _GenHashMap.RemoveValue(const Key: _HashMapKeyType): Boolean;
  var Index, i: __CollectionIndexType;
  begin
    i := GetIndexInBucket(Key, Index);
    Result := i < FValues[Index].Count;
    if Result then begin
      FValues[Index].Data[i] := FValues[Index].Data[FValues[Index].Count - 1];
      Dec(FValues[Index].Count);
      Dec(FCount);
    end;
  end;

  procedure _GenHashMap.SetCapacity(ACapacity: __CollectionIndexType);
  var
    i, j: __CollectionIndexType;
    OldValues, NewValues: _HashMapKeys;
  begin
    Assert((ACapacity > 0) and (ACapacity and (ACapacity-1) = 0), 'Capacity should be greater then zero and a power of 2');
    // Save values
    OldValues := FValues;

    // Allocate new values
    FCapacity := ACapacity;
    SetLength(NewValues, FCapacity);
    FValues := NewValues;
    FMask := FCapacity-1;
    FCount := 0;

    // Insert old values into clean map
    for i := 0 to High(OldValues) do
      for j := 0 to OldValues[i].Count-1 do
        SetValue(OldValues[i].Data[j].Key, OldValues[i].Data[j].Value);
  end;

  function _GenHashMap.GetLoadFactor(): Single;
  begin
    Result := FCount / FCapacity;
  end;

  constructor _GenHashMap.Create();
  begin
    Create(_HashMapDefaultCapacity);
  end;

  constructor _GenHashMap.Create(Capacity: __CollectionIndexType);
  begin
    inherited Create();
    FBucketGrowStep := 1;
    FMaxLoadFactor := 0.75;
    SetCapacity(Capacity);
  end;

  destructor _GenHashMap.Destroy();
  begin
    Clear;
    SetLength(FValues, 0);
    inherited;
  end;

  function _GenHashMap.GetKeyIterator(): _GenHashMapKeyIterator;
  begin
    Result.BktI  := 0;
    Result.DataI := -1;
    Result.Map   := Self;
  end;

  function _GenHashMap.ContainsKey(const Key: _HashMapKeyType): Boolean;
  var Index: __CollectionIndexType;
  begin
    Result := GetIndexInBucket(Key, index) < FValues[Index].Count;
  end;

  function _GenHashMap.ContainsValue(const Value: _HashMapValueType): Boolean;
  var i, j: __CollectionIndexType;
  begin
    Result := True;
    for i := 0 to High(FValues) do
      for j := 0 to FValues[i].Count-1 do
        {$IF Declared(_HashMapValueEquals)}
          if _HashMapValueEquals(FValues[i].Data[j].Value, Value) then Exit;
        {$ELSE}
          if (FValues[i].Data[j].Value = Value) then Exit;
        {$IFEND}
    Result := False;
  end;

  procedure _GenHashMap.ForEach(Delegate: _HashMapDelegate; Data: Pointer);
  var i, j: __CollectionIndexType;
  begin
    for i := 0 to High(FValues) do
      for j := 0 to FValues[i].Count-1 do
        Delegate(FValues[i].Data[j].Key, FValues[i].Data[j].Value, Data);
  end;

  function _GenHashMap.IsEmpty(): Boolean;
  begin
    Result := FCount = 0;
  end;

  procedure _GenHashMap.Clear();
  var i: __CollectionIndexType;
  begin
    FCount := 0;
    for i := 0 to High(FValues) do begin
      SetLength(FValues[i].Data, 0);
      FValues[i].Count := 0;
    end;
  end;

  {$UNDEF _HASHMAPIMPL}
{$ENDIF}
