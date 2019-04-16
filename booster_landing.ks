//FALCON 9 BOOSTER LANDING SCRIPT with SUICIDE BURN - pehus.ddns.net

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").

// FUNCTIONS & VARIABLES.

clearscreen.
set terminal:height to 7.
set terminal:width to 50.
set flightstatus to "READY. WAITING FOR MECO".
set radarOffset to 30.									// F9 booster , the value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.					// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.			// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:airspeed^2 / (2 * maxDecel).		    // The distance the burn will require
lock idealThrottle to stopDist / trueRadar.					// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:airspeed).		    // Time until impact, used for landing gear
set mecostatus to "idle".
lock decouplerstatus to ship:partsdubbedpattern("Interstage")[0]:getmodulebyindex(9):getfield("état ").




function distances {
  // 30 km for in-flight
  // Note the order is important.  set UNLOAD BEFORE LOAD,
  // and PACK before UNPACK.  Otherwise the protections in
  // place to prevent invalid values will deny your attempt
  // to change some of the values:
  SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNLOAD TO 600000.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:LOAD TO 595000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"
  SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:PACK TO 599990.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNPACK TO 590000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"

  // 30 km for parked on the ground:
  // Note the order is important.  set UNLOAD BEFORE LOAD,
  // and PACK before UNPACK.  Otherwise the protections in
  // place to prevent invalid values will deny your attempt
  // to change some of the values:
  SET KUNIVERSE:DEFAULTLOADDISTANCE:LANDED:UNLOAD TO 600000.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:LANDED:LOAD TO 595000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"
  SET KUNIVERSE:DEFAULTLOADDISTANCE:LANDED:PACK TO 699990.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:LANDED:UNPACK TO 590000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"

  // 30 km for parked in the sea:
  // Note the order is important.  set UNLOAD BEFORE LOAD,
  // and PACK before UNPACK.  Otherwise the protections in
  // place to prevent invalid values will deny your attempt
  // to change some of the values:
  SET KUNIVERSE:DEFAULTLOADDISTANCE:SPLASHED:UNLOAD TO 600000.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:SPLASHED:LOAD TO 595000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"
  SET KUNIVERSE:DEFAULTLOADDISTANCE:SPLASHED:PACK TO 599990.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:SPLASHED:UNPACK TO 590000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"

  // 30 km for being on the launchpad or runway
  // Note the order is important.  set UNLOAD BEFORE LOAD,
  // and PACK before UNPACK.  Otherwise the protections in
  // place to prevent invalid values will deny your attempt
  // to change some of the values:
  SET KUNIVERSE:DEFAULTLOADDISTANCE:PRELAUNCH:UNLOAD TO 600000.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:PRELAUNCH:LOAD TO 595000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"
  SET KUNIVERSE:DEFAULTLOADDISTANCE:PRELAUNCH:PACK TO 599990.
  SET KUNIVERSE:DEFAULTLOADDISTANCE:PRELAUNCH:UNPACK TO 590000.
  WAIT 0.001. // See paragraph above: "wait between load and pack changes"
}

function pause {      // affiche la télémétrie en continu au lieu de freeze. muahahah.
    parameter pause_time.
    set start_time to time:seconds.
    lock elapsed_time to (time:seconds - start_time).
  until elapsed_time > pause_time {data.}
}

function data {
	clearscreen.
  	print "F9 BOOSTER  " + char(9632) + "  " + flightstatus.
  	print "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯".
  	print " ".
  	print "ALTITUDE : " + round(trueradar) + " m.".
  	print "AIR SPEED : " + round(ship:airspeed, 1) + " m/s.".
    print "VERT. SPEED : " + round(ship:verticalspeed, 1) + " m/s.".
    // IF ship:verticalspeed < -10 {
    // print "IMPACT TIME : " + round(impactTime) + " m.".}
    wait 0.1.
}

function afterMeco {
    set flightstatus to "WAITING FOR DESCENT".
    data.
        
}

function checkInbox {
    when not ship:messages:empty then {    
        set messageReceived to 0.
        set messageReceived to ship:messages:pop.
        set mecostatus to messagereceived:content.
        }
}

function falling {
    set flightstatus to "SETTING RETROGRADE".
    data.
	sas off.
    brakes on.
    lock steering to srfretrograde.
    rcs on.
    set flightstatus to "CENTRAL ENGINE IGNITION".
    pause(1).
    ship:partsdubbedpattern("engine")[0]:getmodule("Multimodeengine"):doevent("changer mode").
    pause(3).
    set flightstatus to "WAITING FOR FINAL BURN".
}

function suicideburn {
    SET flightstatus TO "FINAL BURN".
    data.
    lock throttle to idealThrottle.
}

function landing {
    ship:partsdubbedpattern("land")[0]:getmodule("modulewheeldeployment"):doevent("étendre").
    when trueradar < 10 then {lock steering to up.}
    data.
}

function landed {
    set flightstatus to "LANDED".
    data.
    set ship:control:pilotmainthrottle to 0.
	unlock steering.
	rcs off.
	sas off.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////  PROGRAM   //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


data().
distances().
checkinbox().

// detection meco

// until throttle < 1 and alt:radar > 10000  { data().}
// when throttle < 1 and alt:radar > 10000 then {
until mecostatus = ("MECO CONFIRMED") or decouplerstatus = ("Extinction !") {
    data().
}

set flightstatus to ("MECO CONFIRMED").
pause(3).

aftermeco().

when ship:verticalspeed < -10 then {falling.}
	
when trueRadar < stopDist then {suicideburn.}

when impactTime < 5 then {landing.}

when ship:verticalspeed > -0.01 and trueradar < 100 then {landed.}

until flightstatus = "LANDED" {data.}

// Fin du programme :
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
clearscreen.
print "F9 BOOSTER  " + char(9632) + "  " + flightstatus.
print "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯".
