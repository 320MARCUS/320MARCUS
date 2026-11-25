# Evidence register

> Evidence level: `E2`
>
> Definition: readable exports + BOM + native DRC + Gerber + manufacturing-file consistency
>
> Not included: physical assembly, power-up, ripple, thermal, EMC, or reliability testing

| Evidence | File | Result |
|---|---|---|
| Complete schematic | [`assets/schematic.pdf`](assets/schematic.pdf) | 7 pages; logical page order; zero detected personal-identifier markers |
| Schematic previews | [`assets/schematic-pages/`](assets/schematic-pages/) | 7 PNG pages rendered from the final PDF |
| Schematic overview | [`assets/schematic-overview.png`](assets/schematic-overview.png) | Seven-page visual contact sheet |
| PCB top capture | [`pcb/top-official.png`](pcb/top-official.png) | Official viewport capture, non-blank |
| PCB bottom capture | [`pcb/bottom-official.png`](pcb/bottom-official.png) | Official viewport capture, mirrored assembly view |
| PCB actual-readback SVG | [`pcb/top-actual.svg`](pcb/top-actual.svg), [`pcb/bottom-actual.svg`](pcb/bottom-actual.svg) | Same board dump as auxiliary assembly views |
| Schematic summary | [`evidence/schematic-summary.json`](evidence/schematic-summary.json) | 224 parts, 258 nets, 0 bridge, 0 orphan |
| Native PCB DRC | [`evidence/pcb-drc.json`](evidence/pcb-drc.json) | `passed:true`, 0 violations |
| PCB DFM audit | [`evidence/pcb-dfm-check.json`](evidence/pcb-dfm-check.json) | Coverage complete; 41 errors, 236 warnings |
| PCB layout lint | [`evidence/pcb-layout-lint.json`](evidence/pcb-layout-lint.json) | 2 envelope overlaps; 101 ratsnest crossings |
| Gerber | [`manufacturing/gerber.zip`](manufacturing/gerber.zip) | 18 entries, 763,765 bytes |
| Gerber validation | [`evidence/gerber-validation.json`](evidence/gerber-validation.json) | Millimeter units, required layers present, closed outline |
| BOM | [`manufacturing/bom.tsv`](manufacturing/bom.tsv) | 59 rows, 224 unique designators |
| Pick-and-Place | [`manufacturing/placement.csv`](manufacturing/placement.csv) | 224 rows, millimeter coordinates |
| BOM/P&P consistency | [`evidence/bom-placement-consistency.json`](evidence/bom-placement-consistency.json) | Exact 224/224 set match |

## Key consistency facts

- PCB dump: 224 components, 822 pads, 1,441 routed line primitives, 1,247 via objects, 14 copper-pour boundaries.
- Board outline: 4-point closed polygon, approximately 200.000 mm x 144.392 mm.
- Copper layers: 4 (top, bottom, `2GND`, `3POWER`).
- Gerber unit declaration: `%MOMM*%` on all copper/outline/mask/paste/silkscreen files; `METRIC` on all three drill files.
- The archive includes top and bottom copper, both inner copper layers, outline, solder mask, paste mask, silkscreen, NPTH, PTH, and plated-via drill data.
- Native DRC and reconstructed DFM are separate checks. A DFM warning does not mean the native DRC failed, and neither means the board was physically tested.
