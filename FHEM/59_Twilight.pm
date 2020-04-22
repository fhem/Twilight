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

package FHEM::Twilight;
    #
    #   ------------------------------------------------------------ Pragmas
    #

    use strict;
    use v5.18;
    use warnings FATAL => 'all';
        no warnings 'experimental::smartmatch';
    use feature qw(switch);
    use POSIX;
    use Data::Dumper;
    use English;
    use FHEM::Meta;

    #
    #   ------------------------------------------------------------ Includes
    #
    ::LoadModule("Astro");

    #
    #   ------------------------------------------------------------ Helper functions
    #

    sub Debugging {
        local $OFS = ", ";
        ::Debug("@_"); # if ::AttrVal("global", "verbose", undef) eq "5";
    }

    #
    #   ------------------------------------------------------------ Main functions
    #

    sub Define {

        my ($hash, $device_definition) = @_;
        my @definition_arguments = split("[ \t][ \t]*", $device_definition);
        my $definition_length = int(@definition_arguments);

        return
            "syntax: define <name> Twilight [Latitude|global] [Longitude|global] [Indoor Horizon] [deprecated: Yahoo Weather ID]"
            unless ($definition_length ~~ [ 1 .. 6 ]);

        my ($device_name, $module, $latitude, $longitude, $indoor_horizon, $yahoo_weather) = @definition_arguments[0 .. 5];

        $indoor_horizon = checkIndoorHorizon($indoor_horizon) if $indoor_horizon;
        $latitude       = checkLatitude($latitude) if $latitude;
        $longitude      = checkLongitude($longitude) if $longitude;

        ::Log3($device_name, 3,
            "Setting a Yahoo Weather ID is deprecated and has no further effect. "
                . "Please consider modifying $device_name.") if $yahoo_weather;

        # move from useExtWeather to Twilight_Weather
        if (::AttrVal($device_name, 'useExtWeather', undef)) {
            ::Log3($device_name, 3, "useExtWeather is deprecated, rewritten to Twilight_Weather.");
            Attr('set', $device_name, 'Twilight_Weather', ::AttrVal($device_name, 'useExtWeather', undef));
            Attr('del', $device_name, 'useExtWeather');
        }

        $hash->{LONGITUDE}          = $longitude;
        $hash->{LATITUDE}           = $latitude;

        # delete old internals, not longer used
        delete($hash->{INDOOR_HORIZON})     if defined($hash->{INDOOR_HORIZON});
        delete($hash->{WEATHER_HORIZON})    if defined($hash->{WEATHER_HORIZON});
        delete($hash->{WEATHER})            if defined($hash->{WEATHER});
        delete($hash->{FORECAST})           if defined($hash->{FORECAST});

        Debugging("Global data is: " . Dumper(\$hash));

        ::readingsSingleUpdate($hash, 'state', 'Initialized', 1);
        return undef;
    }

    sub Undefine {

    }

    sub Set {

    }

    sub Get {

    }

    sub Attr {

        my ($command, $device_name, $attribute_name, $attribute_value) = @_;
        my $hash = $::defs{$device_name};

        Debugging(
            "Attr called", "\n",
            Dumper (
                $command, $device_name, $attribute_name, $attribute_value
            )
        );

        given ($attribute_name) {
            when ('useExtWeather') {
                Debugging(
                    Dumper (
                        {
                            'attribute_value' => $attribute_value,
                            'attr' => 'useExtWeather',
                            "command" => $command,
                        }
                    )
                );

                # @todo useExtWeather is deprecated, instead Twilight_Weather should be used, but this does not work atm.

                ::Log3($device_name, 3, "useExtWeather is deprecated, use Twilight_Weather instead.");
                Attr($command, $device_name, 'Twilight_Weather', $attribute_value);
            }

            when ('Twilight_Weather') {
                if ($command eq "set") {
                    my ($device, $reading) = split /:/, $attribute_value;

                    Debugging(
                        Dumper (
                            {
                                'attribute_value' => $attribute_value,
                                'attr' => 'Twilight_Weather',
                                "command" => $command,
                                "device" => $device,
                                "reading" => $reading,
                            }
                        )
                    );

                    return "Device not given for Twilight_Weather"
                        unless defined($device);

                    return "Reading not given for Twilight_Weather"
                        unless defined($reading);

                    return "${device} does not exist, but given for Twilight_Weather"
                        unless ::IsDevice($device);

                    return "${reading} does not exist for device ${device}, but given for Twilight_Weather"
                        unless defined($::defs{$device}{READINGS}{$reading});

                    # @todo Update the calculations for the current weather
                    return undef;
                }

                if ($command eq "del") {
                    # @todo Update the calculations for the current weather
                    return undef;
                }
            }
            when ('Twilight_Forecast') {
                if ($command eq "set") {
                    my ($device, $reading) = split /:/, $attribute_value;

                    Debugging(
                        Dumper(
                            {
                                'attribute_value' => $attribute_value,
                                'attr'            => 'Twilight_Forecast',
                                "command"         => $command,
                                "device"          => $device,
                                "reading"         => $reading,
                            }
                        )
                    );

                    return "Device not given for Twilight_Forecast"
                        unless defined($device);

                    return "Reading not given for Twilight_Forecast"
                        unless defined($reading);

                    return "${device} does not exist, but given for Twilight_Forecast"
                        unless ::IsDevice($device);

                    return "${reading} does not exist for device ${device}, but given for Twilight_Forecast"
                        unless defined $::defs{$device}{READINGS}{$reading};

                    return undef;

                    # @todo Update the calculations for the forecast
                }

                if ($command eq "del") {
                    # @todo Update the calculations for the forecast
                    return undef;
                }
            }

            when('Twilight_Latitude') {
                # @todo Twilight_Latitude

                if ($command eq 'set') {
                    # @todo update calculations
                    my $latitude = checkLatitude($attribute_value);
                    return undef unless $latitude;
                }

                if ($command eq 'del') {
                    # @todo update calculations
                    return undef;
                }
            }

            when('Twilight_Longitude') {
                # @todo Twilight_Longitude

                if ($command eq 'set') {
                    # @todo update calculations
                    my $longitude = checkLongitude($attribute_value);
                    return undef unless $longitude;
                }

                if ($command eq 'del') {
                    # @todo update calculations
                    return undef;
                }
            }

            when('Twilight_Indoor_Horizon') {
                # @todo Twilight_Indoor_Horizon

                if ($command eq 'set') {
                    # @todo update calculations
                    my $indoor_horizon = checkLongitude($attribute_value);
                    return undef unless $indoor_horizon;
                }

                if ($command eq 'del') {
                    # @todo update calculations
                    return undef;
                }
            }

            default {
                return "Tried to delete unknown attribute $attribute_name." if ($command eq "del");
                return "Tried to set unknown attribute $attribute_name." if ($command eq "set");
            }
        }
    }

    sub Notify {

    }

    sub checkLatitude {
        my $latitude = shift;

        Debugging("Latitude before check: " . Dumper($latitude));

        # check if latitude is set in global when no latitude is given or the keyword "global" is set
        if (!$latitude or ($latitude eq "global")) {
            $latitude = ::AttrVal("global", "latitude", undef);
        }

        Debugging("Latitude after global check: " . Dumper($latitude));

        return "Latitude is not globally set nor set, you have to set one." unless $latitude;

        unless ($latitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $latitude !~ /^[\. ]*$/) {
            return "Latitude '$latitude' seems not to be valid!";
        }

        return $latitude;
    }

    sub checkLongitude {
        my $longitude = shift;

        Debugging("Longitude before check: " . Dumper($longitude));

        # check if longitude is set in global when no longitude is given or the keyword "global" is set
        if (!$longitude or ($longitude eq "global")) {
            $longitude = ::AttrVal("global", "longitude", undef);
        }

        Debugging("Longitude after global check: " . Dumper($longitude));

        return "Longitude is not globally set nor set, you have to set one." unless $longitude;

        unless ($longitude =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $longitude !~ /^[\. ]*$/) {
            return "Longitude '$longitude' seems not to be valid!";
        }

        return $longitude;
    }

    sub checkIndoorHorizon {
        my $indoor_horizon = shift;

        Debugging("Indoor horzion is set: " . Dumper($indoor_horizon));
        Debugging("indoor horizon between -6 and 20") if $indoor_horizon ~~ [ -6 .. 20 ];
        Debugging("indoor horizon not between -6 and 20") unless $indoor_horizon ~~ [ -6 .. 20 ];

        return "Indoor horizon '$indoor_horizon' is not a valid, must be between -6 and 20"
            unless ($indoor_horizon ~~ [ -6 .. 20 ]);

        $indoor_horizon = abs int $indoor_horizon;

        return $indoor_horizon;
    }

package main;

    use strict;
    use warnings;

    sub Twilight_Initialize
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
                'Twilight_Indoor_Horizon',
                'Twilight_Latitude',
                'Twilight_Longitude',
            )
        ) . " $readingFnAttributes";
    }

    sub twilight
    {

    }

1;

=pod
=item device
=item summary       Weather dependend twilight information
=item summary_DE    Liefert wetterabhängige Informationen über die Lichtverhältnisse

=begin html

<h1>Twilight</h1>

=end html

=begin html_DE

<h1>Twilight</h1>

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
