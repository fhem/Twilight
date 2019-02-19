# $Id$
##############################################################################
#
#   59_Twilight.pm
#
#   Copyright by
#       Sebastian Stuecker
#       Dietmar Ortmann
#       Christoph Morrison, jeschkec <fhem@christoph-jeschke.de>
#
#   used algorithm see:          http://lexikon.astronomie.info/zeitgleichung/
#
#   Sun position computing
#   Copyright (C) 2013 Julian Pawlowski, julian.pawlowski AT gmail DOT com
#   based on Twilight.tcl  http://www.homematic-wiki.info/mw/index.php/TCLScript:twilight
#   With contribution from http://www.ip-symcon.de/forum/threads/14925-Sonnenstand-berechnen-(Azimut-amp-Elevation)
#
#   This file is part of FHEM.
#
#   This program is free software; you can redistribute it and/or modify it under
#   the terms of  the GNU General Public License as published by the Free Software
#   Foundation; either version 2 of the License, or  (at your option) any later
#   version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE. See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   this program; if not, write to the Free Software Foundation, Inc., 51 Franklin St,
#   Fifth Floor, Boston, MA 02110, USA
#
##############################################################################

package Twilight;

use strict;
use v5.10;
use warnings FATAL => 'all';
use Date::Parse;
use POSIX;
use Data::Dumper;
use English;
use Math::Trig ':pi';
use Time::Piece;
use Time::Local 'timelocal_nocheck';

require '95_Astro.pm';

use feature qw(switch);
no if $] >= 5.017011, warnings => 'experimental';

our $Twilight;
our $rad = 180./pi;
our $time_delta = 65;

sub Debug(@) {
    $OFS = ", ";
    ::Debug("@_") if ::AttrVal("global", "verbose", undef) eq "5";
}

sub Define($$) {
    my ( $hash, $device_definition ) = @_;
    my @definition_arguments = split( "[ \t][ \t]*", $device_definition );
    my $definition_length = int(@definition_arguments);

    return
        "syntax: define <name> Twilight [Latitude|global] [Longitude|global] [Indoor Horizon] [deprecated: Yahoo Weather ID]"
        unless ( $definition_length ~~ [1..6] );

    my ($name, $module, $latitude, $longitude, $indoor_horizon, $yahoo_weather) = @definition_arguments[0 .. 5];

    Debug("Latitude before check: " . Dumper($latitude));

    # check if latitude is set in global when no latitude is given or the keyword "global" is set
    if (!$latitude or ($latitude eq "global")) {
        $latitude = ::AttrVal("global", "latitude", undef);
    }

    Debug("Lat after global check: ". Dumper($latitude));

    return "[$name] Latitude is not globally set nor set for $name, you have to set one." unless $latitude;

    if ( $latitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $latitude !~ /^[\. ]*$/ ) {
        $latitude = 90 if ( $latitude > 90 );
        $latitude = -90 if ( $latitude < -90 );
    }
    else {
        return "[$name] Latitude '$latitude' seems not to be valid!";
    }

    Debug("Longitude before check: " . Dumper($longitude));

    # check if longitude is set in global when no longitude is given or the keyword "global" is set
    if (!$longitude or ($longitude eq "global")) {
        $longitude = ::AttrVal("global", "longitude", undef);
    }

    Debug("Longitude after global check: ". Dumper($longitude));

    return "[$name] Longitude is not globally set nor set for $name, you have to set one." unless $longitude;

    if ( $longitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $longitude !~ /^[\. ]*$/ ) {
        $longitude = 180 if ( $longitude > 180 );
        $longitude = -180 if ( $longitude < -180 );
    }
    else {
        return "[$name] Longitude '$longitude' seems not to be valid!";
    }

    if ( $indoor_horizon ) {
        Debug("Indoor horzion is set: " . Dumper($indoor_horizon));
        Debug("indoor horizon between -6 and 20") if $indoor_horizon ~~ [-6..20];
        Debug("indoor horizon not between -6 and 20") unless $indoor_horizon ~~ [-6..20];

        return "[$name] Indoor horizon '$indoor_horizon' is not a valid, must be between -6 and 20"
            unless ( $indoor_horizon ~~ [-6..20] );

        $indoor_horizon = int $indoor_horizon;
    }
    else
    {
        $indoor_horizon = 0;
    }

    ::Log3($name, 3,
            "Setting a Yahoo Weather ID is deprecated and has no further effect. "
        .   "Please consider modifying $name.") if $yahoo_weather;

    Debug($device_definition);
    Debug(Dumper(@definition_arguments));
    Debug(Dumper($hash));
    Debug(Dumper($name));
    Debug(Dumper($latitude));
    Debug(Dumper($longitude));
    Debug(Dumper($indoor_horizon));

    $hash->{STATE}              = 0;
    $hash->{LONGITUDE}          = $longitude;
    $hash->{LATITUDE}           = $latitude;
    $hash->{INDOOR_HORIZON}     = $indoor_horizon;
    $hash->{WEATHER}            = "deprecated";
    $hash->{WEATHER_HORIZON}    = "deprecated";
    $hash->{SUNPOS_OFFSET}      = 300;

    $Twilight = $hash;

    Debug("Global data is: " . Dumper($Twilight));

    CalcSunPos();

    return undef;
}

sub Undefine($$) {

}

sub Set($$) {

}

sub Get($$) {

}

sub Attr($$) {

}

sub Notify($$) {

}

sub CalcSunPos() {
    my ($latitude, $longitude) = ($Twilight->{LATITUDE}, $Twilight->{LONGITUDE});

    ::Log3(
        $Twilight->{NAME}, 5,"Computing sun position for $latitude, $longitude"
    );

    Debug("Azimuth time: " . localtime->strftime('%Y-%m-%d %H:%M:%S'));
    my $azimuth = ::Astro_Get($::defs{"global"}, "global", "text", "SunAz", localtime->strftime('%Y-%m-%d %H:%M:%S'));
    Debug("Azimuth: " . $azimuth);

    ::readingsBeginUpdate($Twilight);
        ::readingsBulkUpdate($Twilight, "azimuth", $azimuth);
    ::readingsEndUpdate($Twilight, defined ($Twilight->{LOCAL} ? 0 : 1));

=pod
    my ($pi, $twopi, $rad, $earth_radius, $astronimical_unit) = (pi, pi2, pi / 180, 6371.01, 149597890);

    # Calculate time of the day in UT decimal hours
    my $decimal_hours = $hours + $minutes / 60.0 + $seconds / 3600;
    Debug("Decimal hours: " . $decimal_hours);



    my $omega           = 2.1429 - 0.0010394594 * $julian_days;
    my $mean_longitude  = 4.8950630 + 0.017202791698 * $julian_days;
    my $mean_anomaly    = 6.2400600 + 0.0172019699 * $julian_days;
    my $ecliptic_longitude =
        $mean_longitude +
            0.03341607 * sin($mean_anomaly) +
            0.00034894 * sin( 2 * $mean_anomaly ) - 0.0001134 -
            0.0000203  * sin($omega);
    my $ecliptic_obliquity =
        0.4090928 - 6.2140e-9 * $julian_days + 0.0000396 * cos($omega);

    my $ecliptic_longitude_sin = sin $ecliptic_longitude;
    my $y1 = cos $ecliptic_obliquity * $ecliptic_longitude

    ############### OLD STUFF ###############

  my $dSin_EclipticLongitude = sin($dEclipticLongitude);
    my $dY1             = cos($dEclipticObliquity) * $dSin_EclipticLongitude;
    my $dX1             = cos($dEclipticLongitude);
    my $dRightAscension = atan2( $dY1, $dX1 );
    if ( $dRightAscension < 0.0 ) {
        $dRightAscension = $dRightAscension + $twopi;
    }
    my $dDeclination =
      asin( sin($dEclipticObliquity) * $dSin_EclipticLongitude );

    # Calculate local coordinates ( azimuth and zenith angle ) in degrees
    my $dGreenwichMeanSiderealTime =
      6.6974243242 + 0.0657098283 * $dElapsedJulianDays + $dDecimalHours;

    my $dLocalMeanSiderealTime =
      ( $dGreenwichMeanSiderealTime * 15 + $dLongitude ) * $rad;
    my $dHourAngle         = $dLocalMeanSiderealTime - $dRightAscension;
    my $dLatitudeInRadians = $dLatitude * $rad;
    my $dCos_Latitude      = cos($dLatitudeInRadians);
    my $dSin_Latitude      = sin($dLatitudeInRadians);
    my $dCos_HourAngle     = cos($dHourAngle);
    my $dZenithAngle       = (
        acos(
            $dCos_Latitude * $dCos_HourAngle * cos($dDeclination) +
              sin($dDeclination) * $dSin_Latitude
        )
    );
    my $dY = -sin($dHourAngle);
    my $dX =
      tan($dDeclination) * $dCos_Latitude - $dSin_Latitude * $dCos_HourAngle;
    my $dAzimuth = atan2( $dY, $dX );
    if ( $dAzimuth < 0.0 ) { $dAzimuth = $dAzimuth + $twopi }
    $dAzimuth = $dAzimuth / $rad;

    # Parallax Correction
    my $dParallax =
      ( $dEarthMeanRadius / $dAstronomicalUnit ) * sin($dZenithAngle);
    $dZenithAngle = ( $dZenithAngle + $dParallax ) / $rad;
    my $dElevation = 90 - $dZenithAngle;

    my $twilight = int( ( $dElevation + 12.0 ) / 18.0 * 1000 ) / 10;
    $twilight = 100 if ( $twilight > 100 );
    $twilight = 0   if ( $twilight < 0 );

    my $twilight_weather;


=cut

}

sub Midnight() {

}

1;

package main;

=head1 FHEM INIT FUNCTION

=head2 Twilight_Initialize($)

FHEM I<Initialize> function

=over

=item * param hash: hash for the Ovulation_Calendar device

=back

=cut

sub Twilight_Initialize($)
{
    my ($hash) = @_;

    $hash->{DefFn}      =   "Twilight::Define";
    $hash->{UndefFn}    =   "Twilight::Undefine";
    $hash->{SetFn}      =   "Twilight::Set";
    $hash->{GetFn}      =   "Twilight::Get";
    $hash->{AttrFn}     =   "Twilight::Attr";
    $hash->{NotifyFn}   =   "Twilight::Notify";
    $hash->{AttrList}   =   join(' ',
        ('useExtWeather'. 'debug')
    ) . " $readingFnAttributes";
}

__END__

=pod

package main;
use strict;
use warnings;
use POSIX;
use HttpUtils;
use Math::Trig ':pi';
use Time::Local 'timelocal_nocheck';

use v5.20;
use Data::Dumper;

sub Twilight_calc($$);
sub Twilight_my_gmt_offset();
sub Twilight_midnight_seconds($);

################################################################################
sub Twilight_Initialize($) {
    my ($hash) = @_;

    # Consumer
    $hash->{DefFn}    = "Twilight_Define";
    $hash->{UndefFn}  = "Twilight_Undef";
    $hash->{GetFn}    = "Twilight_Get";
    $hash->{AttrList} = "$readingFnAttributes " . "useExtWeather";
    return undef;
}
################################################################################
sub Twilight_Get($@) {
    my ( $hash, @a ) = @_;
    return "argument is missing" if ( int(@a) != 2 );

    my $reading = $a[1];
    my $value;

    if ( defined( $hash->{READINGS}{$reading} ) ) {
        $value = $hash->{READINGS}{$reading}{VAL};
    }
    else {
        return "no such reading: $reading";
    }
    return "$a[0] $reading => $value";
}
################################################################################
sub Twilight_Define($$) {
    my ( $hash, $def ) = @_;

    my @a = split( "[ \t][ \t]*", $def );

    return
      "syntax: define <name> Twilight <latitude> <longitude> [indoor_horizon]"
      if ( int(@a) < 4 && int(@a) > 6 );

    $hash->{STATE} = "0";

    my $latitude;
    my $longitude;
    my $name = $a[0];
    $hash->{NAME} = $name;

    if ( $a[2] =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $a[2] !~ /^[\. ]*$/ ) {
        $latitude = $a[2];
        if ( $latitude > 90 )  { $latitude = 90; }
        if ( $latitude < -90 ) { $latitude = -90; }
    }
    else {
        return "Argument Latitude is not a valid number";
    }

    if ( $a[3] =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $a[3] !~ /^[\. ]*$/ ) {
        $longitude = $a[3];
        if ( $longitude > 180 )  { $longitude = 180; }
        if ( $longitude < -180 ) { $longitude = -180; }
    }
    else {
        return "Argument Longitude is not a valid number";
    }

    my $weather        = 0;
    my $indoor_horizon = 0;

    if ( int(@a) > 4 ) {
        if ( $a[4] =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $a[4] !~ /^[\. ]*$/ ) {
            $indoor_horizon = $a[4];
            if ( $indoor_horizon > 20 ) { $indoor_horizon = 20; }

      # minimal indoor_horizon makes values like  civil_sunset and civil_sunrise
            if ( $indoor_horizon < -6 ) { $indoor_horizon = -6; }
        }
        else {
            return "indoor_horizon is not a valid number";
        }
    }

    $hash->{WEATHER_HORIZON} = 0;
    $hash->{INDOOR_HORIZON}  = $indoor_horizon;
    $hash->{LATITUDE}        = $latitude;
    $hash->{LONGITUDE}       = $longitude;
    $hash->{WEATHER}         = $weather;
    $hash->{VERSUCHE}        = 0;
    $hash->{DEFINE}          = 1;
    $hash->{CONDITION}       = undef;
    $hash->{SUNPOS_OFFSET}   = 5 * 60;

    $attr{$name}{verbose} = 4 if ( $name =~ /^tst.*$/ );

    my $mHash = { HASH => $hash };
    Twilight_sunpos($mHash);
    Twilight_Midnight($mHash);

    delete $hash->{DEFINE};

    return undef;
}
########################################################################r########
sub Twilight_Undef($$) {
    my ( $hash, $arg ) = @_;

    foreach my $key ( keys %{ $hash->{TW} } ) {
        myRemoveInternalTimer( $key, $hash );
    }
    myRemoveInternalTimer( "Midnight", $hash );
    myRemoveInternalTimer( "weather",  $hash );
    myRemoveInternalTimer( "sunpos",   $hash );

    return undef;
}
################################################################################
sub myInternalTimer($$$$$) {
    my ( $modifier, $tim, $callback, $hash, $waitIfInitNotDone ) = @_;

    my $timerName = "$hash->{NAME}_$modifier";
    my $mHash     = {
        HASH     => $hash,
        NAME     => "$hash->{NAME}_$modifier",
        MODIFIER => $modifier
    };
    if ( defined( $hash->{TIMER}{$timerName} ) ) {
        Log3 $hash, 1,
"[$hash->{NAME}] possible overwriting of timer $timerName - please delete first";
        stacktrace();
    }
    else {
        $hash->{TIMER}{$timerName} = $mHash;
    }

    Log3 $hash, 5,
      "[$hash->{NAME}] setting Timer: $timerName " . FmtDateTime($tim);
    InternalTimer( $tim, $callback, $mHash, $waitIfInitNotDone );
    return $mHash;
}
################################################################################
sub myRemoveInternalTimer($$) {
    my ( $modifier, $hash ) = @_;

    my $timerName = "$hash->{NAME}_$modifier";
    my $myHash    = $hash->{TIMER}{$timerName};
    if ( defined($myHash) ) {
        delete $hash->{TIMER}{$timerName};
        Log3 $hash, 5, "[$hash->{NAME}] removing Timer: $timerName";
        RemoveInternalTimer($myHash);
    }
}
################################################################################
sub myRemoveInternalTimerByName($) {
    my ($name) = @_;
    foreach my $a ( keys %intAt ) {
        my $nam = "";
        my $arg = $intAt{$a}{ARG};
        if ( ref($arg) eq "HASH" && defined( $arg->{NAME} ) ) {
            $nam = $arg->{NAME}
              if ( ref($arg) eq "HASH" && defined( $arg->{NAME} ) );
        }
        delete( $intAt{$a} ) if ( $nam =~ m/^$name/g );
    }
}
################################################################################
sub myGetHashIndirekt ($$) {
    my ( $myHash, $function ) = @_;

    Debug("myGetHashIndirekt");
    Debug( Dumper($myHash) );

    if ( !defined( $myHash->{HASH} ) ) {
        Log 3, "[$function] myHash not valid";
        return undef;
    }
    return $myHash->{HASH};
}
################################################################################
sub Twilight_midnight_seconds($) {
    my ($now) = @_;
    my @time = localtime($now);
    my $secs = ( $time[2] * 3600 ) + ( $time[1] * 60 ) + $time[0];
    return $secs;
}
################################################################################
#sub Twilight_ssTimeAsEpoch($) {
#   my ($zeit) = @_;
#   my ($hour, $min, $sec) = split(":",$zeit);
#
#   my $days=0;
#   if ($hour>=24) {$days = 1; $hour -=24};
#
#   my @jetzt_arr = localtime(time());
#   #Stunden               Minuten               Sekunden
#   $jetzt_arr[2]  = $hour; $jetzt_arr[1] = $min; $jetzt_arr[0] = $sec;
#   $jetzt_arr[3] += $days;
#   my $next = timelocal_nocheck(@jetzt_arr);
#
#   return $next;
#}
################################################################################
sub Twilight_calc($$) {
    my ( $deg, $idx ) = @_;

    my $midnight = time() - Twilight_midnight_seconds( time() );

    my $sr = sunrise_abs("HORIZON=$deg");
    my $ss = sunset_abs("HORIZON=$deg");

    my ( $srhour, $srmin, $srsec ) = split( ":", $sr );
    $srhour -= 24 if ( $srhour >= 24 );
    my ( $sshour, $ssmin, $sssec ) = split( ":", $ss );
    $sshour -= 24 if ( $sshour >= 24 );

    my $sr1 = $midnight + 3600 * $srhour + 60 * $srmin + $srsec;
    my $ss1 = $midnight + 3600 * $sshour + 60 * $ssmin + $sssec;

    return ( 0, 0 ) if ( abs( $sr1 - $ss1 ) < 30 );

    #return Twilight_ssTimeAsEpoch($sr) + 0.01*$idx,
    #       Twilight_ssTimeAsEpoch($ss) - 0.01*$idx;
    return ( $sr1 + 0.01 * $idx ), ( $ss1 - 0.01 * $idx );
}
################################################################################
sub Twilight_TwilightTimes(@) {
    our ( $hash, $whitchTimes ) = @_;

    my $Name = $hash->{NAME};
    $hash->{NAME} = $hash->{HASH}->{NAME};
    Debug("\$Name ====> $Name");

    my $horizon = $hash->{HORIZON};

    # global lat / lon can be set here
    my $lat = $attr{global}{latitude};
    $attr{global}{latitude} = $hash->{LATITUDE};

    my $long = $attr{global}{longitude};
    $attr{global}{longitude} = $hash->{LONGITUDE};

# ------------------------------------------------------------------------------
    my $idx      = -1;
    my @horizons = (
        "_astro:-18", "_naut:-12", "_civil:-6", ":0",
        "_indoor:$hash->{INDOOR_HORIZON}",
        "_weather:$hash->{WEATHER_HORIZON}"
    );

    Debug("pre horizons");
    Debug( Dumper(@horizons) );
    Debug( Dumper($hash) );

    foreach my $horizon (@horizons) {
        $idx++;
        next if ( $whitchTimes eq "weather" && !( $horizon =~ m/weather/ ) );

        my ( $name, $deg ) = split( ":", $horizon );
        my $sr = "sr$name";
        my $ss = "ss$name";
        $hash->{TW}{$sr}{NAME}  = $sr;
        $hash->{TW}{$ss}{NAME}  = $ss;
        $hash->{TW}{$sr}{DEG}   = $deg;
        $hash->{TW}{$ss}{DEG}   = $deg;
        $hash->{TW}{$sr}{LIGHT} = $idx + 1;
        $hash->{TW}{$ss}{LIGHT} = $idx;
        $hash->{TW}{$sr}{STATE} = $idx + 1;
        $hash->{TW}{$ss}{STATE} = 12 - $idx;

        ( $hash->{TW}{$sr}{TIME}, $hash->{TW}{$ss}{TIME} ) =
          Twilight_calc( $deg, $idx );

        if ( $hash->{TW}{$sr}{TIME} == 0 ) {
            Log3 $hash, 4,
"[$Name] hint: $hash->{TW}{$sr}{NAME},  $hash->{TW}{$ss}{NAME} are not defined(HORIZON=$deg)";
        }
    }

    Debug("post horizons");
    Debug( Dumper($hash) );

    $attr{global}{latitude}  = $lat;
    $attr{global}{longitude} = $long;

# ------------------------------------------------------------------------------
    readingsBeginUpdate($hash);

    foreach my $ereignis ( keys %{ $hash->{TW} } ) {

        Debug("readingsUpdate");
        Debug( Dumper($ereignis) );
        Debug( Dumper( $hash->{TW}{$ereignis}{TIME} ) );

        if ( $whitchTimes eq "weather" && !( $ereignis =~ m/weather/ ) ) {
            Debug("whitchTimes: $whitchTimes");
            Debug("ereignis: $ereignis");
            next;
        }

        readingsBulkUpdate( $hash, $ereignis,
            $hash->{TW}{$ereignis}{TIME} == 0
            ? "undefined"
            : FmtTime( $hash->{TW}{$ereignis}{TIME} ) );
    }

    unless ( $hash->{CONDITION} ) {
        readingsBulkUpdate( $hash, "condition",     $hash->{CONDITION} );
        readingsBulkUpdate( $hash, "condition_txt", $hash->{CONDITION_TXT} );
    }

    readingsEndUpdate( $hash, defined( $hash->{LOCAL} ? 0 : 1 ) );

# ------------------------------------------------------------------------------
    my @horizonsOhneDeg =
      map { my ( $e, $deg ) = split( ":", $_ ); "$e" } @horizons;
    my @ereignisse = (
        ( map { "sr$_" } @horizonsOhneDeg ),
        ( map { "ss$_" } reverse @horizonsOhneDeg ),
        "sr$horizonsOhneDeg[0]"
    );
    map { $hash->{TW}{ $ereignisse[$_] }{NAMENEXT} = $ereignisse[ $_ + 1 ] }
      0 .. $#ereignisse - 1;

# ------------------------------------------------------------------------------
    my $myHash;
    my $now              = time();
    my $secSinceMidnight = Twilight_midnight_seconds($now);
    my $lastMitternacht  = $now - $secSinceMidnight;
    my $nextMitternacht =
      ( $secSinceMidnight > 12 * 3600 )
      ? $lastMitternacht + 24 * 3600
      : $lastMitternacht;
    my $jetztIstMitternacht = abs( $now + 5 - $nextMitternacht ) <= 10;

    my @keyListe = qw "DEG LIGHT STATE SWIP TIME NAMENEXT";
    foreach my $ereignis ( sort keys %{ $hash->{TW} } ) {
        next if ( $whitchTimes eq "weather" && !( $ereignis =~ m/weather/ ) );

        myRemoveInternalTimer( $ereignis, $hash );  # if(!$jetztIstMitternacht);
        if ( $hash->{TW}{$ereignis}{TIME} > 0 ) {
            $myHash = myInternalTimer( $ereignis, $hash->{TW}{$ereignis}{TIME},
                "Twilight_fireEvent", $hash, 0 );
            map { $myHash->{$_} = $hash->{TW}{$ereignis}{$_} } @keyListe;
        }
    }

# ------------------------------------------------------------------------------
    return 1;
}
################################################################################
sub Twilight_fireEvent($) {
    my ($myHash) = @_;

    my $hash = myGetHashIndirekt( $myHash, ( caller(0) )[3] );
    return if ( !defined($hash) );

    my $name = $hash->{NAME};

    my $event = $myHash->{MODIFIER};
    my $deg   = $myHash->{DEG};
    my $light = $myHash->{LIGHT};
    my $state = $myHash->{STATE};
    my $swip  = $myHash->{SWIP};

    my $eventTime = $myHash->{TIME};
    my $nextEvent = $myHash->{NAMENEXT};

    my $delta    = int( $eventTime - time() );
    my $oldState = ReadingsVal( $name, "state", "0" );

    my $nextEventTime =
      ( $hash->{TW}{$nextEvent}{TIME} > 0 )
      ? FmtTime( $hash->{TW}{$nextEvent}{TIME} )
      : "undefined";

    my $doTrigger = !( defined( $hash->{LOCAL} ) )
      && ( abs($delta) < 6 || $swip && $state gt $oldState );

#Log3 $hash, 3, "[$hash->{NAME}] swip-delta-oldState-doTrigger===>$swip/$delta/$oldState/$doTrigger";

    Log3 $hash, 4,
      sprintf( "[$hash->{NAME}] %-10s %-19s  ",
        $event, FmtDateTime($eventTime) )
      . sprintf( "(%2d/$light/%+5.1f°/$doTrigger)   ", $state, $deg )
      . sprintf( "===> %-10s %-19s  ", $nextEvent, $nextEventTime );

    readingsBeginUpdate($hash);
    readingsBulkUpdate( $hash, "state",         $state );
    readingsBulkUpdate( $hash, "light",         $light );
    readingsBulkUpdate( $hash, "horizon",       $deg );
    readingsBulkUpdate( $hash, "aktEvent",      $event );
    readingsBulkUpdate( $hash, "nextEvent",     $nextEvent );
    readingsBulkUpdate( $hash, "nextEventTime", $nextEventTime );

    readingsEndUpdate( $hash, $doTrigger );

}
################################################################################
sub Twilight_Midnight($) {
    my ($myHash) = @_;
    my $hash = myGetHashIndirekt( $myHash, ( caller(0) )[3] );
    return if ( !defined($hash) );

    Twilight_WeatherCallback( $myHash, "Mid" );
}
################################################################################
# {Twilight_WeatherTimerUpdate( {HASH=$defs{"Twilight"}} ) }
sub Twilight_WeatherTimerUpdate($) {
    my ($myHash) = @_;
    my $hash = myGetHashIndirekt( $myHash, ( caller(0) )[3] );
    return if ( !defined($hash) );

    $hash->{SWIP} = 1;
    Twilight_WeatherCallback( $myHash, "weather" );

    # my $param = Twilight_CreateHttpParameterAndGetData($myHash, "weather");
}
################################################################################
# sub Twilight_CreateHttpParameterAndGetData($$) {
#   my ($myHash, $mode) = @_;
#   my $hash = myGetHashIndirekt($myHash, (caller(0))[3]);
#   return if (!defined($hash));
#
#   my $location = $hash->{WEATHER};
#   my $verbose  = AttrVal($hash->{NAME}, "verbose", 3 );
#
#   my $URL = "http://query.yahooapis.com/v1/public/yql?q=select%%20*%%20from%%20weather.forecast%%20where%%20woeid=%s%%20and%%20u=%%27c%%27&format=%s&env=store%%3A%%2F%%2Fdatatables.org%%2Falltableswithkeys";
#   my $url = sprintf($URL, $location, "json");
#   Log3 $hash, 4, "[$hash->{NAME}] url=$url";
#
#   my $param = {
#       url        => $url,
#       timeout    => defined($hash->{DEFINE}) ? 10 :10,
#       hash       => $hash,
#       method     => "GET",
#       loglevel   => 4-($verbose-3),
#       header     => "User-Agent: Mozilla/5.0\r\nAccept: application/xml",
#       callback   => \&Twilight_WeatherCallback,
#       mode       => $mode };
#
#   if (defined($hash->{DEFINE})) {
#     delete $param->{callback};
#     my ($err, $result) = HttpUtils_BlockingGet($param);
#     Twilight_WeatherCallback($param, $err, $result);
#   } else {
#     HttpUtils_NonblockingGet($param);
#   }
#
# }
################################################################################

#mod
sub Twilight_WeatherCallback(@) {
    my ( $hash, $timerMode ) = @_;
    return if ( !defined($hash) );

    Debug( Dumper($hash) );

    Twilight_getWeatherHorizon($hash);
    Twilight_RepeatTimerSet( $hash, $timerMode );
    Twilight_TwilightTimes( $hash, $timerMode );
    Twilight_StandardTimerSet($hash);
}
################################################################################
sub Twilight_RepeatTimerSet($$) {
    my ( $hash, $mode ) = @_;
    my $midnight = time() + 60;

    myRemoveInternalTimer( "Midnight", $hash );
    if ( $mode eq "Mid" ) {
        myInternalTimer( "Midnight", $midnight, "Twilight_Midnight", $hash, 0 );
    }
    else {
        myInternalTimer( "Midnight", $midnight, "Twilight_WeatherTimerUpdate",
            $hash, 0 );
    }

}
################################################################################
sub Twilight_StandardTimerSet($) {
    my ($hash) = @_;
    my $midnight = time() - Twilight_midnight_seconds( time() ) + 24 * 3600 + 1;

    myRemoveInternalTimer( "Midnight", $hash );
    myInternalTimer( "Midnight", $midnight, "Twilight_Midnight", $hash, 0 );
    Twilight_WeatherTimerSet($hash);
}
################################################################################
sub Twilight_WeatherTimerSet($) {
    my ($hash) = @_;
    my $now = time();

    myRemoveInternalTimer( "weather", $hash );
    foreach my $key ( "sr_weather", "ss_weather" ) {
        my $tim = $hash->{TW}{$key}{TIME};
        if ( $tim - 60 * 60 > $now + 60 ) {
            myInternalTimer( "weather", $tim - 60 * 60,
                "Twilight_WeatherTimerUpdate", $hash, 0 );
            last;
        }
    }
}
################################################################################
sub Twilight_sunposTimerSet($) {
    my ($hash) = @_;

    myRemoveInternalTimer( "sunpos", $hash );
    myInternalTimer( "sunpos", time() + $hash->{SUNPOS_OFFSET},
        "Twilight_sunpos", $hash, 0 );

}
################################################################################
sub Twilight_getWeatherHorizon(@) {
    my ($hash) = @_;

    my $cond_code   = "none";
    my $cond_txt    = "none";
    my $temperature = "none";

    $hash->{WEATHER_HORIZON}    = 0;
    $hash->{CONDITION}          = 0;
    $hash->{WEATHER_CORRECTION} = 0;
    $hash->{WEATHER_HORIZON}    = 0;
    $hash->{WEATHER_CORRECTION} + $hash->{INDOOR_HORIZON};
    $hash->{CONDITION_TXT} = $cond_txt;
    $hash->{TEMPERATUR}    = $temperature;

    my $doy         = strftime( "%j", localtime );
    my $declination = 0.4095 * sin( 0.016906 * ( $doy - 80.086 ) );

    if ( $hash->{WEATHER_HORIZON} > ( 89 - $hash->{LATITUDE} + $declination ) )
    {
        $hash->{WEATHER_HORIZON} = 89 - $hash->{LATITUDE} + $declination;
    }

    return 1;
}
################################################################################
sub Twilight_sunpos($) {
    my ($myHash) = @_;
    my $hash = myGetHashIndirekt( $myHash, ( caller(0) )[3] );
    return if ( !defined($hash) );

    my $hashName = $hash->{NAME};

    return "" if ( AttrVal( $hashName, "disable", undef ) );

    my $tn = TimeNow();
    my (
        $dSeconds, $dMinutes, $dHours, $iDay, $iMonth,
        $iYear,    $wday,     $yday,   $isdst
    ) = gmtime(time);
    $iMonth++;
    $iYear += 100;

    my $dLongitude = $hash->{LONGITUDE};
    my $dLatitude  = $hash->{LATITUDE};
    Log3 $hash, 5,
      "Compute sunpos for latitude $dLatitude , longitude $dLongitude"
      if ( $dHours == 0 && $dMinutes <= 6 );

    my $pi                = pi;
    my $twopi             = pi2;
    my $rad               = ( $pi / 180 );
    my $dEarthMeanRadius  = 6371.01;         # In km
    my $dAstronomicalUnit = 149597890;       # In km

    # Calculate difference in days between the current Julian Day
    # and JD 2451545.0, which is noon 1 January 2000 Universal Time

    # Calculate time of the day in UT decimal hours
    my $dDecimalHours = $dHours + $dMinutes / 60.0 + $dSeconds / 3600.0;

    # Calculate current Julian Day
    my $iYfrom2000 = $iYear;                        #expects now as YY ;
    my $iA         = ( 14 - ($iMonth) ) / 12;
    my $iM         = ($iMonth) + 12 * $iA - 3;
    my $liAux3     = ( 153 * $iM + 2 ) / 5;
    my $liAux4     = 365 * ( $iYfrom2000 - $iA );
    my $liAux5     = ( $iYfrom2000 - $iA ) / 4;
    my $dElapsedJulianDays =
      ( $iDay + $liAux3 + $liAux4 + $liAux5 + 59 ) + -0.5 +
      $dDecimalHours / 24.0;

    # Calculate ecliptic coordinates (ecliptic longitude and obliquity of the
    # ecliptic in radians but without limiting the angle to be less than 2*Pi
    # (i.e., the result may be greater than 2*Pi)

    my $dOmega = 2.1429 - 0.0010394594 * $dElapsedJulianDays;
    my $dMeanLongitude =
      4.8950630 + 0.017202791698 * $dElapsedJulianDays;    # Radians
    my $dMeanAnomaly = 6.2400600 + 0.0172019699 * $dElapsedJulianDays;
    my $dEclipticLongitude =
      $dMeanLongitude +
      0.03341607 * sin($dMeanAnomaly) +
      0.00034894 * sin( 2 * $dMeanAnomaly ) - 0.0001134 -
      0.0000203 * sin($dOmega);
    my $dEclipticObliquity =
      0.4090928 - 6.2140e-9 * $dElapsedJulianDays + 0.0000396 * cos($dOmega);

# Calculate celestial coordinates ( right ascension and declination ) in radians
# but without limiting the angle to be less than 2*Pi (i.e., the result may be
# greater than 2*Pi)

    my $dSin_EclipticLongitude = sin($dEclipticLongitude);
    my $dY1             = cos($dEclipticObliquity) * $dSin_EclipticLongitude;
    my $dX1             = cos($dEclipticLongitude);
    my $dRightAscension = atan2( $dY1, $dX1 );
    if ( $dRightAscension < 0.0 ) {
        $dRightAscension = $dRightAscension + $twopi;
    }
    my $dDeclination =
      asin( sin($dEclipticObliquity) * $dSin_EclipticLongitude );

    # Calculate local coordinates ( azimuth and zenith angle ) in degrees
    my $dGreenwichMeanSiderealTime =
      6.6974243242 + 0.0657098283 * $dElapsedJulianDays + $dDecimalHours;

    my $dLocalMeanSiderealTime =
      ( $dGreenwichMeanSiderealTime * 15 + $dLongitude ) * $rad;
    my $dHourAngle         = $dLocalMeanSiderealTime - $dRightAscension;
    my $dLatitudeInRadians = $dLatitude * $rad;
    my $dCos_Latitude      = cos($dLatitudeInRadians);
    my $dSin_Latitude      = sin($dLatitudeInRadians);
    my $dCos_HourAngle     = cos($dHourAngle);
    my $dZenithAngle       = (
        acos(
            $dCos_Latitude * $dCos_HourAngle * cos($dDeclination) +
              sin($dDeclination) * $dSin_Latitude
        )
    );
    my $dY = -sin($dHourAngle);
    my $dX =
      tan($dDeclination) * $dCos_Latitude - $dSin_Latitude * $dCos_HourAngle;
    my $dAzimuth = atan2( $dY, $dX );
    if ( $dAzimuth < 0.0 ) { $dAzimuth = $dAzimuth + $twopi }
    $dAzimuth = $dAzimuth / $rad;

    # Parallax Correction
    my $dParallax =
      ( $dEarthMeanRadius / $dAstronomicalUnit ) * sin($dZenithAngle);
    $dZenithAngle = ( $dZenithAngle + $dParallax ) / $rad;
    my $dElevation = 90 - $dZenithAngle;

    my $twilight = int( ( $dElevation + 12.0 ) / 18.0 * 1000 ) / 10;
    $twilight = 100 if ( $twilight > 100 );
    $twilight = 0   if ( $twilight < 0 );

    my $twilight_weather;

    if ( ( my $ExtWeather = AttrVal( $hashName, "useExtWeather", "" ) ) eq "" )
    {
        $twilight_weather = $twilight;
        Log3 $hash, 5, "[$hash->{NAME}] "
          . "Used the unmodified twilight for weather, because useExtWeather is not set.";
    }
    else {
        my ( $extDev, $extReading ) = split( ":", $ExtWeather );
        my $extWeatherHorizont = ReadingsVal( $extDev, $extReading, -1 );
        if ( $extWeatherHorizont >= 0 ) {
            $extWeatherHorizont = 100 if ( $extWeatherHorizont > 100 );
            Log3 $hash, 5,
                "[$hash->{NAME}] "
              . "Used external weather readings from: "
              . $extDev . ":"
              . $extReading
              . ", got "
              . $extWeatherHorizont;
            $twilight_weather = $twilight -
              int( 0.007 * ( $extWeatherHorizont**2 ) )
              ;    ## SCM: 100% clouds => 30% light (rough estimation)
        }
        else {
            $twilight_weather = $twilight;
            Log3 $hash, 3,
                "[$hash->{NAME}] "
              . "Error reading external value from: "
              . $extDev . ":"
              . $extReading
              . ", using unmodified twilight.";
        }
    }

    $twilight_weather = 100 if ( $twilight_weather > 100 );
    $twilight_weather = 0   if ( $twilight_weather < 0 );

    #  set readings
    $dAzimuth   = int( 100 * $dAzimuth ) / 100;
    $dElevation = int( 100 * $dElevation ) / 100;

    my $compassPoint = Twilight_CompassPoint($dAzimuth);

    readingsBeginUpdate($hash);
    readingsBulkUpdate( $hash, "azimuth",          $dAzimuth );
    readingsBulkUpdate( $hash, "elevation",        $dElevation );
    readingsBulkUpdate( $hash, "twilight",         $twilight );
    readingsBulkUpdate( $hash, "twilight_weather", $twilight_weather );
    readingsBulkUpdate( $hash, "compasspoint",     $compassPoint );
    readingsEndUpdate( $hash, defined( $hash->{LOCAL} ? 0 : 1 ) );

    Twilight_sunposTimerSet($hash);

    return undef;
}
################################################################################
sub Twilight_CompassPoint($) {
    my ($azimuth) = @_;

    my $compassPoint = "unknown";

    if ( $azimuth < 22.5 ) {
        $compassPoint = "north";
    }
    elsif ( $azimuth < 45 ) {
        $compassPoint = "north-northeast";
    }
    elsif ( $azimuth < 67.5 ) {
        $compassPoint = "northeast";
    }
    elsif ( $azimuth < 90 ) {
        $compassPoint = "east-northeast";
    }
    elsif ( $azimuth < 112.5 ) {
        $compassPoint = "east";
    }
    elsif ( $azimuth < 135 ) {
        $compassPoint = "east-southeast";
    }
    elsif ( $azimuth < 157.5 ) {
        $compassPoint = "southeast";
    }
    elsif ( $azimuth < 180 ) {
        $compassPoint = "south-southeast";
    }
    elsif ( $azimuth < 202.5 ) {
        $compassPoint = "south";
    }
    elsif ( $azimuth < 225 ) {
        $compassPoint = "south-southwest";
    }
    elsif ( $azimuth < 247.5 ) {
        $compassPoint = "southwest";
    }
    elsif ( $azimuth < 270 ) {
        $compassPoint = "west-southwest";
    }
    elsif ( $azimuth < 292.5 ) {
        $compassPoint = "west";
    }
    elsif ( $azimuth < 315 ) {
        $compassPoint = "west-northwest";
    }
    elsif ( $azimuth < 337.5 ) {
        $compassPoint = "northwest";
    }
    elsif ( $azimuth <= 361 ) {
        $compassPoint = "north-northwest";
    }
    return $compassPoint;
}

sub twilight($$$$) {
    my ( $twilight, $reading, $min, $max ) = @_;

    my $t = hms2h( ReadingsVal( $twilight, $reading, 0 ) );

    $t = hms2h($min) if ( defined($min) && ( hms2h($min) > $t ) );
    $t = hms2h($max) if ( defined($max) && ( hms2h($max) < $t ) );

    return h2hms_fmt($t);
}

1;

=cut
