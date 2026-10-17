// tb_cnt60_bcd.v -- 自检式测试：60 进制 BCD 计数器
`timescale 1ns/1ps

module tb_cnt60_bcd;
    reg        clk;
    reg        rst_n;
    wire [3:0] ones;
    wire [3:0] tens;
    wire       cout;

    integer errors;
    integer i;
    integer exp_ones;
    integer exp_tens;

    cnt60_bcd u_dut (
        .clk(clk), .rst_n(rst_n), .ones(ones), .tens(tens), .cout(cout)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $dumpfile("build/tb_cnt60_bcd.vcd");
        $dumpvars(0, tb_cnt60_bcd);
    end

    initial begin
        errors = 0;
        rst_n  = 0;
        @(negedge clk); @(negedge clk);   // 对齐负沿，避免复位释放与时钟沿竞争
        rst_n = 1;
        #1;
        if (ones !== 4'd0 || tens !== 4'd0) begin
            $display("FAIL: reset ones=%0d tens=%0d", ones, tens);
            errors = errors + 1;
        end

        for (i = 1; i <= 60; i = i + 1) begin
            @(posedge clk); #1;
            exp_ones = (i % 60) % 10;
            exp_tens = (i % 60) / 10;
            if (ones !== exp_ones[3:0] || tens !== exp_tens[3:0]) begin
                $display("FAIL: step %0d: %0d%0d (expect %0d%0d)",
                         i, tens, ones, exp_tens, exp_ones);
                errors = errors + 1;
            end
            if ((i % 60 == 59) && cout !== 1'b1) begin
                $display("FAIL: cout not asserted at %0d%0d", tens, ones);
                errors = errors + 1;
            end
            if ((i % 60 != 59) && cout !== 1'b0) begin
                $display("FAIL: cout asserted early at %0d%0d", tens, ones);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_cnt60_bcd");
        else             $display("FAIL: tb_cnt60_bcd (%0d errors)", errors);
        $finish;
    end
endmodule
