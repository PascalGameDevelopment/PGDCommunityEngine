(*
 * Project: Local
 * User: me
 * Date: 10/3/15
 *)
unit CEUniformsManager;

interface

uses
  CEVectors, CEBaseTypes;

type
  TCEUniformsManager = class(TObject)
  public
    procedure SetInteger(Name: PAPIChar; Value: Integer); virtual; abstract;
    procedure SetSingle(Name: PAPIChar; Value: Single); virtual; abstract;
    procedure SetSingleVec2(Name: PAPIChar; const Value: TCEVector2f); virtual; abstract;
    procedure SetSingleVec3(Name: PAPIChar; const Value: TCEVector3f); virtual; abstract;
    procedure SetSingleVec4(Name: PAPIChar; const Value: TCEVector4f); virtual; abstract;
  end;

implementation

end.