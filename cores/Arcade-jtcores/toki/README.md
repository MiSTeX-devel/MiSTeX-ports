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
  
* Build jtframe core first 

  ```sh
  cd cores/Arcade-jtcores/jtcores/
  source setprj.sh
  jtcore kicker -mistex --nodbg
  ```

* Build MiSTeX core

  ```sh
  python3 mistex_boards/qmtech_ep4cgx150_mistex.py cores/Arcade-jtcores/kicker/
  ```

  