`timescale 1ns/1ps


module cpu
(
  input              ready , 
  input      [ 7: 0] rdata , 
  output reg [ 7: 0] wdata , 
  output reg [15: 0] addr  , 
  output reg         write , 
  output reg         valid , 
  input              rstb  ,
  output reg         halt  , 
  input      [15: 0] entry , 
  input              clk   
);

reg [15:0] p, i;
reg signed [15:0] a, d, m;
wire       nan = i[0];
wire       src = i[1];
wire [7:0] opc = i[9:2];
wire [2:0] dst = i[12:10];
wire [2:0] jmp = i[15:13];
wire signed [15:0] x = d;
wire signed [15:0] y = src ? m : a;
wire signed [15:0] x0 = opc[5] ? 0 : x;
wire signed [15:0] x1 = opc[4] ? ~x0 : x0;
wire signed [15:0] y0 = opc[3] ? 0 : y;
wire signed [15:0] y1 = opc[2] ? ~y0 : y0;
wire signed [15:0] z0 = opc[1] ? 
  (opc[0] ? 
    (y1[15] ? (x1 >> (0-y1)) : x1 << y1) : 
    (x1[15] ? (y1 >> (0-x1)) : y1 << x1)) : 
  (opc[0] ? (x1 + y1) : (x1 & y1));
reg signed [15:0] rz0; integer k;
wire signed [15:0] z1 = opc[7] ? rz0 : z0;
wire signed [15:0] z  = opc[6] ? ~z1 : z1;
wire lt = z[15];
wire eq = ~|z;
wire le = lt || eq;
wire gt = ~le;
reg [2:0] cst, nst;
always@(negedge rstb or posedge clk) begin
  if(!rstb) begin
    cst <= 0;
    p <= entry;
  end
  else if(~halt) begin
    cst <= nst;
    case(cst) 
      0 : if(ready) begin
        i[ 7:0] <= rdata;
        p <= p + 1;
      end
      2 : if(ready) begin
        i[15:8] <= rdata;
        p <= p + 1;
      end
      4 : begin
        if(nst != cst) begin
          if(nan) begin
            if(dst[1]) d <= z;
            if(dst[2]) a <= z;
            if(|(jmp & {lt,eq,gt})) p <= a;
          end
          else a <= {i[15],i[15:1]};
        end
      end
    endcase
  end
end
always@(*) begin
  nst = cst;
  valid = 0;
  addr = a;
  write = 0;
  wdata = z[7:0];
  m = {{8{rdata[7]}},rdata};
  halt = &p;
  for(k=0;k<=15;k=k+1) rz0[k] = z0[15-k];
  case(nst)
    0 : begin
      valid = 1;
      addr = p;
      if(ready) nst = cst+1;
    end
    1 : begin
      valid = 0;
      addr = p;
      if(!ready) nst = cst+1;
    end
    2 : begin
      valid = 1;
      addr = p;
      if(ready) nst = cst+1;
    end
    3 : begin
      valid = 0;
      addr = p;
      if(!ready) nst = cst+1;
    end
    4 : begin
      valid = nan && (src || dst[0]);
      write = nan && dst[0];
      if(valid) begin
        if(ready) nst = cst+1;
      end
      else nst = cst+1;
    end
    5 : begin
      valid = 0;
      write = nan && dst[0];
      if(nan && (src || dst[0])) begin
        if(!ready) nst = 0;
      end
      else nst = 0;
    end
  endcase
end

endmodule


module pll (input rstb, clk, output reg vld, lck);
`ifdef SIM
initial lck = 0;
always #5 lck = ~lck;
`else
wire [4:0] sub_wire0;
wire [0:0] sub_wire4 = 1'h0;
wire [0:0] sub_wire1 = sub_wire0[0:0];
always@(*) lck = sub_wire1;
wire  sub_wire2 = clk;
wire [1:0] sub_wire3 = {sub_wire4, sub_wire2};
altpll altpll_component (
  .inclk (sub_wire3),
  .clk (sub_wire0),
  .areset (1'b0),
  .clkena ({6{1'b1}}),
  .clkswitch (1'b0),
  .configupdate (1'b0),
  .pfdena (1'b1),
  .phasecounterselect ({4{1'b1}}),
  .phasestep (1'b1),
  .phaseupdown (1'b1),
  .pllena (1'b1));
defparam
  altpll_component.bandwidth_type = "AUTO",
  altpll_component.clk0_duty_cycle = 50,
  altpll_component.clk0_divide_by = 2,
  altpll_component.clk0_multiply_by = 4,
  altpll_component.clk0_phase_shift = "0",
  altpll_component.compensate_clock = "CLK0",
  altpll_component.inclk0_input_frequency = 50000,
  altpll_component.intended_device_family = "Cyclone IV E",
  altpll_component.lpm_hint = "CBX_MODULE_PREFIX=pll_pixel_clock",
  altpll_component.lpm_type = "altpll",
  altpll_component.operation_mode = "NORMAL",
  altpll_component.pll_type = "AUTO",
  altpll_component.width_clock = 5;
`endif
always@(negedge rstb or posedge lck) if(!rstb) vld <= 0; else vld <= 1;
endmodule


module top
(
  output [7:0] debug, 
  inout [63:0] io, 
  output halt,
  input rstb, clk 
);

wire vld, lck;
pll pll (rstb, clk, vld, lck);
wire [23:0] ADDR;
localparam [23:0] data = 'h2000;
localparam [23:0] size = 'h0100 + data;
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] rom[0:data-1];
wire sel_rom = &{ADDR>=0,ADDR<=data-1};
localparam [23:0]  page_a0 = data+'h00;
localparam [23:0] entry_a0 = data+'h01;
localparam [23:0] entry_a1 = data+'h02;
localparam [23:0] io_os_a0 = data+'h03;
localparam [23:0] io_is_a0 = data+'h04;
localparam [23:0]  io_c_a0 = data+'h05;
localparam [23:0]  io_c_a1 = data+'h06;
localparam [23:0]  io_c_a2 = data+'h07;
localparam [23:0]  io_c_a3 = data+'h08;
localparam [23:0]  io_c_a4 = data+'h09;
localparam [23:0]  io_c_a5 = data+'h0a;
localparam [23:0]  io_c_a6 = data+'h0b;
localparam [23:0]  io_c_a7 = data+'h0c;
localparam [23:0]  io_i_a0 = data+'h0d;
localparam [23:0]  io_i_a1 = data+'h0e;
localparam [23:0]  io_i_a2 = data+'h0f;
localparam [23:0]  io_i_a3 = data+'h10;
localparam [23:0]  io_i_a4 = data+'h11;
localparam [23:0]  io_i_a5 = data+'h12;
localparam [23:0]  io_i_a6 = data+'h13;
localparam [23:0]  io_i_a7 = data+'h14;
localparam [23:0] io_oe_a0 = data+'h15;
localparam [23:0] io_oe_a1 = data+'h16;
localparam [23:0] io_oe_a2 = data+'h17;
localparam [23:0] io_oe_a3 = data+'h18;
localparam [23:0] io_oe_a4 = data+'h19;
localparam [23:0] io_oe_a5 = data+'h1a;
localparam [23:0] io_oe_a6 = data+'h1b;
localparam [23:0] io_oe_a7 = data+'h1c;
localparam [23:0] io_ie_a0 = data+'h1d;
localparam [23:0] io_ie_a1 = data+'h1e;
localparam [23:0] io_ie_a2 = data+'h1f;
localparam [23:0] io_ie_a3 = data+'h20;
localparam [23:0] io_ie_a4 = data+'h21;
localparam [23:0] io_ie_a5 = data+'h22;
localparam [23:0] io_ie_a6 = data+'h23;
localparam [23:0] io_ie_a7 = data+'h24;
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] dev[data+'h0:data+'h24];
wire sel_dev = &{ADDR>=data+'h0,ADDR<=data+'h24};
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] ram[data+'h25:size-1];
wire sel_ram = &{ADDR>=data+'h25,ADDR<=size-1};
reg          ready;
reg  [ 7: 0] rdata;
wire [ 7: 0] wdata;
wire [15: 0] addr;
wire         write;
wire         valid;
reg [15:0] entry;
cpu cpu 
(
  .ready (ready),
  .rdata (rdata),
  .wdata (wdata),
  .addr  (addr),
  .write (write),
  .valid (valid),
  .rstb  (vld),
  .entry (entry),
  .halt  (halt),
  .clk   (lck)
);
reg [63:0] io_i, io_o, io_c, io_oe, io_ie;
wire signed [7:0] io_os = dev[io_os_a0];
wire signed [7:0] io_is = dev[io_is_a0];
generate
genvar io_k;
for(io_k=0;io_k<=63;io_k=io_k+1) begin : io_bth 
assign io[io_k] = io_oe[io_k] ? io_i[io_k] : 1'bz;
end
endgenerate
always@(posedge clk) begin
  io_i = (io_os < 0) ? 
    ({dev[io_i_a7],
      dev[io_i_a6],
      dev[io_i_a5],
      dev[io_i_a4],
      dev[io_i_a3],
      dev[io_i_a2],
      dev[io_i_a1],
      dev[io_i_a0]} >> (0-io_os)) : 
    ({dev[io_i_a7],
      dev[io_i_a6],
      dev[io_i_a5],
      dev[io_i_a4],
      dev[io_i_a3],
      dev[io_i_a2],
      dev[io_i_a1],
      dev[io_i_a0]} << io_os);
  io_c = (io_is < 0) ? (io_o >> (0-io_is)) : (io_o << io_is);
end
assign ADDR = {dev[page_a0],addr};
reg [7:0] rdata_rom, rdata_dev, rdata_ram;
initial $readmemh("rom.memh", rom);
always@(negedge vld or posedge lck) begin
  if(!vld) begin
    ready <= 1'b0;
    dev[page_a0] = 0;
    dev[entry_a0] = 0;
    dev[entry_a1] = 0;
    dev[io_os_a0] = 0;
    dev[io_is_a0] = 0;
    dev[io_oe_a0] = 0;
    dev[io_oe_a1] = 0;
    dev[io_oe_a2] = 0;
    dev[io_oe_a3] = 0;
    dev[io_oe_a4] = 0;
    dev[io_oe_a5] = 0;
    dev[io_oe_a6] = 0;
    dev[io_oe_a7] = 0;
    dev[io_ie_a0] = 0;
    dev[io_ie_a1] = 0;
    dev[io_ie_a2] = 0;
    dev[io_ie_a3] = 0;
    dev[io_ie_a4] = 0;
    dev[io_ie_a5] = 0;
    dev[io_ie_a6] = 0;
    dev[io_ie_a7] = 0;
  end
  else begin
    ready <= valid;
    if(&{~ready,valid,sel_dev}) begin
      if(write) dev[ADDR] = wdata;
      else rdata_dev = dev[ADDR];
    end
    dev[io_c_a0] = io_c[07:00];
    dev[io_c_a1] = io_c[15:08];
    dev[io_c_a2] = io_c[23:16];
    dev[io_c_a3] = io_c[31:24];
    dev[io_c_a4] = io_c[39:32];
    dev[io_c_a5] = io_c[47:40];
    dev[io_c_a6] = io_c[55:48];
    dev[io_c_a7] = io_c[63:56];
  end
end
always@(posedge lck) begin
  if(&{~ready,valid,sel_rom}) begin
    rdata_rom <= rom[ADDR];
  end
  if(&{~ready,valid,sel_ram}) begin
    if(write) ram[ADDR] <= wdata; 
    else rdata_ram <= ram[ADDR];
  end
end
always@(*) begin
  entry[7:0] = dev[entry_a0];
  entry[15:8] = dev[entry_a1];
  io_oe = (io_os < 0) ? 
    ({dev[io_oe_a7],
      dev[io_oe_a6],
      dev[io_oe_a5],
      dev[io_oe_a4],
      dev[io_oe_a3],
      dev[io_oe_a2],
      dev[io_oe_a1],
      dev[io_oe_a0]} >> (0-io_os)) : 
    ({dev[io_oe_a7],
      dev[io_oe_a6],
      dev[io_oe_a5],
      dev[io_oe_a4],
      dev[io_oe_a3],
      dev[io_oe_a2],
      dev[io_oe_a1],
      dev[io_oe_a0]} << io_os);
  io_ie = 
     {dev[io_ie_a7],
      dev[io_ie_a6],
      dev[io_ie_a5],
      dev[io_ie_a4],
      dev[io_ie_a3],
      dev[io_ie_a2],
      dev[io_ie_a1],
      dev[io_ie_a0]};
  io_o = io & io_ie;
  if(sel_rom) rdata = rdata_rom;
  else if(sel_dev) rdata = rdata_dev;
  else rdata = rdata_ram;
end

assign debug[0] = io[0];
assign debug[1] = io[1];
assign debug[2] = io[2];

endmodule


`ifdef SIM
module tb;

wire [63:0] io;
wire halt;
reg rstb, clk;
top top 
(
  .io(io), 
  .halt(halt),
  .rstb(rstb), .clk(clk) 
);

always #10 clk = ~clk;
wire [7:0] ram_0x00 = top.dev[top.data+'h00];
wire [7:0] ram_0x01 = top.dev[top.data+'h01];
wire [7:0] ram_0x02 = top.dev[top.data+'h02];
wire [7:0] ram_0x03 = top.dev[top.data+'h03];
wire [7:0] ram_0x04 = top.dev[top.data+'h04];
wire [7:0] ram_0x05 = top.dev[top.data+'h05];
wire [7:0] ram_0x06 = top.dev[top.data+'h06];
wire [7:0] ram_0x07 = top.dev[top.data+'h07];
wire [7:0] ram_0x08 = top.dev[top.data+'h08];
wire [7:0] ram_0x09 = top.dev[top.data+'h09];
wire [7:0] ram_0x0a = top.dev[top.data+'h0a];
wire [7:0] ram_0x0b = top.dev[top.data+'h0b];
wire [7:0] ram_0x0c = top.dev[top.data+'h0c];
wire [7:0] ram_0x0d = top.dev[top.data+'h0d];
wire [7:0] ram_0x0e = top.dev[top.data+'h0e];
wire [7:0] ram_0x0f = top.dev[top.data+'h0f];
wire [7:0] ram_0x10 = top.dev[top.data+'h10];
wire [7:0] ram_0x11 = top.dev[top.data+'h11];
wire [7:0] ram_0x12 = top.dev[top.data+'h12];
wire [7:0] ram_0x13 = top.dev[top.data+'h13];
wire [7:0] ram_0x25 = top.ram[top.data+'h25];
wire [7:0] ram_0x26 = top.ram[top.data+'h26];
wire [7:0] ram_0x27 = top.ram[top.data+'h27];
wire [7:0] ram_0x28 = top.ram[top.data+'h28];
wire [7:0] ram_0x29 = top.ram[top.data+'h29];
wire [7:0] ram_0x2a = top.ram[top.data+'h2a];
wire [7:0] ram_0x2b = top.ram[top.data+'h2b];

reg key1;
initial key1 = 0;
always@(posedge clk) begin
  repeat(100000) @(posedge clk);
  key1 = ~key1;
end
assign io[2] = key1;

reg rx,uclk;
initial uclk=0;
always #2930.1875 uclk=~uclk;
always@(negedge rstb or posedge uclk) begin
  if(!rstb) rx=1;
  else begin
    repeat($urandom_range(5,50)) @(posedge uclk);
    rx=0;
    repeat(7) begin
      @(posedge uclk);
      rx=$urandom_range(0,1);
    end
    @(posedge uclk);
    rx=1;
  end
end
assign io[1] = rx;

initial begin
 `ifdef FST
  $dumpfile("hw.fst");
  $dumpvars(0,tb);
  `endif
  `ifdef FSDB
  $fsdbDumpfile("hw.fsdb");
  $fsdbDumpvars(0,tb);
  `endif
  $monitor("%t: ram[0x00:0x0f] : %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,",
  $time,
  ram_0x00, ram_0x01, ram_0x02, ram_0x03, ram_0x04, ram_0x05, ram_0x06, ram_0x07, 
  ram_0x08, ram_0x09, ram_0x0a, ram_0x0b, ram_0x0c, ram_0x0d, ram_0x0e, ram_0x0f, 
  ram_0x10, ram_0x11, ram_0x12, ram_0x13, 
  ram_0x25, ram_0x26, ram_0x27, ram_0x28,
  ram_0x29, ram_0x2a, ram_0x2b, 
  );
  clk = 0;
  rstb = 0;
  repeat(3) @(posedge clk); rstb = 1;
  @(posedge halt);
  repeat(3) @(posedge clk); rstb = 0;
  $finish;
end
endmodule
`endif
