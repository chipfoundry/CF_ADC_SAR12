`timescale 1ns / 1ps

// Ideal functional model of analog leaf CF_ADC_SAR12_sar_refs_core.
// Drop this file in place of hdl/gl/CF_ADC_SAR12_sar_refs_core.v for simulation.
// Do not add it to OpenLane VERILOG_FILES.
//
// Real backdoors:
//   vdda_v   analog supply (default 3.3 V)
//   REFHI_v  high reference (vdda_v when powered, else 0)
//   REFBY2_v mid reference (REFHI_v / 2)
//   refout_v buffered copy of REFHI_v when refout_en is high
//
// Digital REFHI / REFBY2 / refout are 1 when the matching real is > 0.1 V.
// Mux, trim, probe, and buffer dynamics are not modeled.

module CF_ADC_SAR12_sar_refs_core (
    vdda,
    vda_int,
    vccd,
    vpwrd_int,
    VPUMP,
    vssa,
    vssd,
    vref,
    pd,
    hiz,
    PWR_CTRL_VREF,
    muxsarref,
    REFBY2,
    pd_ana,
    EN_RESVDA,
    IREF_VCMBUF,
    sw_start,
    pd_vcmbuf,
    S_LV,
    px_in,
    px,
    refout,
    refout_en,
    sw_holdb,
    enpdb_hv,
    en_pxin_cap,
    REFHI,
    enable_hv,
    IREF_VREFBUF,
    PD_BUF_VREF,
    vssa_shield,
    dft_comp_en
);
    inout vdda;
    output vda_int;
    inout vccd;
    output vpwrd_int;
    inout VPUMP;
    inout vssa;
    inout vssd;
    input [4:0] vref;
    input pd;
    input hiz;
    input [1:0] PWR_CTRL_VREF;
    input [2:0] muxsarref;
    output REFBY2;
    input pd_ana;
    input EN_RESVDA;
    input IREF_VCMBUF;
    input sw_start;
    input pd_vcmbuf;
    input [7:0] S_LV;
    inout px_in;
    inout px;
    output refout;
    input refout_en;
    input sw_holdb;
    input enpdb_hv;
    output en_pxin_cap;
    output REFHI;
    input enable_hv;
    input IREF_VREFBUF;
    input PD_BUF_VREF;
    inout vssa_shield;
    input dft_comp_en;

    real vdda_v;
    real REFHI_v;
    real REFBY2_v;
    real refout_v;

    wire powered = ~pd & ~pd_ana & enable_hv & ~PD_BUF_VREF;

    initial vdda_v = 3.3;

    always @(*) begin
        if (powered) begin
            REFHI_v  = vdda_v;
            REFBY2_v = vdda_v * 0.5;
            refout_v = refout_en ? vdda_v : 0.0;
        end else begin
            REFHI_v  = 0.0;
            REFBY2_v = 0.0;
            refout_v = 0.0;
        end
    end

    assign REFHI      = (REFHI_v  > 0.1);
    assign REFBY2     = (REFBY2_v > 0.1);
    assign refout     = (refout_v > 0.1);
    assign vda_int    = powered;
    assign vpwrd_int  = ~pd;
    assign en_pxin_cap = 1'b0;
endmodule
