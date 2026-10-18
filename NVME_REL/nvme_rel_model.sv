// reference model: the same algorithms written a second way (S-box computed from the math, table-driven CRCs)
class nvme_rel_model;
  static bit [7:0]  sbox[256];
  static bit [15:0] t16[256];
  static bit [31:0] t32[256];
  static bit        built = 0;

  static function bit [7:0] gmul(bit [7:0] a, bit [7:0] b);        // multiply in GF(2^8)
    bit [7:0] p = 0;
    for (int i = 0; i < 8; i++) begin
      if (b[0]) p ^= a;
      a = {a[6:0], 1'b0} ^ (a[7] ? 8'h1B : 8'h00);
      b >>= 1;
    end
    return p;
  endfunction

  static function void build();
    if (built) return;
    for (int a = 0; a < 256; a++) begin                            // S-box = affine(inverse(a))
      bit [7:0] inv = 0, s;
      if (a != 0) for (int x = 1; x < 256; x++) if (gmul(a, x) == 1) inv = x;
      s = inv ^ {inv[6:0], inv[7]} ^ {inv[5:0], inv[7:6]} ^ {inv[4:0], inv[7:5]} ^ {inv[3:0], inv[7:4]} ^ 8'h63;
      sbox[a] = s;
    end
    for (int b = 0; b < 256; b++) begin                            // CRC lookup tables
      bit [15:0] c = b << 8;
      bit [31:0] r = b;
      for (int k = 0; k < 8; k++) begin
        c = c[15] ? ((c << 1) ^ 16'h8BB7) : (c << 1);
        r = r[0] ? ((r >> 1) ^ 32'h82F63B78) : (r >> 1);
      end
      t16[b] = c;  t32[b] = r;
    end
    built = 1;
  endfunction

  static function bit [7:0] byte_of(bit [127:0] d, int i); return d[127 - 8*i -: 8]; endfunction

  static function bit [15:0] crc16(bit [127:0] d);                 // T10-DIF, table driven
    bit [15:0] c = 0;
    build();
    for (int i = 0; i < 16; i++) c = (c << 8) ^ t16[c[15:8] ^ byte_of(d, i)];
    return c;
  endfunction

  static function bit [31:0] crc32c(bit [127:0] d);                // Castagnoli, reflected, table driven
    bit [31:0] c = 32'hFFFF_FFFF;
    build();
    for (int i = 0; i < 16; i++) c = (c >> 8) ^ t32[c[7:0] ^ byte_of(d, i)];
    return ~c;
  endfunction

  static function bit [15:0] parity16(bit [127:0] d);
    bit [15:0] p;
    for (int i = 0; i < 16; i++) p[15 - i] = ^byte_of(d, i);
    return p;
  endfunction

  static function bit [127:0] aes128(bit [127:0] pt, bit [127:0] key);   // FIPS-197, byte arrays
    bit [7:0] s[16], t[16], w[176], rc;
    build();
    for (int i = 0; i < 16; i++) begin s[i] = byte_of(pt, i); w[i] = byte_of(key, i); end
    rc = 8'h01;
    for (int i = 16; i < 176; i += 4) begin                        // full key schedule: 11 round keys
      bit [7:0] k0, k1, k2, k3, tmp;
      k0 = w[i-4]; k1 = w[i-3]; k2 = w[i-2]; k3 = w[i-1];
      if (i % 16 == 0) begin
        tmp = k0; k0 = sbox[k1] ^ rc; k1 = sbox[k2]; k2 = sbox[k3]; k3 = sbox[tmp];
        rc = gmul(rc, 2);
      end
      w[i] = w[i-16] ^ k0; w[i+1] = w[i-15] ^ k1; w[i+2] = w[i-14] ^ k2; w[i+3] = w[i-13] ^ k3;
    end
    for (int i = 0; i < 16; i++) s[i] ^= w[i];
    for (int r = 1; r <= 10; r++) begin
      for (int i = 0; i < 16; i++) s[i] = sbox[s[i]];
      for (int c = 0; c < 4; c++) for (int q = 0; q < 4; q++) t[4*c + q] = s[4*((c + q) % 4) + q];
      for (int c = 0; c < 4; c++) begin
        if (r < 10) begin
          s[4*c]   = gmul(t[4*c], 2) ^ gmul(t[4*c+1], 3) ^ t[4*c+2] ^ t[4*c+3];
          s[4*c+1] = t[4*c] ^ gmul(t[4*c+1], 2) ^ gmul(t[4*c+2], 3) ^ t[4*c+3];
          s[4*c+2] = t[4*c] ^ t[4*c+1] ^ gmul(t[4*c+2], 2) ^ gmul(t[4*c+3], 3);
          s[4*c+3] = gmul(t[4*c], 3) ^ t[4*c+1] ^ t[4*c+2] ^ gmul(t[4*c+3], 2);
        end else
          for (int q = 0; q < 4; q++) s[4*c + q] = t[4*c + q];
      end
      for (int i = 0; i < 16; i++) s[i] ^= w[16*r + i];
    end
    for (int i = 0; i < 16; i++) aes128[127 - 8*i -: 8] = s[i];
  endfunction
endclass
