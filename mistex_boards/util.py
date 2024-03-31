import os
import sys
from os.path import join
from datetime import date
from colorama import Fore, Style
from icecream import ic
from shutil import copy

def add_designfiles(platform, coredir, mistex_yaml, toolchain, build_dir=None):
    use_template_sys = mistex_yaml.get('use-template-sys', False)

    def replace_coredir(s):
        coredir_abs = os.path.abspath(coredir)
        return s.replace('${CORE_DIR}', coredir_abs)

    platform_commands = mistex_yaml[toolchain].get('platform-commands', [])
    for command in platform_commands:
        platform.add_platform_command(replace_coredir(command))

    pre_synthesis_commands = mistex_yaml[toolchain].get('pre-synthesis-commands', [])
    for command in pre_synthesis_commands:
        platform.toolchain.pre_synthesis_commands.append(replace_coredir(command))

    toolchain_specific_sources = mistex_yaml[toolchain]['sourcefiles']
    excludes = mistex_yaml['quartus']['sourcefiles'] + mistex_yaml['vivado']['sourcefiles']

    for sourcedir in mistex_yaml['sourcedirs']:
        print(f"\n{Style.DIM}******** source directory {sourcedir} ********{Style.RESET_ALL}")
        the_coredir = "cores/Template" if use_template_sys and sourcedir == "sys" else coredir
        add_sources(toolchain, platform, the_coredir, build_dir, sourcedir, excludes, use_template_sys)

    print(f"\n{Style.DIM}******** source files ********{Style.RESET_ALL}")
    for source in mistex_yaml.get('sourcefiles', []):
        sourcepath = join(coredir, source)
        add_source(platform, sourcepath, coredir, use_template_sys)

    print(f"\n{Style.DIM}******** board specific sources ********{Style.RESET_ALL}")
    for source in toolchain_specific_sources:
        sourcepath = join(coredir, source)
        add_source(platform, sourcepath, coredir, use_template_sys)

def add_source(platform, fpath, coredir, use_template_sys):
    if use_template_sys and fpath.startswith(os.path.join(coredir, "sys")):
        fpath = fpath.replace(coredir, "cores/Template")

    print(f" -> {fpath}")
    if fpath.endswith(".sdc"):
        platform.add_platform_command(f"set_global_assignment -name SDC_FILE {fpath}")
    else:
        platform.add_source(fpath)

def convert_mif_file(build_dir, fname, fpath, coredir, toolchain):
    mif_dir = os.path.dirname(fpath).replace(coredir, "").replace("/upstream/", "")
    mif_dest_dir = os.path.join(build_dir, mif_dir)
    os.makedirs(mif_dest_dir, exist_ok=True)
    if toolchain == 'vivado':
        with open(fpath, 'r') as f:
            lines = [l for l in f.readlines() if not l.startswith("--")]
            outlines = []
            is_first_entry = False
            is_content = False
            radix = 16
            hexwidth = 2
            this_address = 0
            last_address = 0
            depth = 0
            for line in lines:
                if line.startswith("DATA_RADIX"):
                    data_radix = line.split("=")[-1].replace(';', '').strip()
                    assert data_radix == "HEX" or data_radix == "BIN"
                    if data_radix == "BIN":
                        radix = 2

                if line.startswith("CONTENT BEGIN"):
                    is_first_entry = True
                    is_content = True
                    continue

                if line.startswith("END"):
                    continue

                if line.startswith("WIDTH"):
                    width = int(line.split("=")[-1].replace(';', '').strip())
                    assert width % 4 == 0
                    hexwidth = width // 4
                    continue

                if line.startswith("DEPTH"):
                    depth = int(line.split("=")[-1].replace(';', '').strip())
                    continue

                if not is_content or line.strip() == '':
                    continue

                # handle content
                lineparts = [lp.replace(";", "").replace('\n', '').strip() for lp in line.split(" ") if lp.strip() != '' and lp.strip() != ':' ]
                address = lineparts[0].replace(":", "")

                fmt = f"{{:0{hexwidth}X}}"
                if address.startswith("["):
                    start_addr, end_addr = address[1:-1].split("..")
                    start_addr = int(start_addr, 16)
                    end_addr = int(end_addr, 16)
                    n_of_data = end_addr - start_addr + 1
                    assert (start_addr == last_address + 1) or is_first_entry
                    data = fmt.format(int(lineparts[1], radix))
                    for i in range(n_of_data):
                        outlines.append(data + '\n')
                    last_address = end_addr
                else:
                    this_address = int(address, 16)
                    for p in lineparts[1:]:
                        data = fmt.format(int(p, radix))
                        outlines.append(data + '\n')

                last_address = this_address

            assert len(outlines) == depth

            destpath = os.path.join(mif_dest_dir, fname)
            with open(destpath, 'w') as df:
                df.writelines(outlines)
            copy(destpath, destpath.replace(".mif", ".mem"))
    else:
        copy(fpath, mif_dest_dir)

def add_sources(toolchain, platform, coredir, build_dir, subdir, excludes, use_template_sys):
    sourcedir=join(coredir, subdir)
    for fname in os.listdir(sourcedir):
        fpath = join(sourcedir, fname)
        if build_dir != None and fname.endswith(".mif"):
            convert_mif_file(build_dir, fname, fpath, coredir, toolchain)

        excluded = any([fpath.endswith(e) for e in excludes])
        if not (fname.endswith(".sv") or
                fname.endswith(".v") or
                fname.endswith(".sdc") or
                fname.endswith(".vhd")) or excluded:
            if excluded: print(f"{Fore.RED}    {fpath} is excluded...{Style.RESET_ALL}")
            continue

        add_source(platform, fpath, coredir, use_template_sys)

def generate_build_id(platform, coredir, defines=[]):
    build_id = join(coredir, "build_id.vh")
    platform.add_source(build_id)
    print(f"\nGenerating {build_id}..")
    with open(build_id, "w") as f:
        today = date.today()
        f.write(f'`define BUILD_DATE "{today.year}{today.month:02}{today.day:02}"\n')
        for key, value in defines:
            f.write(f'`define {key} {value}\n')

    return build_id

def add_mainfile(platform, coredir, mistex_yaml):
    mainfile = mistex_yaml['mainfile']
    if mainfile == "detect":
        mainfile = [f for f in os.listdir(coredir) if f.endswith(".sv")][0]
    if mainfile is not None:
        mainpath = coredir + '/' + mainfile
        print(f"\nAdding main file {mainpath}\n")
        platform.add_source(mainpath)

def handle_main(main):
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <core-dir>")
        sys.exit(1)

    coredir=sys.argv[1]
    if coredir.endswith('/'):
        coredir = coredir[0:-1]
    core = coredir.split('/')[-1]
    main(coredir, core)

def get_build_dir(core):
    return os.path.join("build", sys.argv[0].split('.')[0].split('/')[1], core)

def get_build_name(core):
    return core.replace("-", "_") + "_MiSTeX"
