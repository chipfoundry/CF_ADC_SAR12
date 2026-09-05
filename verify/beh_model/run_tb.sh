#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${TMPDIR:-/tmp}/cf_adc_sar12_tb"
iverilog -g2005 -o "$OUT" \
  "$ROOT/hdl/gl/CF_ADC_SAR12.v" \
  "$ROOT/verify/beh_model/CF_ADC_SAR12_core.v" \
  "$ROOT/hdl/gl/CF_ADC_SAR12_sar_refs.v" \
  "$ROOT/verify/beh_model/CF_ADC_SAR12_sar_refs_core.v" \
  "$ROOT/verify/beh_model/tb_CF_ADC_SAR12.v"
vvp "$OUT"
