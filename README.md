## Preconditions

* You are logged in as `auser@example.com` (the admin for the domain `example.com` for your the organization with orgid `111111111111`.
* terraform is installed.

## Create the terraform admin project

* Customize your environment by editing `variables.tf`.
* Create the project.
```bash
$ source ./activate

$ echo $TF_ADMIN
auser-tfroot

$ gcloud projects create ${TF_ADMIN} \
>   --organization ${TF_VAR_org_id} \
>   --set-as-default
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/auser-tfroot].
Waiting for [operations/cp.8118273614719203779] to finish...done.
Updated property [core/project] to [auser-tfroot].

$ gcloud iam service-accounts create "$TF_SVCAC" \
>   --display-name "Terraform admin account"
Created service account [tfadmin].

$ gcloud iam service-accounts list
NAME                     EMAIL
Terraform admin account  tfadmin@auser-tfroot.iam.gserviceaccount.com

$ gcloud iam service-accounts keys create ${TF_CREDS} \
>   --iam-account ${TF_SVCAC}@${TF_ADMIN}.iam.gserviceaccount.com
created key [d1f22ef4c4086bc4c12a2bd13ab6e2087a7f6025] of type [json] as 
[/home/auser/.gcloud/auser-tfroot.json] for [tfadmin@auser-tfroot.iam.gserviceaccount.com]

$ gcloud projects add-iam-policy-binding ${TF_ADMIN} \
>   --member serviceAccount:${TF_SVCAC}@${TF_ADMIN}.iam.gserviceaccount.com \
>   --role roles/viewer

$ gcloud services enable cloudresourcemanager.googleapis.com
Operation "operations/acf.e85faf36-fed9-40ca-940a-83fe6ec8d93a" finished successfully.

$ gcloud services enable cloudbilling.googleapis.com
Operation "operations/acf.89ff7ae6-d421-45b3-a72f-28223c7cea01" finished successfully.

$ gcloud services enable iam.googleapis.com
Operation "operations/acf.a95febef-03cd-4736-b1b7-028402c3ae16" finished successfully.

$ gcloud services enable compute.googleapis.com
# Wait 4-5 minutes to complete
Operation "operations/acf.2be58b51-1766-483e-9baf-55cdfa8712d6" finished successfully.

$ gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_SVCAC}@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator

$ gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_SVCAC}@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/billing.user
```


## Create the infra

```bash
$ gcloud config set project auser-tfroot
(auser-tfroot)$ terraform init
(auser-tfroot)$ terraform plan
(auser-tfroot)$ terraform apply 
...snipped...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
Outputs:
ip1 = 35.203.100.50
ip2 = 35.233.200.78
project_id = dual-nics-lazy-llama
project_number = 111111111111
subnetwork1.gateway = 10.5.0.1

$ gcloud config set project dual-nics-lazy-llama

$ gcloud compute instances list
NAME     ZONE        MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP          EXTERNAL_IP                    STATUS
duanics  us-west1-a  f1-micro                   10.5.0.2,10.138.0.2  35.203.100.50,35.233.200.78   RUNNING
```

## Verification of the newly created VM

SSH into the new VM `duanics`.

Investigate the routing tables and network interfaces:

```bash

 $ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
ens4             UP             10.5.0.2/32 fe80::4001:aff:fe05:2/64 
ens5             UP             10.138.0.2/32 fe80::4001:aff:fe8a:2/64 

 $ ip route show table special
default via 10.138.0.1 dev ens5 
10.138.0.0/20 dev ens5  scope link  src 10.138.0.2 

 $ ip route show table main
default via 10.5.0.1 dev ens4 
10.5.0.0/28 via 10.5.0.1 dev ens4 
10.5.0.1 dev ens4  scope link 
10.138.0.0/20 via 10.138.0.1 dev ens5 
10.138.0.1 dev ens5  scope link 

 $ netstat -anr
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         10.5.0.1        0.0.0.0         UG        0 0          0 ens4
10.5.0.0        10.5.0.1        255.255.255.240 UG        0 0          0 ens4
10.5.0.1        0.0.0.0         255.255.255.255 UH        0 0          0 ens4
10.138.0.0      10.138.0.1      255.255.240.0   UG        0 0          0 ens5
10.138.0.1      0.0.0.0         255.255.255.255 UH        0 0          0 ens5

 $ ip rule
0:      from all lookup local 
32761:  from all oif ens5 lookup special 
32762:  from all to 10.138.0.0/20 lookup special 
32763:  from 10.138.0.0/20 lookup special 
32766:  from all lookup main 
32767:  from all lookup default 
```

Attempt to ping via both interfaces.
```bash

 $ ping -I ens5 -c 1 ipfs.io
PING ipfs.io (209.94.78.78) from 10.138.0.2 ens5: 56(84) bytes of data.
64 bytes from 209.94.78.78: icmp_seq=1 ttl=52 time=19.1 ms
--- ipfs.io ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 19.147/19.147/19.147/0.000 ms

 $ ping -I ens4 -c 1 ipfs.io
PING ipfs.io (209.94.78.80) from 10.5.0.2 ens4: 56(84) bytes of data.
64 bytes from 209.94.78.80: icmp_seq=1 ttl=52 time=19.3 ms
--- ipfs.io ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 19.377/19.377/19.377/0.000 ms

 $ ping -c 1 ipfs.io
PING ipfs.io (209.94.78.80) 56(84) bytes of data.
64 bytes from 209.94.78.80: icmp_seq=1 ttl=52 time=19.1 ms
--- ipfs.io ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 19.155/19.155/19.155/0.000 ms
```

Et voilà !
¶
