{$IFDEF CONDITIONALEXPRESSIONS}
  {$IF not Declared(CompilerVersion)}
    {$MESSAGE ERROR 'Seems that the include file is used in a program before program header'}
  {$IFEND}
  {$IF CompilerVersion >= 15.0}             // Delphi 7
    {$Message 'Delphi 7+ detected'}
    {$DEFINE DELPHI}
    {$IF CompilerVersion >= 17.0}           // Delphi 2005
      {$DEFINE HAS_INLINE}
      {$DEFINE HAS_STRICT}
    {$IFEND}
  {$IFEND}
{$ENDIF}

{$IFDEF DELPHI}
  {$IFDEF UNICODE}
    {$DEFINE UNICODE_STRING}
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    {$DEFINE WINDOWS}
  {$ENDIF}
  {$WARN UNSAFE_TYPE OFF}       // Disable warning for unsafe types in Delphi 7
{$ENDIF}

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
  {$DEFINE HAS_INLINE}
  {$DEFINE HAS_STRICT}
  {$IFDEF WIN32}
    {$DEFINE WINDOWS}
  {$ENDIF}
  {$IFDEF WIN64}
    {$DEFINE WINDOWS}
  {$ENDIF}
{$ENDIF}

{$IFDEF UNICODE}
  {$STRINGCHECKS OFF}           // Comment for C++ builder compatibility
{$ENDIF}

{$IFDEF HAS_INLINE}
  {$INLINE ON}
{$ENDIF}

{.$DEFINE UNICODE_ONLY}          // Enable for mobile delphi compiler compatibility

{$IFOPT D+}
  {$DEFINE CE_DEBUG}
{$ENDIF}
{$IFDEF DEBUG}
  {$DEFINE CE_DEBUG}
{$ENDIF}

