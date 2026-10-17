// shift_piso.v -- 并入串出移位寄存器（左移，高位先出）
// load=1 时并行装入；load=0 时每次时钟左移一位，dout 输出最高位。
module shift_piso #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             load,
    input  wire [WIDTH-1:0] din,
    output wire             dout
);

    reg [WIDTH-1:0] sr;

    always @(posedge clk or negedge rst_n)
        if (!rst_n)    sr <= {WIDTH{1'b0}};
        else if (load) sr <= din;
        else           sr <= {sr[WIDTH-2:0], 1'b0};

    assign dout = sr[WIDTH-1];

endmodule
