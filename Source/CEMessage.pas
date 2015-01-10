(******************************************************************************

  Pascal Game Development Community Engine (PGDCE)

  The contents of this file are subject to the license defined in the file
  'licence.md' which accompanies this file; you may not use this file except
  in compliance with the license.

  This file is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
  either express or implied.  See the license for the specific language governing
  rights and limitations under the license.

  The Original Code is CEMessage.pas

  The Initial Developer of the Original Code is documented in the accompanying
  help file PGDCE.chm.  Portions created by these individuals are Copyright (C)
  2014 of these individuals.

******************************************************************************)

{
@abstract(PGDCE message unit)

Base message class and message management classes

@author(George Bakhtadze (avagames@gmail.com))
}

{$I PGDCE.inc}
unit CEMessage;

interface

const
  // Message pool grow step
  MessagesCapacityStep = 16;
  // Initial capacity of messages pool in bytes
  MessagePoolInitialCapacity = 65536;
  MessagePoolMaxCapacity = 65536 * 256;

type
  // Message flag
  TMessageFlag = (// Message has been discarded. No need to forward it further.
                  mfInvalid,
                  // Message is directed to a particular recipient
                  mfRecipient,
                  // Message is a notification message from parent to immediate childs
                  mfChilds,
                  // Message is a broadcasted message from some item down through hierarchy
                  mfBroadcast,
                  // Message's destination is core handler
                  mfCore,
                  // Message is asyncronous
                  mfAsync);
  // Message flag set
  TMessageFlags = set of TMessageFlag;

  { @Abstract(Base class for all message classes)
    Messages are stored in specific pool (see @Link(TMessagePool)) to speed-up allocation and avoid memory leaks. <br>
    As a consequence, messages can be created in such way: <i>SomeObject.HandleMessage(TCEMessage.Create)</i> without risk of a memory leak. <br>
    TODO: Temporary restriction: Do not use in message classes types which need finalization (such as dynamic arrays or long strings) this will cause memory leaks. Use short strings instead. }
  TCEMessage = class(TObject)
  private
    FFlags: TMessageFlags;
  public
    // This method overridden to store messages in specific pool
    class function NewInstance: TObject; override;
    // If you erroneously deallocate a message manually the overridden implementation of this method will signal you
    procedure FreeInstance; override;

    // Call this method if you don't want the message to be broadcasted
    procedure Invalidate;

    // Message flags
    property Flags: TMessageFlags read FFlags write FFlags;
  end;

  // Message class reference
  CMessage = class of TCEMessage;

  TCESubSystem = class
  public
    procedure HandleMessage(const Msg: TCEMessage); virtual;
  end;

  // Message pool data structure
  TPool = record
    Store: Pointer;
    Size:  Cardinal;
  end;
  PPool = ^TPool;

  { @Abstract(Message pool class)
    The class implements memory management for all instances of @Link(TCEMessage) and its descendant classes }
  TCEMessagePool = class
  private
    CurrentPool, BackPool: PPool;
    FCapacity: Cardinal;
    procedure SetCapacity(ACapacity: Cardinal);
    procedure SwapPools;
    function Allocate(Size: Cardinal): Pointer;
  public
    constructor Create;
    destructor Destroy; override;

    // Begins message handling. Should be called once per main applicatin cycle
    procedure BeginHandle;
    // Ends message handling and clears messages. Should be called once per main applicatin cycle after <b>BeginHandle</b>
    procedure EndHandle;
  end;

  // Array of messages
  TCEMessages = array of TCEMessage;

  // Message handler delegate
  TCEMessageHandler = procedure(const Msg: TCEMessage) of object;

  { @Abstract(Asynchronous messages queue implementation)
    The class provides the possibility to handle asynchronous messages. <br>
    Message handlers can generate other asynchronous messages which will be handled during next handling cycle.
    If you use this class there is no need to call any methods of @Link(TMessagePool). }
  TMessageSubsystem = class
  private
    HandleStarted: Boolean;
    BackMessages, Messages:  TCEMessages;
    TotalMessages, TotalBackMessages, CurrentMessageIndex: Integer;
    procedure SwapPools;
  public
    { Locks current message queue. Should be called before message handling cycle. <br>
      All asynchronous messages generated during handling will be available during next handling cycle. <br>
      Calls @Link(TMessagePool).BeginHandle so application has no need to call it. }
    procedure BeginHandle;
    // Should be called after handling cycle. Calls @Link(TMessagePool).EndHandle so application has no need to call it
    procedure EndHandle;
    // Add an asynchronous message to the queue
    procedure Add(const Msg: TCEMessage);
    { Extracts a message from the queue if any, places it to <b>Msg</b> and returns @True if there was a message in queue.
      Otherwise returns @False and @nil in <b>Msg</b>. Should be called only between BeginHandle and EndHandle calls. }
    function ExtractMessage(out Msg: TCEMessage): Boolean;
  end;

  // Base class for notification messages
  TNotificationMessage = class(TCEMessage)
  end;

  // This message is sent to an object when it should reset its timer if any
  TSyncTimeMsg = class(TNotificationMessage)
  end;

  // Pause begin message
  TPauseMsg = class(TCEMessage)
  end;
  // Pause end message
  TResumeMsg = class(TCEMessage)
  end;
  // Progress report message
  TProgressMsg = class(TCEMessage)
  public
    // Progress indicator ranging from 0 to 1
    Progress: Single;
    constructor Create(AProgress: Single);
  end;

  // Base class for operating system messages
  TOSMessage = class(TCEMessage)
  end;

  // Indicates than application has been activated
  TAppActivateMsg = class(TOSMessage)
  end;

  // Indicates than application has been deactivated
  TAppDeactivateMsg = class(TOSMessage)
  end;

  // Indicates than application's main window position has been changed
  TWindowMoveMsg = class(TOSMessage)
  public
    NewX, NewY: Single;
    // X, Y - new window position in screen coordinates
    constructor Create(X, Y: Single);
  end;

  // Indicates than application's main window size has been changed
  TWindowResizeMsg = class(TOSMessage)
  public
    OldWidth, OldHeight, NewWidth, NewHeight: Single;
    // <b>OldWidth, OldHeight</b> - old size of the window, <b>NewWidth, NewHeight</b> - new size
    constructor Create(AOldWidth, AOldHeight, ANewWidth, ANewHeight: Single);
  end;

  // Indicates than application's main window has been minimized
  TWindowMinimizeMsg = class(TOSMessage)
  end;

  // If some data may be referenced by pointer and the pointer to the data has changed this message is broadcasted with new pointer
  TDataAdressChangeMsg = class(TNotificationMessage)
  public
    OldData, NewData: Pointer;
    DataReady: Boolean;
    // <b>AOldValue</b> - old pointer, <b>ANewValue</b> - new pointer to the data, <b>ADataReady</b> - determines wheter the data is ready to use
    constructor Create(AOldValue, ANewValue: Pointer; ADataReady: Boolean);
  end;

  // This message is broadcasted when some data has been modified
  TDataModifyMsg = class(TNotificationMessage)
  public
    // Pointer, identifying the data. usually it's the address of the data in memory
    Data: Pointer;
    // AData - a pointer, identifying the data. usually it's the address of the data in memory
    constructor Create(AData: Pointer);
  end;

var
  MessagePool: TCEMessagePool;

implementation

{ TCEMessage }

class function TCEMessage.NewInstance: TObject;
begin
//  Result := InitInstance(MessagePool.Allocate(InstanceSize));
  Result := TObject(MessagePool.Allocate(InstanceSize));
  PInteger(Result)^ := Integer(Self);
end;

procedure TCEMessage.FreeInstance;
begin
  Assert(False, 'TCEMessage and descendants should not be freed manually');
end;

procedure TCEMessage.Invalidate;
begin
  Include(FFlags, mfInvalid);
end;

{ TWindowMoveMsg }

constructor TWindowMoveMsg.Create(X, Y: Single);
begin
  NewX := X; NewY := Y;
end;

{ TWindowResizeMsg }

constructor TWindowResizeMsg.Create(AOldWidth, AOldHeight, ANewWidth, ANewHeight: Single);
begin
  OldWidth  := AOldWidth;
  OldHeight := AOldHeight;
  NewWidth  := ANewWidth;
  NewHeight := ANewHeight;
end;

{ TDataAdressChangeMsg }

constructor TDataAdressChangeMsg.Create(AOldValue, ANewValue: Pointer; ADataReady: Boolean);
begin
  OldData   := AOldValue;
  NewData   := ANewValue;
  DataReady := ADataReady;
end;

{ TDataModifyMsg }

constructor TDataModifyMsg.Create(AData: Pointer);
begin
  Data := AData;
end;

{ TMessageSubsystem }

procedure TMessageSubsystem.SwapPools;
var t: TCEMessages;
begin
  t            := BackMessages;
  BackMessages := Messages;
  Messages       := t;
  t              := nil;

  TotalBackMessages := TotalMessages;
  TotalMessages := 0;
end;

procedure TMessageSubsystem.BeginHandle;
begin
  HandleStarted := True;
  SwapPools;
  CurrentMessageIndex := 0;
  MessagePool.BeginHandle;
end;

procedure TMessageSubsystem.EndHandle;
begin
  Assert(HandleStarted, 'TMessageSubsystem.EndHandle: Invalid call');
  HandleStarted := False;
  MessagePool.EndHandle;
end;

procedure TMessageSubsystem.Add(const Msg: TCEMessage);
begin
  if Length(Messages) <= TotalMessages then SetLength(Messages, Length(Messages) + MessagesCapacityStep);
  Messages[TotalMessages] := Msg;
  Inc(TotalMessages);
end;

function TMessageSubsystem.ExtractMessage(out Msg: TCEMessage): Boolean;
begin                                           // ToDo: Needs testing
  Assert(HandleStarted, 'TMessageSubsystem.ExtractMessage: Should be called only between BeginHandle and EndHandle pair');
  Msg := nil;
  if CurrentMessageIndex < TotalBackMessages then begin
    Msg := BackMessages[CurrentMessageIndex];
    Inc(CurrentMessageIndex);
  end;
  Result := Msg <> nil;
end;

{ TCEMessagePool }

procedure TCEMessagePool.SetCapacity(ACapacity: Cardinal);
begin
  FCapacity := ACapacity;
  ReAllocMem(CurrentPool^.Store, ACapacity);
  ReAllocMem(BackPool^.Store, ACapacity);
end;

procedure TCEMessagePool.SwapPools;
var Temp: Pointer;
begin
  Temp := BackPool;
  BackPool := CurrentPool;
  CurrentPool := Temp;
end;

constructor TCEMessagePool.Create;
begin
  New(CurrentPool);
  CurrentPool^.Store := nil;
  CurrentPool^.Size  := 0;
  New(BackPool);
  BackPool^.Store := nil;
  BackPool^.Size  := 0;
  SetCapacity(MessagePoolInitialCapacity);
end;

destructor TCEMessagePool.Destroy;
begin
  SetCapacity(0);
  Dispose(CurrentPool);
  Dispose(BackPool);
  inherited;
end;

function TCEMessagePool.Allocate(Size: Cardinal): Pointer;
var NewCapacity: Integer;
begin
  Assert(CurrentPool^.Size + Size < MessagePoolMaxCapacity, 'Message pool is full');       // Todo: Handle this situation
  if CurrentPool^.Size + Size > FCapacity then begin
    NewCapacity := FCapacity + MessagePoolInitialCapacity;
    if NewCapacity > MessagePoolMaxCapacity then NewCapacity := MessagePoolMaxCapacity;
    SetCapacity(NewCapacity);
  end;

  Result := Pointer(Cardinal(CurrentPool^.Store) + CurrentPool^.Size);
  Inc(CurrentPool^.Size, Size);
end;

procedure TCEMessagePool.BeginHandle;
begin
  SwapPools;
end;

procedure TCEMessagePool.EndHandle;
begin
  BackPool^.Size := 0;
end;

{ TProgressMsg }

constructor TProgressMsg.Create(AProgress: Single);
begin
  Progress := AProgress;
end;

{ TCESubSystem }

procedure TCESubSystem.HandleMessage(const Msg: TCEMessage);
begin
// no action
end;

initialization
  MessagePool := TCEMessagePool.Create();
finalization
  MessagePool.Free;
  MessagePool := nil;
end.

