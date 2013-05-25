#
# Creates a VM image suitable for running
# under Parallels.
#
# General File Structure:
#
# FreeBSD-i386.pvm/
#  +- config.pvs
#  +- Disk-0.hdd/
#      +- DiskDescriptor.xml
#      +- Disk-0.hdd
#
# More documentation:
# http://www.parallels.com/fileadmin/parallels/documents/support/pdfm/Parallels_Desktop_Advanced_VM_Configuration.pdf

#
# BROKEN
#
# This was copied from the VMWare-guest configuration and
# I started to copy-and-paste information from the above
# docs, but it's not finished.
# 
#echo Parallels-guest option is broken.
#echo if you fix it, please send patches.
#exit 1

strategy_add $PHASE_FREEBSD_OPTION_INSTALL parallels_tweak_install
strategy_add $PHASE_POST_UNMOUNT parallels_guest_build_vm ${IMG}

#
# After the GenericI386 board definition has installed
# world and kernel, we can adjust a few things
# to work better on Parallels.
#
parallels_tweak_install ( ) {
    echo "Applying Parallels system tweaks"
    # Add some stuff to etc/rc.conf
    echo 'ifconfig_em0="DHCP"' >> etc/rc.conf
    
    # TODO: Load Parallels-relevant modules in loader.conf?
}

# After unmounting the final image:
#  * pad it out to a full cylinder
#  * compute the geometry, and generate DiskDescriptor.xml
#  * Build a template config.pvs file
#
# $1 = full path of image
#
parallels_guest_build_vm ( ) {
    echo "Building Parallels VM"
    IMGDIR=`dirname ${IMG}`
    IMGBASE=`basename ${IMG} | sed -e s/\.[^.]*$//`

    VMDIR=${IMGDIR}/${IMGBASE}.pvm
    DISKDIR=${VMDIR}/Disk-0.hdd
    mkdir -p ${DISKDIR}

    # Compute the appropriate MBR geometry for this image
    CYLINDERS=$(( ($IMAGE_SIZE + 512 * 63 * 16 - 1) / 512 / 63 / 16 ))
    SECTORS=$(( $CYLINDERS * 16 * 63 ))

    # If the image isn't an exact multiple of the cylinder size, pad it.
    PADDED_SIZE=$(( $CYLINDERS * 512 * 16 * 63 ))
    if [ $PADDED_SIZE -gt $IMAGE_SIZE ]; then
	dd of=${IMG} if=/dev/zero bs=1 count=1 oseek=$(( $PADDED_SIZE - 1))
    fi

    mv ${IMG} ${DISKDIR}

    # Write DiskDescriptor.xml
    DISKUID=`uuidgen`
    SEGMENTUID=`uuidgen`
    cat >${DISKDIR}/DiskDescriptor.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Parallels_disk_image Version="1.0">
    <Disk_Parameters>
        <Disk_size>${SECTORS}</Disk_size>
        <Cylinders>${CYLINDERS}</Cylinders>
        <Heads>16</Heads>
        <Sectors>63</Sectors>
        <Padding>0</Padding>
        <Encryption>
            <Engine>{00000000-0000-0000-0000-000000000000}</Engine>
            <Data></Data>
        </Encryption>
        <UID>{${DISKUID}}</UID>
        <Name>Disk0</Name>
        <Miscellaneous>
            <CompatLevel>level2</CompatLevel>
            <Bootable>1</Bootable>
        </Miscellaneous>
    </Disk_Parameters>
    <StorageData>
        <Storage>
            <Start>0</Start>
            <End>${SECTORS}</End>
            <Blocksize>512</Blocksize>
            <Image>
                <GUID>{${SEGMENTUID}}</GUID>
                <Type>Plain</Type>
                <File>Disk0.hdd.{${SEGMENTUID}}.hds</File>
            </Image>
        </Storage>
    </StorageData>
    <Snapshots>
        <Shot>
            <GUID>{${SEGMENTUID}}</GUID>
            <ParentGUID>{00000000-0000-0000-0000-000000000000}</ParentGUID>
        </Shot>
    </Snapshots>
</Parallels_disk_image>
EOF

    # Write the config.pvs machine description file.
    VMUUID=`uuidgen`
    cat >${VMDIR}/config.pvs <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ParallelsVirtualMachine schemaVersion="1.0" dyn_lists="VirtualAppliance 0">
   <AppVersion>7.0.15107.796624</AppVersion>
   <ValidRc>0</ValidRc>
   <Identification dyn_lists="">
      <VmUuid>{${VMUUID}}</VmUuid>
      <SourceVmUuid>{00000000-0000-0000-0000-000000000000}</SourceVmUuid>
      <LinkedVmUuid></LinkedVmUuid>
      <VmName>FreeBSD-i386-GENERIC</VmName>
      <ServerUuid>{51f7899f-756d-425a-a374-2e97ad5664ba}</ServerUuid>
      <LastServerUuid></LastServerUuid>
      <ServerHost></ServerHost>
      <VmFilesLocation>1</VmFilesLocation>
      <VmCreationDate>2013-05-25 02:59:09</VmCreationDate>
      <VmUptimeStartDateTime>2013-05-25 04:31:46</VmUptimeStartDateTime>
      <VmUptimeInSeconds>52</VmUptimeInSeconds>
   </Identification>
   <Security dyn_lists="">
      <AccessControlList dyn_lists="AccessControl"/>
      <LockedOperationsList dyn_lists="LockedOperation"/>
      <Owner></Owner>
      <IsOwner>0</IsOwner>
      <AccessForOthers>0</AccessForOthers>
      <LockedSign>0</LockedSign>
      <ParentalControlEnabled>1</ParentalControlEnabled>
   </Security>
   <Settings dyn_lists="">
      <General dyn_lists="">
         <OsType>10</OsType>
         <OsNumber>2563</OsNumber>
         <VmDescription></VmDescription>
         <IsTemplate>0</IsTemplate>
         <CustomProperty></CustomProperty>
         <SwapDir></SwapDir>
         <VmColor>0</VmColor>
      </General>
      <Startup dyn_lists="">
         <AutoStart>0</AutoStart>
         <AutoStartDelay>0</AutoStartDelay>
         <VmStartLoginMode>0</VmStartLoginMode>
         <VmStartAsUser></VmStartAsUser>
         <VmStartAsPassword></VmStartAsPassword>
         <WindowMode>0</WindowMode>
         <LockInFullScreenMode>0</LockInFullScreenMode>
         <StartInDetachedWindow>0</StartInDetachedWindow>
         <BootingOrder dyn_lists="BootDevice 12">
            <BootDevice id="10" dyn_lists="">
               <Index>0</Index>
               <Type>6</Type>
               <BootingNumber>0</BootingNumber>
               <InUse>1</InUse>
            </BootDevice>
            <BootDevice id="11" dyn_lists="">
               <Index>0</Index>
               <Type>8</Type>
               <BootingNumber>1</BootingNumber>
               <InUse>0</InUse>
            </BootDevice>
         </BootingOrder>
         <AllowSelectBootDevice>0</AllowSelectBootDevice>
      </Startup>
      <Shutdown dyn_lists="">
         <AutoStop>1</AutoStop>
         <OnVmWindowClose>2</OnVmWindowClose>
         <WindowOnShutdown>0</WindowOnShutdown>
      </Shutdown>
      <ClusterOptions dyn_lists="">
         <Running>0</Running>
         <ServiceName></ServiceName>
      </ClusterOptions>
      <Runtime OptimizePowerConsumptionMode_patch="1" dyn_lists="IoLimit 0">
         <ForegroundPriority>1</ForegroundPriority>
         <BackgroundPriority>1</BackgroundPriority>
         <IoPriority>4</IoPriority>
         <DiskCachePolicy>1</DiskCachePolicy>
         <CloseAppOnShutdown>0</CloseAppOnShutdown>
         <ActionOnStop>0</ActionOnStop>
         <DockIcon>0</DockIcon>
         <OsResolutionInFullScreen>0</OsResolutionInFullScreen>
         <FullScreen CornerAction_patch="2" dyn_lists="CornerAction">
            <UseAllDisplays>0</UseAllDisplays>
            <UseActiveCorners>1</UseActiveCorners>
            <UseNativeFullScreen>0</UseNativeFullScreen>
            <CornerAction>1</CornerAction>
            <CornerAction>0</CornerAction>
            <CornerAction>0</CornerAction>
            <CornerAction>0</CornerAction>
            <ScaleViewMode>1</ScaleViewMode>
         </FullScreen>
         <UndoDisks>0</UndoDisks>
         <SafeMode>0</SafeMode>
         <SystemFlags></SystemFlags>
         <DisableAPIC>0</DisableAPIC>
         <OptimizePowerConsumptionMode>1</OptimizePowerConsumptionMode>
         <ShowBatteryStatus>1</ShowBatteryStatus>
         <Enabled>0</Enabled>
         <EnableAdaptiveHypervisor>0</EnableAdaptiveHypervisor>
         <UseSMBiosData>0</UseSMBiosData>
         <DisableSpeaker>1</DisableSpeaker>
         <HideBiosOnStartEnabled>0</HideBiosOnStartEnabled>
         <UseDefaultAnswers>0</UseDefaultAnswers>
         <CompactHddMask>0</CompactHddMask>
         <CompactMode>0</CompactMode>
         <DisableWin7Logo>1</DisableWin7Logo>
         <OptimizeModifiers>0</OptimizeModifiers>
         <PauseOnDeactivation>0</PauseOnDeactivation>
         <CR4_MASK>0</CR4_MASK>
         <FEATURES_MASK>0</FEATURES_MASK>
         <EXT_FEATURES_MASK>0</EXT_FEATURES_MASK>
         <EXT_80000001_ECX_MASK>0</EXT_80000001_ECX_MASK>
         <EXT_80000001_EDX_MASK>0</EXT_80000001_EDX_MASK>
         <EXT_80000007_EDX_MASK>0</EXT_80000007_EDX_MASK>
         <EXT_80000008_EAX>0</EXT_80000008_EAX>
         <CpuFeaturesMaskValid>0</CpuFeaturesMaskValid>
         <UnattendedInstallLocale></UnattendedInstallLocale>
      </Runtime>
      <Schedule dyn_lists="">
         <SchedBasis>0</SchedBasis>
         <SchedGranularity>0</SchedGranularity>
         <SchedDayOfWeek>0</SchedDayOfWeek>
         <SchedDayOfMonth>0</SchedDayOfMonth>
         <SchedDay>0</SchedDay>
         <SchedWeek>0</SchedWeek>
         <SchedMonth>0</SchedMonth>
         <SchedStartDate>1752-01-01</SchedStartDate>
         <SchedStartTime>00:00:00</SchedStartTime>
         <SchedStopDate>1752-01-01</SchedStopDate>
         <SchedStopTime>00:00:00</SchedStopTime>
      </Schedule>
      <RemoteDisplay dyn_lists="">
         <Mode>0</Mode>
         <Password></Password>
         <HostName>0.0.0.0</HostName>
         <PortNumber>6500</PortNumber>
      </RemoteDisplay>
      <Tools dyn_lists="">
         <IsolatedVm>0</IsolatedVm>
         <Coherence GroupAllWindows_patch="1" RelocateTaskBar_patch="1" ExcludeDock_patch="1" ShowTaskBar_patch="" DoNotMinimizeToDock_patch="1" AlwaysOnTop_patch="1" BringToFront_patch="1" dyn_lists="">
            <ShowTaskBar>1</ShowTaskBar>
            <ShowTaskBarInCoherence>0</ShowTaskBarInCoherence>
            <RelocateTaskBar>0</RelocateTaskBar>
            <ExcludeDock>1</ExcludeDock>
            <MultiDisplay>1</MultiDisplay>
            <GroupAllWindows>0</GroupAllWindows>
            <DisableDropShadow>0</DisableDropShadow>
            <DoNotMinimizeToDock>0</DoNotMinimizeToDock>
            <BringToFront>0</BringToFront>
            <AppInDock>0</AppInDock>
            <ShowWinSystrayInMacMenu>1</ShowWinSystrayInMacMenu>
            <UseBorders>0</UseBorders>
            <UseSeamlessMode>0</UseSeamlessMode>
            <SwitchToFullscreenOnDemand>1</SwitchToFullscreenOnDemand>
            <PauseIdleVM>0</PauseIdleVM>
            <DisableAero>0</DisableAero>
            <CoherenceButtonVisibility>1</CoherenceButtonVisibility>
            <AlwaysOnTop>0</AlwaysOnTop>
            <WindowAnimation>1</WindowAnimation>
         </Coherence>
         <SharedFolders dyn_lists="">
            <HostSharing dyn_lists="SharedFolder 0">
               <Enabled>1</Enabled>
               <ShareAllMacDisks>0</ShareAllMacDisks>
               <ShareUserHomeDir>1</ShareUserHomeDir>
               <MapSharedFoldersOnLetters>1</MapSharedFoldersOnLetters>
               <UserDefinedFoldersEnabled>1</UserDefinedFoldersEnabled>
               <SetExecBitForFiles>0</SetExecBitForFiles>
               <VirtualLinks>1</VirtualLinks>
               <EnableDos8dot3Names>1</EnableDos8dot3Names>
            </HostSharing>
            <GuestSharing dyn_lists="">
               <Enabled>1</Enabled>
               <AutoMount>1</AutoMount>
               <AutoMountNetworkDrives>0</AutoMountNetworkDrives>
               <EnableSpotlight>0</EnableSpotlight>
            </GuestSharing>
         </SharedFolders>
         <SharedProfile dyn_lists="">
            <Enabled>0</Enabled>
            <UseDesktop>0</UseDesktop>
            <UseDocuments>0</UseDocuments>
            <UsePictures>0</UsePictures>
            <UseMusic>0</UseMusic>
            <UseMovies>1</UseMovies>
            <UseDownloads>1</UseDownloads>
            <UseTrashBin>1</UseTrashBin>
         </SharedProfile>
         <SharedApplications dyn_lists="">
            <FromWinToMac>1</FromWinToMac>
            <FromMacToWin>1</FromMacToWin>
            <SmartSelect>1</SmartSelect>
            <AppInDock>2</AppInDock>
            <ShowWindowsAppInDock>1</ShowWindowsAppInDock>
            <WebApplications dyn_lists="">
               <WebBrowser>0</WebBrowser>
               <EmailClient>0</EmailClient>
               <FtpClient>0</FtpClient>
               <Newsgroups>0</Newsgroups>
               <Rss>0</Rss>
               <RemoteAccess>0</RemoteAccess>
            </WebApplications>
            <IconGroupingEnabled>1</IconGroupingEnabled>
         </SharedApplications>
         <AutoUpdate dyn_lists="">
            <Enabled>1</Enabled>
         </AutoUpdate>
         <ClipboardSync Enabled_patch="1" dyn_lists="">
            <Enabled>1</Enabled>
            <PreserveTextFormatting>1</PreserveTextFormatting>
         </ClipboardSync>
         <DragAndDrop Enabled_patch="1" dyn_lists="">
            <Enabled>1</Enabled>
         </DragAndDrop>
         <MouseSync dyn_lists="">
            <Enabled>1</Enabled>
         </MouseSync>
         <MouseVtdSync dyn_lists="">
            <Enabled>1</Enabled>
         </MouseVtdSync>
         <SmartMouse dyn_lists="">
            <Enabled>1</Enabled>
         </SmartMouse>
         <TimeSync dyn_lists="">
            <Enabled>1</Enabled>
            <SyncInterval>60</SyncInterval>
            <KeepTimeDiff>0</KeepTimeDiff>
            <SyncHostToGuest>0</SyncHostToGuest>
         </TimeSync>
         <TisDatabase dyn_lists="">
            <Data></Data>
         </TisDatabase>
         <Modality dyn_lists="">
            <Opacity>0.8</Opacity>
            <StayOnTop>1</StayOnTop>
            <CaptureMouseClicks>1</CaptureMouseClicks>
         </Modality>
         <SharedVolumes dyn_lists="">
            <Enabled>1</Enabled>
            <UseExternalDisks>1</UseExternalDisks>
            <UseDVDs>1</UseDVDs>
            <UseConnectedServers>1</UseConnectedServers>
            <UseInversedDisks>0</UseInversedDisks>
         </SharedVolumes>
         <Gestures Enabled_patch="1" dyn_lists="">
            <Enabled>1</Enabled>
         </Gestures>
         <RemoteControl dyn_lists="">
            <Enabled>1</Enabled>
         </RemoteControl>
         <NativeLook dyn_lists="">
            <Enabled>0</Enabled>
         </NativeLook>
         <AutoSyncOSType dyn_lists="">
            <Enabled>1</Enabled>
         </AutoSyncOSType>
      </Tools>
      <Autoprotect dyn_lists="">
         <Enabled>0</Enabled>
         <Period>86400</Period>
         <TotalSnapshots>10</TotalSnapshots>
         <Schema>2</Schema>
         <NotifyBeforeCreation>1</NotifyBeforeCreation>
      </Autoprotect>
      <AutoCompress dyn_lists="">
         <Enabled>0</Enabled>
         <Period>86400</Period>
         <FreeDiskSpaceRatio>50</FreeDiskSpaceRatio>
      </AutoCompress>
      <GlobalNetwork dyn_lists="DnsIPAddress SearchDomain OfflineService">
         <HostName></HostName>
         <DefaultGateway></DefaultGateway>
         <DefaultGatewayIPv6></DefaultGatewayIPv6>
         <OfflineManagementEnabled>0</OfflineManagementEnabled>
         <NetworkRates dyn_lists="NetworkRate 0">
            <RateBound>0</RateBound>
         </NetworkRates>
      </GlobalNetwork>
      <VmEncryptionInfo dyn_lists="">
         <Enabled>0</Enabled>
         <PluginId></PluginId>
         <Hash1></Hash1>
         <Hash2></Hash2>
      </VmEncryptionInfo>
      <SharedCamera Enabled_patch="1" dyn_lists="">
         <Enabled>1</Enabled>
      </SharedCamera>
      <VirtualPrintersInfo UseHostPrinters_patch="1" dyn_lists="">
         <UseHostPrinters>0</UseHostPrinters>
         <SyncDefaultPrinter>0</SyncDefaultPrinter>
      </VirtualPrintersInfo>
      <SharedBluetooth Enabled_patch="" dyn_lists="">
         <Enabled>0</Enabled>
      </SharedBluetooth>
      <LockDown dyn_lists="">
         <Hash></Hash>
      </LockDown>
   </Settings>
   <Hardware dyn_lists="Fdd 0 CdRom 1 Hdd 1 Serial 0 Parallel 0 Printer 1 NetworkAdapter 1 Sound 0 USB 0 PciVideoAdapter 0 GenericDevice 0 GenericPciDevice 0 GenericScsiDevice 0">
      <Cpu dyn_lists="">
         <Number>1</Number>
         <Mode>0</Mode>
         <AccelerationLevel>2</AccelerationLevel>
         <EnableVTxSupport>1</EnableVTxSupport>
         <EnableHotplug>0</EnableHotplug>
         <CpuUnits>0</CpuUnits>
         <CpuLimit>0</CpuLimit>
         <CpuLimitType>2</CpuLimitType>
         <CpuLimitValue>0</CpuLimitValue>
         <CpuMask></CpuMask>
      </Cpu>
      <Chipset dyn_lists="">
         <Type>1</Type>
      </Chipset>
      <Clock dyn_lists="">
         <TimeShift>0</TimeShift>
      </Clock>
      <Memory dyn_lists="">
         <RAM>512</RAM>
         <EnableHotplug>0</EnableHotplug>
         <HostMemQuotaMin>128</HostMemQuotaMin>
         <HostMemQuotaMax>4294967295</HostMemQuotaMax>
         <HostMemQuotaPriority>50</HostMemQuotaPriority>
         <AutoQuota>1</AutoQuota>
         <MaxBalloonSize>60</MaxBalloonSize>
      </Memory>
      <Video dyn_lists="">
         <Enabled>1</Enabled>
         <VideoMemorySize>2</VideoMemorySize>
         <EnableDirectXShaders>1</EnableDirectXShaders>
         <ScreenResolutions dyn_lists="ScreenResolution 0">
            <Enabled>0</Enabled>
         </ScreenResolutions>
         <Enable3DAcceleration>0</Enable3DAcceleration>
         <EnableVSync>0</EnableVSync>
         <MaxDisplays>0</MaxDisplays>
      </Video>
      <Hdd id="0" dyn_lists="Partition 0">
         <Index>0</Index>
         <Enabled>1</Enabled>
         <Connected>1</Connected>
         <EmulatedType>1</EmulatedType>
         <SystemName>Disk0.hdd</SystemName>
         <UserFriendlyName>Disk0.hdd</UserFriendlyName>
         <Remote>0</Remote>
         <InterfaceType>0</InterfaceType>
         <StackIndex>0</StackIndex>
         <DiskType>0</DiskType>
         <Size>954</Size>
         <SizeOnDisk>954</SizeOnDisk>
         <Passthrough>0</Passthrough>
         <Splitted>0</Splitted>
         <DiskVersion>2</DiskVersion>
         <CompatLevel>level2</CompatLevel>
         <DeviceDescription></DeviceDescription>
      </Hdd>
      <NetworkAdapter AdapterType_patch="1" id="0" dyn_lists="NetAddress DnsIPAddress SearchDomain">
         <Index>0</Index>
         <Enabled>1</Enabled>
         <Connected>1</Connected>
         <EmulatedType>1</EmulatedType>
         <SystemName></SystemName>
         <UserFriendlyName></UserFriendlyName>
         <Remote>0</Remote>
         <AdapterNumber>-1</AdapterNumber>
         <AdapterName></AdapterName>
         <MAC>001C423FA172</MAC>
         <HostMAC></HostMAC>
         <Router>0</Router>
         <DHCPUseHostMac>0</DHCPUseHostMac>
         <ForceHostMacAddress>0</ForceHostMacAddress>
         <VirtualNetworkID></VirtualNetworkID>
         <AdapterType>0</AdapterType>
         <StaticAddress>0</StaticAddress>
         <PktFilter dyn_lists="">
            <PreventPromisc>1</PreventPromisc>
            <PreventMacSpoof>1</PreventMacSpoof>
            <PreventIpSpoof>1</PreventIpSpoof>
         </PktFilter>
         <AutoApply>0</AutoApply>
         <ConfigureWithDhcp>0</ConfigureWithDhcp>
         <DefaultGateway></DefaultGateway>
         <ConfigureWithDhcpIPv6>0</ConfigureWithDhcpIPv6>
         <DefaultGatewayIPv6></DefaultGatewayIPv6>
         <Firewall dyn_lists="">
            <Enabled>0</Enabled>
            <DefaultPolicy>0</DefaultPolicy>
            <FirewallRules dyn_lists="FirewallRule 0"/>
         </Firewall>
         <DeviceDescription></DeviceDescription>
      </NetworkAdapter>
   </Hardware>
   <InstalledSoftware>0</InstalledSoftware>
</ParallelsVirtualMachine>
EOF

}
