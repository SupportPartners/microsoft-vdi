# Personas

## You can choose between 3 Personas:

## Persona 1: News/Sports/Events/Digital
For users making simple edits with up to two HD video layers and a lower third, user will edit from attached SSD if a single deployment or shared storage if part of a workgroup. This persona will not need to require high-resolution 4K codecs and will use only a few effects such as color correction, scale/transform and speed.
 

* Resolution: Up to 1080i30 (1920X1080)
* Codecs: XDCAM-50
* Estimated disk bandwidth required per simultaneous user: 170 Mbps
* Azure Instance type: Standard_NV6

 
Virtual Machine: 

* Standard_NV6 instance providing 6 vCPUs, 
* 56GB of RAM
* 340GB of SSD storage
* 1/2 NVIDIA Tesla M60 GPU

Storage: Azure Standard File Storage

## Persona 2: Advertising/Broadcasters/Studio
For users creating typical edits using 3 HD video layers, 2 graphics and 4-8 audio tracks, user will edit from attached SSD if a single deployment or shared storage if part of a workgroup. User may access other Adobe CC applications such as After Effects which will require high processing speeds
 

* Resolution: up to 1080i60 (1920X1080)
* Codec: DNxHD 145 and DNxHR SQ or ProRes 422 and ProRes HQ
* Estimated disk bandwidth required per simultaneous user: 340 Mbps
* Azure Instance type: Standard_NV12s_v3 

 
Virtual Machine: 

Standard_NV12s_v3 instance provides:
* 12 vCPUs (equivalent to 6 physical cores)
* 112GB of RAM
* 320GB of temporary SSD storage
* 1/2 NVIDIA Tesla M60 GPU

Storage: Azure Premium File Storage

## Persona 3: Promos/High-end Advertising
For personas creating graphics for other groups within the organization using brand guidelines created by Marketing. This persona typically needs the highest performance system, as render times are critical. They are mostly creating in After Effects, using high fidelity codecs that are designed for compositing, not real-time playback. User will edit from attached SSD if a single deployment or shared storage if part of a workgroup.
 

* Resolution: Up to 1080i60
* Codec: DNxHD 145 and DNxHR SQ or ProRes 422 and ProRes HQ
* Estimated disk bandwidth required per simultaneous user: 450 Mbps

 
Virtual Machine: 

Standard_NV24s_v3 instance type. The Standard_NV24s_v3 instance provides 
* 24 vCPUs (equivalent to 12 physical cores)
* 224GB of RAM
* 640GB of temporary SSD storage
* 1 x full NVIDIA Tesla M60 GPU

Storage: Azure Premium Files

## Persona Summary

|Persona Name	|Persona	|Resolution	|Codecs	|Estimated disk bandwidth required per simultaneous user	|Azure Instance type	|Azure File Storage	|
|---	|---	|---	|---	|---	|---	|---	|
|Persona1	|News/Sports/Events/Digital	|Up to 1080i30 (1920X1080)	|XDCAM-50	|170 Mbps	|Standard_NV6	|Standard	|
|Persona2	|Advertising/Broadcasters/Studios	|Up to 1080i60 (1920X1080)	|DNxHD 145 DNxHR SQ or ProRes 422 ProRes HQ     |340 Mbps	|Standard_NV12s_v3	|Premium	|
|Persona3	|Promos/High-end Advertising	|Up to 1080i60	|DNxHD 145  DNxHR SQ or ProRes 422 ProRes HQ	|450 Mbps	|Standard_NV24s_v3	|Premium	|

## Instance Size Summary

|Instance Size	|vCPUs	|RAM (GB)	|GPU	|Local temp SSD storage (GB)	|
|---	|---	|---	|---	|---	|
|Standard_NV6	|6	|56	|1/2 NVIDIA Tesla M60	|340	|
|standard_NV12s_v3	|12	|112	|1/2 NVIDIA Tesla M60	|320	|
|Standard_NV24s_v3	|24	|224	|1 NVIDIA Tesla M60	|640	|

# Core Azure Resources deployed :

* App Registration (CAM Service Principal)
* Virtual Machine - Active Directory
* Virtual Machine- Cloud Access Connector
* Azure File Storage (2TB by default- of which only around 40GB is in use.)
* Storage Account- VM boot diagnostics 
* Network Security Group 
* Virtual Network 
* Workstations (max 5)



## Msoft VDI Templates- Infrastructure components- detailed

* Teradici Cloud Access Manager Service
    * Teradici SAAS service- hosted by Teradici
* Teradici Cloud Access Manager Connector
    * Part of Teradici SAAS service- hosted by Teradici
* App Registration (CAM Service Principal)
* Virtual Machine - Active Directory
    * F2 (standard) 
* Virtual Machine- Cloud Access Connector
    * D2s_V3
* Nat Gateway 
* Azure File Storage- dependent on client requirements
    * Standard- 2TiB
    * Premium- 2TiB
* Block block
    * Hot @150GB
* Storage- boot diagnostics 
* Private DNS Zone 
* Network Security Group 
* Virtual Network 
* GitHub Demo Asset repository
* Workstations- dependent on requirements



# Azure File

|Persona Name	|Estimated disk bandwidth required per simultaneous user	|Persona	|Azure File Storage	|
|---	|---	|---	|---	|
|Persona1	|170 Mbps	|News/Sports/Events/Digital	|Standard	|
|Persona2	|340 Mbps	|Advertising/Broadcasters/Studios	|Premium	|
|Persona3	|450 Mbps	|Promos/High-end Advertising	|Premium	|


