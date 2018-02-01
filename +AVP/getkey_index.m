function cont = getkey_index(IndexName,LastValue)
  %> function works in construction
  %> WHILE AVP.getkey_index(IndexName,LastValue), where 
  %> it pauses and waits for user keypress
  %> @param IndexName is the name of cycle variable which may not be
  %>         created apriory. If it does not exist it starts with 1
  %> @param LastValue is the last value after which cycle ends
  %> If user presses:
  %>  - q :returns false
  %>  - , :(or left arraw) - decreases Index (may wrap)
  %>  -  everything else : - increases Index and returns Index <= LastValue
  
  if evalin('caller',['exist(''',IndexName,''')'])
    Index = evalin('caller',IndexName);
  else
    Index = 0;
  end
  switch AVP.getkey('Prompt','< - previous, q - exit, anything else - next:')
    case {28,44}
      Index = Index - 1; if Index <= 0, Index = LastValue; end
    case 113
      Index = LastValue + 1;
    otherwise
      Index = Index + 1;
  end
  cont = Index <= LastValue;
  assignin('caller',IndexName,Index);  
end
