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
wire [2:0] jmp = i[3:1];
wire [2:0] dst = i[6:4];
wire       src = i[7];
wire [7:0] opc = i[15:8];
wire signed [15:0] x = d;
wire signed [15:0] y = src ? m : a;
wire signed [15:0] x0 = opc[7] ? 0 : x;
wire signed [15:0] x1 = opc[6] ? ~x0 : x0;
wire signed [15:0] y0 = opc[5] ? 0 : y;
wire signed [15:0] y1 = opc[4] ? ~y0 : y0;
wire signed [15:0] z0 = opc[3] ? 
  (opc[2] ? 
    (y1[15] ? (x1 >> (0-y1)) : x1 << y1) : 
    (x1[15] ? (y1 >> (0-x1)) : y1 << x1)) : 
  (opc[2] ? (x1 + y1) : (x1 & y1));
reg signed [15:0] rz0; integer k;
wire signed [15:0] z1 = opc[1] ? rz0 : z0;
wire signed [15:0] z  = opc[0] ? ~z1 : z1;
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
  case(cst)
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
  inout [7:0] io, 
  output halt,
  input rstb, clk 
);

localparam size = 'h2000;
(* ram_style="block" *) reg [7:0] mem[0:size-1];
localparam ram ='h1000;
reg          ready;
reg  [ 7: 0] rdata;
wire [ 7: 0] wdata;
wire [15: 0] addr;
wire         write;
wire         valid;
reg [15:0] entry;
localparam entry_a0 = ram+'h0;
localparam entry_a1 = ram+'h1;
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
localparam  io_c_a0 = ram+'h2;
localparam  io_i_a0 = ram+'h3;
localparam io_oe_a0 = ram+'h4;
generate
genvar io_k;
for(io_k=0;io_k<=7;io_k=io_k+1) begin : io_bth 
assign io[io_k] = io_oe[io_k] ? io_i[io_k] : 1'bz;
end
endgenerate
integer k;
always@(negedge rstb or posedge clk) begin
  if(!rstb) begin
    ready = 0;
    for(k=ram;k<=size-1;k=k+1) mem[k] = 0;
    $readmemh("rom.memh", mem);
    mem[entry_a0] = 0;
    mem[entry_a1] = 0;
    mem[io_c_a0] = io;
  end
  else begin
    if(&{~ready,valid}) begin
      rdata = mem[addr];
      if(write) begin
        mem[addr] = wdata;
      end
    end
    ready = valid;
    mem[io_c_a0] = io;
  end
end
always@(*) begin
  entry[7:0] = mem[entry_a0];
  entry[15:8] = mem[entry_a1];
  io_i = mem[io_i_a0];
  io_oe = mem[io_oe_a0];
end

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

always #3 clk = ~clk;
wire [7:0] ram_0x00 = top.mem[top.ram+'h00];
wire [7:0] ram_0x01 = top.mem[top.ram+'h01];
wire [7:0] ram_0x02 = top.mem[top.ram+'h02];
wire [7:0] ram_0x03 = top.mem[top.ram+'h03];
wire [7:0] ram_0x04 = top.mem[top.ram+'h04];
wire [7:0] ram_0x05 = top.mem[top.ram+'h05];
wire [7:0] ram_0x06 = top.mem[top.ram+'h06];
wire [7:0] ram_0x07 = top.mem[top.ram+'h07];
wire [7:0] ram_0x08 = top.mem[top.ram+'h08];
wire [7:0] ram_0x09 = top.mem[top.ram+'h09];
wire [7:0] ram_0x0a = top.mem[top.ram+'h0a];
wire [7:0] ram_0x0b = top.mem[top.ram+'h0b];
wire [7:0] ram_0x0c = top.mem[top.ram+'h0c];
wire [7:0] ram_0x0d = top.mem[top.ram+'h0d];
wire [7:0] ram_0x0e = top.mem[top.ram+'h0e];
wire [7:0] ram_0x0f = top.mem[top.ram+'h0f];

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
