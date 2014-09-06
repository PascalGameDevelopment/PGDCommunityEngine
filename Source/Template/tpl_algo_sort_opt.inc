(*
  Template quicksort algorithm option constants
*)

  {$IF (soDescending in _SortOptions)}
    {$DEFINE _SORTDESCENDING}
  {$IFEND}

  {$IF (soBadData in _SortOptions)}
    {$DEFINE _SORTBADDATA}
  {$IFEND}

