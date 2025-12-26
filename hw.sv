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


module top
(
  output [7:0] debug, 
  inout [7:0] io, 
  output halt,
  input rstb, clk 
);

localparam [23:0] data ='h2000;
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] rom[0:data-1];
localparam [23:0]  page_a0 = data+'h0;
localparam [23:0] entry_a0 = data+'h1;
localparam [23:0] entry_a1 = data+'h2;
localparam [23:0]  io_c_a0 = data+'h3;
localparam [23:0]  io_i_a0 = data+'h4;
localparam [23:0] io_oe_a0 = data+'h5;
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] dev[data+'h0:data+'h5];
localparam [23:0] size = 'h2100;
//(* ram_style="block" *) 
(* ramstyle = "M9K" *)
reg [7:0] ram[data+'h6:size-1];
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
  .rstb  (rstb),
  .entry (entry),
  .halt  (halt),
  .clk   (clk)
);
reg [7:0] io_i;
reg [7:0] io_oe;
generate
genvar io_k;
for(io_k=0;io_k<=7;io_k=io_k+1) begin : io_bth 
assign io[io_k] = io_oe[io_k] ? io_i[io_k] : 1'bz;
end
endgenerate
wire [23:0] ADDR = {dev[page_a0],addr};
wire sel_rom = &{ADDR>=0,ADDR<=data-1};
wire sel_dev = &{ADDR>=data+'h0,ADDR<=data+'h5};
wire sel_ram = &{ADDR>=data+'h6,ADDR<=size-1};
reg [7:0] rdata_rom, rdata_dev, rdata_ram;
initial $readmemh("rom.memh", rom);
always@(negedge rstb or posedge clk) begin
  if(!rstb) begin
    ready <= 1'b0;
    dev[page_a0] = 0;
    dev[entry_a0] = 0;
    dev[entry_a1] = 0;
    dev[io_c_a0] = io;
  end
  else begin
    ready <= valid;
    if(&{~ready,valid,sel_dev}) begin
      if(write) dev[ADDR] = wdata;
      else rdata_dev = dev[ADDR];
    end
    dev[io_c_a0] = io;
  end
end
always@(posedge clk) begin
  if(&{~ready,valid,sel_ram}) begin
    if(write) ram[ADDR] <= wdata; 
    else rdata_ram <= ram[ADDR];
  end
end
always@(*) begin
  rdata_rom = rom[ADDR];
  entry[7:0] = dev[entry_a0];
  entry[15:8] = dev[entry_a1];
  io_i = dev[io_i_a0];
  io_oe = dev[io_oe_a0];
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

wire [7:0] io;
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
wire [7:0] ram_0x06 = top.ram[top.data+'h06];
wire [7:0] ram_0x07 = top.ram[top.data+'h07];
wire [7:0] ram_0x08 = top.ram[top.data+'h08];
wire [7:0] ram_0x09 = top.ram[top.data+'h09];
wire [7:0] ram_0x0a = top.ram[top.data+'h0a];
wire [7:0] ram_0x0b = top.ram[top.data+'h0b];
wire [7:0] ram_0x0c = top.ram[top.data+'h0c];
wire [7:0] ram_0x0d = top.ram[top.data+'h0d];
wire [7:0] ram_0x0e = top.ram[top.data+'h0e];
wire [7:0] ram_0x0f = top.ram[top.data+'h0f];

reg key4;
initial key4 = 0;
always@(posedge clk) begin
  repeat(10000) @(posedge clk);
  key4 = ~key4;
end
assign io[2] = key4;

initial begin
 `ifdef FST
  $dumpfile("hw.fst");
  $dumpvars(0,tb);
  `endif
  `ifdef FSDB
  $fsdbDumpfile("hw.fsdb");
  $fsdbDumpvars(0,tb);
  `endif
  $monitor("%t: ram[0x00:0x0f] : %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x, %04x,%04x,%04x,%04x",
  $time,
  ram_0x00, ram_0x01, ram_0x02, ram_0x03, ram_0x04, ram_0x05, ram_0x06, ram_0x07, 
  ram_0x08, ram_0x09, ram_0x0a, ram_0x0b, ram_0x0c, ram_0x0d, ram_0x0e, ram_0x0f, 
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
