# csfpost-docker.sh
Make 🐳 Docker play nice with 🧱ConfigServer Firewall

Since both Docker an CSF edit iptables, ports exposed by docker endup accessible even if not opened in csf!

This is my take to make Docker play nice with CSF by:

- disabling Docker management of iptables
- adding csf post script to allow networking for containers
- manually open needed ports on csf

## Installation

It can be used as a standalone script by runnning:

```

```

or as a drop-in replacement for UFW on [OpenPanel](https://openpanel.co) servers.

```

```
