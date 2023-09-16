function data = read_json(fileName)
  %> opens JSON file, reads, decodes and closes
  fid = fopen(fileName,'rt');
  if fid == -1, error('Can not open file <%s>', fileName); end
  fprintf('Reading %s\n',fileName);
  raw = fread(fid,inf);
  str = char(raw'); % Transformation
  fclose(fid);
  data = jsondecode(str); % Using the jsondecode function to parse JSON from string
end
