# Google Sheets Setup Guide — School Validation Tracker

## Import Instructions

1. Go to [Google Sheets](https://sheets.google.com) → New spreadsheet
2. File → Import → Upload → select `school-candidates.csv`
3. Import settings: **Comma** separator, **No** convert text to numbers/dates
4. Rename sheet tab to `Candidates`

---

## Column Reference

| Column | Description | Values |
|--------|-------------|--------|
| ID | Unique ID per region (M=Madrid, V=Valencia, C=Catalunya, A=Andalucía, PV=País Vasco, G=Galicia) | M001, V001… |
| school_name | Official name from public registry | Text |
| city | Municipality | Text |
| ccaa | Comunidad Autónoma | Madrid, Valencia, Catalunya… |
| phone | Primary phone from directory | Number |
| email | Email from directory | Text |
| titularidad | School ownership type | PRIVADO / PRIVADO CONCERTADO |
| tipo_centro | Center type code | EIPR, CPR INF, CPR INF-PRI, etc. |
| ciclos_est | Estimated age range | 0-3 / 0-6 / 0-18 |
| website | URL if available | URL |
| instagram | Instagram handle if found | @handle |
| S1_tipo | Score: School type focus | 0=INF+PRI+SEC, 1=INF+PRI, 2=Pure EI/EIPR |
| S2_ciclos | Score: Age range served | 0=wider, 1=0-6, 2=only 0-3 |
| S3_size | Score: Estimated size | 0=too big/small, 1=unknown, 2=20-80 kids |
| S4_digital | Score: Digital presence | 0=none, 1=website only, 2=website+social |
| S5_email | Score: Email in directory | 0=no, 1=yes |
| S6_independiente | Score: Independent operator (not chain) | 0=chain/concertado, 1=independent |
| total_score | Sum S1+S2+S3+S4+S5+S6 | 0–10 |
| tier | Priority tier | A=8-10 (call first), B=6-7 (second wave), C=4-5 (third wave), D=≤3 (skip) |
| call_status | Current status | pendiente / contactado / entrevistado / descartado |
| call_date | Date of last call | YYYY-MM-DD |
| attempts | Number of call attempts | 0, 1, 2, 3 |
| notes | Free notes from call | Text |
| signal_rating | Post-call signal strength | 🟢 strong / 🟡 neutral / 🔴 negative |
| next_step | Next action | llamar / enviar-email / programar-demo / cerrar |

---

## Google Sheets Formulas

### Auto-calculate Total Score
In column `R` (total_score), replace manual value with formula:
```
=L2+M2+N2+O2+P2+Q2
```

### Auto-assign Tier from Score
In column `S` (tier):
```
=IF(R2>=8,"A",IF(R2>=6,"B",IF(R2>=4,"C","D")))
```

### Count by Tier (add to a summary tab)
```
=COUNTIF(Candidates!S:S,"A")   → Tier A count
=COUNTIF(Candidates!S:S,"B")   → Tier B count
=COUNTIF(Candidates!T:T,"entrevistado")  → Calls completed
```

### Conditional Formatting
Apply to entire row based on tier (Format → Conditional formatting → Custom formula):
- Tier A (score ≥8): `=$S2="A"` → green background (#d9ead3)
- Tier B (score 6-7): `=$S2="B"` → yellow background (#fff2cc)
- Tier C (score 4-5): `=$S2="C"` → orange background (#fce5cd)
- Tier D (score ≤3): `=$S2="D"` → red background (#f4cccc)

### Filter for Priority Calls
Use Data → Create a filter. Then filter:
- `tier` = A or B
- `call_status` = pendiente
- `attempts` < 3

---

## Bulk Website Existence Check
Paste this formula to check if a website URL is live (requires IMPORTDATA):
```
=IF(C2="","No website",IF(ISERROR(IMPORTDATA(C2)),"❌ Down","✅ Live"))
```
> Note: Run this sparingly — Google Sheets limits IMPORTDATA calls.

---

## Data Sources to Complete Pending Rows

### Madrid (complete primer ciclo list)
The Madrid education CSV (`centros_educativos.csv`) contains mostly CPR INF-PRI-SEC schools.
Pure 0-3 guarderías may be regulated by social services:
- Try: `datos.comunidad.madrid` → search "guarderías" or "servicios sociales infancia"
- Or: EDUCABASE national search filtered by `E. Infantil - 1er ciclo` + `Madrid` + `privado`

### Catalunya (llar d'infants)
- Portal: [analisi.transparenciacatalunya.cat](https://analisi.transparenciacatalunya.cat) → search "centres docents"
- School map: [mapaescolar.gencat.cat](http://mapaescolar.gencat.cat) → filter by "Llar d'infants" + "Privat"
- API endpoint (if available): `https://analisi.transparenciacatalunya.cat/resource/e2ef-eiqj.csv?$where=titularitat='Privat'&$limit=500`

### Valencia
- Download CSV: `https://dadesobertes.gva.es/dataset/68eb1d94...` (see architecture doc for full URL)
- Filter by `regimen=PRIV.` and `denominacion_generica_es` contains `INFANTIL PRIMER CICLO`

### Andalucía
- Portal: [datos.juntadeandalucia.es](https://datos.juntadeandalucia.es) → "directorio centros docentes Andalucía"

### País Vasco
- Portal: [opendata.euskadi.eus](https://opendata.euskadi.eus) → search "centros educativos"
- Haur eskolak (nurseries) are regulated by the Basque Government's Hezkuntza department

---

## Call Tracking Workflow

1. Sort by `total_score` descending
2. Set `call_status` = `contactado` after first attempt, increment `attempts`
3. After a conversation: fill `notes`, set `signal_rating`, set `call_status` = `entrevistado`
4. If they hang up or say no: `call_status` = `descartado`
5. Check the signal codebook in `validation-plan.md` to assign 🟢/🟡/🔴

**Target: 15-20 completed interviews (🟢 or 🟡) before making the build/no-build decision.**
