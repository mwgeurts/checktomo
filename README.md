## TomoTherapy Secondary Dose Calculation Tool

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2017, University of Wisconsin Board of Regents
<br>MATLAB dose calculation algorithm copyright &copy; 2011-15, Simon Thomas

CheckTomo opens a GUI that allows users to load a plan and re-calculate the plan dose for helical tomotherapy plans, then compare the second dose calculation to the TPS. This application is named after and is an adapted form of the CheckTomo software developed by Simon Thomas. It has been modified to use TomoTherapy patient archives to load files, as well as allow calculation using either the MATLAB dose calculation algorithm developed by Simon Thomas or using a research standalone dose calculator provided by Accuray Incorporated.

For more information on the MATLAB dose calculation algorithm, see Thomas  et al. *Independent dose calculation software for tomotherapy*, **Med Phys**  2015; 39: 160-167. The original tool, CheckTomo, can be obtained through the GPL license by contacting Simon Thomas (refer to the correspondence address in the journal article referenced above for contact information).

TomoTherapy is a registered trademark of Accuray Incorporated.

## Contents

* [Installation](README.md#installation)
* [Application Use](README.md#application-use)
* [Compatibility and Requirements](README.md#compatibility-and-requirements)
* [Troubleshooting](README.md#troubleshooting)
* [License](README.md#license) 

## Installation

To install this application as a MATLAB App, download and execute the `CheckTomo.mlappinstall` file from this directory. If downloading the repository via git, make sure to download all submodules by running  `git clone --recursive https://github.com/mwgeurts/checktomo`.

## Application Use

To run the application, execute this function `CheckTomo` with no inputs. Once the user interface loads, click Browse and select the patient archive to load. If multiple approved helical plans exist in the archive, a list menu will appear allowing you to select a plan. Once the plan loads, select the re-calculation method and resolution and click Calculate Dose. Finally, after the dose calculation is complete, enter  the desired Gamma Index criteria click Calculate Gamma to compare the two  dose distributions.

This application reads in a set of configuration options in the provided file config.txt. Refer to the documentation in the code for more information on how each configuration option is defined. The `REMOTE_*` and `MATLAB_POOL` options are commonly edited and are discussed below.

By default, this application will only enable the standalone dose calculator method options if the gpusadose and sadose applications are locally installed and part of the current path. To enable this tool to connect to another computer that has these executables installed, add the following configuration options to the config.txt file: `REMOTE_CALC_SERVER`, `REMOTE_CALC_USER`, and `REMOTE_CALC_PASS`, where the server is the IP address or DNS name of the computer, and the other two are a username and password for an account that has access to connect to the computer (via SSH) and execute the gpusadose and/or sadose applications.

## Compatibility and Requirements

When running MATLAB based dose calculations, this application will attempt to start a local parallel pool using the default profile. Users who do not have the Parallel Computing toolbox licensed should remove the `MATLAB_POOL` configuration option from config.txt. To change the number of workers accessed by this tool, change the value of `MATLAB_POOL` in config.txt.

For Gamma calculation, if the Parallel Computing Toolbox is enabled, `CalcGamma()` will attempt to compute the three-dimensional computation using a compatible CUDA device.  To test whether the local system has a GPU compatible device installed, run `gpuDevice(1)` in MATLAB.  All GPU calls in this application are executed in a try-catch statement, and automatically revert to an equivalent (albeit longer) CPU based computation if not available or if the available memory is insufficient.

For MATLAB, this application has been validated in version 9.1 and Parallel Computing Toolbox version 6.9 on macOS 10.12 (Sierra). As discussed above, the Parallel Computing Toolbox is only required if using the MATLAB dose calculation method with parallel computation or the Gamma metric plugin with GPU based computation.

## Troubleshooting

This application records key input parameters and results to a log.txt file using the `Event()` function. The log is the most important route to troubleshooting errors encountered by this software.  The author can also be contacted using the information above.  Refer to the license file for a full description of the limitations on liability when using or this software or its components.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
