// FALCON 9 WITH PAYLOAD FLIGHT SCRIPT - pehus.ddns.net



// PARAMETRES DE VOL :

set fuelStockDesired to 20.                     // Quantité de fuel restante pour le landing burn, minimum 15, en %.
set apoapsisDesired to 135000.                   // Apoapsis de l'orbite souhaitée.
set cap to 90.                                  // Cap de mise en orbite.


// Variables et fonctions

set flightstatus to "GOOD LUCK !".
set f9tank to SHIP:PARTSTAGGED("F9TANK")[0].
set marlin to SHIP:PARTSTAGGED("MARLIN")[0].
set countdown to 3.
lock f9_fuel to f9tank:resources[0].
lock f9capacity to f9_fuel:capacity.
lock f9amount to f9_fuel:amount.
set mecoprogress to 1.
set burnduration to 0.
set circ_node to 0.



// Paramètres kOs

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
set terminal:height to 24.
set terminal:width to 50.
clearscreen.



function pause {      //affiche la télémétrie en continu au lieu de freeze. muahahah.
    parameter pause_time.
    set start_time to time:seconds.
    lock elapsed_time to (time:seconds - start_time).
  until elapsed_time > pause_time {affichage_data.}
}

function distances {
  // 300 km for in-flight
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

function affichage_data {
  parameter flightstatus is flightstatus. // pour devenir un paramètre facultatif quand affichagedata().
  clearscreen.
  print "F9 SECOND STAGE  " + char(9632) + "  " + flightstatus.
  print "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯". // 50 char, window size
  print " ".
  print "ALTITUDE : " + round(alt:radar) + " m.".
  print "AIR SPEED : " + round(ship:airspeed, 1) + " m/s.".
  //print "FUEL CAPACITY : " + f9_fuel:f9capacity.
  //print "FUEL AMOUNT : " + f9_fuel:f9amount.
  if mecoProgress < 100 {
    set mecoprogress to round(((-(f9amount-((fuelstockdesired*0.01)*f9capacity))/((1-(fuelstockdesired*0.01))*f9capacity))*100+100)).  
	  print " ".
    print "BURN COMPLETE : " + mecoProgress + " %".}
  if hasnode {
    print " ".
    print "BURN DURATION : " + round(burnduration) + " s.".
    if round(circ_node:eta-(burnduration/2)) > 0 {
      print "TIME TO BURN : " + round(circ_node:eta-(burnduration/2)) + " s.".}
  }

  wait 0.2.
}

function launch {
    wait 0.5.
    until countdown = 0 {
      set flightstatus to ("INITIATE SEQUENCE START :  " + countdown).
      set countdown to countdown-1.
      affichage_data.
      wait 0.5.
    }
    set flightstatus to "LIFTOFF".
    sas on.
    //stage. // a remplacer par engine ignition.
    ship:partsdubbedpattern("s1.engine")[0]:getmodulebyindex(1):doaction("activer propulseur", true).
    //set throttleTime to time:seconds.
    //when throttleTime is time:seconds+1 then {
    //  set throttletime to time:seconds
    //} 
    pause(0.3).
    set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
    when alt:radar > 80 then {gear off.}
    set targetDirection to cap.
    // lock targetPitch to 90 - 1.03287 * alt:radar^0.412387.
    lock targetpitch to 1.46028E-8*alt:radar^2 - 0.0020098*alt:radar + 92.0477.
    when alt:radar > 1000 then {
      sas off.
      set flightstatus to "GRAVITY TURN".
	    lock steering to heading(targetDirection, targetPitch).
    }
    when mecoprogress = 95 then {set flightstatus to "PREPARE FOR MECO".}
}

function decoupleurf9 {
    ship:partsdubbedpattern("interstage")[0]:getmodulebyindex(9):doaction("activer propulseur", true).
    ship:partsdubbedpattern("interstage")[0]:getmodule("ModuleDecouple"):doEvent("découpler").
}

function sendFlightStatus{
  set message to "MECO CONFIRMED".
  set destinationVesselConnexion to vessel("F9BOOSTER"):CONNECTION.
  destinationvesselConnexion:SENDMESSAGE(message).
  set flightstatus to "MESSAGE SENT !".
  
}

function meco {
  set flightstatus to "MECO".
  affichage_data.
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
  pause(2).
  decoupleurf9().
  SET flightstatus to "STAGE SEPARATION".
  pause(1).
  SET flightstatus to "STAGE SEPARATION : CONFIRMED".
  brakes off.
  rcs on.
  sas on.
  set sasMode to "PROGRADE".
  pause(0.5).
  marlin:shutdown().
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.//pour le rcs activation
  set start_time to time:seconds.
  pause(3).                               // fonction en test, si false : wait 3.
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
  affichage_data().
  pause(1).
  marlin:activate().
  sendflightstatus().
  rcs off.
  sas off.
  set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
  pause(2).
  set flightstatus to "SECOND STAGE BURN".
  affichage_data().
}

function fairingDeploy {
    set flightstatus to "FAIRING DEPLOY".
    affichage_data.
    pause(2).
    //insert separation parts
    ship:partsdubbedpattern("fairing")[1]:getmodulebyindex(1):doaction("jettison fairing", true).
    ship:partsdubbedpattern("fairing")[2]:getmodulebyindex(1):doaction("jettison fairing", true).
    //stage.
    pause(2).
    set flightstatus to "FAIRING DEPLOY : OK".
}

function solarPanel {
    set flightstatus to "SOLAR PANEL DEPLOY".
    affichage_data.
    pause(1).
    //insert deplot solar
    ship:partsdubbedpattern("solarpanel-deploying-1x3-2")[0]:getmodulebyindex(0):doaction("déployer panneau solaire", true).
    ship:partsdubbedpattern("solarpanel-deploying-1x3-2")[1]:getmodulebyindex(0):doaction("déployer panneau solaire", true).
    //ag1 on.
    pause(2).
    set flightstatus to "SOLAR PANEL DEPLOY : OK ".
    affichage_data.
    pause(2).
}

function seco {
    set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
    set flightstatus to "SECOND ENGINE CUTOFF".
}

function node_circ {
    set targetV to sqrt(ship:body:mu/(ship:orbit:body:radius + ship:orbit:apoapsis)).
    set m to ship:orbit:body:mu.
    set b to ship:orbit:SEMIMAJORAXIS.
    set con1 to 1 - ship:orbit:ECCENTRICITY.
    set con2 to 1 + ship:orbit:ECCENTRICITY.
    set div1 to con1 * m.
    set div2 to con2 * b.
    set div to div1 / div2.
    set speedAtAp to sqrt(div).
    set dv to targetV - speedAtAp.
    set circ_node to node(time:seconds + eta:apoapsis, 0, 0, dv).
    add circ_node.
    lock burnduration to circ_node:deltav:mag / (ship:maxthrust/ship:mass).

}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////  PROGRAM  ///////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SETTINGS + DISPLAY TELEMETRY
distances().
affichage_data().


// WAITING FOR KSC MISSION CONTROL GREEN LIGHT !
UNTIL AG5 {
  affichage_data("PRESS [5] TO START IGNITION").
}

// START SEQUENCE
launch().

// MECO & STAGE SEPARATION
when (f9amount < (fuelstockdesired*0.01) * f9capacity) then { meco(). }

// FAIRING DEPLOY
when (alt:radar > 60000) then { fairingdeploy(). }

// SOLAR PANELS DEPLOY 
// when (alt:radar > 62000) then { solarPanel().}

// WAITING SECO
//when (alt:radar > 65000) then { set flightstatus to "WAITING FOR SECOND BURN".}

// SECO and SECOND BURN
when alt:apoapsis > apoapsisDesired then { 
  seco().
  pause(1).
  node_circ().
  affichage_data("WAITING FOR SECOND BURN").

  rcs on.
  lock steering to circ_node:deltav.

  when circ_node:eta < burnduration/2 then {
    set flightstatus to "SECOND BURN : CIRCULARIZE".
    set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
    set node_burn_timedeparture to time:seconds.
    when circ_node:deltav:mag < 100 then {
      set ship:control:pilotmainthrottle to 0.5.
    }
    when circ_node:deltav:mag < 30 then {
      set ship:control:pilotmainthrottle to 0.2.
    }
  }
  // FIN DE CIRCULARISATION
  when circ_node:deltav:mag < 1 then {
      set ship:control:pilotmainthrottle to 0.
      unlock steering.
      remove circ_node.
      set flightstatus to "EN ORBITE !".
  }
}

// SOLAR PANELS DEPLOY
when flightstatus = ("EN ORBITE !") then {
  pause (2).
  solarPanel().
  SET flightstatus TO "EN ORBITE !".
}


until AG6 {
  affichage_data().
}

SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
clearscreen.
print "END OF PROGRAM".
print "CONTROLS RELEASED".

