// modn.v -- 参数化 N 进制计数器（异步复位 + 使能 + 同步装载）
// 计数范围 0 ~ N-1（N <= 2^WIDTH）；控制优先级：复位 > 装载 > 计数。
module modn #(
    parameter N     = 10,
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    input  wire             load,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] q,
    output wire             cout
);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) q <= {WIDTH{1'b0}};
        else if (load) q <= din;
        else if (en) begin
            if (q == N - 1) q <= {WIDTH{1'b0}};
            else            q <= q + 1'b1;
        end

    assign cout = en && (q == N - 1);

endmodule
