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
%%CommandRef.en%%
=end html

=begin html_DE
%%CommandRef.de%%
=end html_DE

=for :application/json;q=META.json 59_Twilight.pm
%%Meta%%
=end :application/json;q=META.json
