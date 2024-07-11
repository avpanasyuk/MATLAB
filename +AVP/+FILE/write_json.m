%>
%> @file write_json

function write_json(json_data, fileName)
  %> @param data : in format as created by "read_file"
  %> @param fileName (optional) : if omitted writes to stdout 
  if ~exist('fileName','var') || isempty(fileName)
    fid = 1;
  else
    fid = fopen(fileName,'wt');
    if fid == -1, error('Can not open file <%s>', fileName); end
    fprintf(2,'Writing %s\n',fileName);
  end
  fwrite(fid,jsonencode(json_data,'PrettyPrint',true));
  if fid > 1, fclose(fid); end
end


