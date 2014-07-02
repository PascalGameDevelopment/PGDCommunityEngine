// General compiler defines
{$IFDEF VER150} {$DEFINE Delphi} {$ENDIF}                      // Delphi 7
{$IFDEF VER160} {$DEFINE Delphi} {$ENDIF}                      // Delphi 8
{$IFDEF VER170} {$DEFINE Delphi} {$DEFINE Delphi2005} {$ENDIF} // Delphi 2005
{$IFDEF VER180} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$ENDIF} // Delphi 2006
{$IFDEF VER185} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$ENDIF} // Delphi 2007
{$IFDEF VER200} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$DEFINE Delphi2009} {$ENDIF} // Delphi 2009
{$IFDEF VER210} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$DEFINE Delphi2009} {$ENDIF} // Delphi 2010
{$IFDEF VER220} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$DEFINE Delphi2009} {$DEFINE DelphiXE} {$ENDIF} // Delphi XE
{$IFDEF VER230} {$DEFINE Delphi} {$DEFINE Delphi2005} {$DEFINE Delphi2006} {$DEFINE Delphi2009} {$DEFINE DelphiXE} {$DEFINE FireMonkey} {$ENDIF} // Delphi XE2

{$IFDEF UNICODE}
  {$STRINGCHECKS OFF}
{$ENDIF}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$DEFINE HAS_INLINE}
  {$DEFINE HAS_STRICT}
  {$IFDEF WIN32}
    {$DEFINE WINDOWS}
  {$ENDIF}
{$ELSE}
  {$DEFINE DELPHI}
{$ENDIF}

{$IFDEF Delphi}
  {$DEFINE Delphi32}
  {$WARN UNSAFE_TYPE OFF}       // Disable warning for unsafe types in Delphi 7
  {$DEFINE Has_Int64}
  {$DEFINE WINDOWS}
{$ENDIF}

{$IFDEF Delphi2005}
  {$DEFINE HAS_INLINE}
  {$DEFINE HAS_STRICT}
{$ENDIF}

{$IFDEF WIN64}
  {$DEFINE CPU64}
{$ENDIF}

{$IFDEF HAS_INLINE}
  {$INLINE ON}
{$ENDIF}

{$IFOPT D+}
  {$DEFINE DEBUG}
{$ENDIF}

