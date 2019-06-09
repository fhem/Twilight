use strict;
use warnings;

package FHEM::Twilight;

sub Define()
{

}

sub Undefine()
{

}

sub Set()
{

}

sub Get()
{

}

sub Attr()
{

}

sub Notify()
{

}

package main;

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
            'useExtWeather',
            'Twilight_Weather',
            'Twilight_Forecast',
            'debug'
        )
    ) . " $readingFnAttributes";
}

sub twilight()
{

}

1;

=pod
=item device
=item summary       Weather dependend twilight information
=item summary_DE    Liefert wetterabhängige Informationen über die Lichtverhältnisse

=begin html

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
