enum PointRecordType {
	PType_Invalid = 0,
	PType_FinishCampaign,
	PType_CommonKill,
	PType_SpecialKill,
	PType_TankKill,
	PType_WitchKill,
	PType_TankKill_Solo,
	PType_TankKill_Melee,
	PType_Headshot,
	PType_FriendlyFire,
	PType_HealOther,
	PType_ReviveOther,
	PType_ResurrectOther,
	PType_DeployAmmo,
	PType_FriendlyKilled,
	PType_WitchCrowned,
	PType_SelfClearSmoker,
	PType_HunterDeadstopped,

	PType_Count
}
int PointValueDefaults[PType_Count] = {
	0, // Generic
	0, // Finish Campaign - don't assign any value as tank kills / other stats should take in
	1, // Common Kill
	6, // Special Kill
	200, // Tank Kill
	25, // Witch Kill
	100, // Tank Kill (Solo)  [bonus to tank kill]
	50, // Tank Kill (Melee) [bonus to tank kill]
	4, // Headshot kill (commons only) [bonus to common kill]
	-5, // Friendly Fire
	50, // Heal Other
	25, // Revive Other
	50, // Defib Other
	5, // Deploy Special Ammo
	-500, // Friendly killed
	100, // Witch crowned
	10, // Self cleared smoker
	10, // Hunter dead stopped
};