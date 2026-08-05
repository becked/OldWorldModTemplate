# Old World Reference Changelog

## 2026-08-05 Update (Update #149, v1.0.84365)

XML, Reference/Source C#, and decompiled changes across 47 XML files (40 record-bearing files with 118 modified, 65 added, 76 removed records, plus 5 UI layout files and 2 new scenario override files), 30 Reference/Source C# files, and ~46 decompiled files. Highlights: **Modsets** — named, saved groups of mods that toggle as a unit — a new **High Contrast Player Colors** option that routes single-team games through the team-color palette, **Schemers made eligible for every council seat**, **per-player tech-path history recorded in saves** for community analytics, an **AI governor/general cross-penalty** so a strong governor candidate isn't wasted as a general, a new **6-per-player city-site density**, and **attackers can now advance into a tile whose defender died during attack events**. Unity engine stays at 6000.3.15f1 (verified in `globalgamemanagers`).

### Gameplay

- **Schemers can serve as Ambassador and Chancellor** — `council.xml`: `COUNCIL_AMBASSADOR` and `COUNCIL_CHANCELLOR` both gain `abTraitPrereq.TRAIT_SCHEMER_ARCHETYPE (absent)→1`. `COUNCIL_SPYMASTER` already carried it and is unchanged; since the file defines only these three seats, Schemers now qualify for all of them
- **Priest and Bishop religion opinion sharply increased** — `specialist.xml`: `SPECIALIST_PRIEST_1/2/3` `iOpinionReligion 1/2/3→2/4/6` (doubled); `SPECIALIST_BISHOP_1/2/3` `iOpinionReligion 1/2/3→3/6/9` (tripled)
- **Priest happiness rebalanced to a clean 1/2/3 per tier** — `effectCity.xml`: `EFFECTCITY_SPECIALIST_PRIEST_2` `aiYieldRate.YIELD_HAPPINESS 15→20`, `EFFECTCITY_SPECIALIST_PRIEST_3` `20→30` (yields are ×10-scaled; `_PRIEST_1` stays at `10`)
- **Expensive courtier techs now award two courtiers** — `bonus.xml`: `BONUS_TECH_BATTLELINE_BONUS_SOLDIER`, `BONUS_TECH_INFANTRY_SQUARE_BONUS_SOLDIER`, `BONUS_TECH_CHAIN_DRIVE_BONUS_MERCHANT`, `BONUS_TECH_FISCAL_POLICY_BONUS_MERCHANT`, `BONUS_TECH_JURISPRUDENCE_BONUS_MINISTER`, `BONUS_TECH_SCHOLARSHIP_BONUS_SCIENTIST` each gain `AddCourtierOther[1].First (absent)→` a second copy of the same courtier. These six are exactly the courtier bonus-techs costing 350+ science (Jurisprudence 550); the cheaper `TECH_FORESTRY`/`TECH_CITIZENSHIP`/`TECH_EVENT` variants are untouched
- **"Repair improvements" ambitions removed entirely** — `goal.xml` drops `GOAL_FOUR_REPAIRED` and `GOAL_EIGHT_REPAIRED`; `bonus.xml` drops `BONUS_AMBITION_FOUR_REPAIRED`/`_EIGHT_REPAIRED`; `eventOption.xml` drops `EVENTOPTION_AMBITION_FINISHED_STONE_500_OPTION_FOUR_REPAIRED` and `EVENTOPTION_RALLY_STANDING_ARMIES_REPAIR_{FOUR_IMPROVEMENTS,EIGHT_IMPROVEMENTS,CITIES}`
- **Rally Standing Armies flattened from a chooser into a direct outcome** — `EVENTOPTION_RALLY_STANDING_ARMIES_OPTION_0` loses all three `aiEventOptionProb` entries and instead gains `Text TEXT_EVENTOPTION_RALLY_STANDING_ARMIES_OPTION_0` plus `aeBonuses[2]`/`[3]` = `BONUS_EVENTOPTION_RALLY_STANDING_ARMIES_OPTION_0_CITY_0`/`_CITY_1` — the bonuses the removed `_REPAIR_CITIES` variant carried, now unconditional. `EVENTOPTION_AMBITION_FINISHED_STONE_500_OPTION_0` likewise drops its `aiEventOptionProb.…_FOUR_REPAIRED 1000` entry, leaving Four Stonecutters (100) and Engineering (10)
- **Religion "four disciples" ambitions pushed later for the newer faiths** — `goal.xml`: `GOAL_FOUR_DISCIPLES_BUDDHISM` `iMinTier 2→4`, `iMaxTier 3→5` (Empires of the Indus); `GOAL_FOUR_DISCIPLES_CHRISTIANITY` and `_MANICHAEISM` both `iMinTier 2→3`, `iMaxTier 3→4`. The Zoroastrianism and Judaism variants stay at 2–3
- **Gifted ivory now counts as a precious resource** — `effectCity.xml`: `EFFECTCITY_GIVE_IVORY` gains `EffectCityUnlock (absent)→EFFECTCITY_RESOURCE_PRECIOUS`, the same unlock as the gem/gold/silver/pearl effects. It is the only `EFFECTCITY_GIVE_*` record carrying it
- **Tile-buying unlock now keys off the acting unit, not any unit on the tile** — `City.canBuyTile` gains a `Unit pUnit` parameter and replaces its scan of `pTile.getAliveUnits(...)` for any same-team unit with `hasBuyTileYield(eYield)` by a direct `(pUnit == null) || (pUnit.getTeam() != getTeam()) || !pUnit.hasBuyTileYield(eYield)` rejection. `Unit.canBuyTile` passes `this`; `PlayerAI.doYieldExpenses` and `getBestBuyTile` pass `null`
- **Tribe-kill ambitions survive the tribe's death via converted raiders** — `Player.isGoalPossible` (PlayerGoal.cs), in both the single-tribe and multi-tribe branches, replaces a bare `return false` with a count of units where `getTribe() == infos().Globals.RAIDERS_TRIBE && getOriginalTribe() == <tribe>`, failing only if `killed + iRaiders < required`
- **`bTileText` threaded through the whole-yield path** — `City.processYieldWhole(YieldType, int)` → `(YieldType, int, bool bTileText)` and `Player.processYieldWholeTile(YieldType, int, Tile)` → `(…, bool bTileText)`, so callers can suppress floating tile text. Sites passing `false`: `Game.removeCity`, `Tile.makeRevealed`, `Tile.harvestTile`, `Unit.attackUnit`, `Unit.pillage`; passing `true`: `Game.handleAction` and two loops in `Player.doBonus` (PlayerBonus.cs)
- **Event-story cache cleared when a human hands off to the AI** — `Player.leaveGame` adds `mzTriggerValidEventStories.clear();` before `setAIControlled(true)` in the "other human players left" branch

### Combat

- **Attacker can advance into a tile whose defender died after attack events resolved** — `Unit.attackUnitOrCity` gains a post-`doAttackEvents` block that, when `getHP() > 0 && pDefendingUnit != null && pDefendingUnit.isDead()`, scans `apDefendingTileOutcomes` and — if the outcome lacks `KILL`, `CAPTURED`, and `ADVANCE`, and `canAdvanceAfterAttack(...)` passes — calls `setTileID(pToTile.getID(), …)` and ORs in `AttackOutcome.ADVANCE`. If `canHaveRoutCooldown(...)` also passes it ORs in `ROUT`, applies `doCooldown(infos().Globals.ROUT_COOLDOWN, bForce: true)`, and calls `changeRoutChain(1, pActingPlayer)`
- **Externally-imposed cooldowns no longer suppressed by no-cooldown turn styles** — `Unit.actCooldownTurns` and `Unit.doCooldown` gain a `bool bOwnAction = true` parameter, and the short-circuit becomes `if (game().turnStyle().mbNoCooldown && bOwnAction)`. `Unit.attackUnitOrCity` passes `bOwnAction: false` for the defender's `STUNNED_COOLDOWN`/`IMMOBILE_COOLDOWN`, as does `Player.doBonus` (PlayerBonus.cs) for `infos().bonus(eBonus).meSetCooldown`
- **Tribe units lose their action-cooldown exemption** — `Unit.actCooldownTurns` removes the `if (isTribe()) return 1;` early-out, so tribe units fall through to the standard `return 2`
- **Killing a tribe unit no longer accelerates the nearest settlement's spawn timer** — `Unit.makeDead` drops the block that found `game().findNearestTribeSettlement(tile(), getTribe())` and cut `setImprovementUnitTurns((getImprovementUnitTurns() * 4) / 5)` — a 20% reduction to the remaining spawn countdown on every tribe unit death. Nothing replaces it
- **Stun/immobile recovery gated to the last cooldown turn, and end-turn unit work consolidated** — new `Unit.processEndTurn` kills the unit at `getHP() == 0`, else — only when `getCooldownTurns() == 1` — converts `STUNNED_COOLDOWN` *or* `IMMOBILE_COOLDOWN` to `ATTACKED_COOLDOWN`. Previously `Player.processEndTurn` did this inline with no turn-count check and handled only `STUNNED_COOLDOWN`; it now just loops `game().unit(getUnits()[i]).processEndTurn()`. `Game.playCurrentTurn` splits tribe-unit handling into a pre-move `doTurn()` pass and a post-move `processEndTurn()` pass (dropping the old unit-ID snapshot indirection). A parallel `Tribe.processEndTurn()` was added but has no caller in `Reference/Source/` or `decompiled/`
- **New `Unit.canConvert` precondition replaces ad-hoc checks at every conversion site** — `Unit.canConvert(PlayerType, TribeType)` returns false when the unit already has that player+tribe, when `isTribe() && tile().getImprovementTribeSite() == getTribe()`, or when the tile's city isn't allied with the target. `Unit.convert` drops its unused `bool bEnlisted` parameter and opens with `MohawkAssert.Assert(canConvert(...))`. Guarded call sites: `Unit.convertToRaider`, `Unit.doTurn`, `Unit.getEnlistOnKillChance` (returns `0` early), and `Player.canDoBonusSingle` (PlayerBonus.cs)

### AI

- **AI cross-penalizes governor and general roles by opportunity cost** — `PlayerAI.traitValue` now computes `iTestGovernorCityID` as `eUnitGeneral.HasValue ? -1 : pCharacter.getCityGovernorID()` and `eTestUnit` as `iCityGovernor.HasValue ? UnitType.NONE : …`, widens both branch conditions to fire when *either* role applies, and **subtracts** the opposite role's value — `iGovernorValue` when `iTestGovernorCityID == -1` ("penalize general role for being a good governor candidate") and `iGeneralValue * getTurnsLeftEstimate(…)` when `eTestUnit == UnitType.NONE` ("penalize governor role for being a good general candidate"). This is the code behind the release note's improved governor/general selection
- **Opinion and relationship bonuses now score for player-less characters** — `PlayerAI.bonusValue` splits its `pTargetCharacter != null && pTargetCharacter.hasPlayer()` gate into an outer null check with a nested `hasPlayer()` block, hoisting the `meMemory`, `meMemoryLeader`, `meAddLeaderRelationship`, and `meRemoveLeaderRelationship` handling above it. Those four also switch from `iCharacterValue += pCharacterPlayer.AI.getCharacterOpinionValue(…)` to `iValue += getCharacterOpinionValue(…)`, so the evaluating AI scores the opinion and the values bypass the trailing same-team/other-team halving
- **Family-head opinion value requires the family to be started** — `PlayerAI.getCharacterOpinionValue`: `if (pCharacter.isFamilyHead())` → `… && player.isFamilyStarted(pCharacter.getFamily())`
- **AI strongly prefers urban tiles the player has pinged** — `PlayerAI.getBestUrbanTile` adds `if (player.getTileImprovementPing(iTileID, true) == infos.Helpers.getUrbanImprovementPing()) { iValue *= 10; }`
- **River-crossing attack modifier was testing the target tile against itself** — in the local `getEffectExtraModifier` inside `UnitRoleManager.getAttackTargetValue`: `pTargetTile.isRiverCrossing(pTargetTile)` → `pFromTile.isRiverCrossing(pTargetTile)`, so `applyEffect.miRiverAttackModifier` now keys off the actual attack direction (`UnitRoleManager.cs:4729`)
- **AI event-decision error log names the offending record** — `PlayerAI.doDecision`: `MohawkLog.LogError("Unexpected EVENT_STORY")` → `… ("Unexpected Event: " + infos.eventStory(eEventStory).mzType)`

### Maps & map generation

- **New "6 per Player" city-site density** — `mapOption.xml` adds `MAP_OPTION_CITY_SITE_NUMBER_MEDIUM_LOW` ("6 per Player", reusing the Medium help text); `mapOptionsMulti.xml` inserts it into `MAP_OPTIONS_CITY_SITE_NUMBER` at `Choices[2]`, taking the list from 4 to 5 choices (High 9 / Medium / **6 per Player** / Low 3 / Single) with `Default` unchanged. `DefaultMapScript.GetCitySiteSelectedNumber` gains a `MEDIUM_LOW_CITY_NUMBER` branch returning `infos.Globals.MAX_FAMILIES * 2 * iNumPlayers`, bound in `AssignTypes`; `MAX_FAMILIES` is `3` (`globalsInt.xml:786`), so it slots between Low (×1) and Medium (×3)
- **Game of the Week map selection ignores locally-owned content** — `InfoHelpers.GetAvailableMapsScripts` gains a trailing `bool bCheckOwnedContent = true` and guards its `maeGameContentRequired` filter behind it; `GameParameters.GetRandomMapClass` forwards a matching parameter, and `GameParameters.SetGameOfTheWeekParameters` calls it with `bCheckOwnedContent: false`
- **Occurrence terrain changes are conditional on the change succeeding, and prune other occurrences** — `Tile.setValidTerrain` changes from `void` to `bool`; `Game.doOccurrenceModifyTerrain` wraps the whole `modifiedTiles.Add` / `getOccurrenceTileChange` / `loadOccurrenceTileChange` sequence in `if (pLoopTile.setValidTerrain(eChange))` and calls the new `Tile.updateOccurrenceValidity(OccurrenceData)`, which removes the tile from other active occurrences' `msiAffectedTileIDs` unless it or an adjacent tile still matches their terrain criteria
- **Occurrence-driven vegetation reduction no longer pillages improvements itself** — `Tile.reduceVegetation` deletes the entire `hasImprovement() && canDestroyImprovement()` block (the `clearImprovement()`/`pillageImprovement()` branch and its `TEXT_GAME_IMPROVEMENT_PILLAGED_OCCURRENCE_LOG_DATA` push). The standalone `if (vegetation.meVegetationRemove == VegetationType.NONE) return;` early-out was folded into `if (!hasImprovement() && vegetation.meVegetationRemove != VegetationType.NONE)`, so the `iUnitDamage` and adjacent-spread code below now runs for vegetation with no removal target. The occurrence-pillage path at `Game.cs:8511` is unchanged
- **Huns are no longer an organized tribe in the Barbarian scenario** — new file `Reference/XML/Mods/Barbarian/Infos/tribe-change.xml` with a single entry, `TRIBE_HUNS` `bOrganized 0`, overriding `tribe.xml` where it is `1`. The `Barbarian` mod folder itself is not new
- **Carthage 1 buffs passive and weak tribes** — new file `Reference/XML/Mods/Carthage1/Infos/tribeLevel-change.xml` gives `TRIBELEVEL_PASSIVE` and `TRIBELEVEL_WEAK` an identical block: `iDefendUnits 2`, `iMaxUnitsRange 3`, `iTurnUnitModifier 20`, `iTurnCityUnitProb 12`, `iUnitUpgrade 25`, `iRaidRange 16`. Against base `tribeLevel.xml` that is PASSIVE `iTurnUnitModifier 80→20`, `iTurnCityUnitProb 6→12`, `iRaidRange (absent)→16`; WEAK `iDefendUnits 1→2`, `iTurnUnitModifier 40→20`, `iRaidRange 14→16` — denser, further-raiding, better-defended low-tier tribes

### Events & characters

- **Tribes no longer demand peace upkeep when a teammate is their ally** — `eventStory.xml`: `EVENTSTORY_TRIBE_PEACE_UPKEEP` gains `aeSubjects[3] SUBJECT_PLAYER_US` and `SubjectRelations[1]` = (`First 3`, `Second SUBJECTRELATION_TRIBE_NO_ALLIANCE_TEAM`, `Third 2`). That relation is `bNotTribeAllianceTeam`, which `PlayerEvent.cs:10255-10272` fails when `game().getTribeAllyTeam(tribe) == player.getTeam()`
- **New Buddhist holy site event** — `eventStory-eoti.xml` adds `EVENTSTORY_HOLY_SITE_BUDDHISM` (`Trigger EVENTTRIGGER_IMPROVEMENT_FINISHED`, `TriggerData IMPROVEMENT_HOLY_SITE_BUDDHISM`, option `EVENTOPTION_HOLY_SITE_FINISHED`, `bIgnoreTriggerProb 1`, frame `FRAME_INDIA`). Buddhism was the only faith without one — the Zoroastrianism/Judaism/Christianity/Manichaeism equivalents already exist in `eventStory.xml` (Empires of the Indus)
- **Hun "Testing the Treaty" events gated behind turn 20 and put on a shared cooldown** — `eventStory-eoti.xml`: `EVENTSTORY_TESTING_THE_TREATY_{ALLIANCE,ALLIANCE_NORMAL,ALLIANCE_WEAK,PEACE,PEACE_NORMAL,PEACE_WEAK}` each gain `iMinTurns (absent)→20`, `aeEventStoryRepeatTurns[0] EVENTSTORY_AN_ENEMY_TO_FEAR`, and `aeEventStoryRepeatTurns[1]` pointing at the paired opposite variant (alliance↔peace at matching tribe strength); `iRepeatTurns 10` is unchanged (Empires of the Indus)
- **Character full-name and inset crests switch from nation to player** — `Character.getFullNameVariable`'s `hasNation()` branch and `ClientUI.updateCharacterInsetInfo`'s (now `hasPlayer()`) branch both move to `HelpText.buildPlayerCrestLinkVariable(…)`/`buildPlayerCrestVariable(…)`. `HelpText.buildNationCrestVariable` and `buildNationCrestLinkVariable` are deleted outright; no callers remain anywhere in `Reference/Source/` or `decompiled/`
- **Character-upgrade decision popups include heir text** — `ClientUI.doDecision` calls `HelpText.getCharacterHeirTextType(pCharacter)` and, when non-`NONE`, appends it with `buildCharacterLinkVariable(pCharacter, pActivePlayer)`
- **Malchus I gets a distinct portrait in Carthage 1** — `Mods/Carthage1/Infos/character-add.xml`: `CHARACTER_MALCHUS_I` `PreferredPortrait CHARACTER_PORTRAIT_CARTHAGE_LEADER_MALE_01→CHARACTER_PORTRAIT_HANNO_THE_NAVIGATOR` (target record in `characterPortrait-wd.xml:1329`, Wonders and Dynasties)
- **Rome female leader 11 and Tamil male leader 05 portraits retuned** — both are modified existing records, not new ones (`characterPortrait.xml` is unmodified at 544 records). `characterPortraitFeaturePoints.xml` shifts `zColor` across all five ages of each; `characterPortraitOpinion.xml` softens `OPINION_OPTIONS_ROME_LEADER_FEMALE_11_NEGATIVE_{ADULT,SENIOR}` eyebrow-corner offsets and heavily damps the `POSITIVE_{ADULT,SENIOR}` mouth-corner deltas; `characterPortraitAgeInterpolation.xml` rebuilds `INTERPOLATION_OPTIONS_TAMIL_LEADER_MALE_05_{TEEN_ADULT,YOUTH_TEEN}` with `bTint 0→1` and, for `TEEN_ADULT`, `eDestinationDonor NONE→CHARACTER_PORTRAIT_TAMIL_LEADER_MALE_03` (Empires of the Indus)
- **2026 community tournament announcement hidden** — `announcements.xml`: `TOURNAMENT_ANNOUNCEMENT` `bHidden (absent)→1`

### UI

- **New "High Contrast Player Colors" player option** — `playerOption.xml` adds `PLAYEROPTION_HIGH_CONTRAST_PLAYER_COLORS` ("Player colors are chosen to be highly distinguishable from one another"), exposed to C# via `globalsType.xml`'s new `HIGH_CONTRAST_PLAYER_COLORS` global and `InfoGlobals.HIGH_CONTRAST_PLAYER_COLORS`. `Player.getTeamColor`, `getPlayerColor`, and `getBorderPattern` change their gate from `game().isTeamColors()` to `game().isTeamColors() || (pActivePlayer ?? this).isPlayerOption(infos().Globals.HIGH_CONTRAST_PLAYER_COLORS)`, and `getTeamColor` now indexes by player rather than team when only the option is on (`int iColor = game().isTeamColors() ? (int)getTeam() : (int)getPlayer();`). A new `ClientUI.DirtyType.BORDERS` dispatches to the new `ClientUI.updateBorders()` (looping `Tile.updateBorders()`), set from `OptionsMenuPanel` alongside `TILES` when this option, `FLIP_UNIT_COLORS`, or `SHOW_RIVAL_FAMILY_COLORS` is toggled — border repaint on those two is itself new
- **Team palettes reshuffled and completed to support the above** — `color.xml`: the `COLOR_TEAM_03_*` family takes Team 10's former values (`COLOR_TEAM_03 #4f4f56→#fadc3b`, `_FIRST`/`_SECONDARY` `#fdee2d→#ab2c38`) while `COLOR_TEAM_10_*` gets a fresh cyan/blue/magenta set (`#fadc3b→#03e3fc`, `_FIRST`/`_SECONDARY` `#ab2c38→#1e14a6`, `_OTHERS` `#4f4f56→#cc23bb`); `COLOR_TEAM_05` and its text variants shift `#e8f815→#aaff00`. `teamColor.xml` fills `TEAMCOLOR_06`–`_10` out to the full six-entry `aeBorderPatterns` list (TRIANGLE/DASH/PLUS/CIRCLE/DIAMOND/X) that `_01`–`_05` already had — `Player.getBorderPattern` indexes it modulo its count, so short lists previously collapsed distinct players onto one pattern. `playerColor.xml` adds the last missing `PLAYERCOLOR_TEAM_10_OTHERS`, wired as `TEAMCOLOR_10` `aePlayerColors[1]`
- **Attack overlay is now fully opaque** — `color.xml`: `COLOR_ATTACK_OVERLAY` `zHexValue #ff000080→#ff0000ff`
- **Map search gains an "All" player filter** — `ClientUI.MapSearchPlayerType` gains `ALL` as its first member, shifting downstream indices by one: `ClientUI.start` seeds sub-tag `-Player` index 0 with `TEXT_UI_MODS_FILTER_ALL` and starts its loop at 1; `getMapSearchResults`'s `isPlayerTile`/`isPlayerUnit` short-circuit to `true` for `ALL` and otherwise offset by one. Invalid selections now fall back to `ALL` instead of the first valid entry (`updateMapSearchDropdowns` drops its `firstValid` local), dead tribes are filtered out of the dropdown (`Game.tribe(eLoopTribe).isAlive()`), and new `ClientUI.setMapSearchActive(bool)` closes the panel on tab change. An unhandled-type assert was also inverted so it can fire: `MohawkAssert.Assert(true, "Unhandled MapSearchPlayerType")` → `Assert(false, …)`
- **"Make Urban" becomes a first-class worker ping and tile-widget action** — new `InfoHelpers.getUrbanImprovementPing()` (`improvementsNum() + 2`, sibling to `getRoadImprovementPing()`) is handled across `ClientUI.start` (icon `ADD_URBAN`), `GetValidImprovementsForPing`, `IsValidPingImprovement`, `doImprovementPing`, `OnWidgetHover`, and `updateTileWidget` (availability via `canAddUrban(…)`/`canMakeUrban(…)`, ending in `WorkerActionType.URBAN`). `Tile.makeUrban` calls a new `Tile.clearUrbanPings()`; `Player.writeGameXML`/`readGameXML` serialize it as `Improvement="URBAN"` alongside the existing `"ROAD"`; `PlayerAI.getBestUrbanTile` weights it ×10
- **Road and Make Urban tooltips show a buy-yields hint** — `ClientUI.populateImprovementTooltip` adds a `hintBuilder` to both branches, fed by the new `Game.getRoadCostsTile(int, Dictionary<YieldType, int>)` and by `getAddUrbanCost`, rendering through `HelpText.buildBuyYieldsKeyText(…)` into `Hint-Label`
- **Tribe widgets show a trade-outpost countdown** — `ClientUI.updateTribeWidget` scans all players for the smallest positive `tile.getTradeOutpostTurnsLeft(eLoopPlayer)` and sets `IsTradeOutpost`/`TradeOutpost-Label`; the develop-turns label now requires `nextDevelopTurns < tradeOutpostTurns`, so the countdown outranks it. Backed by new `LinkType.HELP_TRADE_OUTPOST`, `HelpText.buildTradeOutpostIconLinkVariable(…)`, `TEXT_HELPTEXT_LINK_HELP_NEXT_TRADE_OUTPOST`, and a new `UIText` bound to `TribeWidget$-TradeOutpost-Label` in `barbarian-widget.xml`
- **Holy city religion icons use a dedicated sprite** — `ClientUI.updateCityWidget`: `religionTag.SetKey("Icon", Infos.religion(eLoopReligion).mzIconName)` → `$"{…mzIconName}_HOLY"`
- **Multi-source city effects link to a source list instead of picking one** — new `InfoEffectCity.getNumSources()` counts every non-`NONE` `meSource*` field plus `maeSourceEffectCity.Count + maeSourceResources.Count`; `HelpText.buildEffectCitySourceLinkVariable` gains a `bool bListType` parameter and routes `getNumSources() > 1` to the new `HelpText.buildMultiSourceLinkVariable(…)`, handled by the new `LinkType.HELP_SOURCE_ALL` case in `buildLinkHelp` which bullet-lists every populated source. `Infos.SetEffectCitySources` now also back-propagates `maeSourceImprovements`/`maeSourceProjects` and aggregates luxury resources into `Globals.LUXURY_EFFECTCITY`
- **Luxury concept help lists every luxury resource, map resources first** — `concept.xml`: `CONCEPT_LUXURY` drops `zHelpText TEXT_HELPTEXT_LINK_HELP_LUXURY` for `zLink HELP_LUXURY`; `HelpText.buildLinkHelp`'s `HELP_LUXURY` case adds a two-pass loop splitting on the new `InfoHelpers.isMapResource(eResource)`, with the remainder under `TEXT_HELPTEXT_LINK_HELP_LUXURY_NON_MAP`. Entries are gated by the new `InfoHelpers.canEverHaveEffectCity(Player, EffectCityType)`, which rejects effects whose source nation, project, improvement, or difficulty doesn't match the player
- **Resource help fully gated on owning the resource's content** — `HelpText.buildResourceHelp` wraps its family-opinion, no-improvement-yields, improvement-class, specialist-class and harvest sections in `pGame?.checkGameContent(eResource) ?? mInfos.modSettings().App.CheckContentOwnership(…)`, using the new `Game.checkGameContent(ResourceType)` overload
- **Bonus courtier grants are grouped and counted** — `HelpText.buildBonusHelp` replaces the flat `foreach` over `maeAddCourtierOther` with a loop over `courtiersNum()` that counts matches and emits one line carrying `iNumCourtiers > 1 ? TEXTVAR(iNumCourtiers) : TEXTVAR(false)` — the display side of the two-courtier tech change above
- **Help-text yield math no longer lets a sub-100% modifier flip a value's sign** — ~19 `infos().utils().modify(…)` call sites across `HelpText.Effect.cs` and `HelpText.cs` (including `calculateTotalYieldModifierForGovernor`, `yieldModifierNoSpecialist`, and `buildTheologyHelp`) drop the trailing `bAllowNegative: true`, so `Utils.modify`'s default clamp `Math.Max(0, iModifier + 100)` applies. Separately, `HelpText.buildCityYieldNetHelp` adds `bool bReverseModiferSign = bReverseSign ^ (iBaseYield < 0);` and substitutes it at all seven modifier sites
- **Effect-city totals respect `bShowTotal` and stop rendering as rates without a city** — `HelpText.Effect.cs`: `if (iTotalValue != 0)` → `… && bShowTotal`, `((iCount > 0) ? …)` → `((iCount > 0 && bShowTotal) ? …)`, and four `buildYieldValueIconLinkVariable` calls change `bRate: true` → `bRate: pCity != null`
- **Worker action filters persist per unit type, and current-tile buttons respect enabled state** — `ClientUI.updateWorkerActions` writes `mdSelectedWorkerFilter[pSelectedUnit.getType()] = WorkerActionFilter.CURRENT_TILE` on a lookup miss instead of using a throwaway local; `GetValidImprovementsForTile` drops `bTestEnabled: false`; and a new `ClientUI.isIgnoreRequirements()` replaces the unconditional `bForceImprovement: true` in `isShowTileYieldPreview` and `updateTileWidget`
- **Pillaged tiles grey out by repair eligibility** — `ClientUI.updateTileWidget` moves the `canStartImprovementOnTile(…)` assignment into the non-pillaged branch and gives the pillaged branch `bAvailable = pSelectedUnit == null || pSelectedUnit.canRepair(tile, pActivePlayer, isBuyGoods())`
- **Popup handling during autoplay and minimized decisions** — `ClientUI.update` drops `!pActivePlayer.isAIAutoPlay()` from its `shouldProcessPopups()` guard, and adds `&& !(getActiveMinimizedDecision() is PlaceBonusDecision)` so modal popups don't interrupt a minimized bonus placement
- **Korean number formatting corrected** — `language.xml`: `LANGUAGE_KOREAN` `zDecimalSeparator ,→.` and `zThousandsSeparator .→,`, which were swapped
- **Tile and unit widget layout** — `tile-widget.xml` regroups the build button, status raycast target, and yields under one centred `VGroup` (the other ~60 changed lines are re-indentation); `unit-widget.xml` adds `SortingGroupName="WorldUI"` to the widget root, backed by a new `UnitWidget.SortingGroupName` property and `canvasSortingLayer = "WorldUI"` set during init

### Modding

- **Modsets — named, saved groups of mods that toggle as a unit** — five new Assembly-CSharp types: `Modset` (`name`, `summary`, `List<ModsetEntry> mods`, `isActive`, `appliedFingerprint`, `HasUnavailableMods`), `ModsetEntry` (`folderName`, `displayName`, `modioID`, `workshopFileID`, `unavailable`), `ModsetSave`, `ModsetManager`, and `ModsetInputPopup`. `ModsetManager` persists to `ModsetsSave.xml` under `AppDirectoryPaths.UserDataPath` via `XmlSerializer`, resolves entries against installed mods by mod.io ID → Workshop ID → folder name → display name (`ResolveEntry`/`ResolveAgainstInstalled`, back-filling stored fields and marking unmatched entries unavailable), and builds activation lists that skip script mods and non-toggled scenario mods while enforcing a single language mod. `ReconcileActiveModset` compares live mods against `appliedFingerprint` and clears `isActive` on mismatch — hand-editing your mod selection silently drops you out of the modset. UI: `ModManagerPanel` gains the full create/rename/delete/add/remove surface, `mod-manager.xml` adds `ModsetItemToggle`, `ModsetAddDropdown`, `ModsetAddDropdownChoice`, `ModsetModItem` templates and a `POPUP_INPUT_MM_MODSET` popup, `text-ui.xml` adds 23 `TEXT_UI_MODS_MODSET_*`/`TEXT_UI_MODS_PANEL_*` strings, and `ItemType` gains `MOD_MANAGER_MODSET_{TOGGLE,SELECT,REMOVE_MOD}`
- **Mod info parsing is now cached by file write time** — `ModPath` gains `private struct CachedModInfo { DateTime writeTimeUtc; ModInfo info; }` plus static `modInfoCache`/`internalModInfoCache` dictionaries; `GetInfoFromModPath` stats the file once and returns `value.info.Copy()` on a hit, delegating misses to new `ReadInfoFromModPath`/`ReadInfoFromInternalMod`. `ModInfo.Copy()` is new (`MemberwiseClone` plus fresh `modDependencies`/`modIncompatibilities`/`modWhitelist` lists)
- **`REMOVE`-mode XML fragments no longer require a file to load** — `ModPath.MergeXMLFragments` moves the whole `Resources.Load<TextAsset>`/`FileStream`/`XmlDocumentFragment` block inside `if (xmlFragmentMergeMode != XmlFragmentMergeMode.REMOVE)`, so a `Remove` fragment without a `File` element no longer hits the "Couldn't load XML fragment" error path
- **Mod list no longer rescanned every frame during init** — `ModManagerController.InitCoroutine` hoists `UpdateLocalModList()` out of its `while` loop and changes `yield return null` to a new `readonly WaitForSeconds initRetryDelay = new WaitForSeconds(1f)`
- **`LinkType` insertions renumber DLC help-link enums** — `HELP_TRADE_OUTPOST` (after `HELP_NEXT_DEVELOP`) and `HELP_SOURCE_ALL` (after `HELP_SOURCE_RESOURCES`) are inserted mid-enum, so every DLC `HelpText` subclass that anchors its private link enum to the end of `LinkType` shifts its base from `216` to `218`: `CalamitiesHelpText.CalamitiesLinkType`, `Egypt5HelpText.Egypt5LinkType`, `Greece4HelpText.Greece4LinkType`, `CarthageCampaignHelpText.CampaignLinkType`. Mechanical, but it moves the numeric values a mod would see
- **`WidgetData` gains a varargs constructor** — `public WidgetData(string zType, params string[] lzData)`, mirroring the existing `List<string>` overload

### Client & infrastructure

- **Per-player tech-path history recorded in saves for community analytics** — `Player.NetworkData` gains `SetList<(TechType, TechType)> msTechPathHistory` with a matching `DirtyType.msTechPathHistory` and `SimplifyIO.Data` branch in `Player.dirtyValuesIO`, plus three accessors `Player.recordTechPathHistory(TechType)`, `isTechPathHistory(TechType, TechType)`, and `makeTechPathHistory(TechType, TechType)`. `Player.makeTechAcquired` calls `recordTechPathHistory(eIndex)` inside its `bReset` branch, storing the chosen tech paired with each tech that was available but passed over. `Player.writeGameXML` emits a `<TechPathHistory>` element and `readGameXML` parses it back
- **Enum serialization switched from `Convert.ChangeType` to the non-boxing `CastTo<T>`** — `SimplifyIO.ConvertToInt<T>`, `SimplifyIO.ConvertFomInt<T>`, `BinaryReader.ConvertFomInt<T>`, and `DebugBinaryReader.Read<T>` all now use `CastTo<T>.From(…)`; `SimplifyIO` drops `using System.Globalization`. `CastTo.cs` itself is unchanged — it compiles an `Expression.ConvertChecked` lambda, so out-of-range values now throw `OverflowException` rather than going through `Convert`'s path. A new 217-line test file, `Reference/Source/Base/SystemCoreEditor/Editor/SimplifyIOEnumUnitTests.cs`, pins the wire format across the refactor: eight test enums covering every integral backing type, exact expected byte sequences captured from the previous implementation, container coverage for `T[]`/`List<T>`/`SetList<T>`/`DictionaryList<K,V>`/`List<(T1,T2)>`, and an `OutOfRangeEnumThrowsTest` asserting `Assert.Throws<OverflowException>`
- **Incoming network queues cleared at three more reset points** — `GameClientBehaviour` gains `ClearIncomingQueues()` (locking and clearing `incomingMessages`, the nested `incomingNetworkMessageBuffer`, `incomingReplay`, and `incomingMatchData`); two inline clear blocks now call it — note the disconnect path previously did *not* clear `incomingNetworkMessageBuffer` and now does — and three new calls were added in `ProcessMessages` before `SendClientGameReadyToServer()`: on the `!IsClientReceivingInitData()` path and both `"Network read error. Resetting connection."` catch blocks. `base.LocalGame.clearClientValues()` is now also called before `handleMessageClient(…)` in the queued-message path
- **New "Disable SRP Batcher" graphics option** — `miscOption.xml` adds `MISCOPTION_DISABLE_SRP_BATCHER` ("Only for troubleshooting"), `OptionType` gains `DISABLE_SRP_BATCHER`, `options-menu.xml` adds the checkbox, and `GraphicsOptionsSave` gains a serialized `disableSRPBatcher` whose `ApplyOptions()` sets `GraphicsSettings.useScriptableRenderPipelineBatching = !disableSRPBatcher`
- **History popup rework fixes stuck low-detail terrain** — `HistoryPopup`'s `IsVisible` setter body moves into `UpdateVisibility()`, which edge-triggers new `OnOpen()`/`OnClose()` against a `wasVisible` field; terrain handling moves into `LimitTerrainDetail()`/`RestoreTerrainDetail()` guarded by a new `isTerrainLimited` flag, so the restore path can only run when the limit was actually applied. `ClosePopup()` now also calls `OnClose()`, and `LateUpdate()` calls `RestoreTerrainDetail()` whenever not visible
- **Terrain texture renderer rendered nothing without a detail limit** — `TerrainTextureRenderer.RenderAllPendingCells()`: `if (num != -1)` → `if (maxDetailLevel != -1 && num != -1)`. With the default `maxDetailLevel = -1` the old code computed `Math.Min(-1 + 1, num) == 0` and skipped every detail level
- **Nested UI templates can no longer corrupt the caller's dictionaries** — `XmlInterfaceBuilder`'s template-instantiation path pairs the inherited `combinedTemplates` copy with a `HashSet<string> ownedTemplateObjects` and a `getWritableTemplateObject(string)` local that clones an inherited inner dictionary before the first write. Both write sites route through it, and the second's `Add` became an indexer assignment — a duplicate dotted attribute now overwrites instead of throwing `ArgumentException`
- **Tooltips force-unfrozen on start-screen navigation** — `UITooltipManager.UnfreezeTooltip()` changes from `private` to `public`, and `StartScreenUI` calls it just before `UI.PopupManager.CloseAll()` on screen change
- **Dead option bindings removed** — `DefaultUserInterface` drops the hard-coded `SetUIAttribute` calls for `Options-ShowSystemTime-IsOn`, `Options-FlipUnitColors-IsOn`, `Options-ShowRivalFamilyColors-IsOn`, and `Options-HideMovementSteps-IsOn` (and the `PlayerOptionsSave` local feeding them); none of those attribute names appear anywhere in `decompiled/`, `Reference/Source/`, or `Reference/XML/UI/` any more, superseded by the generic player-option list
- **Null guard on dirty-value tile refresh** — `Player.dirtyValuesIO` fetches `Unit pUnit = game().unit(unitID)` and only calls `makeTileDirty(pUnit.getTileID())` when `pUnit != null`
- **Razed-city assert removed** — `Tile.city()` drops its `MohawkAssert.Assert(pCity != null, "Unexpected null city - razed?")` and returns `game().city(getCityID())` directly

## 2026-07-01 Update (Update #148, v1.0.84044)

XML, Reference/Source C#, and decompiled changes across 39 XML files (84 modified, 222 added, 231 removed records — the add/remove counts are dominated by relocated help-text strings and new Empires of the Indus place-names), 26 Reference/Source C# files, and ~27 decompiled files. Highlights: a **renderer per-frame allocation memory-leak fix** (URP renderer-feature callbacks hoisted from per-frame closures to static functions), a broad **Influence Mission event rework** (rarer, retargeted, and softened negative outcomes), the **DOTA mapscript** rebuilt around Inner/Outer terrain split + a path-width option (Empires of the Indus), **Minor Cities reclassified as urban improvements**, **Christianity/Manichaeism tech-tree changes**, and three new options (**Map Search**, **Manual Bonus Placement**, **Disable Idle Animations**). Unity engine stays at 6000.3.15f1 (verified in `UnityPlayer.dylib`/asset bundle).

### Gameplay

- **Christianity loses its tech requirement; Manichaeism moves to Metaphysics** — `religion.xml`: `RELIGION_CHRISTIANITY` drops `RequiresTech TECH_METAPHYSICS`; `RELIGION_MANICHAEISM` `RequiresTech TECH_MONASTICISM→TECH_METAPHYSICS`
- **Minor Cities reclassified as urban improvements** — `improvement.xml`: `IMPROVEMENT_MINOR_CITY` `bUrban (absent)→1` (now counts toward urban-improvement ambitions). `Tile.makeUrban` is made idempotent (whole body wrapped in `if (!isUrban())`) and now calls `clearImprovementPings()` at the end
- **Tile-buying cost ramps more gradually** — `City.getBuyTileCost` returns `Math.Max(iCost, 1)` instead of `infos().utils().roundUp(iCost, 10)`, so purchase cost increments by 1 rather than jumping to the next multiple of 10
- **Drought no longer creates sand and ends sooner** — `occurrence.xml`: `OCCURRENCE_DROUGHT` removes `aaiTileTerrainChangeChance.TERRAIN_TARGET_ARID.TERRAIN_CHANGE_SAND 100` and `iMinDuration 3→2`; `OCCURRENCE_PLAGUE` `iEndChanceIncrement 5→10` (ends faster each turn) (Wrath of Gods)
- **Disciple and Brahmin vision buffs** — `unit.xml`: `UNIT_BUDDHISM_DISCIPLE` and `UNIT_HINDUISM_DISCIPLE` `iVision 3→4`; `effectUnit.xml`: `EFFECTUNIT_BRAHMIN` `iVisionExtra (absent)→1` (Empires of the Indus)
- **"Not Inclined to Marry" removes the leader flag** — `trait.xml`: `TRAIT_NOT_INCLINED_TO_MARRY` `bRemoveLeader (absent)→1`
- **City effects can be gated to a source trait** — new `InfoEffectCity.meSourceTrait` (replacing the removed `mSource` TextType); `Player.canEverHaveEffectCity` now returns false unless `game().checkGameContent(eSourceTrait)` passes and, for non-archetype traits, an active character actually has the trait (`character(iCharacterID).isTrait(eSourceTrait)`) — the data hook behind trait-sourced city effects only appearing when the player possesses the trait
- **Foreign-population governor penalty requires a real founder** — `City.calculateBaseYieldNetGovernor` adds `&& (getFirstPlayer() != PlayerType.NONE)`, so `miForeignPopulation` isn't applied to cities of neutral/free-city origin
- **Project-count cap scales with max count** — `Player.testProjectCount`: `iValue > getCityMax()` → `iValue > (getCityMax() * iMaxCount)`

### AI

- **AI no longer builds non-Settler growth units in empty cities** — `PlayerAI.unitValue`: when `infos.unit(eUnit).meProductionType == GROWTH_YIELD && !mbFound && pCity.getCitizens() == 0`, forces `iCityProduction = 0` ("let city grow so it can build specialists")
- **AI won't raze a city it founded itself** — `PlayerAI.doDecision` raze condition adds `&& (pCity.getFirstPlayer() != player.getPlayer())`
- **AI skips impossible tribe-diplomacy outcomes** — `PlayerAI.doTribeDiplomacy` now captures the result die (`int iResultDie`) and only evaluates a mission result when `iResultDie > 0`
- **Tribe-diplomacy bonus valuation rewritten** — `PlayerAI.bonusValue` replaces the `getTribeDiplomacy - eDiplomacyTribe` delta with an explicit peace/hostile accumulator (`+AI_DIPLOMACY_VALUE` on `diplomacy(eDiplomacyTribe).mbPeace`, `-` on its `mbHostile`, and the inverse on `tribeDiplomacy(eTribe, Team)`)
- **Mission yield-cost always subtracted** — `PlayerAI.missionValue` moves the `iTotalValue -= yieldValue(eYield) * getMissionCost(...)` loop out of the `if (iWeightSum > 0)` guard so cost is deducted even when the weight sum is non-positive
- **Flank-tile coverage test inverted** — `UnitRoleManager.assignUnitstoTarget` now marks a flank tile as needed when the unit *cannot* reach it: `if (AI.isMoveTile(pLoopUnit, pFlankTile.getID()))` → `if (!AI.isMoveTile(...))`
- **Bonus valuation prefers the tile's own city** — `Player.fillBonusValues`: `findClosestCity(pTile)` → `pTile.hasCityTerritory() ? pTile.cityTerritory() : findClosestCity(pTile)`
- **Achievement mode disabled in tiny games** — `Player.isAchievementGameMode` returns false when `game().getNumPlayersInt() <= 2`

### Maps & map generation

- **DOTA mapscript: Inner/Outer terrain split plus a path-width option** — `MapScriptDota` swaps its boundary-terrain and river-width options for inner-terrain, outer-terrain, and path-width multi-options (`mapOptionsMulti.xml` adds `MAP_OPTIONS_MULTI_DOTA_INNER_TERRAIN`, `_OUTER_TERRAIN`, `_PATH_WIDTH` and removes `_BOUNDARY_TERRAIN`/`_RIVER_WIDTH`; `mapOption.xml` adds `MAP_OPTION_PATH_NARROW`/`_WIDE` and `MAP_OPTION_TERRAIN_{INNER,OUTER}_{JUNGLE,MOUNTAINS,SAND,WATER,RANDOM}`, removing the old `MAP_OPTION_RIVER_*`/`MAP_OPTION_TERRAIN_*`). `MapScriptDota.GenerateLand` is rewritten: path half-width scales wide vs narrow (`Max(2, (MapHeight+MapWidth)/30)` vs `/60`), obstacle tiles are flood-filled into up to four connected regions each assigned inner (interior) or outer (edge) terrain, `RANDOM` regions pick among water/jungle/mountains/sand honoring `MirrorMap` symmetry, and at least one water section is guaranteed (Empires of the Indus)
- **Tribe placement reworked** — `DefaultMapScript`: only `mbOrganized` tribes are now pushed far from human starts — the loop pre-seeding every `ACTIVE_START` into `startSites` and the organized-first tiebreak in `TribeSiteValue.CompareTo` are removed, and the distance-from-`playerStarts` minimization in `PlaceTribes` is gated behind `if (updateValue.organized)`; `getSiteTribeValues` raises the preferred-terrain bonus (`++tribeValue` → `tribeValue += 2`) and adds `tribeValue += 4` for organized tribes (covers the Huns spawn-location fix)
- **Mirror-map option hidden where disallowed** — `StartScreenController.SetDefaultMapScriptOptions` now also filters out `MIRROR_MAP_OPTION` when `!mapClass.mbAllowMirror` (decompiled)

### Events & characters

- **Influence Mission events — new "appoint officer + influence" bonuses** — `bonus-event.xml` adds `BONUS_AMBASSADOR_AND_INFLUENCE`, `BONUS_CHANCELLOR_AND_INFLUENCE`, and `BONUS_SPYMASTER_AND_INFLUENCE`, each pairing a make-officer bonus with `BONUS_LEADER_INFLUENCED_BY` (note: `BONUS_SPYMASTER_AND_INFLUENCE` references `BONUS_MAKE_AMBASSADOR`, not `BONUS_MAKE_SPYMASTER`). `eventOption.xml` rewires `EVENTOPTION_INFLUENCE_OF_COUNCIL_{AMBASSADOR,CHANCELLOR,SPYMASTER}_OPTION_0` `aeBonuses[1]` to the new records, so appointing an officer via these options now also applies leader influence
- **Influence events made rarer and retargeted** — `eventStory.xml` raises `iWeight` on six Influence records (`EVENTSTORY_INFLUENCE_A_DEADLY_REQUEST`/`_LOCAL_AUTHORITY`/`_UNEARTHED` and `_REJECTION_OF_INFLUENCE` to `12`, `_DISTASTEFUL`/`_THE_TRIBE_UNLEASHED` to `6`) and drops the flat `iProb 50` from `_THE_TRIBE_UNLEASHED` and `_UNEARTHED`; subject requirements are retargeted toward `SUBJECT_CURSED` characters. Negative option outcomes are softened: `EVENTOPTION_INFLUENCE_DISTASTEFUL_OPTION_1` `BONUS_LEADER_ENDEARED_TO→BONUS_INFLUENCED_OR_ESTRANGED`, and `EVENTOPTION_INFLUENCE_UNEARTHED_OPTION_1` drops its `BONUS_ORDERS_LOSS_SMALL`
- **Influence-mission completion no longer fires two events** — `EVENTSTORY_LEADER_TWILIGHT_YEARS` (base) and `EVENTSTORY_ACIDIC` (Behind the Throne) drop `Trigger EVENTTRIGGER_MISSION_FINISHED` / `TriggerData MISSIONRESULT_INFLUENCE_EVENT`
- **Intercession events get a 30-turn cooldown** — eight `EVENTSTORY_INTERCESSION_*` records (`CONFUSION`, `EXILE`, `FAMILY_UNITED`, `FEAST`, `GREED`, `NEW_LOVE`, `PARRICIDE`, `SACRIFICE`) `iRepeatTurns 0→30`
- **Agent Recognized reworked** — `eventStory.xml`: `EVENTSTORY_AGENT_RECOGNIZED` drops `iProb 20`, `iWeight 1→6`; `eventOption.xml`: `EVENTOPTION_AGENT_RECOGNIZED_0` lowers the charisma bar (`SUBJECT_HIGH_CHARISMA→SUBJECT_SOME_CHARISMA`) and `_1` adds `BONUS_XP_CHARACTER_AVERAGE`
- **Tutorial Marriage gains a spouse subject** — `EVENTSTORY_TUTORIAL_MARRIAGE` adds `aeSubjects[1] SUBJECT_SPOUSE_OF_LEADER_US` and `iTriggerExtra 1`
- **Behind the Throne / Sacred and the Profane event tuning** — several `-btt`/`-sap` events swap a flat `iProb`/`iMaxTurns` for a per-game `iGameProb` roll (`EVENTSTORY_RISING_MERCENARY 40`, `_ROYAL_PREROGATIVE 50`, `_THEY_MUST_DIE 50`, `_PLAYING_WITH_FIRE_SETUP 20`; `-sap` `EVENTSTORY_A_POETESS_IN_EXILE 40`). `-btt` adds `bonus-event-btt.xml` `BONUS_ZENOBIA_IS_JUDGING_YOU` (grants Rising Star + Judge archetype), wired into `EVENTOPTION_CITY_AUTONOMY_EMPRESS_1_NEW`. `-sap` `EVENTSTORY_FUNERARY_GAMES` fixes an `Achilles'→Achilles's` `zEventURL` typo, and `EVENTSTORY_THE_FORGOTTEN_PROPHET` plus its three `EVENTLINK_THE_FORGOTTEN_PROPHET_*` become two-subject (`iNumSubjects 1→2`)
- **Empires of the Indus wonder events ignore trigger probability** — `eventStory-eoti.xml`: `EVENTSTORY_WONDER_{HILL_FORT,MAHAVIHARA,MONUMENTAL_BUDDHAS,STUPA}` `bIgnoreTriggerProb (absent)→1`

### UI

- **New Map Search UI** — `text-ui.xml` adds `TEXT_UI_MAPSEARCH_*` (city name, improvement type/wonder, resource all/improved/unimproved, unit type/promotion, results) and `text-helptext.xml` the matching `TEXT_HELPTEXT_MAPSEARCH_{CITY,IMPROVEMENT,RESOURCE,UNIT}` — search the map by city name, improvement/wonder, resource, or unit type/promotion
- **New "Manual Bonus Placement" player option** — `text-playerOption.xml` adds `TEXT_PLAYEROPTION_MANUAL_BONUS_PLACEMENT` (+`_DESC`, "Automatically enter bonus placement mode without popup prompt")
- **New "Disable Idle Animations" option** — `text-miscOptions.xml` adds `TEXT_MISCOPTION_DISABLE_IDLE_ANIMATIONS_NAME` and `_DESC` ("Pauses animations for idle units, improvements, and resources")
- **Military unit yields always shown in help text** — new `InfoHelpers.getUnitYieldCost(eUnit, aiCosts)`; `HelpText.buildUnitTypeHelp` now builds the yield-cost dictionary even without a player/city (relaxing `if (production != null && pActivePlayer != null)` to `if (production != null)`) and always calls `buildYieldCostText`
- **Mission-blocking memory shows remaining turns** — `HelpText.buildWidgetHelp` appends the blocking-memory link plus `buildTurnsTextVariable(iTurns - (pGame.getTurn() - pLoopData.miTurn), pGame)` when a subject has `meMemoryInvalid != MemoryType.NONE`
- **Law event prerequisites read as "active law"** — `HelpText.buildEventStoryPrereqsHelper` wraps the law link in `TEXT_HELPTEXT_EVENT_ACTIVE_LAW` and inverts the `SubjectNotExtras` warnings via `InvertWarningsScope`
- **Victory points hidden when points victory inactive** — `HelpText.buildVPLinkVariable` only emits the count/needed slash text inside `if (pGame.isVictoryActive(POINTS_VICTORY) && iPointsNeeded > 0)`, otherwise returns just the team's VP count
- **Tribal Invasion help mentions the war declaration** — `HelpText.buildBonusHelp` `mbTribeInvade` branch adds a `WAR_DIPLOMACY` hostility line (`TEXT_HELPTEXT_BONUS_TRIBE_DIPLOMACY_HOSTILE_TO`) and a `buildTribeCancelledTributeHelp` call
- **Landmark discovery is always logged** — `Tile.makeRevealed` now always calls `pPlayer.pushLogData(...)` for the reveal / named-landmark bonus (previously only when reveal popups were hidden), so a discovered landmark shows in the log even when a popup is shown
- **Occurrence turn summary is scoped to the affected player and names the nation** — `Game.doAllOccurrenceEffects` adds a nation-link argument (`buildNationLinkVariable(...)`, else `CONCEPT_NEUTRAL`) to the tile add/change log text and gates `pPlayer.addTurnSummary(...)` on `eLoopPlayer == ePlayer`
- **Foreign event-start tooltip names the city** — `text-ui.xml`: `TEXT_UI_EVENT_STORY_X_STARTED_FOREIGN` "Started in {TRIGGER-1}" → "Started in {CITY-1}"
- **World Religions help text lists Buddhism** — `text-helptext.xml`: `TEXT_HELPTEXT_LINK_HELP_WORLD_RELIGION` now reads "The World Religions (Judaism, Zoroastrianism, Christianity, Manichaeism, and Buddhism)" (text correction; `religion.xml` classification unchanged)
- **New Empires of the Indus place-names** — `text-mapElementNames.xml` adds regional names (`TEXT_HIMALAYAS`, `TEXT_THE_INDUS`, `TEXT_WESTERN_GHATS`, `TEXT_KALINGA`, `TEXT_SOGDIA`, …)
- **Help-text overlay records relocated** — `text-change.xml` drops ~37 records — overwhelmingly `TEXT_HELPTEXT_EVENT_REQUIRES_*` strings plus the two `TEXT_HELPTEXT_EFFECT_UNIT_HELP_PUSH*` — as they move into the base `text-helptext.xml`, which also adds new trade-modifier (`TEXT_HELPTEXT_*_TRADE_MODIFIERS*`) and occurrence-duration (`TEXT_HELPTEXT_OCCURRENCE_{CURRENT,MIN}_DURATION`) help strings
- **Governor yield-modifier help respects the base yield's sign** — `HelpText.buildRatingHelp` and `buildCityGovernorHelp` change `infos().utils().modify(iYield, iModifier)` to `... iModifier * Math.Sign(iYield)`
- **City-widget religion list rebuilt as structured sub-tags** — `ClientUI.updateCityWidget` emits per-religion `widgetAttribute.GetSubTag("-Religion", n)` entries (Icon / IconColor / Data) with `SetInt("NumReligions", ...)` instead of a concatenated `ReligionList` string
- **Localization comma-parse fix** — `HelpText.needs` builds the event sub-prereq variable with a literal comma join instead of the `ScopeType.COMMA` builder, whose `TEXT_HELPTEXT_COMMA_SPACE_TWO` (Japanese ideographic comma) broke the `is_sub` predicate parser

### Client & infrastructure

- **Renderer per-frame allocation memory leak fixed** — across five URP renderer-feature files (`AmplifyOcclusionRendererFeature`, `BlurScreenRendererFeature`, `GlobalKeywordRendererFeature`, `RenderUnitBannerIconsRendererFeature`, `DrawGrabPassMeshRendererFeature`), the `SetRenderFunc` render callbacks became `static` methods that read state from a pooled `PassData` (new fields such as `PassData.pass`, `blurMaterial`/`blurData`, `keywords`, `cameraData`, `renderer`) instead of capturing `this`/locals in a fresh closure every `RecordRenderGraph`; `DrawGrabPassMeshRendererFeature.DrawMeshPass` also drops a per-frame `"DrawMeshPass: " + sourceObject.gameObject.name` string concat (now the literal `"DrawMeshPass:"`), and all eight passes are wrapped in `UnityProfileScope` instrumentation. On the client side, `ClientRenderer.drawTile` defers the per-tile camera-bounds work into a new `addTileToScrollBounds(Tile)` called only when `isTileInScrollBounds(...)` (decompiled Assembly-CSharp plus `Reference/Source` `ClientRenderer.cs`)
- **Terrain can blacklist mountain rendering per height** — new `InfoTerrain.maeMountainRendererBlacklist` (XML key `aeMountainRendererBlacklist`); `MountainRenderer.MountainGroup.Initialize` and `IsMountain` skip blacklisted heights. `terrain.xml`: `TERRAIN_SAND` adds `aeMountainRendererBlacklist[0] HEIGHT_HILL` (keeps sand hills flat, tied to Drought no longer sanding tiles). `MountainRenderer.UpdateTile` also forces a re-render for tiles with asset overrides (decompiled)
- **Observer-mode visibility fixes** — `ClientManager.switchActivePlayer` reveals the map via `Renderer.setRevealMap(activePlayer().isSurrendered() || activePlayer().isDead())` while observing; `ClientRenderer.isTileInScrollBounds` keeps `HIDDEN` tiles in bounds once `Game.isGameOver()`; `TileEffectCollection.Synchronize` uses `game.getCurrentPlayerTurnTeam()` instead of hardcoded team 0; `Game.dirtyValuesIO` calls `makeAllTilesDirty()` on single-player game-over (decompiled + `Reference/Source`)
- **Victory checks split into conquest and time/points** — `Game.checkVictory` separates the `mbConquest` check from the `miMinTurns` (time/points) check and adds a margin to the min-turn gate: `getTurn() < victory.miMinTurns` → `100 * getTurn() < (100 - iMarginPercent) * victory.miMinTurns`
- **Hotseat game-over guard** — `Game.updateServer` adds an `isMultiplayerHotseat()` branch that keeps the game running (`bGameOverAndDone = false`) while a current player `isAlive()` and still `hasDecisions()`
- **Tribe dead-state update relocated** — moved out of `Game.removeUnit` and into `Unit.kill`, which now runs `if (isTribe()) { game().tribe(getTribe()).updateDead(true); }` after `sendUnitFullState`
- **Spread-religion trigger gated to harvest units** — `UnitObject.PlayUnitChangeVegetation` only fires `SPREAD_RELIGION_TRIGGER_HASH` when `Infos.unit(unitType).mbHarvest` (previously unconditional) (decompiled)
- **`Tile.canHaveImprovement` parameter order changed** (modding) — `bTestEnabled` now precedes `bTestTerritory`; call sites updated to named args across `Player.canStartImprovementOnTile`, `PlayerAI.isImprovementOutOfPlace`/`calculateImprovementValueForTile`, `ClientUI.GetValidImprovementsForTile` (which additionally now passes `bTestEnabled: false` when listing valid worker improvements), and `CarthageCampaignGame` (decompiled). Signature-only for modders Harmony-patching this method
- **Removed `[Rec]` recommendation-timing debug instrumentation** — `ClientUI` drops the static `sRecLogStopwatch` field and the `logRec`/`recNow` helpers along with every call site (the diagnostics that shipped with #147's worker-recommendation overhaul, spanning `updateDirty`, `updateTileWidgets`, `updateWorkerActions`, `updateCityBestBuilds*`, `updateBestBuilds*`, `ShowChooseResearchPopup`); `ClientManager.sendAction` drops its `[Rec] sendAction` `Debug.Log`

## 2026-06-03 Update (Update #147, v1.0.83788)

XML, Reference/Source C#, and decompiled changes across 39 XML files (263 modified, 44 added, 5 removed records), 38 Reference/Source C# files, and ~45 decompiled files. Highlights: a new **Competitive AI** aggression tier (behaviors moved down from Ruthless), a late-game worker-recommendation perf overhaul, a client-wide send-action refactor (every action send now returns success and callers gate local state on it), critical-hit timing rework, mirror-map start/tribe placement fixes, leader death immunity moved to `mortality.xml`, and 1-tile mountain-pass smoothing. Unity engine updated to 6000.3.15f1 (verified in `UnityPlayer.dylib`/asset bundle).

### Gameplay

- **2nd tier tech costs 150 → 160** — `tech.xml`: `TECH_ARISTOCRACY`, `TECH_DRAMA`, `TECH_HUSBANDRY`, `TECH_LABOR_FORCE`, `TECH_MILITARY_DRILL`, `TECH_POLIS`, `TECH_RHETORIC` all `iCost 150→160`; their half-cost bonus variants (`TECH_ARISTOCRACY_BONUS_BORDERS`, `TECH_DRAMA_BONUS_SETTLER`, `TECH_HUSBANDRY_BONUS_FOOD`) `75→80`
- **Free Horseman card moved to Coinage** — `TECH_STIRRUPS_BONUS_HORSEMAN` `abTechPrereq` swaps `TECH_LAND_CONSOLIDATION → TECH_COINAGE`
- **Improvement wood cost cuts** — `aiYieldCost.YIELD_WOOD`: `IMPROVEMENT_HARBOR 60→40`, `IMPROVEMENT_MARKET_1 80→60` (Market), `MARKET_2 100→80` (Grocer), `MARKET_3 120→100` (Fair). `GOAL_FOUR_MARKET_1` retiered `iMinTier 2→3`, `iMaxTier 3→4`
- **Difficulty achievements cascade downward** — `Player.isAchievementComplete` (PlayerGoal.cs): `getDifficultyMode() != eDifficulty` → `< eDifficulty`, so winning at a higher difficulty grants all lower-difficulty achievements
- **Invested tech progress reimbursed** — `Player.addFreeTech` refunds `getTechProgress(eBestTech)` to the science stockpile before `makeTechAcquired`; new loop at top of `Player.doResearch` also refunds progress on any tech that became invalid (`!isTechValid(eTech, true)`) and clears research if it was the active tech
- **Leader death immunity now per-mortality** — `mortality.xml` gains `iInitLeaderSafeTurns`: `MORTALITY_LONG` 30, `MORTALITY_STANDARD` 20, `MORTALITY_REALISTIC` 10. The `INIT_LEADER_SAFE_TURNS` global (20) is removed from `globalsInt.xml` and `InfoGlobals`; `Character.checkDeathTrait` reads `infos().mortality(game().getMortality()).miInitLeaderSafeTurns`. New `InfoMortality.miInitLeaderSafeTurns` field
- **Jungle/unlock vegetation cutting requires city territory** — `Tile.canRemoveVegetation`: new `if (!hasCityTerritory()) return false;` for `mbRequiresUnlock` vegetation; `Tile.canHaveImprovement` now returns false outright on null `pCityTerritory`. HelpText (`buildTileTooltip`, `buildImprovementRequiresHelp`, `buildWidgetHelp`) adds a "requires territory" line via `CONCEPT_TERRITORY`; new `TEXT_HELPTEXT_UNIT_TYPE_CAN_CHOP_TERRITORY`
- **Workers can't stack in teammates' territory** — `Player.isMultipleWorkersUnlock` gains a `Tile pTile = null` first param and returns false when `pTile.hasOwner() && pTile.getOwner() != getPlayer()`. Caller cluster passes the tile: `Tile.canBothUnitsOccupy`, `UnitAI.doHelpImprove`, `PlayerAI.getBestTileImprovementHelper`/`canSetMoveTarget`, `ClientUI.updateTileWidget`, `HelpText.Game.buildTileTooltip`
- **Tight turn style blocks all military actions** — `Unit.canUseUnitTurn` param renamed `bAttackOrMove → bMilitaryAction` and body collapsed to a single `bMilitaryAction ? turnStyle().mbNoMilitary : turnStyle().mbNoBuild` check; military gating is now keyed off `canDamage()` instead of unit cycle group. `Unit.canUseUnit` drops its `bool bAttackOrMove` param entirely — caller cluster drops the arg across Unit.cs (6 sites), `Game.handleAction` (4 sites), `ClientRenderer.drawTilePathFromTile`/`drawTileOverlays`, `ClientSelection.shouldSkipUnitSelection` (the `bIdleOnly` check), `ClientUI.updateCursorType`/`updateTileWidget`, and `Greece1Game.isPersianStandoff`. `HelpText.Game.buildTurnStyleHelp` drops its `bNetwork` param and the no-undo footnote
- **Eagle Eye reaches non-fixed range-1 units** — `Game.isEffectUnitValid`: `miRangeMax == 1` → `(miRangeMax == 1 && mbRangeFlat)`, so range-1 units without fixed range (Persian UUs) are no longer excluded. New `TEXT_HELPTEXT_RANGE_FIXED` string; `HelpText.Unit.buildUnitTypeHelp` shows "Fixed Range" when `mbRangeFlat`
- **Rebels avoid teammates** — `UnitAI.isLowPriorityAttack` reworked from `TeamType` to `PlayerType`: rebel check is now player-based (`unit.getRebelPlayer() != eOtherPlayer && unit.rebelPlayer().isAlive()`). Callers pass players instead of teams (`pickTribeAttackTarget` ×2, unit/tile overloads, `pickTribePillageTile`, `PlayerAI.addTileDanger`)
- **Converted-tribe barbarians become raiders** — `Tile.doTribeTurn`: per-unit conversion now computes `findBestRaidCity(eNewTribe)` and calls `pLoopUnit.convertToRaider(pRaidCity.getTeam())` when found; the old create-copy-kill path only runs as fallback
- **Per-game fixed event probability** — new `InfoEventStory.miGameProb` (`iGameProb`); `Player.canDoEventStory` (PlayerEvent.cs) rolls a seed-stable `RandomStruct(game().getFirstSeed() + (ulong)eEventStory)` so an event can be gated on/off for an entire game
- **Effect-city per-improvement yields** — `City.getEffectCityYieldRate` adds a loop over `maaiImprovementYield` crediting `iLoopYield * getImprovementCount(eLoopImprovement)`
- **Stun folded into Tactician Leader** — `effectUnit.xml`: `EFFECTUNIT_STUN` record removed; `bStun 1` set directly on `EFFECTUNIT_TACTICIAN_LEADER` (its `aeEffectUnitUnlock` entry dropped). `EFFECTUNIT_LEADER_EXPLORER`/`EFFECTUNIT_LEADER_GENERAL` immunity lists swap `EFFECTUNIT_STUN → EFFECTUNIT_TACTICIAN_LEADER` (fixes the duplicated Tactician Leader General icon)
- **Charge no longer blocked by terrain type** — `EFFECTUNIT_CHARGE` `aiMeleeToClearTerrainTargetModifier` retargets `TERRAIN_TARGET_OPEN` (50) → new `terrainTarget.xml` record `TERRAIN_TARGET_BARE` (50, vegetation NONE) (Yuezhi UU, Empires of the Indus)
- **Ranger leader works in Jungle** — `EFFECTUNIT_RANGER_ALL` gains `aiVegetationFromModifier.VEGETATION_JUNGLE: 10`
- **Base-game Plague no longer eats citizens** — `bonus-event-wog.xml` removes `BONUS_PLAGUE_START` (carried `BONUS_LOSE_CITIZEN_1`); `OCCURRENCE_PLAGUE` `StartBonus` cleared (Wrath of Gods)
- **Lumbermills on Ebony give full Wood** — `IMPROVEMENT_LUMBERMILL` drops `abNoBaseOutput.RESOURCE_EBONY` (Empires of the Indus)
- **Tamilakam Supremacy rework** — `eventStory-eoti.xml` `EVENTSTORY_COALITION_FAMILY_RISING`/`_LEADER_SAME`/`_RIGHTFUL_HEIR`/`_UPSTART`: rebel option drops `BONUS_REBEL_UNITS_3 → BONUS_REBEL_UNITS_1` and new culture-gated options keyed on `SUBJECT_CITY_CULTURE_WEAK/DEVELOPING/STRONG/LEGENDARY` (family seat) grant `BONUS_REBEL_UNITS_1/2/3/4` — rebels scale with family-seat culture. `_RIGHTFUL_HEIR`/`_UPSTART` add `bIgnoreOptions` and the new-leader option now chains `BONUS_MAKE_ROYAL` + new `BONUS_XP_CHARACTER_HUGE` (`iXPCharacter 150`) — new leader gets XP and becomes Royal. Companion C# helper `InfoHelpers.getCultureNumber` (culture ordinal by threshold); `PlayerAI.calculateEffectCityValue` switches to it
- **DOTA maps drop marsh** — `MapScriptDota.GenerateLand`: `LockTileTerrain(tile, WET_TERRAIN)` removed (flat-height lock retained) (Empires of the Indus)
- **Hotseat games send turn emails** — `Game.shouldSendEmail` adds `|| getGameMode() == GameModeType.HOTSEAT`

### Combat

- **Critical hit rolled once per turn / after attack** — crit re-rolls removed from state-change paths: `Unit.setGeneralID` (drops the whole `iDeltaCriticalChance` accumulator), `Unit.setNextCriticalModifier`, `Unit.changeEffectUnitDictionary`, and `Character.setRating` (general-rating crit reset deleted). `Unit.attackTile` now calls `resetCriticalHit()` immediately after reading `isCriticalHit()` under `GAMEOPTION_CRITICAL_HIT_PREVIEW` — also the fix for crits not occurring during routs with the preview option on

### AI

- **Competitive AI aggression tier** — new `InfoOpponentLevel.mbCompetitive` (`bCompetitive`), set on `OPPONENTLEVEL_COMPETITIVE`. Behavior moved from the `GAMEOPTION_PLAY_TO_WIN` (Ruthless) check to `opponentLevel().mbCompetitive` across `PlayerAI.shouldRespectCitySiteOwnership`, `shouldClaimCitySite`, `getNoWonderTurns`, `getNoReligionTurns`, `getTruceOfferPercent` (no truce when about to capture a city), and `UnitRoleManager.assignUnitRoles` (citysite guards); `PlayerAI.effectPlayerValue` VP valuation broadened to `PLAY_TO_WIN || mbCompetitive`. New `CONCEPT_COMPETITIVE_AI` ("Cutthroat AI Tactics") + helptext + gendered text; `HelpText.Game.buildOpponentLevelHelp` links it when `mbCompetitive`
- **Late-game worker recommendation lag overhaul** — new `ClientUI` throttle/abort infrastructure: `notifySendAction`, `delayWorkerRecommendation` (`WORKER_RECOMMENDATION_DELAY_SECONDS = 1.3`), `cancelRecommendationCache` (abort generation counter `miAbortGeneration`), `cancelImprovementPreview`, `clearWorkerRecommendationWidgets`, pending-city queue `miPendingCityBuildUpdates` drained one per pass when no AI task in flight (`miAITaskInFlight`), and recommendations gated to turns > `RECOMMENDATION_GATE_MIN_TURN` (50). A `Func<bool> abortCheck` param is threaded through `PlayerAI.cacheCityImprovementValues` (6 early-out checkpoints), `PlayerAI.getBestCityImprovements`, and `UnitRoleManager.getBestCityImprovements` so in-flight caching aborts when selection changes. `ClientUI.updateTileWidgets` only consumes cached recommendations matching the current worker/city selection; re-selecting a build worker clears stale widgets (`ClientSelection.updateUnitUI`). Note: extensive `[Rec]` `UnityEngine.Debug.Log`/`logRec` diagnostics shipped in this path
- **AI engineer-general road building fixed** — best-road-tile cache moved from `UnitRoleManager.mmapBestRoadTiles` into `PlayerCache` (new `setBestRoadTile`/`getBestRoadTile`/`clearBestRoadTiles`); `UnitRoleManager.calculateBestRoadTile` adds an already-`isRoad()` early-out, gates candidates on `AI.isCityReachable`, and caps both candidate loops at `iMaxCityTries = 4`; `UnitAI.isUnitValidPriority` now returns true for `unit.isRoadBuilder()` in the Improve branch
- **AI ship anchoring** — `globalsAI.xml` `AI_MAX_WATER_CONTROL_DISTANCE 10 → 20` (anchor range to bridge lands doubled). `UnitRoleManager.assignWaterControlUnits` rewritten to greedily assign the unit covering the most uncontrolled water targets (`assignBestWaterControlTarget` + factored `isValidTarget`, new `isWaterControl(int)` helper); `updateWaterControlTiles` calls switch from `AI.Team` to `TeamType.NONE` (team-agnostic coverage)
- **Misc AI** — `PlayerAI.updateCityTiles` impassable check via `CurrentData.isImpassable(infos)`; `UnitRoleManager.findBestRoadTiles` restructured around a `hasRoadBuilderAvailable()` local

### Maps & map generation

- **1-tile mountain passes widened** — new ~140-line `DefaultMapScript.RemoveSingleTileMountainPasses` (called from `Build` after `SetBoundaryTiles`): detects passable tiles with multiple adjacent passes through mountain/boundary blockers and smooths the offending mountains to `HILL_HEIGHT` (mirroring via `copyTileData` on mirror maps, honoring height/terrain locks) — also covers "unintended 1-tile-wide mountain passes in mirror maps"
- **Mirror maps enforce connected human starts** — `DefaultMapScript.ConnectedHumanStarts` getter drops its `if (MirrorMap) return false;` early-out
- **Mirror player-start placement can fail and retry** — `MirrorPlayerStarts` now returns `bool` (validates via `IsValidPlayerLandArea`, uses new `RemovePlayerStart(tileID)` helper); `AddPlayerStarts` propagates the failure; `AddCities` early-returns on it; `MapBuilder.buildMap` reseeds (`ulMapSeed = pGame.nextSeed()`) on each failed build attempt
- **Organized tribes placed farther from humans, mirrored on mirror maps** — `TribeSiteValue` gains `organized` (sorted first, "as far as possible to player starts"); `PlaceTribes` factors `playerStarts` into `distanceFromOther` and mirrors organized-tribe sites via `getSymmetricTileId` (The Huns / Empires of the Indus)

### Events & characters

- **Camera-focus metadata mass-add** — explicit `iLookAtSubject` added to ~220 `EVENTSTORY_*` records across `eventStory.xml` (169), `eventStory-sap.xml` (33), `eventStory-btt.xml` (13), and `eventStory-eoti.xml` (mostly `0`, some 1–8); `EVENTSTORY_GROWING_THIRST` `1→0`
- **Question Authority rewired** — `EVENTSTORY_TRAIT_QUESTION_AUTHORITY` `SubjectExtras` now require `SUBJECT_GENERAL` + `SUBJECT_COMPASSIONATE` + new `subject.xml` record `SUBJECT_LEADER_US_5_UNITS_LOST` (leader, `STAT_UNIT_LOST` ≥ 5), dropping `SUBJECT_PLAYER_5_UNITS_LOST`
- **SubjectAny trait check fixed** — `Player.isValidEventSubjectCharacter` (PlayerEvent.cs): removed the `else { bTrait = false; break; }` clobber so one matching trait satisfies the check
- **Zenobia is a Diplomat** — `CHARACTER_ZENOBIA` `aeTraits[0]` `TRAIT_JUDGE_ARCHETYPE → TRAIT_DIPLOMAT_ARCHETYPE`
- **Gudit's Intimidate gated to leader** — `MISSION_INTIMIDATE` gains `aeSubjectCharacterOn[0]: SUBJECT_LEADER_US` (Wonders and Dynasties)
- **Hurricane grove variants completed** — `asset.xml`/`assetVariation.xml` add Citrus/Honey/Incense/Lavender/Olive/Wine hurricane grove assets; `TILEVISUALEFFECT_HURRICANE_REPLACE_GROVE`/`_RESOURCES` in `tileVisualEffectComponent-wog.xml` extended/reindexed accordingly
- **2026 Community Tournament** — new `TOURNAMENT_ANNOUNCEMENT` record; `text-announcements.xml` swaps the 2025-H2 strings for `TEXT_COMMUNITY_TOURNAMENT_2026` (Season 3, registration through June 30 2026)

### UI

- **Map search toggle vs tab panel** — new `ItemType.MAP_SEARCH_TOGGLE`; `ClientUI.doWidgetAction` flips `mbMapSearchActive` and `updateTabPanelState` suppresses tab highlight while search is open (tab-open checks gain `&& !mbMapSearchActive`)
- **Tech tab overlay state persists** — `ClientUI.SetCurrentTabOverlay` now saves `mLastTechsOverlayState`; TECH_TREE/DISCARDED_TECH widget actions restore it instead of hardcoding `TabOverlayState.TECHS`; `mTechScreenButton` field removed
- **Send Luxury tooltip rebuilt** — `HelpText.Widget.buildWidgetHelp` luxury-trade branch: per-yield COMMA sub-list via `getEffectCityYieldRate`, opinion blocks reworked around `TEXT_HELPTEXT_OPINION_COLON` with family/tribe/player links
- **Add Urban button hides Orders cost** — `HelpText.Game.buildAddUrbanText` drops `addYieldCost(ORDERS_YIELD, UNIT_ADD_URBAN_COST)`
- **Tribe opinion rate shown at zero modifiers** — `ClientUI.updateTribePanel`: new `hasOpinion` flag true when the tribe leader's `calculateCharacterOpinionRate` has a value, decoupled from `iOpinionRate.HasValue`
- **Stats screen always shows totals** — `StatsPopup`: dropped the `num3 > 0` guard on the totals row; totals label now takes a player-count arg (`TEXT_HELPTEXT_TOTALS`, also added to `text-change.xml`)
- **City widget occlusion** — `ClientUI.updateCityWidget` sets `ASSET_CITYWIDGET_BASE_MATERIAL` up-front in the revealed branch and computes the mouseover tile earlier (city widgets occluded by clouds/geometry; units partially occluding selected widgets)
- **Event helptext negation (`bNot`) propagation** — `HelpText.Event.buildOccurrenceSubjectPrereqs` gains `bool bNot`; `buildEventStorySubjectPrereqs` threads `bNot` into player/any-family/occurrence/character/any-character prereq builders; three `TEXTVAR(bNot)` flips to `TEXTVAR(!bNot)`; `SubjectNotExtras` scope `NOT_COMMA_AND → COMMA_AND` (fixes SubjectNot display, TraitInvalid subjects, `aeRelationshipNone` subjects). New `TEXT_HELPTEXT_EVENT_REQUIRES_OCCURRENCE_ACTIVE`
- **Religion help split name/details** — `HelpText.Game.buildReligionHelp` gains `bool bDetails = true` wrapping the team-religion details block; `HelpText.Link.buildLinkHelp` passes `bDetails: (pCity == null)`; `CalamitiesHelpText.buildReligionHelp` override synced (decompiled)
- **Improvement requires-help defaults to active player** — `HelpText.Improvement.buildImprovementRequiresHelp`: `pTile != null ? pTile.owner() : null` → `: pActivePlayer` (tech requirement sometimes missing from improvement helptext)
- **Tribal peace helptext token fix** — `TEXT_HELPTEXT_WIDGET_MAKE_DECISION_OFFER_PEACE_TRIBE` `{0_barbarian} → {1_barbarian}` (no-characters mode)
- **Family tree shows coalition royals** — `FamilyTreePanel` (decompiled): when the player's nation is `mbCoalition`, royal active characters not already in the tree get `GetCharacterRoots` entries (Tamilakam family tree after Supremacy leader changes)

### Client & infrastructure

- **Send-action refactor: every action send reports success** — `Game.sendActionToServer` `void → bool` (early-false when `!manager().canDoAction`); `ClientManager.sendAction` and all ~190 `sendXxx` wrappers `void → bool`; `sendAction` also calls `UI?.notifySendAction()` / `delayWorkerRecommendation()` / `cancelRecommendationCache()` / `cancelImprovementPreview()` before dispatch. Caller cluster across `ClientInput`/`ClientSelection`/`ClientUI` wraps follow-up local state changes (unit cycling, cache clears, popups) in `if (ClientMgr.sendXxx(...))` — the client no longer advances state when the server rejects an action. `LearnToPlay1/2ClientManager.sendAction` overrides synced. Play-by-cloud: `GameClientBehaviour` only persists `DefaultPlayerEmail` when `sendPlayerInformation` returns true (emails with incorrect information)
- **Game log gains structured 4th data slot** — `GameLogData` gains `mzData4` (ctor param, `SimplifyIO.Data`, `Data4` XML element — save-format change). `Player.pushLogData` overloads updated + new 4-arg generic; new `Player.pushUnitLogData(Func<string>, GameLogType, Tile, Unit, Tile)` helper logs attacker nation/tribe as data; `Unit.attackTile` defender logs switch to it. `Player.getCurrentTurnLogText` attack tallies now parse `mzData4` via `getTypeFromSave<NationType/TribeType/OccurrenceType>` instead of substring-matching localized text. `Greece5Player.pushLogData` override synced
- **Two action types removed** — `ActionType.SAW_TECH_DISCOVERED` and `ActionType.PLAYER_LOG` deleted (Enums.cs + `Game.handleAction` cases + `ClientManager.sendSawTechDiscovered`/`sendPlayerLogData`); `ClientManager.canDoAction` PLAY_BY_CLOUD block swaps `SAW_TECH_DISCOVERED` for `MAKE_DECISION`. Enum-value shift affects action serialization
- **Alliance victory recording fixed** — `Game.getWinnerVictory` no longer excludes `mbAlliance` victories; `Game.makeWinner` reordered to complete the alliance team's victory (`loadTeamVictoryCompleted(eAllianceTeam, ...)`) before the winner-team check; `ClientUI.buildGameOverText` keys the roster label off `infos().victory(eWinnerVictory).mbAlliance` instead of comparing against the `ALLIANCE_VICTORY` global
- **Observer mode draws revealed city assets** — `Game.getCityDataForTerrain` non-visible branch passes when `manager().Renderer.isObserverMap()`
- **Randomized Improvements respects DLC** — `Game.randomizeNationalReligiousImprovements` gates both selections on `isGameContentEnabled(meGameContentRequired)` (shrines unavailable without all DLC)
- **Team diplomacy popup** — `Game.doTeamDiplomacy` replaces the same-team `addTurnSummary` with `pushNextPopupText(..., eCIQEvent: bNewHostile ? CIQEventType.WAR : CIQEventType.PEACE)`
- **Road objects removed correctly** — `RoadRenderer.RoadSegment` (decompiled): ctor was assigning to a dead private `newObject` field, leaving the public `gameObject` null so segments could never be found/removed; now assigns `this.gameObject`
- **Mod manager fixes** (decompiled) — `ModManagerController.UpdateSubscribedModioMod` no longer overwrites when any matching local mod exists (version-equality requirement dropped); `ModManagerPanel` version-mismatch "!" condition simplified to `File.Version != null && File.Version != mod.Version`; `StartScreenController` Mods-Not-Found popup moved after the join callback so screen switches don't clear it (+ `StartScreenUI` null-checks `ModManagerController`)
- **Map script dropdown data fixed** (decompiled) — `SetupScreenPanel` map-script subtags carry `subTag.Data = value[i].ToStringCached()`; `MapClass` change/help handlers resolve via `data.GetDataEnum<MapClassType>(1, Infos)` instead of indexing a rebuilt list

### Scenarios & mods

- **Rise of Carthage 2 goal counts** — new `Carthage2Player.calculateGoalsIndirectlyCompleted`/`calculateGoalsActive` overrides exclude the explanatory sub-goal `GOAL_QUEST_ALLY_PHOENICIAN_ISLAND_COLONIES_RESOURCES` from tallies; `CarthageCampaignPlayer.calculateGoalsActive` made `virtual` to allow it
- **Rise of Carthage 3 fallback goals** — new `EVENTSTORY_CARTHAGE3_FAMILY_GOAL_3_NO_GREECE_FALLBACK` event with Riders/Traders fallback options forcing new goals `GOAL_QUEST_FALLBACK_FOUR_CITADELS` (4× `IMPROVEMENT_GARRISON_3`, 30 turns) / `GOAL_QUEST_FALLBACK_TWELVE_WORKERS` (12× `UNIT_WORKER`, 30 turns) — covers goal 3 failing when Syracuse is eliminated quickly
- **Heroes of the Aegean 4 helptext** — `Mods/Greece4/subject-add.xml`: `SUBJECT_FAMILY_ANTIPATER`/`_ATHENS`/`_OLYMPIAS` gain `bHidden: 1`

## 2026-05-14 Hotfix (v1.0.83591)

2 files changed in `Reference/Source` plus 1 decompiled `Assembly-CSharp` file. Per the developer notes: fixes bugs that could cause game hangs, plus AI performance optimizations. (Dev notes call out "v1.0.82591" but the shipped asset bundle reports `1.0.83591` — using the bundle value.)

### Multiplayer

- **Network read error no longer resets client connection** — `GameClientBehaviour.cs` client network read loop (two sites): on a network-read `Exception`, was calling `APP?.DefaultNetwork?.ResetClientNetwork(clearGame: false)`, which tore down the transport layer and could leave the game hung (server still thinks the client is connected, client has dropped). Now calls `SendClientGameReadyToServer()` — re-signals readiness to the server without nuking the connection so the server can resend init data. Assembly-CSharp only (no Reference/Source counterpart)

### AI

- **Improvement adjacency valuation fixed** — `PlayerAI.calculateImprovementValueForTile` (~line 11353): in the per-yield / per-adjacent-improvement inner loop, the `iAdjacentValue +=` term using `getYieldToAdjacent(eLoopYield, eLoopImprovement, eImprovement, pTile.getResource())` × `cityYieldValue(_, pCity)` was being applied unconditionally — even when `pAdjacentCity.getTeam() != Team`. Moved inside the team check. A separate inside-if term that used the reversed-argument call against `pAdjacentCity` is dropped entirely. Adds a `iYieldToAdjacent != 0` early-out around the multiply. Net effect: the AI no longer credits itself yield-to-adjacent value when the neighbouring tile sits in foreign- or un-team territory
- **Project effect-city evaluation reorders for perf** — `PlayerAI.calculateEffectCityValue` (~line 14659): predicate order was `pCity.canBuildProject(...)` → `meEffectCityPrereq == eEffectCity` → `!mbHidden` → `isTechAcquired`. Reordered so the cheap field/method checks run first and the expensive `canBuildProject` runs last. Same body, no behaviour change

### UI

- **Improvement ping tooltip uses central helper** — `Player.updatePings` (line 21925): swapped the sentinel comparison `zPing.meImprovement == infos().improvementsNum()` for `infos().Helpers.isActualImprovementPing(zPing.meImprovement)` (and inverted the ternary branches to match). Aligns this site with the ~12 other call sites already using the helper

## 2026-05-06 Update (Update #146, v1.0.83499)

XML, Reference/Source C#, and decompiled changes across 65 XML files (304 modified, 261 added, 62 removed records) and ~74 decompiled C#/source files. Highlights: a new in-game **Map Search** UI, fog-of-war-aware combat math (visibility-team plumbed through every attack/defend/ZOC call), tribute hostility cooldown, an out-of-game tech-tree browser, an EOTI "Testing the Treaty" event split, market/tech rebalances, AI succession rework, and a sweep of rendering/perf/null-safety fixes.

### Gameplay

- **Tech tree cost rebalance** — 82 `tech.xml` records re-priced. Most root and unit-bonus techs go up ~+25% (e.g. `TECH_ADMINISTRATION 80→100`, `TECH_FORESTRY 200→250`, `TECH_BATTLELINE 600→700`, `TECH_WINDLASS 1000→1100`, `TECH_HOPLITE_BONUS 200→250`). Three exceptions go down: `TECH_JURISPRUDENCE_BONUS_MINISTER 600→550`, `TECH_SCHOLARSHIP_BONUS_SCIENTIST 400→350`, `TECH_VAULTING_BONUS_HAPPINESS 400→350`
- **Trashable tech filter** — new global `MIN_NON_TRASHABLE_TECHS_AVAILABLE` (2). `Player.countTechsAvailable` and `addTechAvailable` gain `bool bIncludeTrashable = true`; `doTechsAvailable` reverse-counts and forces non-trashable picks while the available pool is below the threshold
- **Markets unlock at lower culture tiers** — `IMPROVEMENT_MARKET_1` `CULTURE_DEVELOPING → WEAK`, `MARKET_2 STRONG → DEVELOPING`, `MARKET_3 LEGENDARY → STRONG`. Goal targeting for `GOAL_FOUR_MARKET_1/2` and `GOAL_THREE_MARKET_3` re-aimed at the new tier windows; `iSubjectWeight 1200 → 1000`. `GOAL_LEGENDARY_IMPROVEMENTS_ALL` adds `IMPROVEMENT_THEATER_3` count 3
- **Gold/Silver mines yield more money** — `IMPROVEMENTCLASS_MINE` Gold/Silver `YIELD_MONEY 400 → 500` (+25%)
- **Jungle wood yields up** — `VEGETATION_JUNGLE` build-yield wood 40→60; `VEGETATION_JUNGLE_CUT` 20→30
- **Jade is rarer** — `RESOURCE_JADE` `iMinDist 4→8`, `iProbThousand 10→8`
- **Anti-melee modifier no longer attack-only** — `EFFECTUNIT_ANTIMELEE` moves the 50% UNITTRAIT_MELEE modifier from `aiUnitTraitModifierAttack` to `aiUnitTraitModifier` (now applies on defense too)
- **Indian elephant + Yuezhi-Kushan vision reduced** — `iVision 5→4` cluster: `UNIT_ARCHER_ELEPHANT`, `UNIT_ARMOURED_ELEPHANT`, `UNIT_ASSAULT_ELEPHANT`, `UNIT_JAVELIN_ELEPHANT`, `UNIT_KUSHAN_CAVALRY`, `UNIT_KUSHAN_WARLORDS`
- **Hindu Disciple religion gating moved** — `UNIT_HINDUISM_DISCIPLE` migrates from `RequiresReligion` to `EffectCityPrereq: EFFECTCITY_RELIGION_HINDUISM` (city must have Hinduism, not the unit). `Unit.start` now sources religion from `Helpers.getUnitReligion(getType())` (checks `meRequiresReligion`, then any religion whose `meEffectCity` matches `meEffectCityPrereq`)
- **Slinger no longer obsoleted by Windlass** — `UNIT_SLINGER` drops `aeObsoleteTech[1]: TECH_WINDLASS`
- **Leader/Explorer immunity widened** — `EFFECTUNIT_LEADER_EXPLORER` adds immunities to `EFFECTUNIT_PANIC`, `EFFECTUNIT_STUN`, `EFFECTUNIT_DISARMED`, `EFFECTUNIT_GRAPPLER`; icon `EFFECTUNIT_SWIFT → EFFECTUNIT_ALEXANDER`
- **AI science-yield boost across all difficulties** — `effectPlayer.xml` `aiYieldRate.YIELD_SCIENCE` +20 on every AI difficulty: GREAT 50→70, MAGNIFICENT 60→80, GLORIOUS 70→90, NOBLE 80→100, STRONG 90→110, ABLE 100→120, GOOD 100→120
- **Family control sourced from globals** — `Player.getFamilyControl` replaces hardcoded weights with new `globalsInt` records `CONTROL_SCORE_LEADER` (2), `CONTROL_SCORE_RELIGION_HEAD` (2), `CONTROL_SCORE_COUNCIL` (2), `CONTROL_SCORE_CLERGY` (1), `CONTROL_SCORE_COURTIER` (1), `CONTROL_SCORE_GOVERNOR` (1), `CONTROL_SCORE_GENERAL` (1), `CONTROL_SCORE_AGENT` (1). **Explorers no longer count toward family control** (the `iControl += countExplorersOfFamily(eFamily)` line is gone)
- **Rising Star supersedes negative reputation traits** — `TRAIT_RISING_STAR` adds `aeTraitReplaces`: `TRAIT_INFAMOUS`, `TRAIT_UNPOPULAR`
- **Mission flag overhaul** — `bReligionIcons` renamed to `bShowReligionIcons` (Convert Religion / Convert State / Make Clergy). New `bShowCityDiscontent` on Pacify City missions (`MISSION_PACIFY_CITY`, `MISSION_PACIFY_CITY_MENTUHOTEP_II`, `MISSION_PAGAN_SACRIFICES`). New `bShowCharacterSuccession` on `MISSION_TUTOR` and `MISSION_TUTOR_SCHOLAR`
- **Bumping rules tightened/loosened** — `Tile.canBumpUnit`: own-territory check now uses `getPlayer() == getOwner()` (was `isAlliedWith`), but a new branch lets you bump non-allied units off allied territory
- **Specialist count includes pillaged** — `City.getSpecialistCount(bool bIncludePillaged = false)` walks territory tiles when true; UI uses the diff to show a red/pillage-icon warning when totals diverge
- **Religion future-build helpers** — new `City.isReligionFuture` / `isReligionNowOrFuture`: a religion counts as "future" once any territory tile has an in-progress build of an improvement matching `meReligionSpread`. Used by religion territory overlays
- **Improvement replace gate** — `City.canAddImprovement(eImprovement, bool bAllowReplace = true)` (and `canAddImprovementTile`); when false, rejects tiles with an existing improvement
- **Yield sign-correct city effect modifiers** — `Tile.yieldOutputCityEffects` multiplies the modifier by `Math.Sign(iYield)` so negative yields flip sign correctly

### Combat & Visibility

- **Fog-of-war-aware combat math** — `Unit.attackUnitStrength`, `attackUnitDamage`, `attackCityStrength`, `attackCityDamage`, `defendUnitStrength`, `getCounterAttackDamage`, `canCounterattack`, plus `Tile.flankingAttack` / `adjacentTileFriendUnitSame` / `adjacentTileFriendUnitDifferent` / `isHostileZOC` / `isDirectionHostileZOC` all gain a `TeamType eVisibilityTeam` parameter (39 hits in the C# diff). Flanking and adjacency modifiers now skip units invisible to the rendering team. `ClientUI.populateAttackPreviewTooltip` and `updateCityWidget` thread the active team through; `ClientRenderer.drawTileOverlays` collapses ZOC overlay to hostile-team only
- **TempHidden / bounce parameter sweep** — `bounce`, `doBounce`, `setTempHiddenTurns`, `refreshTempHiddenTurns`, `clearTempHidden`, `updateTempHidden` all gain `bool bNoKill`; `bounce` and `doBounce` now return `bool` (false instead of killing when no escape tile and `bNoKill`). New silent setter `loadTempHiddenTurns(int)` replaces direct `mpCurrentData.miTempHiddenTurns` writes (~6 sites). `Tile.pillageImprovement` passes `bNoKill: true` when clearing temp-hidden
- **Hidden-from semantics tightened** — `Unit.isHiddenTileFrom` restructured (no early-exit for owned, non-peace tiles); `isVisibleTile` split into `isVisible` + `isHiddenTileFrom`, and **skips the hidden check when `eTeam == TeamType.NONE`**. `Unit.getTileOccupyValue` now triggers its +1000 bonus from `isHiddenTileFrom(NONE, ...)` instead of `!isVisibleTile(NONE, ...)`. `UnitRoleManager` retreat/agent value calls switched to `isHiddenTileFrom(TeamType.NONE, ...)`
- **AI visibility check stricter** — new `PlayerAI.isUnitVisible` adds a `!isHiddenFrom(Team)` check on top of `isVisibleTo(Team)`. Adopted across ~10 AI sites: `isValidTargetUnit`, `cacheLastSeenUnitStates`, `setCurrentUnitDangers`, `updateLastSeenDangers`, `doHirePlanning`, `isVisibleForeignShip`, `updateLastSeenUnit`, `isRivalTileOrUnit`, `getWarOfferPercent`. AI now ignores units that are tile-visible but ability-hidden
- **Per-unit-type ZOC** — `Unit.hasZOC()` → `hasZOC(UnitType eAgainstUnit)`. Egypt3's Amun/Aten ZOC carve-out moved from `Egypt3Tile.isDirectionHostileZOC` (override deleted) to a new `Egypt3Unit.hasZOC(UnitType)` override
- **Tribute hostility cooldown** — `PlayerBonus.canDoBonusSingle` rejects bonuses with `maiYieldsTributeBase`/`maiYieldsTributePerUs` when `tribeDiplomacy(eTribe, getTeam()).mbHostile && getTribeDiplomacyNumTurns == 0`
- **Tribe role pipeline two-phase** — `UnitAI.canMoveTo` gains `bool bDirectOnly = false` (rejects paths > `2 * distanceTile`); `pickRoleMoveTile`, `pickRaidTarget`, `selectMoveTile` plumb the flag; `tribeMoveToTarget` loses its `bDirectOnly` param; `doMoveTribe` now does a direct-only pass first, then falls back to non-direct. `pickRoleMoveTile` adds a `eRole != RoleType.NONE` exit guard. `canHaveTribeRole` rewritten as a switch — **roles outside `PILLAGE`/`ATTACK_UNIT`/`ATTACK_TARGET` now return `false`** (previously fell through to true). `doTurnTribe` re-picks role when current role becomes invalid
- **Counterattack advance fix** — `Unit.canAdvanceAfterAttack` `bTestTheirUnits` now `(!bKilledDefender || pDefendingUnit != null)` instead of always true
- **Repair gate widened** — `Unit.canRepair` is also true if `canBuildImprovementType(pTile.getImprovement())`
- **Upgrade tech check fix** — `Unit.canUpgrade` uses `player()` (own player) for tech-acquired check instead of `pActingPlayer`
- **Tribe site capture guard** — `Unit.doImprovementCapture` (tribe branch) requires `tile().connectedNoFoundUnit(TeamType.NONE) == null`

### AI

- **AI succession rework** — `Player.chooseNextLeader`: when AI heir is non-adult, walks `getSuccession()` for an adult; if none, **synthesizes a fresh adult character** (age `ADULT_AGE + randomNext(4)`, gender from `successionGender`, current leader family) and reassigns founder. Law-leader fallback skipped unless `isHuman() || pLeader.isAdult()`. The "no heir = defeat" path now applies in **all** single-player games, not just human players (`if (game().isSinglePlayer())`)
- **AI city family deferred** — `MapBuilder.addPlayers` always calls `preStartFoundCity(pBestFoundTile, FamilyType.NONE, NationType.NONE)` regardless of human/AI. AI family selection now happens later in `Player.initNation`, which iterates `getCurrrentCities()` [sic] and calls `pCity.setFamily(AI.getBestFoundFamily(pCity.tile(), getNation()), bPreStart: true)` for any city without a family. Likewise `Player.doDevelopment` now always passes `FamilyType.NONE` to `preStartFoundCity`
- **canFoundCityFamily rewritten** — fails immediately when `getNumFamilies() >= MAX_FAMILIES` for unstarted families. Per-`maeForceFamily` requirement now requires that at least one listed family is either `eFamily` itself or already started, replacing the old two-flag (`bFoundUs`/`bMissingOther`) scheme. The `canFoundCityFamily(eFamily)` result is used by the "found city as family" popup option's IsInteractable
- **Tribe AI yield caching guarded** — `PlayerAI.evaluateTurn` gates `cacheYieldValues`/`cacheCityYieldValues`/`cacheImprovementValues`/`cacheTechValues` behind `if (player != null)` (tribes skip player-only caching)
- **Tribe attribution by type** — `Player.getCurrentTurnLogText` matches tribe by `tribe.mzType` directly instead of evaluating localized display text — fixes locale-dependent comparisons

### Events

- **EOTI: "Testing the Treaty" split into four tribe-level variants** — four new `eventStory-eoti.xml` events all sharing `Class: EVENTCLASS_HUN_EVENTS`, gated by `MinTribeLevel`/`MaxTribeLevel` plus current Hun relationship: `EVENTSTORY_TESTING_THE_TREATY_ALLIANCE_NORMAL`, `..._ALLIANCE_WEAK` (alliance + repeat 10), `..._PEACE_NORMAL`, `..._PEACE_WEAK` (peace + repeat 15). The two original events `EVENTSTORY_TESTING_THE_TREATY_ALLIANCE` and `..._PEACE` now also gain `MinTribeLevel: TRIBELEVEL_STRONG` (the new variants cover the lower tiers); the PEACE one bumps `iRepeatTurns 10→15`
- **EOTI: Hindu Synthesis option 2** — bonus changed `BONUS_JOIN_S4` → `BONUS_ADD_CHARACTER`
- **EOTI: Maxim of the Fish** — now requires loyal leader subject (`Subjects.leader.Type: SUBJECT_LEADER_US`, `Any: SUBJECT_LOYAL`)
- **EOTI: Scourge of All Lands** — option 0 swap `BONUS_INFLUENCE_S1 → BONUS_GAIN_COURAGE_1`; option 2 sign fix `BONUS_TRAINING_LOSS_SMALL → BONUS_TRAINING_GAIN_SMALL`; `Subjects.huns.Any` switched `SUBJECT_TRIBE_TRUCE → SUBJECT_TRIBE_PEACE`; new `attila` subject relation `SUBJECTRELATION_TRIBE_SAME` to huns
- **Relationship Good Cheer rescoped to city** — `EVENTOPTION_RELATIONSHIP_GOOD_CHEER_OPTION_{0,1,2}` retarget bonuses from character-scope to city-scope. Paired XML rename in `bonus-event.xml`: `BONUS_EVENTOPTION_RELATIONSHIP_GOOD_CHEER_OPTION_{1,2}_CHARACTER_1` removed, `..._CITY_1` added with the same payloads (`PROJECT_IRON_INDUSTRY`, `BONUS_PROJECT_BY_THE_NUMBERS`). `EVENTSTORY_RELATIONSHIP_GOOD_CHEER` adds `aeSubjects[2]: SUBJECT_CAPITAL_US` and `iLookAtSubject: 1`
- **Camera-target tweaks** — `EVENTSTORY_CITY_AUTONOMY` `iLookAtSubject: 0`, `EVENTSTORY_FEROCIOUS` `iLookAtSubject: 4`. `EVENTSTORY_THE_SHADOWS_OF_LANDMARK` `iImageSubject: -1`, `EVENTSTORY_WARNING_OF_DAYS_TO_COME` `iImageSubject: 2`
- **Scenario loss events flagged as game-end** — `bEndGame: 1` added across seven scenario `eventStory-add.xml` files: Barbarian (`EVENTSTORY_BH_LOSS`), Carthage 1–4 (`*_GAME_LOSS`), Greece1 (`*_LOSS_FALLBACK`), Greece2 (`*_LOSE_GREECE`)
- **Trait removal family-opinion guard** — `Character.removeTrait` skips `FamilyType.NONE` before calling `updateFamilyOpinion`

### UI

- **In-game Map Search** — new `ClientUI` feature with nested enums `MapSearchType` (CITY/UNIT/RESOURCE/IMPROVEMENT), `MapSearchPlayerType` (UNOWNED/OTHER), and per-domain search subtypes (`MapResourceSearchType`/`MapImprovementSearchType`/`MapCitySearchType`/`MapUnitSearchType`). New methods `resetMapSearch`, `updateMapSearchDropdowns`, `getMapSearchResults`. New `ItemType` cases `MAP_SEARCH`, `MAP_SEARCH_CYCLE`, `MAP_SEARCH_PLAYER`, `MAP_SEARCH_TYPE`, `MAP_SEARCH_FILTER`, `MAP_SEARCH_FIELD`. `HelpText.Widget` handles `MAP_SEARCH_FILTER` tooltips. `ClientManager.switchActivePlayer` resets the search state. New `text-ui.xml` strings: `TEXT_TECH_TREE_SEARCH` plus 9 `TEXT_UI_TECHTREE_FILTER_*` (NONE/BONUS/COUNCIL/IMPROVEMENT/LAW/MISSION/PROJECT/TECH/THEOLOGY/UNIT)
- **Out-of-game tech-tree browse** — `TechTree.BuildTree(Game)` → `BuildTree(ClientManager)`; `Node` ctor likewise. Lookups go through `mgr.GameClient?.isTechPrereq(...) ?? mgr.Infos.tech(eTech).mabTechPrereq[...]`. `ClientManager.Initialize` calls `TechTree.BuildTree(this)` eagerly (not just at `startGame`). Cascading null-safety in `ClientUI.FillTechUnlockInfo`/`SetCurrentTabOverlay`/`doWidgetAction`. New `TechTree-InGame` UI attribute exposes the distinction. `decompiled/Assembly-CSharp/TechTreePanel.cs` was overhauled to match (researching/target sections gated on `Game != null`)
- **Banded religion-territory overlay** — new XML asset `ASSET_TILE_OVERLAY_BANDED` (`Prefabs/UI/TileOverlayQuadBanded`). `ClientRenderer.createTileOverlay` gains `bBanded`; new `drawTileOverlayBanded`, banded pools/dictionaries, and cleanup paths. `drawTileOverlays` religion path now uses `isReligionNowOrFuture` and **draws the banded overlay where territory is "future religion only"** (vs current). Religion overlay alpha 0.2f → 0.3f
- **Trade-modifier UI surface** — new `LinkType.HELP_TRADE_MODIFIER` (5-arg payload). `HelpText.Bonus` shows `buildModifiedYieldValueLinkVariable` for trade-rolePlaying when `getTradeValueModifier != 0` and `ADVANCED_HELP` is set. `HelpText.cs::buildYieldNetHelp` foreign-trade items append `TEXT_HELPTEXT_YIELD_TRADE_MODIFIERS`. New `HelpText.cs::buildTradeValueModifierHelp` and `HelpText.Game::buildTradeModifierLinkVariable`/`buildModifiedYieldValueLinkVariable`
- **Pillaged specialist display** — `populateCityTooltip` and `ComparePopulation` use `getSpecialistCount(true)` and color/warn when totals diverge from the unpillaged count. `HelpText.City::buildCitySpecialistsHelp` overlays a pillaged icon per pillaged tile
- **Mission widget refactor** — `ClientUI.CreateContextButtons` uses `bShowReligionIcons`/`bShowCityDiscontent`/`bShowCharacterSuccession` flags instead of the prior `mbReligionIcons` plus per-bonus scans; appends heir text on character buttons
- **Damage preview alt-toggle** — `decompiled/Assembly-CSharp/UnitObjectBanner.cs`: holding **Alt** swaps to non-hostile damage preview (`damagePreview2`)
- **Game Editor refactor** — `decompiled/Assembly-CSharp/GameEditor.cs`/`GameEditorUI.cs` split the fat `UpdateModeUI(...)` setter into per-state setters (`SetCurrentMode`, `SetCurrentPlayer`, `SetCurrentTribe`, `SetCurrentUnitMode`, `SetCurrentCityMode`, `SetCurrentImprovementMode`, `SetCurrentMapMode`, `SetGame`), each marking `IsDirty = true`. `GameEditorUI` becomes `IUIAttributeObserver` of `GameEditor-IsDirty`/`IsDirty`. ESC now closes an open game editor (`ClientInput.evaluateGameHotKeys`)
- **New character: Phidias** — `CHARACTER_PHIDIAS` (Greek, Pericles dynasty, Builder Archetype + Artist, age 21, Minister, portrait `CHARACTER_PORTRAIT_GREECE_LEADER_MALE_13`)
- **Hun teen portraits sourced from Yuezhi** — 20 records in `characterPortrait-eoti.xml` retarget `CHARACTER_AGE_GROUP_TEEN` from each Hun leader's own `_ADULT` sprite to `YUEZHI_LEADER_*_TEEN` (HUN_LEADER_FEMALE_*_TEEN → `YUEZHI_LEADER_FEMALE_07_TEEN`; males split between `YUEZHI_LEADER_MALE_01/04/06_TEEN`). Companion clusters: 38 `characterPortraitAgeInterpolation` rows retune `bFlipSource`/`bFlipDestination`/`bTint`/`fBlendInversionPoint`/`fForeheadBlendDistance` across all four age transitions, and 91 `characterPortraitFeaturePoints` rows shift `zColor` (largest deltas on `_TEEN`)
- **Attila portrait fix** — `CHARACTER_ATTILA` `PreferredPortrait CARTHAGE_LEADER_MALE_01 → HUN_LEADER_MALE_01` (was using a Carthaginian portrait)
- **Mission concept linkable** — new `CONCEPT_MISSION` plus `GENDERED_TEXT_CONCEPT_MISSION` (M/F variants)
- **Possessive grammar localized** — `Character.getFullNameVariable` only appends a possessive suffix when the active language has `mzPossessiveMethod == "concat"`, and uses `TEXTVAR_TYPE("TEXT_CHARACTER_POSSESSIVE_SUFFIX")` instead of a literal `"'s"`. `language.xml`: `LANGUAGE_CHINESE_SIMPLIFIED/TRADITIONAL`, `ENGLISH`, `JAPANESE`, `KOREAN` all gain `zPossessiveMethod=concat`. Added `InfoLanguage.mzPossessiveMethod` field
- **Heir text type** — `getCharacterHeirTextType` return type `string → TextType`. `Character.getFullNameExtraVariable` migrated to the new sentinel/builder pattern
- **Tile-jump from links** — `ClientUI.doWidgetAction` adds camera-pan cases for `LinkType.HELP_IMPROVEMENT` and `HELP_RESOURCE`; `HELP_TILE` widened from `isVisible` to `isRevealed`
- **Hover/scroll fix** — new `ClientUI.previousHover` field; on scroll-stop, only re-enters the hover if the widget changed. Road-overlay path now actually accumulates `clientRoadIDs`
- **Empires of the East scenario name strings** — `text-infos.xml` adds `TEXT_SCENARIO_BACTRIA_DUEL` ("Maurya vs. Yuezhi"), `TEXT_SCENARIO_THREE_CROWNED_KINGS` ("Fight for the lands of Tamilakam"), and `_SUB` variants
- **Observer noun** — new `TEXT_OBSERVER_NOUN` ("Observer") in `text-game.xml` (spectator role label)
- **Achievement rename** — "Archer Elephant" → "Elephant Archer" (achievement and title)
- **Help text additions** — new EN-US strings: `TEXT_HELPTEXT_EFFECT_CITY_HELP_VOID_TECH_PREREQ_IMPROVEMENTCLASS` ("Can build {0} without {1}"), `..._BUILD_ROAD` ("Can build Roads"), `..._HEAL_KILL` ("link(CONCEPT_HEAL,2) on Unit killed"), `..._HURRY_WARNING_INVALID`, `..._POPUP_MAIN_MENU_REHOST` / `..._WIDGET_REHOST` (rehost button is back), `TEXT_HELPTEXT_UNLOCKED_BY` ("Unlocked by {0_cityEffects}"), `TEXT_MP_SETUP_TOO_MANY_TEAMS`, plus `TEXT_UI_STATS_WORKER_TURNS`. Wording change: "Immune to {0}" → "Immune from {0}". Removed: 7 generic `TEXT_HELPTEXT_EVENT_REQUIRES_*` strings (likely consolidated into shared formatters via the new `bNot` parameter on `HelpText.Event::buildPlayerSubjectPrereqs`/`buildCharacterSubjectPrereqs`/`buildEventStorySubjectPrereqs`)
- **HelpText.Event.bNot propagation** — three event-prereq builders gain `bool bNot`; "not any" prereq scopes flip `COMMA_OR → COMMA_AND`. `getEventStringVariables`'s `needs("PLAYER-")`/`TRIBE`/`RELIGION`/`TRAIT` shortened to bare needs without the `-` suffix

### Rendering & Networking

- **Encrypted relay protocol** — `NetTransportClient.PlayerRelayData` and `NetTransportServer.HostRelayData`: `RelayProtocol.UDP → RelayProtocol.DTLS`. `NetTransportBase` adds `ClearSendMessageOverrides()`; `UnityTransportComponent` clears stale send-message overrides before re-attaching, and on relay-connect failure now also `DeleteNetworkServerData(joinedMatch, null)`. Log typo fix `"recieved" → "received"`
- **TerrainRenderer two-phase init** — `InitializeTerrain` split into `InitializeTerrainData()` + `InitializeTerrainRenderers()` gated by a new `initPhase` field; constructor no longer eagerly calls `Update()`. Reduces frame hitch on terrain init
- **CoastRendererV2 selective dirty** — new `ShouldDirtyTile(tileID)` predicate (only dirties tiles whose mask actually changed). All height/water lookups now go through new `ITerrainData.getHeightTurn`/`isWaterTurn`/`getTerrainTurn` instead of reaching into `AppMain.gApp.Client.Game.tileBoundary(...)`. New `ITerrainData` members + `TerrainDataExtensions.isWaterTurn`
- **Stacked mountain overrides** — `MountainRenderer.assetOverrides` value type now `List<InfoTileVisualEffectComponent>`. `ClearOverride(iTileID, eHeight)` removed; replaced by `RemoveOverride(iTileID, eHeight, meTileVisualEffectComponent)` (pops a single effect). Matching rename `clearMountainOverride → removeMountainOverride(int, HeightType, TileVisualEffectComponentType)` on `IRenderer` and `DefaultRenderer`. `TileEffectComponentReplaceMountain` updated
- **RoadRenderer segment struct** — `roadObjects` element type `GameObject → RoadSegment` (gameObject + direction). New `HasSegment(tileID, direction)` query
- **River bridge gating** — `RiverRendererV2` constructor takes `TerrainRenderer`. New `ShouldDrawBridge(tileID, direction)` only draws bridge when `RoadRenderer.HasSegment` reports a road on that edge **or** both tiles are cities
- **UnitRenderer temp-hidden cleanup** — entire `unitTempHidden` HashSet machinery removed (field, `Clear`, `Add(ReplacedUnitID)`, public `IsUnitTempHidden`). `UnitObject` and `UnitObjectBanner` drop the corresponding visibility-gate calls
- **MapCamera bounds clamp** — `Move` adds a `Vector2(17.320509f, 15f)` margin around `worldExtents` (zoomed-out camera no longer leaves the playable area)
- **Fog timeline projector toggle** — `FogOfWarRenderer.SetTimelineFogOfWarEnabled` also toggles `fogOfWarSetup.projectorTimeline.SetActive(enable)` alongside the cloud object
- **HistoryPopup tile refresh** — scrub-restore now calls `forceUpdateTileTerrain(tile.getID())` instead of `drawTile(pTile)`

### Bug Fixes & Safety

- **Game double-init guard** — `Game.initClientValues` early-returns if `mpCurrentData != null` before `createNetworkData(eNumTeams)`
- **AddTech recursion** — `GameHelpers.AddTech` recurses into itself with `addPrereqs` for inner prereq grants instead of calling `manager().sendAddTech` directly (handles deeper prereq chains consistently)
- **InfoHelpers split for HelpText** — `yieldOutputImprovement` gains `bIncludeResource = true`; HelpText.Improvement passes `false` at two call sites to avoid double-counting resource yields
- **MapBuilder family lookup deferred** — `addPlayers` no longer calls `getBestFoundFamily(pBestFoundTile)` for AI; family selection moved to `Player.initNation`
- **DefaultMapScript helpers** — new `SortTilesByX`/`SortTilesByY`. `MakeWater` is now idempotent on water tiles (wraps mountain/terrain-locked checks in `if (!IsWater(tile))`) and clears `tile.Resource` when converting. `TryAddPlayerStartsTwoTeamMP` rewritten to assign zone partition by index after `SortTilesByX` rather than absolute X coordinate; `bTopBottomBuffer` branch uses `RemoveRange` slices on Y-sorted tiles. `DoMirrorMap` correctly syncs `lockedTerrain`/`lockedHeight`/`lockedVegetation` sets across the mirror (removes prior mirror entry, re-adds when source ID is in the locked set)
- **Mod system imports loose Modio mods** — `ModManagerController.UpdateLocalMods` now imports `modPlatformInfo == "Modio"` (or empty) in addition to Workshop. `EditModfile()` chain sets `.SetVersion(localEdit.Info.modversion)`. `ModPath.GetModIOInfo` signature dropped its `Infos` parameter (callers in `ModListing` and `ModManagerPanel` updated). `ModListing.LocalImage` for Modio mods keys cache off path-derived `modioID`
- **ModManagerPanel coroutine pile-up fix** — caches and `StopCoroutine`s the `updateCoroutine` before re-running `updateSelectedModPanelCoroutine`; removes redundant `UpdateSelectedModPanel()` calls in image/file picker callbacks
- **AspectRatio simplified** — `decompiled/TenCrowns.GameCore/TenCrowns.ClientCore/AspectRatioType.cs` deleted. `IUserInterface.AspectRatioType` enum and `GetAspectRatio()` method removed; aspect ratio now flows purely through the `Globals-AspectRatio` UI attribute string. New 32:9 bucket added to `DefaultUserInterface` (`>= 18000`)
- **UIDropdown re-apply** — `_selectedIndex` initialized to `-1`; setter no longer short-circuits on equal value; option-add calls `SetSelectedOption(option)` if the new option matches `SelectedIndex`. Reference resolution computed from `_rootCanvas.pixelRect.size.y / scaleFactor`
- **Setup screen invalid-nation handling** — `SPSetupScreenPanel` no longer clears `mapPath` / calls `ClearMapData()` on invalid nations (now always calls `UpdateCurrentMapData(bAdjustAIPlayers: false)`). `StartScreenController` writes empty `mapPath` to defaults only when `InvalidNations.Count > 0`. `JoinMatch` calls `DeleteNetworkGameData(gameToJoin.gameId, null)` post-join. `StartScreenUI` ESC now closes a full-screen tab overlay before falling through to popup-escape
- **No Organized Tribes gating** — `SetupScreenPanel` iterates `Infos.tribes()` and checks each tribe's `meGameContentRequired` ownership instead of the prior single EOTI check. `HelpText.buildMapSizeHelp` now passes `Controller.IsSinglePlayer()` for player-count clamping
- **Per-tile dirty UI on ZOC change** — `Tile.dirtyValuesIO` now also marks `ClientUI.DirtyType.WATER_CONTROL_PREVIEW` alongside the existing renderer dirty
- **Player dirty flags expanded** — `Player.dirtyValuesIO` adds `GAME_EDITOR`, `TURN_TEXT` (when `nation()?.mbCoalition`), and `YIELD_PANEL` (in the unit-list block)
- **setCustomName null guard** — `Character.setCustomName` checks `player() != null` before `findLeaderIndex`/`searchLineageForSuffix`
- **Unknown Mother gets a name** — `CHARACTER_UNKNOWN_MOTHER` `FirstName: NAME_UNKNOWN → NAME_DHARINI`
- **Subject prereq text cleanup** — `IN_THE_HANDS_OF_GOD` option 0 trait bonus: `iRemoveTraitSubject 0` cleared (default)
- **Typo fixes** — event text: "hoards → hordes" (Overflowing With Hate), "discrete → discreet" (As Iron Sharpens Iron Covert), "Recieved → Received" (Received Congratulatory Gift memory)

### Mods (Reference/Source)

- **Egypt3** — `Egypt3Tile.isDirectionHostileZOC` override deleted (logic moved to `Egypt3Unit.hasZOC(UnitType)`). `Egypt3Unit.bounce` widened to new `bool` return / `bool bNoKill` signature (follow-on of `Unit.bounce` cluster)
- **EgyptCampaign** — `EgyptClientUI.SetEgyptTabOverlay` drops a now-stale `mTechScreenButton.Data = mLastTechsOverlayState.ToStringCached()` assignment
- **Greece5: Halicarnazian fire via occurrence** — `Greece5Game.razeHalicarnassus` replaces the inline `addVisualEffectForTile(OCCURRENCE_EFFECT_WILDFIRE, ...)` ring loop with a single `addOccurrence(OCCURRENCE_HALICARNASSUS_FIRE, ..., pTile: pOrigin)`. New `Greece5/Infos/occurrence-add.xml` defines `OCCURRENCE_HALICARNASSUS_FIRE` (`OccurrenceEffect: OCCURRENCE_EFFECT_WILDFIRE`, `iMaxDuration: 1`, `iTileContiguousRange: 2`, `TERRAIN_TARGET_LAND`). New `Greece5Player` overrides `addTurnSummary` / `pushLogData` filter `TurnLogType.OCCURRENCE` / `GameLogType.OCCURRENCE` (keeps the fire visual-only without log spam)
- **CalamitiesSurvival (decompiled-only)** — `CalamitiesCity.canAddImprovement` gains `bool bAllowReplace = true` (follow-on of base signature change). New `CalamitiesUnit.canRecruit` returns false when `isRaiding()`
- **DLC HelpText LinkType base shift** — `CalamitiesSurvival/CalamitiesHelpText`, `Egypt5/Egypt5HelpText`, `Greece4/Greece4HelpText`, `decompiled/TenCrowns.CarthageCampaign/CarthageCampaignHelpText` all shift their per-mod LinkType base `215 → 216` (matches a new `LinkType` slot inserted into the base enum, alongside `HELP_TRADE_MODIFIER`)
- **LearnToPlay5** — `LearnToPlay5UnitAI.canMoveTo` signature updated for new `bDirectOnly` parameter (follow-on of `UnitAI.canMoveTo` change)

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
