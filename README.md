A helper script to disassemble the geometry output of a gaussian calculation into a new to a new input, with preserved fragment information, for counterpoise calculations. 

Usage:
bash fragmenter.sh <logfile.log>

Which will prompt the user for assignment of fragment per atom indices

Optionally:
bash fragmenter.sh <logfile.log> [existing_input_file.gjf]

Which will extract fragment information from an existing input file, used in a case where a calculation is done before the counterpoise step itself, which leads to Gaussian ignoring fragment info in the checkpoint file. The assumption is that the input file has the same atoms as the log used and correctly assigned fragmets.msg