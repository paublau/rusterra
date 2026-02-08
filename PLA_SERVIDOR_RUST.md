# Pla de viabilitat - servidor Rust "món persistent"

## Objectiu
Avaluar i definir un servidor Rust amb mapa persistent (sense wipe total freqüent), amb equips per països i mecànica de pèrdua per inactivitat.

## Decisió base de disseny
Rust no està pensat per no-wipe indefinit. El model viable és:
- persistència de mapa + manteniment automàtic agressiu
- resets parcials de temporada (economia/BP) en lloc de wipe complet constant
- degradació per inactivitat com a regulador principal

## Model de temps (proposta inicial)
- Free: protecció d'inactivitat màxima de 48 hores
- Premium: protecció d'inactivitat màxima de 7 dies

### Lectura operativa
- Si no entres dins la finestra, el teu grup passa a decay accelerat.
- El terreny no es "reserva" indefinidament: la persistència no vol dir immunitat.

## Opcions de regles (A/B/C)

### Opció A (estricta, recomanada)
- Free: 48h sense login -> decay x3
- Premium: 7 dies sense login -> decay x2
- >14 dies (qualsevol): demolició automàtica d'actius orfes
Avantatge: rendiment estable, evita cimentar el mapa.
Risc: pot ser dura per jugadors casuals free.

### Opció B (equilibrada)
- Free: 48h -> decay x2
- Premium: 7 dies -> decay x1.5
- >21 dies: neteja automàtica selectiva
Avantatge: menys fricció comunitària.
Risc: més acumulació d'entitats.

### Opció C (per creixement inicial)
- Free: 72h (només primer mes), després 48h
- Premium: 10 dies (només primer mes), després 7 dies
- Neteja setmanal agressiva de deployables inactius
Avantatge: onboarding suau en llançament.
Risc: requereix comunicar canvi de fase.

## Països / faccions
- Assignació inicial: elecció manual en primer login.
- Canvi de país: cooldown (ex. 14 dies) per evitar abusos.
- Límit per país: soft cap per evitar superblocs.
- Bonus de compensació: països amb baixa població reben boost moderat de gather/respawn.

## Anti-lag mínim necessari
- Límit d'entitats per jugador i per clan.
- Neteja programada de deployables abandonats.
- Reinicis programats + monitoratge TPS/tickrate.
- Logs d'activitat i auditoria de decay.

## Monetització i equitat
Premium ha de donar comoditat, no pay-to-win:
- + finestra d'inactivitat (fins 7 dies)
- cues/slots prioritaris
- QoL cosmètic o administratiu menor
No incloure dany, loot o combat advantage.

## Full de ruta d'implementació
1. Definir regla final (A/B/C) i KPIs de rendiment (tickrate, entitats, latència).
2. Muntar servidor test privat amb plugins base (decay, límits, neteja, equips).
3. Simular 2-3 setmanes amb dades de càrrega i inactivitat real.
4. Ajustar multiplicadors i llindars de demolició.
5. Llançament públic en temporada 0 (durada recomanada: 30-45 dies).
6. Revisió posttemporada i possible reset parcial d'economia/BP.

## KPIs per validar viabilitat
- Tickrate estable en hora punta.
- Temps mitjà de resposta acceptable en raids/esdeveniments.
- % d'entitats netejades per inactivitat vs. actives.
- Retenció D1/D7 de free i premium.
- Distribució de població per país (evitar dominació extrema).

## Preguntes obertes
- Voleu que el premium mantingui només base principal o tot el clan?
- El còmput d'inactivitat és per jugador, per clan o per Tool Cupboard?
- Voleu reset parcial fix (ex. cada 45 dies) o només quan els KPIs caiguin?
