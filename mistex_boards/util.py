import os
from os.path import join
from datetime import date
from colorama import Fore, Style

def add_designfiles(platform, coredir, mistex_yaml, boardspecific):
    boardspecific_sources = mistex_yaml[boardspecific]['sourcefiles']
    excludes = mistex_yaml['quartus' if boardspecific == 'vivado' else 'vivado']['sourcefiles']

    for sourcedir in mistex_yaml['sourcedirs']:
        print(f"\n{Style.DIM}******** source directory {sourcedir} ********{Style.RESET_ALL}")
        add_sources(platform, coredir, sourcedir, excludes)

    print(f"\n{Style.DIM}******** source files ********{Style.RESET_ALL}")
    for source in mistex_yaml.get('sourcefiles', []):
        sourcepath = join(coredir, source)
        print(f" -> {sourcepath}")
        platform.add_source(sourcepath)

    print(f"\n{Style.DIM}******** board specific sources ********{Style.RESET_ALL}")
    for source in boardspecific_sources:
        sourcepath = join(coredir, source)
        print(f" -> {sourcepath}")
        platform.add_source(sourcepath)

def add_sources(platform, coredir, subdir, excludes):
    sourcedir=join(coredir, subdir)
    for fname in os.listdir(sourcedir):
        fpath = join(sourcedir, fname)
        excluded = any([fpath.endswith(e) for e in excludes])
        if not (fname.endswith(".sv") or
                fname.endswith(".v") or
                fname.endswith(".vhd")) or excluded:
            if excluded: print(f"{Fore.RED}    {fpath} is excluded...{Style.RESET_ALL}")
            continue

        print(f" -> {fpath}")
        platform.add_source(fpath)

def generate_build_id(platform, coredir, defines=[]):
    build_id = join(coredir, "build_id.v")
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
