# RUNBOOK_WIPE_15D - Wipe de coses cada 15 dies (sense perdre conquesta)

## Objectiu
Executar un cicle de manteniment cada 15 dies que reiniciï **bases/loot/objectes** mantenint intacta la capa de **conquesta territorial per país**.

## Abast
- Inclou: backup, parada controlada, wipe de món (fitxers de save), arrencada, restauració de territorial ownership, proves de fum.
- No inclou: canvi de versió major de Rust, migracions disruptives de schema, redisseny de regions.

## Requisits previs
1. Servei Rust dedicat funcionant a Windows (service o procés controlat).
2. Plugin `RustEarthTerritory` amb:
   - export/import d'ownership (DB o JSON de suport).
   - comanda de reindexació/reaplicació post-wipe.
3. Estructura mínima:
   - `server/` (save files i identitat)
   - `backups/`
   - `logs/`
   - `scripts/wipe_15d.ps1`
   - `scripts/restore_territory.ps1`
4. Claus/credencials operatives disponibles:
   - accés al servei/host
   - accés DB territorial
   - token RCON (si es fan smoke tests per RCON)

---

## Pipeline operatiu (ordre estricte)

### 0) Finestra i comunicació (T-30 min)
- Avisar jugadors (Discord + in-game): manteniment planificat, durada estimada, hora de retorn.
- Congelar canvis manuals no crítics.
- Confirmar que ningú està executant migracions al mateix temps.

### 1) Backup (T-20 min)
- Backup de `save` del servidor Rust.
- Backup de BD territorial (`territories`, `capture_events`, `season_meta`, etc.).
- Guardar checksums i timestamp del lot.

### 2) Stop controlat (T-10 min)
- Enviar advertiments de countdown in-game.
- Aturar servei/procés Rust.
- Verificar que no hi ha lock de fitxers.

### 3) Wipe de coses (T0)
- Eliminar/rotar fitxers de món (`*.sav*`) i artefactes de sessió segons política.
- **No tocar** fitxers de configuració de regions ni BD de conquesta.

### 4) Start server (T+5)
- Arrencar servidor amb el mateix `seed/size/map layout` (contracte de `region_id` estable).
- Esperar que RCON estigui operatiu.

### 5) Restore territorial ownership (T+8)
- Executar `scripts/restore_territory.ps1`.
- Comprovar resum: regions restaurades, avisos d'inconsistència, errors.

### 6) Smoke tests (T+12)
- Validar connexió RCON i comandes bàsiques.
- Validar que una mostra de regions manté país correcte.
- Validar que es poden capturar/reconquerir regions noves.

### 7) Reobertura i monitoratge (T+15)
- Obrir servidor als jugadors.
- Monitoratge intensiu 30-60 min (tickrate, errors plugin, mismatch ownership).

---

## Tasques en paral·lel vs seqüencials

### Es poden fer simultàniament
- Preparar missatge de manteniment + changelog curt.
- Compressió de backups antics i rotació de `logs/`.
- Verificació prèvia de credencials RCON/DB.

### Han d'esperar a la fase anterior
- **Stop servidor** després de completar backup.
- **Wipe fitxers** després de confirmar servidor aturat.
- **Restore ownership** només després de confirmar que el servidor ja ha arrencat.
- **Reobrir públicament** només després de smoke tests satisfactoris.

---

## Checklist pre-wipe
- [ ] Confirmat horari de manteniment.
- [ ] Plugins carregats i versió de servidor estable.
- [ ] Espai de disc suficient per backup complet.
- [ ] `scripts/wipe_15d.ps1` i `scripts/restore_territory.ps1` verificats.
- [ ] Darrera prova de restauració feta en staging recentment.

## Checklist post-wipe
- [ ] Servidor accessible i estable (sense crash loop).
- [ ] Ownership territorial restaurat > 99% regions esperades.
- [ ] Sense errors crítics a logs del plugin.
- [ ] KPI inicial acceptable (tickrate/latència base).
- [ ] Comunicació de finalització enviada a la comunitat.

---

## Rollback (si hi ha fallada)

### Triggers de rollback
- Error crític en restauració territorial.
- Mismatch massiu de regions (`region_id` no reconeguts).
- Crash repetit en arrencada post-wipe.

### Procediment
1. Tancar servidor immediatament.
2. Restaurar fitxers de save des del backup del cicle.
3. Restaurar BD territorial del mateix lot de backup.
4. Arrencar servidor en mode restringit (whitelist admin).
5. Revalidar integritat i tornar a obrir progressivament.
6. Obrir incident report amb causa arrel i accions correctives.

---

## Criteri de validació (acceptació)
1. **Consistència**: totes les regions amb `owner_country_id` pre-wipe han quedat igual post-wipe (tolerància 0 en producció).
2. **Operabilitat**: servidor arrenca, accepta connexions i no presenta errors crítics els primers 30 minuts.
3. **Gameplay**: captures/reconquestes continuen funcionant després del restore.
4. **Traçabilitat**: existeix registre del lot de backup + log d'execució del runbook.

---

## Comandes d'ús (exemple)
```powershell
# Dry-run de validació
pwsh -File .\scripts\wipe_15d.ps1 -WhatIf -ServerRoot "D:\RustEarth\server" -BackupRoot "D:\RustEarth\backups"

# Execució real
pwsh -File .\scripts\wipe_15d.ps1 -ServerRoot "D:\RustEarth\server" -BackupRoot "D:\RustEarth\backups" -ServiceName "RustDedicated"
```

```powershell
# Restauració ownership explícita
pwsh -File .\scripts\restore_territory.ps1 -ServerRoot "D:\RustEarth\server" -ManifestPath "D:\RustEarth\backups\latest\territory_manifest.json"
```
