// fsm_det1011.v -- "1011" 序列检测器（Moore 型，允许重叠，异步复位）
// 检测完成时输出 sout 在完成态（S4）保持一个时钟周期的高电平。
module fsm_det1011 (
    input  wire clk,
    input  wire rst_n,
    input  wire din,        // 串行输入
    output wire sout        // Moore 输出：状态 = S4 时为 1
);

    parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;
    reg [2:0] cstate, nstate;

    // 主控时序过程：状态寄存器
    always @(posedge clk or negedge rst_n)
        if (!rst_n) cstate <= S0;
        else        cstate <= nstate;

    // 主控组合过程：次态逻辑（重叠检测的回退见注释）
    always @(*) begin
        case (cstate)
            S0:      nstate = din ? S1 : S0;
            S1:      nstate = din ? S1 : S2;   // "11" 的后缀 "1" 仍有效
            S2:      nstate = din ? S3 : S0;   // "100" 无有效后缀
            S3:      nstate = din ? S4 : S2;   // "1010" 的后缀 "10" 是新序列前两位
            S4:      nstate = din ? S1 : S2;   // "10111" 回 "1"；"10110" 回 "10"
            default: nstate = S0;
        endcase
    end

    assign sout = (cstate == S4);

endmodule
