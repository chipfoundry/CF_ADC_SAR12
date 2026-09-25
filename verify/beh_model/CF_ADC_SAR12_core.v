`timescale 1ns / 1ps

// Ideal functional model of analog leaf CF_ADC_SAR12_core.
// Drop this file in place of hdl/gl/CF_ADC_SAR12_core.v for simulation.
// Do not add it to OpenLane VERILOG_FILES.
//
// Analog voltages are Verilog real backdoors (1-bit pins stay digital):
//   vinp_v, vinm_v, vrefhi_v, vreflo_v, refby2_v
//
// Assumed protocol:
//   * reset_n low, pd, pd_ana, or enable_hv low → idle, eof=0, data_out=0
//   * sof sampled on refclk in IDLE starts a conversion
//   * sample for max(sample_width, 1) clocks, then convert nbits+OVERHEAD
//   * data_out valid in the same cycle eof rises; eof is one refclk wide
//   * next (or sof held) starts another conversion after eof
//   * resolution: 2'b01=10-bit, 2'b10=8-bit, else 12-bit (left-justified)
//   * unipolar: code = round((vinp-vinm)/(vrefhi-vreflo) * (2^n-1))
//   * BIPOLAR=1 maps (vinp-vinm) of ±span/2 onto 0 .. 2^n-1
// Pump, trim, bias, DFT, and analog accuracy are not modeled.

module CF_ADC_SAR12_core (
    en_pump_lv,
    sample_width,
    vreflo,
    resolution,
    scan_test_mode,
    test_scanin,
    test_scanen,
    test_scanout,
    en_csel_dft,
    sel_csel_dft,
    hiz,
    sof,
    test_sea,
    reset_n,
    eof,
    data_out,
    iso_en,
    next,
    vinp,
    vinm,
    vrefhi,
    vssa_q,
    dft_inp,
    dft_inm,
    dft_op,
    dft_om,
    trimunit,
    vpwr_lv_int,
    vdda,
    vdda_q,
    vssd,
    VPUMP,
    vboost,
    vssa,
    refby2,
    cap_trim,
    pumpclk,
    dft_enc,
    pd,
    pd_ana,
    refclk,
    dft_inc,
    dft_outc,
    vccd_q,
    vpwr_int,
    vccd,
    vpwrd_int,
    icont_lv,
    vsub_vic,
    vsub_agr,
    dly_inc,
    dcen,
    ibiasin,
    ibias2p5u,
    ibias2p5u_out,
    ibias2p5u_1,
    enable_hv
);
    parameter CONVERT_OVERHEAD = 1;
    parameter BIPOLAR = 0;

    input en_pump_lv;
    input [9:0] sample_width;
    inout vreflo;
    input [1:0] resolution;
    input scan_test_mode;
    input test_scanin;
    input test_scanen;
    output test_scanout;
    output en_csel_dft;
    input [3:0] sel_csel_dft;
    input hiz;
    input sof;
    input test_sea;
    input reset_n;
    output eof;
    output [11:0] data_out;
    input iso_en;
    input next;
    input vinp;
    input vinm;
    input vrefhi;
    inout vssa_q;
    inout dft_inp;
    inout dft_inm;
    inout dft_op;
    inout dft_om;
    input trimunit;
    inout vpwr_lv_int;
    inout vdda;
    inout vdda_q;
    inout vssd;
    inout VPUMP;
    inout vboost;
    inout vssa;
    input refby2;
    input [2:0] cap_trim;
    input pumpclk;
    output dft_enc;
    input pd;
    input pd_ana;
    input refclk;
    input [3:0] dft_inc;
    input [2:0] dft_outc;
    inout vccd_q;
    inout vpwr_int;
    inout vccd;
    inout vpwrd_int;
    input [1:0] icont_lv;
    inout vsub_vic;
    inout vsub_agr;
    input dly_inc;
    input dcen;
    inout ibiasin;
    input ibias2p5u;
    output ibias2p5u_out;
    input ibias2p5u_1;
    input enable_hv;

    localparam ST_IDLE    = 2'd0;
    localparam ST_SAMPLE  = 2'd1;
    localparam ST_CONVERT = 2'd2;

    real vinp_v;
    real vinm_v;
    real vrefhi_v;
    real vreflo_v;
    real refby2_v;

    reg [1:0]  state;
    reg [9:0]  wait_cnt;
    reg [11:0] data_q;
    reg        eof_q;
    reg        scan_q;
    real       sampled_p;
    real       sampled_m;
    real       sampled_hi;
    real       sampled_lo;

    wire powered = reset_n & ~pd & ~pd_ana & enable_hv;

    initial begin
        vinp_v    = 0.0;
        vinm_v    = 0.0;
        vrefhi_v  = 3.3;
        vreflo_v  = 0.0;
        refby2_v  = 1.65;
        sampled_p = 0.0;
        sampled_m = 0.0;
        sampled_hi = 3.3;
        sampled_lo = 0.0;
    end

    function integer nbits_of;
        input [1:0] res;
        begin
            case (res)
                2'b01: nbits_of = 10;
                2'b10: nbits_of = 8;
                default: nbits_of = 12;
            endcase
        end
    endfunction

    function [11:0] quantize;
        input real vp;
        input real vm;
        input real vhi;
        input real vlo;
        input [1:0] res;
        integer n;
        integer maxc;
        integer code;
        real span;
        real diff;
        real scaled;
        begin
            n = nbits_of(res);
            maxc = (1 << n) - 1;
            span = vhi - vlo;
            if (span <= 0.0) begin
                code = 0;
            end else if (BIPOLAR != 0) begin
                diff = vp - vm;
                scaled = (diff / span) + 0.5;
                if (scaled < 0.0) scaled = 0.0;
                if (scaled > 1.0) scaled = 1.0;
                code = $rtoi(scaled * maxc + 0.5);
            end else begin
                diff = vp - vm;
                if (diff < 0.0) diff = 0.0;
                if (diff > span) diff = span;
                code = $rtoi((diff / span) * maxc + 0.5);
            end
            if (code < 0) code = 0;
            if (code > maxc) code = maxc;
            quantize = code << (12 - n);
        end
    endfunction

    task start_sample;
        begin
            state <= ST_SAMPLE;
            if (sample_width == 10'd0)
                wait_cnt <= 10'd0;
            else
                wait_cnt <= sample_width - 10'd1;
        end
    endtask

    always @(posedge refclk or negedge reset_n) begin
        if (!reset_n) begin
            state    <= ST_IDLE;
            wait_cnt <= 10'd0;
            data_q   <= 12'd0;
            eof_q    <= 1'b0;
            scan_q   <= 1'b0;
        end else begin
            if (scan_test_mode && test_scanen)
                scan_q <= test_scanin;

            if (!powered) begin
                state    <= ST_IDLE;
                wait_cnt <= 10'd0;
                data_q   <= 12'd0;
                eof_q    <= 1'b0;
            end else begin
                eof_q <= 1'b0;
                case (state)
                    ST_IDLE: begin
                        if (sof)
                            start_sample;
                    end
                    ST_SAMPLE: begin
                        if (wait_cnt == 10'd0) begin
                            sampled_p  = vinp_v;
                            sampled_m  = vinm_v;
                            sampled_hi = vrefhi_v;
                            sampled_lo = vreflo_v;
                            state <= ST_CONVERT;
                            wait_cnt <= nbits_of(resolution) + CONVERT_OVERHEAD - 1;
                        end else begin
                            wait_cnt <= wait_cnt - 10'd1;
                        end
                    end
                    ST_CONVERT: begin
                        if (wait_cnt == 10'd0) begin
                            data_q <= quantize(
                                sampled_p, sampled_m, sampled_hi, sampled_lo,
                                resolution
                            );
                            eof_q <= 1'b1;
                            if (next || sof)
                                start_sample;
                            else
                                state <= ST_IDLE;
                        end else begin
                            wait_cnt <= wait_cnt - 10'd1;
                        end
                    end
                    default: state <= ST_IDLE;
                endcase
            end
        end
    end

    assign data_out       = iso_en ? 12'd0 : data_q;
    assign eof            = iso_en ? 1'b0  : eof_q;
    assign test_scanout   = scan_q;
    assign en_csel_dft    = 1'b0;
    assign dft_enc        = 1'b0;
    assign ibias2p5u_out  = ibias2p5u;
endmodule
