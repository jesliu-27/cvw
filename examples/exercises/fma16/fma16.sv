/////////////////////////////////////////////////////////////////////////////
// fma16.sv
// Written:  4/1/2025 Jessica Liu jesliu@hmc.edu
//
// Purpose: Final project for Spring ENGR154, designing a  design a 
//          half-precision FMA optimized for low power for computer 
//          graphics. 
/////////////////////////////////////////////////////////////////////////////



module fma16 (

    input  logic [15:0]         x, y, z, 
    input  logic                mul, add, negp, negz,
    input  logic [1:0]          roundmode,
    output logic [15:0]         result,
    output logic [3:0]          flags

);

logic[4:0]      bias;
logic           Ps;
logic[6:0]      Pe;
logic[21:0]     Pm;

logic           Ss;
logic[6:0]      Se;
logic[21:0]     Sm;

logic           XZero, YZero, ZZero;
logic           XInf, YInf, ZInf;
logic           XNaN, YNaN, ZNaN;

assign bias     =  5'd15;           // bias = 15
// unpack
unpack unpack(x, y, z, XZero, YZero, ZZero, XInf, YInf, ZInf, XNaN, YNaN, ZNaN);

// fmul
fmaMul fmaMul(x, y, bias, negp, XZero, YZero, Ps, Pe, Pm);

// temp result for fmul test
// assign result = {Ps, Pe[4:0]+ {4'b0000, Pm[21]} , Pm[21] ? Pm[20:11]:Pm[19:10]};

// fadd

fmaAdd fmaAdd(z, negz, Ps, Pe, Pm, XZero, YZero, ZZero, Ss, Se, Sm);
assign result = {Ss, Se[4:0] , Sm[20:11]};

assign flags = 0;

endmodule


module fmaMul(
    input   logic[15:0]   x, y,              // input
    input   logic[4:0]    bias,
    input   logic         negp, XZero, YZero,
    output  logic         Ps,                // product's sign
    output  logic[6:0]    Pe,                // product's exponent
    output  logic[21:0]   Pm                 // product's significand
);

    logic[4:0]      Xe, Ye;
    logic[10:0]     Xm, Ym;
    logic           Xs, Ys;
    logic           PZero;
    logic[6:0]      PExponent;


    assign Xe       = x[14:10];
    assign Ye       = y[14:10];

    assign Xm       = {1'b1, x[9:0]};
    assign Ym       = {1'b1, y[9:0]};

    assign Xs       = x[15];
    assign Ys       = y[15];



    // calculate product's sign
    assign Ps = Xs ^ Ys ^ negp;

    assign PZero     = XZero | YZero;

    assign PExponent = {2'b0, Xe} + {2'b0, Ye} - {2'b0, bias};
    assign Pe        = PZero ? 7'b0     : PExponent;
    assign Pm        = PZero ? 22'b0    : Xm * Ym;

endmodule

module fmaAdd(
    input   logic[15:0]   z,                 // input
    input   logic         negz,               
    input   logic         Ps,                // product's sign
    input   logic[6:0]    Pe,                // product's exponent
    input   logic[21:0]   Pm,                // product's significand
    input   logic         XZero, YZero, ZZero,
    output  logic         Ss,                // add/sub result's sign
    output  logic[6:0]    Se,                // add/sub result's exponent
    output  logic[21:0]   Sm                 // add/sub result's significand
);
    logic           As;
    logic           Zs;
    logic[4:0]      Ze;
    logic[10:0]     Zm;

    logic           subtract;
    logic[6:0]      Acnt;
    logic           KillP, KillZ;
    logic[21:0]     ZmPreshift, PmPreshift;
    logic[21:0]     ZmShifted;
    logic[21:0]     PmShifted;
    logic           ASticky;
    logic[39:0]     Zma;
    logic[39:0]     Pma;
    logic[39:0]     ZTemp;
    logic[39:0]     PTemp;
    

    logic[5:0]      Mcnt;
    logic[21:0]     MmC;

    logic[21:0]     Mm;
    logic           ShiftPE;
    logic[39:0]     NegZ, NegP, subSum;


    assign Zs           = z[15];
    assign Ze           = z[14:10];
    assign Zm           = {1'b1, z[9:0]};

    assign As           = Zs ^ negz;            // addend sign, flipped if negz
    assign subtract     = Ps ^ As;              // diff sign, subtraction



    // Determine the alignment shift count
    assign Zma = {1'b0, Zm[9:0], 29'b0};
    assign Pma = {1'b0, Pm[19:0], 19'b0};

    assign ZmPreshift   = {1'b0, Zm, 10'b0};   // placed z in the upper bit


    always_comb begin
        if (Pe > {2'b0, Ze}) begin
            Acnt         = Pe - {2'b0, Ze};
            ZTemp        = Zma >> Acnt;
            PTemp        = Pma;
            ZmShifted    = ZmPreshift >> Acnt;
            PmShifted    = Pm;
            ShiftPE      = 1;
        end else if (Pe < {2'b0, Ze} )begin
            Acnt         = {2'b0, Ze} - Pe;
            PTemp        = Pma >> Acnt;
            ZTemp        = Zma;
            PmShifted    = Pm >> Acnt;
            ZmShifted    = ZmPreshift;   
            ShiftPE      = 0; 
        end else begin
            Acnt = 0;
            ZTemp        = Zma;
            PTemp        = Pma;
            ZmShifted    = ZmPreshift >> Acnt;
            PmShifted    = Pm;
            ShiftPE   = 1;
        end

        assign NegZ = (~ZTemp)+1;
        assign NegP = (~PTemp)+1;

        if (subtract) begin
            if (ZTemp > PTemp) begin
                Ss = As;
                subSum = Zma+NegP; 
                Mm = {1'b1, subSum[38:18]};
            end else begin
                Ss = Ps;
                subSum = Pma+NegZ;
                Mm = {1'b0, 1'b1, subSum[38:19]};
            end
        end else begin
                Mm =  ZmShifted + PmShifted;
                Ss = Ps;
        end


    // Finding the leading 1 for normaliztion shift
        casez(Mm)
            22'b1?????????????????????: begin Mcnt = 6'd0; end
            22'b01????????????????????: begin Mcnt = 6'd1; end
            22'b001???????????????????: begin Mcnt = 6'd2; end
            22'b0001??????????????????: begin Mcnt = 6'd3; end
            22'b00001?????????????????: begin Mcnt = 6'd4; end
            22'b000001????????????????: begin Mcnt = 6'd5; end
            22'b0000001???????????????: begin Mcnt = 6'd6; end
            22'b00000001??????????????: begin Mcnt = 6'd7; end
            22'b000000001?????????????: begin Mcnt = 6'd8; end
            22'b0000000001????????????: begin Mcnt = 6'd9; end
            22'b00000000001???????????: begin Mcnt = 6'd10; end  //invalid to prevent shifting
            22'b000000000001??????????: begin Mcnt = 6'd11; end
            22'b0000000000001?????????: begin Mcnt = 6'd12;  end
            22'b00000000000001????????: begin Mcnt = 6'd13;  end
            22'b000000000000001???????: begin Mcnt = 6'd14;  end
            22'b0000000000000001??????: begin Mcnt = 6'd15;  end
            22'b00000000000000001?????: begin Mcnt = 6'd16;  end
            22'b000000000000000001????: begin Mcnt = 6'd17;  end
            22'b0000000000000000001???: begin Mcnt = 6'd18;  end
            22'b00000000000000000001??: begin Mcnt = 6'd19;  end
            22'b000000000000000000001?: begin Mcnt = 6'd20;  end
            22'b0000000000000000000001: begin Mcnt = 6'd21;  end
            default: begin
                Mcnt = 6'd0;
            end
        endcase
    

    // assign MmC  = Mm << 7'd14;
    // assign Sm = MmC[40:19];
    // assign Se = Pe + 7'd15 -  7'd10;

    // assign MmC = (Mm << Mcnt);
    // assign Sm = MmC[40:19];
    // assign Se = Pe + 7'd15 - Mcnt;
    
  end

    assign Sm = Mm << Mcnt;
    assign Se = ShiftPE ? (Pe - Mcnt + 1) : ({2'b0, Ze} - Mcnt+1);
    // assign Sm = Mm;// [39:18]; 
    // assign Se = Pe;


endmodule

module unpack(
    input   logic [15:0] x, y, z,
    output  logic XZero, YZero, ZZero,
    output  logic XInf, YInf, ZInf,
    output  logic XNaN, YNaN, ZNaN
);

assign XZero = (x[14:0] == 15'b0);
assign YZero = (y[14:0] == 15'b0);
assign ZZero = (z[14:0] == 15'b0);

assign XInf  = (x[14:10] == 5'b11111) && (x[9:0] == 10'b0);
assign YInf  = (y[14:10] == 5'b11111) && (y[9:0] == 10'b0);
assign ZInf  = (z[14:10] == 5'b11111) && (z[9:0] == 10'b0);

assign XNaN = (x[14:10] == 5'b11111) && (x[9:0] != 10'b0);
assign YNaN = (y[14:10] == 5'b11111) && (y[9:0] != 10'b0);
assign ZNaN = (z[14:10] == 5'b11111) && (z[9:0] != 10'b0);

endmodule

