function  hex_hash = get_hex_hash_str(anything)
  AVP.CRC16_CCITT();
  hex_hash = dec2hex(AVP.CRC16_CCITT(AVP.CONVERT.something2bytes(anything)));
end
