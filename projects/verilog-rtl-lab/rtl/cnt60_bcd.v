// cnt60_bcd.v -- 60 进制 BCD 计数器（个位/十位分离输出 + 进位）
// 计数范围 00~59；cout 在计数值为 59 时为高电平。
module cnt60_bcd (
    input  wire       clk,
    input  wire       rst_n,    // 异步复位，低电平有效
    output reg  [3:0] ones,     // 个位 BCD
    output reg  [3:0] tens,     // 十位 BCD
    output wire       cout      // 进位：计数值 59 时有效
);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            ones <= 4'd0;
            tens <= 4'd0;
        end
        else if (ones == 4'd9) begin    // 个位满 9，向十位进位
            ones <= 4'd0;
            if (tens == 4'd5) tens <= 4'd0;   // 59 -> 00
            else              tens <= tens + 1'b1;
        end
        else ones <= ones + 1'b1;

    assign cout = (ones == 4'd9) && (tens == 4'd5);

endmodule
