// div_even.v -- 参数化偶数分频器（50% 占空比）
// DIV 必须为 >= 2 的偶数；每 DIV/2 个时钟翻转一次输出。
module div_even #(
    parameter DIV = 4
) (
    input  wire clk,
    input  wire rst_n,
    output reg  clk_out
);

    reg [7:0] cnt;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cnt     <= 8'd0;
            clk_out <= 1'b0;
        end
        else if (cnt == (DIV/2 - 1)) begin
            cnt     <= 8'd0;
            clk_out <= ~clk_out;
        end
        else cnt <= cnt + 1'b1;

endmodule
