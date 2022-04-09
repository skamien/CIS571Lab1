`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/
   
	// PC registers:
	wire [15:0] next_pc, next_pc_plus, AF_pc_out, BF_pc_out, AD_pc_in, BD_pc_in, AD_pc_out, BD_pc_out, 
				AX_pc_in, BX_pc_in, AX_pc_out, BX_pc_out, AM_pc_out, BM_pc_out, AW_pc_out, BW_pc_out;
	Nbit_reg #(16, 16'd0) AF_pc_reg (.in(next_pc), .out(AF_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BF_pc_reg (.in(next_pc_plus), .out(BF_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AD_pc_reg (.in(AD_pc_in), .out(AD_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BD_pc_reg (.in(BD_pc_in), .out(BD_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AX_pc_reg (.in(AX_pc_in), .out(AX_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BX_pc_reg (.in(BX_pc_in), .out(BX_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AM_pc_reg (.in(AX_pc_out), .out(AM_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BM_pc_reg (.in(BX_pc_out), .out(BM_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AW_pc_reg (.in(AM_pc_out), .out(AW_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BW_pc_reg (.in(BM_pc_out), .out(BW_pc_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	
	// Instruction registers:
	wire [15:0] AD_insn_in, BD_insn_in, AF_insn_out, BF_insn_out, AD_insn_out, BD_insn_out, AX_insn_in, BX_insn_in, 
				AX_insn_out, BX_insn_out, AM_insn_out, BM_insn_out, AW_insn_out, BW_insn_out;
	Nbit_reg #(16, 16'd0) AD_insn_reg (.in(AD_insn_in), .out(AD_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BD_insn_reg (.in(BD_insn_in), .out(BD_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AX_insn_reg (.in(AX_insn_in), .out(AX_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BX_insn_reg (.in(BX_insn_in), .out(BX_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AM_insn_reg (.in(AX_insn_out), .out(AM_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BM_insn_reg (.in(BX_insn_out), .out(BM_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) AW_insn_reg (.in(AM_insn_out), .out(AW_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	Nbit_reg #(16, 16'd0) BW_insn_reg (.in(BM_insn_out), .out(BW_insn_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	
	// Stall registers:
	wire [1:0] next_AD_stall, next_BD_stall, AD_stall, BD_stall, AX_stall_in, BX_stall_in, AX_stall, BX_stall, AM_stall, BM_stall, AW_stall, BW_stall;
   Nbit_reg #(2, 2'd2) AD_stall_reg (.in(next_AD_stall), .out(AD_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) BD_stall_reg (.in(next_BD_stall), .out(BD_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) AX_stall_reg (.in(AX_stall_in), .out(AX_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) BX_stall_reg (.in(BX_stall_in), .out(BX_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) AM_stall_reg (.in(AX_stall), .out(AM_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) BM_stall_reg (.in(BX_stall), .out(BM_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) AW_stall_reg (.in(AM_stall), .out(AW_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) BW_stall_reg (.in(BM_stall), .out(BW_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
	





   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule
