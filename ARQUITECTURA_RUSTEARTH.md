# Arquitectura tecnica - RustEarth (conquesta persistent + wipe de coses cada 15 dies)

## Objectiu operatiu
- Persistir control territorial per pais al llarg de temporades.
- Fer wipe cada 15 dies de coses del servidor (bases/loot/economia segons configuracio), sense perdre propietat de territori.
- Mantenir mapa tipus "mon" aproximat, jugable i optimitzat.

## Viabilitat resumida
Si, es viable.
No es viable fer un "mon real" 1:1 dins Rust de forma jugable. La via correcta es fer un mapa estilitzat: continents recognoscibles, distancia i recursos ajustats a gameplay.

## Disseny del mapa (mundo aproximat)
- Eina: RustEdit per crear mapa custom.
- Escala recomanada inicial: 4250-4500.
- Territori segmentat en regions (grid o poligons simples).
- Cada regio te un id estable (ex: `NA_03`, `EU_12`).
- Les fronteres de regio han de ser estables entre versions de mapa per no trencar la persistencia.

## Model de dades territorial
Persistencia fora del save del servidor (SQLite o MySQL).

Taula `territories`:
- `region_id` (PK)
- `owner_country_id` (nullable)
- `control_score` (0-100)
- `last_capture_at` (timestamp)
- `updated_at` (timestamp)

Taula `countries`:
- `country_id` (PK)
- `name`
- `is_active`

Taula `season_meta`:
- `season_id` (PK)
- `start_at`
- `end_at`
- `wipe_type` (items_only/full)

Taula `capture_events` (audit):
- `id` (PK)
- `region_id`
- `from_country_id`
- `to_country_id`
- `reason` (raid/event/decay)
- `created_at`

## Logica de conquesta
- Un pais conquista una regio quan compleix condicions (control point, TC dominance, event, etc.).
- En canvi de control:
  - update `territories.owner_country_id`
  - update `control_score`
  - insertar event a `capture_events`
- Si no hi ha activitat en regio durant X dies, es pot degradar `control_score` per facilitar reconquesta.

## Wipe cada 15 dies (nomes coses)
Objectiu: renovar economia/base-building sense esborrar geopolítica.

Flux recomanat:
1. Tancar temporadeta (`season_meta.end_at`).
2. Backup complet (save + BD territorial).
3. Executar wipe de coses al servidor Rust.
4. Reiniciar amb mateix layout de mapa (mateix set de `region_id`).
5. Carregar plugin territorial i reaplicar ownership des de BD.
6. Obrir nova temporada (`season_meta.start_at`).

## Regles free/premium (acoblades al model)
- Free: inactivitat maxima 48h abans de decay accelerat.
- Premium: inactivitat maxima 7 dies abans de decay accelerat.
- Nivell territorial: si un pais no genera activitat minima, pot perdre `control_score` a regions per abandonament.

## Stack minim de plugins/sistemes
- Plugin custom `RustEarthTerritory`:
  - mapeig regio <-> pais
  - captura/reconquesta
  - persistencia BD
  - API per UI/leaderboard
- Plugin de decay configurable (free vs premium).
- Plugin limits d'entitats i neteja automatica.
- Integracio Discord/Rust+ per alerts de perdua territorial.

## Riscos i mitigacions
- Risc: mismatch entre versio de mapa i `region_id`.
  Mitigacio: contracte de regions estable i test de compatibilitat pre-wipe.
- Risc: bola de neu d'un pais dominant.
  Mitigacio: soft cap territorial + bonus de catch-up a paisos menors.
- Risc: lag per entitats.
  Mitigacio: limits per clan/jugador, neteges programades, decay agressiu per inactius.

## Pla d'execucio (90% practic)
1. Definir fitxer mestre de regions (`regions.json`) amb ids estables.
2. Fer mapa v1 estilitzat a RustEdit i validar spawn/routes.
3. Implementar BD + plugin territorial minim (capture + persistencia + restore).
4. Simular 1 cicle de 15 dies en staging.
5. Mesurar KPIs: tickrate, entitats, disputes per regio, retencio D1/D7.
6. Ajustar i obrir Temporada 0 publica.

## Criteri de "go/no-go"
Go si:
- tickrate estable en hora punta
- restauracio territorial post-wipe 100% consistent
- latencia i crashejos dins llindar
- retencio i participacio suficients per pais
No-go si falla consistencia territorial o rendiment sostingut.

## Decisions a tancar ara
- Wipe de 15 dies inclou o no blueprints?
- Conquesta per control points, per raid o model hibrid?
- Degradacio territorial per inactivitat: lineal o escalonada?
