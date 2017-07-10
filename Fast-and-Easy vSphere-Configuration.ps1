######################################################################
# Created By @RicardoConzatti | November 2016
# www.Solutions4Crowds.com.br
######################################################################
$vCenter = "lab-n-vc1c.s4c.local" # Default = 0
$vCuser = "administrator@vsphere.local" # Default = 0
$MyHosts = 'lab-n-esxi1c.s4c.local','lab-n-esxi2c.s4c.local','lab-n-esxi3c.s4c.local' # Default = 0
$TestServer = 1 # 1 off | 0 on
######################################################################
$NumHost = $MyHosts.count
cls
$S4Ctitle = "Fast and Easy vSphere Configuration v2.0"
$Body = 'www.Solutions4Crowds.com.br

=======================================================
'
$CSS="<style>
body {
font-family: Verdana, sans-serif;
font-size: 14px;
color: #666666;
background: #FEFEFE;
}
#title{
color:#34597C;
font-size: 30px;
font-weight: bold;
padding-top:25px;
margin-left:35px;
height: 50px;
}
#subtitle{
font-size: 11px;
margin-left:35px;
}
#main {
position:relative;
padding-top:10px;
padding-left:10px;
padding-bottom:10px;
padding-right:10px;
}
table{
width:100%;
border-collapse:collapse;
}
table td, table th {
border:1px solid #34597C;
padding:3px 7px 2px 7px;
}
table th {
text-align:left;
padding-top:5px;
padding-bottom:4px;
background-color:#34597C;
color:#fff;
}
table tr.alt td {
color:#000;
background-color:#34597C;
}
</style>
"
$BoxContentOpener="<div id='boxcontent'>"
$PageBoxCloser="</div>"
$br="<br>"
Function MyConfiguration { # 0 - CONFIGURATION
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "CONFIGURATION`n`n=======================================================`n"
	$vCenter = read-host "vCenter Server (FQDN or IP)"
	write-host
	[array]$MyHosts = (Read-Host "ESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
	$NumHost = $MyHosts.count
	write-host "`nMake sure the information is correct`nGo to option 1 and test servers`n"
	pause
	vMenu
}
Function MyTest { # 1 - TEST SERVERS
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Test Connection with the ESXi hosts and vCenter Server`n" 
	if ($vCenter -eq 0) {
		$vCenter = read-host "vCenter Server (FQDN or IP)"
		write-host
	}
	if ($MyHosts -eq 0) {
		[array]$MyHosts = (Read-Host "ESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
		write-host
	}
	$Hostname = hostname
	$QuestionDNS = read-host "Would you like to execute Flush & Register DNS on"$Hostname" (must be run as administrator)? (Y or N)"
	write-host
	if ($QuestionDNS -eq "Y") {
		write-host "Running FlushDNS..."
		ipconfig /flushdns
		write-host
		write-host "Running RegisterDNS..." 
		ipconfig /registerdns
		write-host
	}
	write-host "Ping Servers`n"
	$ConnectionError = 0
	If (Test-Connection $vCenter -count 4 -quiet) {write-host "$vCenter OK!" -foregroundcolor "green"} 
	else {write-host "$vCenter FAIL | Check network / DNS entry" -foregroundcolor "red"; $ConnectionError = 1;}
	$NumHostTotal = 0 # Test Hosts
	while($NumHost -ne $NumHostTotal) {
		If (Test-Connection $MyHosts[$NumHostTotal] -count 4 -quiet) {write-host $MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"} 
		else {write-host $MyHosts[$NumHostTotal]"FAIL | Check network / DNS entry" -foregroundcolor "red"; $ConnectionError = 1;}
		$NumHostTotal++;
	}
	If ($ConnectionError -eq 1) {
		$TestServer = 0
		write-host "`nFAIL`nCheck the errors and verify your network / DNS`n" -foregroundcolor "red";
		write-host "or go to option 0 and check the servers name`n"
	}
	else {
		write-host
		$TestServer = 1
		write-host "`nSUCCESS`n" -foregroundcolor "green"
		write-host "Go to option 2 and connect to vCenter Server`n"
	}
	pause
	vMenu
}
Function MyvCenter { # 2 - VCENTER SERVER
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Connect to vCenter Server`n`n=======================================================`n"
	if ($vCenter -eq 0) {
		$vCenter = read-host "vCenter Server (FQDN or IP)"
		write-host
	}
	else {
		write-host "vCenter Server: $vCenter`n"
	}
	if ($vCuser -eq 0) {
		$vCuser = read-host "Username (Ex: administrator@vsphere.local)"
		write-host
	}
	else {
		write-host "Username: $vCuser`n"
	}
	$vCpass = Read-Host -assecurestring "Password"
	$vCpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCpass))
	Connect-VIServer $vCenter -u $vCuser -password $vCpass | Out-Null
	write-host "`nConnected to $vCenter`n" -foregroundcolor "green"
	pause
	vMenu
}
Function CreateDC { # 3 - DATA CENTER
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Data Center ($vCenter)`n`n=======================================================`n"
	$MyDC = read-host "New Data Center Name"
	New-Datacenter -Location (Get-Folder -NoRecursion) -Name $MyDC | Out-Null # Create Data Center
	write-host "`nData Center $MyDC OK!`n" -foregroundcolor "green"
	pause;vMenuDatacenter
}
Function ListHostsDC {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "List ESXi Host - Data Center ($vCenter)`n`n=======================================================`n"
	$GetDC = Get-Datacenter | Get-View
	if ($GetDC.Name.count -eq 0) {
		write-host "There is no data center" -foregroundcolor "red"
		write-host "Redirecting to create data center`n"
		pause;CreateDC
	}
	if ($GetDC.Name.count -eq 1) {
		write-host "Data Center Name:"$GetDC.Name
		$MyDC = $GetDC.Name
	}
	else {
		$ListDCtotal = 0
		while ($GetDC.Name.count -ne $ListDCtotal) {
			write-host "$ListDCtotal -"$GetDC.Name[$ListDCtotal]
			$ListDCtotal++;
		}
		$MyDC = read-host "`nData Center Number"
		$MyDC = $GetDC.Name[$MyDC]
	}
	Get-VMHost -Location $MyDC | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,MemoryTotalGB,MemoryUsageGB,CpuTotalMhz,CpuUsageMhz | Format-List # List ESXi Hosts Cluster
	$QuestionExport = read-host "Would you like to export this report? (Y or N)"
	if ($QuestionExport -eq "Y") {
		$ExportPath = read-host "`nPath to export (Ex: C:\temp)"
		write-host "`nHTML or CSV`n"
		write-host "1 - HTML`n"
		write-host "2 - CSV`n"
		$QuestionExportFormat = read-host "Choose an Option"
		write-host
		if ($QuestionExportFormat -eq 1) {
			$Report = Get-VMHost -Location $MyDC | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,@{Label="MemoryTotalGB";Expression={"{0:N2} GB" -f ($_.MemoryTotalGB)}},@{Label="MemoryUsageGB";Expression={"{0:N2} GB" -f ($_.MemoryUsageGB)}},CpuTotalMhz,CpuUsageMhz | ConvertTo-HTML -Fragment
			if (-not $Report) {
				$Report = New-Object PSObject -Property @{
				  Name = ""
				  Version = ""
				  Manufacturer = ""
				  Model = ""
				  PowerState = ""
				  State = ""
				  MemoryTotalGB = ""
				  MemoryUsageGB = ""
				  CpuTotalMhz = ""
				  CpuUsageMhz= ""
			}
		}
			ConvertTo-HTML -Title "::. Solutions4Crowds .::" -Head "<title>::. Solutions4Crowds .::</title><div id='title' align='center'>vCenter: $vCenter | List ESXi Host - $MyDC</div>$br<div id='subtitle'>Solutions4Crowds.com.br | Generated report: $(Get-Date) </div> $br" -Body "$CSS $BoxContentOpener $Report $PageBoxCloser" | Out-File $ExportPath'\ESXi-'$MyDC'-Details.html'
			write-host "Exported to $ExportPath\ESXi-$MyDC-Details.html`n"
		}
		if ($QuestionExportFormat -eq 2) {
			Get-VMHost -Location $MyDC | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,MemoryTotalGB,MemoryUsageGB,CpuTotalMhz,CpuUsageMhz | Export-Csv "$ExportPath\ESXi-$MyDC-Details.csv"
			write-host "`nExported to $ExportPath\ESXi-$MyDC-Details.csv`n"
		}
	}
	else {
		pause;vMenuDatacenter
	}
	pause;vMenuDatacenter
}
Function CreateCluster { # 4 - CLUSTER
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Cluster ($vCenter)`n`n=======================================================`n"
	$GetDC = Get-Datacenter | Get-View
	if ($GetDC.Name.count -eq 0) {
		write-host "There is no data center" -foregroundcolor "red"
		write-host "Redirecting to create data center`n"
		pause;CreateDC
	}
	if ($GetDC.Name.count -eq 1) {
		write-host "Data Center Name:"$GetDC.Name
		$MyDC = $GetDC.Name
	}
	else {
		$ListDCtotal = 0
		while ($GetDC.Name.count -ne $ListDCtotal) {
			write-host "$ListDCtotal -"$GetDC.Name[$ListDCtotal]
			$ListDCtotal++;
		}
		$MyDC = read-host "`nData Center Number"
		$MyDC = $GetDC.Name[$MyDC]
	}
	write-host
	$MyCluster = read-host "New Cluster Name"
	write-host
	New-Cluster -Location $MyDC -Name $MyCluster | Out-Null # Create Cluster
	write-host "Cluster $MyCluster OK!`n" -foregroundcolor "green"
	pause;vMenuCluster	
}
Function AddHostsToCluster {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Add Hosts ESXi to Cluster ($vCenter)`n`n=======================================================`n"
	$GetCluster = Get-Cluster | Get-View
	if ($GetCluster.Name.count -eq 0) {
		write-host "There is no cluster" -foregroundcolor "red"
		write-host "Redirecting to create cluster`n"
		pause;CreateCluster
	}
	if ($GetCluster.Name.count -eq 1) {
		write-host "Cluster Name:"$GetCluster.Name
		$MyCluster = $GetCluster.Name
	}
	else {
		$ListClustertotal = 0
		while ($GetCluster.Name.count -ne $ListClustertotal) {
			write-host "$ListClustertotal -"$GetCluster.Name[$ListClustertotal]
			$ListClustertotal++;
		}
		$MyCluster = read-host "`nCluster Number"
		$MyCluster = $GetCluster.Name[$MyCluster]
	}
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to add these ESXi hosts to"$GetCluster.Name[$MyCluster]"? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	$MyESXiPass = Read-Host -assecurestring "`nESXi Password"
	$MyESXiPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MyESXiPass))
	$NumHostTotal = 0
	write-host
	while($NumHost -ne $NumHostTotal) {
		Add-VMHost -Name $MyHosts[$NumHostTotal] -Location $MyCluster -User root -Password $MyESXiPass -Force -RunAsync | Out-Null # Add to Cluster
		Start-Sleep -Seconds 10
		Set-VMHost -VMHost $MyHosts[$NumHostTotal] -State "Maintenance" -RunAsync | Out-Null # Enter Maintenance Mode
		write-host "ESXi host"$MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause;vMenuCluster
}
Function ListHostsCluster {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "List ESXi Host - Cluster ($vCenter)`n`n=======================================================`n"
	$GetCluster = Get-Cluster | Get-View
	if ($GetCluster.Name.count -eq 0) {
		write-host "There is no cluster" -foregroundcolor "red"
		write-host "Redirecting to create cluster`n"
		pause;CreateCluster
	}
	if ($GetCluster.Name.count -eq 1) {
		write-host "Cluster Name:"$GetCluster.Name
		$MyCluster = $GetCluster.Name
	}
	else {
		$ListClustertotal = 0
		while ($GetCluster.Name.count -ne $ListClustertotal) {
			write-host "$ListClustertotal -"$GetCluster.Name[$ListClustertotal]
			$ListClustertotal++;
		}
		$MyCluster = read-host "`nCluster Number"
		$MyCluster = $GetCluster.Name[$MyCluster]	
	}
	Get-VMHost -Location $MyCluster | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,MemoryTotalGB,MemoryUsageGB,CpuTotalMhz,CpuUsageMhz | Format-List # List ESXi Hosts Cluster
	$QuestionExport = read-host "Would you like to export this report? (Y or N)"
	if ($QuestionExport -eq "Y") {
		$ExportPath = read-host "`nPath to export (Ex: C:\temp)"
		write-host "`nHTML or CSV`n"
		write-host "1 - HTML`n"
		write-host "2 - CSV`n"
		$QuestionExportFormat = read-host "Choose an Option"
		write-host
		if ($QuestionExportFormat -eq 1) {
			$Report = Get-VMHost -Location $MyCluster | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,@{Label="MemoryTotalGB";Expression={"{0:N2} GB" -f ($_.MemoryTotalGB)}},@{Label="MemoryUsageGB";Expression={"{0:N2} GB" -f ($_.MemoryUsageGB)}},CpuTotalMhz,CpuUsageMhz | ConvertTo-HTML -Fragment
			if (-not $Report) {
				$Report = New-Object PSObject -Property @{
				  Name = ""
				  Version = ""
				  Manufacturer = ""
				  Model = ""
				  PowerState = ""
				  State = ""
				  MemoryTotalGB = ""
				  MemoryUsageGB = ""
				  CpuTotalMhz = ""
				  CpuUsageMhz= ""
			}
		}
		ConvertTo-HTML -Title "::. Solutions4Crowds .::" -Head "<title>::. Solutions4Crowds .::</title><div id='title' align='center'>vCenter: $vCenter | List ESXi Host - $MyCluster</div>$br<div id='subtitle'>Solutions4Crowds.com.br | Generated report: $(Get-Date) </div> $br" -Body "$CSS $BoxContentOpener $Report $PageBoxCloser" | Out-File $ExportPath'\ESXi-'$MyCluster'-Details.html'
		write-host "Exported to $ExportPath\ESXi-$MyCluster-Details.html`n"
		}
		if ($QuestionExportFormat -eq 2) {
			Get-VMHost -Location $MyCluster | select Name,Version,Manufacturer,Model,PowerState,ConnectionState,MemoryTotalGB,MemoryUsageGB,CpuTotalMhz,CpuUsageMhz | Export-Csv "$ExportPath\ESXi-$MyCluster-Details.csv"
			write-host "`nExported to $ExportPath\ESXi-$MyCluster-Details.csv`n"
		}
	}
	else {
		pause;vMenuCluster
	}
	pause;vMenuCluster
}
Function ConfigureClusterHA {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Configure Cluster HA ($vCenter)`n`n=======================================================`n"
	$GetCluster = Get-Cluster | Get-View
	if ($GetCluster.Name.count -eq 0) {
		write-host "There is no cluster" -foregroundcolor "red"
		write-host "Redirecting to create cluster`n"
		pause;CreateCluster
	}
	if ($GetCluster.Name.count -eq 1) {
		write-host "Cluster Name:"$GetCluster.Name
		$MyCluster = $GetCluster.Name
	}
	else {
		$ListClustertotal = 0
		while ($GetCluster.Name.count -ne $ListClustertotal) {
			write-host "$ListClustertotal -"$GetCluster.Name[$ListClustertotal]
			$ListClustertotal++;
		}
		$MyCluster = read-host "`nCluster Number"
		$MyCluster = $GetCluster.Name[$MyCluster]	
	}
	write-host "`n1 - Enable HA`n" -foregroundcolor "green"
	write-host "2 - Disable HA`n" -foregroundcolor "red"
	$QuestionHA = read-host "Choose an Option"
	if ($QuestionHA -eq 1) { # Enable Cluster HA
		Get-Cluster $MyCluster | Set-Cluster -HAEnabled:$true -Confirm:$false | Out-Null
		write-host "`n$MyCluster HA enabled!`n"
	}
	if ($QuestionHA -eq 2) { # Disable Cluster HA
		Get-Cluster $MyCluster | Set-Cluster -HAEnabled:$false -Confirm:$false | Out-Null
		write-host "`n$MyCluster HA disabled!`n"
	}
	pause;vMenuCluster
}
Function ConfigureClusterDRS {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Configure Cluster DRS ($vCenter)`n`n=======================================================`n"
	$GetCluster = Get-Cluster | Get-View
	if ($GetCluster.Name.count -eq 0) {
		write-host "There is no cluster" -foregroundcolor "red"
		write-host "Redirecting to create cluster`n"
		pause;CreateCluster
	}
	if ($GetCluster.Name.count -eq 1) {
		write-host "Cluster Name:"$GetCluster.Name
		$MyCluster = $GetCluster.Name
	}
	else {
		$ListClustertotal = 0
		while ($GetCluster.Name.count -ne $ListClustertotal) {
			write-host "$ListClustertotal -"$GetCluster.Name[$ListClustertotal]
			$ListClustertotal++;
		}
		$MyCluster = read-host "`nCluster Number"
		$MyCluster = $GetCluster.Name[$MyCluster]	
	}
	write-host "`n1 - Enable DRS`n" -foregroundcolor "green"
	write-host "2 - Disable DRS`n" -foregroundcolor "red"
	$QuestionDRS = read-host "Choose an Option"
	if ($QuestionDRS -eq 1) { # Enable Cluster DRS
		Get-Cluster $MyCluster | Set-Cluster -DrsEnabled:$true -Confirm:$false | Out-Null
		write-host "`n$MyCluster DRS enabled!`n"
	}
	if ($QuestionDRS -eq 2) { # Disable Cluster DRS
		Get-Cluster $MyCluster | Set-Cluster -DrsEnabled:$false -Confirm:$false | Out-Null
		write-host "`n$MyCluster DRS disabled!`n"
	}
	pause;vMenuCluster
}
Function CreateVDS { # 5 - NETWORK
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create VDS ($vCenter)`n`n=======================================================`n"
	$GetDC = Get-Datacenter | Get-View
	if ($GetDC.Name.count -eq 0) {
		write-host "There is no data center" -foregroundcolor "red"
		write-host "Redirecting to create data center`n"
		pause;CreateDC
	}
	if ($GetDC.Name.count -eq 1) {
		write-host "Data Center Name:"$GetDC.Name
		$MyDC = $GetDC.Name
	}
	else {
		$ListDCtotal = 0
		while ($GetDC.Name.count -ne $ListDCtotal) {
			write-host "$ListDCtotal -"$GetDC.Name[$ListDCtotal]
			$ListDCtotal++;
		}
		$MyDC = read-host "`nData Center Number"
		$MyDC = $GetDC.Name[$MyDC]
	}
	write-host
	$MyVDS = read-host "New VDS Name"
	write-host
	$NumUplink = read-host "Number of Uplinks"
	write-host
	$MyMTU = read-host "MTU (Ex: Default = 1500 | Jumbo Frames = 9000)"
	write-host
	New-VDSwitch -Name $MyVDS -Location $MyDC -NumUplinkPorts $NumUplink -MTU $MyMTU -RunAsync | Out-Null # Create VDS
	write-host "$MyVDS with $NumUplink uplinks and MTU $MyMTU OK!`n" -foregroundcolor "green"
	pause;vMenuVDS
}
Function ListVDS {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "List VDS ($vCenter)`n`n=======================================================`n"
	$GetDC = Get-Datacenter | Get-View
	if ($GetDC.Name.count -eq 0) {
		write-host "There is no data center" -foregroundcolor "red"
		write-host "Redirecting to create data center`n"
		pause;CreateDC
	}
	if ($GetDC.Name.count -eq 1) {
		write-host "Data Center Name:"$GetDC.Name
		$MyDC = $GetDC.Name
	}
	else {
		$ListDCtotal = 0
		while ($GetDC.Name.count -ne $ListDCtotal) {
			write-host "$ListDCtotal -"$GetDC.Name[$ListDCtotal]
			$ListDCtotal++;
		}
		$MyDC = read-host "`nData Center Number"
		$MyDC = $GetDC.Name[$MyDC]
	}
	Get-VDSwitch -Location $MyDC | select Name,NumPorts,NumUplinkPorts,Mtu,Version | format-table # List VDS
	$QuestionExport = read-host "Would you like to export this report? (Y or N)"
	if ($QuestionExport -eq "Y") {
		$ExportPath = read-host "`nPath to export (Ex: C:\temp)"
		write-host
		write-host "HTML or CSV`n"
		write-host "1 - HTML`n"
		write-host "2 - CSV`n"
		$QuestionExportFormat = read-host "Choose an Option"
		write-host
		if ($QuestionExportFormat -eq 1) {
			$Report = Get-VDSwitch -Location $MyDC | select Name,NumPorts,NumUplinkPorts,Mtu,Version | ConvertTo-HTML -Fragment
			if (-not $Report) {
				$Report = New-Object PSObject -Property @{
				  Name = ""
				  NumPorts = ""
				  NumUplinkPorts = ""
				  MTU = ""
				  Version = ""
			}
		}
		ConvertTo-HTML -Title "::. Solutions4Crowds .::" -Head "<title>::. Solutions4Crowds .::</title><div id='title' align='center'>vCenter: $vCenter | List VDS - $MyDC</div>$br<div id='subtitle'>Solutions4Crowds.com.br | Generated report: $(Get-Date) </div> $br" -Body "$CSS $BoxContentOpener $Report $PageBoxCloser" | Out-File $ExportPath'\VDS-'$MyDC'-Details.html'
		write-host "Exported to $ExportPath\VDS-$MyDC-Details.html`n"
		}
		if ($QuestionExportFormat -eq 2) {
			Get-VDSwitch -Location $MyDC | select Name,NumPorts,NumUplinkPorts,Mtu,Version | Export-Csv "$ExportPath\VDS-$MyDC-Details.csv"
			write-host "`nExported to $ExportPath\VDS-$MyVDS-Details.csv`n"
		}
	}
	else {
		pause;vMenuVDS
	}
	pause;vMenuVDS
}
Function Listpg {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "List Port Group ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	Get-VDPortgroup -VDSwitch $MyVDS | select Name,VlanConfiguration,NumPorts,PortBinding | format-table # List Port Group
	$QuestionExport = read-host "Would you like to export this report? (Y or N)"
	if ($QuestionExport -eq "Y") {
		$ExportPath = read-host "`nPath to export (Ex: C:\temp)"
		write-host "`nHTML or CSV`n"
		write-host "1 - HTML`n"
		write-host "2 - CSV`n"
		$QuestionExportFormat = read-host "Choose an Option"
		write-host
		if ($QuestionExportFormat -eq 1) {
			$Report = Get-VDPortgroup -VDSwitch $MyVDS | select Name,VlanConfiguration,NumPorts,PortBinding | ConvertTo-HTML -Fragment
			if (-not $Report) {
				$Report = New-Object PSObject -Property @{
				  Name = ""
				  VlanConfiguration = ""
				  NumPorts = ""
				  PortBinding = ""
			}
		}
		ConvertTo-HTML -Title "::. Solutions4Crowds .::" -Head "<title>::. Solutions4Crowds .::</title><div id='title' align='center'>vCenter: $vCenter | List Port Group - $MyVDS</div>$br<div id='subtitle'> Solutions4Crowds.com.br | Generated report: $(Get-Date) </div> $br" -Body "$CSS $BoxContentOpener $Report $PageBoxCloser" | Out-File $ExportPath'\PortGroup-'$MyVDS'-Details.html'
		write-host "Exported to $ExportPath\PortGroup-$MyVDS-Details.html`n"
		}
		if ($QuestionExportFormat -eq 2) {
			Get-VDSwitch -Location $MyDC | select Name,NumPorts,NumUplinkPorts,Mtu,Version | Export-Csv "$ExportPath\PortGroup-$MyVDS-Details.csv"
			write-host "`nExported to $ExportPath\PortGroup-$MyVDS-Details.csv`n"
		}
	}
	else {
		pause;vMenuPortGroup
	}
	pause;vMenuPortGroup
}
Function Createpg {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Port Group ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	$NumPortPG = read-host "`nNumber of Ports (default = 8)"
	[array]$MyPG = (read-Host "`nPort Group Name (separate with comma)").split(",") | %{$_.trim()}
	[array]$MyVLANPG = (read-Host "`nVLAN ID - without VLAN = 0 - (separate with comma)").split(",") | %{$_.trim()}
	write-host
	$NumPG = $MyPG.count
	$NumPGTotal = 0
	while($NumPG -ne $NumPGTotal) {
		Get-VDSwitch -Name $MyVDS | New-VDPortgroup -Name $MyPG[$NumPGTotal] -VlanId $MyVLANPG[$NumPGTotal] -NumPorts $NumPortPG -RunAsync | Out-Null # Create Port Group for Virtual Machines
		write-host "PortGroup"$MyPG[$NumPGTotal]"with VLAN"$MyVLANPG[$NumPGTotal]"OK!" -foregroundcolor "green"
		$NumPGTotal++;
	}
	write-host "`nPort Groups OK!`n" -foregroundcolor "green"
	pause;vMenuPortGroup
}
Function CreatepgiSCSI {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Port Group iSCSI ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	write-host "`n# For more than TWO iSCSI Port Group, manually configure Teaming and Failover`n"
	[array]$MyPGiSCSI = (read-Host "New Port Group iSCSI Name (separate with comma)").split(",") | %{$_.trim()}
	[array]$MyVLANiSCSI = (read-Host "`nVLAN ID - without VLAN = 0 (separate with comma)").split(",") | %{$_.trim()}
	$NumPortPG = read-host "`nNumber of Ports (default = 8)"
	$NumPGiSCSI = $MyPGiSCSI.count
	$NumPGiSCSITotal = 0
	write-host "`nCreating Port Group`n"
	while($NumPGiSCSI -ne $NumPGiSCSITotal) {
		Get-VDSwitch -Name $MyVDS | New-VDPortgroup -Name $MyPGiSCSI[$NumPGiSCSITotal] -VlanId $MyVLANiSCSI[$NumPGiSCSITotal] -NumPorts $NumPortPG -RunAsync | Out-Null # Create PortGroup for Virtual Machines
		write-host "Port Group"$MyPGiSCSI[$NumPGiSCSITotal]"with VLAN"$MyVLANiSCSI[$NumPGiSCSITotal]"OK!" -foregroundcolor "green"
		$NumPGiSCSITotal++;
	}
	if ($NumPGiSCSI -eq "2") {
		write-host "`nConfiguring teaming and failover`n"
		Start-Sleep -Seconds 2
		Get-VDPortgroup -Name $MyPGiSCSI[0] | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink1" -UnusedUplinkPort "dvUplink2" | Out-Null # Modify PortGroup iSCSI-1 - dvUplink1 ACTIVE | dvUplink2 UNUSED
		write-host "PortGroup"$MyPGiSCSI[0]"teaming and failover OK!" -foregroundcolor "green"
		Get-VDPortgroup -Name $MyPGiSCSI[1] | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink2" -UnusedUplinkPort "dvUplink1" | Out-Null # Modify PortGroup iSCSI-2 - dvUplink1 UNUSED | dvUplink2 ACTIVE
		write-host "PortGroup"$MyPGiSCSI[1]"teaming and failover OK!`n" -foregroundcolor "green"
	}
	if ($NumPGiSCSI -gt "2") {
		write-host "`n# Manually configure teaming and failover"
	}
	pause;vMenuPortGroup
}
Function AddHostsToVDS {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Add Hosts ESXi to VDS ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to add these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
			write-host
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
		write-host
	}
	$NumHostTotal = 0
	write-host
	while($NumHost -ne $NumHostTotal) {
		Get-VDSwitch -Name $MyVDS | Add-VDSwitchVMHost -VMHost $MyHosts[$NumHostTotal] | Out-Null # Add to VDS
		write-host "Add"$MyHosts[$NumHostTotal]"to $MyVDS OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause;vMenuVDS
}
Function AddNICtoVDS {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Add Uplink (VMNIC) to VDS ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	write-host
	$HostsVDS = Get-VDSwitch -Name $MyVDS | Get-VMHost # Get ESXi hosts on VDS
	if ($HostsVDS.count -ne 0) {
		if ($NumHost -ne 0) {
			$NumHostTotal = 0
			while($NumHost -ne $NumHostTotal) {
				write-host $MyHosts[$NumHostTotal]
				$NumHostTotal++;
			}
			$QuestionESXi = read-host "`nWould you like to use these ESXi hosts VMNICs to $MyVDS ? (Y or N)"
			if ($QuestionESXi -eq "n") {
				[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
				$NumHost = $MyHosts.count
			}
		}
		else {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
		$NumVMNIC = Get-VMHostNetworkAdapter -Physical -VirtualSwitch $MyVDS # Get VMNIC on VDS
		$GetVDSname = Get-VDSwitch -Name $MyVDS | select *
		if ($NumVMNIC.count -ne 0) {
			write-host "`n======================================================="
			write-host "VMNICs on $MyVDS"
			write-host "======================================================="
			$NumHostTotal = 0;$HostOK = 0
			while($NumHost -ne $NumHostTotal) {
				$TheHost = $MyHosts[$NumHostTotal]
				$GetVDSnic = Get-VMHostNetworkAdapter -Physical -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS | Select * # Get VMNIC on Hosts ESXi
				
				if ($GetVDSnic.Name.count -eq $GetVDSname.NumUplinkPorts) {
					write-host $TheHost $GetVDSnic.Name"|"$GetVDSnic.Name.count"VMNICs OK!`n"
					$HostOK++;
				}
				else {
					write-host $TheHost $GetVDSnic.Name"`n" -foregroundcolor "red"
				}
				$NumHostTotal++;
			}
			write-host "=======================================================`n"
		}
		else {
			$NumVMNICtoAdd = 0
			write-host "`n$MyVDS doesnt have VMNIC" -foregroundcolor "red"
		}
		write-host $GetVDSname.Name"has"$GetVDSname.NumUplinkPorts"uplink ports"
		
		if ($HostOK -eq $NumHost) {
			write-host "Uplinks and VMNICs OK`n" -foregroundcolor "green"
		}
		else {
			write-host "`n======================================================="
			write-host "VMNICs"
			write-host "======================================================="
			$NumHostTotal = 0
			while($NumHost -ne $NumHostTotal) {
				$TheHost = $MyHosts[$NumHostTotal]
				$GetVMNIC = Get-VMHostNetworkAdapter -Physical -VMHost $TheHost | Select * # Get VMNIC on Hosts ESXi
				write-host $TheHost $GetVMNIC.Name"`n"
				$NumHostTotal++;
			}
			write-host "=======================================================`n" 
			[array]$MyNICs = (Read-Host "VMNICs (separate with comma)").split(",") | %{$_.trim()}
			$NumNIC = $MyNICs.count
			$NumHostTotal = 0
			$NumNICsTotal = 0
			write-host
			while($NumHost -ne $NumHostTotal) {
				while ($NumNIC -ne $NumNICsTotal) {
					$MyFirstNicHost = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -Physical -Name $MyNICs[$NumNICsTotal] # Add First NIC - Uplink
					Get-VDSwitch $MyVDS | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $MyFirstNicHost -Confirm:$false | Out-Null
					write-host "Configure"$MyHosts[$NumHostTotal]$MyNICs[$NumNICsTotal]"OK!" -foregroundcolor "green"
					$NumNICsTotal++;
				}
				$NumNICsTotal = 0
				$NumHostTotal++;
				write-host
			}
			write-host "`nHosts OK!`n" -foregroundcolor "green"
		}
	}
	else {
		write-host "The $MyVDS doesnt have ESXi hosts" -foregroundcolor "red"
		write-host "Redirecting to add ESXi Host to VDS`n"
		pause;AddHostsToVDS
	}
	pause;vMenuVDS
}
Function CreateVMKvMotion {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create VMKernel vMotion - ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	$GetPG = Get-VDPortgroup -VDSwitch $MyVDS
	$MyPGvMotion = read-host "`nvMotion Port Group Name ("$GetPG.Name")"
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	[array]$MyIPvMotionHosts = (Read-Host "`nvMotion IP (separate with comma)").split(",") | %{$_.trim()}
	write-host
	$MyMaskvMotion = read-host "vMotion Mask (Ex: 255.255.255.0)"
	$NumHostTotal = 0
	write-host
	while($NumHost -ne $NumHostTotal) {
		New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS -PortGroup $MyPGvMotion -IP $MyIPvMotionHosts[$NumHostTotal] -SubnetMask $MyMaskvMotion -VMotionEnabled $true | Out-Null # Create VMKernel vMotion
		write-host $MyHosts[$NumHostTotal]"with IP"$MyIPvMotionHosts[$NumHostTotal]"OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause;vMenuVMKernel
}
Function CreateVMK {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create VMKernel Generic ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	$GetPG = Get-VDPortgroup -VDSwitch $MyVDS | Get-View
	if ($GetPG.Name.count -eq 1) {
		write-host "`nDoesnt have Port Groups on $MyVDS" -foregroundcolor "red"
		write-host "Redirecting to create Port Group to VDS`n"
		pause;Createpg
	}
	else {
		$ListPGtotal = 0
		while ($GetPG.Name.count -ne $ListPGtotal) {
			write-host "$ListPGtotal -"$GetPG.Name[$ListPGtotal]
			$ListPGtotal++;
		}
		$MyPG = read-host "`nPort Group Number"
		$MyPG = $GetPG.Name[$MyPG]
	}
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	[array]$MyIPHostsVMK = (Read-Host "`nVMKernel IP (separate with comma)").split(",") | %{$_.trim()}
	$MyMaskVMK = read-host "`nVMKernel Mask (Ex: 255.255.255.0)"
	$MyMTU = read-host "`nMTU (Ex: Default = 1500 | Jumbo Frames = 9000)"
	$NumHostTotal = 0
	write-host
	while($NumHost -ne $NumHostTotal) {
		New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS -PortGroup $MyPG -IP $MyIPHostsVMK[$NumHostTotal] -SubnetMask $MyMaskVMK -MTU $MyMTU | Out-Null # Create VMKernel
		write-host $MyHosts[$NumHostTotal]"with IP"$MyIPHostsVMK[$NumHostTotal]"OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nEnable the function you want (vMotion, FT, MGMT, VSAN...)`n"
	write-host "Hosts OK!`n" -foregroundcolor "green"
	pause;vMenuVMKernel	
}
Function ListVMK {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "List VMKernel ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	write-host
	Get-VMHostNetworkAdapter -VMKernel -Name $MyVMK -VirtualSwitch $MyVDS | select VMHost,Name,IP,SubnetMask,Mtu,PortGroupName,ManagementTrafficEnabled,VMotionEnabled,FaultToleranceLoggingEnabled,VsanTrafficEnabled | format-table # List Port Group
	$QuestionExport = read-host "Would you like to export this report? (Y or N)"
	if ($QuestionExport -eq "Y") {
		$ExportPath = read-host "`nPath to export (Ex: C:\temp)"
		write-host "`nHTML or CSV`n"
		write-host "1 - HTML`n"
		write-host "2 - CSV`n"
		$QuestionExportFormat = read-host "Choose an Option"
		write-host
		if ($QuestionExportFormat -eq 1) {
			$Report = Get-VMHostNetworkAdapter -VMKernel -VirtualSwitch $MyVDS | select VMHost,Name,IP,SubnetMask,Mtu,PortGroupName,ManagementTrafficEnabled,VMotionEnabled,FaultToleranceLoggingEnabled,VsanTrafficEnabled | ConvertTo-HTML -Fragment
			if (-not $Report) {
				$Report = New-Object PSObject -Property @{
				  VMHost = ""
				  Name = ""
				  IP = ""
				  SubnetMask = ""
				  Mtu = ""
				  PortGroupName = ""
				  ManagementTrafficEnabled = ""
				  VMotionEnabled = ""
				  FaultToleranceLoggingEnabled = ""
				  VsanTrafficEnabled = ""
			}
		}
		ConvertTo-HTML -Title "::. Solutions4Crowds .::" -Head "<title>::. Solutions4Crowds .::</title><div id='title' align='center'>vCenter: $vCenter | List VMKernel - $MyVDS</div>$br<div id='subtitle'>Solutions4Crowds.com.br | Generated report: $(Get-Date) </div> $br" -Body "$CSS $BoxContentOpener $Report $PageBoxCloser" | Out-File $ExportPath'\VMKernel-'$MyVDS'-Details.html'
		write-host "Exported to $ExportPath\VMKernel-$MyVDS-Details.html`n"
		}
		if ($QuestionExportFormat -eq 2) {
			Get-VMHostNetworkAdapter -VMKernel -Name $MyVMK -VirtualSwitch $MyVDS | select VMHost,Name,ManagementTrafficEnabled,IP,SubnetMask,PortGroupName | Export-Csv "$ExportPath\VMKernel-$MyVDS-Details.csv"
			write-host "`nExported to $ExportPath\VMKernel-$MyVDS-Details.csv`n"
		}
	}
	else {
		pause;vMenuVMKernel
	}
	pause;vMenuVMKernel
}
Function CreateVMKiSCSI {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create VMKernel iSCSI ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
		write-host
	}
	$GetPGiSCSI = Get-VDPortgroup -VDSwitch $MyVDS | Get-View
	if ($GetPGiSCSI.Name.count -eq 1) {
		write-host "There is no port group on $MyVDS" -foregroundcolor "red"
		write-host "Redirecting to create port group to VDS`n"
		pause;CreatepgiSCSI
	}
	else {
		$ListPGiSCSItotal = 0
		while ($GetPGiSCSI.Name.count -ne $ListPGiSCSItotal) {
			write-host "$ListPGiSCSItotal -"$GetPGiSCSI.Name[$ListPGiSCSItotal]
			$ListPGiSCSItotal++;
		}
		[array]$MyPGiSCSI = (Read-Host "`nPort Group iSCSI Number (separate with comma)").split(",") | %{$_.trim()}
		$MyPGiSCSI = $GetPGiSCSI.Name[$MyPGiSCSI]
		write-host
	}
	$NumPGiSCSI = [array]$MyPGiSCSI.count
	$NumPGiSCSITotal = 0
	while($NumPGiSCSI -ne $NumPGiSCSITotal) {
		[array]$MyIPiSCSIHosts = (Read-Host "iSCSI IP -"$MyPGiSCSI[$NumPGiSCSITotal]"(write $NumHost IP separate with comma)").split(",") | %{$_.trim()} # IP VMKernel
		$MyMaskiSCSI = read-host "`niSCSi Mask (Ex: 255.255.255.0)"
		$MyMTUiSCSI = read-host "`nMTU (Ex: Default = 1500 | Jumbo Frames = 9000)"
		write-host
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS -PortGroup $MyPGiSCSI[$NumPGiSCSITotal] -IP $MyIPiSCSIHosts[$NumHostTotal] -SubnetMask $MyMaskiSCSI -MTU $MyMTUiSCSI | Out-Null # Create VMkenel iSCSI
			write-host $MyHosts[$NumHostTotal]"VMKernel for Port Group"$MyPGiSCSI[$NumPGiSCSITotal]"-"$MyIPiSCSIHosts[$NumHostTotal]"OK!`n" -foregroundcolor "green"
			$NumHostTotal++;
		}
		$NumPGiSCSITotal++;
	}
	write-host "Hosts OK!`n" -foregroundcolor "green"
	pause;vMenuVMKernel	
}
Function ConfigureiSCSI {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Configure iSCSI ($vCenter)`n`n=======================================================`n"
	$MyiSCSItarget = read-host "IP iSCSI Server Send Target"
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	write-host "`n======================================================="
	write-host "VMKernel (Select VMK for iSCSI Traffic)"
	write-host "======================================================="
	$NumHostTotal = 0
	while($NumHost -ne $NumHostTotal) {
		$TheHost = $MyHosts[$NumHostTotal]
		$GetVDSvmk = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -VMKernel | where {$_.ManagementTrafficEnabled -ne "True" -and $_.VMotionEnabled -ne "True" -and $_.FaultToleranceLoggingEnabled -ne "True" -and $_.VsanTrafficEnabled -ne "True"} # Get VMK on Hosts ESXi
		write-host $TheHost $GetVDSvmk.Name"`n"
		$NumHostTotal++;
	}
	$MyFirstVMKiSCSI = read-host "`nFirst VMK iSCSI (Ex: vmk2)`n"
	$MySecondVMKiSCSI = read-host "Second VMK iSCSI (Ex: vmk3)`n"
	$NumHostTotal = 0
	while($NumHost -ne $NumHostTotal) {
		write-host "Configuring"$MyHosts[$NumHostTotal]
		Get-VMHoststorage $MyHosts[$NumHostTotal] | set-vmhoststorage -softwareiscsienabled $True | Out-Null # Add iSCSI Software Adapter
		write-host "iSCSI Software Adapter OK!" -foregroundcolor "green"
		$esxcli = Get-EsxCli -VMhost $MyHosts[$NumHostTotal]
		$HBAiSCSI = Get-VMHostHba -VMHost $MyHosts[$NumHostTotal] -Type iSCSI | %{$_.Device} # Add VMKernel port binding iSCSI
		$esxcli.iscsi.networkportal.add($HBAiSCSI, $Null, $MyFirstVMKiSCSI)
		$esxcli.iscsi.networkportal.add($HBAiSCSI, $Null, $MySecondVMKiSCSI)
		write-host "VMKernel Port Binding ($MyFirstVMKiSCSI and $MySecondVMKiSCSI) OK!" -foregroundcolor "green"
		Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostHba -Type iScsi | New-IScsiHbaTarget -Address $MyiSCSItarget | Out-Null # Add Send Target Portal
		write-host "Send Target Portal ($MyiSCSItarget) OK!" -foregroundcolor "green"
		Get-VMHoststorage $MyHosts[$NumHostTotal] -rescanallhba -rescanvmfs | Out-Null # Rescan all hba and vmfs
		write-host "Rescan all HBA and VMFS OK!`n" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause
	vMenuiSCSI
}
Function MigrateVSStoVDS {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Migrate VSS to VDS ($vCenter)`n`n=======================================================`n"
	$GetVDS = Get-VDSwitch | Get-View
	if ($GetVDS.Name.count -eq 0) {
		write-host "There is no VDS" -foregroundcolor "red"
		write-host "Redirecting to create VDS`n"
		pause;CreateVDS
	}
	if ($GetVDS.Name.count -eq 1) {
		write-host "VDS Name:"$GetVDS.Name"`n"
		$MyVDS = $GetVDS.Name
	}
	else {
		$ListVDStotal = 0
		while ($GetVDS.Name.count -ne $ListVDStotal) {
			write-host "$ListVDStotal -"$GetVDS.Name[$ListVDStotal]
			$ListVDStotal++;
		}
		$MyVDS = read-host "`nVDS Number"
		$MyVDS = $GetVDS.Name[$MyVDS]
	}
	if ($MyHosts -eq 0) {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	$GetPG = Get-VDPortgroup -VDSwitch $MyVDS | Get-View
	if ($GetPG.Name.count -eq 1) {
		write-host "Doesnt have Port Groups on $MyVDS" -foregroundcolor "red"
		write-host "Redirecting to create Port Group to VDS`n"
		pause
		Createpg
	}
	else {
		$ListPGtotal = 0
		while ($GetPG.Name.count -ne $ListPGtotal) {
			write-host "$ListPGtotal -"$GetPG.Name[$ListPGtotal]
			$ListPGtotal++;
		}
		$MyPGMGMT = read-host "`nManagement Port Group Number"
		$MyPGMGMT = $GetPG.Name[$MyPGMGMT]
	}
	write-host
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to migrate these ESXi hosts to $MyVDS - $MyPGMGMT ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	$QuestionVMNIC = read-host "`nWould you like to see the VMNIC on $MyVDS ? (Y or N)"
	if ($QuestionVMNIC -eq "Y") {
		write-host "`n======================================================="
		write-host "VMNICs on $MyVDS"
		write-host "======================================================="
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			$TheHost = $MyHosts[$NumHostTotal]
			$GetVDSnic = Get-VMHostNetworkAdapter -Physical -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS | Select * # Get VMNIC on Hosts ESXi
			write-host $TheHost $GetVDSnic.Name"`n"
			$NumHostTotal++;
		}
	write-host "=======================================================`n"
	}
	$MyFirstNicHost = read-host "VMNIC existing on $MyVDS"
	$QuestionVMK = read-host "`nWould you like to see the VMKernel on ESXi hosts? (Y or N)"
	$MyDefaultVSS = read-host "`nVSS Name - Management Port Group - (Ex: vSwitch0)"
	if ($QuestionVMK -eq "Y") {
		write-host "`n======================================================="
		write-host "Management Traffic VMKernel on $MyDefaultVSS"
		write-host "======================================================="
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			$GetVDSvmk = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -VMKernel -VirtualSwitch $MyDefaultVSS | where {$_.ManagementTrafficEnabled -eq "True"} # Get VMK on Hosts ESXi
			write-host $GetVDSvmk.VMHost $GetVDSvmk.Name $GetVDSvmk.IP $GetVDSvmk.Mac"`n"
			$NumHostTotal++;
		}
	write-host "=======================================================`n"
	}
	$MyVMKmgmt = read-host "Management Traffic VMK (Ex: vmk0)"
	$NumHostTotal = 0
	write-host
	while($NumHost -ne $NumHostTotal) {
		$PhysicalNic = Get-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -Physical -Name $MyFirstNicHost # Migrate Management (vSS to vDS)
		$VirtualNic = Get-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VMKernel -Name $MyVMKmgmt
		Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $MyVDS -VMHostPhysicalNic $PhysicalNic -VMHostVirtualNic $VirtualNic -VirtualNicPortGroup $MyPGMGMT -Confirm:$false | Out-Null
		write-host $MyHosts[$NumHostTotal]"migrate Management Network to $MyVDS OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	$RemoveVSS = read-host "`nDo you want to remove VSS? (Y or N)"
	write-host
	if ($RemoveVSS -eq "Y") {
		Remove-VirtualSwitch -VirtualSwitch $MyDefaultVSS -Confirm:$false # Remove VSS
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause
	vMenuVDS
}
Function ConfigureNTP { # 6 - ESXI
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Configure NTP ($vCenter)`n`n=======================================================`n"
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
			write-host
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	$MyNTP = read-host "`nNTP Server"
	write-host
	$NumHostTotal = 0
	while($NumHost -ne $NumHostTotal) {
		Get-VMHost $MyHosts[$NumHostTotal] | Add-VMHostNtpServer -NtpServer $MyNTP | Out-Null # Configure and Start NTP Service
		Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService | Out-Null
		Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on" | Out-Null
		write-host $MyHosts[$NumHostTotal]"configure and Start NTP Server OK!" -foregroundcolor "green"
		$NumHostTotal++;
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause
	vMenuHosts
}
Function ConfigureSSH {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Enable SSH ($vCenter)`n`n=======================================================`n"
	if ($NumHost -ne 0) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) {
			write-host $MyHosts[$NumHostTotal]
			$NumHostTotal++;
		}
		$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
		if ($QuestionESXi -eq "n") {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
		}
	}
	else {
		[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
		$NumHost = $MyHosts.count
	}
	write-host "`n1 - Start SSH`n" -foregroundcolor "green"
	write-host "2 - Stop SSH`n" -foregroundcolor "red"
	$QuestionSSH = read-host "Choose an Option"
	write-host
	if ($QuestionSSH -eq 1) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) { # Start NTP Service
			Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "TSM-SSH"} | Start-VMHostService | Out-Null
			Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "TSM-SSH"} | Set-VMHostService -policy "on" | Out-Null
			write-host $MyHosts[$NumHostTotal]"start SSH OK!`n" -foregroundcolor "green"
			$NumHostTotal++;
		}
		write-host "SSH enabled!"
	}
	if ($QuestionSSH -eq 2) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) { # Stop NTP Service
			Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false | Out-Null
			Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "TSM-SSH"} | Set-VMHostService -policy "off" | Out-Null
			write-host $MyHosts[$NumHostTotal]"stop SSH OK!`n" -foregroundcolor "green"
			$NumHostTotal++;
		}
		write-host "SSH disabled!"
	}
	write-host "`nHosts OK!`n" -foregroundcolor "green"
	pause
	vMenuHosts
}
Function ConfigureMaintenance {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Maintenance Mode ($vCenter)`n`n=======================================================`n"
	write-host "ALL ESXi HOSTS"
	write-host "=========================="
	write-host "1 - Enter Maintenance Mode`n" -foregroundcolor "green"
	write-host "2 - Exit Maintenance Mode`n`n" -foregroundcolor "red"
	write-host "ONE ESXi HOST"
	write-host "=========================="
	write-host "3 - Enter Maintenance Mode`n" -foregroundcolor "green"
	write-host "4 - Exit Maintenance Mode`n" -foregroundcolor "red"
	$QuestionMaintenance = read-host "Choose an Option"
	write-host
	if ($QuestionMaintenance -eq "1" -Or $QuestionMaintenance -eq "2") {
		if ($NumHost -ne 0) {
			$NumHostTotal = 0
			while($NumHost -ne $NumHostTotal) {
				write-host $MyHosts[$NumHostTotal]
				$NumHostTotal++;
			}
			$QuestionESXi = read-host "`nWould you like to use these ESXi hosts to $MyVDS ? (Y or N)"
			if ($QuestionESXi -eq "n") {
				[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
				$NumHost = $MyHosts.count
				write-host
			}
		}
		else {
			[array]$MyHosts = (Read-Host "`nESXi Hosts - FQDN or IP (separate with comma)").split(",") | %{$_.trim()}
			$NumHost = $MyHosts.count
			write-host
		}
	if ($QuestionMaintenance -eq 1) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) { # Enter Maintenance Mode
			Set-VMHost -VMHost $MyHosts[$NumHostTotal] -State "Maintenance" -RunAsync | Out-Null
			write-host $MyHosts[$NumHostTotal]"OK!`n" -foregroundcolor "green"
			$NumHostTotal++;
		}
	write-host "`nMaintenance Mode OK"
	}
	if ($QuestionMaintenance -eq 2) {
		$NumHostTotal = 0
		while($NumHost -ne $NumHostTotal) { # Exit Maintenance Mode
			Set-VMHost -VMHost $MyHosts[$NumHostTotal] -State "Connected" -RunAsync | Out-Null
			write-host $MyHosts[$NumHostTotal]"OK!`n" -foregroundcolor "green"
			$NumHostTotal++;
		}
	write-host "`nNormal Mode OK"
	}
	}
	else {
	if ($QuestionMaintenance -eq 3) { # Enter Maintenance Mode
		$MyESXiHost = read-host "ESXi Host (FQDN or IP)"
		Set-VMHost -VMHost $MyESXiHost -State "Maintenance" -RunAsync | Out-Null
		write-host "$MyESXiHost OK!`n" -foregroundcolor "green"
		write-host "Maintenance Mode OK`n"
	}
	if ($QuestionMaintenance -eq 4) { # Exit Maintenance Mode
		$MyESXiHost = read-host "ESXi Host (FQDN or IP)"
		Set-VMHost -VMHost $MyESXiHost -State "Connected" -RunAsync | Out-Null
		write-host "$MyESXiHost OK!`n" -foregroundcolor "green"
		write-host "Normal Mode OK`n"
	}
	}
	pause
	vMenuHosts
}
Function CreateVMLC { # 7 - VIRTUAL MACHINE
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Linked Clone Virtual Machine ($vCenter)`n`n=======================================================`n"
	write-host "Ensure that there is a snapshot and that the source VM is off`n"
	$SourceVMName = read-Host "Source Virtual Machine Name"
	$Snap = Get-Snapshot -VM $SourceVMName | Select Name
	$SourceVMSnapshotName = read-Host "Source Virtual Machine Snapshot Name ($Snap)"
	$NewVMName = read-Host "`nNew Virtual Machine Name"
	$ESXiName = read-Host "`nESXi hostname (FQDN)"
	$DatastoreName = read-Host "`nDatastore Name"
	$QuestionLocation = read-Host "`nWould you like to define Resouce Pool and Folder? (Y or N)"
	if ($QuestionLocation -eq "Y") {
		$vCenterFolderName = read-Host "`nLocation - Folder Name"
		$vCenterResourcePoolName = read-Host "`nLocation - Resource Pool Name"
		$QuestionCustom = read-Host "`nWould you like to define Guest Customization? (Y or N)"
		if ($QuestionCustom -eq "Y") {
			$Customization = read-Host "`nGuest Customization Name"
			New-VM -Name $NewVMName -VM $SourceVMName -Location $vCenterFolderName -Datastore $DatastoreName -ResourcePool $vCenterResourcePoolName -VMHost $ESXiName -LinkedClone -ReferenceSnapshot $SourceVMSnapshotName -OSCustomizationSpec $Customization | Out-Null
		}
		else {
			New-VM -Name $NewVMName -VM $SourceVMName -Location $vCenterFolderName -Datastore $DatastoreName -ResourcePool $vCenterResourcePoolName -VMHost $ESXiName -LinkedClone -ReferenceSnapshot $SourceVMSnapshotName | Out-Null
		}
	}
	else {
		$QuestionCustom = read-Host "`nWould you like to define Guest Customization? (Y or N)"
		if ($QuestionCustom -eq "Y") {
			$Customization = read-Host "`nGuest Customization Name"
			New-VM -Name $NewVMName -VM $SourceVMName -Datastore $DatastoreName -VMHost $ESXiName -LinkedClone -ReferenceSnapshot $SourceVMSnapshotName -OSCustomizationSpec $Customization | Out-Null
		}
		else {
			New-VM -Name $NewVMName -VM $SourceVMName -Datastore $DatastoreName -VMHost $ESXiName -LinkedClone -ReferenceSnapshot $SourceVMSnapshotName | Out-Null
		}
	}
	write-host
	Get-VM -Name $NewVMName | Select Name,Version,NumCpu,@{Label="MemoryGB";Expression={"{0:N2} GB" -f ($_.MemoryGB)}},@{Label="ProvisionedSpaceGB";Expression={"{0:N2} GB" -f ($_.ProvisionedSpaceGB)}},Folder,ResourcePool,GuestId,VMHost
	write-host "`nVirtual Machine $NewVMName OK!`n" -foregroundcolor "green"
	pause
	vMenuVM	
}
Function AssignmentTag { # 8 - TAG
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Assignment Tag ($vCenter)`n`n=======================================================`n"
	$GetTag = Get-Tag
	$MyTag = read-host "Tag Name ($GetTag)"
	$NumVM = read-host "`nNumber of Virtual Machines"
	[array]$MyVM = (Read-Host "`nVirtual Machines Name (separate with comma)").split(",") | %{$_.trim()}
	write-host
	$NumVMTotal = 0
	while($NumVM -ne $NumVMTotal) { # Assignment Tag to VM
			Get-VM -Name $MyVM[$NumVMTotal] | New-TagAssignment -Tag $MyTag | Out-Null
			write-host $MyVM[$NumVMTotal]"OK!" -foregroundcolor "green"
			$NumVMTotal++;
		}
	write-host "`nTag $MyTag in Virtual Machines OK!`n" -foregroundcolor "green"
	pause
	vMenuTag
}
Function CreateTag {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Tag ($vCenter)`n`n=======================================================`n"
	$GetTagC = Get-TagCategory
	$QuestionCreate = "y"
	while ($QuestionCreate -eq "y") {
		$MyTag = read-host "Tag Name"
		$MyTagCategoryDesc = read-Host "`nDescription"
		$MyTagCategory = read-host "`nTag Category Name ($GetTagC)"
		New-Tag -Name $MyTag -Description $MyTagDescription -Category $MyTagCategory | Out-Null
		write-host "Tag $MyTag in category $MyTagCategory OK!`n" -foregroundcolor "green"
		$QuestionCreate = read-host "Would you like to create other tag? (Y or N)"
		write-host
	}	
	pause
	vMenuTag
}
Function CreateCategoryTag {
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "Create Category Tag ($vCenter)`n`n=======================================================`n"
	$QuestionCreate = "y"
	while ($QuestionCreate -eq "y") {
		$MyTagCategory = read-host "Tag Category Name"
		$MyTagCategoryDesc = read-Host "`nDescription"
		$QuestionCardinality = read-Host "`nMultiple Cardinality (Y or N)"
		if ($QuestionCardinality -eq "N") {$MyTagCardinality = "single"}
		if ($QuestionCardinality -eq "Y") {$MyTagCardinality = "multiple"}
		#write-host
		#write-host "1 = Cluster | 2 = Datacenter | 3 = Datastore | 4 = DatastoreCluster"
		#write-host "5 = DistributedPortGroup | 6 = DistributedSwitch | 7 = Folder"
		#write-host "8 = ResourcePool | 9 = VApp | 10 = VirtualPortGroup"
		#write-host "11 = VirtualMachine | 12 = VM | 13 = VMHost"
		#write-host
		#$QuestionEntityType = read-host "Number of Associable Entities"
		#if ($QuestionEntityType -eq 1) {$MyTagEntityType = "Cluster"}
		#if ($QuestionEntityType -eq 2) {$MyTagEntityType = "Datacenter"}
		#if ($QuestionEntityType -eq 3) {$MyTagEntityType = "Datastore"}
		#if ($QuestionEntityType -eq 4) {$MyTagEntityType = "DatastoreCluster"}
		#if ($QuestionEntityType -eq 5) {$MyTagEntityType = "DistributedPortGroup"}
		#if ($QuestionEntityType -eq 6) {$MyTagEntityType = "DistributedSwitch"}
		#if ($QuestionEntityType -eq 7) {$MyTagEntityType = "Folder"}
		#if ($QuestionEntityType -eq 8) {$MyTagEntityType = "ResourcePool"}
		#if ($QuestionEntityType -eq 9) {$MyTagEntityType = "VApp"}
		#if ($QuestionEntityType -eq 10) {$MyTagEntityType = "VirtualPortGroup"}
		#if ($QuestionEntityType -eq 11) {$MyTagEntityType = "VirtualMachine"}
		#if ($QuestionEntityType -eq 12) {$MyTagEntityType = "VM"}
		#if ($QuestionEntityType -eq 13) {$MyTagEntityType = "VMHost"}
		$MyTagEntityType = "VirtualMachine"
		write-host
		New-TagCategory -Name $MyTagCategory -Description $MyTagCategoryDesc -Cardinality $MyTagCardinality -EntityType $MyTagEntityType | Out-Null
		write-host "Category $MyTagCategory with cardinality $MyTagCardinality for entity type $MyTagEntityType OK!`n" -foregroundcolor "green"
		$QuestionCreate = read-host "Would you like to create other category? (Y or N)"
		write-host
	}
	write-host
	pause;vMenuTag
	}
Function vMenu { ######### MENUS #########
	if ($TestServer -eq 0) { # PRINCIPAL MENU - BEFORE REGISTER SERVER
		cls
		write-host $S4Ctitle
		write-host $Body
		write-host "PRINCIPAL MENU`n`n=======================================================`n"
		write-host "0 - Configuration`n"
		write-host "1 - Test Servers`n"
		write-host "9 - EXIT`n`n" -foregroundcolor "red"
		$vQuestion = read-host "Choose an Option"
		switch ($vQuestion) {
			0 {MyConfiguration}
			1 {MyTest}
			9 {exit}
			default {
				cls
				write-host "Invalid option, try again!" -foregroundcolor "red"
				pause;vMenu
			}
		}
	} 
	else { # PRINCIPAL MENU
		cls
		write-host $S4Ctitle
		write-host $Body
		write-host "PRINCIPAL MENU`n`n=======================================================`n"
		write-host "0 - Configuration`n"
		write-host "1 - Test Servers`n"
		write-host "2 - vCenter Server`n"
		write-host "3 - Data Center`n"
		write-host "4 - Cluster`n"
		write-host "5 - Network`n"
		write-host "6 - ESXi`n"
		write-host "7 - VM`n"
		write-host "8 - TAG`n"
		write-host "9 - EXIT`n`n" -foregroundcolor "red"
		$vQuestion = read-host "Choose an Option"
		switch ($vQuestion) {
			0 {MyConfiguration}
			1 {MyTest} 
			2 {MyvCenter} 
			3 {vMenuDatacenter}
			4 {vMenuCluster}
			5 {vMenuNetwork}
			6 {vMenuHosts}
			7 {vMenuVM}
			8 {vMenuTag}
			9 {Disconnect-VIServer -Confirm:$false;exit}
			default {
				cls
				write-host "Invalid option, try again!" -foregroundcolor "red"
				pause;vMenu
			}
		}
	}
}
Function vMenuDatacenter { # 3 - DATA CENTER
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU DATA CENTER`n`n=======================================================`n"
	write-host "1 - Create Data Center`n"
	write-host "2 - List ESXi Host (report)`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {CreateDC}
		2 {ListHostsDC}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuDatacenter
		}
	}
}
Function vMenuCluster { # 4 - CLUSTER
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU CLUSTER`n`n=======================================================`n"
	write-host "1 - Create Cluster`n"
	write-host "2 - Add ESXi Host to Cluster`n"
	write-host "3 - List ESXi Host (report)`n"
	write-host "4 - Configure HA`n"
	write-host "5 - Configure DRS`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {CreateCluster}
		2 {AddHostsToCluster}
		3 {ListHostsCluster}
		4 {ConfigureClusterHA} 
		5 {ConfigureClusterDRS}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuCluster
		}
	}
}
Function vMenuNetwork { # 5 - NETWORK
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU NETWORK`n`n=======================================================`n"
	write-host "1 - VDS`n"
	write-host "2 - Port Group`n"
	write-host "3 - VMKernel`n"
	write-host "4 - iSCSI`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {vMenuVDS}
		2 {vMenuPortGroup}
		3 {vMenuVMKernel}
		4 {vMenuiSCSI}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuNetwork
		}
	}
}
Function vMenuVDS { # MENU VDS
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU VDS`n`n=======================================================`n"
	write-host "1 - Create VDS`n"
	write-host "2 - List VDS (report)`n"
	write-host "3 - Add ESXi Host to VDS`n"
	write-host "4 - Add Uplinks to VDS`n"
	write-host "5 - Migrate VSS to VDS`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {CreateVDS}
		2 {ListVDS}
		3 {AddHostsToVDS}
		4 {AddNICtoVDS}
		5 {MigrateVSStoVDS}
		9 {vMenuNetwork}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuVDS
		}
	}
}
Function vMenuPortGroup { # MENU PORT GROUP
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU PORT GROUP`n`n=======================================================`n"
	write-host "1 - Create Port Group`n"
	write-host "2 - List Port Group (report)`n"
	write-host "3 - Create iSCSI Port Group`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {Createpg}
		2 {Listpg}
		3 {CreatepgiSCSI}
		9 {vMenuNetwork}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuPortGroup
		}
	}
}
Function vMenuVMKernel { # MENU VMKERNEL
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU VMKERNEL`n`n=======================================================`n"
	write-host "1 - Create VMKernel`n"
	write-host "2 - List VMKernel (report)`n"
	write-host "3 - Create vMotion VMKernel`n"
	write-host "4 - Create iSCSI VMKernel`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"

	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {CreateVMK}
		2 {ListVMK}
		3 {CreateVMKvMotion}
		4 {CreateVMKiSCSI}
		9 {vMenuNetwork}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuVMKernel
		}
	}
}
Function vMenuiSCSI { # MENU ISCSI
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU iSCSI`n`n=======================================================`n"
	write-host "1 - Configure iSCSI`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {ConfigureiSCSI}
		9 {vMenuNetwork}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuNetwork
		}
	}
}
Function vMenuHosts { # 6 - ESXI
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU ESXi`n`n=======================================================`n"
	write-host "1 - Configure NTP`n"
	write-host "2 - Configure SSH`n"
	write-host "3 - Maintenance Mode`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionHosts = read-host "Choose an Option"
	switch ($vQuestionHosts) {
		1 {ConfigureNTP}
		2 {ConfigureSSH}
		3 {ConfigureMaintenance}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			#Start-Sleep -Seconds 3
			pause;vMenuHosts
		}
	}
}
Function vMenuVM { # 7 - VIRTUAL MACHINE
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU VIRTUAL MACHINE`n`n=======================================================`n"
	write-host "1 - Create Linked Clone VM`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionHosts = read-host "Choose an Option"
	switch ($vQuestionHosts) {
		1 {CreateVMLC}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause;vMenuHosts
		}
	}
}
Function vMenuTag { # 8 - TAG
	cls
	write-host $S4Ctitle
	write-host $Body
	write-host "MENU TAG`n`n=======================================================`n"
	write-host "1 - Create Category`n"
	write-host "2 - Create Tag`n"
	write-host "3 - Assignment Tag in VM`n"
	write-host "9 - BACK`n`n" -foregroundcolor "red"
	$vQuestionPortGroup = read-host "Choose an Option"
	switch ($vQuestionPortGroup) {
		1 {CreateCategoryTag}
		2 {CreateTag}
		3 {AssignmentTag}
		9 {vMenu}
		default {
			cls
			write-host "Invalid option, try again!" -foregroundcolor "red"
			pause
			vMenuTag
		}
	}
}
vMenu