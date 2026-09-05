// Empty blackbox stub for hierarchical integration LVS.
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
endmodule
