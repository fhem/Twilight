##############################################################################
#
#   59_Twilight.pm
#
#   Copyright by
#
#       Dietmar Ortmann, dietmar63
#       Sebastian Stuecker
#       Michael Prange, igami
#       Christoph Morrison, jeschkec <fhem@christoph-jeschke.de>
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
#   ---------------------------------------------------------------------------
#
#   In memoriam Dietmar Ortmann, dietmar63
#       * 19.07.1963  ✝ 11.07.2017
#
##############################################################################

# include 95_Astro
require '95_Astro.pm';

package FHEM::Twilight {

    #
    #   ------------------------------------------------------------ Pragmas
    #

    use strict;
    use v5.10;
    use warnings FATAL => 'all';
    use feature qw(switch);
    use POSIX;
    use Data::Dumper;
    use English;
    no if $] >= 5.017011, warnings => 'experimental';

    #
    #   ------------------------------------------------------------ Helper functions
    #

    sub Debugging(@) {
        $OFS = ", ";
        ::Debug("@_") if ::AttrVal("global", "verbose", undef) eq "5";
    }

    #
    #   ------------------------------------------------------------ Main functions
    #

    sub Define($$) {
        my ($hash, $device_definition) = @_;
        my @definition_arguments = split("[ \t][ \t]*", $device_definition);
        my $definition_length = int(@definition_arguments);

        return
            "syntax: define <name> Twilight [Latitude|global] [Longitude|global] [Indoor Horizon] [deprecated: Yahoo Weather ID]"
            unless ($definition_length ~~ [ 1 .. 6 ]);

        my ($name, $module, $latitude, $longitude, $indoor_horizon, $yahoo_weather) = @definition_arguments[0 .. 5];

        Debugging("Latitude before check: " . Dumper($latitude));

        # check if latitude is set in global when no latitude is given or the keyword "global" is set
        if (!$latitude or ($latitude eq "global")) {
            $latitude = ::AttrVal("global", "latitude", undef);
        }

        Debugging("Lat after global check: " . Dumper($latitude));

        return "[$name] Latitude is not globally set nor set for $name, you have to set one." unless $latitude;

        unless ($latitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $latitude !~ /^[\. ]*$/) {
            return "[$name] Latitude '$latitude' seems not to be valid!";
        }

        Debugging("Longitude before check: " . Dumper($longitude));

        # check if longitude is set in global when no longitude is given or the keyword "global" is set
        if (!$longitude or ($longitude eq "global")) {
            $longitude = ::AttrVal("global", "longitude", undef);
        }

        Debugging("Longitude after global check: " . Dumper($longitude));

        return "[$name] Longitude is not globally set nor set for $name, you have to set one." unless $longitude;

        unless ($longitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $longitude !~ /^[\. ]*$/) {
            return "[$name] Longitude '$longitude' seems not to be valid!";
        }

        if ($indoor_horizon) {
            Debugging("Indoor horzion is set: " . Dumper($indoor_horizon));
            Debugging("indoor horizon between -6 and 20") if $indoor_horizon ~~ [ -6 .. 20 ];
            Debugging("indoor horizon not between -6 and 20") unless $indoor_horizon ~~ [ -6 .. 20 ];

            return "[$name] Indoor horizon '$indoor_horizon' is not a valid, must be between -6 and 20"
                unless ($indoor_horizon ~~ [ -6 .. 20 ]);

            $indoor_horizon = abs int $indoor_horizon;
        }
        else {
            $indoor_horizon = 0;
        }

        ::Log3($name, 3,
            "Setting a Yahoo Weather ID is deprecated and has no further effect. "
                . "Please consider modifying $name.") if $yahoo_weather;

        Debugging($device_definition);
        Debugging(Dumper(@definition_arguments));
        Debugging(Dumper($hash));
        Debugging(Dumper($name));
        Debugging(Dumper($latitude));
        Debugging(Dumper($longitude));
        Debugging(Dumper($indoor_horizon));

        $hash->{STATE}              = 0;
        $hash->{LONGITUDE}          = $longitude;
        $hash->{LATITUDE}           = $latitude;
        $hash->{INDOOR_HORIZON}     = $indoor_horizon;
        $hash->{WEATHER_HORIZON}    = undef;
        $hash->{WEATHER}            = undef;
        $hash->{FORECAST}           = undef;

        Debugging("Global data is: " . Dumper(\$hash));

        return undef;
    }

    sub Undefine() {

    }

    sub Set() {

    }

    sub Get() {

    }

    sub Attr() {
        my ($command, $device_name, $attribute_name, $attribute_value) = @_;
        my $hash = $::defs{$name};

        given ($attribute_name) {
            when ('useExtWeather') {
                if ($command eq "set") {
                    ::Log3($device_name, 3, "useExtWeather is deprecated, use Twilight_Weather instead.");
                    Attr($command, $device_name, 'Twilight_Weather', $attribute_value);
                }
                if ($command eq "del") {
                    ::Log3($device_name, 3, "useExtWeather is deprecated, use Twilight_Weather instead.");
                    Attr($command, $device_name, 'Twilight_Weather');
                }
            }
            when ('Twilight_Weather') {
                if ($command eq "set") {
                    my ($device, $reading) = split('/:/', $attribute_value);

                    return "${attribute_value} is no valid value for ${attribute_name}."
                        unless ($device or $reading);

                    return "${device} does not exist, but given for Twilight_Weather"
                        unless defined $::defs{$device};

                    return "${reading} does not exist for device ${device}, but given for Twilight_Weather"
                        unless defined $::defs{$device}{READINGS}{$reading};

                    $hash->{'Twilight_Weather'} = $attribute_value;

                    # @todo Update the calculations for the current weather
                }
                if ($command eq "del") {
                    delete $hash->{'WEATHER'};

                    # @todo Update the calculations for the current weather
                }
            }
            when ('Twilight_Forecast') {
                if ($command eq "set") {
                    my ($device, $reading) = split('/:/', $attribute_value);

                    return "${attribute_value} is no valid value for ${attribute_name}."
                        unless ($device or $reading);

                    return "${device} does not exist, but given for Twilight_Forecast"
                        unless defined $::defs{$device};

                    return "${reading} does not exist for device ${device}, but given for Twilight_Forecast"
                        unless defined $::defs{$device}{READINGS}{$reading};

                    $hash->{'FORECAST'} = $attribute_value;

                    # @todo Update the calculations for the forecast
                }
                if ($command eq "del") {
                    delete $hash->{'.Twilight_Forecast'};

                    # @todo Update the calculations for the forecast
                }
            }
            default {
                return "Tried to delete unknown attribute $attribute_name." if ($command eq "del");
                return "Tried to set unknown attribute $attribute_name." if ($command eq "set");
            }
        }
    }

    sub Notify() {

    }

}

package main {

    use strict;
    use warnings;

    sub Twilight_Initialize($)
    {
        my ($hash) = @_;

        $hash->{DefFn}      =   "FHEM::Twilight::Define";
        $hash->{UndefFn}    =   "FHEM::Twilight::Undefine";
        $hash->{SetFn}      =   "FHEM::Twilight::Set";
        $hash->{GetFn}      =   "FHEM::Twilight::Get";
        $hash->{AttrFn}     =   "FHEM::Twilight::Attr";
        $hash->{NotifyFn}   =   "FHEM::Twilight::Notify";
        $hash->{AttrList}   =   join(' ',
            (
                'useExtWeather',        # backward compatibility → Twilight_Weather
                'Twilight_Weather',
                'Twilight_Forecast',
            )
        ) . " $readingFnAttributes";
    }

    sub twilight()
    {

    }

}

1;

=pod
=item device
=item summary       Weather dependend twilight information
=item summary_DE    Liefert wetterabhängige Informationen über die Lichtverhältnisse

=begin html

<h1 id="twilight">Twilight</h1>

=end html

=begin html_DE

<h1 id="twilight">Twilight</h1>

=end html_DE

=for :application/json;q=META.json 59_Twilight.pm
{
    "abstract": "FHEM module for weather depended brightness and twilight",
    "x_lang": {
        "de": {
            "abstract": "FHEM-Modul für wetterabhängige Lichtverhältnisse"
        }
    },
    "keywords": [
        "Twilight",
        "Helligkeit",
        "Sonnenaufgang",
        "Sonnenuntergang",
        "Sunrise",
        "Sunset",
        "D&auml;mmerung"
    ],
    "release_status": "stable",
    "license": "GPL_2",
    "version": "2.0.0",
    "author": [
        "Christoph Morrison <post@christoph-jeschke.de>"
    ],
    "resources": {
        "homepage": "https://github.com/fhem/Twilight/",
        "x_homepage_title": "Module homepage",
        "license": [
            "https://github.com/fhem/Twilight/blob/master/LICENSE"
        ],
        "bugtracker": {
            "web": "https://github.com/fhem/Twilight/issues"
        },
        "repository": {
            "type": "git",
            "url": "https://github.com/fhem/Twilight.git",
            "web": "https://github.com/fhem/Twilight.git",
            "x_branch": "master",
            "x_development": {
                "type": "git",
                "url": "https://github.com/fhem/Twilight.git",
                "web": "https://github.com/fhem/Twilight/tree/development",
                "x_branch": "development"
            },
            "x_filepath": "",
            "x_raw": ""
        },
        "x_wiki": {
            "title": "Twilight",
            "web": "https://wiki.fhem.de/wiki/Twilight"
        }
    },
    "x_fhem_maintainer": [
        "jeschkec"
    ],
    "x_fhem_maintainer_github": [
        "christoph-morrison"
    ],
    "prereqs": {
        "runtime": {
            "requires": {
                "FHEM": 5.00918799,
                "perl": 5.10,
                "Meta": 0
            },
            "recommends": {
            
            },
            "suggests": {
            
            }
        }
    }
}
=end :application/json;q=META.json
