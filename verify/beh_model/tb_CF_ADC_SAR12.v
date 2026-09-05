`timescale 1ns / 1ps

// Self-check for the ideal CF_ADC_SAR12 behavioral cores.
// Instantiates the customer wraps so the sim file list matches integration.

module tb_CF_ADC_SAR12;
    integer errors;
    integer cycles;

    reg refclk;
    reg reset_n;
    reg sof;
    reg next;
    reg pd;
    reg pd_ana;
    reg iso_en;
    reg enable_hv;
    reg [9:0] sample_width;
    reg [1:0] resolution;
    reg refs_pd;
    reg refs_pd_ana;
    reg refs_enable_hv;
    reg refs_pd_buf;
    reg refout_en;

    wire eof;
    wire [11:0] data_out;
    wire refs_refhi;
    wire refs_refby2;
    wire refs_refout;

    CF_ADC_SAR12 u_adc (
        .en_pump_lv(1'b0),
        .sample_width(sample_width),
        .resolution(resolution),
        .scan_test_mode(1'b0),
        .test_scanin(1'b0),
        .test_scanen(1'b0),
        .hiz(1'b0),
        .sof(sof),
        .test_sea(1'b0),
        .reset_n(reset_n),
        .eof(eof),
        .data_out(data_out),
        .iso_en(iso_en),
        .next(next),
        .trimunit(1'b0),
        .cap_trim(3'b000),
        .pumpclk(1'b0),
        .pd(pd),
        .pd_ana(pd_ana),
        .refclk(refclk),
        .dft_inc(4'b0000),
        .dft_outc(3'b000),
        .icont_lv(2'b00),
        .dly_inc(1'b0),
        .dcen(1'b0),
        .ibias2p5u(1'b0),
        .ibias2p5u_1(1'b0),
        .enable_hv(enable_hv),
        .sel_csel_dft(4'b0000)
    );

    CF_ADC_SAR12_sar_refs u_refs (
        .vref(5'b00000),
        .pd(refs_pd),
        .hiz(1'b0),
        .PWR_CTRL_VREF(2'b00),
        .muxsarref(3'b000),
        .REFBY2(refs_refby2),
        .pd_ana(refs_pd_ana),
        .EN_RESVDA(1'b0),
        .IREF_VCMBUF(1'b0),
        .sw_start(1'b0),
        .pd_vcmbuf(1'b0),
        .S_LV(8'h00),
        .refout(refs_refout),
        .refout_en(refout_en),
        .sw_holdb(1'b1),
        .enpdb_hv(1'b1),
        .REFHI(refs_refhi),
        .enable_hv(refs_enable_hv),
        .IREF_VREFBUF(1'b0),
        .PD_BUF_VREF(refs_pd_buf),
        .dft_comp_en(1'b0)
    );

    initial refclk = 1'b0;
    always #27.778 refclk = ~refclk;

    task expect_eq;
        input [11:0] got;
        input [11:0] exp;
        input [8*32-1:0] tag;
        begin
            if (got !== exp) begin
                $display("FAIL %s got=%0d exp=%0d", tag, got, exp);
                errors = errors + 1;
            end else begin
                $display("PASS %s %0d", tag, got);
            end
        end
    endtask

    task convert;
        input real vp;
        input real vm;
        output [11:0] result;
        begin
            u_adc.u_core.vinp_v = vp;
            u_adc.u_core.vinm_v = vm;
            @(posedge refclk);
            sof <= 1'b1;
            @(posedge refclk);
            sof <= 1'b0;
            cycles = 0;
            result = 12'hx;
            while (cycles < 64) begin
                @(posedge refclk);
                cycles = cycles + 1;
                if (eof) begin
                    #1;
                    result = data_out;
                    cycles = 64;
                end
            end
            if (result === 12'hx) begin
                $display("FAIL timeout vp=%g vm=%g", vp, vm);
                errors = errors + 1;
                result = 12'd0;
            end
        end
    endtask

    reg [11:0] code;

    function [11:0] expected_unipolar;
        input real vp;
        input real vm;
        input real vhi;
        input real vlo;
        input [1:0] res;
        integer n;
        integer maxc;
        integer raw;
        real span;
        real diff;
        begin
            n = (res == 2'b01) ? 10 : ((res == 2'b10) ? 8 : 12);
            maxc = (1 << n) - 1;
            span = vhi - vlo;
            diff = vp - vm;
            if (diff < 0.0) diff = 0.0;
            if (diff > span) diff = span;
            raw = $rtoi((diff / span) * maxc + 0.5);
            expected_unipolar = raw << (12 - n);
        end
    endfunction

    initial begin
        errors = 0;
        sof = 1'b0;
        next = 1'b0;
        pd = 1'b0;
        pd_ana = 1'b0;
        iso_en = 1'b0;
        enable_hv = 1'b1;
        sample_width = 10'd4;
        resolution = 2'b00;
        refs_pd = 1'b0;
        refs_pd_ana = 1'b0;
        refs_enable_hv = 1'b1;
        refs_pd_buf = 1'b0;
        refout_en = 1'b1;
        reset_n = 1'b0;

        u_adc.u_core.vrefhi_v = 3.3;
        u_adc.u_core.vreflo_v = 0.0;
        u_refs.u_core.vdda_v = 3.3;

        repeat (4) @(posedge refclk);
        reset_n = 1'b1;
        repeat (2) @(posedge refclk);

        convert(3.3, 0.0, code);
        expect_eq(code, expected_unipolar(3.3, 0.0, 3.3, 0.0, 2'b00), "full-scale");

        convert(1.65, 0.0, code);
        expect_eq(code, expected_unipolar(1.65, 0.0, 3.3, 0.0, 2'b00), "mid-scale");

        convert(0.0, 0.0, code);
        expect_eq(code, 12'd0, "zero");

        convert(0.825, 0.0, code);
        expect_eq(code, expected_unipolar(0.825, 0.0, 3.3, 0.0, 2'b00), "quarter");

        resolution = 2'b10;
        convert(3.3, 0.0, code);
        expect_eq(code, expected_unipolar(3.3, 0.0, 3.3, 0.0, 2'b10), "8-bit-full");
        resolution = 2'b00;

        pd = 1'b1;
        @(posedge refclk);
        sof <= 1'b1;
        @(posedge refclk);
        sof <= 1'b0;
        repeat (24) @(posedge refclk);
        if (eof !== 1'b0) begin
            $display("FAIL eof while powered down");
            errors = errors + 1;
        end else begin
            $display("PASS powered-down idle");
        end
        pd = 1'b0;
        repeat (2) @(posedge refclk);

        #1;
        if (refs_refhi !== 1'b1 || refs_refby2 !== 1'b1 || refs_refout !== 1'b1) begin
            $display("FAIL refs digital outputs hi=%b by2=%b out=%b",
                refs_refhi, refs_refby2, refs_refout);
            errors = errors + 1;
        end else begin
            $display("PASS refs powered");
        end
        if (u_refs.u_core.REFHI_v < 3.29 || u_refs.u_core.REFBY2_v < 1.64) begin
            $display("FAIL refs reals REFHI=%g REFBY2=%g",
                u_refs.u_core.REFHI_v, u_refs.u_core.REFBY2_v);
            errors = errors + 1;
        end else begin
            $display("PASS refs reals");
        end

        refs_pd = 1'b1;
        #1;
        if (refs_refhi !== 1'b0 || u_refs.u_core.REFHI_v != 0.0) begin
            $display("FAIL refs pd REFHI=%b %g", refs_refhi, u_refs.u_core.REFHI_v);
            errors = errors + 1;
        end else begin
            $display("PASS refs pd");
        end

        if (errors == 0) begin
            $display("CF_ADC_SAR12 behavioral model: %0d checks passed", 8);
            $finish;
        end else begin
            $display("CF_ADC_SAR12 behavioral model: %0d failure(s)", errors);
            $finish(1);
        end
    end
endmodule
