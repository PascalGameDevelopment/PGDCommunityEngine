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
        Result := Trunc(maxint * (Frac(Key * K)));
      end;
    {$ELSE}
      // Integer or pointer hash key
      const K = 0.6180339887; // (Sqrt(5) - 1) / 2
      begin
        Result := Trunc(maxint * (Frac(Integer(Key) * K)));
      end;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
