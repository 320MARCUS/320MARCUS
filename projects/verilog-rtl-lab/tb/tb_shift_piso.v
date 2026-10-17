// tb_shift_piso.v -- 自检式测试：并入串出移位寄存器
`timescale 1ns/1ps

module tb_shift_piso;
    reg        clk;
    reg        rst_n;
    reg        load;
    reg  [7:0] din;
    wire       dout;

    integer errors;
    integer i;
    reg [7:0] data;

    shift_piso #(.WIDTH(8)) u_dut (
        .clk(clk), .rst_n(rst_n), .load(load), .din(din), .dout(dout)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        errors = 0;
        rst_n  = 0;
        load   = 0;
        din    = 8'd0;
        data   = 8'b1010_0101;
        #25 rst_n = 1;
        #5;

        @(negedge clk); load = 1; din = data;
        @(posedge clk); #1;
        if (dout !== data[7]) begin
            $display("FAIL: load dout=%b (expect MSB %b)", dout, data[7]);
            errors = errors + 1;
        end

        load = 0;
        for (i = 6; i >= 0; i = i - 1) begin
            @(posedge clk); #1;
            if (dout !== data[i]) begin
                $display("FAIL: piso bit %0d dout=%b (expect %b)", i, dout, data[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_shift_piso");
        else             $display("FAIL: tb_shift_piso (%0d errors)", errors);
        $finish;
    end
endmodule
