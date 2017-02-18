**Table of Contents**

- [3.0.0 (development branch)](#300-development-branch)
- [2.1.0 (2016-08-24)](#210-2016-08-24)
- [2.0.0 (2016-08-24)](#200-2016-08-24)
- [Previous version](#previous-version)

## 3.0.0 (development branch)

  - Added variable to be able to control push to Domoticz (DOMOTICZ_PUSH)
  - Added 3 phase configuration support (using single phase by default)
  - Added Reactive Power and Apparent Power values
  - Added possibility to select which values should be pushed to Domoticz
  - Added required tools check
  - Many code improvements
  
  - Bash lint fixes:
    -  Use $(..) instead of legacy `..`. [SC2006]
    -  Double quote to prevent globbing and word splitting. [SC2086]

  - TODO:
    - TEST it with three phase system
    - (After testing it) Add to three-phase system reactive/cosfi/apparent values

## 2.1.0 (2016-08-24)

Features:

  - Added script for controlling Smappee plugs from Domoticz via script
  - Added support for listing Smappee plugs available (to get the key)


## 2.0.0 (2016-08-24)

Features:

  - Refactoring of the bash script
  - Extracted important parameters as variables in a "user-friendly" zone
  - Created README.md with documentation, requirements
  - Created CHANGELOG.md with latest changes

## Previous version
https://www.domoticz.com/forum/viewtopic.php?f=31&t=7312&hilit=smappee&start=20
