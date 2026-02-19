# Old World Reference Changelog

## 2026-02-18 Update

194 files changed (+9,550 / -5,713 lines) across Source and XML.

### Gameplay

- **Road building decoupled from worker identity** — new `bBuildRoad` effect unit flag allows any unit to build roads; worker units now carry `EFFECTUNIT_ROAD_BUILDER`; `isRoadBuilder()` replaces `isWorker()` checks for road-related logic
- **Nation bonus units unlock by culture level** instead of tech prerequisites; most now grant 2 units instead of 1 (Medjay Archer, Battering Ram, Siege Tower, Akkadian Archer, African Elephant, Light Chariot, Palton Cavalry, Hastatus, Hittite Chariot, DMT Warrior)
  - Tier 1 units: cost 100→200, require `CULTURE_STRONG`
  - Tier 2 units: cost 600, require `CULTURE_LEGENDARY`
- **Fervent trait redesigned** from player-level religion spread bonus (`EFFECTPLAYER_TRAIT_FERVENT` removed) to a general effect unit with self-apply enlist ability; civics cost reduced 400→100
- **Import resources now support quantities** — `ImportResource` (single) replaced with `aeImportResources` (list with counts); Perfume and Porcelain now grant 2 units
- **Christianity** now requires 3 Judaism cities (was 2); `RequiresReligion` tag replaced with threshold-based `aiRequiresReligion`
- **Workers** now have `bRemoveVegetation` by default (all 4 tiers)
- **Birth rate limiting** — female characters can only have 1 child per year on fast game speeds (`canHaveChildren` gains `bTestTooSoon` parameter)
- **Trait roll weights** now context-sensitive: reduced weight for governor traits if character isn't a governor, general traits if not a general; controlled by new globals `NO_GOVERNOR_TRAIT_DIE_MULTIPLIER` (25) and `NO_GENERAL_TRAIT_DIE_MULTIPLIER` (25)
- **ZOC display** now ignores rivers (`bIgnoreRiver: true`)
- **Porcelain tech** cost reduced 600→200, prereq changed from Lateen Sail to Coinage
- **Silk and Exotic Fur techs** disabled by default (`bDisable: 1`)

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
- `EVENTOPTION_SECURING_PEACE_RETURNING_EMISSARY_MISUNDERSTANDING_WAR` split into two weighted sub-options (peace vs. war fallback)
- Several diplomacy events tightened from `SUBJECTRELATION_PLAYER_MAX_UPSET` to `SUBJECTRELATION_PLAYER_WAR`
- `EVENTSTORY_MARRIAGE_POLY_FOREIGN` now has `bNoEventsValid: 1`

#### Missions & Results
- `MISSION_TRIBE_END_ALLIANCE_NO_CHARACTERS` — variant for no-characters games
- `MISSIONRESULT_TRIBE_END_ALLIANCE_NO_CHARACTER` — applies `BONUS_TRIBE_ALLIANCE_END` directly

#### Memories
- `MEMORYFAMILY_WORKER_KILLED` (medium-short negative) — families remember killed workers
- `MEMORYRELIGION_UNIT_KILLED` (medium-short negative) — religions remember killed units

#### Effect Units
- `EFFECTUNIT_ROAD_BUILDER` — grants road building ability
- `EFFECTUNIT_TRAIT_FERVENT` — self-apply enlist, replaces old player-level Fervent effect
- New flags: `bHealKill` (heal on kill), `bBuildRoad` (can build roads)

#### Subjects
- `SUBJECT_TRIBE_HAS_CAMP` — tribe with at least 1 camp
- `SUBJECT_SINGLE_HIDDEN` — hidden single character with no spouse
- Gendered names added to all archetype leader subjects

#### BTT (Beyond the Tiber) Bonuses
- `BONUS_SLUM_AND_3_CITIZENS`, `BONUS_SEWER_AND_3_CITIZENS`

#### Enums
- `LinkType.HELP_EFFECT_UNIT_APPLY`
- `TileTextType.UNIMPROVED_RESOURCES` (512)
- `GameLogType.EVENT_INVALIDATED`

### UI / Client

- **PlaceBonusDecision rework** — now shows a popup with "Recommended Tile" (auto-place) and "Choose Tile" (manual pick) options; tracked via `ClientUI.getActiveMinimizedDecision()` instead of selection state
- **New map overlay**: `UNIMPROVED_RESOURCES` highlights tiles with resources but no improvement
- **New hotkeys**: `HOTKEY_EXTEND_TIME` (Alt+E) for multiplayer timer, `HOTKEY_SUPPRESS_TOOLTIP` (Ctrl+X hold) clears tooltips
- **Tech tooltips** now show theology unlocks
- **HelpLinkParser rewritten** from regex-based to span-based recursive parser with hash-cached string interning (performance improvement)
- **Attack damage preview** sign display fixed (was double-negating)
- **Character tooltip** now includes `IsAlive` bool; XP display moved to separate line, only shown if level > 1 or XP > 0
- **Project tooltips** now show turns-to-complete estimate
- **Religion adoption panel** shows requirement reasons when can't adopt; only shows religions player has contact with
- **Luxury panel** send/return text now colored (green for send, red for stop); opens even with 0 luxuries
- **Hall of Fame** now tracks peak legitimacy and per-leader peak legitimacy
- **Multiplayer** turn timer shows disconnected player count
- **Fortify/Heal hotkeys** now cycle away from unit after acting
- **Road building** moved from worker panel to unit action buttons; overlay toggles immediately
- **Cooldown ground text** (tile label showing cooldown name) removed
- **Minimap** city sites and units merged into single "MinimapIcons" layer
- **Tile overlay** rendering moved to end of pass at 0.7 alpha
- **End turn button** simplified to `getCurrentTurnPlayer() == activePlayer`
- **Custom reminder** notification hidden when empty
- **Caravan mission** now checks team contact before showing player in list
- **Worker improvement filter** now checks all city territory tiles (not just selected tile)
- **Unit widget** now shows applied effect unit icons (debuffs) with negative color

### Balance

- **Scribe specialist** money bonus doubled: tier 2 (10→20), tier 3 (20→40)
- **Wonder terrain targets fixed** — many wonders incorrectly used `TERRAIN_TARGET_WATER` (water only), now use `TERRAIN_TARGET_WATER_MARSH` (water + marsh): Great Ziggurat, Hanging Gardens, Ishtar Gate, Apadana, Musaeum, Circus Maximus, Pantheon, Hagia Sophia, Via Recta Souk, Yazilikaya, Royal Library, Colosseum, national temples
- **Baths** (all 3 tiers) now have `TerrainInvalid: TERRAIN_TARGET_WATER_MARSH`
- **AI worker value** reduced 20,000→18,000; new `AI_UNIT_ROAD_BUILDER_VALUE: 2,000`; new `AI_UNIT_HEAL_KILL_VALUE: 5,000`
- **AI succession change resistance** halved (-50→-25)
- **Descendant spouse tribe opinion** halved (40→20)
- **Traders family seat** no longer grants a Merchant courtier
- **Engineer effect unit** no longer gives +25% Siege/Ship modifiers
- **Family class trait dice** rebalanced: Zealot/Hero weights swapped on two families
- **Chariot** strength reduced 60→50
- **Civics bonus** on one tech reduced 200→100
- **Trait rating fallback** info now always shown (was gated behind Advanced Help)

### Modder-Breaking Changes

- `Character.getChildren()` now **protected** — use `getChildAt(int)`, `getNumChildren()`, `isParentOf(int)` instead
- `Game.setScenarioData(string, string, bool bSave)` simplified to `setScenarioData(string, string)` — `bSave` parameter removed
- All opinion calculation methods (`calculatePlayerOpinionOfUsRate`, `calculateCharacterOpinionRate`, `calculateTribeOpinionRate`, `calculateReligionOpinionRate`, `calculateFamilyOpinionRate`, and all `calculateXOpinionMemory` variants) return **`int?`** instead of `(bool, int)` tuples
- `InfoBonus.meImportResource` (single) replaced with `InfoBonus.maeImportResources` (list of `(ResourceType, int)` pairs)
- `ClientSelection.cycleDecisions()` renamed to `cycleRequiredDecisions()`
- `removeTileOverlay` renamed to `clearTileOverlay`
- `IApplication.RestartGame` parameter renamed from `randomSeed` to `newMapSeed`
- `EFFECTPLAYER_TRAIT_FERVENT` removed from `effectPlayer.xml`
- `DISEMBARKED_COOLDOWN` global removed

### Scenario Mods

- **Carthage 2/3/4**: silk tech disable overrides removed (base game now handles via `bDisable`)
- **Carthage 1**: new `Carthage1City.cs` file; game factory gains new overrides
- **Carthage 2**: new `Carthage2City` and `Carthage2Game` overrides added
- **Carthage Campaign**: significant `CarthageCampaignPlayer` refactor; new `CarthageCampaignGame` overrides
- **Egypt 3/5**: worker units gain `bRemoveVegetation`
- **Egypt Campaign**: tab panel UI updated; new `text-egypt-change.xml`
- **Greece 4**: new `text-greece4-change.xml`
- **Greece 5**: new `Greece5Game` override added
- **LearnToPlay 1/2/3**: significant new game overrides added
- **LearnToPlay 3/4**: `-change.xml` text files deleted, content merged into base text files

### Infrastructure

- `ReadOnlyList` minor update
- `TreeNode` updated
- New `Game.getScenarioDataKeys()` protected virtual method for scenario subclasses
- New `Game.checkGameContent(ReligionType)` and `checkGameContent(CognomenType)` — DLC gating for religions and cognomens
- New `Game.getNumHumanControlled()` and `getNumPlayersDisconnected()` methods
- New `Game.areHumansOnSameTeam()` for cooperative/competitive detection
- `doOccurrenceEffectsAllPlayers` gains `bForce` parameter
- `IRenderer.setAssetRenderQueue()` new interface method
- `GameParameters.IsValid()` now validates dynasty counts per nation
- `Player.onCultureGrow(eNextCulture)` called on city culture expansion — hookable by mods
- Content gating fields added to `religion.xml`, `cognomen.xml`, `tribe.xml` defaults
- `tech.xml` gains `CultureValid` field — techs can require minimum culture level
