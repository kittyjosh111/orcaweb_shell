#!/bin/bash
#orcaweb_url="https://orca.kittyjosh.com"
orca_ver=4.2.1
openmpi_ver=3.1.4
orca_path="/opt/orca-${orca_ver}"
openmpi_path="${orca_path}/openmpi-${openmpi_ver}"

if [[ ! -x "${orca_path}/orca" ]]; then
  echo "ORCA not found." >&2
  return 1
fi
if [[ ! -d "${openmpi_path}/lib" ]]; then
  echo "OpenMPI "${openmpi_ver}" not installed." >&2
  return 2
fi

if [[ ! ${PATH} =~ ${openmpi_path} ]]; then
  export PATH="${openmpi_path}/bin"${PATH:+":$PATH"}
fi
if [[ ! ${LD_LIBRARY_PATH} =~ ${orca_path} ]]; then
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"${LD_LIBRARY_PATH}:"}${orca_path}
fi
if [[ ! ${LD_LIBRARY_PATH} =~ "${openmpi_path}/lib" ]]; then
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+"${LD_LIBRARY_PATH}:"}"${openmpi_path}/lib"
fi
export PATH="${orca_path}"${PATH:+":$PATH"}

##############
cd /var/www/orcaweb_files
for d in */ ; do
    cd $d
    if [ -f "pending" ] && [ -f "request_email" ] && [ -f "inp_filename" ]; then
	nonce=$(echo $d | sed 's:/*$::')
	inp_filename=$(<inp_filename)
	email=$(<request_email)
	email_url=$(php -r "echo rawurlencode('$email');")
        echo "orca $inp_filename > $inp_filename.out"
	echo "Thank you for using orcaweb at $orcaweb_url, brought to you by Joshua Shi <joshua.shi@gmail.com>. A new orca job has been started for input file $inp_filename. You can check the status at $orcaweb_url/status.php?q=$nonce&e=$email_url" | mutt -s "orca started for $inp_filename" $email
	rm pending
        orca $inp_filename > $inp_filename.out
	retVal=$?
	if [ $retVal -ne 0 ]; then
	    echo "Error"
	    echo "Thank you for using orcaweb at $orcaweb_url, brought to you by Joshua Shi <joshua.shi@gmail.com>. A new orca job has failed for input file $inp_filename. You can check the out file at $orcaweb_url/status.php?q=$nonce&e=$email_url" | mutt -s "orca FAILED for $inp_filename" $email
            continue
        fi
	touch completed
	cd ..
	tar -czvf $inp_filename.$nonce.tar.gz $d
	echo "Thank you for using orcaweb at $orcaweb_url, brought to you by Joshua Shi <joshua.shi@gmail.com>. Please find the orca result attached." | mutt -s "orca result for $inp_filename" $email -a $inp_filename.$nonce.tar.gz
	cd $d
    fi
    cd ..
done
