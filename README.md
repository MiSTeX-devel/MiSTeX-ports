# MiSTeX
# How to set up the required python environment
```sh
$ python -m venv venv
$ source ./venv/bin/activate
$ pip install -r requirements.txt
```

# How to build a core
Make sure that the required ventor toolchain is in your PATH.
That would be a recent Vivado, if you intend to build for Xilinx targets,
or Quartus, if you want to build for Altera targets.
Usage example for the Menu core:

```sh
$ source ./venv/bin/activate
# python3 [path_to_board_definition.py] [core_name]
$ python3 mistex_boards/qmtech_xc7a100t_mistex.py cores/Menu
```
