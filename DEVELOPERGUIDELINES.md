# PGD Community Engine - Development Guidelines #

Last updated - 2nd May 2014 *AthenaOfDelphi*

## Introduction ##

This document defines the standard style for formatting Object Pascal code that is to be submitted to the Pascal Game Development Community Engine (PGDCE) source code repository.

It is based on the [JEDI Delphi Style Guide](http://wiki.delphi-jedi.org/index.php?title=Style_Guide "JEDI Delphi Style Guide") and seeks to provide project specific formatting information only where it differs from that which is defined in the JEDI Delphi Style Guide.  As such, this document should be read alongside the JEDI Delphi Style Guide.

## Source-File Naming ##

Source files should use InfixCaps (or Camel Caps).  For example:- PGDCEVectorMaths.pas.  All extensions should be in lower case.  All PGDCE source code files should be prefixed with 'PGDCE'.

Care should be taken to ensure consistent capitalisation as these files could be used on case sensitive systems such as Linux.

## Source Code Documentation ##

All sources files are to be documented using [PasDoc](http://pasdoc.sipsolutions.net/ "PasDoc") compatible tags.  Where appropriate, some simple examples are given below, but developers should familiarise themselves with the range of tags available in PasDoc.

## Source File Organization ##

### Source File Header ###

For the PGDCE the following header should be used.

    (******************************************************************************
    
      Pascal Game Development Community Engine (PGDCE)
     
      The contents of this file are subject to the license defined in the file
      'licence.md' which accompanies this file; you may not use this file except
      in compliance with the license.
     
      This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
      either express or implied.  See the license for the specific language governing
      rights and limitations under the license.
     
      The Original Code is <INSERT UNIT NAME HERE>
     
      The Initial Developer of the Original Code is documented in the accompanying
      help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
      2014 of these individuals.
     
    ******************************************************************************)

    {
    @abstract(<INSERT ONE-LINER FOR UNIT HERE>)

    <INSERT UNIT DESCRIPTION HERE>

    @author(<INSERT YOUR NAME HERE> (<INSERT YOUR EMAIL ADDRESS OR WEBSITE HERE>))

    }
    unit <INSERT UNIT NAME HERE>;
    
For example:-

    (******************************************************************************
    
      Pascal Game Development Community Engine (PGDCE)
     
      The contents of this file are subject to the license defined in the file
      'licence.md' which accompanies this file; you may not use this file except
      in compliance with the license.
     
      This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
      either express or implied.  See the license for the specific language governing
      rights and limitations under the license.
     
      The Original Code is PGDCEVectorMaths.pas
     
      The Initial Developer of the Original Code is documented in the accompanying
      help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
      2014 of these individuals.
     
    ******************************************************************************)

    {
    @abstract(Contains vector maths utility functions)

    This unit provides the vector maths utility functions for PGD CE.

    @author(Fred Bloggs (fred@pgd.tld))

    }
    unit PGDCEVectorMaths;

### Compiler Directives ###

Compiler directives should not be defined directly in the source files, nor should they be defined using project options in the developers IDE.  They should instead be placed in the global 'PGDCE.inc' file which can be included where needed.

For example:-

    {$I PGDCE.inc}

### Naming Conventions ###

All PGDCE classes and types should be prefixed with 'TCE' regardless of whether they are only used internally or not.

Base classes (i.e. those which, within the PGDCE source code, are used as the parent for multiple classes) should include 'Base' after the prefix.  For example:-

    TCEBaseObjectList = class(TObject)
    ....
    TCESceneObjectList = class(TCEBaseObjectList)
    ....
    TCEMapObjectList = class(TCEBaseObjectList)

Similarly, classes that include abstract methods should include 'Abstract' after the prefix.

In the situation where a class is both 'Abstract' and 'Base', the identifiers should be applied as 'AbstractBase'.  For example:-

    TCEAbstractBaseStreamer = class(TObject)

## Indentation ##

The commonly accepted standard for indentation is two spaces for all indentation levels.

All submissions to the repository **MUST** follow this standard.  Source code formatters can be used to adjust this if required by care must be taken to ensure the reformatted source code follows the other guidelines laid out in this document and the JEDI Delphi Style Guide.

## Continuation Lines ##

Lines should be limited to 100 columns. Lines longer than 100 columns should be broken into one or more continuation lines, as needed.

## Exceptions ##

All exceptions raised by the engine should be of type 'ECEException' or a descendant of it.

## Assembler ##

Since PGDCE is a multi-target project that could be compiled for x86 based architectures and ARM based architectures, the use of assembly language should be avoided where possible.

## PasDoc Documentation Comments ##

PasDoc documentation comments should be placed within the interface section of the unit.  For example:-

    type
      { @abstract(Base object list class)
    
      Base definition for the object list classes. Descendant classes should
      override the load and save methods to handle the required datatypes.} 
      TCEBaseObjectList = class(TObject)
      private
      protected
        { @abstract(Get item from list)
    
        Get the item specified by index from the list.
        @param(index is an integer containing the index of the required item)
        @returns(TObject from the list)
        @raises(ECEIndexOutOfBounds if the requested index is out of bounds) }
        function getItem(index:integer):TObject;

The @abstract tag is optional and may be omitted.

When using the @author tag, you should use your real name since these are relevant for the licensing of PGDCE.  You can optionally include an email address or website URL.

## Enhanced Language Features ##

Use of advanced language features (from either Delphi or FreePascal) should be avoided unless 100% compatibility can be guaranteed.  At the time of writing, the features to avoid include generics and attributes.  