// tb_fsm_det1011_mealy.v -- 自检式测试：Mealy 型 "1011" 序列检测器（允许重叠）
`timescale 1ns/1ps

module tb_fsm_det1011_mealy;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire sout;

    integer errors;

    fsm_det1011_mealy u_dut (
        .clk(clk), .rst_n(rst_n), .din(din), .sout(sout)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    task drive_bit;
        input b;
        begin
            @(negedge clk);
            din = b;
        end
    endtask

    initial begin
        errors = 0;
        rst_n  = 0;
        din    = 0;
        #25 rst_n = 1;
        #5;

        // 1,0,1 -> 处于 S3；再给 1 时 sout 应在"当拍"立即为 1（比 Moore 提前一拍）
        drive_bit(1); @(posedge clk); #1;
        drive_bit(0); @(posedge clk); #1;
        drive_bit(1); @(posedge clk); #1;
        drive_bit(1);
        #1;
        if (sout !== 1'b1) begin
            $display("FAIL: Mealy output not immediate on din=1");
            errors = errors + 1;
        end
        @(posedge clk); #1;            // 进入 S1

        // 输入变低后输出应立即撤销（Mealy 组合输出）
        drive_bit(0);
        #1;
        if (sout !== 1'b0) begin
            $display("FAIL: Mealy output not cleared when din=0");
            errors = errors + 1;
        end
        @(posedge clk); #1;

        // 中途复位
        rst_n = 0; #5;
        if (sout !== 1'b0) begin
            $display("FAIL: sout after reset");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_fsm_det1011_mealy");
        else             $display("FAIL: tb_fsm_det1011_mealy (%0d errors)", errors);
        $finish;
    end
endmodule
