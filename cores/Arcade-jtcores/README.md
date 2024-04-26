## jtcores port status

| **Core** | **Max10/Cyclone IV** | **Cyclone V** | **Xilinx7** |
| -------- | -------------------- | ------------- | ----------- |
| kicker   | works                | untested      | untested    |
| toki     | works                | untested      | untested    |
|          |                      |               |             |
|          |                      |               |             |



## Build instructions

* Prepare Jotego's jtframe environment as descrived in [compilation.md](../jtcores/modules/jtframe/doc/compilation.md)

  ```sh
  #just for the first time update jtcores submodules
  cd cores/Arcade-jtcores/jtcores/
  git -c submodule."modules/jt900h".update=none -c submodule."modules/jtframe/target/pocket".update=none submodule update --init --recursive
  ```
  
* Build MiSTeX core

  ```sh
  python3 mistex_boards/qmtech_ep4cgx150_mistex.py cores/Arcade-jtcores/corename/
  ```
  
  


## Development notes

* Generate mistex target folder with Jotego's scripts

  ```sh
  cd cores/Arcade-jtcores/jtcores/
  source setprj.sh
  jtcore corename -mistex
  ```

  MiSTeX target is defined at cores/Arcade-jtcores/jtcores/modules/jtframe/target/mistex

* Copy the generated mistex folder from cores/Arcade-jtcores/jtcores/cores/corename over to cores/Arcade-jtcores/corename/. Replace wrong symbolic links for the ones from kicker core

* Get MiSTeX.yaml template from kicker core and adapt it to your own core.

  * adapt mainfile
  * defines come from mistex/corename.qsf
  * sourcedirs and sourcefiles come from mistex/game.qip
  * adapt quartus/vivado specific platform-commands and sourcefiles