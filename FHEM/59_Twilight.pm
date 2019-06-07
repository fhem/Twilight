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