-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: 45.33.30.87:3306
-- Generation Time: Apr 22, 2021 at 10:02 AM
-- Server version: 10.3.27-MariaDB-0+deb10u1-log
-- PHP Version: 7.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `left4dead2`
--

-- --------------------------------------------------------

--
-- Table structure for table `stats_games`
--
-- Creation: Apr 06, 2021 at 04:51 PM
-- Last update: Apr 22, 2021 at 02:50 PM
--

CREATE TABLE `stats_games` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `steamid` varchar(20) NOT NULL,
  `map` varchar(128) NOT NULL,
  `flags` tinyint(4) NOT NULL DEFAULT 0,
  `campaignID` varchar(255) DEFAULT NULL,
  `gamemode` varchar(30) CHARACTER SET ascii DEFAULT NULL,
  `difficulty` tinyint(1) NOT NULL DEFAULT 0,
  `date_start` bigint(20) UNSIGNED DEFAULT NULL,
  `date_end` bigint(20) NOT NULL,
  `finale_time` int(11) UNSIGNED NOT NULL,
  `ZombieKills` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `SurvivorDamage` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `MedkitsUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `PillsUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `MolotovsUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `PipebombsUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `BoomerBilesUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `AdrenalinesUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `DefibrillatorsUsed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `DamageTaken` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `ReviveOtherCount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `FirstAidShared` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `Incaps` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `Deaths` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `MeleeKills` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `ping` tinyint(3) UNSIGNED DEFAULT NULL,
  `boomer_kills` int(10) UNSIGNED DEFAULT NULL,
  `smoker_kills` int(10) UNSIGNED DEFAULT NULL,
  `jockey_kills` int(10) UNSIGNED DEFAULT NULL,
  `hunter_kills` int(10) UNSIGNED DEFAULT NULL,
  `spitter_kills` int(10) UNSIGNED DEFAULT NULL,
  `charger_kills` int(10) UNSIGNED DEFAULT NULL,
  `server_tags` text DEFAULT NULL,
  `characterType` tinyint(3) UNSIGNED DEFAULT NULL,
  `SpecialInfectedKills` int(10) UNSIGNED GENERATED ALWAYS AS (`boomer_kills` + `spitter_kills` + `jockey_kills` + `charger_kills` + `hunter_kills` + `smoker_kills`) VIRTUAL,
  `honks` smallint(5) UNSIGNED DEFAULT 0,
  `top_weapon` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- RELATIONSHIPS FOR TABLE `stats_games`:
--   `steamid`
--       `stats_users` -> `steamid`
--

-- --------------------------------------------------------

--
-- Table structure for table `stats_users`
--
-- Creation: Feb 18, 2021 at 04:20 AM
-- Last update: Apr 22, 2021 at 02:51 PM
--

CREATE TABLE `stats_users` (
  `steamid` varchar(20) NOT NULL,
  `last_alias` varchar(32) NOT NULL,
  `last_join_date` bigint(11) NOT NULL,
  `created_date` bigint(11) NOT NULL,
  `connections` int(11) UNSIGNED NOT NULL DEFAULT 1,
  `country` varchar(45) NOT NULL,
  `points` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `survivor_deaths` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `infected_deaths` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `survivor_damage_rec` bigint(11) UNSIGNED NOT NULL DEFAULT 0,
  `survivor_damage_give` bigint(11) UNSIGNED NOT NULL DEFAULT 0,
  `infected_damage_rec` bigint(11) UNSIGNED NOT NULL DEFAULT 0,
  `infected_damage_give` bigint(11) UNSIGNED NOT NULL DEFAULT 0,
  `pickups_molotov` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `pickups_pipe_bomb` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `survivor_incaps` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `pills_used` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `defibs_used` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `adrenaline_used` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `heal_self` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `heal_others` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `revived` int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Times themselves revived',
  `revived_others` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `pickups_pain_pills` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `melee_kills` int(11) UNSIGNED DEFAULT 0,
  `tanks_killed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `tanks_killed_solo` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `tanks_killed_melee` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `survivor_ff` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `common_kills` int(10) UNSIGNED DEFAULT 0,
  `common_headshots` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `door_opens` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `damage_to_tank` int(10) UNSIGNED DEFAULT 0,
  `damage_as_tank` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `damage_witch` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `minutes_played` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `finales_won` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_smoker` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_boomer` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_hunter` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_spitter` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_jockey` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_charger` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_witch` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `packs_used` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `ff_kills` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `throws_puke` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `throws_molotov` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `throws_pipe` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `damage_molotov` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_molotov` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_pipe` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `kills_minigun` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `caralarms_activated` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `witches_crowned` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `witches_crowned_angry` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `smokers_selfcleared` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `rocks_hitby` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `hunters_deadstopped` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `cleared_pinned` int(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Times cleared a survivor thats pinned',
  `times_pinned` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `clowns_honked` smallint(5) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- RELATIONSHIPS FOR TABLE `stats_users`:
--

--
-- Indexes for dumped tables
--

--
-- Indexes for table `stats_games`
--
ALTER TABLE `stats_games`
  ADD PRIMARY KEY (`id`),
  ADD KEY `userindex` (`steamid`);

--
-- Indexes for table `stats_users`
--
ALTER TABLE `stats_users`
  ADD PRIMARY KEY (`steamid`),
  ADD KEY `points` (`steamid`);
ALTER TABLE `stats_users` ADD FULLTEXT KEY `last_alias` (`last_alias`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `stats_games`
--
ALTER TABLE `stats_games`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `stats_games`
--
ALTER TABLE `stats_games`
  ADD CONSTRAINT `matchUser` FOREIGN KEY (`steamid`) REFERENCES `stats_users` (`steamid`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
