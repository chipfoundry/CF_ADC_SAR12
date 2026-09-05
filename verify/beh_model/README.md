# CF_ADC_SAR12 behavioral model

Ideal functional models for digital simulation. They are **not** SPICE-accurate
and they are **not** Infineon protocol-verified. Use them to exercise `sof` /
`eof` firmware and SoC wrappers. Do not add these files to OpenLane
`VERILOG_FILES`.

## Files

| File | Replaces |
|---|---|
| `CF_ADC_SAR12_core.v` | `hdl/gl/CF_ADC_SAR12_core.v` |
| `CF_ADC_SAR12_sar_refs_core.v` | `hdl/gl/CF_ADC_SAR12_sar_refs_core.v` |

Keep the customer wraps in `hdl/gl/CF_ADC_SAR12.v` and
`hdl/gl/CF_ADC_SAR12_sar_refs.v`. Do **not** compile the empty `hdl/gl/*_core.v`
stubs in the same sim (duplicate module names).

```bash
./verify/beh_model/run_tb.sh
```

## Analog stimulus

The public pins `vinp` / `vinm` / `vrefhi` / `vreflo` / `refby2` are 1-bit
nets. Voltages live on Verilog `real` backdoors inside the core:

```verilog
u_adc.u_core.vinp_v   = 1.65;
u_adc.u_core.vinm_v   = 0.0;
u_adc.u_core.vrefhi_v = 3.3;   // or copy u_refs.u_core.REFHI_v
u_adc.u_core.vreflo_v = 0.0;
```

`CF_ADC_SAR12_sar_refs_core` exposes `vdda_v` (default 3.3 V), `REFHI_v`,
`REFBY2_v`, and `refout_v`. Digital `REFHI` / `REFBY2` / `refout` are 1 when
the matching real is above 0.1 V.

## Assumed protocol

A conversion starts when `sof` is sampled high on `refclk` in IDLE, with
`reset_n` high and `pd` / `pd_ana` low and `enable_hv` high.

1. Sample for `max(sample_width, 1)` `refclk` cycles and capture the reals.
2. Convert for `nbits + CONVERT_OVERHEAD` cycles (`CONVERT_OVERHEAD` default 1).
3. `data_out` updates in the same cycle `eof` rises. `eof` is one `refclk` wide.
4. `next` or a held `sof` starts another conversion after `eof`.

`resolution`: `2'b01` → 10-bit, `2'b10` → 8-bit, otherwise 12-bit.
Results are left-justified into `data_out[11:0]`.

Default (unipolar):

```
code = round((vinp_v - vinm_v) / (vrefhi_v - vreflo_v) * (2^n - 1))
```

Clamp to the legal range. Instantiate with `BIPOLAR=1` to map
`(vinp_v - vinm_v)` of ±span/2 onto `0 .. 2^n-1`.

`iso_en` forces `eof` and `data_out` to 0. Pump, trim, bias, DFT, scan
(beyond a 1-bit shift), mux select, and INL/DNL are ignored.
