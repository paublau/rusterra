# MATRIX_PLUGINS - Agent 2 (Plugin Compatibility)

## 1) Decisions recomanades (curt i clar)
- **Stack base recomanat:** Carbon (framework de plugins), `RustEarthTerritory` (custom), Zones (control d'àrees), CopyPaste (bootstrap d'estructures d'event), plugin de limits d'entitats i plugin de neteja/decaïment per inactivitat.
- **Conquesta territorial:** resoldre-la al plugin custom `RustEarthTerritory`; evita dependre d'un únic plugin extern de "clans/factions" per la lògica crítica.
- **Inactivitat (free 48h / premium 7d):** aplicar política al model de dades del plugin custom i usar plugins externs només com a suport operatiu (neteja i decay d'actius).
- **Ordre de càrrega:** primer llibreries/framework, després dades socials (permissions/clans), després territori, i finalment observabilitat/UI.

---

## 2) Matriu de compatibilitat (A amb B)

Escala:
- ✅ Compatible habitualment
- ⚠️ Compatible amb configuració/ordre de càrrega
- ❌ Conflicte probable (evitar combinació directa)

| Plugin / Sistema | RustEarthTerritory (custom) | Zones | Clans/Teams | Entity Limits | Auto Cleanup / Decay | Economics / Leaderboard | Notes operatives |
|---|---:|---:|---:|---:|---:|---:|---|
| **RustEarthTerritory (custom)** | — | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | Cal prioritat de hooks per evitar doble càlcul de propietat/score. |
| **Zones** | ✅ | — | ✅ | ✅ | ✅ | ⚠️ | Si hi ha scoring per zona, evitar que UI/leaderboard escoltin events duplicats. |
| **Clans/Teams** | ✅ | ✅ | — | ⚠️ | ✅ | ✅ | Definir unitat de propietat (jugador vs clan vs país) des del primer dia. |
| **Entity Limits** | ⚠️ | ✅ | ⚠️ | — | ⚠️ | ✅ | Pot bloquejar construcció legítima en punts de captura si no hi ha whitelists. |
| **Auto Cleanup / Decay** | ⚠️ | ✅ | ✅ | ⚠️ | — | ✅ | Coordinar llindars perquè no "mengi" objectes d'event o bases actives premium. |
| **Economics / Leaderboard** | ✅ | ⚠️ | ✅ | ✅ | ✅ | — | Sincronitzar timestamps per evitar rànquings inconsistents post-wipe. |

### Conflictes coneguts a controlar
1. **Doble autoritat sobre ownership**: si Clans/Teams i RustEarthTerritory intenten decidir propietat territorial alhora.
2. **Neteja agressiva vs persistència territorial**: plugins de cleanup poden eliminar artefactes necessaris per rehidratació post-wipe.
3. **Limits globals massa rígids**: poden frenar mecàniques de captura en regions amb alta densitat.

---

## 3) Dependències mínimes

### Base tècnica
1. **Framework de plugins**: Carbon o equivalent actiu.
2. **Sistema de permisos**: permisos/grups (free/premium/admin).
3. **Persistència externa**: SQLite (staging) i opció MySQL/MariaDB (producció).

### Funcional mínim per objectiu RustEarth
1. `RustEarthTerritory` (custom):
   - mapping `region_id -> country_id`
   - captura/reconquesta
   - decay de control score segons inactivitat
   - rehidratació ownership post-wipe
2. Plugin de **limits d'entitats** configurable per grup/rol.
3. Plugin de **neteja/decaïment** amb exclusions (TC, markers de captura, assets d'event).
4. Integració **RCON/Discord** per alertes de pèrdua territorial i incidents.

---

## 4) Plugins que cal fer custom

### Imprescindible custom
- **`RustEarthTerritory`**: no hi ha combinació estàndard robusta que cobreixi conjuntament:
  - país com a unitat de control,
  - persistència de conquesta entre wipes de "coses",
  - regles diferenciades free/premium per inactivitat,
  - auditoria d'events i restauració consistent.

### Custom recomanat (si l'ecosistema escollit no ho resol)
- **Bridge de decay per membresia** (free/premium) si el plugin de decay no suporta regles per grup de permisos.
- **Adapter de leaderboard territorial** si el plugin d'economia no pot consumir events custom amb granularitat per regió.

---

## 5) Configuració base per staging

### Principis
- **Una sola font de veritat** per ownership territorial: `RustEarthTerritory`.
- **Wipe de coses** no ha de trencar `region_id` ni `country_id`.
- **Logs obligats** per captura, decay i restauració post-wipe.

### Valors inicials suggerits
- Free: decay accelerat a partir de **48h** sense activitat.
- Premium: decay accelerat a partir de **7 dies** sense activitat.
- Revisió de cleanup cada **6h** amb dry-run durant la primera setmana.
- Límit d'entitats:
  - Free: conservador
  - Premium: +20% sobre free (sense avantatge de combat)

### Ordre de càrrega (detallat)
Veure `config/plugin-load-order.txt`.

---

## 6) Passos executables en aquesta carpeta

1. Crear ordre de càrrega inicial:
   - `config/plugin-load-order.txt`
2. Preparar esquelet de configuracions per staging:
   - `config/staging.permissions.example.json`
   - `config/staging.cleanup.example.json`
3. Definir contracte mínim de dades de territori (a coordinar amb Agent 4):
   - `data/territory.contract.json`
4. Executar smoke test funcional (manual):
   - arrencada servidor
   - càrrega plugins
   - captura de regió
   - simulació inactivitat
   - restauració post-wipe

---

## 7) Riscos i mitigacions
- **Risc:** canvis d'API en framework/plugins externs.
  - **Mitigació:** version pinning + entorn staging replicable.
- **Risc:** regressió en l'ordre de càrrega.
  - **Mitigació:** prova d'arrencada automàtica i validació de hooks crítics.
- **Risc:** falsos positius de neteja sobre actius legítims.
  - **Mitigació:** dry-run + llista blanca d'assets + auditoria diària primera quinzena.

---

## 8) Criteri de validació
S'accepta la baseline de compatibilitat si es compleix:
1. Tots els plugins carreguen sense errors fatals.
2. Captura/reconquesta actualitza ownership i leaderboard en <5s.
3. Inactivitat aplica correctament 48h (free) i 7d (premium).
4. Wipe de coses + restart rehidrata ownership territorial al 100% de regions definides.
5. No hi ha pèrdua de dades d'auditoria (`capture_events`) en 3 reinicis consecutius.
