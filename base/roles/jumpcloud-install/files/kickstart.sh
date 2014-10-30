#!/bin/bash

LOGFILE="/opt/jc/jcagentInstall.log"
PATH='/sbin:/bin:/usr/sbin:/usr/bin'

agentInstallDir='/opt/jc'
clientKeyName='client.key'
clientCrtName='client.crt'
caCrtName='ca.crt'
connectKeyHeaderName='x-connect-key'
connectKey='24d7f301eaa33b0dc8d40720ac5811fa75ccdb83'

connectKeyHeader="$connectKeyHeaderName: $connectKey"
clientKey="$agentInstallDir/$clientKeyName"
clientCrt="$agentInstallDir/$clientCrtName"
caCrt="$agentInstallDir/$caCrtName"
installScript="$agentInstallDir/agentInstall.sh"

failWithMessage() {
	echo "$1" >&2
	echo "$1" >> $LOGFILE
	echo "It appears your agent installation has failed. Please contact support@jumpcloud.com." >&2
	echo "It appears your agent installation has failed. Please contact support@jumpcloud.com." >> $LOGFILE
	exit 1
}

printMessageIfNotZero() {
  if [ "$1" != '0' ]; then
    echo "$2" >&2
	  echo "$2" >> $LOGFILE
  fi
}
failIfNotZero() {
	if [ "$1" != '0' ]; then
		failWithMessage "$2"
	fi
}

failIfDoesNotExist() {
	if [ ! -e "$1" ]; then
		failWithMessage "$2"
	fi
}

setTimeIfIncorrect() {
  local ERRMSG="$2"
  if [ "$1" != '0' ]; then
    checkFor 'ntpdate'
    local CMDRES="$?"
    if [ "$CMDRES" != '0' ]; then
      failWithMessage "$ERRMSG"
    else
      echo 'Setting local system time using ntpdate and pool.ntp.org...' | tee -a $LOGFILE
      ntpdate -u pool.ntp.org
      localTime="$(date +%s)"
      curlAgentWithoutCerts --data "time=$localTime" "$timeUrl"
      local CURLRES="$?"
      printMessageIfNotZero "$CURLRES" "Problem setting time with ntpdate"
      failIfNotZero "$CURLRES" "$ERRMSG"
    fi
  fi
}
checkFor() {
	type "$1" >/dev/null 2>&1
}

failIfCommandNotFound() {
	checkFor "$1"
	failIfNotZero "$?" "Necessary command not found: '$1'"
}

curlAgentWithoutCerts() {
	curl --silent --show-error --fail --header "$connectKeyHeader" "$@"
}

curlAgent() {
	curlAgentWithoutCerts --cert "$clientCrt" --key "$clientKey" --cacert "$caCrt" "$@"
}

progress(){
  while true
  do
    echo -n "."
    sleep 1
  done
}

function killsub()
{
    kill -9 ${1} 2>/dev/null
    wait ${1} 2>/dev/null
}

failIfCommandNotFound id
if [ "$(id -u)" != '0' ]; then
	failWithMessage 'Script must be run as root (or with sudo)'
fi

failIfCommandNotFound curl

failIfCommandNotFound mkdir
failIfCommandNotFound chmod
mkdir -p "$agentInstallDir"
chmod 700 "$agentInstallDir"

publicUrlBase='https://kickstart.jumpcloud.com'
privateUrlBase='https://kickstart.jumpcloud.com:444'

detectUrl="$publicUrlBase/Detect"
timeUrl="$publicUrlBase/Time"
signUrl="$publicUrlBase/SignCsr"
checkUrl="$privateUrlBase/CheckAccess"
installUrl="$privateUrlBase/GetAgentInstall"

templateFile="$agentInstallDir/templateId"
clientCsr="$agentInstallDir/client.csr"

if grep -q Debian /etc/issue; then # force curl uuid-runtime install for debian
  apt-get install curl uuid-runtime -y
fi

echo 'Checking for necessary install commands...'
echo 'Checking for necessary install commands...' >> $LOGFILE # repeated because we haven't confirmed tee is installed
notFoundCommands=''
for command in bash cat date grep head openssl rm uname uuidgen tee; do
	checkFor "$command"
	if [ "$?" != '0' ]; then
		notFoundCommands="$notFoundCommands $command"
	fi
done
if [ -n "$notFoundCommands" ]; then
	failWithMessage "Missing necessary install commands: $notFoundCommands"
else
	echo 'Necessary install commands found' | tee -a $LOGFILE
fi

echo 'Checking system compatibility...' | tee -a $LOGFILE
arch="$(uname -m)"
os="$(head -n 1 /etc/issue)"
curlAgentWithoutCerts --data "arch=$arch&os=$os" --output "$templateFile" "$detectUrl"
if [ "$?" != '0' ] || [ ! -f "$templateFile" ]; then
    failWithMessage "Your OS/architecture [$os/$arch] is not supported. Please visit http://support.jumpcloud.com/knowledgebase/articles/257990-getting-started for a list of supported systems."
fi
echo 'System is supported' | tee -a $LOGFILE
templateId="$(cat "$templateFile")"
rm -f "$templateFile"

echo 'Checking local system time...' | tee -a $LOGFILE
localTime="$(date +%s)"
curlAgentWithoutCerts --data "time=$localTime" "$timeUrl"
setTimeIfIncorrect "$?" "Your system time seems inaccurate. Please ensure your system is set to the correct time by running ntpdate ('ntpdate -u pool.ntp.org') or verifying that ntpd is configured properly."
localTime="$(date +%s)"
echo 'System time is accurate' | tee -a $LOGFILE

echo 'Generating private key...' | tee -a $LOGFILE
openssl genrsa -out "$clientKey" 2048
failIfNotZero "$?" 'Problem generating private key'
failIfDoesNotExist "$clientKey" 'Problem generating private key'
echo 'Successfully generated private key' | tee -a $LOGFILE
chmod 600 "$clientKey"

echo 'Generating certificate signing request...' | tee -a $LOGFILE
certuuid="$(uuidgen)"
openssl req -new -subj "/CN=$certuuid/O=JumpCloud" -key "$clientKey" -out "$clientCsr" -nodes -batch -sha1
failIfNotZero "$?" 'Problem generating certificate signing request'
failIfDoesNotExist "$clientCsr" 'Problem generating certificate signing request'
echo 'Successfully generated certificate signing request' | tee -a $LOGFILE

echo 'Fetching signed certificate...' | tee -a $LOGFILE
curlAgentWithoutCerts --form "csr=@$clientCsr" --form "certuuid=$certuuid" --output "$clientCrt" "$signUrl"
failIfNotZero "$?" 'Problem fetching signed certificate'
failIfDoesNotExist "$clientCrt" 'Problem fetching signed certificate'
echo 'Successfully fetched signed certificate' | tee -a $LOGFILE
chmod 600 "$clientCrt"
rm -f "$clientCsr"

cat >"$caCrt" <<END_OF_CA
-----BEGIN CERTIFICATE-----
MIIEpTCCAo2gAwIBAgIJAMfV46dMgC/IMA0GCSqGSIb3DQEBBQUAMD0xJDAiBgNV
BAMMG1Byb2RSb290Q0Euc2FmZWluc3RhbmNlLmNvbTEVMBMGA1UECgwMU2FmZUlu
c3RhbmNlMB4XDTEyMTEzMDE3MzEyN1oXDTE3MTEyOTE3MzEyN1owRTEsMCoGA1UE
AwwjUHJvZFNlcnZlcklzc3VlckNBLnNhZmVpbnN0YW5jZS5jb20xFTATBgNVBAoM
DFNhZmVJbnN0YW5jZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMQI
+cbjs/oEwdLNzF280rRbmLWyubF8bc9iZBE4Np2iuhcCPAR0TUehsGafaaPdJ8q7
zuZ8ZYDf1H7WLiXeGDHjZhWK2h8uQfNltFTwUCOKJCdayGMQF8ns8YqKZfqPBRd7
KKS5hHDEdptvcC5WrepoLxyDyU0qyviKuiAT28+PNQpnIV8RGsyFzQWWrGeRSUKI
0iz6LqvHpPcTg7PrmcIPRvDWuVhjqsJGiX6oUdSOZvMyXzYV3pofzLtUcVUvDHLr
Vt+Ez5Kh73sk9oi+vv+kBP+4zItlCc0JSXEo+jGG7h4v1jSNNDxeEtNOQ7TYoaJz
aq5Ni7POvq+t/OtpnnECAwEAAaOBnzCBnDAMBgNVHRMEBTADAQH/MB0GA1UdDgQW
BBRqTYKPb2II4GXLmFGKy36PZvaRcjBtBgNVHSMEZjBkgBRGr28P6uqQ5AsThMqh
wgok5w89MKFBpD8wPTEkMCIGA1UEAwwbUHJvZFJvb3RDQS5zYWZlaW5zdGFuY2Uu
Y29tMRUwEwYDVQQKDAxTYWZlSW5zdGFuY2WCCQDi3GG5EBn20DANBgkqhkiG9w0B
AQUFAAOCAgEAD7Q9/Dp5hzqRW258DfGuFWlX9LY+vcD5oKxjqMX1Di4YmhIn9baU
pN1Ocs9kp988Ez8nZIHID4QHnk99Uy/mmqGpeI4ht/wEuLbUHMhYlpKhg7UellRJ
gGflioehkt6IrghHVDIt2DUb96dCwrkED6MAozQ8dNc/wLaNP47FptS+wV1C00nf
Q9qZ/kHu9f7tjQBWVfIrDOdFdw1e7R4nE4pCwpOI/MUzEj2rMvLd9b3pXFDxxtfs
Or4inEDnY2+XISRUFRPOim1BHdSa7sZwCcascmH3ZDaMqdU2fTJ5UrHGIH3X+/4+
e9V6hPTUZDEvMShAuPWn8mmJDMcQuBcN0sx69H+rFZVdYekoIW3z0crOemMLHGgp
FNHE4a+lqwzXW/4+6FNjkeGbyrvMqD5A/wSGB4G+tCHZikyuRGZhQ3sVGjFlE6sq
Jji55KlPwQlp76OQf/6jnIgAbNUI5osaVUDrvEu9I3F7FCgNwoNHmXYr047CEi4t
1QvggncMLVSWQM25LswThLPpd/Cp9k5Mh19RIOZoBIb2lpyKFkuUw/UjLkzJEJSH
hoUi9iTxg7YYKYo3hxj6EoIyAHUuZEAnHqg8OoTAQI8y4Udt67+9GvLfqUzC3evR
89cBFQBF7yfqbLfD6rUBdZwLWBJsXu8pMdfZe+zic9ztcnx4vBX8fKs=
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIFnTCCA4WgAwIBAgIJAOLcYbkQGfbQMA0GCSqGSIb3DQEBBQUAMD0xJDAiBgNV
BAMMG1Byb2RSb290Q0Euc2FmZWluc3RhbmNlLmNvbTEVMBMGA1UECgwMU2FmZUlu
c3RhbmNlMB4XDTEyMTEzMDE3MzAwOVoXDTIyMTEyODE3MzAwOVowPTEkMCIGA1UE
AwwbUHJvZFJvb3RDQS5zYWZlaW5zdGFuY2UuY29tMRUwEwYDVQQKDAxTYWZlSW5z
dGFuY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC99EZwH/pmOzd4
2WTpQ1K4WAJcLS1fyBhov54JrXGtWVj1V8/tTe2ZTgnecvJLxwmJ4aZ5mYeixkci
cSrohsl0nR5Y6hNBXiL+JVEmg5b5NoMvg5mLLI2CeWhzp434wUY+YV9yXrkxA8N6
RCJOqJFQuLPCGrFenNz8ynlZ5Op8o/jhDln2Sv/+bjc0dGRH5Dn0jQD97rOvdO8L
Kt1fHqK+WTqdC64j8eSgSaTJKVtGjRh8P3xQ6MCG0HJMrc9YftbaeDujczTgNL3p
AiR1aZLMV8mQhcB9YLr07uhJMsKMsp2s5DSTvyQnUWOEjikRZFEYBtsc46gzYpo8
8HSIFq78OIxEi9gKBTaz3b+GCB+fxES+44Ax66lzdV6X8xEl8z1uCDygXq0/9VHC
3aSb7bqLPlASD5tr2qvfQuc3LZDsyCf1IkXJLl+luraeXJhkoR08UqmruS79qz9S
GmM/hl6z5q7WEW0bRqbRQ6kZozAhBaFM/0jkUnxNyL8eKiZSfmvQoYY0LILmEW85
8KNNvuxl8ptPm3jnPafBGPfjh3uFqq7ZTmMj0O8O0m7wYoZTpCFIhoDAHJvYaLFg
A8Vulv9v5Vy0KsY+Qh4OVL599nUyvS7ZJdtJIYiqED4IBVfnECDfU90drZZjv16W
T48RBvpcvGWQRRqRnWSxtabThcmg/wIDAQABo4GfMIGcMAwGA1UdEwQFMAMBAf8w
HQYDVR0OBBYEFEavbw/q6pDkCxOEyqHCCiTnDz0wMG0GA1UdIwRmMGSAFEavbw/q
6pDkCxOEyqHCCiTnDz0woUGkPzA9MSQwIgYDVQQDDBtQcm9kUm9vdENBLnNhZmVp
bnN0YW5jZS5jb20xFTATBgNVBAoMDFNhZmVJbnN0YW5jZYIJAOLcYbkQGfbQMA0G
CSqGSIb3DQEBBQUAA4ICAQCWONaWzTOoIlw5zNtWGZCDWOrix5/KXrbnek8Y5u39
kLf3Wp1drWIDePxOQBF5Nyvm+aucnkvHmlNX74545zgYKweCDYSnAhID0qpjqxaz
8GYSxJ2d6bxqbnFo3gw8VZDqQ4+ruqPlraFEtuePAS8S7lSXfzr0r6Ob74p1Rp59
h0w3+cdW97XSFBzxLcT9jNmpICzFnB2GqRmR8a1Nl5ejgSz0RxEeHE1oi9KoOCAW
7E4vO7+9zJ6Z3DHHGyEG6CdUQlyPBLjaHUCzdjpGrRd16XzxNHu8I9M3KS3gDAXr
wiSaZGmqhXTI7XJRMtpVPhzc0XOpm7GvWVm4sbL1/lBSrmb7Eqs0Fj1J2A3F+pK7
FuKNWXSS6kDmV191d5NG5zcRugQeGQhKZ4v8y0L5L6OoXlneMAE1O/tz8W2x++rV
MBDbPcCA0OzzMN/b9ySdc7J2Mn2rHR5HQ+yN7fqDFAXpJxuK3mRb83iszimk+K44
ub45ruuFbcYfgLjPpamLneGNvZM1r1DcuJBcHi94DoetRL6txpMtmvgN2UoHcXlv
LJcoqIUKhsV94UQZ0Bb5C4HGdq0B/qKv5rCCW/t5PJqcvgNV+XsMGGb/2A2xAjV6
kC3iATf2LLcvHi/gnQ5sDtxaQOhMU0kmFJpsfQ/0fDN53eQhxN/RSH015ojOeSHY
vg==
-----END CERTIFICATE-----

END_OF_CA
chmod 600 "$caCrt"

echo 'Verifying certificate access...' | tee -a $LOGFILE
curlAgent "$checkUrl"
failIfNotZero "$?" 'Problem verifying certificate access'
echo 'Successfully verified certificate access' | tee -a $LOGFILE

echo 'Fetching second stage installer...' | tee -a $LOGFILE
curlAgent --data "templateId=$templateId&certuuid=$certuuid" --output "$installScript" "$installUrl"
failIfNotZero "$?" 'Problem fetching second stage installer'
failIfDoesNotExist "$installScript" 'Problem fetching second stage installer'
echo 'Successfully fetched second stage installer' | tee -a $LOGFILE

echo 'Executing second stage installer...' | tee -a $LOGFILE
bash "$installScript"
