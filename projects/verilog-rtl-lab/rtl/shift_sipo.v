// shift_sipo.v -- 串入并出移位寄存器（左移，高位先入）
// 连续 WIDTH 个时钟后，输出即为串行输入组成的字节。
module shift_sipo #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             din,        // 串行输入（先送最高位）
    output reg  [WIDTH-1:0] dout
);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) dout <= {WIDTH{1'b0}};
        else        dout <= {dout[WIDTH-2:0], din};

endmodule
