// tb_counter_bin.v -- 自检式测试：4 位二进制计数器
`timescale 1ns/1ps

module tb_counter_bin;
    reg        clk;
    reg        rst_n;
    reg        en;
    wire [3:0] q;

    integer errors;
    integer i;

    counter_bin #(.WIDTH(4)) u_dut (
        .clk(clk), .rst_n(rst_n), .en(en), .q(q)
    );

    initial clk = 0;
    always #10 clk = ~clk;      // 20ns 周期

    initial begin
        errors = 0;
        rst_n  = 0;
        en     = 0;
        @(negedge clk); @(negedge clk);   // 对齐负沿，避免复位释放与时钟沿竞争
        rst_n = 1;
        #1;
        if (q !== 4'd0) begin
            $display("FAIL: reset q=%0d (expect 0)", q);
            errors = errors + 1;
        end

        en = 1;
        for (i = 1; i <= 16; i = i + 1) begin
            @(posedge clk); #1;
            if (q !== i[3:0]) begin
                $display("FAIL: count step %0d: q=%0d (expect %0d)", i, q, i[3:0]);
                errors = errors + 1;
            end
        end

        en = 0;                  // 使能关闭 -> 保持
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (q !== 4'd0) begin
            $display("FAIL: hold with en=0: q=%0d", q);
            errors = errors + 1;
        end

        en = 1; @(posedge clk); #1;   // q=1
        rst_n = 0; #5;                // 异步复位立即生效
        if (q !== 4'd0) begin
            $display("FAIL: async reset: q=%0d", q);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_counter_bin");
        else             $display("FAIL: tb_counter_bin (%0d errors)", errors);
        $finish;
    end
endmodule
