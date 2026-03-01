# Old World Reference Changelog

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
