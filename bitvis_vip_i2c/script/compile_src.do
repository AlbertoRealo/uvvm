#========================================================================================================================
# Copyright (c) 2017 by Bitvis AS.  All rights reserved.
# You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not, 
# contact Bitvis AS <support@bitvis.no>.
#
# UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR
# OTHER DEALINGS IN UVVM.
#========================================================================================================================

# This file may be called with an argument
# arg 1: Part directory of this library/module

# Overload quietly (Modelsim specific command) to let it work in Riviera-Pro
proc quietly { args } {
  if {[llength $args] == 0} {
    puts "quietly"
  } else {
    # this works since tcl prompt only prints the last command given. list prints "".
    uplevel $args; list;
  }
}

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
} else {
  onerror {abort all}
}
#Just in case...
quietly quit -sim   

# Detect simulator
if {[catch {eval "vsim -version"} message] == 0} { 
  quietly set simulator_version [eval "vsim -version"]
  # puts "Version is: $simulator_version"
  if {[regexp -nocase {modelsim} $simulator_version]} {
    quietly set simulator "modelsim"
  } elseif {[regexp -nocase {aldec} $simulator_version]} {
    quietly set simulator "rivierapro"
  } else {
    puts "Unknown simulator. Attempting use use Modelsim commands."
    quietly set simulator "modelsim"
  }  
} else { 
    puts "vsim -version failed with the following message:\n $message"
    abort all
}

if { [string equal -nocase $simulator "modelsim"] } {
  ###########
  # Fix possible vmap bug
  do fix_vmap.tcl 
  ##########
}

# Set up vip_i2c_part_path and lib_name
#------------------------------------------------------
quietly set lib_name "bitvis_vip_i2c"
quietly set part_name "bitvis_vip_i2c"
# path from mpf-file in sim
quietly set vip_i2c_part_path "../..//$part_name"

if { [info exists 1] } {
  # path from this part to target part
  quietly set vip_i2c_part_path "$1/..//$part_name"
  unset 1
}


# (Re-)Generate library and Compile source files
#--------------------------------------------------
echo "\n\nRe-gen lib and compile $lib_name source\n"


if {[file exists $vip_i2c_part_path/sim/$lib_name]} {
  file delete -force $vip_i2c_part_path/sim/$lib_name
}
if {![file exists $vip_i2c_part_path/sim]} {
  file mkdir $vip_i2c_part_path/sim
}

vlib $vip_i2c_part_path/sim/$lib_name
vmap $lib_name $vip_i2c_part_path/sim/$lib_name

if { [string equal -nocase $simulator "modelsim"] } {
  set compdirectives "-2008 -suppress 1346,1236,1090 -work $lib_name"
} elseif { [string equal -nocase $simulator "rivierapro"] } {
  set compdirectives "-2008 -nowarn COMP96_0564 -nowarn DAGGEN_0001 -dbg -work $lib_name"
}

eval vcom  $compdirectives  $vip_i2c_part_path/src/i2c_bfm_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/src/vvc_cmd_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/../uvvm_vvc_framework/src_target_dependent/td_target_support_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/../uvvm_vvc_framework/src_target_dependent/td_vvc_framework_common_methods_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/src/vvc_methods_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/../uvvm_vvc_framework/src_target_dependent/td_queue_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/../uvvm_vvc_framework/src_target_dependent/td_vvc_entity_support_pkg.vhd
eval vcom  $compdirectives  $vip_i2c_part_path/src/i2c_vvc.vhd

