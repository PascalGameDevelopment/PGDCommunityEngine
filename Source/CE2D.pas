(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CE2D.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE 2D graphics handler)

2D graphics class for PGDCE

@author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))
}

unit CE2D;

interface

type
  TCE2D = class
  private
    {Private declarations}
  protected
    {Protected declarations}
    fRenderer: TCEBaseRenderer;
  public
    {Public declarations}
    constructor create;
  published
    {Published declarations}
    property renderer:TCEBaseRenderer read fRenderer write fRenderer;
  end;

implementation

constructor TCE2D.create;
begin
  inherited;

  fRenderer:=nil;
end;

end.
