## TomoTherapy Secondary Dose Calculation Tool

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2017, University of Wisconsin Board of Regents
<br>MATLAB dose calculation algorithm copyright &copy; 2011-15, Simon Thomas

## Description

CheckTomo is a MATLAB&reg; application that allows users to load a plan and re-calculate the plan dose for helical tomotherapy plans, then compare the second dose calculation to the TPS. This application is named after and is an adapted form of the CheckTomo software developed by Simon Thomas. It has been modified to use TomoTherapy patient archives to load files, as well as allow calculation using either the MATLAB dose calculation algorithm developed by Simon Thomas or using a research standalone dose calculator provided by Accuray Incorporated.

For more information on the MATLAB dose calculation algorithm, see [Thomas et al. Independent dose calculation software for tomotherapy, Med Phys 2015; 39: 160-167](http://onlinelibrary.wiley.com/doi/10.1118/1.3668061/full). The original tool, can be obtained through the GPL license by contacting Simon Thomas (refer to the correspondence address in the journal article referenced above for contact information).

TomoTherapy is a registered trademark of Accuray Incorporated. MATLAB is a registered trademark of MathWorks Inc.

## Installation

To install this application as a MATLAB App, download and execute the `CheckTomo.mlappinstall` file from this directory. If downloading the repository via git, make sure to download all submodules by running  `git clone --recursive https://github.com/mwgeurts/checktomo`.

## Usage and Documentation

To run the application, execute this function `CheckTomo` with no inputs. Once the user interface loads, click Browse and select the patient archive to load. If multiple approved helical plans exist in the archive, a list menu will appear allowing you to select a plan. Once the plan loads, select the re-calculation method and resolution and click Calculate Dose. Finally, after the dose calculation is complete, enter  the desired Gamma Index criteria click Calculate Gamma to compare the two  dose distributions. 

See the [wiki](../../wiki/) for information on configuration parameters, setting up a calculation server and beam models, and additional documentation.

## License

Released under the GNU GPL v3.0 License.  See the [LICENSE](LICENSE) file for further details.
