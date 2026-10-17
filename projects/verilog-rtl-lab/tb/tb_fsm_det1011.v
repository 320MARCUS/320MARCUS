// tb_fsm_det1011.v -- 自检式测试：Moore 型 "1011" 序列检测器（允许重叠）
`timescale 1ns/1ps

module tb_fsm_det1011;
    reg  clk;
    reg  rst_n;
    reg  din;
    wire sout;

    integer errors;

    fsm_det1011 u_dut (
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
        if (sout !== 1'b0) begin
            $display("FAIL: reset sout=%b", sout);
            errors = errors + 1;
        end

        // 序列 1,0,1,1 -> 完成检测
        drive_bit(1); @(posedge clk); #1;
        drive_bit(0); @(posedge clk); #1;
        drive_bit(1); @(posedge clk); #1;
        if (sout !== 1'b0) begin
            $display("FAIL: sout early after 101");
            errors = errors + 1;
        end
        drive_bit(1); @(posedge clk); #1;
        if (sout !== 1'b1) begin
            $display("FAIL: sout missing after 1011");
            errors = errors + 1;
        end

        // 重叠：继续 0,1,1 -> 1011011 中的第二个 1011（位 4-7）
        drive_bit(0); @(posedge clk); #1;
        if (sout !== 1'b0) begin
            $display("FAIL: sout not cleared after 0");
            errors = errors + 1;
        end
        drive_bit(1); @(posedge clk); #1;
        drive_bit(1); @(posedge clk); #1;
        if (sout !== 1'b1) begin
            $display("FAIL: overlapping detection missed");
            errors = errors + 1;
        end

        // 中途复位
        rst_n = 0; #5;
        if (sout !== 1'b0) begin
            $display("FAIL: sout after reset");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_fsm_det1011");
        else             $display("FAIL: tb_fsm_det1011 (%0d errors)", errors);
        $finish;
    end
endmodule
