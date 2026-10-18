`timescale 1ns/1ps
// NVMe reliability block (simple version): one 16-byte data block in, and
//  - write path (mode 0): AES-128 encrypt + generate PI (CRC-16 Guard, App Tag, Ref Tag) + CRC-32C Guard + byte parity
//  - read path  (mode 1): same, and CHECK the PI / parity that came with the block
module nvme_rel (
   input  logic         clk,
   input  logic         rst_n,
   input  logic         in_valid,
   output logic         in_ready,
   input  logic         in_mode,          // 0 = write path, 1 = read path
   input  logic [127:0] in_data,          // byte 0 = in_data[127:120]
   input  logic [127:0] in_key,
   input  logic [31:0]  in_lba,
   input  logic [15:0]  in_app_tag,
   input  logic [15:0]  in_guard16,       // read path: PI received with the block
   input  logic [31:0]  in_guard32,
   input  logic [31:0]  in_ref_tag,
   input  logic [15:0]  in_parity,
   output logic         out_valid,
   output logic         out_mode,
   output logic [127:0] out_cipher,
   output logic [15:0]  out_guard16,
   output logic [15:0]  out_app_tag,
   output logic [31:0]  out_ref_tag,
   output logic [31:0]  out_guard32,
   output logic [15:0]  out_parity,
   output logic         out_guard16_err,
   output logic         out_guard32_err,
   output logic         out_reftag_err,
   output logic         out_parity_err);

  localparam logic [7:0] SBOX [256] = '{
8'h63, 8'h7c, 8'h77, 8'h7b, 8'hf2, 8'h6b, 8'h6f, 8'hc5, 8'h30, 8'h01, 8'h67, 8'h2b, 8'hfe, 8'hd7, 8'hab, 8'h76,
8'hca, 8'h82, 8'hc9, 8'h7d, 8'hfa, 8'h59, 8'h47, 8'hf0, 8'had, 8'hd4, 8'ha2, 8'haf, 8'h9c, 8'ha4, 8'h72, 8'hc0,
8'hb7, 8'hfd, 8'h93, 8'h26, 8'h36, 8'h3f, 8'hf7, 8'hcc, 8'h34, 8'ha5, 8'he5, 8'hf1, 8'h71, 8'hd8, 8'h31, 8'h15,
8'h04, 8'hc7, 8'h23, 8'hc3, 8'h18, 8'h96, 8'h05, 8'h9a, 8'h07, 8'h12, 8'h80, 8'he2, 8'heb, 8'h27, 8'hb2, 8'h75,
8'h09, 8'h83, 8'h2c, 8'h1a, 8'h1b, 8'h6e, 8'h5a, 8'ha0, 8'h52, 8'h3b, 8'hd6, 8'hb3, 8'h29, 8'he3, 8'h2f, 8'h84,
8'h53, 8'hd1, 8'h00, 8'hed, 8'h20, 8'hfc, 8'hb1, 8'h5b, 8'h6a, 8'hcb, 8'hbe, 8'h39, 8'h4a, 8'h4c, 8'h58, 8'hcf,
8'hd0, 8'hef, 8'haa, 8'hfb, 8'h43, 8'h4d, 8'h33, 8'h85, 8'h45, 8'hf9, 8'h02, 8'h7f, 8'h50, 8'h3c, 8'h9f, 8'ha8,
8'h51, 8'ha3, 8'h40, 8'h8f, 8'h92, 8'h9d, 8'h38, 8'hf5, 8'hbc, 8'hb6, 8'hda, 8'h21, 8'h10, 8'hff, 8'hf3, 8'hd2,
8'hcd, 8'h0c, 8'h13, 8'hec, 8'h5f, 8'h97, 8'h44, 8'h17, 8'hc4, 8'ha7, 8'h7e, 8'h3d, 8'h64, 8'h5d, 8'h19, 8'h73,
8'h60, 8'h81, 8'h4f, 8'hdc, 8'h22, 8'h2a, 8'h90, 8'h88, 8'h46, 8'hee, 8'hb8, 8'h14, 8'hde, 8'h5e, 8'h0b, 8'hdb,
8'he0, 8'h32, 8'h3a, 8'h0a, 8'h49, 8'h06, 8'h24, 8'h5c, 8'hc2, 8'hd3, 8'hac, 8'h62, 8'h91, 8'h95, 8'he4, 8'h79,
8'he7, 8'hc8, 8'h37, 8'h6d, 8'h8d, 8'hd5, 8'h4e, 8'ha9, 8'h6c, 8'h56, 8'hf4, 8'hea, 8'h65, 8'h7a, 8'hae, 8'h08,
8'hba, 8'h78, 8'h25, 8'h2e, 8'h1c, 8'ha6, 8'hb4, 8'hc6, 8'he8, 8'hdd, 8'h74, 8'h1f, 8'h4b, 8'hbd, 8'h8b, 8'h8a,
8'h70, 8'h3e, 8'hb5, 8'h66, 8'h48, 8'h03, 8'hf6, 8'h0e, 8'h61, 8'h35, 8'h57, 8'hb9, 8'h86, 8'hc1, 8'h1d, 8'h9e,
8'he1, 8'hf8, 8'h98, 8'h11, 8'h69, 8'hd9, 8'h8e, 8'h94, 8'h9b, 8'h1e, 8'h87, 8'he9, 8'hce, 8'h55, 8'h28, 8'hdf,
8'h8c, 8'ha1, 8'h89, 8'h0d, 8'hbf, 8'he6, 8'h42, 8'h68, 8'h41, 8'h99, 8'h2d, 8'h0f, 8'hb0, 8'h54, 8'hbb, 8'h16};

  // ---------------- CRC-16 T10-DIF: poly 0x8BB7, init 0, MSB first ----------------
  function automatic logic [15:0] crc16(logic [127:0] d);
    logic [15:0] c = 16'h0000;
    for (int i = 0; i < 16; i++) begin
      c = c ^ {d[127 - 8*i -: 8], 8'h00};
      for (int b = 0; b < 8; b++)
        c = c[15] ? ((c << 1) ^ 16'h8BB7) : (c << 1);
    end
    return c;
  endfunction

  // ---------------- CRC-32C (Castagnoli): reflected poly 0x82F63B78, init and final XOR 0xFFFFFFFF ----------------
  function automatic logic [31:0] crc32c(logic [127:0] d);
    logic [31:0] c = 32'hFFFF_FFFF;
    for (int i = 0; i < 16; i++) begin
      c = c ^ {24'h0, d[127 - 8*i -: 8]};
      for (int b = 0; b < 8; b++)
        c = c[0] ? ((c >> 1) ^ 32'h82F6_3B78) : (c >> 1);
    end
    return c ^ 32'hFFFF_FFFF;
  endfunction

  // ---------------- even parity per byte: bit 15 = byte 0 ----------------
  function automatic logic [15:0] parity16(logic [127:0] d);
    logic [15:0] p;
    for (int i = 0; i < 16; i++) p[15 - i] = ^d[127 - 8*i -: 8];
    return p;
  endfunction

  // ---------------- AES-128 helpers (FIPS-197) ----------------
  function automatic logic [7:0] xtime(logic [7:0] b);       // multiply by 2 in GF(2^8)
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1B : 8'h00);
  endfunction

  function automatic logic [127:0] aes_round(logic [127:0] s, logic [127:0] rk, logic last);
    logic [7:0] b [16];
    logic [7:0] t [16];
    for (int i = 0; i < 16; i++) b[i] = SBOX[s[127 - 8*i -: 8]];            // SubBytes
    for (int c = 0; c < 4; c++)                                              // ShiftRows
      for (int r = 0; r < 4; r++) t[4*c + r] = b[4*((c + r) % 4) + r];
    if (!last)
      for (int c = 0; c < 4; c++) begin                                      // MixColumns
        logic [7:0] a0, a1, a2, a3;
        a0 = t[4*c]; a1 = t[4*c+1]; a2 = t[4*c+2]; a3 = t[4*c+3];
        t[4*c]   = xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3;
        t[4*c+1] = a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3;
        t[4*c+2] = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3);
        t[4*c+3] = (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3);
      end
    for (int i = 0; i < 16; i++) aes_round[127 - 8*i -: 8] = t[i] ^ rk[127 - 8*i -: 8];   // AddRoundKey
  endfunction

  function automatic logic [127:0] next_key(logic [127:0] k, logic [7:0] rcon);   // key expansion, one round
    logic [31:0] w0, w1, w2, w3, t;
    {w0, w1, w2, w3} = k;
    t  = {SBOX[w3[23:16]] ^ rcon, SBOX[w3[15:8]], SBOX[w3[7:0]], SBOX[w3[31:24]]};   // RotWord + SubWord + Rcon
    w0 = w0 ^ t;  w1 = w1 ^ w0;  w2 = w2 ^ w1;  w3 = w3 ^ w2;
    return {w0, w1, w2, w3};
  endfunction

  function automatic logic [7:0] rcon_of(logic [3:0] r);
    case (r)
      1: return 8'h01;  2: return 8'h02;  3: return 8'h04;  4: return 8'h08;  5: return 8'h10;
      6: return 8'h20;  7: return 8'h40;  8: return 8'h80;  9: return 8'h1B;  default: return 8'h36;
    endcase
  endfunction

  // ---------------- control: accept -> 10 AES rounds (one per clock) -> out_valid ----------------
  logic         busy;
  logic [3:0]   round;
  logic [127:0] state, rkey, rkey_n;

  assign in_ready = !busy;
  assign rkey_n   = next_key(rkey, rcon_of(round));

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy <= 1'b0;  round <= '0;  state <= '0;  rkey <= '0;  out_valid <= 1'b0;
      {out_mode, out_cipher, out_guard16, out_app_tag, out_ref_tag, out_guard32, out_parity} <= '0;
      {out_guard16_err, out_guard32_err, out_reftag_err, out_parity_err} <= '0;
    end else begin
      out_valid <= 1'b0;
      if (in_valid && in_ready) begin
        logic escape;
        escape          = (in_app_tag == 16'hFFFF);            // App Tag FFFFh: PI checks disabled (Type 1)
        state           <= in_data ^ in_key;                  // round 0: AddRoundKey
        rkey            <= in_key;
        round           <= 4'd1;
        busy            <= 1'b1;
        out_mode        <= in_mode;
        out_guard16     <= crc16(in_data);
        out_guard32     <= crc32c(in_data);
        out_parity      <= parity16(in_data);
        out_app_tag     <= in_app_tag;
        out_ref_tag     <= in_lba;                            // Type 1: Ref Tag = low 32 bits of the LBA
        out_guard16_err <= in_mode && !escape && (crc16(in_data)  != in_guard16);
        out_guard32_err <= in_mode && !escape && (crc32c(in_data) != in_guard32);
        out_reftag_err  <= in_mode && !escape && (in_ref_tag != in_lba);
        out_parity_err  <= in_mode && (parity16(in_data) != in_parity);
      end else if (busy) begin
        logic [127:0] nxt;
        nxt   = aes_round(state, rkey_n, round == 4'd10);    // rounds 1..9 full, round 10 without MixColumns
        state <= nxt;
        rkey  <= rkey_n;
        if (round == 4'd10) begin
          out_cipher <= nxt;                                  // ciphertext ready
          busy       <= 1'b0;
          out_valid  <= 1'b1;
        end else
          round <= round + 1;
      end
    end
  end

endmodule
