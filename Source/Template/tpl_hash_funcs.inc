{$IFDEF Hash_Key_PChar}
  // PChar-like hash key
  begin
    {$Q-}
    Result := 5381;
    while Key^ <> #0 do begin
      Result := 33 * Result + Ord(Key^);
      Inc(Key);
    end;
  end;
{$ELSE}
  {$IFDEF Hash_Key_String}
    // String-like hash key
    var i: Integer;
    begin
      {$Q-}
      Result := 5381;
      for i := 1 to Length(Key) do Result := 33 * Result + Ord(key[i]);
    end;
  {$ELSE}
    {$IFDEF Hash_Key_Float}
      // Float hash key
      const K = 0.6180339887; // (Sqrt(5) - 1) / 2
      begin
        {$Q-}
        Result := Trunc(maxint * (Frac(Key * K)));
      end;
    {$ELSE}
      // 32-bit integer or pointer hash key
      begin
        {$Q-}
        {$R-}
        Result := ((PtrUInt(Key) shr 16) xor PtrUInt(Key)) * $45d9f3b;
        Result := ((Result shr 16) xor Result) * $45d9f3b;
        Result := ((Result shr 16) xor Result);
      end;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
