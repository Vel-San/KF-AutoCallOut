//=============================================================================
// Automatically sends a message to all players with how many Scrakes &
// FleshPounds are currently spawned
// Written by Vel-San
// for more information, feedback, questions or requests please contact
// https://steamcommunity.com/id/Vel-San/
//=============================================================================

Class KFAutoCallOut extends Mutator config(KFAutoCallOut);

var() config bool bDEBUG;
var() config string sWarningMSG;
var() config int iDelay;

var bool DEBUG;
var string WarningMSG;
var int Delay;

// Colors from Config
struct ColorRecord
{
  var config string ColorName; // Color name, for comfort
  var config string ColorTag; // Color tag
  var config Color Color; // RGBA values
};
var() config array<ColorRecord> ColorList; // Color list

replication
{
	unreliable if (Role == ROLE_Authority)
		sWarningMSG, iDelay, bDEBUG,
		WarningMSG, Delay, DEBUG;
}

simulated function PostBeginPlay()
{
	TimeStampLog("-----|| Server Vars Replicated ||-----");

  WarningMSG = sWarningMSG;
  Delay = iDelay;
	DEBUG = bDEBUG;

  // TO-DO Complete this to show player name who sees Fleshpounds and Scrakes first
  // MutLog("-----|| Changing SC & FP Controller ||-----");
  // class'ZombieFleshpound'.Default.ControllerClass = Class'FPCustomController';
  // class'ZombieScrake'.Default.ControllerClass = Class'SCCustomController';

  if(DEBUG){
    MutLog("-----|| DEBUG - MSG: " $WarningMSG$ " ||-----");
    MutLog("-----|| DEBUG - Delay: " $Delay$ " ||-----");
  }

	SetTimer( Delay, true);
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);
  PlayInfo.AddSetting("KFAutoCallOut", "sWarningMSG", "Warning Message", 0, 0, "text");
  PlayInfo.AddSetting("KFAutoCallOut", "iDelay", "MSG Frequency", 0, 0, "text");
  PlayInfo.AddSetting("KFAutoCallOut", "bDEBUG", "DEBUG", 0, 0, "check");
}

static function string GetDescriptionText(string SettingName)
{
	switch(SettingName)
	{
    case "sWarningMSG":
			return "Message to show players about SCs & FPs number. Use %FP for Fleshpounds & %SC for Scrakes";
    case "iDelay":
			return "How often will the warning message be sent out ( in Seconds ) | Preffered 5";
		case "bDEBUG":
			return "Shows some Debugging messages in the LOG. Keep OFF unless you know what you are doing!";
		default:
			return Super.GetDescriptionText(SettingName);
	}
}

simulated function TimeStampLog(coerce string s)
{
  log("["$Level.TimeSeconds$"s]" @ s, 'AutoCallOut');
}

simulated function MutLog(string s)
{
  log(s, 'AutoCallOut');
}

function Timer()
{
  local string tmpMSG, sFP, sSC;;
  local int iFP, iCountFP, iSC, iCountSC;

	iFP = CheckFleshPoundCount(iCountFP);
  iSC = CheckScrakeCount(iCountSC);
  sFP = string(iFP);
  sSC = string(iSC);
  tmpMSG = WarningMSG;

  ReplaceText(tmpMSG, "%FP", sFP);
  ReplaceText(tmpMSG, "%SC", sSC);

  if (iFP != 0 || iSC != 0){
    BroadcastMSG(tmpMSG);
  }

  if(DEBUG){
	  MutLog("-----|| DEBUG - FP Count: " $iFP$ "x | SC Count: " $iSC$ "x ||-----");
    MutLog("-----|| DEBUG - WarningMSG: " $tmpMSG$ " ||-----");
  }
}

// TO-DO Decrease count if FP or SC Killed is killed, to keep the number always up to date
function int CheckFleshPoundCount(int i){
  local KFMonster Monster;

  foreach DynamicActors(class'KFMonster', Monster){
    if (Monster.isA('ZombieFleshpound')){
        i = i + 1;
        	/*if(DEBUG){
	          MutLog("-----|| DEBUG - FP Controller: " $Monster.ControllerClass$ " ||-----");
	        }*/
    }
  }
  return i;
}

// TO-DO Decrease count if FP or SC Killed, to keep the number always up to date
function int CheckScrakeCount(int j){
  local KFMonster Monster;

  foreach DynamicActors(class'KFMonster', Monster){
    if (Monster.isA('ZombieScrake')){
        j = j + 1;
        /*if(DEBUG){
	          MutLog("-----|| DEBUG - SC Controller: " $Monster.ControllerClass$ " ||-----");
	        }*/
    }
  }
  return j;
}

/////////////////////////////////////////////////////////////////////////
// BELOW SECTION IS CREDITED FOR ServerAdsKF Mutator | NikC	& DeeZNutZ //

// Send MSG to Players
event BroadcastMSG(coerce string Msg)
{
  local PlayerController pc;
  local Controller c;
  local string strTemp;

  // Apply Colors to MSG
  SetColor(Msg);

  for(c = level.controllerList; c != none; c = c.nextController)
  {
    // Allow only player controllers
    if(!c.isA('PlayerController'))
      continue;

    pc = PlayerController(c);
    if(pc == none)
      continue;

    // Remove colors for server log and WebAdmin
    if(pc.PlayerReplicationInfo.PlayerID == 0)
    {
      strTemp = RemoveColor(Msg);
      pc.teamMessage(none, strTemp, 'KFAutoCallOut');
      continue;
    }

    pc.teamMessage(none, Msg, 'KFAutoCallOut');
  }
}

// Apply Color Tags To Message
function SetColor(out string Msg)
{
  local int i;
  for(i=0; i<ColorList.Length; i++)
  {
    if(ColorList[i].ColorTag!="" && InStr(Msg, ColorList[i].ColorTag)!=-1)
    {
      ReplaceText(Msg, ColorList[i].ColorTag, FormatTagToColorCode(ColorList[i].ColorTag, ColorList[i].Color));
    }
  }
}

// Format Color Tag to ColorCode
function string FormatTagToColorCode(string Tag, Color Clr)
{
  Tag=Class'GameInfo'.Static.MakeColorCode(Clr);
  Return Tag;
}

function string RemoveColor(string S)
{
  local int P;
  P=InStr(S,Chr(27));
  While(P>=0)
  {
    S=Left(S,P)$Mid(S,P+4);
    P=InStr(S,Chr(27));
  }
  Return S;
}
//////////////////////////////////////////////////////////////////////


defaultproperties
{
	// Mut Vars
  GroupName="KF-AutoCallOut"
  FriendlyName="FP & SC Auto Call Out - v1.0"
  Description="Automatically calls out FPs & SCs as a broadcast message to all players; By Vel-San"
  bAlwaysRelevant=True
  RemoteRole=ROLE_SimulatedProxy
	bNetNotify=True
}
