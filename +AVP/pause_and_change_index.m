function Index = pause_and_change_index(Index,LastValue)
  %> function pauses and waits for user keypress. If it is
  %>  - q :returns LastValue + 1
  %>  - , :(or left arraw) - returns Index - 1 or LastValue if wrapped
  %>  -  everything else : returns Index + 1
  
  Index = Index + 1;
  switch AVP.getkey('Prompt','< - previous, q - exit, anything else - next:')
    case {28,44}
      Index = Index - 2; if Index == 0, Index = LastValue; end
    case 113
      Index = LastValue + 1;
    otherwise
  end  
end
