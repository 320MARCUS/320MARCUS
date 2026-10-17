// tb_div_even.v -- 自检式测试：偶数分频器（DIV=4，20ns 输入 -> 80ns 输出）
`timescale 1ns/1ps

module tb_div_even;
    reg  clk;
    reg  rst_n;
    wire clk_out;

    integer errors;
    integer i;
    reg     exp;

    div_even #(.DIV(4)) u_dut (
        .clk(clk), .rst_n(rst_n), .clk_out(clk_out)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        errors = 0;
        rst_n  = 0;
        @(negedge clk); @(negedge clk);   // 对齐负沿，避免复位释放与时钟沿竞争
        rst_n = 1;
        #1;
        if (clk_out !== 1'b0) begin
            $display("FAIL: reset clk_out=%b", clk_out);
            errors = errors + 1;
        end

        // DIV=4：每 2 个时钟沿翻转一次 => 周期为输入时钟的 4 倍、占空比 50%
        exp = 1'b0;
        for (i = 1; i <= 8; i = i + 1) begin
            @(posedge clk); #1;
            if (i % 2 == 0) exp = ~exp;
            if (clk_out !== exp) begin
                $display("FAIL: edge %0d clk_out=%b (expect %b)", i, clk_out, exp);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_div_even");
        else             $display("FAIL: tb_div_even (%0d errors)", errors);
        $finish;
    end
endmodule
