# Prompts per agents - RustEarth

## Context comu (enganxa-ho a cada agent)
Projecte: `RustEarth`  
Carpeta de treball: `c:\Users\trape\programes vscode\rustearth`  
Objectiu: mapa persistent amb conquesta per pais, wipe cada 15 dies nomes de coses, free 48h inactiu, premium 7 dies inactiu.  
Entorn final: servidor dedicat.  
Finestra de test: 3 mesos.  
Important: prioritzar fonts oficials i repos actius; no improvisar dades no verificades.

Sortida obligatoria de cada agent:
1. Decisions recomanades (curt i clar).
2. Repos/plugins candidats (taula amb URL, ultim update, llicencia, risc).
3. Passos executables en aquesta carpeta.
4. Riscos i mitigacions.
5. Criteri de validacio (com provar que funciona).

---

## Agent 1 - Recerca de repos i stack base
Ets Agent 1 (Repo Scout).  
Fes recerca dels repos necessaris per muntar:
- servidor Rust dedicat
- framework de plugins (uMod/Oxide o equivalent actual)
- plugins de decay/neteja/limits
- eines de mapa custom (RustEdit pipeline)
- integracio Discord/RCON/Rust+

Tasques:
- Dona una llista prioritzada de repos (must-have, should-have, optional).
- Marca si cada repo te manteniment actiu i compatibilitat amb la versio actual de Rust.
- Proposa estructura de carpetes dins `rustearth` per clonar-ho tot.
- Dona comandes `git clone` en ordre.
- Evita eines abandonades si hi ha alternativa estable.

Condicio de sortida:
- Entregar un fitxer `REPOS_STACK_BASE.md` i un script `scripts/clone_repos.ps1`.

---

## Agent 2 - Compatibilitat de plugins i dependecies
Ets Agent 2 (Plugin Compatibility).  
Analitza compatibilitat real entre plugins necessaris per:
- conquesta territorial
- decay per inactivitat (free 48h, premium 7d)
- limits d'entitats
- neteja automatica
- economia/leaderboard (si cal)

Tasques:
- Fer matriu de compatibilitat (plugin A amb B, conflictes coneguts, ordre de carrega).
- Definir dependencies minimals.
- Identificar plugins que cal fer custom.
- Proposar configuracio base per staging.

Condicio de sortida:
- Entregar `MATRIX_PLUGINS.md` + `config/plugin-load-order.txt`.

---

## Agent 3 - Disseny mapa "mon aproximat"
Ets Agent 3 (Map Design).  
Dissenya una proposta de mapa estilitzat del mon (no 1:1) jugable en escala 4250-4500.

Tasques:
- Definir regions estables amb IDs (`NA_01`, `EU_04`, etc.).
- Dissenyar regles de frontera i punts de captura.
- Definir criteris de balanc de recursos per regio.
- Preparar especificacio per a `regions.json`.
- Explicar com versionar mapa sense trencar persistencia territorial.

Condicio de sortida:
- Entregar `MAP_SPEC.md` + `data/regions.json` (schema inicial).

---

## Agent 4 - Arquitectura plugin custom RustEarthTerritory
Ets Agent 4 (Core Plugin Architect).  
Defineix arquitectura tecnica del plugin custom `RustEarthTerritory`.

Tasques:
- API interna: assignacio de pais, captura, reconquesta, decay territorial.
- Persistencia (SQLite/MySQL) amb migracions.
- Events d'auditoria (`capture_events`).
- Reaplicacio d'ownership despres de wipe de coses.
- Contracts de dades i fallback en errors.

Condicio de sortida:
- Entregar `PLUGIN_ARCHITECTURE.md` + `sql/schema.sql` + `sql/migrations/`.

---

## Agent 5 - Orquestracio de wipe 15 dies
Ets Agent 5 (Wipe Orchestrator).  
Defineix runbook automatitzat de wipe cada 15 dies sense perdre conquesta.

Tasques:
- Pipeline: backup, stop server, wipe coses, start server, restore ownership, smoke tests.
- Scripts PowerShell per servidor dedicat.
- Checklists pre/post wipe.
- Rollback en cas de fallada.

Condicio de sortida:
- Entregar `RUNBOOK_WIPE_15D.md` + `scripts/wipe_15d.ps1` + `scripts/restore_territory.ps1`.

---

## Agent 6 - Observabilitat i KPIs del pilot (3 mesos)
Ets Agent 6 (Telemetry/KPI).  
Defineix metriques i dashboard minim per validar viabilitat en 3 mesos.

Tasques:
- KPIs: tickrate, latencia, entitats actives, disputes territorials, retencio D1/D7/D30, balanc per pais.
- Llindars go/no-go.
- Calendari de revisions setmanals i informe mensual.
- Alerts operatives (lag, caigudes, mismatch ownership).

Condicio de sortida:
- Entregar `KPI_PLAN_3M.md` + `ops/weekly_review_template.md`.

---

## Agent 7 - Validacio gameplay amb client del joc
Ets Agent 7 (Gameplay QA).  
Tenim el joc instal.lat localment. Defineix proves jugables per validar experiencia real.

Tasques:
- Escenaris de test per clan free i premium.
- Validar que inactivitat aplica be (48h vs 7 dies).
- Validar captura/reconquesta i persistencia post-wipe.
- Detectar exploits (canvi de pais, multiclans, abuse de decay).

Condicio de sortida:
- Entregar `GAMEPLAY_TEST_PLAN.md` + `qa/test-cases.csv`.

---

## Agent 8 - Integrador final
Ets Agent 8 (Integrator).  
Consolida tota la recerca dels agents 1..7 en un pla executable unic.

Tasques:
- Prioritzar backlog per sprints (setmana 1..12).
- Definir dependencies entre tasques.
- Identificar bloquejos tecnics i alternatives.
- Preparar ordre d'implementacio dins aquesta carpeta.

Condicio de sortida:
- Entregar `MASTER_IMPLEMENTATION_PLAN_12W.md` amb cronograma setmanal.

---

## Prompt curt de llancament (plantilla)
Copia i enganxa a qualsevol agent:

```text
Context: treballem a c:\Users\trape\programes vscode\rustearth. 
Volem RustEarth: conquesta per pais persistent, wipe cada 15 dies nomes de coses, free 48h inactiu, premium 7 dies.
Entorn final: servidor dedicat. Pilot: 3 mesos.

Rol: [NOM_AGENT]
Objectiu: [OBJECTIU_AGENT]

Entrega exactament:
1) decisions recomanades
2) llista de repos/plugins (url + manteniment + risc)
3) passos executables en aquesta carpeta
4) riscos/mitigacions
5) criteri de prova
6) fitxers a crear amb ruta concreta
```
