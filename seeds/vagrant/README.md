# Clusterlite Project Seed

## Distributed Cluster over Local VMs

This project seed demonstrates how clusterlite managed cluster of Docker containers can be launched over a set of virtual machines.

### Prerequisites

- [VirtualBox 5.1.22](https://www.virtualbox.org/wiki/Downloads). It is used to run virtual machines.
    - Note: later version may work but has not been tried.
    - [windows only] C:\Program Files\Oracle\VirtualBox\drivers\network\*\*.inf files -> Right click -> Install
- [Vagrantup 1.9.2] (https://www.vagrantup.com/downloads.html). It is used to create virtual machines atuomatically.
    - Note: later version may work but has not been tried.
- ssh in PATH (adding ssh coming with git is fine)
- Valid configuration for `http_proxy`, `https_proxy` and `no_proxy` environment variables if behind proxy
- Internet connection

### Installation Steps

- Enable or disable machines in `Vagranthosts.yaml` file.
- Run `vagrant up` in the current directory and wait until virtual machines are created, up and running.

### Operation Steps

- Run `vagrant ssh <machine-name>` in the current directory (machine name is defined in [Vagranthosts.yaml](./Vagranthosts.yaml) file, for example: `vagrant ssh m1`)
- Run `sudo clusterlite nodes` - to check status of nodes
- Run `sudo clusterlite help` - for more help on operations

### Sample Configuration
File [clusterlite.yaml](./clusterlite.yaml) defines settings for sample Cassandra cluster. When nodes are up and running, you may check that all cassandra nodes connected and formed the cluster. Sample configuration opens client ports for Cassandra, so it can be accessed from a host machine too via CQL.

```
vagrant@m1:~$ sudo docker exec -it cassandra /opt/cassandra/bin/nodetool status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address    Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.32.4.1  104.59 KiB  32           66.1%             26fca3ba-2451-4ee4-8050-be48cdf57c8a  rack1
UN  10.32.4.2  95.09 KiB  32           67.8%             b5521f27-e613-4abb-8b3a-2fbfbb9ffdcc  rack1
UN  10.32.4.3  95.09 KiB  32           66.2%             08593a3a-18a9-4854-9cde-11dd1a4cbc59  rack1
```

Note that cassandra recognized the same IP addresses as assigned by the clusterlite:
```
vagrant@m1:~$ sudo clusterlite lookup cassandra
10.32.4.3
10.32.4.2
10.32.4.1
```

### Next steps
Modify the [clusterlite.yaml](./clusterlite.yaml) file to launch your services. You may browse for and try [other sample configurations](../../examples) to get started.