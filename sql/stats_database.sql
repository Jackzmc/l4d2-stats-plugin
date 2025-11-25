/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.6.22-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: ovh1    Database: left4dead2
-- ------------------------------------------------------
-- Server version	11.8.3-MariaDB-deb12-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping routines for database 'left4dead2'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `left4dead2.cleanup_log`()
BEGIN
  	SELECT * FROM `activity_log` 
	WHERE `timestamp` < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE PROCEDURE `stats_points_reset_next`()
begin
    DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
        ROLLBACK;
    -- record points for this period
    insert into stats_points_history (period_start, period_end, steamid, points)
        select points_start_time, unix_timestamp(), steamid, points from stats_users where points > 0;

    -- add to cumulation and res
    update stats_users SET points_cuml=points_cuml+points;

    -- reset current points
    update stats_users SET points=0, points_start_time=unix_timestamp();
    delete from stats_points;

    commit;
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

create event stats_points_reset on schedule
    every '1' MONTH
    enable
    do
    CALL stats_points_reset_next();

--
-- Table structure for table `stats_weapon_usages`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_weapon_usages` (
  `steamid` varchar(32) NOT NULL,
  `weapon` varchar(64) NOT NULL,
  `minutesUsed` float NOT NULL,
  `totalDamage` bigint(20) NOT NULL,
  `headshots` int(11) NOT NULL,
  `kills` int(11) NOT NULL,
  PRIMARY KEY (`steamid`,`weapon`),
  CONSTRAINT `stats_weapon_usages_stats_users_steamid_fk` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_weapon_names`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_weapon_names` (
  `id` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `melee` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wstats_eapon_names`
--

insert into left4dead2.stats_weapon_names (id, name, melee)
values  ('baseball_bat', 'Baseball Bat', 1),
        ('cricket_bat', 'Cricket Bat', 1),
        ('crowbar', 'Crowbar', 1),
        ('didgeridoo', 'Didgeridoo', 1),
        ('electric_guitar', 'Guitar', 1),
        ('fireaxe', 'Fire Axe', 1),
        ('frying_pan', 'Frying Pan', 1),
        ('golfclub', 'Golf Club', 1),
        ('katana', 'Katana', 1),
        ('knife', 'Knife', 1),
        ('machete', 'Machete', 1),
        ('pitchfork', 'Pitchfork', 1),
        ('shovel', 'Shovel', 1),
        ('tonfa', 'Nightstick', 1),
        ('weapon_adrenaline', 'Adrenaline', 0),
        ('weapon_autoshotgun', 'Automatic Shotgun', 0),
        ('weapon_chainsaw', 'Chainsaw', 1),
        ('weapon_defibrilator', 'Defibrillator', 0),
        ('weapon_first_aid_kit', 'First Aid Kit', 0),
        ('weapon_grenade_launcher', 'Grenade Launcher', 0),
        ('weapon_hunting_rifle', 'Hunting Rifle', 0),
        ('weapon_molotov', 'Molotov Cocktail', 0),
        ('weapon_pain_pills', 'Pain Pills', 0),
        ('weapon_pipe_bomb', 'Pipe Bomb', 0),
        ('weapon_pistol', 'Pistol', 0),
        ('weapon_pistol_magnum', 'Magnum Pistol', 0),
        ('weapon_pumpshotgun', 'Pump Shotgun', 0),
        ('weapon_rifle', 'M16', 0),
        ('weapon_rifle_ak47', 'AK-47', 0),
        ('weapon_rifle_desert', 'Combat Rifle', 0),
        ('weapon_rifle_m60', 'M60', 0),
        ('weapon_rifle_sg552', 'SG552', 0),
        ('weapon_shotgun_chrome', 'Chrome Shotgun', 0),
        ('weapon_shotgun_spas', 'SPAS Shotgun', 0),
        ('weapon_smg', 'SMG', 0),
        ('weapon_smg_mp5', 'MP5', 0),
        ('weapon_smg_silenced', 'SMG (Silenced)', 0),
        ('weapon_sniper_awp', 'AWP', 0),
        ('weapon_sniper_military', 'Military Sniper', 0),
        ('weapon_sniper_scout', 'Scout Sniper', 0),
        ('weapon_vomitjar', 'Boomer Bile', 0);

--
-- Table structure for table `stats_users`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_users` (
  steamid                     varchar(32)                                     not null comment 'steamid2' primary key,
  last_alias                  varchar(32)                                     not null comment 'last known name',
  last_join_date              bigint(11)                                      not null,
  created_date                bigint(11)                                      not null,
  connections                 int(11) unsigned       default 1                not null comment 'times joined server',
  country                     varchar(60)                                     not null,
  region                      varchar(60)                                     null,
  points                      int unsigned           default 0                not null comment 'current points earned',
  points_start_time           int unsigned           default unix_timestamp() not null comment 'unix timestamp when current points had reset',
  points_cuml                 int unsigned           default 0                not null comment 'total points earned',
  deaths                      mediumint(11) unsigned default 0                not null,
  damage_taken                int(11) unsigned       default 0                not null,
  damage_dealt                int(11) unsigned       default 0                not null,
  pickups_molotov             int(11) unsigned       default 0                not null,
  pickups_bile                mediumint(11) unsigned default 0                not null,
  pickups_pipebomb            mediumint(11) unsigned default 0                not null,
  pickups_pills               mediumint(11) unsigned default 0                not null,
  times_incapped              mediumint(11) unsigned default 0                not null,
  times_hanging               mediumint(11) unsigned default 0                not null comment 'ledge grabs',
  used_pills                  mediumint unsigned     default 0                not null,
  used_adrenaline             mediumint unsigned     default 0                not null,
  used_kit_self               mediumint unsigned     default 0                not null comment 'healed self',
  used_kit_other              mediumint unsigned     default 0                not null comment 'healed teammate',
  used_defib                  mediumint unsigned     default 0                not null,
  times_revived               mediumint unsigned     default 0                not null comment 'self got incapped',
  times_revived_other         mediumint(11) unsigned default 0                not null,
  pickups_adrenaline          mediumint unsigned                              null,
  kills_melee                 int(11) unsigned       default 0                not null comment 'kils with melee',
  kills_tank                  int(11) unsigned       default 0                not null,
  kills_tank_solo             int unsigned           default 0                not null,
  kills_tank_melee            int unsigned           default 0                not null comment 'with melee',
  damage_dealt_friendly       int unsigned           default 0                not null,
  damage_taken_friendly       int                    default 0                null comment 'ff recv',
  kills_common                int unsigned           default 0                null,
  kills_common_headshots      int unsigned           default 0                not null,
  door_opens                  int unsigned           default 0                not null,
  damage_dealt_tank           int unsigned           default 0                null,
  damage_dealt_witch          int unsigned           default 0                not null,
  finales_won                 int unsigned           default 0                not null,
  kills_smoker                int unsigned           default 0                not null,
  kills_boomer                int unsigned           default 0                not null,
  kills_hunter                int unsigned           default 0                not null,
  kills_spitter               int unsigned           default 0                not null,
  kills_jockey                int unsigned           default 0                not null,
  kills_charger               int unsigned           default 0                not null,
  kills_witch                 int unsigned           default 0                not null,
  kills_friendly              int unsigned           default 0                not null comment 'teammates killed',
  used_bile                   mediumint unsigned     default 0                not null comment 'throws',
  used_molotov                mediumint unsigned     default 0                not null comment 'throws',
  used_pipebomb               mediumint unsigned     default 0                not null comment 'throws',
  damage_dealt_fire           int unsigned           default 0                not null comment 'gascan/molotov',
  kills_fire                  int unsigned           default 0                not null comment 'gascan/molotov',
  kills_pipebomb              int unsigned           default 0                not null,
  kills_minigun               int unsigned           default 0                not null,
  caralarms_activated         smallint unsigned      default 0                not null,
  witches_crowned             int unsigned           default 0                not null,
  witches_crowned_angry       smallint unsigned      default 0                not null,
  smokers_selfcleared         int unsigned           default 0                not null,
  rocks_hitby                 int unsigned           default 0                not null,
  rocks_dodged                mediumint unsigned     default 0                not null,
  hunters_deadstopped         int unsigned           default 0                not null,
  times_cleared_pinned        mediumint unsigned     default 0                not null comment 'helped survivor that was pinned',
  times_pinned                int unsigned           default 0                not null,
  honks                       int unsigned           default 0                not null comment 'clown honks',
  times_boomed_teammates      mediumint unsigned     default 0                null comment 'popped boomer and got someone boomed',
  times_boomed_self           mediumint unsigned     default 0                null comment 'popped boomer and got self boomed',
  times_boomed                mediumint unsigned     default 0                null,
  forgot_kit_count            smallint unsigned      default 0                not null comment 'forgot kit in saferoom if some left',
  total_distance_travelled    float                  default 0                null,
  kills_all_specials          int as (`kills_boomer` + `kills_charger` + `kills_smoker` + `kills_jockey` +
                                      `kills_hunter` + `kills_spitter`),
  kits_slapped                int                    default 0                not null,
  damage_dealt_friendly_count mediumint unsigned     default 0                not null,
  damage_taken_friendly_count mediumint unsigned     default 0                null,
  used_ammopack_fire          mediumint unsigned     default 0                not null,
  used_ammopack_explosive     mediumint unsigned     default 0                not null,
  used_kit                    int as (`used_kit_self` + `used_kit_other`) comment 'any usage',
  seconds_alive               int unsigned                                    not null,
  seconds_idle                int unsigned                                    not null,
  seconds_dead                int unsigned           default 0                null,
  seconds_total               int unsigned as (`seconds_alive` + `seconds_idle` + `seconds_dead`),
  damage_taken_fall           float                                           null,
  times_shove                 mediumint                                       null,
  times_jumped                mediumint                                       null,
  bullets_fired               mediumint                                       null,
  times_incapped_fire         mediumint unsigned                              null,
  times_incapped_acid         mediumint unsigned                              null,
  times_incapped_zombie       mediumint unsigned                              null,
  times_incapped_special      mediumint unsigned                              null,
  times_incapped_tank         mediumint unsigned                              null,
  times_incapped_witch        mediumint unsigned                              null,
  KEY `points` (`steamid`),
  FULLTEXT KEY `last_alias` (`last_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_points_history`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_points_history` (
  `period_start` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'unix timestamp',
  `period_end` int(10) unsigned NOT NULL DEFAULT unix_timestamp() COMMENT 'unix timestamp',
  `steamid` varchar(32) NOT NULL,
  `points` int(10) unsigned NOT NULL,
  PRIMARY KEY (`period_end`,`steamid`),
  KEY `stats_points_history_stats_users_steamid_fk` (`steamid`),
  CONSTRAINT `stats_points_history_stats_users_steamid_fk` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_points`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL,
  `type` tinyint(3) unsigned NOT NULL,
  `amount` smallint(6) NOT NULL COMMENT 'point value',
  `timestamp` int(11) unsigned NOT NULL,
  `multiplier` tinyint(3) unsigned NOT NULL DEFAULT 1 COMMENT 'number of times to apply (merged record)',
  PRIMARY KEY (`id`),
  KEY `stats_points_stats_users_steamid_fk` (`steamid`),
  KEY `stats_points_timestamp_index` (`timestamp`),
  CONSTRAINT `stats_points_stats_users_steamid_fk` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1448492 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_names_history`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_names_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL,
  `name` varchar(64) NOT NULL,
  `created` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `stats_names_history_stats_users_steamid_fk` (`steamid`),
  CONSTRAINT `stats_names_history_stats_users_steamid_fk` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1078 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_migrations`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_migrations` (
  `id` smallint(6) NOT NULL,
  `timestamp` datetime DEFAULT NULL,
  `state` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_map_ratings`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_map_ratings` (
  `map_id` varchar(64) NOT NULL,
  `steamid` varchar(32) NOT NULL,
  `value` tinyint(4) NOT NULL,
  `comment` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`map_id`,`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_map_info`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_map_info` (
  `mission_id` varchar(64) DEFAULT NULL,
  `mapid` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `chapter_count` smallint(6) DEFAULT NULL,
  `flags` smallint(6) DEFAULT 0 COMMENT '1:official',
  PRIMARY KEY (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_heatmaps`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_heatmaps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL,
  `timestamp` int(11) NOT NULL DEFAULT unix_timestamp(),
  `map` varchar(64) NOT NULL,
  `type` smallint(6) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `z` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stats_heatmaps_stats_users_steamid_fk` (`steamid`),
  CONSTRAINT `stats_heatmaps_stats_users_steamid_fk` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=420596 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats_games`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
create table stats_games
(
    id                int unsigned auto_increment  primary key,
    uuid              uuid default uuid() not null comment 'legacy campaignID',
    date_start        bigint              not null comment 'unix timestamp',
    date_start_finale int                 null comment 'unix timestamp of finale',
    date_end          bigint              null comment 'unix timestamp',
    duration_game     bigint as (`date_end` - `date_start`) comment 'seconds of game',
    duration_finale   bigint as (`date_end` - `date_start_finale`) comment 'seconds of finale',
    map_id            varchar(64)         not null comment 'map id of last chapter',
    gamemode          varchar(64)         not null,
    difficulty        tinyint             null comment '0=easy, 1=normal, 2=advanced, 3=expert',
    server_tags       varchar(255)        not null comment 'comma separated list of tags',
    stat_version      tinyint unsigned    not null comment 'version of metrics',
    constraint uuid
        unique (uuid)
);

create index stats_games_gamemode_index
    on stats_games (gamemode);

create index stats_games_map_id_index
    on stats_games (map_id);

/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

create table stats_sessions
(
    id                          bigint unsigned auto_increment primary key,
    game_id                     int unsigned                    not null,
    steamid                     varchar(32)                     not null,
    flags                       tinyint               default 0 not null,
    join_time                   bigint unsigned                 not null comment 'when user first joined game',
    character_type              tinyint unsigned                null,
    ping                        tinyint(4) unsigned             null,
    kills_common                int unsigned          default 0 not null,
    kills_melee                 smallint(10) unsigned default 0 not null,
    damage_dealt                int unsigned          default 0 not null,
    damage_taken                int unsigned          default 0 not null,
    damage_dealt_friendly_count int unsigned          default 0 not null,
    damage_taken_friendly_count int unsigned                    null,
    damage_dealt_friendly       int unsigned                    null,
    damage_taken_friendly       int unsigned                    null,
    used_kit_self               smallint(10) unsigned default 0 not null comment 'heal self',
    used_kit_other              smallint(10) unsigned default 0 not null comment 'healed teammate',
    used_pills                  smallint(10) unsigned default 0 not null,
    used_molotov                smallint(10) unsigned default 0 not null,
    used_pipebomb               smallint(10) unsigned default 0 not null,
    used_bile                   smallint(10) unsigned default 0 not null,
    used_adrenaline             smallint(10) unsigned default 0 not null,
    used_defib                  smallint(10) unsigned default 0 not null,
    times_revived_other         smallint(10) unsigned default 0 not null,
    times_hanging               smallint unsigned     default 0 null,
    times_incapped              smallint(10) unsigned default 0 not null,
    deaths                      tinyint(10) unsigned  default 0 not null,
    kills_boomer                smallint(10) unsigned           not null,
    kills_smoker                smallint(10) unsigned           not null,
    kills_jockey                smallint(10) unsigned           not null,
    kills_hunter                smallint(10) unsigned           not null,
    kills_spitter               smallint(10) unsigned           not null,
    kills_charger               smallint(10) unsigned           not null,
    kills_all_specials          int unsigned as (`kills_boomer` + `kills_smoker` + `kills_jockey` + `kills_hunter` +
                                                 `kills_spitter` + `kills_charger`),
    kills_tank                  smallint unsigned               null,
    kills_witch                 smallint unsigned               null,
    kills_fire                  smallint unsigned               null comment 'gascan/molotov',
    kills_pipebomb              smallint unsigned               null,
    kills_minigun               smallint unsigned               null,
    honks                       smallint unsigned     default 0 null comment 'clowns honked',
    top_weapon                  varchar(64)                     null,
    witches_crowned             smallint(8) unsigned  default 0 not null,
    smokers_selfcleared         smallint(8) unsigned  default 0 not null,
    rocks_hitby                 smallint(8) unsigned  default 0 not null,
    rocks_dodged                smallint(8) unsigned  default 0 not null,
    hunters_deadstopped         smallint(8) unsigned  default 0 not null,
    times_pinned                smallint(8) unsigned  default 0 not null,
    times_cleared_pinned        smallint(8) unsigned  default 0 null comment 'helped pinned teammate',
    times_boomed_teammates      smallint unsigned     default 0 not null,
    times_boomed                smallint(8) unsigned  default 0 not null,
    damage_dealt_tank           mediumint unsigned    default 0 not null comment 'dmg to tank',
    damage_dealt_witch          mediumint unsigned    default 0 not null comment 'dmg to witch',
    caralarms_activated         tinyint unsigned      default 0 not null,
    used_kit                    smallint(11) unsigned as (`used_kit_self` + `used_kit_other`) comment 'any usage',
    longest_shot_distance       float                           null,
    seconds_alive               int unsigned                    not null,
    seconds_idle                int unsigned                    not null,
    seconds_dead                int unsigned          default 0 null,
    seconds_total               int unsigned as (`seconds_alive` + `seconds_idle` + `seconds_dead`),
    damage_taken_fall           float                           null,
    times_shove                 mediumint                       null,
    times_jumped                mediumint                       null,
    bullets_fired               mediumint                       null,
    constraint stats_games_stats_users_steamid_fk
        foreign key (steamid) references stats_users (steamid)
            on delete cascade,
    constraint stats_sessions_stats_games_id_fk
        foreign key (game_id) references stats_games (id)
            on update cascade on delete cascade
);


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-11 23:24:51
