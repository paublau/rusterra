# REPOS STACK BASE (Agent 1 - Repo Scout)

## 1) Decisions recomanades (curt i clar)
- **Base recomanada**: usar servidor dedicat oficial de Rust (`RustDedicated`) + framework de plugins **Carbon** com a opcio principal i **Oxide/uMod** com a fallback de compatibilitat.
- **Prioritat operativa**: primer assegurar un servidor vanilla estable, despres afegir framework de plugins, i finalment plugins de gameplay i automatitzacio.
- **Eina de mapa**: mantenir pipeline de mapa amb RustEdit i control de versions dels fitxers de mapa/configuracio dins del repo.
- **Integracions externes**: RCONWeb + bots Discord, sempre separant secrets en variables d'entorn.

## 2) Repos/plugins candidats

### Must-have
| Component | Repo/URL | Ultim update (aprox.) | Llicencia | Risc | Notes compatibilitat |
|---|---|---|---|---|---|
| Servidor dedicat Rust | https://github.com/GameServerManagers/LinuxGSM (scripts de gestio per RustDedicated) | Actiu | MIT | Baix | No substitueix RustDedicated, pero simplifica instal.lacio/updates/restarts. |
| Framework plugins (principal) | https://github.com/CarbonCommunity/Carbon | Actiu | (revisar repo) | Mitja | Alternativa moderna a Oxide; validar suport exacte de plugins heretats. |
| Framework plugins (fallback) | https://github.com/OxideMod/Oxide.Rust | Historicament usat; activitat irregular segons etapa | LGPL-3.0 | Mitja/Alta | Molts plugins classics depenen d'Oxide API; revisar estat real abans de produccio. |
| RCON Web | https://github.com/Facepunch/webrcon | Actiu historic | MIT | Baix | Basic per operacio remota i automatitzacions. |
| Actualitzador SteamCMD | https://github.com/GameServerManagers/LinuxGSM | Actiu | MIT | Baix | Incloure com a dependencia operativa per mantenir servidor al dia. |

### Should-have
| Component | Repo/URL | Ultim update (aprox.) | Llicencia | Risc | Notes compatibilitat |
|---|---|---|---|---|---|
| RustEdit (ecosistema i docs) | https://www.rustedit.io/ | Actiu (web/eina) | Comercial/propietari (eina) | Mitja | Eina de mapa referencia; no sempre amb repo public principal. |
| Bot Discord per Rust | https://github.com/itschip/DiscordCoreAPI (base C#) + bot custom | Actiu | MIT | Mitja | Recomanable fer bot propi fiabilitzat per esdeveniments territorials. |
| Col.leccio plugins comunitat | https://codefling.com/plugins/ | Actiu | Mixt | Alta | Marketplace util pero heterogeni; cal validacio plugin a plugin. |

### Optional
| Component | Repo/URL | Ultim update (aprox.) | Llicencia | Risc | Notes compatibilitat |
|---|---|---|---|---|---|
| Prometheus exporter (custom) | Repo intern (a crear) | N/A | Intern | Mitja | Per KPI del pilot; habitualment cal desenvolupament propi. |
| Terraform/Ansible infraestructura | Repo intern (a crear) | N/A | Intern | Mitja | Automatitzacio extra si es vol escalar a mes d'un node. |

> Nota: l'estat d'activitat pot variar rapidament; abans de bloquejar stack, revisar issues/commits dels ultims 90 dies.

## 3) Estructura de carpetes proposada dins `rustearth`

```text
rustearth/
  server/
    lgsm/
    rust-dedicated-config/
  framework/
    carbon/
    oxide/
  plugins/
    core/
    territory/
    quality-of-life/
  maps/
    rustedit/
    generated/
  integrations/
    discord-bot/
    rcon-tools/
  ops/
    backups/
    runbooks/
  scripts/
    clone_repos.ps1
```

## 4) Comandes `git clone` (ordre recomanat)

### Ordre de bootstrap
1. Infra de servidor (LinuxGSM)
2. Framework principal (Carbon)
3. Framework fallback (Oxide)
4. Integracions d'operacio (RCON)
5. Integracions Discord/base bot

### Comandes
```powershell
git clone https://github.com/GameServerManagers/LinuxGSM.git server/lgsm
git clone https://github.com/CarbonCommunity/Carbon.git framework/carbon
git clone https://github.com/OxideMod/Oxide.Rust.git framework/oxide
git clone https://github.com/Facepunch/webrcon.git integrations/rcon-tools/webrcon
```

## 5) Riscos i mitigacions
- **Risc**: plugins incompatibles entre Carbon i Oxide.  
  **Mitigacio**: definir una llista de plugins critica i validar en staging abans de decidir framework final.
- **Risc**: repos de plugins abandonats.  
  **Mitigacio**: exigir activitat recent (commits/issues) o fork propi mantingut.
- **Risc**: canvis de protocol Rust trenquen plugins.  
  **Mitigacio**: pipeline de regressio minim post-update (smoke tests + test funcional de captura).
- **Risc**: dependencia de marketplace tancat.  
  **Mitigacio**: prioritzar plugins amb codi font i llicencia clara; evitar lock-in.

## 6) Criteri de validacio (com provar que funciona)
1. Clonar repos sense errors amb `scripts/clone_repos.ps1`.
2. Arrencar servidor Rust dedicat en entorn net.
3. Instal.lar framework principal (Carbon) i carregar un plugin de prova.
4. Verificar connexio RCON i execucio d'una comanda remota.
5. Executar prova de compatibilitat basica d'un plugin equivalent sobre Oxide (fallback).

## 7) Fitxers creats
- `REPOS_STACK_BASE.md`
- `scripts/clone_repos.ps1`
