# Old World Reference Changelog

## 2026-04-08 Update (Update #145, v1.0.83082)

233 files changed across Reference/Source, Reference/XML, and decompiled (+15,877 / -13,574 lines). Unit and tech tree rebalances, legitimacy conversion rework, rendering optimizations, AI improvements, and 50+ bug fixes.

Official patch notes: https://mohawkgames.com/2026/04/08/old-world-update-145/

### Gameplay

- **Legitimacy conversion now has scaling cost** — new globals `CONVERT_LEGITIMACY_FLAT_COST` (2) and `CONVERT_LEGITIMACY_PER_100_COST` (100) define a base cost plus escalating cost per prior conversion. `miLegitimacyConvertCount` on Character tracks uses. Previously only required >0 legitimacy and no prior conversion that turn
- **Trade value modifier capped** — new `MAX_TRADE_MODIFIER` global (90) caps trade income modifiers in both directions. `calculateModifiedTradeValue()` refactored: `getTradeValueModifier()` extracted as separate method, rounding mode changed
- **Crossbowman strength reduced** from 80 to 60; **Polybolos strength reduced** from 100 to 80
- **Slinger** now also obsoleted by Bodkin Arrow (previously only by Windlass)
- **Mill split into Watermill + Windmill** — old `IMPROVEMENTCLASS_MILL` becomes `IMPROVEMENTCLASS_WATERMILL` (prereq: Hydraulics). New `IMPROVEMENTCLASS_WINDMILL` (prereq: Windlass) with adjacency bonuses from Mine, Quarry, Lumbermill (+100% each). Windlass now requires Coinage instead of Manor
- **Specialist civics costs lowered** — Rancher, Trapper, Gardener, Fisher reduced from 60 to 40
- **New specialist prerequisite system** — `meEffectCityPrereq` field allows specialists to require a specific EffectCity to be active in the city
- **Besieger/Highlander/Engineer promotions** switched from whitelist (Melee+Ranged only) to blacklist (invalid for Mounted+Ship). Net effect: applicable to more unit types
- **Water units cannot get road-building** — `effectUnitInfo.mbBuildRoad` now invalid for water units
- **Judaism no longer requires Labor Force** tech to found
- **Hinduism** now has a description tooltip
- **Gatherer/Resourceful cognomens** (EOTI) threshold reduced from 400 to 300 harvested resources
- **EFFECTCITY_MONARCHICAL_OWNERSHIP** (EOTI) rebalanced — Food penalty doubled (-40 → -80), Money bonus 10x'd (200 → 2000)
- **Religion memory rebalanced** — MEMORYRELIGION_APPEASED_LOCAL_LEADERS changed from medium-duration medium-positive to short-duration high-positive
- **Random city site number option removed** — `MAP_OPTION_CITY_SITE_NUMBER_RANDOM` removed from map options and "All Random" preset. Game of the Week no longer varies city site numbers

#### Tech Tree — Bonus Unit/Courtier Rework

Free unit and courtier techs shuffled and costs normalized to 300 (from 400–1000):

- Free Court Soldier: Infantry Square → **Stirrups**
- Free Longbowman: Manor → **Battle Line**
- Free Horse Archer: Land Consolidation → **Composite Bow**
- Free Court Merchant: Chain Drive → **Cartography**
- Free Court Merchant: Fiscal Policy → **Manor**
- Bodkin Arrow (main tech): prereq changed from Manor to **Coinage**

#### Childbirth Rework

- `canHaveChildren()` now accepts optional `pSpouse` parameter with twin support: if last child was born this turn AND the spouse is the father, birth is not blocked. Otherwise blocks if child born this turn or under age 1
- Before auto-marrying, game checks if the character is already the target of a marriage mission (new `MARRIAGE_MISSIONCLASS` global)

### Events

- **8 new Kush religion events** — Dedication and Displeasure events for Amani, Apedemek, Mandulis, and Sebiumeker. Triggered by EVENTTRIGGER_RELIGION_SPREAD, repeat every 40 turns, Kush-specific
- **EVENTSTORY_PLAYER_TRIBE_WAR** — now respects `bNoEventsValid` (won't fire if character has NoEvents)
- **Trait occurrence timing fix** — `doOccurrenceTrait()` now called before extra XP processing instead of after, fixing traits intermittently not working
- **Subject reign range fix** — special reign behavior now only applies when `miMinReign == miMaxReign` (exact reign match), not whenever both are non-zero
- **Religion subject check** — `mbUnlockedReligion` now uses new `isUnlockedReligion()` method instead of `canAdoptReligion(bTestCost: false)`, separating availability from affordability
- **Tournament announcement removed** (Community Tournament 2025 H2)

#### EOTI DLC Events (Extensive Rebalancing)

- New **EVENTLINK_TRADE_VENTURE** event link (20-turn time limit)
- Shipwrecked Sailor: now gives TRAIT_EXPLORING (was TRAIT_TRADE_VENTURE), option 1 gives TRAIT_NATURALIST instead of TRAIT_EXPLORING. Weight 4 → 6
- First Voyage: uses EVENTLINK_TRADE_VENTURE prereq instead of SUBJECT_PLAYER_MIN_DISTANT. Weight 3 → 10. Adds BONUS_CONTACT_S0
- Exploring Lost: uses SUBJECT_EXPLORING (was SUBJECT_TRADE_VENTURE). Weight 2 → 5
- Multiple events had weight increases (Study 1→10, Influence 1→10, New Perspectives 2→6, Cultural influence 6→8, etc.)
- Several events had `bSinglePlayer` restrictions removed (allowing multiplayer)
- Several events had event class assignments removed in favor of direct triggers

### AI

- **New city evaluation parameters** — `AI_CITY_REGROWTH_VALUE` (100), `AI_CITY_TRADE_VALUE` (100), `AI_CITY_AUTOBUILD_VALUE` (0) for effect city evaluation
- **Culture advancement priority** — AI now gives +100% modifier to culture advancement if no city has yet reached the next culture level
- **Wonder feasibility** — AI reduces wonder improvement value by 10x if it can't actually start building it
- **Adjacent improvement team check** — yield calculation now checks team membership instead of player ownership, fixing valuation in team games
- **Legitimacy value split** — `getLegitimacyValue()` gains `bIncludeYields` parameter to avoid double-counting yields in effect city evaluation
- **Tribe unit role selection rewritten** — `pickRoleMoveTile()` now cycles through roles systematically (PILLAGE → ATTACK_UNIT → ATTACK_TARGET) with new `canHaveTribeRole()` method, replacing fixed if-else chain
- **Ranged unit in-place attack** — when a unit has a target but no move tile, it now checks if it can attack from its current position
- **Transport retreat priority** — transport units now get retreat value calculations
- **AI religion improvement check** — city founding no longer auto-places religion improvements, using new `isReligionImprovement()` method

### Bug Fixes

- **ZOC visibility fix** — Zone of Control now properly checks `isVisible()` on adjacent tiles before considering enemy units. Previously could "see" units through fog of war for ZOC purposes
- **Settlement defense logic fix** — changed `hasImprovementTribeSite()` to `isSettlement()` and inverted defender check logic (was allowing defense when it shouldn't and vice versa)
- **Pathfinding direct-path optimization** — shortcut now works with multi-segment paths, iterating through all end-tile segments independently
- **Unit selection cleanup on death** — tile highlights now dirtied when any unit dies with a different unit selected, fixing stale attack range highlights
- **Occurrence per-player tracking** — tile changes now include `PlayerType` in key tuple, fixing effects for different players colliding
- **Tile title display** — vegetation, city site, and clear-for-attack labels now accumulate with slashes instead of if/else-if showing only one
- **Family first city naming** — naming logic moved before city name assignment, so `meFirstCityName` is used directly during initial naming instead of overwriting afterward
- **Input processing timing** — hotkey/cheat key processing deferred to next update frame via `mbInputThisFrame` flag, preventing execution during inconsistent state
- **Map overlay state management** — `meLastActiveOverlay` saved at overlay entry point; `clearTemporaryOverlay()` removed in favor of `setTemporaryOverlayToggle(NONE, false)`
- **Road building overlay** — properly tracks tiles via `clientRoadIDs`, toggling off when re-selected instead of flickering
- **Improvement tooltip null safety** — all `pTile`-dependent sections wrapped in null checks for tileless contexts (e.g., improvement pings)
- **Unit replaced ID persistence** — new `miReplacedUnitID` tracks unit lineage across upgrades; serialized in save/load and network sync
- **Player turn start visibility** — unit visibility now dirtied on renderer when `mbProcessingTurnStart` changes, fixing units appearing/disappearing during transitions
- **Connected human starts fix** — start placement now also rejects tiles with `iLandArea == -1`
- **MakeUrban validation** — refactored into `CanMakeUrban()` + `MakeUrban()`, returning false gracefully instead of asserting. Checks terrain/vegetation locks before placing
- **Mountain visibility leak** — mountain asset variations now only apply when at least one tile in cluster is visible, preventing hidden mountain shape reveals
- **Fog of war rendering** — destination meshes start inactive, activated only during rendering; removed animated-tile-queue cleanup that dropped frames; instant movement sets percentage directly
- **StoryPreview null reference** — now checks `meRelationUs != NONE` before accessing `mbPlayerLuxury`
- **TechTreePanel search** — filters out `mbReturn` techs, strips hyperlink formatting from names, empty search shows all results
- **Unit upgrade visual doubling** — new `unitTempHidden` set prevents rendering both old and new unit during transitions via `ReplacedUnitID`
- **Particle renderer filtering** — `GetRenderers()` excludes `ParticleSystemRenderer` to prevent particle effects from being affected by material operations
- **Calamities occurrences now gated** — OCCURRENCE_EVAPORATE, OCCURRENCE_DESOLATION, OCCURRENCE_REMOVE_MOUNTAINS, and OCCURRENCE_REJUVENATE all require `CALAMITIES` content. OCCURRENCE_REJUVENATE now only targets bare terrain (new TERRAIN_TARGET_ARID_BARE and TERRAIN_TARGET_TEMPERATE_BARE)

### UI

- **Manual Bonus Placement player option** — new `PLAYEROPTION_MANUAL_BONUS_PLACEMENT` skips recommendation popup and goes straight to tile selection
- **"Disable Idle Animations" option** — replaces the old quality-preset `animationLODEnabled`. New standalone toggle on `GraphicsOptionsSave`. Paused animations freeze at frame 0.5 (midpoint) for better appearance. `MinDetailObject` component removed, replaced by `"MinimumDetailOnly"` GPU culling layer
- **Healthbar healing preview** — damage preview shows green when `damagePreview < 0` (healing) instead of generic darkened color
- **Attack range highlight** — hovering a tile with a selected unit now shows actual attack splash/AOE tiles instead of a simple range circle
- **Timeline tribe territory** — timeline and minimap now show tribe territory in addition to player territory. New `mapOwnerTribeHistory` on Tile
- **Fog of war toggle API** — new `isShowMapFogOfWar`/`setShowMapFogOfWar`/`toggleShowMapFogOfWar` methods for programmatic fog of war control
- **Occurrence tooltips expanded** — now show current duration, minimum duration, and escalating end chance (base + increment per turn)
- **Tech culture prerequisite display** — tech tooltips now show `meCultureValid` requirement
- **Culture unlocks tech display** — culture level help text now lists which techs become available at that level
- **Tribe tile "Not City Site" indicator** — tiles with tribe improvements that aren't city sites show a note with map option link
- **Character trait exclusions display** — trait tooltips now show `mabUnitTraitInvalid` (excluded unit traits) alongside included ones
- **Cooldown text specificity** — recruit/hire/gift tooltips now specify which unit the cooldown applies to
- **Map option help links** — new `HELP_MAP_OPTION` link type for clickable map option references
- **Improvement ping tooltips** — new `IMPROVEMENT_PING` item type with own tooltip handling
- **Decision description divider** — decisions now have a visual divider before the description
- **Overlay customizer button images** — map overlay customizer buttons now get their icons set
- **Order movement below yield preview** — movement orders now display below yield preview
- **Game Editor rework** — changed from fixed-height panel to dynamic-height using PreferredSize, grid items to HGroup layout, scrollable panel with AutoHideAndExpand
- **Barbarian widget** — added stencil image layer, changed materials, added SortOrder=1
- **'Exploring' trait renamed to 'Travelling Afar'** — TRAIT_EXPLORING and TRAIT_TRAVELLING_AFAR consolidated (Exploring ID kept, Travelling Afar display name)
- **Mirror Map option disabled** on Desolation and Ebbing Sea map scripts
- **DLC title capitalization standardized** — lowercase articles in "Heroes of the Aegean", "The Sacred and the Profane", etc.
- **Caravan helptext** — now explains how to get caravans
- **Critical Hits helptext** — clarifies damage to units only, cities immune, explains pending critical hits option
- **Flanking helptext** — added: "The attacker does not receive any counterattack damage when performing a Flanking attack."
- **Culture event text** — changed "Culture Level in City" to "Culture Level achieved in City"
- **Gender-neutral memory text** — "fleeing wife" → "fleeing spouse"
- **World Religion concept** — edited to include Buddhism
- **Vassalize Tribe mission** — added description

### Multiplayer

- **"Rehost" feature restored** (reworked) — `IsMatchUnlisted` property and `RestartServer()` re-added to `IApplication` after removal in v1.0.82832. Menu option appears when match is unlisted. `REHOST` ItemType enum re-added
- **Network match staleness** — new time-based system: `networkGameStaleSeconds` (3600s), `networkGameUpdateSeconds` (30s). Server info updated if older than 30s or if match data changed. `ServerStruct` gains `lastDate` field
- **Match verification cleanup** — removed `restart` parameter from `UpdateMatchServer()` and the old `RestartServer()` fallback

### Rendering

- **Aqueduct rendering overhaul** — tracks construction progress, lightweight height-dirty system replaces full `ForceUpdateAll`, spline replacement via `SetSplineAtIndex()`, deterministic path comparison via sorted children
- **Border renderer optimization** — caches `mouseoverCityID` and `highlightedBorderGroup`, early-returns when unchanged
- **Terrain quality consolidation** — new `TerrainRenderer.SetQuality()` method with `"MinimumDetailOnly"` culling layer replaces per-object `MinDetailObject` toggling
- **Mountain tile effect** — restricted to specific tile instead of any matching-height visible tile
- **Minimap layer consolidation** — `MinimapResources`, `MinimapIcons`, `MinimapBorders`, `TimelineFogOfWar`, `TimelineBorders` replaced by `"MinimapOnly"` and `"TimelineOnly"`
- **Graphics options refactor** — `OnApplyOptions` callback now receives `GraphicsOptionsSave` instead of `GraphicsSettings`. `animationLODEnabled` removed from quality presets, replaced by `disableIdleAnimations` user toggle. `uiHealthbarScale` removed
- **Loading graphics** — `ApplyOptions()` now called after loading completes, ensuring settings applied immediately
- **Waypoint text** — canvas explicitly sets `sortingLayerName = "Default"` for correct rendering order

### Map Scripts

- **TileData encapsulation** — all fields converted from `public` to properties with `protected internal` backing (e.g., `meTerrain` → `Terrain`, `mbBoundary` → `Boundary`). Purely mechanical change affecting all ~20 map scripts

### Other

- **SystemCore IO** — new serialization for `DictionaryList<(T, U, V), string>` (triple-key dictionaries) for per-player occurrence tracking
- **Spline node position setter** — new `SetNodePosition(int, Vector3)` for post-creation modification
- **ScrollablePanel refactored** — now extends `UIScrollable` base class with `ResizeRect()` override and `ContentRectObserver`

## 2026-04-03 Hotfix (v1.0.82975)

1 file changed across Reference/Source, Reference/XML, and decompiled (HelpText only). Trade tooltip fix and Russian localization styling.

### Bug Fixes

- **Trade yield tooltips now show modified values** — `HelpText.cs` trade breakdown now calls `calculateModifiedTradeValue()` instead of displaying raw `miValue`, so tooltips correctly reflect diplomatic modifiers for both "trade to player" and "trade from player" lines

### UI / Localization

- **Title style moved to text system** — `buildTitleScope` changed from hardcoded `QUICKTEXTVAR("<style=H1>{LIST}</style>")` to `TEXTVAR_TYPE("TEXT_HELPTEXT_TITLE")`, allowing per-locale title styling
- **Russian heading styles** — `TEXT_HELPTEXT_TITLE` and `TEXT_HELPTEXT_SUBTITLE` now use `H1_RU` / `H2_RU` styles for Russian locale (fixes Cyrillic text sizing in tooltips)

## 2026-03-25 Hotfix (v1.0.82832)

18 files changed across Reference/Source, Reference/XML, and decompiled (bulk is decompiler variable renaming). Multiplayer networking fix.

### Multiplayer

- **Removed "Rehost" feature entirely** — `IsMatchUnlisted` property, `RestartServer()` method, `ItemType.REHOST` enum value, pause menu "Rehost" option, and tooltip text all removed from `IApplication`, `ClientUI`, `AppMain`, `DefaultApplication`, `NullApplication`, `HelpText.Widget`, and `Enums.cs`
- **Relay server connection reworked** — `NetTransportClient.PlayerRelayData()` and `NetTransportServer.HostRelayData()` now use Unity's `allocation.ToRelayServerData(RelayProtocol.UDP)` instead of manually constructing `RelayServerData` from endpoints, allocation IDs, connection data, and HMAC keys. Removed `connectionType` parameter (was defaulting to `"dtls"`, now hardcoded to UDP)
- **Match verification interval increased** from 2 seconds to 45 seconds (`matchCheckIntervalSeconds`), reducing server polling load
- **Smarter match verification** — host match check now skips verification when all players are connected (`AreAllPlayersConnected()`), and auto-refreshes join code when no clients are connected before allocation expires
- **Removed `databaseUpdateTimer`** — previously triggered `UpdateMatchServer` calls every 30 seconds; database updates now only happen on match recreation or join code changes
- **Removed `driver.ScheduleUpdate()` call** during client connection loop — was in the connecting wait loop, now just yields
- **`RestartServer()` simplified** — now calls `OnLocalServerListed(null)` directly instead of going through the removed `RecreateMatch()` method
- **`OnLocalServerListed` restructured** — consolidated `RecreateMatch()` logic inline; removed `IsMatchUnlisted` state tracking (matches are now either valid or recreated, no "unlisted" intermediate state)

### Map Generation

- **Lake-next-to-ocean fix now runs unconditionally** — `DefaultMapScript.cs` previously only ran the lake adjacency fix for centerpoint-symmetric maps (`if (CenterpointSymmetricMap)`); now runs for all map types. Comment: "no lakes next to ocean - possible with locked terrain or point symmetry"

### UI

- **Removed `FONT_LIBERATION_GLOW` font entry** from `font.xml` (LiberationSans with TraitFX material)
- **`ChooseLawsPopup` ItemType index shifted** — `134` → `133` due to REHOST enum removal

## 2026-03-18 Update (Update #144)

321 files changed (+109,146 / -67,097 lines) across Source, XML, and decompiled. Bulk of additions are pre-loaded Empires of the Indus DLC content (gated behind `EMPIRES_OF_THE_INDUS` content check, DLC not yet released).

Official patch notes: https://mohawkgames.com/2026/03/18/old-world-update-144/

### Gameplay

- **Flanking now prevents counterattack damage** — `canCounterattack()` gains `pToUnit` parameter; checks `pToTile.flankingAttack(pToUnit, pFromTile)` and returns false if attacker is flanking. AI sets counter damage to 0 for flanking attacks. New `Tile.hasMeleeCounter()` method. Combat tooltip shows "Flanking" text when active
- **Void tech prerequisite system** — new `EffectCityType.maeVoidTechPrereqImprovementClass` allows city effects to bypass tech prerequisites for improvement classes. `City.mdVoidTechPrereqUnlocks` dictionary tracks unlocked classes. `Player.isImprovementUnlocked()` gains optional `City` parameter. Help text shows "requires Tech OR [effect source]" using OR-lists. AI values void tech prereqs proportional to skipped tech's science cost
  - Clerics family seat now uses this: `aeVoidTechPrereqImprovementClass` for Monastery (replaces removed `BONUS_FAMILYCLASS_CLERICS_SEAT` free Divine Rule law)
- **Enlightenment Cathedrals** give growth per population, not per citizen (yield moved from `EFFECTCITY_ADVANTAGE_PENALTY_LOW` to `EFFECTCITY_ADVANTAGE_PENALTY_HIGH`)
- **Redemption theology buffed** — harbor and hamlet improvement class modifiers increased from 20% to 50%. Redemption Cathedrals now allow hurrying specialists and projects with training (`aeHurryTraining`)
- **Zealot leaders** can now only rush units with training — `aeHurryTraining` limited to `BUILD_UNIT` only (was `bHurryTraining=1` for all)
- **Monasteries** can be built in Clerics family cities without Monasticism tech (via void tech prereq)
- **Clerics no longer start with Divine Rule** — `SeatFoundBonus` (`BONUS_FAMILYCLASS_CLERICS_SEAT`) removed from family class
- **Baths** can no longer be built on sand (except for Clerics) — `bFreshWaterValid` removed from improvements, replaced with `TerrainValid: TERRAIN_TARGET_HABITABLE_FRESH` via new `InfoTerrainTarget.mbFreshWaterAccess` field
- **Events that spread a religion** now contribute to religion spread goals — `City.spreadReligion()` tracks `pSpreadPlayer` for goal/stat attribution
- **Law upkeep swaps**: Legal Code now costs 6 Money/city (was 0.2 Orders); Divine Rule now costs 0.5 Science/city (was 6 Money); Guilds now costs 0.5 Orders/city (was 10 Money)
  - Underlying: `EFFECTPLAYER_UPKEEP_MEDIUM_ORDERS` reduced -5→-3; `EFFECTPLAYER_UPKEEP_HIGH_ORDERS` reduced -10→-5; new `EFFECTPLAYER_UPKEEP_MEDIUM_SCIENCE` at -5
- **Besieger effect** now valid for Melee and Ranged (was Melee and Siege) — `EFFECTUNIT_DISARM` target changed from `UNITTRAIT_SIEGE` to `UNITTRAIT_RANGED`
- **Growth scaling delayed** — increased Growth required for new population now occurs after 30 growths instead of 20
- **Family opinion yield formula changed** — `getFamilyOpinion() + 1` → `getFamilyOpinion()` (removes +1 offset), now starts from 0 at Furious to 5 at Friendly
- **Disciples generate 1 Culture per turn** on their respective Holy Sites (all 4 existing religions: Zoroastrianism, Judaism, Christianity, Manichaeism)
- **Rebels in Hunters cities** no longer affect family opinion — `InfoTribe.mbNoAttackDiscontent` now checked
- **Clergy traits minimum age** raised to 18 — all pagan clergy traits added `iMinAge: 18`; existing religion clergy raised from 14 to 18
- **Pagan religions can now have theologies** — new `InfoReligion.mbForceTheologies` boolean; `Game.canEstablishTheology()` allows theologies for pagan religions if flag set
- **Rebel and Anarchy units** no longer receive tribe-level fatigue bonus — new `InfoTribe.mbNoFatigueBonus` flag
- **Initial tribe diplomacy** now starts at `TRUCE_DIPLOMACY` (was `DiplomacyType.NONE`)
- **Road pathfinding** refactored — `Tile.canHaveRoad()` now uses revealed data (fog-of-war aware); new `Tile.canAddRoad(TeamType, bool, TeamType)` consolidates ownership/territory checks; pathfinder won't route through rival nation territory
- **Adjacent improvement cost modifier** now only counts improvements belonging to the same team
- **Push-through attack fix** — can no longer push through a tile containing a non-vulnerable city
- **Character creation defaults** — `createPresetCharacter()` now reads family, tribe, nation from character XML when NONE passed
- **Bonus character assignment** — characters made into councilors/governors/generals/explorers via bonus now have `setPlayer()` called before assignment

### New Content

#### Events
- Grief
- Last of the Pack
- Founded (lost tie) ×4 — religion founded tie events made non-internal
- The Wanderers
- Tribal Truce Offer (no war due to alliance)
- "A Talent for Geometry" study event gains a 3rd option

#### Event Changes
- Multiple events removed `SUBJECT_CITY_GARRISON` requirement (~6 events loosened)
- "Date Night" — removed "No" options for both male and female variants
- "Happiness: Valuable Experience" rebalanced — Astute option now gives Cunning trait + Discipline; Wisdom option now gives Educated trait
- Tribe Eliminated cognomen event weight reduced 8→3
- Several events had weights increased from 1 to 4–6
- Tower of Silence event expanded to include Hinduism (via SubjectAny)
- Duplicated `SUBJECT_PLAYER_THEM` replaced with `SUBJECT_PLAYER_PEACE_OR_TRUCE` (bug fix)

#### Player Options
- **Disable Turn Start Cycling** (`NO_TURN_START_CYCLE`) — new
- **Disable Automatic Cycling** (`DISABLE_ALL_CYCLING`) — new
- Unit Cycling and Fatigue Cycling moved to end of options list

#### Stats
- `WORKER_TURNS_STAT` — tracks worker turns spent building improvements

### UI / Client

- **Tech tree search** — new `TechTreeSearchFilterType` enum with categories (Tech, Unit, Council, Improvement, Law, Theology, Project, Mission, Bonus); text search with category filters, max 20 results, clickable results center tree on tech. New widget types `TECH_TREE_SEARCH`, `TECH_TREE_SEARCH_FILTER`, `TECH_TREE_SEARCH_RESULT`
- **Unit cycling options** — `Player.isTurnStartCycling()` and `Player.isUnitCycling()` convenience methods; `ClientSelection.startCycle()` respects new options; `cycleFromUnit()` called after attack to auto-advance; hotseat calls `clearCycles()` before `startCycle()` on player switch
- **Water control visualization** — per-tile alpha values: owned tiles at alpha 127, preview at 63; water control preview now team-aware via `isWaterControlPreview(Tile, TeamType)`; ship anchoring color changed from white to more transparent
- **Worker filters** now show improvements not currently valid due to culture level restrictions; `bTestTerritory` changed to `(eFilter == WorkerActionFilter.GENERAL)`; `canHaveImprovement` passes `bTestEnabled: eFilter == WorkerActionFilter.GENERAL`
- **Dynasty entries** in Encyclopedia labeled with dynasty name instead of first ruler name
- **Records screen** displays Improvements Controlled and Improvements Finished stats separately; Worker Turns stat added; Disciples no longer counted in Workers Produced
- **Improvement tooltip** now receives building `Unit` and shows cooldown warning when relevant
- **Improvement theology potential bonuses** added to help text — new `maaiTheologyYieldOutput` display on improvement classes
- **Damage preview fixes** — non-hostile and hidden unit damage now included in mouseover text; `isAffectedByMouseover()` always uses `bCheckHostile: false`; health bar shows damage only from hostile units with visibility; damage text no longer shows on units other than top defender
- **City counterattack** now shown in attack preview
- **Critical hit and Culture Level** concept text improvements
- **Hurry tooltip** shows explanation text when invalid specialist cannot be hurried
- **Specialist build warning** — HelpText now warns when current specialist being built is no longer valid
- **Tile widget refactoring** — inline display logic extracted into virtual methods (`isShowTileYieldPreview`, `isShowTileRecommendations`, `isShowTileResource`, etc.) enabling subclass customization; yields overlay checks team ownership instead of player ownership
- **Unit widget fixes** — promotion chevron material changed to `UIWorldOutlineUnitWidget`; damage preview text moved outside healthbar hierarchy; sort order changed (-5→8)
- **Minimap** — removed camera snapback when clicking minimap on city screen
- **Network games** — more frequent updates in browser; non-host observers can send chat messages; new `ItemType.REHOST` for rehosting unlisted matches; chat distinguishes observer vs host labels
- **DLC content filtering** — map editor, game editor, portrait editor, event browser, tooltips, encyclopedias all filter by `isContentEnabled(GameContentType)`; new centralized `HelpText.isContentEnabled()` and `isSourceContentEnabled()` utility methods
- **Relationships tab** reordered — families shown first, then religions; religions also show if player `hasReligion()`
- **Encyclopedia updates** — "Tutorial: Grand Vizier" added; "Councilors" section on DLC Summary pages; Council concept merged with Councilor; removed unhelpful Clergy links; updated Caravan Mission concept text
- **Colorblind filter** — fixed menu transparent backgrounds rendering as blank; filter added to UI overlay camera
- **Fog of war rendering** — tile updates now deferred via dirty tile lists, processed in batch during `Update()`; new `Tile.hasRevealedHistory(TeamType)` method; timeline start turn changed from 0 to 1
- **Camera optimization** — city mode only recalculates target look-at when dirty (`isCityDirty` flag)
- **Scrollable panels** — scrolling disabled when `UIInputField` is focused (prevents scroll hijacking while typing)
- **Increased Cyrillic sampling** point size for better rendering
- **Family tag grammar pass** and text localization updates

### Bug Fixes

- **Unit widget stacking** — fixed incorrect stacking; back-of-stack icons no longer sorted behind water
- **Kill preview icon** — no longer draws behind city widget
- **Unit cycling option** — fixed reversed logic; fixed cycling after attacking
- **Worker filters** — fixed showing for non-allied units
- **Unit build list** — fixed not showing valid improvements on mouseover tile with Ctrl
- **Occurrence notifications** — fixed showing as started when set as pending via bonus (`mbOccurrenceSetPending` check added in 5 places in PlayerBonus.cs)
- **Raider AI** — removed special case that nulled move tile for raiding units; now uses same candidate filtering as non-raiding. Attack move validation gains `canOccupyTile` check
- **File browser** — fixed game UI registering clicks while file browser is open
- **Custom overlay** — fixed getting cleared by temporary road overlay; road-building auto-overlay only clears when unit can actually build roads
- **Colorblind filter** — fixed transparent backgrounds rendering as blank
- **Female worker tools** — fixed being tinted by team color
- **Wildfire rendering** — fixed pink models in burning cut scrub
- **Main menu color** — fixed looking different on minimum detail settings
- **Premade characters** — fixed Family, Tribe, and Nation sometimes not being assigned; `createCharacterSafe()` now falls back to XML-defined values
- **Archetype assignment** — fixed bug
- **Link colors** — fixed colors getting applied to links that no longer exist
- **Simultaneous events** — fixed characters both leaving nation and becoming governor/general
- **Event Browser** — fixed loading of dependent mods
- **Unit damage text** — fixed sometimes being incorrectly updated
- **Mac hotkeys** — fixed Cmd key interaction when assigning hotkeys; Windows key presses now skipped in key tracking
- **Remove Dissent projects** — fixed being able to be queued multiple times
- **Suppress Dissent projects** — fixed only being completable once per city
- **Marsh tiles** — fixed being replaced by Urban during map generation (fresh water sources can no longer be made urban)
- **Egypt improvement costs** — fixed cost discounts for adjacent improvements of different team
- **Rebel/Anarchy fatigue** — fixed receiving tribe-level fatigue bonus
- **Bonus improvement placement** — fixed sometimes being placed on bad tile
- **Map script preservation** — fixed not being preserved when using Reroll Game with random map script; restart now resolves random map class to actual before restarting
- **MP setup** — fixed Player 1 name and player archetypes not being saved
- **Alliance text** — fixed help text typo about alliance with Ruthless AI; fixed "Blackmailed by" relationship text
- **Player info panels** — fixed not getting hidden when selecting unmet nation
- **City production list** — fixed icons sometimes not showing
- **Governor tooltip** — fixed flickering on city list screen (tooltip location moved to parent container)
- **Family/religion order** — fixed tab tooltip ordering
- **Tribe units** — fixed sometimes not moving when they wanted to move
- **Anchor ranges** — fixed sometimes not showing
- **Selection clearing** — fixed not clearing when closing event popups; decision popup tracks `decisionID` and clears on dismiss
- **Point Symmetry maps** — fixed city sites and resources not always being symmetric near center; `AddMiddleMapCities()` now supports `CenterpointSymmetricMap`
- **Fog of war units** — fixed visual issue where units exiting fog and attacking immediately during AI turn disappear after attacking
- **Yield previews** — fixed sticking when cycling units
- **Unit crit chance** — fixed not updating properly on attack preview
- **Alliance notifications** — fixed doubled notifications for starting/ending tribal alliances (now excludes player who gained/lost alliance)
- **One Continent per Team** — fixed map option with multiple players per team
- **Tile ownership reveal** — fixed not being revealed to agent player when new tiles added; agent characters now trigger tile reveal when territory changes
- **Terrain normals** — fixed some terrain tiles not rendering correctly
- **Allied vision fog** — fixed flickering from allied vision
- **Pharaohs timeline** — fixed rendering on first turn in scenarios
- **Mod loading** — fixed strict mode on startup when loading external mods; mod path now propagates strict mode setting
- **Play to Win opinion** — fixed operator precedence bug: added parentheses around `(calculatePlayerOpinionPlayToWin(...) ?? 0) - iValue`

### Map Script System

- **Tile locking refactored** — old `LockTileTerrain(tile, terrain, height)` split into three separate systems: `LockTileTerrain()`, `LockTileHeight()`, `LockTileVegetation()`, each with `force` parameter and boolean return value. `IsTerrainLockedAny()` checks all three; `UnlockTileTerrain()` clears all. All 17+ map scripts updated to use new API
- **Max teams per map** — new `InfoMapClass.miMaxTeams` field; `GetMaxTeams()` static method on map scripts; `GetRandomMapClass()` gains `iNumTeams` parameter
- **Map content filtering** — ownership check moved from registration-time in `Infos.cs` to display-time in `InfoHelpers.GetAvailableMapsScripts()`
- **Start placement** — players on different land areas get heavily penalized in distance scoring (prevents cross-water starts appearing close)
- **Resource placement** — min-distance check uses `getTilesInRange` instead of iterating all placed resources; `placedResources.Clear()` at start of `AddResources()`
- **Boundary handling** — removed "remove unreachable areas" step that marked non-main-area tiles as boundary; small boundary islands still cleaned up
- **Coast generation** — lakes adjacent to salt water now promoted to coast height
- **Urban tile validation** — fresh water sources can no longer be made urban
- **MapScriptDisjunction** — fields changed from private to `protected` for subclass access
- **MapScriptTumblingMountain** — major refactor: channel mountains now created during `GenerateLand()` instead of post-build; overrides `SetUnreachableAreas()`, `BuildContinents()`, `GetRiverSources()`, `IsPotentialRiverDelta()`, `AddMountainRangeNames()`
- 4 new map scripts (untracked files, DLC-related): `MapScriptDota`, `MapscriptJungle`, `MapscriptMountainPass`, `MapscriptWetlands`

### Fresh Water System Refactored

- `InfoImprovement.mbFreshWaterValid` **removed** — fresh water access moved to `InfoTerrainTarget.mbFreshWaterAccess`
- `TileData.isFreshWaterAccess()` new overload for map generation context (not just live `Tile`)
- `TileData.isTerrainTarget()` now takes optional `adjacent` function for fresh water and adjacent terrain checks
- `TileData.isRiver()` refactored with `Func<DirectionType, TileData>` overload for context-free river detection

### Vegetation Removal Refactored

- `canRemoveVegetation()` gains `bTestOrders` parameter — when false, skips `canAct()` orders check (used during improvement placement validation)
- New Jungle vegetation type added (DLC): movement cost 18, +75% ranged defense, requires Land Consolidation tech to remove

### Egypt Campaign Scenarios

- All 6 Egypt scenarios refactored — victory/defeat achievement logic extracted into reusable `DoMinorVictory()`, `DoMajorVictory()`, `DoMinorDefeat()`, `DoMajorDefeat()` methods. Major victories now properly chain through minor victory achievements
- Egypt Scenarios 2 and 3: `LAW_DIVINE_RULE` added as active starting law (compensates for Clerics losing free Divine Rule on founding)
- Pharaohs scenarios: major defeat/victory now also awards minor defeat/victory achievements

### Scenario Text Consolidation

- `text-egypt-change.xml` **deleted** — content moved into `text-egypt-other.xml` with proper localization
- `text-greece4-change.xml` **deleted** — content merged into `text-greece4-misc.xml`
- `text-learnToPlay1-change.xml` **deleted** — content merged into `text-learnToPlay1.xml`
- Carthage campaign: multiple `{FAMILY-1}` references fixed to use proper grammatical gender variants

### Empires of the Indus DLC (Pre-loaded, Not Yet Released)

Content is shipped in game files but gated behind `GameContentType.EMPIRES_OF_THE_INDUS` (Steam AppID 4129630). Game of the Week has a 28-day preview window starting April 1, 2026 that enables the DLC content with rotating nations and new map scripts. Pre-loaded content includes:

- **3 new nations**: Maurya (Indian, Hindu), Tamil/Tamilakam (Indian, coalition mechanic), Yuezhi (nomadic, tribal)
- **2 new religions**: Hinduism (pagan, hidden/no natural spread, forced theologies), Buddhism (requires 4 theologies + Philosophy law, 10% spread)
- **1 new tribe**: Huns (organized, diplomatic, mercenary, Hunnic Cavalry units)
- **1 new vegetation**: Jungle (high movement cost, ranged defense, tech-gated removal)
- **~10 new units**: Assault/Armoured Elephant (Maurya), Steppe Rider/Kushan Cavalry/Warlords (Yuezhi), Javelin/Archer Elephant (Tamil), Hunnic Cavalry, Hinduism/Buddhism Disciples
- **5 new wonders**: Stupa, The Mahavihara, Monumental Buddhas, Hill Fort, Pillar Edict
- **~8 new shrines**: Hindu shrines for Maurya and Yuezhi
- **~5 resources**: Jade, Ebony, Spices, Silk (all given full terrain data, previously abstract placeholders), Wootz Steel (Tamil national ability)
- **~60+ new characters** with full dynasty trees across 15 dynasties
- **~25+ new traits**: dynasty, combat, religious, item traits
- **~30+ new achievements**
- **4 new map scripts**: Dota, Jungle, Mountain Pass, Wetlands (+ 8 new map options)
- **New event classes**: Family Supremacy, Hun Events
- **New missions**: Vassalize Tribe (Yuezhi), Quell Dissent (Hinduism/Buddhism)
- **New occurrences**: Religious Upheaval, Pax Kushana
- **UI frame**: India-themed event popup frame
- Extensive DLC content gating added throughout: map editor, portrait editor, event browser, hints, tutorials, help text, tooltips, encyclopedias all filter by `isContentEnabled()`

### Modder-Breaking Changes

- `InfoImprovement.mbFreshWaterValid` **removed** — use `InfoTerrainTarget.mbFreshWaterAccess` instead
- `Tile.canHaveRoad()` signature changed — now takes `TeamType eVisibilityTeam` parameter
- New `Tile.canAddRoad()` consolidates checks previously in `Player.canAddRoad()`
- `canCounterattack()` gains `Unit pToUnit` parameter
- `canRemoveVegetation()` gains `bTestOrders` parameter
- `Player.isImprovementUnlocked()` gains optional `City` parameter
- `LockTileTerrain()` API split into `LockTileTerrain()`, `LockTileHeight()`, `LockTileVegetation()` (map scripts)
- `BONUS_FAMILYCLASS_CLERICS_SEAT` removed
- `InfoEffectUnit.meGameContentDisplay`, `InfoVegetation.meGameContentDisplay`, `InfoTutorial.meGameContentRequired` — new DLC gating fields
- `InfoProject.meGameOptionPrereq` — new field gating projects on game options
- `EnumExtensions` changed to `partial class`
- Family opinion yield formula: `getFamilyOpinion() + 1` → `getFamilyOpinion()` (affects mods that depend on opinion yield calculations)
- Water control tile sets changed from `HashSet<(int, ColorType)>` to `HashSet<(int, ColorType, int)>` (added alpha)

## 2026-02-26 Hotfix (post-Update #143)

### Bug Fixes

- **Portrait interpolation** — rewrote `PortraitAgeInterpolator.DrawMesh` from immediate-mode GL rendering to `CommandBuffer`-based rendering; added explicit `Vector2`→`Vector3` casts for face mesh vertex interpolation and bounds calculation
- **Terrain display** — added depth buffer (0→16) to all terrain render textures (`tempRenderTextureARGB32`, `heightmapTexture`, `cluttermapTexture`, `minimapTexture`); new `ScheduledRender` queue and camera pool for deferred cell rendering; added `UnityEngine.Rendering.Universal` import
- **Promotion icon occlusion** — unit widget promotion-available icon now includes a nested `WorldButtonOccludeUnitWidget` cutout layer to render correctly against other UI elements
- **Network game timeout** — new `WaitForSecondsAndPredicate` yield class combines timeout + predicate waiting; `GameClientBehaviour.ProcessMessages` replay wait refactored to use it; `Unit.canUpgradeFromToUnit` gains `iTimeout` parameter (cap 100) to prevent infinite recursion on circular upgrade references
- **End Turn button** — fixed interactability in simultaneous MP; now verifies the turn hasn't already been ended (`isTurnEnded()`) and uses `isCurrentPlayerTurn()` instead of direct player comparison
- **Tooltip flicker on game browser** — multiplayer game list tooltip changed from `TooltipLocation.Right` to `TooltipLocation.Mouse`
- **Ping wheel initial position** — removed `SortModifier="100"` from popup; fixed template variable syntax (`PopupPings-@-` → `PopupPings@-`)
- **Specialist icon display** — new `SPRITE_GROUP_SPECIALIST_ICONS` sprite group registered in `Infos.cs`; `CityDetailUI.cs` specialist icon binding fixed with null-coalescing for current/building specialist types

## 2026-02-18 Update (Update #143)

194 files changed (+9,550 / -5,713 lines) across Source and XML.

Official patch notes: https://mohawkgames.com/2026/02/18/old-world-update-143/

### Gameplay

- **Road building decoupled from worker identity** — new `bBuildRoad` effect unit flag allows any unit to build roads; worker units now carry `EFFECTUNIT_ROAD_BUILDER`; `isRoadBuilder()` replaces `isWorker()` checks for road-related logic
- **Nation bonus units unlock by culture level** instead of tech prerequisites; most now grant 2 units instead of 1
  - Tier 1 (`CULTURE_STRONG`, cost 200): Battering Ram, Akkadian Archer, African Elephant, Light Chariot, Palton Cavalry, Hastatus, Hittite Chariot 1, Medjay Archer, DMT Warrior, Hoplite
  - Tier 2 (`CULTURE_LEGENDARY`, cost 600): Siege Tower, Cimmerian Archer, Turreted Elephant, Mounted Lancer, Cataphract Archer, Phalangite, Legionary, Hittite Chariot 2, Beja Archer, Shotelai
  - Implemented via new `CultureValid` field in `tech.xml`; `Player.onCultureGrow()` marks matching techs as passed
- **Engineer promotion redesigned** — `EFFECTUNIT_ENGINEER` lost Siege/Ship modifiers, replaced with `bBuildRoad: 1` (road building ability). `EFFECTUNIT_ENGINEER_ALL` Siege/Ship modifiers reduced from 25% to 10%
- **Fervent trait redesigned** from player-level religion spread bonus (`EFFECTPLAYER_TRAIT_FERVENT` removed) to a general effect unit with self-apply enlist ability (`EFFECTUNIT_TRAIT_FERVENT`); civics cost reduced 400→100
- **Zealot leader redesigned** — `EFFECTUNIT_ZEALOT_LEADER` now has `bHealKill: 1` (heal on kill) instead of Apply Enlist
- **Import resources now support quantities** — `ImportResource` (single) replaced with `aeImportResources` (list with counts); Perfume and Porcelain now grant 2 units
- **Christianity** now requires 3 Judaism cities globally (was 2 owned); `RequiresReligion` tag replaced with threshold-based `aiRequiresReligion`
- **Workers and Disciples** now have `bRemoveVegetation` by default — `UNIT_WORKER` and all 4 religion disciple units (`UNIT_ZOROASTRIANISM_DISCIPLE`, etc.) carry this flag in `unit.xml`
- **Vegetation removal gated on unit capability** — `Tile.canRemoveVegetation()` gains `bTestImprovement` parameter; improvements that require vegetation clearance check whether the unit can actually clear it
- **Birth rate limiting** — characters limited to 1 child per year on fast game speeds (`canHaveChildren` gains `bTestTooSoon` parameter)
- **Trait roll weights** now context-sensitive: non-governor traits penalized when character is a governor, non-general traits penalized when character is a general; controlled by new globals `NO_GOVERNOR_TRAIT_DIE_MULTIPLIER` (25) and `NO_GENERAL_TRAIT_DIE_MULTIPLIER` (25)
- **ZOC display** now ignores rivers — renderer passes `bIgnoreRiver: true` to `Tile.isHostileZOC()`
- **Porcelain tech** cost reduced 600→200, prereq changed from Lateen Sail to Coinage
- **Silk and Ebony techs** disabled by default (`bDisable: 1` in `tech.xml`)
- **Free laws** replacing existing laws no longer increment change count — `makeActiveLaw` gains conditional `bIncrementChange` parameter (only increments if no law exists in that class)
- **Autonomous Rule** project removed when city breached via `CITY_BREACHED_EVENTTRIGGER`
- **Raiders** can now capture empty cities and sites
- **Killed Workers/Disciples** generate family/religion memories — `MEMORYLEVEL_NEG_MEDIUM_SHORT` = -40 opinion for 20 turns
- **Fresh water sources** supply adjacent and own tiles via `bFreshWaterSource` flag in `improvement.xml`
- **Carthage founding bonus** reduced from 200 to 100 civics

### New Content

#### Goals / Ambitions (~30+ new)
- Religion monastery goals: 6 monasteries per religion (Zoroastrianism, Judaism, Christianity, Manichaeism)
- Religion temple goals: 6 temples per religion
- Religion cathedral goals: 3 cathedrals per religion
- Holy site goals: 1 per religion
- Military: `GOAL_SIX_MOATS`, `GOAL_SIX_TOWERS`
- Repair: `GOAL_FOUR_REPAIRED`, `GOAL_EIGHT_REPAIRED`
- Foreign cities: `GOAL_TWO/THREE/FOUR_CITIES_FOREIGN`
- Combat: `GOAL_CLEAR_THREE_BARBS`, `GOAL_KILL_10_ENEMIES`, `GOAL_KILL_5_BARBS`
- `GOAL_LEGENDARY_IMPROVEMENTS_ALL`

#### Events & Triggers
- `EVENTTRIGGER_IMPROVEMENT_REPAIRED` — fires when an improvement is repaired (Subject = Player + Tile, 20% probability)
- `EVENTOPTION_SECURING_PEACE_RETURNING_EMISSARY_MISUNDERSTANDING_WAR` split into two weighted sub-options: `_MAIN` (weight 1000, peace) and `_FALLBACK` (weight 1, war)

#### Missions & Results
- `MISSION_TRIBE_END_ALLIANCE_NO_CHARACTERS` — variant for no-characters games
- `MISSIONRESULT_TRIBE_END_ALLIANCE_NO_CHARACTER` — applies `BONUS_TRIBE_ALLIANCE_END` directly

#### Memories
- `MEMORYFAMILY_WORKER_KILLED` (`MEMORYLEVEL_NEG_MEDIUM_SHORT`: -40 opinion, 20 turns)
- `MEMORYRELIGION_UNIT_KILLED` (`MEMORYLEVEL_NEG_MEDIUM_SHORT`: -40 opinion, 20 turns)

#### Effect Units
- `EFFECTUNIT_ROAD_BUILDER` — grants road building ability via `bBuildRoad: 1`
- `EFFECTUNIT_TRAIT_FERVENT` — self-apply enlist, replaces old player-level Fervent effect
- `EFFECTUNIT_ZEALOT_LEADER` — now uses `bHealKill: 1` instead of Apply Enlist
- New flags: `bHealKill` (heal on kill), `bBuildRoad` (can build roads)

#### Subjects
- `SUBJECT_TRIBE_HAS_CAMP` — tribe with at least 1 camp
- `SUBJECT_SINGLE_HIDDEN` — hidden single character with no spouse
- Gendered names added to archetype leader subjects (`SUBJECT_LEADER_SCHEMER`, `SUBJECT_LEADER_DIPLOMAT`, etc.)

#### BTT (Beyond the Tiber) Bonuses
- `BONUS_SLUM_AND_3_CITIZENS`, `BONUS_SEWER_AND_3_CITIZENS`

#### Enums
- `LinkType.HELP_EFFECT_UNIT_APPLY`
- `TileTextType.UNIMPROVED_RESOURCES` (512)
- `AnalyticsEventType.EVENT_INVALIDATED`

### UI / Client

- **PlaceBonusDecision rework** — free improvement bonuses now shown as normal event popups; tracked via `ClientUI.getActiveMinimizedDecision()` instead of selection state; place improvement overlay hidden during bonus events; Ctrl+click required to replace existing improvements
- **New map overlay**: `UNIMPROVED_RESOURCES` highlights tiles with resources but no improvement
- **New hotkeys**: `HOTKEY_EXTEND_TIME` (Alt+E) for multiplayer timer extension, `HOTKEY_SUPPRESS_TOOLTIP` (Ctrl+X hold) clears tooltips
- **"Restart Game" renamed to "Reroll Game"** — `TEXT_HELPTEXT_POPUP_MAIN_MENU_RESTART_GAME_BUTTON` now reads "Reroll Game"; "New Map" renamed to "Reroll Map" (hidden on predefined maps)
- **HelpLinkParser rewritten** from regex-based to span-based recursive parser with hash-cached string interning (performance improvement)
- **Character tooltip** now includes `IsAlive` bool
- **Project tooltips** now show turns-to-complete estimate via `buildTurnsLeftTextVariable()`
- **Religion adoption panel** shows requirement reasons when can't adopt (via `buildReligionAdoptionRequirementVariable()`); includes pagan religions
- **Luxury panel** send/return text now colored (`buildColorTextPositiveVariable` for send, `buildColorTextNegativeVariable` for stop)
- **Hall of Fame** now tracks `PeakLegitimacy` and per-leader `LeaderPeakLegitimacies` in `CompletedGame.cs`
- **Multiplayer** turn timer shows disconnected player count via `Game.getNumPlayersDisconnected()`
- **Fortify/Heal hotkeys** now call `cycleFromUnit()` after acting
- **Road building** moved from worker panel to unit action buttons; `RoadToActive` setter immediately dirties `TILE_PATHS` and `TILE_EDGES` overlays
- **Minimap** city sites and units merged into single `"MinimapIcons"` layer
- **Tile overlay** rendering uses 0.7f alpha via `SetAlpha(0.7f)`
- **End turn button** simplified to `getCurrentTurnPlayer() == activePlayer`
- **Custom reminder** notification hidden when empty (`IsVisible = !string.IsNullOrEmpty(customReminder)`)
- **Caravan mission** now checks `Game.isTeamContact()` before showing player in list
- **Worker improvement filter** now checks all city territory tiles via `pCity.getTerritoryTiles()` (not just selected tile)
- **Unit widget** now shows applied effect unit icons (debuffs) with `COLOR_NEGATIVE` via `SourceEffectUnitType.APPLIED`
- **Theology tech tooltip** information added (bug fix)
- **Latin supplemental characters** (U+100 to U+17F) added for Polish mod support

### Balance

- **Scribe specialist** money bonus doubled: tier 2 (10→20), tier 3 (20→40) in `EFFECTCITY_CITIZEN` yield rates
- **Ballista** strength reduced 60→50 (`iStrength` in `unit.xml`)
- **Chariot** strength reduced 60→50 (`iStrength` in `unit.xml`)
- **Wonder terrain targets fixed** — many wonders now use `TERRAIN_TARGET_WATER_MARSH` (water + marsh) in `TerrainInvalid`: Great Ziggurat, Hanging Gardens, Ishtar Gate, Apadana, Musaeum, Circus Maximus, Pantheon, Hagia Sophia, Via Recta Souk, Yazilikaya, Royal Library, Colosseum
- **Baths** (all 3 tiers) now have `TerrainInvalid: TERRAIN_TARGET_WATER_MARSH`
- **AI worker value** reduced 20,000→18,000; new `AI_UNIT_ROAD_BUILDER_VALUE: 2,000`; new `AI_UNIT_HEAL_KILL_VALUE: 5,000` (in `globalsAI.xml`)
- **AI succession change resistance** halved: `AI_SUCCESSION_CHANGE_MODIFIER` -50→-25
- **Descendant spouse tribe opinion** halved: `DESCENDANT_SPOUSE_OPINION_TRIBE` 40→20
- **Traders family seat** no longer grants a Merchant courtier
- **Family class trait dice** rebalanced: Champions favor more Zealots, Riders favor more Heroes (per Mohawk notes)
- **Civics bonus** on Sovereignty tech reduced 200→100 (`TECH_SOVEREIGNITY_BONUS_CIVICS` `iCost`)

### Modder-Breaking Changes

- `Character.getChildren()` now **protected** — use `getChildAt(int)`, `getNumChildren()`, `isParentOf(int)` instead
- All opinion calculation methods (`calculatePlayerOpinionOfUsRate`, `calculateCharacterOpinionRate`, `calculateTribeOpinionRate`, `calculateReligionOpinionRate`, `calculateFamilyOpinionRate`, and all `calculateXOpinionMemory` variants) return **`int?`** instead of `(bool, int)` tuples — callers use `?? 0` and `.HasValue` instead of `.Item2`
- `InfoBonus.maeImportResources` replaces singular `ImportResource` — now a `SparseList<ResourceType, int>` of `(ResourceType, count)` pairs
- `ClientSelection.cycleRequiredDecisions()` (renamed from `cycleDecisions()`)
- `IApplication.RestartGame` parameter renamed from `randomSeed` to `newMapSeed`
- `EFFECTPLAYER_TRAIT_FERVENT` removed from `effectPlayer.xml` — Fervent now uses `EFFECTUNIT_TRAIT_FERVENT` instead
- `DISEMBARKED_COOLDOWN` global removed

### Scenario Mods

- **Carthage 2/3/4**: silk tech disable overrides removed (base game now handles via `bDisable`)
- **Carthage 1**: new `Carthage1City.cs` file; game factory gains `CreateCity()` override
- **Carthage 2**: new `Carthage2City.setFamily()` override; `Carthage2Game.cs` substantially expanded
- **Carthage Campaign**: `CarthageCampaignPlayer.cs` (411 lines) and `CarthageCampaignGame.cs` (1105 lines) with victory level system, dirty bits networking, ruins placement
- **Egypt 3/5**: disciple/priest units gain `bRemoveVegetation` (e.g., `UNIT_MERYRE`, lector priests, `UNIT_AMUN_PRIEST`)
- **Egypt Campaign**: tab panel UI updated; new `text-egypt-change.xml`
- **Greece 4**: new `text-greece4-change.xml`
- **Greece 5**: new `Greece5Game` override (extends `GreeceCampaignGame`)
- **LearnToPlay 1/2/3**: significant new game overrides added (~18-25% code growth each)
- **LearnToPlay 3/4**: `-change.xml` text files deleted, content merged into base text files

### Infrastructure

- New `Game.getScenarioDataKeys()` — `protected virtual` method returning `ReadOnlyList<string>` for scenario subclasses
- New `Game.checkGameContent(ReligionType)` and `checkGameContent(CognomenType)` — DLC gating for religions and cognomens
- New `Game.getNumHumanControlled()` and `getNumPlayersDisconnected()` methods
- New `Game.areHumansOnSameTeam()` — used by `isMultiCompetitive()`, `isCompetitiveGameMode()`, `isMultiCooperative()`
- `doOccurrenceEffectsAllPlayers` gains `bForce` parameter (default `false`)
- `IRenderer.setAssetRenderQueue()` — new interface method
- `GameParameters.CanHaveDuplicateNations()` — validates dynasty counts per nation
- `Player.onCultureGrow(CultureType eCulture)` — called on city culture expansion, `public virtual` (hookable by mods); marks culture-gated techs as passed
- Content gating fields (`GameContentRequired`) added to `religion.xml`, `cognomen.xml`, `tribe.xml` defaults
- `tech.xml` gains `CultureValid` field — techs can require minimum culture level
- `TreeNode<T>` updated with `CollectionCache`-based scoped collections for ancestry queries
- `ReadOnlyList<T>` minor update — struct enumerator for heap-allocation avoidance
