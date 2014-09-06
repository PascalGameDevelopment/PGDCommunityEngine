(*
  (C) 2006-2014 George Bakhtadze.

  Generic quicksort algorithm implementation
    + optimized generic quicksort implementation
    + constant memory consumption (64 * 2 * SizeOf(Integer) bytes)
    + custom inlineable comparator or evaluator functions support
    + indirect sorting with additional index support, without data move
    + any indexable with "[]" collection support - raw arrays, template vectors, etc
    + resistive to quicksort-unfriendly data (soBadData option)
    + no recursion
    - doesn't preserve relative order of equal values

Usage:
--------------------------
  procedure/function <Name>(Count: Integer; Data: <any array of _SortDataType> [;Index: <any array of integer> ]);
  type
    _SortDataType = <Your type>;
    [_SortValueType = <any comparable with "<" type>]
  const _SortOptions = "["soBadData, soDescending"]";

    [<_SortGetValue() or _SortCompare() function>]
    {$I tpl_algo_quicksort.inc}
  end;
--------------------------
  include soDescending in _SortOptions constant to perform sort in descending order
  include soBadData in _SortOptions constant to use a random index for base element. This can be ~5% slower on usual data but good for quicksort-unfriendly data.

  if _SortDataType is a type which can not be compared with "<" operation one of the following functions should be declared:

        function _SortCompare(const V1,V2: _SortDataType): <Some numeric type>;
        begin
          Result := V1 - V2;         // As usual
        end;
  or
        function _SortGetValue(const V: _SortDataType): _SortValueType;
        begin
          Result := <some numeric expression>;
        end;

  if _SortCompare() function is declared the algorithm will call it each time when a comparation of two data values is needed

  if _SortGetValue() function is declared the algorithm will call it each time when a comparable representation of data value is needed

--------------------------
  Examples:

  // Example 1: Sort array of integers in accending order
  procedure Sort(const Count: Integer; var Data: Array of Integer);
    type _SortDataType = Integer;
    {$MESSAGE 'Instantiating sort algorithm <Integer>'}
    {$I tpl_algo_quicksort.inc}
  end;

  // Example 2: Sort template vector of complex numbers by module in descending order
  procedure Sort(const Count: Integer; Data: TComplexVector);
    const _SortOptions = [soDescending];
    type _SortDataType = TComplex;

    function _SortCompare(const V1, V2: _SortDataType): Integer; {$I inline.inc}
    begin
      Result := (TComplex.GetModule(V1) - TComplex.GetModule(V2));
    end;

    {$MESSAGE 'Instantiating sort algorithm <TComplex>'}
    {$I tpl_algo_quicksort.inc}
  end;
*)

  {$IF Declared(Index)}
    {$DEFINE _SORTINDEXED}
  {$IFEND}

  {$IF Declared(_SortCompare)}
    {$IFNDEF _SORTNOCOMPAREFUNC}
      {$DEFINE _SORTCOMPAREFUNC}
    {$ENDIF}
  {$ELSE}
    {$UNDEF _SORTCOMPAREFUNC}
  {$IFEND}

  {$IF Declared(_SortGetValue)}
    {$IFNDEF _SORTNOCOMPUTEFUNC}
      {$DEFINE _SORTCOMPUTEFUNC}
    {$ENDIF}
  {$ELSE}
    {$UNDEF _SORTCOMPUTEFUNC}
  {$IFEND}

{$IF Declared(_SortOptions)}
  {$I tpl_algo_sort_opt.inc}
{$IFEND}

{$IF not Declared(_SORT_INSERTION_THRESHOLD)}
  // if number of elements <= this value, insertion sort will be used
  const _SORT_INSERTION_THRESHOLD = 30;
{$IFEND}

{$DEFINE CodeNav}

const
  {$IFDEF CPU64}
    StackSize = 64;     // Enough for 2^64 sort data size
  {$ELSE}
    StackSize = 32;     // Enough for 2^32 sort data size
  {$ENDIF}


var
  n1, n2, L, R: Integer;
  {$IFDEF _SORTINDEXED}ti: Integer;{$ENDIF}
  bv, t: _SortDataType;

  StackPTR: Integer;
  MaxStack: Integer;
  Stack: array[0..StackSize-1] of record
    l, r: Integer;
  end;
  {$IFDEF _SORTBADDATA}
    Seed: Cardinal;
    temp: Integer;
  {$ENDIF}
  {$IFDEF _SORTCOMPUTEFUNC}
    TempValue: _SortValueType;
  {$ENDIF}

begin
  {$IFDEF _SORTBADDATA}
    Seed := 1000;
  {$ENDIF}
    MaxStack := 0; //ToFix: temporary
  StackPTR := 0;
  Stack[0].l := 0;
  Stack[0].r := Count-1;
  repeat
    L := Stack[StackPTR].l;
    R := Stack[StackPTR].r;
    Dec(StackPTR);

    // Insertion sort
    if R - L < _SORT_INSERTION_THRESHOLD then begin

      for n1 := L+1 to R do begin
        n2 := n1-1;
        {$IFDEF _SORTINDEXED}
          ti := Index[n1];
          bv := Data[ti];
        {$ELSE}
          bv := Data[n1];
        {$ENDIF}

        while (n2 >= L) do begin
          {$IFNDEF _SORTDESCENDING}
            {$IFDEF _SORTCOMPUTEFUNC}
              if not (_SortGetValue(bv) < _SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}])) then Break;
            {$ELSE}
              {$IFDEF _SORTCOMPAREFUNC}
                if not (_SortCompare(bv, Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) < 0) then Break;
              {$ELSE}
                if not (bv < Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) then Break;
              {$ENDIF}
            {$ENDIF}
          {$ELSE}
            {$IFDEF _SORTCOMPUTEFUNC}
              if not (_SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) < _SortGetValue(bv)) then Break;
            {$ELSE}
              {$IFDEF _SORTCOMPAREFUNC}
                if not (_SortCompare(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}], bv) < 0) then Break;
              {$ELSE}
                if not (Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}] < bv) then Break;
              {$ENDIF}
            {$ENDIF}
          {$ENDIF}

          {$IFDEF _SORTINDEXED}
            Index[n2+1] := Index[n2];
          {$ELSE}
            Data[n2+1] := Data[n2];
          {$ENDIF}
(*          Data[{$IFDEF _SORTINDEXED}Index[n2+1]{$ELSE}n2+1{$ENDIF}] := Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}];*)
          Dec(n2);
        end;

        if n1 <> n2+1 then
          {$IFDEF _SORTINDEXED}
            Index[n2+1] := ti;
          {$ELSE}
            Data[n2+1] := bv;
          {$ENDIF}
      end;

    end else while (L < R) do begin
      // Get separating element
      {$IFDEF _SORTBADDATA} {$Q-}
        Seed := 97781173 * Seed + 7;
        temp := R - L - 1;
        temp := temp or temp shr 1;
        temp := temp or temp shr 2;
        temp := temp or temp shr 4;
        temp := temp or temp shr 8;
        temp := temp or temp shr 16;
        {$IFDEF CPU64}
          temp := temp or temp shr 32;
        {$ENDIF}

        bv := Data[{$IFDEF _SORTINDEXED}Index[Cardinal(L) + Seed and (temp shr 1)]{$ELSE}Cardinal(L) + Seed and (temp shr 1){$ENDIF}];
      {$ELSE}
        bv := Data[{$IFDEF _SORTINDEXED}Index[(L+R) div 2]{$ELSE}(L+R) div 2{$ENDIF}];
      {$ENDIF}

      {$IFDEF _SORTCOMPUTEFUNC}
        TempValue := _SortGetValue(bv);
      {$ENDIF}

      n1 := L;
      n2 := R;
      while n1 <= n2 do begin
        {$IFNDEF _SORTDESCENDING}
          {$IFDEF _SORTCOMPUTEFUNC}
            while True do if _SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}]) < TempValue then Inc(n1) else Break;              // While conditions not inlined by some stupid reason
            while True do if TempValue < _SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) then Dec(n2) else Break;
          {$ELSE}
            {$IFDEF _SORTCOMPAREFUNC}
              while True do if _SortCompare(Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}], bv) < 0 then Inc(n1) else Break;
              while True do if _SortCompare(bv, Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) < 0 then Dec(n2) else Break;
            {$ELSE}
              while Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}] < bv do Inc(n1);
              while bv < Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}] do Dec(n2);
//              while True do if Data[n1] < bv then Inc(n1) else Break;
//              while True do if bv < Data[n2] then Dec(n2) else Break;
            {$ENDIF}
          {$ENDIF}
        {$ELSE}
          {$IFDEF _SORTCOMPUTEFUNC}
            while True do if TempValue < _SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}]) then Inc(n1) else Break;
            while True do if _SortGetValue(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}]) < TempValue then Dec(n2) else Break;
          {$ELSE}
            {$IFDEF _SORTCOMPAREFUNC}
              while True do if _SortCompare(bv, Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}]) < 0 then Inc(n1) else Break;
              while True do if _SortCompare(Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}], bv) < 0 then Dec(n2) else Break;
            {$ELSE}
              while bv < Data[{$IFDEF _SORTINDEXED}Index[n1]{$ELSE}n1{$ENDIF}] do Inc(n1);
              while Data[{$IFDEF _SORTINDEXED}Index[n2]{$ELSE}n2{$ENDIF}] < bv do Dec(n2);
//              while True do if bv < Data[n1] then Inc(n1) else Break;
//              while True do if Data[n2] < bv then Dec(n2) else Break;
            {$ENDIF}
          {$ENDIF}
        {$ENDIF}
        if n1 <= n2 then begin
          {$IFDEF _SORTINDEXED}
            ti        := Index[n1];
            Index[n1] := Index[n2];
            Index[n2] := ti;
          {$ELSE}
            t        := Data[n1];
            Data[n1] := Data[n2];
            Data[n2] := t;
          {$ENDIF}
          Inc(n1);
          Dec(n2);
        end;
      end;
      // { Data[si..n1<bi] < Data[bi] AND Data[bi<n2..fi] > Data[bi] }

      if (n2-L) > (R-n1) then begin
        if L < n2 then begin
                Inc(StackPTR);
                Stack[StackPTR].l := L;
                Stack[StackPTR].r := n2;
                if StackPTR > MaxStack then MaxStack := StackPTR;
        end;
        L := n1;
      end else begin
        if n1 < R then begin
                Inc(StackPTR);
                Stack[StackPTR].l := n1;
                Stack[StackPTR].r := R;
                if StackPTR > MaxStack then MaxStack := StackPTR;
        end;
        R := n2;
      end;
    end;
  until StackPTR < 0;

{$UNDEF _SORTCOMPAREFUNC}
{$UNDEF _SORTCOMPUTEFUNC}
{$UNDEF _SORTDESCENDING}
{$UNDEF _SORTBADDATA}
{$UNDEF _SORTNOCOMPAREFUNC}
{$UNDEF _SORTNOCOMPUTEFUNC}
