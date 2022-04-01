#!/bin/bash

error_message="Error 😵‍💫 ... Exiting."

printf "Welcome to the vCard QRCode generator 🤩\n\n"

## Check if qrencode is installed on the machine
if ! command -v qrencode &> /dev/null; then
    printf " ❌ You first need to install the package \"qrencode\" before you can proceed.\n"
    exit 1
fi

## Personal details:
printf "Please enter your personal details.\n ⚠️  If you don't want to enter a specific detail, just leave it blank.\n\n"

required_params=false
while ! ${required_params}; do
    read -p " => Firstname: " firstname
    read -p " => Lastname: " lastname

    if [[ -z ${firstname} || -z ${lastname} ]]; then
        printf "\n❌ At least you need a first- and a lastname 🤨 \n\n"
        required_params=false
    else
        required_params=true
    fi
done

## Generate a base filename and filename for the vcard
filename_base=$( echo ${firstname} | awk ' { print tolower($0) } ' )"-"$( echo ${lastname} | awk ' { print tolower($0) } ' )
vcard_file="./${filename_base}.vcard"
qrcode_file="${filename_base}-qrcode.png"

if [[ -f ${vcard_file} || -f ${qrcode_file} ]]; then
    printf "\n"
    read -p "❔ Are you sure, that you want to override the existing files? [y/n] " override
    case "${override}" in
        [yY]|[yY]es )   printf "\n Okay, the files will be overridden!\n\n" ;;
        [nN]|[nN]o  )   exit 1                                         ;;
        *           )   printf "${error_message}" && exit 1            ;;
    esac
fi 

read -p " => Additional names: " additional_names
read -p " => Title: " title
read -p " => Company: " company
read -p " => Role: " role
read -p " => Birthday [YYYY-MM-DD]: " birthday

## Write the base vcard with the personal details to the vcard_file
cat << EOF > ${vcard_file}
BEGIN:VCARD
VERSION:4.0
N:${lastname};${firstname};${additional_names};${title};
ORG:${company}
ROLE:${role}
BDAY:${birthday}
EOF

## addresses
address_count=0
read_address=true
while ${read_address}; do
    printf "\n"

    if [[ ${address_count} == 0 ]]; then
        read -p "❔ Do you want to enter an address? [y/n] " read_address
    else
        read -p "❔ Do you want to enter another address? [y/n] " read_address
    fi

    case "${read_address}" in
        [yY]|[yY]es )   read_address=true                       ;;
        [nN]|[nN]o  )   read_address=false                      ;;
        *           )   printf "${error_message}" && exit 1     ;;
    esac

    if ${read_address}; then
        (( address_count++ ))
        read -p " => Type of the address [e.g. home / work]: "   adr_type
        read -p " => Street and Housenumber: "                  adr_street
        read -p " => City: "                                    adr_city
        read -p " => Postal code: "                             adr_pc
        read -p " => Country: "                                 adr_country

        adr_label="${adr_type}=\"${adr_street}\n${adr_pc} ${adr_city}\n${adr_country}\""
        adr_string="ADR;TYPE=${adr_type};${adr_label}:;;${adr_street};${adr_city};;${adr_pc};${adr_country}"

        echo "${adr_string}" >> ${vcard_file} # Write address to the vcard file
    fi
done

## Phone numbers
phoneno_count=0
read_phoneno=true
while ${read_phoneno}; do
    printf "\n"

    if [[ ${phoneno_count} == 0 ]]; then
        read -p "❔ Do you want to enter an phone number? 📱 [y/n] " read_phoneno
    else
        read -p "❔ Do you want to enter another phone number? 📱 [y/n] " read_phoneno
    fi

    case "${read_phoneno}" in
        [yY]|[yY]es )   read_phoneno=true                     ;;
        [nN]|[nN]o  )   read_phoneno=false                    ;;
        *           )   printf "${error_message}" && exit 1   ;;
    esac

    if ${read_phoneno}; then
        (( phoneno_count++ ))
        read -p " => Type of the phone number  [e.g. home / work / mobile]: "   phone_type
        read -p " => Phone number: "                                            phone_number

        phone_string="TEL;TYPE="${phone_type}",voice;"${phone_type}"=uri:"${phone_number}""

        echo "${phone_string}" >> ${vcard_file} # Write phone number to the vcard file
    fi
done

## Email addresses
mail_count=0
read_mail=true
while ${read_mail}; do
    printf "\n"

    if [[ ${mail_count} == 0 ]]; then
        read -p "❔ Do you want to enter an mail address? [y/n] " read_mail
    else
        read -p "❔ Do you want to enter another mail address?  [y/n] " read_mail
    fi

    case "${read_mail}" in
        [yY]|[yY]es )   read_mail=true                        ;;
        [nN]|[nN]o  )   read_mail=false                       ;;
        *           )   printf "${error_message}" && exit 1   ;;
    esac

    if ${read_mail}; then
        (( mail_count++ ))
        read -p " => Type of the mail address  [e.g. home / work / mobile]: "   mail_type
        read -p " => Mail address: "                                            mail_address

        mail_string="EMAIL;type=${mail_type}:${mail_address}"

        echo "${mail_string}" >> ${vcard_file} # Write mail address to the vcard file
    fi
done

## Write the end of the vCard file
echo "END:VCARD" >> ${vcard_file}

qrencode -o ${qrcode_file} < "${vcard_file}"

printf "\n\n 🎉  Succesfully created your QRCode.\n\n"

qrencode -t ansiutf8 < "${vcard_file}"
