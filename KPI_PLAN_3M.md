# KPI Plan Pilot 3 mesos - RustEarth (Agent 6)

## 1) Decisions recomanades (curt i clar)
- **Stack mínim d'observabilitat:** Prometheus + Grafana + Loki per reduir complexitat operativa i mantenir cost baix.
- **Model de dades:** separar metriques en 4 blocs: `server_health`, `territory_war`, `player_lifecycle`, `economy_balance`.
- **Cadencia d'anàlisi:** revisió setmanal operativa + informe mensual executiu.
- **Go/No-Go al final del pilot:** basat en estabilitat tècnica, retenció i qualitat de disputes territorials.

## 2) Repos/plugins candidats

| Component | URL | Últim update (aprox.) | Llicència | Risc | Nota d'ús |
|---|---|---:|---|---|---|
| Prometheus | https://github.com/prometheus/prometheus | Actiu | Apache-2.0 | Baix | Scrape de metriques custom/exporters |
| Grafana | https://github.com/grafana/grafana | Actiu | AGPL-3.0 | Baix | Dashboards, alerting i anotacions |
| Loki | https://github.com/grafana/loki | Actiu | AGPL-3.0 | Mitjà | Logs centralitzats (cost menor que ELK) |
| node_exporter | https://github.com/prometheus/node_exporter | Actiu | Apache-2.0 | Baix | CPU, RAM, disc i IO del servidor |
| cAdvisor (opcional) | https://github.com/google/cadvisor | Actiu | Apache-2.0 | Mitjà | Si hi ha contenidors |

> Nota: les metriques específiques de RustEarth (captures, ownership mismatch, decay aplicat) s'han d'emetre des del plugin custom via endpoint o fitxer agregable.

## 3) KPIs del pilot i definició exacta

### 3.1 Server Health (operació)
- **Tickrate mitjà 5m** (`tickrate_avg_5m`): objectiu >= 25.
- **P95 latència jugador-servidor** (`latency_p95_ms`): objectiu <= 120 ms.
- **Caigudes/dia** (`server_crashes_daily`): objectiu <= 1.
- **Temps recuperació mitjà** (`mttr_min`): objectiu <= 15 min.
- **Entitats actives totals** (`active_entities_total`): monitor per correlacionar lag.

### 3.2 Territory War (gameplay)
- **Disputes territorials/setmana** (`territory_disputes_weekly`).
- **Captures reeixides / intents** (`capture_success_rate`).
- **Temps mitjà de defensa efectiva** (`avg_defense_duration_min`).
- **Mismatches ownership post-wipe** (`ownership_mismatch_count`): objectiu 0.

### 3.3 Player Lifecycle (retenció)
- **DAU/WAU ratio** (`dau_wau_ratio`): objectiu >= 0.22.
- **Retenció D1 / D7 / D30** (`retention_d1`, `retention_d7`, `retention_d30`).
- **Churn setmanal** (`weekly_churn_pct`).
- **Temps fins abandonament clan** (`time_to_clan_exit_days`).

### 3.4 Balance per país/facció
- **Distribució de jugadors per país** (`players_per_country_share`).
- **Concentració de territori (índex HHI)** (`territory_hhi_index`).
- **Ingressos/consum de recursos per país** (`resource_netflow_by_country`).
- **Dominància excessiva** (`dominance_over_40pct_regions`): booleà d'alerta.

## 4) Llindars GO / NO-GO (fi de pilot, setmana 12)

### GO
- Tickrate mitjà >= 25 en hores punta durant 4 setmanes consecutives.
- Retenció D7 >= 18% i D30 >= 8%.
- `ownership_mismatch_count = 0` després de cada wipe planificat.
- Disputes territorials setmanals estables (no col·lapse de participació >30% 2 setmanes seguides).

### NO-GO
- Tickrate < 20 de forma recurrent (>25% franges punta en 2 setmanes).
- Més de 2 incidents crítics/mes sense correcció estructural.
- Retenció D7 < 12% durant 2 mesos seguits.
- Concentració territorial extrema (HHI molt alt) sense mecanismes de reequilibri.

## 5) Calendari de revisions

### Setmanal (operatiu, 45-60 min)
- Revisar dashboard operatiu + alertes de la setmana.
- Identificar anomalies i decidir accions de tuning.
- Assignar responsables i data límit.

### Mensual (executiu, 90 min)
- Evolució de KPIs macro (estabilitat, retenció, engagement territorial).
- Revisió de risc i decisió de priorització per al mes següent.
- Validació de “go/no-go parcial” mensual.

## 6) Alertes operatives mínimes
- **Lag crític:** `tickrate_avg_5m < 20` durant 10 min.
- **Latència degradada:** `latency_p95_ms > 180` durant 15 min.
- **Crash loop:** més de 2 reinicis en 30 min.
- **Ownership mismatch:** qualsevol valor > 0 post-wipe.
- **Disminució sobtada d'activitat:** DAU -35% WoW.

## 7) Passos executables en aquesta carpeta
1. Crear carpeta d'operacions i plantilles:
   - `ops/weekly_review_template.md`
2. Crear fitxer de pla KPI:
   - `KPI_PLAN_3M.md`
3. (Següent iteració) Afegir:
   - `ops/monthly_report_template.md`
   - `ops/alerts-rules.yml`

## 8) Riscos i mitigacions
- **Risc:** metriques incompletes del plugin custom.  
  **Mitigació:** definir contracte d'events mínims abans de producció (`capture_started`, `capture_finished`, `ownership_reapplied`, `decay_applied`).
- **Risc:** massa dashboards i poca acció.  
  **Mitigació:** limitar-se a 1 dashboard operatiu + 1 executiu.
- **Risc:** decisions tardanes per manca de cadència.  
  **Mitigació:** bloquejar reunió setmanal fixa amb acta i responsables.

## 9) Criteri de validació (com provar que funciona)
- Existeixen metriques per tots 4 dominis (`server_health`, `territory_war`, `player_lifecycle`, `economy_balance`).
- Les alertes crítiques es disparen en prova controlada.
- L'informe setmanal es pot completar en < 30 minuts amb dades objectives.
- Es pot emetre una decisió GO/NO-GO parcial cada mes sense dades manuals addicionals.

## 10) Planificació de treball (què pot anar en paral·lel vs què és seqüencial)

### Tasques que es poden treballar **simultàniament**
- Definició de KPIs de gameplay (`territory_war`) i de retenció (`player_lifecycle`).
- Disseny de dashboards Grafana i redacció de plantilles setmanals.
- Preparació d'alertes de servidor i inventari d'incidents.

### Tasques que han d'esperar la fase anterior (**seqüencials**)
1. Primer: contracte de metriques del plugin custom.
2. Després: implementació d'export de metriques.
3. Després: configuració final d'alertes sobre metriques reals.
4. Finalment: validació de llindars GO/NO-GO amb 4+ setmanes de dades.

