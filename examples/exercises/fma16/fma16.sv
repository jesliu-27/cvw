module fma16(
    input  logic [15:0] x, y, z,      // 16 bit half-precision float
    input  logic mul, add, negp, negz,
    input  logic [1:0] roundmode,
    output logic [15:0] res,
    output logic [3:0] flags
);

/* multiply two positive half-precision floats */
logic carry, sign_x, sign_y, sign_res_mul, sign_res;
logic[10:0] mantissa_x, mantissa_y;
logic[9:0] fraction_res;
logic[21:0] product;
logic[4:0] exponents_x;
logic[4:0] exponents_y;
logic[4:0] exponents_res;
logic[4:0] bias;
logic[15:0] res_mul;
always_comb
    begin
        // Sign
        sign_x = x[15];
        sign_y = y[15];
        sign_res_mul = sign_x ^ sign_y;
        sign_res = sign_res_mul ^ negp;

        // Fraction part
        mantissa_x = {1'b1, x[9:0]};
        mantissa_y = {1'b1, y[9:0]};
        product = mantissa_x * mantissa_y;
        carry = product[21];
        fraction_res = carry ? product[20:11]:product[19:10];

        // Exponents
        bias = 5'd15;
        exponents_x = x[14:10] - bias;
        exponents_y = y[14:10] - bias;
        exponents_res = exponents_x + exponents_y + bias +{4'b0000, carry};
        res_mul = {sign_res, exponents_res, fraction_res};
        res = res_mul;
        flags = 0;

    end

endmodule