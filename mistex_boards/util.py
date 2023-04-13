import os
import sys
from os.path import join
from datetime import date
from colorama import Fore, Style

def add_designfiles(platform, coredir, mistex_yaml, boardspecific):
    use_template_sys = mistex_yaml.get('use-template-sys', False)

    boardspecific_sources = mistex_yaml[boardspecific]['sourcefiles']
    excludes = mistex_yaml['quartus']['sourcefiles'] + mistex_yaml['vivado']['sourcefiles']

    for sourcedir in mistex_yaml['sourcedirs']:
        print(f"\n{Style.DIM}******** source directory {sourcedir} ********{Style.RESET_ALL}")
        add_sources(platform, coredir, sourcedir, excludes, use_template_sys)

    print(f"\n{Style.DIM}******** source files ********{Style.RESET_ALL}")
    for source in mistex_yaml.get('sourcefiles', []):
        sourcepath = join(coredir, source)
        add_source(platform, sourcepath, coredir, use_template_sys)

    print(f"\n{Style.DIM}******** board specific sources ********{Style.RESET_ALL}")
    for source in boardspecific_sources:
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

def add_sources(platform, coredir, subdir, excludes, use_template_sys):
    sourcedir=join(coredir, subdir)
    for fname in os.listdir(sourcedir):
        fpath = join(sourcedir, fname)
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
        print(f"Usage: {sys.argv[0]} <core-name>")
        print("Available cores:")
        for core in os.listdir("cores"):
            print(f"   * {core}")
        sys.exit(1)

    main(core=sys.argv[1])

def get_build_dir(core):
    return os.path.join("build", sys.argv[0].split('.')[0].split('/')[1], core)
