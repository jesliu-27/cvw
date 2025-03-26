module fma16(
    input  logic [15:0] x, y, z,      // 16 bit half-precision float
    input  logic mul, add, negp, negz,
    input  logic [1:0] roundmode,
    output logic [15:0] result,
    output logic [3:0] flags
);

/* multiply two positive half-precision floats */
logic carry, signX, signY, signResMul, signRes;
logic[10:0] mantissaX, mantissaY;
logic[9:0] fractionRes;
logic[21:0] product;
logic[4:0] exponentsX;
logic[4:0] exponentsY;
logic[4:0] exponentsRes;
logic[4:0] bias;
logic[15:0] resMul;
always_comb
    begin
        // Sign
        signX = x[15];
        signY = y[15];
        signResMul = signX ^ signY;
        signRes = signResMul ^ negp;

        // Fraction part
        mantissaX = {1'b1, x[9:0]};
        mantissaY = {1'b1, y[9:0]};
        product = mantissaX * mantissaY;
        carry = product[21];
        fractionRes = carry ? product[20:11]:product[19:10];

        // Exponents
        bias = 5'd15;
        exponentsX = x[14:10] - bias;
        exponentsY = y[14:10] - bias;
        exponentsRes = exponentsX + exponentsY + bias +{4'b0000, carry};
        resMul = {signRes, exponentsRes, fractionRes};
        result = resMul;
        flags = 0;

    end

endmodule