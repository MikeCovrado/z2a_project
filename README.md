# z2a_project submission
Submission for Zero To Asic course offered by @mattvenn.
The "submission" is a single "wrapped" project in Matt Venn's "multi-project wrapper" instantiated as a user-project in Caravel.
This particular wrapped project is a `serial divider` which Caravel's core (picorv32) can access via a memory mapped Wishbone peripheral.

## Design Sources
The source code of this project submission, including both design and verification was originally done on the `mpw-one-b-mike` tag of https://github.com/MikeCovrado/caravel.
The "official" sources are now maintained on the `main` branch of https://github.com/MikeCovrado/z2a_project.git.

Synthesis and physical implementation is done in a working copy of https://github.com/efabless/openlane, release `rc6`.

## Project Status
In theory, the wrapper and project RTL plus associated GDS and LEF files are clean and ready to go.
However, none of this has been subjected to the [multi-project](https://github.com/mattvenn/multi_project_tools) integration tests.
Having said that, the following tests are passing on my [single-project](https://github.com/MikeCovrado/multi_project_tools/tree/z2a_project) version of multi_project_tools:
* ./multi_tool.py --config projects.yaml --force-delete --test-module
* ./multi_tool.py --config projects.yaml --force-delete --prove-wrapper
* ./multi_tool.py --config projects.yaml --force-delete --test-gds
* ./multi_tool.py --config projects.yaml --force-delete --test-interface
* ./multi_tool.py --config projects.yaml --force-delete --test-tristate

The following _was_ working and is now (temporarily) broken:
* ./multi_tool.py --config projects.yaml --force-delete --test-caravel

Watch this space for further updates.

## Credit-where-credit-is-due
- The structure of this repository is shameless copied from https://github.com/jamieiles/a5-1-wb-macro.
- None of this would be possible without @mattvenn.
