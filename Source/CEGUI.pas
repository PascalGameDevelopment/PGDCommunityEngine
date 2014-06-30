(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEGUI.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE Graphical User Interface handler)

Graphical user interface implementation for PGDCE

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

unit CEGUI;

interface

type
  TCEGUI = class
  private
    {Private declarations}
  protected
    {Protected declarations}
    fRenderer2D: TCE2D;
  public
    {Public declarations}
    constructor create;
  published
    {Published declarations}
    property renderer2D:TCE2D read fRenderer2D write fRenderer2D;
  end;

implementation

constructor TCEGUI.create;
begin
  inherited;

  fRenderer2D:=nil;
end;

end.
