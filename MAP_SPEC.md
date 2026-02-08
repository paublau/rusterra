# MAP_SPEC - RustEarth "món aproximat" (Agent 3)

## 1) Decisions recomanades (curt i clar)
- **Escala de mapa recomanada:** `4500` (dins rang 4250-4500) per mantenir jugabilitat, rutes marítimes i espai PvP sense fer el mapa excessivament dispers.
- **Model territorial:** regions macro-estables amb ID immutable (`NA_01`, `EU_04`, etc.) + punts de captura fixos per evitar disputes per microcanvis de terreny.
- **Persistència:** el control territorial es vincula a `region_id` i `capture_point_id`, no a coordenades absolutes de construccions (resistent a wipe de “coses”).
- **Balanç:** distribuir recursos de forma asimètrica però compensada (metall/sulfur/petroli/menjar), amb “trade-offs” per forçar moviment entre continents.
- **Versionat:** semver de mapa (`map_version`) amb taula de migració d’IDs i política “no reusar IDs retirats”.

## 2) Repos/plugins candidats (mapa i pipeline)

| Categoria | Candidat | URL | Últim update* | Llicència | Risc |
|---|---|---|---|---|---|
| Edició mapa | RustEdit | https://www.rustedit.io/ | Verificar abans d’adoptar | Comercial/Freemium (segons ús) | Dependència d’eina externa i format propietari parcial |
| Framework plugins | uMod/Oxide (estat actual a validar) | https://umod.org/games/rust | Verificar abans d’adoptar | Mix (framework + plugins) | Canvis d’ecosistema entre uMod/Carbon/Oxide |
| Plugin framework alternatiu | Carbon | https://carbonmod.gg/ | Verificar abans d’adoptar | Verificar | Compatibilitat real per plugin concret |
| Telemetria mapa (custom) | regions.json propi + plugin `RustEarthTerritory` | Repo intern del projecte | N/A | Intern | Cost de manteniment propi |

\* **Nota:** cal validació final de manteniment actiu en el moment d’implementació (evitar dades no verificades).

## 3) Disseny de regions estables

### 3.1 Principis de disseny
- **No 1:1 geogràfic:** siluetes estilitzades perquè el gameplay tingui prioritat sobre precisió cartogràfica.
- **Region IDs immutables:** un cop publicat un `region_id`, no es canvia ni es reutilitza.
- **Contigüitat clara:** cada regió té fronteres lògiques i punts de pas (chokepoints) explícits.
- **Simetria competitiva parcial:** cap continent concentra tots els recursos crítics.

### 3.2 Catàleg inicial de regions
- **Nord-amèrica:** `NA_01`, `NA_02`, `NA_03`, `NA_04`
- **Sud-amèrica:** `SA_01`, `SA_02`, `SA_03`
- **Europa:** `EU_01`, `EU_02`, `EU_03`, `EU_04`
- **Àfrica:** `AF_01`, `AF_02`, `AF_03`
- **Àsia:** `AS_01`, `AS_02`, `AS_03`, `AS_04`
- **Oceania:** `OC_01`, `OC_02`
- **Àrtic (control logístic):** `AR_01`

Total proposta inicial: **21 regions**.

## 4) Regles de frontera i punts de captura

### 4.1 Frontera
- Una captura només pot començar si el clan controla com a mínim **1 regió adjacent** o un **hub marítim connectat**.
- Fronteres transoceàniques limitades a rutes predefinides (evita “teleport conquest”).
- Si una regió queda aïllada, manté control però pateix penalització de manteniment (cost temporal o vulnerabilitat extra configurable).

### 4.2 Punts de captura (`capture_points`)
- Cada regió té:
  - `cp_capital` (valor alt)
  - `cp_industry` (valor econòmic)
  - `cp_logistics` (valor de connexió)
- Condició recomanada de captura de regió:
  - Control de `cp_capital` + (almenys 1 dels altres 2) durant una finestra temporal.
- Els punts de captura s’han de col·locar en zones jugables (evitar cims extrems/bug spots).

## 5) Criteris de balanç de recursos per regió

### 5.1 Tiers de recursos
- **Tier A (escàs i crític):** sulfur, crude/fuel d’alt volum.
- **Tier B (base combat/construcció):** metall HQM/metal frags.
- **Tier C (sosteniment):** pedra, fusta, menjar.

### 5.2 Regles de balanç
- Cada continent ha de tenir mínim:
  - 1 regió “forta” en Tier A,
  - 1 regió “forta” en Tier B,
  - suficients Tier C per sostenir grups nous.
- Cap regió supera ~`1.35x` rendiment total relatiu respecte la mitjana global (evitar “must-pick”).
- Regions petites poden tenir bonus de mobilitat/logística en lloc de raw resources.

## 6) Especificació per `data/regions.json`

### 6.1 Esquema inicial (resum)
- `schema_version`: versió de l’esquema de dades.
- `map`: metadades (`map_id`, `map_size`, `map_version`, `seed`).
- `regions[]`:
  - `id`, `name`, `continent`, `biome_profile`, `resource_profile`
  - `adjacent_regions[]`
  - `capture_points[]` (id, type, weight, world_pos)
  - `control_rules` (timers, requisits)
  - `versioning` (created_in, deprecated_in)
- `sea_routes[]`: connexions marítimes vàlides.
- `id_migrations[]`: mapatge d’IDs antics a nous (si algun dia cal).

### 6.2 Notes d’implementació
- Coordenades (`world_pos`) inicialment placeholders fins al layout final de RustEdit.
- El plugin ha de validar:
  - IDs únics
  - adjacència bidireccional
  - que cada regió tingui 3 capture points mínim (capital/industry/logistics)

## 7) Versionar mapa sense trencar persistència territorial

### 7.1 Política de compatibilitat
- **No breaking (minor/patch):** retoc visual/terreny sense tocar `region_id`.
- **Breaking controlat (major):** canvis d’estructura regional amb `id_migrations` obligatori.

### 7.2 Flux de migració recomanat
1. Congelar captures noves temporalment.
2. Exportar estat territorial (owner per `region_id`).
3. Aplicar migració `old_region_id -> new_region_id`.
4. Rehidratar control amb regles de fallback (si split/merge).
5. Executar smoke tests de frontera/captura.

### 7.3 Regles d’or
- No reusar IDs retirats.
- Mantenir històric de versions al repositori.
- Test de regressió de persistència a cada canvi de `map_version`.

## 8) Passos executables en aquesta carpeta

### Fase A (pot anar en paral·lel)
- A1. Editar/validar `data/regions.json`.
- A2. Preparar layout en RustEdit amb punts de captura placeholders.
- A3. Definir tests de validació d’adjacència i esquema.

### Fase B (ha d’esperar A1+A2)
- B1. Connectar `regions.json` amb plugin de territori.
- B2. Executar simulació de captura multi-regió.

### Fase C (ha d’esperar B1+B2)
- C1. Congelar versió `map_version` per staging.
- C2. Provar migració de persistència (mock wipe de “coses”).

## 9) Riscos i mitigacions
- **Risc:** desequilibri de recursos per continent.  
  **Mitigació:** simulacions de farm/combat per regió i ajust de pesos.
- **Risc:** fronteres confuses (disputes injustes).  
  **Mitigació:** adjacència explícita a JSON + visualització debug in-game.
- **Risc:** canvis de mapa trenquen ownership.  
  **Mitigació:** `id_migrations`, política semver i proves de regressió.
- **Risc:** punts de captura en zones explotables.  
  **Mitigació:** QA gameplay amb casos d’abús (altura/col·lisions/line-of-sight).

## 10) Criteri de validació (com provar que funciona)
- Validació d’esquema JSON passa sense errors.
- Totes les regions tenen:
  - ID únic,
  - adjacències coherents,
  - 3 capture points mínim,
  - perfils de recursos definits.
- Simulació de conquestes:
  - només permet captures adjacents/rutes marítimes.
- Test de persistència:
  - després de wipe de construccions, el control territorial per `region_id` es conserva.
- Test de migració:
  - canvi de `map_version` amb `id_migrations` manté propietari esperat.
