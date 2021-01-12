/*
 * NAME
 *
 * cpu_tb.v - generic cpu test bench
 *
 * DESCRIPTION
 *
 * This generic cpu test bench can be used to run a program, which is in
 * ASCII hex format, and output the results.
 *
 * Configuration is done by setting preprocessor defines at compile
 * time.  The result is an executable for that specific test.
 *
 *   iverilog -DIM_DATA_FILE="\"t0001-no_hazard.hex\"" \
 *            -DNUM_IM_DATA=`wc -l t0001-no_hazard.hex | awk {'print $$1'}` \
 *            -DDUMP_FILE="\"t0001-no_hazard.vcd\"" \
 *            -I../ -g2005 \
 *            -o t0001-no_hazard \
 *            cpu_tb.v
 *
 * Then it can be run in the usual manner.  $monitor variables will be
 * output to STDOUT and a .vcd for use with Gtkwave will be output to
 * 'DUMP_FILE'.
 *
 *   ./t0001-no_hazard > t0001-no_hazard.out
 */


`include "./pipeline.v"

module test;
    reg clk;
    parameter inst="inst.hex";
    parameter len =8 ;
    pipeline #(len, inst) mips(clk);
    integer i=0;

    always begin
		clk <= ~clk;
		#5;
	end

	initial begin
		$dumpfile("dump.vcf");
		$dumpvars(0, test);
		clk <= 1'b0;
		for (i = 0; i <= len + 4; i = i + 1) begin
			@(posedge clk);
		end

		$finish;
	end

endmodule
