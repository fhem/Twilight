# FHEM::Twilight

## General description
``FHEM::Twilight`` extends [FHEM](https://fhem.de/) with astronomical informations enriched with meterological ones for twilight calculation.

## License
This software is published under the [GNU General Public License 2.0](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html).

## This version vs. the SVN version
If you install a vanilla FHEM, you will be provided with an older Twilight version. If you want to use this much more newer version, you need to exclude the old one from `update`. To do so, you need to set the `exclude_from_update` (also) to fhem.de's `FHEM/59_Twilight.pm`, i.e. by

        attr global exclude_from_update fhem.de.*:FHEM/59_Twilight.pm   

Then you have to add this repository to your FHEM installation and `update` it.

## Branching model
* `stable` contains the current version as delivered by `fhem update` from the [official FHEM Repository](https://svn.fhem.de/trac/browser/trunk/fhem/FHEM/59_Twilight.pm).
* ``oldstable`` contains the previous release version, just for stability issues. Issues for ``oldstable`` are not ``accepted``.
* ``testing`` contains the next release version, it's considered stable also, but might contains bugs or issues. Fixed set of features.
* ``development`` is not much surprising under development, can change at any time and is certainly **not** stable. Don't use it.

## Community support
* The [FHEM user forum](https://forum.fhem.de/) is for general support and discussion, mostly in german, but an [english section](https://forum.fhem.de/index.php/board,52.0.html) is also available. Please read the [Posting 101](https://forum.fhem.de/index.php/topic,71806.0.html) before your first posting their. 
* `FHEM::Twilight` specific discussions are on topic at the [Unterstützende Dienste / Wettermodule](https://forum.fhem.de/index.php/board,86.0.html) board.
* Additional information for usage can be found at the [FHEM Wiki](https://wiki.fhem.de/wiki/Twilight).

## Bug reports and feature requests
Bugs and feature requests are tracked using [Github Issues](https://github.com/fhem/Twilight/issues).

## Pull requests / How to participate into development
You are invited to send pull requests to the ``development`` branch whenever you think you can contribute with some useful improvements to the module. The module maintainer will review you code and decide whether it is going to be part of the module in a future release.

## Contributors
* [Christoph Morrison](https://github.com/christoph-morrison)
* [Michael Prange](https://github.com/Igami)
* Sebastian Stuecker
* Dietmar Ortmann, dietmar63, †

## In memoriam
In memoriam Dietmar Ortmann, dietmar63<br />
&nbsp;&nbsp;&nbsp;* 19.07.1963&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;† 11.07.2017

