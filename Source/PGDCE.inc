{$IFDEF CONDITIONALEXPRESSIONS}
  {$IF not Declared(CompilerVersion)}
    {$MESSAGE ERROR 'Seems that the include file is used in a program before program header'}
  {$IFEND}
  {$IF CompilerVersion >= 15.0}             // Delphi 7
    {$DEFINE DELPHI}
    {$IF CompilerVersion >= 17.0}           // Delphi 2005
      {$DEFINE HAS_INLINE}
      {$DEFINE HAS_STRICT}
    {$IFEND}
    {$IF CompilerVersion >= 22.0}           // Delphi XE
      {$DEFINE HAS_FILE_TIMESTAMP}
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
  {.$MODE DELPHIUNICODE}
  {$MODE DELPHI}
  {$DEFINE HAS_INLINE}
  {$DEFINE HAS_STRICT}
  {$IFDEF ANDROID}
    {$DEFINE MOBILE}
  {$ENDIF}
  {$IFDEF WIN32}
    {$DEFINE WINDOWS}
  {$ENDIF}
  {$IFDEF WIN64}
    {$DEFINE WINDOWS}
  {$ENDIF}
  {$IFDEF UNIX}
    {$IFNDEF MOBILE}
      {$DEFINE XWINDOW}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF UNICODE}
  {$STRINGCHECKS OFF}           // Comment for C++ builder compatibility
{$ENDIF}

{$IFDEF HAS_INLINE}
  {$INLINE ON}
{$ENDIF}

{.$DEFINE UNICODE_ONLY}          // Enable for mobile Delphi compiler compatibility

{$IFOPT D+}
  {$DEFINE CE_DEBUG}
{$ENDIF}
{$IFDEF DEBUG}
  {$DEFINE CE_DEBUG}
{$ENDIF}

{$DEFINE FLOAT_IEEE}             // Assume IEEE floating point values representation
{$DEFINE LOGGING}

{$IFDEF MOBILE}
{$ELSE}
  {$DEFINE HAS_TYPE_EXTENDED}     // Extended floating point type
{$ENDIF}

{.$DEFINE OPENGLES_EMULATION}     // Use GLES 2.0 emulation layer for desktops
{$DEFINE OPENGL_ERROR_CHECK}          // Check for OpenGL errors
{$IFDEF MOBILE}
  {$DEFINE GLES20}
{$ENDIF}
{$IFDEF OPENGLES_EMULATION}
    {$DEFINE GLES20}
{$ENDIF}
