// Structural PG wrapper. Analog leaf is CF_ADC_SAR12_sar_refs_core.
// Customer rails are vpwr/vgnd; well taps vpb/vnb/vpbe are tied inside.
module CF_ADC_SAR12_sar_refs (
    vdda,
    vda_int,
    vpwr,
    vpwrd_int,
    VPUMP,
    vssa,
    vgnd,
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
    input vpwr;
    output vpwrd_int;
    inout VPUMP;
    inout vssa;
    input vgnd;
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
    CF_ADC_SAR12_sar_refs_core u_core (
        .vdda(vdda),
        .vda_int(vda_int),
        .vccd(vpwr),
        .vpwrd_int(vpwrd_int),
        .VPUMP(VPUMP),
        .vssa(vssa),
        .vssd(vgnd),
        .vref(vref),
        .pd(pd),
        .hiz(hiz),
        .PWR_CTRL_VREF(PWR_CTRL_VREF),
        .muxsarref(muxsarref),
        .REFBY2(REFBY2),
        .pd_ana(pd_ana),
        .EN_RESVDA(EN_RESVDA),
        .IREF_VCMBUF(IREF_VCMBUF),
        .sw_start(sw_start),
        .pd_vcmbuf(pd_vcmbuf),
        .S_LV(S_LV),
        .px_in(px_in),
        .px(px),
        .refout(refout),
        .refout_en(refout_en),
        .sw_holdb(sw_holdb),
        .enpdb_hv(enpdb_hv),
        .en_pxin_cap(en_pxin_cap),
        .REFHI(REFHI),
        .enable_hv(enable_hv),
        .IREF_VREFBUF(IREF_VREFBUF),
        .PD_BUF_VREF(PD_BUF_VREF),
        .vssa_shield(vssa_shield),
        .dft_comp_en(dft_comp_en)
    );
endmodule
