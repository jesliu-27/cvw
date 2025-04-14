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

assign bias     =  5'd15;           // bias = 15
assign XZero    = ~|{1'b1, x[9:0]};
assign YZero    = ~|{1'b1, y[9:0]};
assign ZZero    = ~|{1'b1, z[9:0]};
// fmul
fmaMul fmaMul(x, y, bias, negp, XZero, YZero, Ps, Pe, Pm);

// temp result for fmul test
assign result = {Ps, Pe[4:0]+ {4'b0000, Pm[21]} , Pm[21] ? Pm[20:11]:Pm[19:10]};

// fadd

// fmaAdd fmaAdd(z, negz, Ps, Pe, Pm, XZero, YZero, ZZero, Ss, Se, Sm);
// assign result = {Ss, Se[4:0] , Sm[20:11]};


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

    // calculate product's exponent
    assign PZero        = XZero | YZero;    // if input = 0, Pe = 0
    assign PExponent    = {2'b0, Xe} + {2'b0, Ye} - {2'b0, bias};  // Xe+Ye-bias
    assign Pe           = PZero ? '0 : PExponent;

    // calculate product's significand
    assign Pm = Xm * Ym;

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

    logic           Zs;
    logic[4:0]      Ze;
    logic[10:0]     Zm;

    logic           As;
    logic           subtract;
    logic[6:0]      Acnt;
    logic[40:0]     Am;
    logic           KillP, KillZ;
    logic[40:0]     ZmPreshift;
    logic[40:0]     ZmShifted;
    logic[40:0]     PmShifted;
    logic           ASticky;
    logic[21:0]     AmInv;
    logic           KillPm;
    logic[21:0]     PreSum, NegPreSum;
    logic           NegSum;
    

    logic[5:0]      Mcnt;
    logic[40:0]     MmC;

    logic[40:0]     Mm;
    logic           valid;


    assign Zs           = z[15];
    assign Ze           = z[14:10];
    assign Zm           = {1'b1, z[9:0]};

    assign As           = Zs ^ negz;            // addend sign, flipped if negz
    assign subtract     = Ps ^ As;              // diff sign, subtraction


    // Determine the alignment shift count
    assign KillP        = XZero | YZero;        // kill product if P = 0 or Z is too big
    assign ZmPreshift   = {15'b0, Zm, 15'b0};   // placed z in the upper bit


    always_comb begin
        if(KillP) begin
            ZmShifted = ZmPreshift;
        end

        else begin
            if (Pe > {2'b0, Ze}) begin
                Acnt         = Pe - {2'b0, Ze};
                ZmShifted = ZmPreshift >> Acnt;
            end else begin
                Acnt         = {2'b0, Ze} - Pe;
                ZmShifted = ZmPreshift << Acnt;
            end
        end
    end

    assign PmShifted = {14'b0, Pm, 5'b0};


    // always_comb begin
    //     if (subtract) begin
    //         if (Am > Pm) begin
    //             {NegSum, PreSum} = {1'b0, Am} + {1'b0, AmInv} + {21'd0, (~ASticky | KillPm)};
    //             Ss = As;
    //             Mm = PreSum;
    //         end else begin
    //             {NegSum, PreSum} = {1'b0, Pm} + {1'b0, AmInv} + {21'd0, (~ASticky | KillP)};
    //             Ss = Ps;
    //             Mm = PreSum;
    //         end
    //     end else begin
    //         Mm = Pm + Am;
    //         Ss = Ps;
    //     end

  always_comb begin
        if (subtract) begin
            if (ZmShifted > PmShifted) begin
                Ss = As;
                Mm = ZmShifted - PmShifted;
            end else begin
                Ss = Ps;
                Mm = PmShifted - ZmShifted;
            end
        end else begin
            Mm =  ZmShifted + PmShifted;
            Ss = Ps;
        end




    // Determine the alignment shift count
    // Shift the signiificand of Z into alignment

    // always_comb begin
    //     if (Pe == {2'b0, Ze}) begin
    //         Am = {11'b0, Zm};
    //     end
    //     else if (Pe > {2'b0, Ze}) begin
    //         Acnt = Pe - {2'b0, Ze};
    //         Am   = {11'b0, Zm} >> Acnt;
    //     end
    //     else begin
    //         Acnt =  {2'b0, Ze} - Pe;
    //         Am   = {11'b0, Zm} << Acnt;
    //     end

    //     if(As == Ps) begin
    //         Mm   = Pm + Am;
    //         Ss = Zs;
    //     end
    //     else begin
    //         if (Am > Pm) begin
    //             Mm = Am - Pm;
    //             Ss = Zs;
    //         end
    //         else begin
    //             Mm = Pm - Am;
    //             Ss = Ps;
    //         end
    //     end


    // Finding the leading 1 for normaliztion shift
        casez(Mm)
            41'b1????????????????????????????????????????: begin Mcnt = 6'd0; end
            41'b01???????????????????????????????????????: begin Mcnt = 6'd1; end
            41'b001??????????????????????????????????????: begin Mcnt = 6'd2; end
            41'b0001?????????????????????????????????????: begin Mcnt = 6'd3; end
            41'b00001????????????????????????????????????: begin Mcnt = 6'd4; end
            41'b000001???????????????????????????????????: begin Mcnt = 6'd5; end
            41'b0000001??????????????????????????????????: begin Mcnt = 6'd6; end
            41'b00000001?????????????????????????????????: begin Mcnt = 6'd7; end
            41'b000000001????????????????????????????????: begin Mcnt = 6'd8; end
            41'b0000000001???????????????????????????????: begin Mcnt = 6'd9; end
            41'b00000000001??????????????????????????????: begin Mcnt = 6'd10;end  //invalid to prevent shifting
            41'b000000000001?????????????????????????????: begin Mcnt = 6'd11;end
            41'b0000000000001????????????????????????????: begin Mcnt = 6'd12;end
            41'b00000000000001???????????????????????????: begin Mcnt = 6'd13;end
            41'b000000000000001??????????????????????????: begin Mcnt = 6'd14;end
            41'b0000000000000001?????????????????????????: begin Mcnt = 6'd15;end
            41'b00000000000000001????????????????????????: begin Mcnt = 6'd16;end
            41'b000000000000000001???????????????????????: begin Mcnt = 6'd17;end
            41'b0000000000000000001??????????????????????: begin Mcnt = 6'd18;end
            41'b00000000000000000001?????????????????????: begin Mcnt = 6'd19;end
            41'b000000000000000000001????????????????????: begin Mcnt = 6'd20;end
            41'b0000000000000000000001???????????????????: begin Mcnt = 6'd21;end
            default: begin
                Mcnt = 6'd0;
            end
        endcase
    end

    // assign MmC  = Mm << 7'd14;
    // assign Sm = MmC[40:19];
    // assign Se = Pe + 7'd15 -  7'd10;

    assign MmC = (Mm << Mcnt);
    assign Sm = MmC[40:19];
    assign Se = Pe + 7'd15 - Mcnt;


    // assign Sm = 0;
    // assign Se = 0;
    // assign Ss = 0;


endmodule