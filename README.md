# z2a_project submission
Submission for Zero To Asic course offered by @mattvenn.
The "submission" is a single "wrapped" project in Matt Venn's "multi-project wrapper" instantiated as a user-project in Caravel.
This particular wrapped project is a serial divider which Caravel's core (picorv32) can access via a memory mapped Wishbone peripheral.

## Design Sources
The source code of this project submission, including both design and verification is maintained on the `mpw-one-b-mike` tag of https://github.com/MikeCovrado/caravel.
Synthesis and physical implementation is done in a working copy of https://github.com/efabless/openlane, release `rc6`.

## Project Status
In theory, the wrapper and project RTL plus associated GDS and LEF files are clean and ready to go.  However, none of this has been subjected to the [multi-project](https://github.com/mattvenn/multi_project_tools) integration tests.  Watch this space for further updates.

## Credit-where-credit-is-due
- The structure of this repository is shameless copied from https://github.com/jamieiles/a5-1-wb-macro.
- None of this would be possible without @mattvenn.
