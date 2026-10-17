// counter_bin.v -- 参数化二进制加法计数器（异步低电平复位 + 同步使能）
// 计数到 2^WIDTH-1 后自动回绕到 0。
module counter_bin #(
    parameter WIDTH = 4
) (
    input  wire             clk,
    input  wire             rst_n,      // 异步复位，低电平有效
    input  wire             en,         // 同步使能
    output reg  [WIDTH-1:0] q
);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) q <= {WIDTH{1'b0}};
        else if (en) q <= q + 1'b1;     // 满量程自动回绕

endmodule
