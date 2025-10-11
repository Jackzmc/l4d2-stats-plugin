enum struct WeaponStatistics {
	float minutesUsed;
	int totalDamage;
	int headshots;
	int kills;
}

#define MAX_VALID_WEAPONS 19
char VALID_WEAPONS[MAX_VALID_WEAPONS][] = {
	"weapon_melee", "weapon_chainsaw", "weapon_rifle_sg552", "weapon_smg", "weapon_rifle_ak47", "weapon_rifle", "weapon_rifle_desert", "weapon_pistol", "weapon_pistol_magnum", "weapon_autoshotgun", "weapon_shotgun_chrome", "weapon_sniper_scout", "weapon_sniper_military", "weapon_sniper_awp", "weapon_smg_silenced", "weapon_smg_mp5", "weapon_shotgun_spas", "weapon_rifle_m60", "weapon_pumpshotgun"
};

enum struct ActiveWeaponData {
	StringMap pendingStats;
	char classname[32];
	int pickupTime;
	int damage;
	int kills;
	int headshots;

	void Init() {
		this.Reset();
		this.pendingStats = new StringMap();
	}

	void Reset(bool full = false) {
		this.classname[0] = '\0';
		this.damage = 0;
		this.kills = 0;
		this.headshots = 0;
		this.pickupTime = 0;
		if(full) {
			this.Flush();
		}
	}

	void Flush() {
		if(this.pendingStats != null) {
			this.pendingStats.Clear();
		}
	}

	void SetActiveWeapon(int weapon) {
		if(this.pendingStats == null || !IsValidEntity(weapon)) return;

		// If there was a previous active weapon, up its data before we reset
		if(this.classname[0] != '\0') {
			WeaponStatistics stats;
			this.pendingStats.GetArray(this.classname, stats, sizeof(stats));
			stats.totalDamage += this.damage;
			stats.kills += this.kills;
			stats.headshots += this.headshots;
			if(this.pickupTime != 0)
				stats.minutesUsed += (GetTime() - this.pickupTime);
			this.pendingStats.SetArray(this.classname, stats, sizeof(stats));
		}

		// Reset the data for the new cur weapon
		this.Reset();

		// Check if it's a valid weapon
		char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));
		for(int i = 0; i < MAX_VALID_WEAPONS; i++) {
			if(StrEqual(VALID_WEAPONS[i], classname)) {
				this.pickupTime = GetTime();
				if(StrEqual(classname, "weapon_melee")) {
					GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", this.classname, sizeof(this.classname));
				} else {
					strcopy(this.classname, sizeof(this.classname), classname);
				}
				break;
			}
		}
	}
}