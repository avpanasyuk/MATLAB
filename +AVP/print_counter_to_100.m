function print_counter_to_100(counter,maximum,number)
  if ~AVP.is_defined('number'), number = 20; end % to fill 80 columns
  if mod(counter,fix(maximum/number)) == 0
     fprintf('%i%% ',floor(counter*100/maximum)); 
  end
  if counter == maximum, fprintf('\n'); end
end