// tb_shift_sipo.v -- 自检式测试：串入并出移位寄存器
`timescale 1ns/1ps

module tb_shift_sipo;
    reg        clk;
    reg        rst_n;
    reg        din;
    wire [7:0] dout;

    integer errors;
    integer i;
    reg [7:0] data;

    shift_sipo #(.WIDTH(8)) u_dut (
        .clk(clk), .rst_n(rst_n), .din(din), .dout(dout)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        errors = 0;
        rst_n  = 0;
        din    = 0;
        data   = 8'b1000_0001;      // 先送最高位
        #25 rst_n = 1;
        #5;

        for (i = 7; i >= 0; i = i - 1) begin
            @(negedge clk);
            din = data[i];
        end
        @(posedge clk); #1;
        if (dout !== data) begin
            $display("FAIL: sipo dout=%b (expect %b)", dout, data);
            errors = errors + 1;
        end

        rst_n = 0; #5;
        if (dout !== 8'd0) begin
            $display("FAIL: reset dout=%b", dout);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_shift_sipo");
        else             $display("FAIL: tb_shift_sipo (%0d errors)", errors);
        $finish;
    end
endmodule
