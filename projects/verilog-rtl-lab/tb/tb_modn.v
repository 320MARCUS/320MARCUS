// tb_modn.v -- 自检式测试：参数化 N 进制计数器（N=10）
`timescale 1ns/1ps

module tb_modn;
    reg        clk;
    reg        rst_n;
    reg        en;
    reg        load;
    reg  [7:0] din;
    wire [7:0] q;
    wire       cout;

    integer errors;
    integer i;
    integer exp;

    modn #(.N(10), .WIDTH(8)) u_dut (
        .clk(clk), .rst_n(rst_n), .en(en), .load(load),
        .din(din), .q(q), .cout(cout)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        errors = 0;
        rst_n  = 0;
        en     = 0;
        load   = 0;
        din    = 8'd0;
        @(negedge clk); @(negedge clk);   // 对齐负沿，避免复位释放与时钟沿竞争
        rst_n = 1;
        #1;

        en = 1;
        for (i = 1; i <= 10; i = i + 1) begin
            @(posedge clk); #1;
            exp = i % 10;
            if (q !== exp[7:0]) begin
                $display("FAIL: count step %0d: q=%0d (expect %0d)", i, q, exp);
                errors = errors + 1;
            end
            if (((exp == 9) ? 1'b1 : 1'b0) !== cout) begin
                $display("FAIL: cout mismatch at q=%0d", q);
                errors = errors + 1;
            end
        end

        // 装载优先于计数：load=1 时 q 直接变为 din
        din = 8'd5; load = 1;
        @(posedge clk); #1;
        if (q !== 8'd5) begin
            $display("FAIL: load q=%0d (expect 5)", q);
            errors = errors + 1;
        end
        load = 0;

        // 从 5 继续计数到 9 再回 0
        for (i = 6; i <= 10; i = i + 1) begin
            @(posedge clk); #1;
            exp = i % 10;
            if (q !== exp[7:0]) begin
                $display("FAIL: after load step %0d: q=%0d", i, q);
                errors = errors + 1;
            end
        end

        // en=0 保持
        en = 0;
        @(posedge clk); #1;
        if (q !== 8'd0) begin
            $display("FAIL: hold q=%0d", q);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_modn");
        else             $display("FAIL: tb_modn (%0d errors)", errors);
        $finish;
    end
endmodule
