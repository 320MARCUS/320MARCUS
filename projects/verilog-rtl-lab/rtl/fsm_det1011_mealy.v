// fsm_det1011_mealy.v -- "1011" 序列检测器（Mealy 型，允许重叠，异步复位）
// 与 Moore 版对照：输出在"处于 S3 且 din=1"的当拍立即有效。
module fsm_det1011_mealy (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output wire sout
);

    parameter S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
    reg [1:0] cstate, nstate;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) cstate <= S0;
        else        cstate <= nstate;

    always @(*) begin
        case (cstate)
            S0:      nstate = din ? S1 : S0;
            S1:      nstate = din ? S1 : S2;
            S2:      nstate = din ? S3 : S0;
            S3:      nstate = din ? S1 : S2;   // 完成后回退："1011" 后缀 "1"；"1010" 后缀 "10"
            default: nstate = S0;
        endcase
    end

    assign sout = (cstate == S3) && din;       // Mealy：状态 + 输入

endmodule
