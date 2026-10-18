// One PCIe Memory Write TLP (PCIe Base Spec header layout; the same TLP format is used from Gen1 to Gen5)
class tlp_item extends uvm_sequence_item;
  `uvm_object_utils(tlp_item)
  rand bit [2:0]  fmt;          // 010 = 3-DW header with data, 011 = 4-DW header with data
  rand bit [4:0]  typ;          // 00000 = Memory Request
  rand bit [9:0]  length;       // payload length in DWORDs
  rand bit [15:0] req_id;       // Requester ID: bus/device/function
  rand bit [7:0]  tag;
  rand bit [3:0]  first_be, last_be;
  rand bit [63:0] addr;
  rand bit [31:0] payload[];
  rand bit        target;       // 0 = data window, 1 = doorbell
  rand int        idle_cycles;
  rand bit        bad_len, bad_type, bad_addr;   // error knobs

  constraint c_type     { fmt inside {3'b010, 3'b011}; typ == 5'b00000; }                       // 1
  constraint c_fmt_addr { (fmt == 3'b011) == (addr[63:32] != 0); addr[1:0] == 0; }              // 2: 4-DW only above 4 GB
  constraint c_target   { target dist {0 := 80, 1 := 20}; }                                    // 3
  // 4: inside the window AND the last byte in the same 4 KB page. Written this way on purpose:
  //    "addr + length*4 <= WIN_BASE + 4096" can WRAP AROUND in 64-bit math and let huge addresses through
  constraint c_window   { target == 0 -> (addr inside {[WIN_BASE : WIN_BASE + 32'hFFF]} &&
                                          int'(addr[11:0]) + int'(length) * 4 <= 4096); }
  constraint c_doorbell { target == 1 -> (length == 1 && first_be == 4'hF &&
                                          addr inside {[DB_BASE:DB_BASE + 32'h1C]}); }          // 5
  constraint c_len      { length inside {[1:32]}; idle_cycles inside {[1:3]}; }                 // 6: MPS = 128 bytes
  constraint c_payload  { payload.size() == length; }                                           // 7
  constraint c_be       { length == 1 -> (last_be == 0 && first_be != 0);                       // 8: byte-enable rules
                          length > 1  -> (first_be inside {4'hF, 4'hE, 4'hC, 4'h8} &&
                                          last_be  inside {4'h1, 4'h3, 4'h7, 4'hF}); }
  constraint c_good     { bad_len == 0; bad_type == 0; bad_addr == 0; }                         // 9

  function new ( string name = "tlp_item");
   super.new(name);
 endfunction

  // the error knobs bend a legal TLP into an illegal one AFTER it was solved
  function void post_randomize();
    if (bad_type) begin fmt = 3'b000; payload.delete(); end           // Memory Read (no data): not supported here
    if (bad_addr) addr = {32'h0, BAR + 32'h4000};                      // nothing is mapped at BAR + 0x4000
    if (bad_len) begin                                                 // one DW more than Length says
      payload = new[payload.size() + 1](payload);                      // grow the dynamic array, keep old DWs
      payload[payload.size() - 1] = 32'hBAD0_BAD0;
    end
  endfunction

  // header DWORDs exactly as they go on the link
  function void header(ref bit [31:0] h[$]);
    h.delete();
    h.push_back({fmt, typ, 1'b0, 3'b000, 4'b0000, 2'b00, 2'b00, 2'b00, length});   // DW0: Fmt Type T9 TC T8.Attr2.LN.TH TD.EP Attr AT Length
    h.push_back({req_id, tag, last_be, first_be});                                // DW1
    if (fmt[0]) h.push_back(addr[63:32]);                                         // DW2 (4-DW): address high
    h.push_back({addr[31:2], 2'b00});                                             // address low
  endfunction
 endclass
