function [Index, key] = pause_and_change_index(Index,LastValue, MorePrompts)
  %> function pauses and waits for user keypress. If it is
  %>  - q :returns LastValue + 1
  %>  - , :(or left arraw) - returns Index - 1 or LastValue if wrapped
  %>  -  everything else : returns Index + 1
  %> @note: you can not change counter inside FOR-loop, use WHILE
  %> keys:
  %> 'p' == 112

  Index = Index + 1; % by default go to next step
  Prompt = '< - previous, q - exit, k - keyboard, anything else - next';
  if exist('MorePrompts','var'), Prompt = [Prompt ', ' MorePrompts]; end
  
  key = AVP.getkey('Prompt', Prompt);
  switch key
    case {28,','}
      Index = Index - 2; if Index == 0, Index = LastValue; end
    case 'q'
      Index = LastValue + 1;
    case 'k'
      keyboard
    otherwise
  end  
end
