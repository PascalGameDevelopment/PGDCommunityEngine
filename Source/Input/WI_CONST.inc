{$IFDEF WINDOWS}
{$DEFINE _INPUT_KEYCODES_SET}
// Virtual key codes for Windows
  vkESCAPE          := 27;
  vk1               :=Ord('1');
  vk2               :=Ord('2');
  vk3               :=Ord('3');
  vk4               :=Ord('4');
  vk5               :=Ord('5');
  vk6               :=Ord('6');
  vk7               :=Ord('7');
  vk8               :=Ord('8');
  vk9               :=Ord('9');
  vk0               :=Ord('0');
  vkMINUS           :=189;    (* - on main keyboard *)
  vkEQUALS          :=187;
  vkBACK            :=8;      (* backspace *)
  vkTAB             :=9;
  vkQ               :=Ord('Q');
  vkW               :=Ord('W');
  vkE               :=Ord('E');
  vkR               :=Ord('R');
  vkT               :=Ord('T');
  vkY               :=Ord('Y');
  vkU               :=Ord('U');
  vkI               :=Ord('I');
  vkO               :=Ord('O');
  vkP               :=Ord('P');
  vkLBRACKET        :=219;
  vkRBRACKET        :=221;
  vkRETURN          :=13;     (* Enter on main keyboard *)
  vkLCONTROL        :=162;
  vkA               :=Ord('A');
  vkS               :=Ord('S');
  vkD               :=Ord('D');
  vkF               :=Ord('F');
  vkG               :=Ord('G');
  vkH               :=Ord('H');
  vkJ               :=Ord('J');
  vkK               :=Ord('K');
  vkL               :=Ord('L');
  vkSEMICOLON       :=186;
  vkAPOSTROPHE      :=222;
  vkGRAVE           :=192; (* accent grave *)
  vkLSHIFT          :=160;
  vkBACKSLASH       :=220;
  vkZ               :=Ord('Z');
  vkX               :=Ord('X');
  vkC               :=Ord('C');
  vkV               :=Ord('V');
  vkB               :=Ord('B');
  vkN               :=Ord('N');
  vkM               :=Ord('M');
  vkCOMMA           :=188;
  vkPERIOD          :=190;    (* . on main keyboard *)
  vkSLASH           :=191;    (* / on main keyboard *)
  vkRSHIFT          :=161;
  vkMULTIPLY        :=106;    (* * on numeric keypad *)
  vkLMENU           :=164;    (* left Alt *)
  vkSPACE           :=32;
  vkCAPITAL         :=20;
  vkF1              :=112;
  vkF2              :=113;
  vkF3              :=114;
  vkF4              :=115;
  vkF5              :=116;
  vkF6              :=117;
  vkF7              :=118;
  vkF8              :=119;
  vkF9              :=120;
  vkF10             :=121;
  vkNUMLOCK         :=144;
  vkSCROLL          :=145;    (* Scroll Lock *)
  vkNUMPAD7         :=36;
  vkNUMPAD8         :=38;
  vkNUMPAD9         :=33;
  vkSUBTRACT        :=109;    (* - on numeric keypad *)
  vkNUMPAD4         :=37;
  vkNUMPAD5         :=12;
  vkNUMPAD6         :=39;
  vkADD             :=107;    (* + on numeric keypad *)
  vkNUMPAD1         :=35;
  vkNUMPAD2         :=40;
  vkNUMPAD3         :=34;
  vkNUMPAD0         :=45;
  vkDECIMAL         :=46;     (* . on numeric keypad *)
  // $54 to $55 unassigned
  vkOEM_102         :=$56;    (* < > | on UK/Germany keyboards *)
  vkF11             :=122;
  vkF12             :=123;
  // $59 to $63 unassigned
  vkF13             :=$64;    (*                     (NEC PC98) *)
  vkF14             :=$65;    (*                     (NEC PC98) *)
  vkF15             :=$66;    (*                     (NEC PC98) *)
  // $67 to $6F unassigned
  vkKANA            :=$70;    (* (Japanese keyboard)            *)
  vkABNT_C1         :=$73;    (* / ? on Portugese (Brazilian) keyboards *)
  // $74 to $78 unassigned
  vkCONVERT         :=$79;    (* (Japanese keyboard)            *)
  // $7A unassigned
  vkNOCONVERT       :=$7B;    (* (Japanese keyboard)            *)
  // $7C unassigned
  vkYEN             :=$7D;    (* (Japanese keyboard)            *)
  vkABNT_C2         :=$7E;    (* Numpad . on Portugese (Brazilian) keyboards *)
  // $7F to 8C unassigned
  vkNUMPADEQUALS    :=13;     (* :=on numeric keypad (NEC PC98) *)
  // $8E to $8F unassigned
  vkCIRCUMFLEX      :=$90;    (* (Japanese keyboard)            *)
  vkAT              :=$91;    (*                     (NEC PC98) *)
  vkCOLON           :=$92;    (*                     (NEC PC98) *)
  vkUNDERLINE       :=$93;    (*                     (NEC PC98) *)
  vkKANJI           :=$94;    (* (Japanese keyboard)            *)
  vkSTOP            :=$95;    (*                     (NEC PC98) *)
  vkAX              :=$96;    (*                     (Japan AX) *)
  vkUNLABELED       :=$97;    (*                        (J3100) *)
  // $98 unassigned
  vkNEXTTRACK       :=$99;    (* Next Track *)
  // $9A to $9D unassigned    
  vkNUMPADENTER     :=13;     (* Enter on numeric keypad *)
  vkRCONTROL        :=163;
  // $9E to $9F unassigned
  vkMUTE            :=$A0;    (* Mute *)
  vkCALCULATOR      :=$A1;    (* Calculator *)
  vkPLAYPAUSE       :=$A2;    (* Play / Pause *)
  vkMEDIASTOP       :=$A4;    (* Media Stop *)
  // $A5 to $AD unassigned  
  vkVOLUMEDOWN      :=$AE;    (* Volume - *)
  // $AF unassigned  
  vkVOLUMEUP        :=$B0;    (* Volume + *)
  // $B1 unassigned  
  vkWEBHOME         :=$B2;    (* Web home *)
  vkNUMPADCOMMA     :=$B3;    (* , on numeric keypad (NEC PC98) *)
  // $B4 unassigned
  vkDIVIDE          :=111;    (* / on numeric keypad *)
  // $B6 unassigned
  vkSYSRQ           :=$B7;
  vkRMENU           :=165;    (* right Alt *)
  // $B9 to $C4 unassigned
  vkPAUSE           :=19;     (* Pause (watch out - not realiable on some kbds) *)
  // $C6 unassigned
  vkHOME            :=36;     (* Home on arrow keypad *)
  vkUP              :=38;     (* UpArrow on arrow keypad *)
  vkPRIOR           :=33;     (* PgUp on arrow keypad *)
  // $CA unassigned
  vkLEFT            :=37;     (* LeftArrow on arrow keypad *)
  // $CC unassigned  
  vkRIGHT           :=39;     (* RightArrow on arrow keypad *)
  // $CE unassigned
  vkEND             :=35;     (* End on arrow keypad *)
  vkDOWN            :=40;     (* DownArrow on arrow keypad *)
  vkNEXT            :=34;     (* PgDn on arrow keypad *)
  vkINSERT          :=45;     (* Insert on arrow keypad *)
  vkDELETE          :=46;     (* Delete on arrow keypad *)
  vkLOS             :=91;     (* Left Windows key *)
  vkROS             :=92;     (* Right Windows key *)
  vkAPPS            :=93;     (* AppMenu key *)
  vkPOWER           :=$DE;
  vkSLEEP           :=$DF;
  // $E0 to $E2 unassigned
  vkWAKE            :=$E3;    (* System Wake *)
  // $E4 unassigned
  vkWEBSEARCH       :=$E5;    (* Web Search *)
  vkWEBFAVORITES    :=$E6;    (* Web Favorites *)
  vkWEBREFRESH      :=$E7;    (* Web Refresh *)
  vkWEBSTOP         :=$E8;    (* Web Stop *)
  vkWEBFORWARD      :=$E9;    (* Web Forward *)
  vkWEBBACK         :=$EA;    (* Web Back *)
  vkMYCOMPUTER      :=$EB;    (* My Computer *)
  vkMAIL            :=$EC;    (* Mail *)
  vkMEDIASELECT     :=$ED;    (* Media Select *)


(*
 *  Alternate names for keys, to facilitate transition from DOS.
 *)
  vkBACKSPACE      :=vkBACK;      (* backspace *)
  vkNUMPADSTAR     :=vkMULTIPLY;  (* * on numeric keypad *)
  vkLALT           :=vkLMENU;     (* left Alt *)
  vkCAPSLOCK       :=vkCAPITAL;   (* CapsLock *)
  vkNUMPADMINUS    :=vkSUBTRACT;  (* - on numeric keypad *)
  vkNUMPADPLUS     :=vkADD;       (* + on numeric keypad *)
  vkNUMPADPERIOD   :=vkDECIMAL;   (* . on numeric keypad *)
  vkNUMPADSLASH    :=vkDIVIDE;    (* / on numeric keypad *)
  vkRALT           :=vkRMENU;     (* right Alt *)
  vkUPARROW        :=vkUP;        (* UpArrow on arrow keypad *)
  vkPGUP           :=vkPRIOR;     (* PgUp on arrow keypad *)
  vkLEFTARROW      :=vkLEFT;      (* LeftArrow on arrow keypad *)
  vkRIGHTARROW     :=vkRIGHT;     (* RightArrow on arrow keypad *)
  vkDOWNARROW      :=vkDOWN;      (* DownArrow on arrow keypad *)
  vkPGDN           :=vkNEXT;      (* PgDn on arrow keypad *)

(*
 *  Alternate names for keys originally not used on US keyboards.
 *)

  vkPREVTRACK      :=vkCIRCUMFLEX;  (* Japanese keyboard *)

  vkMOUSELEFT       :=$1;
  vkMOUSERIGHT      :=$2;
  vkMOUSEMIDDLE     :=$4;

  vkSHIFT :=16;
  vkCONTROL :=17;
  vkALT :=18;

  vkMOUSEBUTTON[mbLeft]    := vkMOUSELEFT;
  vkMOUSEBUTTON[mbRight]   := vkMOUSERIGHT;
  vkMOUSEBUTTON[mbMiddle]  := vkMOUSEMIDDLE;
  vkMOUSEBUTTON[mbCustom1] := vkNONE;
{$ENDIF}
