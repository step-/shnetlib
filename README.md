# shnetlib

Linux shell library to retrieve basic network interface information.

## News

**10-Aug-2017 Release 1.0.0**
 * First release.

## Scope

Shnetlib aims at retrieving network interface information that can be used to
configure wired and wireless network interfaces from Linux shell scripts
without bashisms. Shnetlib doesn't depend on external network commands. Its
design focus is speed and a consistent API. It doesn't try to be comprehensive
in the information it can retrieve but it is reasonably complete for most basic
configuration tasks. A shell programmer should be able to extend its source
code easily as needed.

### Examples

The project includes script file `demo.sh`.

Other projects that use `shnetlib`:

* [fatdog-wireless-radio](https://github.com/step-/scripts-to-go/) is a simple
  wireless radio antenna manager script.

## Requirements and Installing

* The `/sys` file system branch is required. All interface properties are
  extracted from special files under `/sys`.
* A bourne-like shell.  Shnetlib has been tested with ash, bash and dash.
* Detailed information mode (optional) needs the `readlink` command.

Install by copying `usr/sbin/shnetlib.sh` to `/usr/sbin/shnetlib.sh`.

## Using shnetlib in Your Script

* Source the library `. /usr/sbin/shnetlib.sh`.
* If you need detailed information mode set variable `SHNETLIB_MODE=detailed`.
* Call `enum_interfaces` to fetch interface lists into library global
   variables `IFACE_*`.
* Call `get_iface_wired`, `get_iface_wireless`, `get_iface_other`, and
   `get_iface_by_bus` to fetch interface specific information.

API definition is provided as comment lines in file `usr/sbin/shnetlib.sh`.
File `demo.sh` exercises the entire API.

## Change Log

See [release announcements](https://github.com/step-/shnetlib/releases)
and - for fine-grained information -
[commit history](https://github.com/step-/shnetlib/commits/master).

## Old News

* --

