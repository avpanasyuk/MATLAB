% converts precision in form, say, 'uint8' into a number of bytes
function n_bytes = prec2n_bytes(prec)
        s = sscanf(prec,'%[a-z]%d'); % 'precision' ends with number of bits 
        n_bytes = s(end)/8;
end
