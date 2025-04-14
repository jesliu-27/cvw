module fma16(
    input  logic [15:0] x, y, z,      // 16 bit half-precision float
    input  logic mul, add, negp, negz,
    input  logic [1:0] roundmode,
    output logic [15:0] result,
    output logic [3:0] flags
);

// multiplication signals
logic           carry, signX, signY, signResMul, signRes;
logic[10:0]     mantissaX, mantissaY;
logic[9:0]      fractionMulRes;
logic[21:0]     product;
logic[4:0]      exponentsX;
logic[4:0]      exponentsY;
logic[4:0]      exponentsMulRes;
logic[4:0]      bias;
logic[15:0]     resMul;

// addition signals
logic           signZ, addSign;
logic[4:0]      exponentsZ, alignShift;
logic[10:0]     mantissaZ;
logic[15:0]     resAdd;
logic[10:0]     mantissaZAligned;
logic[10:0]     significand;
logic[14:0]     normalizedResult;
logic[4:0]      Mcnt;
logic[10:0]     mantissaMulRes;
logic[14:0]     alignSignificand;
logic[4:0]      normalizeExponent;
logic[9:0]      normalizeFraction;
logic [14:0]    mantissaMulResExt;
logic [14:0]    mantissaZAlignedExt;

// flags

logic overflow;
logic underflow;
logic inexact;
logic invalid;



// Sign
assign signX = x[15];
assign signY = y[15];
assign signResMul = signX ^ signY;
assign signRes = signResMul ^ negp;

// Fraction part
assign mantissaX = {1'b1, x[9:0]};
assign mantissaY = {1'b1, y[9:0]};
assign product = mantissaX * mantissaY;
assign carry = product[21];
assign fractionMulRes = carry ? product[20:11]:product[19:10];

// Exponents
assign bias = 5'd15;
assign exponentsX = x[14:10] - bias;
assign exponentsY = y[14:10] - bias;
assign exponentsMulRes = exponentsX + exponentsY + bias +{4'b0000, carry};
assign resMul = {signRes, exponentsMulRes, fractionMulRes};



// addition


// unpack
assign signZ = z[15];
assign mantissaZ = {1'b1, z[9:0]};
assign exponentsZ = z[14:10];
assign mantissaMulResExt = {4'b0000, 1'b1, fractionMulRes};

// Acnt = Pe - Ze
assign alignShift = exponentsMulRes - exponentsZ;

// Am = Zm >> Acnt
assign mantissaZAligned = mantissaZ >> alignShift;
assign mantissaZAlignedExt = {4'b0000, mantissaZ};


// Sm = Am + Pm
assign alignSignificand = mantissaZAlignedExt + mantissaMulResExt;

always_comb begin
    Mcnt = 0;
    for (int i = 14; i >= 0; i--) begin
        if (alignSignificand[i] == 1'b0)
            Mcnt = Mcnt + 1;
        else
            break;
    end
end


// Mm = Sm << Mcnt
// Me = Pe - Mcnt
assign normalizedResult = alignSignificand << Mcnt;
assign normalizeExponent = exponentsMulRes - Mcnt + 1;
assign normalizeFraction = normalizedResult[14:5];
assign resAdd = {signRes, normalizeExponent, normalizeFraction};
assign result = (add == 1'b0) ? resMul : resAdd;

// flags
assign overflow  = 0; //(normalizeExponent >= 5'd31);
assign underflow = 1'b0;
assign inexact = normalizedResult[4] | normalizedResult[3] | (|normalizedResult[2:0]);
assign invalid   = 1'b0;
assign flags = {invalid, overflow, underflow, inexact};


endmodule
