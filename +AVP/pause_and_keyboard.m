function pause_and_keyboard()
  %> function pauses and waits for user keypress. If it is 'k' turns on
  %> "keyboard"
  if AVP.getkey('Prompt', 'PAUSED, PRESS ANY KEY, "k" calls keyboard which can be exited with "dbcont"') == 'k', keyboard; end
end
