`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2023 11:41:34 AM
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/06/2023 08:47:56 PM
// Design Name:
// Module Name: main
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module sevenSegDecoder (
    input [3:0] in,
    output reg [6:0] out
);
  always @(in)
    case (in)
      4'b0001: out = 7'b1111001;  // 1
      4'b0010: out = 7'b0100100;  // 2
      4'b0011: out = 7'b0110000;  // 3
      4'b0100: out = 7'b0011001;  // 4
      4'b0101: out = 7'b0010010;  // 5
      4'b0110: out = 7'b0000010;  // 6
      4'b0111: out = 7'b1111000;  // 7
      4'b1000: out = 7'b0000000;  // 8
      4'b1001: out = 7'b0010000;  // 9
      4'b1010: out = 7'b0001000;  // A
      4'b1011: out = 7'b0000011;  // b
      4'b1100: out = 7'b1000110;  // C
      4'b1101: out = 7'b0100001;  // d
      4'b1110: out = 7'b0000110;  // E
      4'b1111: out = 7'b0001110;  // F
      default: out = 7'b1000000;  // 0
    endcase

endmodule



module decoder4 (
    input [1:0] in,
    output reg [3:0] out
);

  always @(in) begin
    case (in)
      2'b00: out = 4'b0001;
      2'b01: out = 4'b0010;
      2'b10: out = 4'b0100;
      2'b11: out = 4'b1000;
    endcase
  end

endmodule

module mux4 (
    input [1:0] sel,
    input [3:0] d1,
    input [3:0] d2,
    input [3:0] d3,
    input [3:0] d4,
    output reg [3:0] out
);

  always @(*) begin
    case (sel)
      2'b00: out = d1;
      2'b01: out = d2;
      2'b10: out = d3;
      2'b11: out = d4;
    endcase
  end

endmodule

module sevenSeg (
    input clk,
    input [3:0] d0,
    input [3:0] d1,
    input [3:0] d2,
    input [3:0] d3,
    output [6:0] seg,
    output [3:0] an
);

  localparam cnt_bits = 19;

  wire [cnt_bits-1:0] cnt;
  wire [1:0] active;
  wire [3:0] enb;
  wire [3:0] activeDigit;

  counter #(cnt_bits) c (
      clk,
      cnt
  );
  decoder4 dec (
      active,
      enb
  );
  mux4 mx (
      active,
      d3,
      d2,
      d1,
      d0,
      activeDigit
  );
  sevenSegDecoder sseg (
      activeDigit,
      seg
  );

  assign active = cnt[cnt_bits-1:cnt_bits-2];
  assign an = ~enb;



endmodule

module dff (
    input d,
    input clk,
    output reg q
);
  always @(posedge clk) begin
    q <= d;
  end
endmodule

module debouncer (
    input  in,
    output out,
    input  clk
);

  wire q1, pressed;
  wire [18:0] cnt;
  wire timerClr;
  reg [2:0] s;
  wire timerDone;

  dff d1 (
      in,
      clk,
      q1
  );
  dff d2 (
      q1,
      clk,
      pressed
  );

  counter #19 c (
      clk,
      cnt,
      timerClr
  );

  assign timerDone = &cnt;

  always @(posedge clk) begin
    if (s == 0 && pressed) s <= 1;
    else if (s == 1 && !pressed) s <= 0;
    else if (s == 1 && pressed && timerDone) s <= 2;
    else if (s == 2 && !pressed) s <= 3;
    else if (s == 3 && pressed) s <= 2;
    else if (s == 3 && !pressed && timerDone) s <= 0;
  end

  assign timerClr = (s == 0 || s == 2);
  assign out = s == 2 || s == 3;

endmodule

module oneShot (
    input in,
    input clk,
    output reg out
);
  reg s;
  always @(posedge clk) begin
    if (s == 0 && !in) begin
      s   <= 0;
      out <= 0;
    end else if (s == 0 && in) begin
      s   <= 1;
      out <= 1;
    end else if (s == 1 && in) begin
      s   <= 1;
      out <= 0;
    end else if (s == 1 && !in) begin
      s   <= 0;
      out <= 0;
    end
  end
endmodule

module button (
    input  in,
    output out,
    input  clk
);
  wire ind;
  debouncer d (
      in,
      ind,
      clk
  );
  oneShot o (
      ind,
      clk,
      out
  );
endmodule

module bcdCounter (
    input clk,
    input inc,
    input dec,
    input set0,
    input set9,
    output reg [3:0] out,
    output reg bout,
    output reg cout
);
  always @(posedge clk) begin
    if (set0) begin
      out  <= 0;
      cout <= 0;
      bout <= 0;
    end else if (set9) begin
      out  <= 9;
      cout <= 0;
      bout <= 0;
    end else if (inc && out < 9) begin
      out  <= out + 1;
      cout <= 0;
      bout <= 0;
    end else if (inc) begin
      out  <= 0;
      cout <= 1;
      bout <= 0;
    end else if (dec && out > 0) begin
      out  <= out - 1;
      cout <= 0;
      bout <= 0;
    end else if (dec) begin
      out  <= 9;
      cout <= 0;
      bout <= 1;
    end else begin
      cout <= 0;
      bout <= 0;
    end
  end
endmodule

module stack (
    input clk,
    input push,
    input pop,
    input reset,
    input [7:0] in,
    output reg [7:0] size,
    output reg [7:0] top
);
  reg [7:0] mem[256:0];
  always @(posedge clk) begin
    if (reset) begin
      mem[0] <= 0;
      size = 0;
    end else if (push && size < 256) begin
      mem[size] <= in;
      size <= size + 1;
    end else if (pop && size > 0) begin
      top  <= mem[size-1];
      size <= size - 1;
    end
  end
endmodule

// module bcdRom (
//     input clk,
//     input [4:0] addr,
//     output reg [7:0] out
// );
//   (* rom_style="block" *)
//   reg [7:0] mem[31:0];

//   initial $readmemb("rom.dat", mem);

//   always @(posedge clk) out <= mem[addr];
// endmodule

// module calcRom (
//     input clk,
//     input [9:0] addr,
//     output reg [11:0] out
// );
//   (* rom_style="block" *)
//   reg [11:0] mem[(1<<10)-1:0];

//   initial $readmemb("rom2.dat", mem);

//   always @(posedge clk) out <= mem[addr];
// endmodule

module Rom #(
    parameter WIDTH = 12,
    parameter ADDR_WIDTH = 10
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg [WIDTH-1:0] out
);
  (* rom_style="block" *)
  reg [WIDTH-1:0] mem[(1<<ADDR_WIDTH)-1:0];

  initial $readmemb("rom.dat", mem);

  always @(posedge clk) out <= mem[addr];
endmodule

module counter #(
    parameter N = 4
) (
    input clk,
    output reg [N-1:0] val
);

  always @(posedge clk) begin
    val <= val + 1;
  end

endmodule

module aikenCounter (
    input clk,
    output reg [4:0] out,
    output reg tggle
);
  reg [4:0] cnt;
  always @(posedge clk) begin
    cnt   <= (cnt + 1) % 10;
    tggle <= !tggle;
  end
  always @(cnt) begin
    case (cnt)
      0: out <= 4'b0000;
      1: out <= 4'b0001;
      2: out <= 4'b0010;
      3: out <= 4'b0011;
      4: out <= 4'b0100;
      5: out <= 4'b1011;
      6: out <= 4'b1100;
      7: out <= 4'b1101;
      8: out <= 4'b1110;
      9: out <= 4'b1111;
    endcase
  end
endmodule

module main (
    input clk,
    output [7:0] led
);
  wire [25:0] timer;
  counter #(26) CNTER (
      clk,
      timer
  );
  assign signal = &timer;
  wire [3:0] aiken;
  wire tggle;
  aikenCounter AIKEN (
      signal,
      aiken,
      tggle
  );
  assign led[7]   = tggle;
  assign led[3:0] = aiken;

  
endmodule

