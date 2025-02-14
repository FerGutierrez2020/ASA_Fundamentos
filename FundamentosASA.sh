
"""
Autor: Fer Gutierrez
SageITraining - Certificarse hace la diferencia
Fundamentos ASA:
Configuración Inicial
PBR
NAT
Transparent Firewall
"""

---------------------
—ASA_Cohort_Initial—
---------------------
1. ASA initial
Objective: 
Basic License features
Basic configuration on interfaces
 
 
Show commands:
Show license all: Smart licensing is needed
Show version: Displays version and features
show mode: Displays current ASA mode
 
Summary of Steps:
interface gi0/0
ipaddress 10.10.10.10 255.255.255.0
nameif outside
no shut
 
interface gi0/1
ip address 10.20.20.10 255.255.255.0
nameif DMZ
security level 50
no shut

---------------------
——ASA multi-context—
---------------------
On ASA

CCIEASA#show mode

Configuration steps

!
Config t
mode multiple -> this command will trigger a reload
!
Show mode
Show context
!
CCIEASA(Config)#delete *.cfg
!
admin-context admin
context admin
config-url disk0:/admin.cfg
exit
!
context one
config-url disk0:one.cfg
allocate interface gi0/0
allocate interface gi0/1
!
interface gi0/0
no shut
interface gi0/1
no shut
!
changeto context one
interface gi0/0
ip address 12.0.0.2 255.0.0.0
nameif inside
sec 100
!
interface gi0/1
ip address 13.0.0.2 255.0.0.0
nameif outside
!


Note: To revert back type mode single command

-----------------------------
——Transparent firewall ———
-----------------------------
Objective: 
Transparent firewall configuration
Show commands


Summary of Steps

1. Switch the ASA to transparent mode
2. Enable and configure each interface
3. Configure VLAN interfaces and assign them to bridge-groups
4. Assign an IP address to the Bridge Virtual Interface (BVI) for management
5. Enable HTTP for management via ASDM

Limitations:
No VPN is supported
Only static routing is supported

Initial Show Commands:
Show firewall

Configuration 

PC1
sudo hostname PC1
sudo ifconfig eth0 10.10.10.2  netmask 255.255.255.0

PC2 
sudo hostname PC2
sudo ifconfig eth0 10.10.10.3  netmask 255.255.255.0

sudo hostname PCManagement
sudo ifconfig eth0 10.10.10.20  netmask 255.255.255.0

Note: configure 

Config t
Firewall Transparent
!
Firewall transparent
Interface BVI 1 
Ip address 10.10.10.1 255.255.255.0
!
Int Gi0/1
Bridge-group 1
Nameif inside
No shut
Exit
!
Int Gi0/0
Bridge-group 1
Nameif outside
No shut
!
ssh 0 0 inside 
exit
!
show nameif
show bridge-group
!
 
Verification
config t
logging on 
exit
!
Ping pc2 to pc 1 it should fail due to ping not inspected
ping 10.10.10.2
show logging
!
 
Policy-map global_policy
Class inspection_default
Inspect icmp
 
!
Ping again, it should work this time. 
 
 
 
 
Show commands
Show firewall
Show run int Eth0/Eth1
Show int ip br
 
Debug commands
logging on 
logging console 7 / no logging console
 
-----------------------------
——ASA Policy Based Routing ——
-----------------------------

Configuration:

InternalRouter

interface Loopback1
ip address 10.10.0.1 255.255.255.255
!
interface Loopback2
ip address 10.20.0.1 255.255.255.0
!
interface Loopback11
ip address 10.10.1.1 255.255.255.0
!
interface Loopback22
ip address 10.20.1.1 255.255.255.0
!
interface GigabitEthernet1
ip address 192.168.100.1 255.255.255.0
no shut
!
ip route 0.0.0.0 0.0.0.0 192.168.100.2
 
 
ISP1
!
interface GigabitEthernet1
ip address 1.1.1.2 255.255.255.0
no shut
!
ip route 0.0.0.0 0.0.0.0 1.1.1.1
 
ISP2
!
interface GigabitEthernet1
ip address 2.2.2.2 255.255.255.0
no shut
!
ip route 0.0.0.0 0.0.0.0 2.2.2.1
 
ASA
Pwd:cisco
!!!!!!!!!PBR route map in inside interface!!!!!!
interface GigabitEthernet0/0
nameif inside
security-level 100
ip address 192.168.100.2 255.255.255.0
no shut
!
interface GigabitEthernet0/1
nameif ISP1
security-level 0
ip address 1.1.1.1 255.255.255.0
no shut
!
interface GigabitEthernet0/2
nameif ISP2
security-level 0
ip address 2.2.2.1 255.255.255.0
no shut
!
!!!!!!!!!!Extended ACL to Match the source traffic!!!!!!
access-list ACL_ISP1 extended permit ip 10.10.0.0 255.255.0.0 1.1.1.0 255.255.255.0
access-list ACL_ISP2 extended permit ip 10.20.0.0 255.255.0.0 2.2.2.0 255.255.255.0
 
!!!!!!!!!!PBR configuration!!!!!!
!
route-map PBR permit 10
 match ip address ACL_ISP1
 set ip next-hop 1.1.1.2
!
route-map PBR permit 20
 match ip address ACL_ISP2
 set ip next-hop 2.2.2.2
!
interface GigabitEthernet0/0
policy-route route-map PBR
!
route ISP1 0.0.0.0 0.0.0.0 1.1.1.2 
route ISP2 0.0.0.0 0.0.0.0 2.2.2.2 
route inside 10.10.0.0 255.255.0.0 192.168.100.1 1
route inside 10.20.0.0 255.255.0.0 192.168.100.1 1
!
Policy-map global_policy
Class inspection_default
Inspect icmp
!

------------
Verification
------------

Turn on Policy-route and ICMP debug on the ASA with the command debug icmp trace and debug policy-route.

Ping from InternalRouter to 
ISP 1-> ping 1.1.1.2 source loopback 1 and 11
ISP2 -> ping 2.2.2.2 source loopback 2 and 22

See logs on ASA


Notes:
1      We need to configure proper routing to allow the traffic to return from ISP to internal network (in my lab I used static routes) in order to avoid asymmetric routing 
2      In order for ASA to make decisions for source subnets/IP addresses, we need to use Extended ACLs.
3      You can use 1 IP address and source to test and once successful, you can use the entire subnet

Windows PC
Username: IEUser
Password: Passw0rd!

------------
ASA NATs
------------

Note: ICMP already inspected

InsideRouter
!
config t
interface GigabitEthernet1
ip address 10.1.1.1 255.255.255.0
no shut
!
interface loopback99
ip address 10.2.1.50 255.255.255.0
no shut
!
 
!
DMZRouter
!
config t
interface GigabitEthernet1
ip address 11.1.1.1 255.255.255.0
no shut
!
 
OutsideRouter
!
config t
interface GigabitEthernet1
ip address 101.1.1.1 255.255.255.0
no shut
!
 
ASA
int Gi0/0
no shut
ip address 10.1.1.2 255.255.255.0
nameif inside
security-level 100
exit
!
!
int Gi0/1
no shut
ip address 101.1.1.2 255.255.255.0
nameif outside
security-level 0
!
int Gi0/2
no shut
ip address 11.1.1.2 255.255.255.0
nameif dmz
security-level 50
exit
!
InsideRouter
ip route 0.0.0.0 0.0.0.0 10.1.1.2 
end
!
DmzRouter
ip route 0.0.0.0 0.0.0.0 11.1.1.2
end
!
OutsideRouter
ip route 0.0.0.0 0.0.0.0 101.1.1.2
en
!

On ASA
route inside 10.1.1.0 255.255.255.0 10.1.1.1
route inside 10.2.1.0 255.255.255.0 10.1.1.1
route dmz 101.1.1.0 255.255.255.0 101.1.1.1
route outside 11.1.1.0 255.255.255.0 10.1.1.1
!
Policy-map global_policy
Class inspection_default
Inspect icmp
!
!
 

STATIC NAT

On ASA
object network loop_nat
host 10.2.1.50
nat (inside,outside) static 101.1.1.80

------------
Verification
------------
Ping from InsideRouter lo99 to OutsideRouter G1 interface
ping 101.1.1.1 source loopback99

Dynamic NAT
On ASA
object network dmz_nat
subnet 11.1.1.0 255.255.255.0
exit
!
object network dmz_nat_pool
range 101.1.1.20 101.1.1.60
exit
nat (dmz,outside) source dynamic dmz_nat dmz_nat_pool 

------------
Verification
------------
ping 101.1.1.1 from DMZ router


PAT
On ASA

object network inside_nat
subnet 10.1.1.0 255.255.255.0
exit
nat (inside,outside) source dynamic inside_nat interface

!
------------
Verification
------------
Ping from InsideRouter to OutsideRouter G1 interface
ping 101.1.1.1

Show commands:
show xlate
show nat