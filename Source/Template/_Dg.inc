{$IF not Declared(_ValueType_0)}
  {$MESSAGE ERROR 'Instantiate value type first'}
{$ELSE}
  {$IF not Declared(_ValueType_1)}
    _DelegateType_0
  {$ELSE}
    {$IF not Declared(_ValueType_2)}
      _DelegateType_1
    {$ELSE}
      {$IF not Declared(_ValueType_3)}
        _DelegateType_2
      {$IFEND}
    {$IFEND}
  {$IFEND}
{$IFEND}
