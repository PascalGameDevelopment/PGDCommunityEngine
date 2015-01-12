(*
  @Abstract(Test framework unit)
  (C) 2003-2012 George "Mirage" Bakhtadze.<br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Jan 21, 2012
  The unit contains implementation of simple yet powerful unit test framework

  Main entity is a suite of tests represented by a descendant of TTestSuite class.
  Test suite contains tests - each published method of a TTestSuite descendant class is a test.
  TTestSuite descendants cannot have other published methods than parameterless procedure methods.
  Descendants of TTestSuite should be registered using RegisterSuite, RegisterSuites or RunTests routines.

  Consider the following class hierarchy:

    TSuite1 = class(TTestSuite)
    published
      procedure TestFirst();
    end;

    TSuite2 = class(TTestSuite)
    published
      procedure TestSecond();
      procedure TestThird();
    end;

    TSubSuite = class(TSuite2)
    published
      procedure TestSub();
    end;

  When all these classes will be registered:

    RegisterSuites([TSuite1, TSuite2, TSubSuite]);

  The following hierarchy of tests will be created:

    TSuite1.TestFirst
    TSuite2.TestSecond
    TSuite2.TestThird
    TSuite2.TSubSuite.TestSub

  The test can be runned with a single call:

    RunTests();

  Which returns True if all test passed.
*)
{$Include PGDCE.inc}
unit Tester;

interface

uses CEBaseTypes, CETemplate, SysUtils;

const
  TEST_METHOD_SIGNATURE = 'Test';

type
  {$TYPEINFO ON}
  // Forward declaration of TTestSuite
  TTestSuite = class;
  {$TYPEINFO OFF}

  // Test suite metaclass
  CTestSuite = class of TTestSuite;

  _VectorValueType = CTestSuite;        // TODO: Move to implementation
  {$I tpl_coll_vector.inc}
  TTestSuiteVector = _GenVector;        // TODO: Move to implementation

  TTestName = ShortString;

  // Possible test outcome
  TTestResult = (// Not run yet
                 trNone,
                 // Not run because is skipped due to previous test in suite failed
                 trSkipped,
                 // Test not run because it's disabled
                 trDisabled,
                 // Test passes
                 trSuccess,
                 // Test failed
                 trFail,
                 // Exception occured
                 trException,
                 // Error occured
                 trError);

  // Record with test data
  TTest = record
    // Index in all tests array of runner class
    Index: Integer;
    // Testsuite class
    Suite: CTestSuite;
    // Test name
    Name: TTestName;
    // Test command
    Command: TCommand;
    // Result of previous test run
    LastResult: TTestResult;
    // Location in code of fail. Filled in when test fails.
    FailCodeLoc: TCodeLocation;
  end;
  // Array of tests
  TTests = array of TTest;

  TChildsRunCondition = (// Not run child levels
                         crcNever,
                         // Run if current level tests passed
                         crcIfPassed,
                         // Run child tests
                         crcAlways);

  // Single level of tests hierarchy
  TTestLevel = class(TObject)
  private
    // Index of last run test
    LastIndex: Integer;
    // Test suite class reference
    FSuiteClass: CTestSuite;
    // Suite instance
    Suite: TTestSuite;
    // Parent level
    FParent: TTestLevel;
    // Tests
    FTests: TTests;
    // Next hierarchy
    FChilds: array of TTestLevel;

    // Creates suite instance
    procedure CreateSuite();
    // Destroys suite instance
    procedure DestroySuite();

    // Fills Tests field with tests found in SuiteClass and returns number of such tests
    function RetrieveTests(): Integer;
    // Retuns total number of test in hierarchy
    function GetTotalTestCount(): Integer;

    // Adds new child level
    procedure AddChild(Level: TTestLevel);
    function GetChild(Index: Integer): TTestLevel;
    function GetTotalChilds: Integer;
    function GetTest(Index: Integer): TTest;
    function GetTotalTests: Integer;
  public
    // Creates an instance of test level
    constructor Create(ASuiteClass: CTestSuite; AParent: TTestLevel);
    // Calls DestroySuite()
    destructor Destroy(); override;
    { Runs the given test of the given suite. First calls Suite.InitTest() then calls test method, finally, calls Suite.DoneTest()
      Returns test outcome. }
    function RunTest(Index: Integer): TTestResult;
    // Runs all tests in level
    function Run(RunChilds: TChildsRunCondition): Boolean;
    // Number of child levels
    property TotalChilds: Integer read GetTotalChilds;
    // Child level by index
    property Childs[Index: Integer]: TTestLevel read GetChild;
    // Number of tests
    property TotalTests: Integer read GetTotalTests;
    // Test by index
    property Tests[Index: Integer]: TTest read GetTest;
    // Test suite class reference
    property SuiteClass: CTestSuite read FSuiteClass write FSuiteClass;
  end;

  // Abstract test runner class
  TTestRunner = class(TObject)
  private
    FTestRoot: TTestLevel;
    FAllTests: TTests;
    function Run(Suites: TTestSuiteVector): Boolean;
    function CreateLevel(Suite: TClass; ARetrieveTests: Boolean): TTestLevel;
    function FindSuiteInLevel(Level: TTestLevel; Suite: CTestSuite): TTestLevel;
    function FillAllTests(Level: TTestLevel; AllTests: TTests; Offset: Integer): Integer;
    function GetTotalTests: Integer;
    function GetTest(Index: Integer): TTest;
  protected
    // Number of test with a certain result
    Stats: array[TTestResult] of Integer;
    // Should run all tests and return True if all tests passed successfully
    function DoRun(): Boolean; virtual; abstract;
    // Returns test level containing tests of the specified class or nil if not found
    function FindTestLevel(Suite: CTestSuite): TTestLevel;

    // Should return False if the test should not be performed at this time. For exampled, it's disabled.
    function IsTestEnabled(const ATest: TTest): Boolean; virtual;
    // Called after test suite instance creation
    procedure HandleCreateSuite(Suite: TTestSuite); virtual;
    // Called before test suite instance destroy
    procedure HandleDestroySuite(Suite: TTestSuite); virtual;
    { Called after each test. If it returns False test running will stop.
      Typically retrns false of TestResult is trFail, trException or trError. }
    function HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean; virtual; abstract;
    // Called when an exception occurs during test.
    procedure HandleTestException(const ATest: TTest; E: Exception); virtual; abstract;

    // Fills TestRoot and AllTests data structures with information from Suites vector
    procedure PrepareTests(Suites: TTestSuiteVector);

    // All registered tests
    property Tests[Index: Integer]: TTest read GetTest;
    // Number of registered tests
    property TotalTests: Integer read GetTotalTests;
    // Root test level
    property TestRoot: TTestLevel read FTestRoot;
  public
    // Destroys the runner
    destructor Destroy(); override;
  end;

  // Test runner implementation which outputs test results to log
  TLogTestRunner = class(TTestRunner)
  protected
    function DoRun(): Boolean; override;
    function IsTestEnabled(const ATest: TTest): Boolean; override;
    function HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean; override;
    procedure HandleTestException(const ATest: TTest; E: Exception); override;
    procedure HandleCreateSuite(Suite: TTestSuite); override;
    procedure HandleDestroySuite(Suite: TTestSuite); override;
  end;

  {
    Any published method will be threated as a test.
    Tests should check assertions with the following syntax:

    To check for a condition:
      Assert(Check(<Condition>), 'Message');

    To check if the test raises some of the listed exceptions:
      Assert(Raises([<List of exception classes>], 'Message');

    To check if the test returns some of the listed errors:
      Assert(Error([<List of error classes>], 'Message');
  }
  {$M+}
  TTestSuite = class(TObject)
  private
    FLastName: TTestName;
  protected
    // If called from a test method returns name of the method. Otherwise returns name of last called test method.
    function GetName(): string;
    // Called after creation of a suite instance
    procedure InitSuite(); virtual;
    // Called before destroy of a suite instance
    procedure DoneSuite(); virtual;
    // Called before each test method
    procedure InitTest(); virtual;
    // Called after each test method
    procedure DoneTest(); virtual;
    // Returns suite level in hierarchy. Immediate descendant of TTestSuite has level 1.
    class function GetLevel(): Integer;
    // Returns all tests in the test suite
    class function GetTests(): TTests;
  public
    constructor Create();
    destructor Destroy(); override;
  end;

  // Sets test runner. Frees previous runner if any.
  procedure SetRunner(Runner: TTestRunner);

  // Runs all registered tests and returns True if all tests passed
  function RunTests(): Boolean; overload;
  // Registers the given test suites, runs all registered tests and returns True if all tests passed
  function RunTests(ATestSuites: array of CTestSuite): Boolean; overload;

  // Register the given test suite
  procedure RegisterSuite(ATestSuite: CTestSuite);
  // Register all of the given test suites
  procedure RegisterSuites(ATestSuites: array of CTestSuite);

  { A special function-argument. Should be called ONLY as Assert() argument.
    Suggested usage:

    Assert(_Check(Assumption), 'Assumption is false!');

    This call will raise TTestFailException if the assumption is false.
    Always returns False. }
  function _Check(Condition: Boolean): Boolean;

implementation

uses CERttiUtil;

type
  // Exception raised when a test was failed
  TTestFailException = class(Exception)
  public
    // Place in code where test failed
    CodeLocation: TCodeLocation;
    // Creates an instance
    constructor Create(ACodeLocation: TCodeLocation; const AMsg: string);
  end;

var
  TestSuites: TTestSuiteVector;
  TestRunner: TTestRunner;

  procedure SetRunner(Runner: TTestRunner);
  begin
    if Runner = TestRunner then Exit;
    if Assigned(TestRunner) then TestRunner.Free;
    TestRunner := Runner;
  end;

  function RunTests(): Boolean; overload;
  begin
    if Assigned(TestRunner) then
      Result := TestRunner.Run(TestSuites)
    else
      Result := False;
  end;

  function RunTests(ATestSuites: array of CTestSuite): Boolean; overload;
  begin
    RegisterSuites(ATestSuites);
    Result := RunTests();
  end;

  procedure RegisterSuite(ATestSuite: CTestSuite);
  begin
    if ATestSuite <> nil then TestSuites.Add(ATestSuite)
  end;

  procedure RegisterSuites(ATestSuites: array of CTestSuite);
  var i: Integer;
  begin
    for i := Low(ATestSuites) to High(ATestSuites) do RegisterSuite(ATestSuites[i]);
  end;

  {$IFDEF FPC}
    procedure TestAssert(const Message, Filename: ShortString; LineNumber: LongInt; ErrorAddr: Pointer);
  {$ELSE}
    procedure TestAssert(const Message, Filename: string; LineNumber: Integer; ErrorAddr: Pointer);
  {$ENDIF}
  begin
    AssertRestore();
    raise TTestFailException.Create(GetCodeLoc(Filename, '', '', LineNumber, ErrorAddr), Message);
  end;

  function _Check(Condition: Boolean): Boolean;
  begin
    if not Condition then AssertHook(@TestAssert);
    Result := Condition;
  end;

{$IFDEF TEMPLATE_HINTS}{$MESSAGE 'Instantiating TStringIntegerHashMap'}{$ENDIF}
  {$I tpl_coll_vector.inc}

procedure Log(const s: string);  // TODO: replace with logger
begin
  Writeln(s);
end;

procedure LogError(const s: string);  // TODO: replace with logger
begin
  Writeln('!ERROR!: ' + s);
end;

{ TTestSuite }

function TTestSuite.GetName: string;
begin
  Result := string(FLastName);
end;

procedure TTestSuite.InitSuite;
begin
end;

procedure TTestSuite.DoneSuite;
begin
end;

procedure TTestSuite.InitTest;
begin
end;

procedure TTestSuite.DoneTest;
begin
end;

constructor TTestSuite.Create;
begin
  InitSuite();
end;

destructor TTestSuite.Destroy;
begin
  DoneSuite();
  inherited;
end;

class function TTestSuite.GetLevel: Integer;
var Parent: TClass;
begin
  Result := 0;
  Parent := Self;
  while Parent <> TTestSuite do begin
    Inc(Result);
    Parent := Parent.ClassParent;
  end;
end;

class function TTestSuite.GetTests: TTests;
var
  i: Integer;
  MNames: TRTTINames;
begin
  MNames := CERttiUtil.GetClassMethodNames(Self, False);
  SetLength(Result, Length(MNames));
  for i := 0 to High(MNames) do
  begin
    Result[i].Suite      := Self;
    Result[i].Name       := MNames[i];
    Result[i].LastResult := trNone;
    //Result[i].Command    :=
    //Log('Found test: ' + MNames[i]);
  end;
end;

{ TTestRunner }

function TTestRunner.FindSuiteInLevel(Level: TTestLevel; Suite: CTestSuite): TTestLevel;
var i: Integer;
begin
  Result := nil;
  if Level = nil then Exit;
  i := High(Level.FChilds);
  while (i >= 0)
    and ((Level.FChilds[i] = nil) or (Level.FChilds[i].FSuiteClass <> Suite)) do
      Dec(i);
  if i >= 0 then
    Result := Level.FChilds[i]
  else
    for i := 0 to High(Level.FChilds) do
      Result := FindSuiteInLevel(Level.FChilds[i], Suite);
end;

function TTestRunner.FindTestLevel(Suite: CTestSuite): TTestLevel;
begin
  Result := FindSuiteInLevel(FTestRoot, Suite);
end;

function TTestRunner.IsTestEnabled(const ATest: TTest): Boolean;
begin
  Result := True;
end;

function TTestRunner.CreateLevel(Suite: TClass; ARetrieveTests: Boolean): TTestLevel;
var Level: TTestLevel;
begin
  Assert(Suite.InheritsFrom(TTestSuite));

  if (Suite = TTestSuite) then
  begin
    if FTestRoot = nil then
      FTestRoot := TTestLevel.Create(CTestSuite(Suite), nil);
    Result := FTestRoot;
  end else
  begin
    Level := CreateLevel(Suite.ClassParent, False);
    Result := FindSuiteInLevel(Level, CTestSuite(Suite));
    if Result = nil then
    begin
      Result := TTestLevel.Create(CTestSuite(Suite), Level);
      Level.AddChild(Result);
    end;
  end;

  if ARetrieveTests then Result.RetrieveTests();
end;

function TTestRunner.FillAllTests(Level: TTestLevel; AllTests: TTests; Offset: Integer): Integer;
var i: Integer;
begin
  for i := 0 to High(Level.FTests) do
  begin
    Level.FTests[i].Index := Offset+i;
    AllTests[Offset+i] := Level.FTests[i];
  end;
  for i := 0 to High(Level.FChilds) do Offset := FillAllTests(Level.FChilds[i], AllTests, Offset + Length(Level.FTests));
  Result := Offset + Length(Level.FTests);
end;

function TTestRunner.GetTotalTests: Integer;
begin
  Result := Length(FAllTests);
end;

function TTestRunner.GetTest(Index: Integer): TTest;
begin
  Result := FAllTests[Index];
end;

function TTestRunner.Run(Suites: TTestSuiteVector): Boolean;
var
  i: TTestResult;
begin
  for i := Low(TTestResult) to High(TTestResult) do Stats[i] := 0;
  PrepareTests(TestSuites);
  Result := DoRun();
end;

procedure TTestRunner.PrepareTests(Suites: TTestSuiteVector);
var i: Integer;
begin
  if Suites.Count = 0 then Exit;
  for i := 0 to Suites.Count-1 do CreateLevel(Suites[i], True);
  SetLength(FAllTests, FTestRoot.GetTotalTestCount());
  FillAllTests(FTestRoot, FAllTests, 0);
  for i := 0 to GetTotalTests()-1 do Assert(FAllTests[i].Index = i);
end;

destructor TTestRunner.Destroy;
  procedure FreeLevel(Level: TTestLevel);
  var i: Integer;
  begin
     if Level = nil then Exit;
     for i := 0 to High(Level.FChilds) do FreeLevel(Level.FChilds[i]);
     Level.Free();
  end;
begin
  FreeLevel(FTestRoot);
  SetLength(FAllTests, 0);
  inherited;
end;

procedure TTestRunner.HandleCreateSuite(Suite: TTestSuite);
begin
end;

procedure TTestRunner.HandleDestroySuite(Suite: TTestSuite);
begin
end;

{ TTestLevel }

constructor TTestLevel.Create(ASuiteClass: CTestSuite; AParent: TTestLevel);
begin
  FSuiteClass := ASuiteClass;
  FParent     := AParent;
  LastIndex   := -1;
end;

destructor TTestLevel.Destroy;
begin
  DestroySuite();
  inherited;
end;

procedure TTestLevel.CreateSuite;
var i: Integer;
begin
  Assert(Suite = nil);
  Suite := FSuiteClass.Create();
  TestRunner.HandleCreateSuite(Suite);
  for i := 0 to High(FTests) do FTests[i].LastResult := trNone;
  LastIndex := -1;
end;

procedure TTestLevel.DestroySuite;
begin
  if Assigned(Suite) then
  begin
    TestRunner.HandleDestroySuite(Suite);
    Suite.Free();
    Suite := nil;    
  end;
  LastIndex := -1;  
end;

function TTestLevel.GetTotalChilds: Integer;
begin
  Result := Length(FChilds);
end;

function TTestLevel.GetChild(Index: Integer): TTestLevel;
begin
  Result := FChilds[Index];
end;

function TTestLevel.GetTotalTests: Integer;
begin
  Result := Length(FTests);
end;

function TTestLevel.GetTest(Index: Integer): TTest;
begin
  Result := FTests[Index];
end;

function TTestLevel.GetTotalTestCount: Integer;
var i: Integer;
begin
  Result := Length(FTests);
  for i := 0 to High(FChilds) do Result := Result + FChilds[i].GetTotalTestCount();
end;

function TTestLevel.RetrieveTests: Integer;
begin
  FTests := FSuiteClass.GetTests();
  Result := Length(FTests);
end;

function TTestLevel.RunTest(Index: Integer): TTestResult;
begin
  Result := trSuccess;
  // Destroy suite instance if new test cycle started
  if LastIndex > Index then DestroySuite();
  if Suite = nil then CreateSuite();
  LastIndex := Index;
  Suite.InitTest();
  try
    try
      Suite.FLastName := FTests[Index].Name;
      InvokeCommand(Suite, FTests[Index].Name);
    except
      on E: TTestFailException do
      begin
        FTests[Index].FailCodeLoc := E.CodeLocation;
        Result := trFail;
      end;
      on E: Exception do
      begin
        Result := trException;
        raise;
      end;
    end;
  finally
    FTests[Index].LastResult := Result;
    Suite.DoneTest();
  end;
end;

function TTestLevel.Run(RunChilds: TChildsRunCondition): Boolean;
var
  i: Integer;
  RunNext: Boolean;
  Res: TTestResult;
begin
  i := 0;
  RunNext := True;
  Res := trNone;
  while (i < Length(FTests)) do
  begin
    if RunNext and TestRunner.isTestEnabled(FTests[i]) then
    begin
      try
        Res := RunTest(i);
      except
        on E: Exception do
        begin
          Res := trException;
          TestRunner.HandleTestException(FTests[i], E);
        end;
      end;
      RunNext := TestRunner.HandleTestResult(FTests[i], Res);
    end else
    begin
      if RunNext then
        FTests[i].LastResult := trDisabled
      else
        FTests[i].LastResult := trSkipped;
      RunNext := TestRunner.HandleTestResult(FTests[i], FTests[i].LastResult) and RunNext;
    end;
    Inc(TestRunner.Stats[FTests[i].LastResult]);
    Inc(i);
  end;
  Result := i >= Length(FTests);

  if (RunChilds <> crcNever) and (Result or (RunChilds = crcAlways)) then
    for i := 0 to High(FChilds) do
      Result := FChilds[i].Run(RunChilds) and Result;
end;

procedure TTestLevel.AddChild(Level: TTestLevel);
begin
  SetLength(FChilds, Length(FChilds)+1);
  FChilds[High(FChilds)] := Level;
end;

{ TTestFailException }

constructor TTestFailException.Create(ACodeLocation: TCodeLocation; const AMsg: string);
begin
  inherited Create(AMsg);
  CodeLocation := ACodeLocation;
end;

{ TLogTestRunner }

function TLogTestRunner.DoRun(): Boolean;
begin
  Result := TestRoot.Run(crcAlways);

  Log('Test result statistics:');
  Log('  Not run:   ' + IntToStr(Stats[trNone]));
  Log('  Disabled:  ' + IntToStr(Stats[trDisabled]));
  Log('  Passed:    ' + IntToStr(Stats[trSuccess]));
  Log('  Failed:    ' + IntToStr(Stats[trFail]));
  Log('  Exception: ' + IntToStr(Stats[trException]));
  Log('  Error:     ' + IntToStr(Stats[trError]));
end;

procedure TLogTestRunner.HandleCreateSuite(Suite: TTestSuite);
begin
  Log('Created suite instance of class "' + Suite.ClassName + '"');
end;

procedure TLogTestRunner.HandleDestroySuite(Suite: TTestSuite);
begin
  Log('Destroyed suite instance of class "' + Suite.ClassName + '"');
end;

function TLogTestRunner.HandleTestResult(const ATest: TTest; TestResult: TTestResult): Boolean;
begin
  Result := not (TestResult in [trFail, trException, trError]);
  case TestResult of
    trNone: Log('  not run');
    trDisabled: Log('  disabled');
    trSuccess: Log('  passed');
    trFail: Log('  failed' + CodeLocToStr(ATest.FailCodeLoc));
    trException: Log('  exception');
    trError: Log('  error');
  end;
end;

procedure TLogTestRunner.HandleTestException(const ATest: TTest; E: Exception);
begin
  if Assigned(E) then
    LogError('Exception in test "' + String(ATest.Name) + '" with message: ' + E.Message);
end;

function TLogTestRunner.IsTestEnabled(const ATest: TTest): Boolean;
begin
  Result := True;
  Log('Test: "' + string(ATest.Name) + '"...');
end;

initialization
  TestSuites := TTestSuiteVector.Create();
  SetRunner(TLogTestRunner.Create);
finalization
  SetRunner(nil);
  TestSuites.Free;
  TestSuites := nil;
end.
