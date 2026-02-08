# PLUGIN_ARCHITECTURE.md

## Agent 4 - Arquitectura del plugin custom `RustEarthTerritory`

Objectiu: definir una arquitectura implementable per mantenir conquesta territorial persistent entre wipes de "coses" cada 15 dies.

---

## 1) Decisions recomanades (curt i clar)

1. **Arquitectura modular amb nucli de domini + adaptadors**: separar lògica de conquesta de hooks d'uMod/Oxide per facilitar test i manteniment.
2. **Persistència híbrida SQLite/MySQL**: SQLite per staging/single-node, MySQL per producció dedicada; mateix contracte de repositori.
3. **Event-sourcing lleuger per auditories**: registrar tots els canvis de propietat a `capture_events` i derivar estat actual a `territories`.
4. **Reaplicació idempotent post-wipe**: rutina segura que reconstrueix ownership des de BD sense duplicacions.
5. **Fallback resilient**: en error de BD, congelar captures noves, mantenir lectura en memòria i exposar alertes admin.

---

## 2) Abast funcional del plugin

### Funcions core
- Assignació de país (primer login + cooldown de canvi).
- Captura territorial (punt de captura / dominància / model híbrid configurable).
- Reconquesta (mateix flux de captura amb `from_country_id` informat).
- Decay territorial per inactivitat (free 48h, premium 7d).
- Reaplicació d'ownership després de wipe de coses.
- Auditoria completa d'esdeveniments.

### Fora d'abast (fase 1)
- UI avançada in-game (només API/events i missatges mínims).
- Economia complexa i recompenses dinàmiques.
- Integració directa amb BI extern (només export bàsic).

---

## 3) Arquitectura tècnica

## 3.1 Components

- **OxideAdapter**
  - Hooks del servidor Rust (login, construcció, combat/captura, wipe cycle).
  - Traducció d'events de joc a comandes de domini.

- **TerritoryApplicationService**
  - Casos d'ús: `AssignCountry`, `StartCapture`, `CompleteCapture`, `ApplyDecay`, `ReapplyOwnership`.
  - Gestió de transaccions i validacions.

- **Domain Core**
  - Entitats: `Territory`, `Country`, `PlayerAffiliation`, `CaptureEvent`, `Season`.
  - Regles de negoci (cooldowns, llindars de control, anti-abús).

- **Repository Layer**
  - Interfícies: `ITerritoryRepository`, `ICountryRepository`, `ICaptureEventRepository`, `ISeasonRepository`.
  - Implementacions: SQLite i MySQL.

- **Scheduler/Jobs**
  - Jobs periòdics: decay, conciliació, purga d'auditories antigues, heartbeat.

- **Admin/API Surface**
  - Comandes admin (`/re_territory_sync`, `/re_decay_run`, `/re_country_set`).
  - Events per integració Discord/RCON.

## 3.2 Flux principal de captura

1. `OxideAdapter` detecta condició de captura complerta.
2. `TerritoryApplicationService.CompleteCapture(regionId, actorCountryId)` valida:
   - regió existent i activa,
   - país vàlid,
   - no bloqueig temporal,
   - no conflicte de temporada.
3. S'inicia transacció.
4. Update atòmic de `territories`.
5. Insert a `capture_events`.
6. Commit i emissió event `TerritoryCaptured`.

## 3.3 Reaplicació ownership post-wipe

- Entrada: set de `region_id` actual de `regions.json`.
- Procés idempotent:
  1. validar contracte `region_id` (sense IDs orfes o nous sense mapping),
  2. carregar estat des de `territories`,
  3. reaplicar ownership al runtime,
  4. registrar resultat a `reapply_runs`.
- Si falla una regió: marcar com `degraded`, continuar amb la resta, alertar admin.

---

## 4) API interna (contractes)

## 4.1 Comandes de domini

- `AssignCountry(playerId, countryId, reason)`
- `StartCapture(regionId, countryId, startedByPlayerId)`
- `CompleteCapture(regionId, countryId, completedByPlayerId)`
- `ApplyTerritorialDecay(runAt)`
- `ReapplyOwnership(seasonId, runId)`

## 4.2 Esdeveniments de domini

- `CountryAssigned`
- `CaptureStarted`
- `TerritoryCaptured`
- `TerritoryDecayed`
- `OwnershipReapplied`
- `OwnershipReapplyPartiallyFailed`

## 4.3 Regles de validació mínimes

- Un jugador només pot tenir **un país actiu**.
- Canvi de país amb cooldown configurable (recomanat: 14 dies).
- Una regió només pot tenir **un owner_country_id**.
- Captura concurrent sobre mateixa regió: lock optimista (`version`) o lock transaccional.

---

## 5) Persistència i migracions

## 5.1 Motor recomanat
- **Producció**: MySQL 8+.
- **Staging/local**: SQLite 3.40+.

## 5.2 Estratègia de migració
- Carpeta: `sql/migrations`.
- Nomenclatura: `V{num}__{descripcio}.sql`.
- Canvis sempre forward-only; rollback via scripts explícits.

## 5.3 Índexs clau
- `territories(region_id)` PK.
- `territories(owner_country_id, updated_at)` per rànquing i dashboards.
- `capture_events(region_id, created_at)` per auditories i timeline.
- `player_country_membership(player_id, active)` per lookup de permisos.

---

## 6) Model de decay territorial

## 6.1 Inputs
- Última activitat per país/regió.
- Tipus de compte (free/premium).
- Multiplicadors de decay per inactivitat.

## 6.2 Política recomanada
- **Free**: >48h sense activitat => `control_score -X` per interval.
- **Premium**: >7 dies sense activitat => `control_score -Y` per interval.
- `control_score <= 0`: regió passa a estat neutral (`owner_country_id = NULL`).

## 6.3 Proteccions
- Clamp de puntuació [0..100].
- Cooldown de recaptura després de neutralització (opcional 30-60 min).
- Límit de pèrdua màxima per cicle per evitar wipes encoberts.

---

## 7) Events d'auditoria (`capture_events`)

Cada captura/reconquesta/neutralització ha de registrar:
- `region_id`
- `from_country_id` (nullable)
- `to_country_id` (nullable)
- `reason` (`capture`, `reconquest`, `decay`, `admin_override`, `reapply`)
- `actor_player_id` (nullable si job automàtic)
- `season_id`
- `metadata_json` (context opcional)
- `created_at`

Això permet:
- reconstrucció històrica,
- anàlisi de disputes,
- traçabilitat per incidències.

---

## 8) Fallbacks en errors

## 8.1 Tipus d'error
- Error temporal de connexió BD.
- Error de migració.
- Error de contracte de dades (`region_id` inconsistente).

## 8.2 Comportament degradat
- Passar a **read-only de conquesta**: no noves captures, sí consultes.
- Fer cua temporal d'events en memòria (TTL curt) quan hi hagi error temporal.
- Reintents exponencials (max N).
- Notificació admin immediata via log + webhook.

## 8.3 Recovery
- Auto-heal quan torni BD.
- Reconciliació de cua pendent amb deduplicació per `idempotency_key`.

---

## 9) Seguretat i integritat

- Comandes admin restringides per permisos Oxide.
- Escapar i parametritzar totes les consultes SQL.
- Validar `country_id` i `region_id` contra catàlegs actius.
- Checksum de `regions.json` guardat a BD per detectar mismatch de mapa.

---

## 10) Operativa i desplegament

## 10.1 Ordre d'implementació (què pot anar en paral·lel)

**Seqüencial (bloquejant):**
1. Definir contractes de dades (`schema.sql`) i migració base.
2. Implementar repositoris + servei d'aplicació.
3. Afegir hooks d'Oxide per captura.

**En paral·lel (no bloquejant entre si, després del punt 1):**
- A) Jobs de decay i reconciliació.
- B) Comandes admin i observabilitat.
- C) Integració Discord/RCON per alertes.

## 10.2 Smoke tests mínims
- Captura simple d'una regió neutral.
- Reconquesta entre dos països.
- Simulació decay free/premium.
- Wipe de coses + reaplicació 100% de `region_id` vàlids.

---

## 11) Riscos i mitigacions

- **Risc:** condicions de carrera en captures simultànies.
  - **Mitigació:** transaccions + `version` optimista.
- **Risc:** deriva entre mapa i BD (`region_id`).
  - **Mitigació:** validació prèvia i checksum abans de reaplicar.
- **Risc:** sobrecàrrega d'events.
  - **Mitigació:** índexs, partició temporal (MySQL), retenció configurable.

---

## 12) Criteri de validació

El disseny es considera vàlid si:
1. Un cicle complet de wipe 15 dies restaura ownership sense pèrdues.
2. Totes les captures queden auditades i consultables.
3. Els llindars 48h/7d produeixen decay consistent.
4. En fallada de BD, el sistema entra en degradació segura i recupera estat.

