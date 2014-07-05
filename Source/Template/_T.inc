{$IF not Declared(_ValueType_0)}
  {$UNDEF _ValueType_0}
  {$UNDEF _GEN_CNT_ADV}
{$IFEND}

{$IFNDEF _ValueType_0}
  {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_0}{$ELSE}_ValueType_0{$ENDIF}
{$ELSE}
  {$IFNDEF _ValueType_1}
    {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_1}{$ELSE}_ValueType_1{$ENDIF}
  {$ELSE}
    {$IFNDEF _ValueType_2}
      {$IFDEF _GEN_CNT_ADV}{$DEFINE _ValueType_2}{$ELSE}_ValueType_2{$ENDIF}
    {$ELSE}
                      {$MESSAGE ERROR 'Too many delegate types'}
                      "Too many delegate types"
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$UNDEF _GEN_CNT_ADV}
