# portqry.sh

portqry.sh is a shell script that you can use to help troubleshoot TCP/IP connectivity issues. portqry.sh runs on Linux-based computers. The script can be used to check the port status of TCP ports on a number of target computers you specify.

## Installing

```bash
git clone https://github.com/stdtom/portqry.git
cd portqry/
git submodule update --init --recursive
```

## Usage

portqry.sh reads one or more TCP/IP target in the format `<ip address|hostname>[:port]` from stdin and tests the port status. 

```console
user@host:~$ echo github.com | portqry.sh
github.com:80   LISTENING

user@host:~$ echo 140.82.118.3 | portqry.sh
140.82.118.3:80 LISTENING

user@host:~$ echo github.com:22 | portqry.sh
github.com:22   LISTENING

user@host:~$ echo 140.82.118.3:22 | portqry.sh
140.82.118.3:22 LISTENING
```


## Additional Information

portqry.sh reports one of the following states:

* **LISTENING**

  A process is listening on the TCP/IP target port specified and portqry.sh receives a response from this process.
  
* **NOT LISTENING**

  No process is listening on the TCP/IP target port specified.

* **FILTERED**

  portqry.sh does not receive a response from the TCP/IP target port specified. The connection times out. The connection to the TCP/IP
  target port is being filtered e.g. by a firewall. A process may or may not be listening on the TCP/IP target port specified.
  
  
  
  
