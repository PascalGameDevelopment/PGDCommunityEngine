{$IF not Declared(_ValueType_0)}
  {$MESSAGE ERROR 'Instantiate value type first'}
{$ELSE}
  {$IF not Declared(_ValueType_1)}
    _CallbackType_0
  {$ELSE}
    {$IF not Declared(_ValueType_2)}
      _CallbackType_1
    {$ELSE}
      {$IF not Declared(_ValueType_3)}
        _CallbackType_2
      {$IFEND}
    {$IFEND}
  {$IFEND}
{$IFEND}
