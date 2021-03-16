<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="17008000">
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="1_SimpleDemo_MHHisto.vi" Type="VI" URL="../1_SimpleDemo_MHHisto.vi"/>
		<Item Name="2_AdvancedDemo_MHHisto.vi" Type="VI" URL="../2_AdvancedDemo_MHHisto.vi"/>
		<Item Name="3_AdvancedDemo_MHT3.vi" Type="VI" URL="../3_AdvancedDemo_MHT3.vi"/>
		<Item Name="Dependencies" Type="Dependencies">
			<Property Name="NI.SortType" Type="Int">1</Property>
			<Item Name="vi.lib" Type="Folder">
				<Item Name="Application Directory.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/file.llb/Application Directory.vi"/>
				<Item Name="BuildHelpPath.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/BuildHelpPath.vi"/>
				<Item Name="Check if File or Folder Exists.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/libraryn.llb/Check if File or Folder Exists.vi"/>
				<Item Name="Check Special Tags.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Check Special Tags.vi"/>
				<Item Name="Clear Errors.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Clear Errors.vi"/>
				<Item Name="Convert property node font to graphics font.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Convert property node font to graphics font.vi"/>
				<Item Name="Details Display Dialog.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Details Display Dialog.vi"/>
				<Item Name="DialogType.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/DialogType.ctl"/>
				<Item Name="DialogTypeEnum.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/DialogTypeEnum.ctl"/>
				<Item Name="Error Cluster From Error Code.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Cluster From Error Code.vi"/>
				<Item Name="Error Code Database.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Error Code Database.vi"/>
				<Item Name="ErrWarn.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/ErrWarn.ctl"/>
				<Item Name="eventvkey.ctl" Type="VI" URL="/&lt;vilib&gt;/event_ctls.llb/eventvkey.ctl"/>
				<Item Name="ex_CorrectErrorChain.vi" Type="VI" URL="/&lt;vilib&gt;/express/express shared/ex_CorrectErrorChain.vi"/>
				<Item Name="Find Tag.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Find Tag.vi"/>
				<Item Name="Format Message String.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Format Message String.vi"/>
				<Item Name="General Error Handler Core CORE.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/General Error Handler Core CORE.vi"/>
				<Item Name="General Error Handler.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/General Error Handler.vi"/>
				<Item Name="Get String Text Bounds.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Get String Text Bounds.vi"/>
				<Item Name="Get System Directory.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/sysdir.llb/Get System Directory.vi"/>
				<Item Name="Get Text Rect.vi" Type="VI" URL="/&lt;vilib&gt;/picture/picture.llb/Get Text Rect.vi"/>
				<Item Name="GetHelpDir.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/GetHelpDir.vi"/>
				<Item Name="GetRTHostConnectedProp.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/GetRTHostConnectedProp.vi"/>
				<Item Name="Longest Line Length in Pixels.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Longest Line Length in Pixels.vi"/>
				<Item Name="LVBoundsTypeDef.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/miscctls.llb/LVBoundsTypeDef.ctl"/>
				<Item Name="LVRectTypeDef.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/miscctls.llb/LVRectTypeDef.ctl"/>
				<Item Name="NI_FileType.lvlib" Type="Library" URL="/&lt;vilib&gt;/Utility/lvfile.llb/NI_FileType.lvlib"/>
				<Item Name="NI_PackedLibraryUtility.lvlib" Type="Library" URL="/&lt;vilib&gt;/Utility/LVLibp/NI_PackedLibraryUtility.lvlib"/>
				<Item Name="Not Found Dialog.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Not Found Dialog.vi"/>
				<Item Name="Search and Replace Pattern.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Search and Replace Pattern.vi"/>
				<Item Name="Set Bold Text.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Set Bold Text.vi"/>
				<Item Name="Set String Value.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Set String Value.vi"/>
				<Item Name="Simple Error Handler.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Simple Error Handler.vi"/>
				<Item Name="subFile Dialog.vi" Type="VI" URL="/&lt;vilib&gt;/express/express input/FileDialogBlock.llb/subFile Dialog.vi"/>
				<Item Name="System Directory Type.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/sysdir.llb/System Directory Type.ctl"/>
				<Item Name="TagReturnType.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/TagReturnType.ctl"/>
				<Item Name="Three Button Dialog CORE.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Three Button Dialog CORE.vi"/>
				<Item Name="Three Button Dialog.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Three Button Dialog.vi"/>
				<Item Name="Trim Whitespace.vi" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/Trim Whitespace.vi"/>
				<Item Name="whitespace.ctl" Type="VI" URL="/&lt;vilib&gt;/Utility/error.llb/whitespace.ctl"/>
			</Item>
			<Item Name="CalcRate.vi" Type="VI" URL="../_lib/CalcRate.vi"/>
			<Item Name="GetDLLPath.vi" Type="VI" URL="../_lib/GetDLLPath.vi"/>
			<Item Name="InitMH_UIThread.vi" Type="VI" URL="../_lib/PQ/MultiHarp/InitMH_UIThread.vi"/>
			<Item Name="MH_AllocateAllHistoBuffer.vi" Type="VI" URL="../SubVIs/MH_AllocateAllHistoBuffer.vi"/>
			<Item Name="MH_AllocateCntRateBuffer.vi" Type="VI" URL="../SubVIs/MH_AllocateCntRateBuffer.vi"/>
			<Item Name="MH_AllocateHistoBuffer.vi" Type="VI" URL="../SubVIs/MH_AllocateHistoBuffer.vi"/>
			<Item Name="MH_CalcBinningValues.vi" Type="VI" URL="../SubVIs/MH_CalcBinningValues.vi"/>
			<Item Name="MH_CalcTimeTrace.vi" Type="VI" URL="../SubVIs/MH_CalcTimeTrace.vi"/>
			<Item Name="MH_ClearHistMem.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_ClearHistMem.vi"/>
			<Item Name="MH_CloseDevice.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_CloseDevice.vi"/>
			<Item Name="MH_CTCStatus.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_CTCStatus.vi"/>
			<Item Name="MH_DataProcThread.vi" Type="VI" URL="../SubVIs/MH_DataProcThread.vi"/>
			<Item Name="MH_DataProcThread_Data.ctl" Type="VI" URL="../Types/MH_DataProcThread_Data.ctl"/>
			<Item Name="MH_DataProcThread_QCmds.ctl" Type="VI" URL="../Types/MH_DataProcThread_QCmds.ctl"/>
			<Item Name="MH_DataProcThread_QData.ctl" Type="VI" URL="../Types/MH_DataProcThread_QData.ctl"/>
			<Item Name="MH_DataProcThread_QRef.ctl" Type="VI" URL="../Types/MH_DataProcThread_QRef.ctl"/>
			<Item Name="MH_DllPath_global.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_DllPath_global.vi"/>
			<Item Name="MH_EnQError.vi" Type="VI" URL="../SubVIs/MH_EnQError.vi"/>
			<Item Name="MH_GetAllCountRates.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetAllCountRates.vi"/>
			<Item Name="MH_GetAllHistograms.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetAllHistograms.vi"/>
			<Item Name="MH_GetBaseResolution.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetBaseResolution.vi"/>
			<Item Name="MH_GetCountRate.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetCountRate.vi"/>
			<Item Name="MH_GetErrorString.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetErrorString.vi"/>
			<Item Name="MH_GetFeatures.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetFeatures.vi"/>
			<Item Name="MH_GetFlags.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetFlags.vi"/>
			<Item Name="MH_GetHardwareInfo.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetHardwareInfo.vi"/>
			<Item Name="MH_GetHistogram.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetHistogram.vi"/>
			<Item Name="MH_GetLibraryVersion.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetLibraryVersion.vi"/>
			<Item Name="MH_GetNumOfInputChannels.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetNumOfInputChannels.vi"/>
			<Item Name="MH_GetResolution.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetResolution.vi"/>
			<Item Name="MH_GetSyncPeriod.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetSyncPeriod.vi"/>
			<Item Name="MH_GetSyncRate.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_GetSyncRate.vi"/>
			<Item Name="MH_InitChannels.vi" Type="VI" URL="../SubVIs/MH_InitChannels.vi"/>
			<Item Name="MH_Initialize.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_Initialize.vi"/>
			<Item Name="MH_InitInfo.ctl" Type="VI" URL="../_lib/PQ/MultiHarp/MH_InitInfo.ctl"/>
			<Item Name="MH_InputChannel.ctl" Type="VI" URL="../Types/MH_InputChannel.ctl"/>
			<Item Name="MH_InsertIntoTimeTrace.vi" Type="VI" URL="../SubVIs/MH_InsertIntoTimeTrace.vi"/>
			<Item Name="MH_LibVersion_global.vi" Type="VI" URL="../_lib/PQ/MultiHarp/MH_LibVersion_global.vi"/>
			<Item Name="MH_MeasMode.ctl" Type="VI" URL="../_lib/PQ/MultiHarp/MH_MeasMode.ctl"/>
			<Item Name="MH_OpenDevice.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_OpenDevice.vi"/>
			<Item Name="MH_ProcData.vi" Type="VI" URL="../SubVIs/MH_ProcData.vi"/>
			<Item Name="MH_ReadFiFo.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_ReadFiFo.vi"/>
			<Item Name="MH_RefSource.ctl" Type="VI" URL="../_lib/PQ/MultiHarp/MH_RefSource.ctl"/>
			<Item Name="MH_SetBinning.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetBinning.vi"/>
			<Item Name="MH_SetHistoLen.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetHistoLen.vi"/>
			<Item Name="MH_SetInpChanCmds.ctl" Type="VI" URL="../Types/MH_SetInpChanCmds.ctl"/>
			<Item Name="MH_SetInpChanData.ctl" Type="VI" URL="../Types/MH_SetInpChanData.ctl"/>
			<Item Name="MH_SetInputChannelEnable.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetInputChannelEnable.vi"/>
			<Item Name="MH_SetInputChannelOffset.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetInputChannelOffset.vi"/>
			<Item Name="MH_SetInputChannels.vi" Type="VI" URL="../SubVIs/MH_SetInputChannels.vi"/>
			<Item Name="MH_SetInputDeadTime.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetInputDeadTime.vi"/>
			<Item Name="MH_SetInputEdgeTrg.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetInputEdgeTrg.vi"/>
			<Item Name="MH_SetOffset.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetOffset.vi"/>
			<Item Name="MH_SetStopOverflow.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetStopOverflow.vi"/>
			<Item Name="MH_SetSyncChannelOffset.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetSyncChannelOffset.vi"/>
			<Item Name="MH_SetSyncDeadTime.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetSyncDeadTime.vi"/>
			<Item Name="MH_SetSyncDiv.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetSyncDiv.vi"/>
			<Item Name="MH_SetSyncEdgeTrg.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_SetSyncEdgeTrg.vi"/>
			<Item Name="MH_StartMeas.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_StartMeas.vi"/>
			<Item Name="MH_StopMeas.vi" Type="VI" URL="../_lib/PQ/MultiHarp/mhlib_x86_x64_UIThread.llb/MH_StopMeas.vi"/>
			<Item Name="MH_TTraceToGraph.vi" Type="VI" URL="../SubVIs/MH_TTraceToGraph.vi"/>
			<Item Name="MH_UIThread_Cmds.ctl" Type="VI" URL="../Types/MH_UIThread_Cmds.ctl"/>
			<Item Name="MH_UIThread_Data.ctl" Type="VI" URL="../Types/MH_UIThread_Data.ctl"/>
			<Item Name="MH_VisThread_Data.ctl" Type="VI" URL="../Types/MH_VisThread_Data.ctl"/>
			<Item Name="MH_VisThread_QCmds.ctl" Type="VI" URL="../Types/MH_VisThread_QCmds.ctl"/>
			<Item Name="MH_VisThread_QData.ctl" Type="VI" URL="../Types/MH_VisThread_QData.ctl"/>
			<Item Name="MH_VisThread_QRef.ctl" Type="VI" URL="../Types/MH_VisThread_QRef.ctl"/>
			<Item Name="ProcessTTRecMHT3.vi" Type="VI" URL="../SubVIs/ProcessTTRecMHT3.vi"/>
		</Item>
		<Item Name="Build Specifications" Type="Build">
			<Item Name="MultiHarpHisto_32bit" Type="EXE">
				<Property Name="App_copyErrors" Type="Bool">true</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{A3FC7B41-51F3-4277-960D-F4A4A2E88660}</Property>
				<Property Name="App_INI_GUID" Type="Str">{674B5B29-D174-4E32-9850-4EF5B494851E}</Property>
				<Property Name="App_serverConfig.httpPort" Type="Int">8002</Property>
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{1C1D10C0-20F1-41F0-A5AF-4920650F7B95}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">MultiHarpHisto_32bit</Property>
				<Property Name="Bld_excludeInlineSubVIs" Type="Bool">true</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/32bit</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{23126D42-65E9-496C-A7FB-FB01A1F03942}</Property>
				<Property Name="Bld_version.build" Type="Int">22</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">MultiHarpHisto.exe</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/32bit/MultiHarpHisto_32bit.exe</Property>
				<Property Name="Destination[0].preserveHierarchy" Type="Bool">true</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/32bit/data</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{B25CBEB8-00A8-481E-B9B0-56225D095407}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/2_AdvancedDemo_MHHisto.vi</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">2</Property>
				<Property Name="TgtF_fileDescription" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_internalName" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_legalCopyright" Type="Str">Copyright © 2018 </Property>
				<Property Name="TgtF_productName" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_targetfileGUID" Type="Str">{CE7539E3-DC29-4090-98AC-4E92BF1E1049}</Property>
				<Property Name="TgtF_targetfileName" Type="Str">MultiHarpHisto.exe</Property>
				<Property Name="TgtF_versionIndependent" Type="Bool">true</Property>
			</Item>
			<Item Name="MultiHarpHisto_64bit" Type="EXE">
				<Property Name="App_copyErrors" Type="Bool">true</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{F77FB8C5-AB18-46B5-AEFB-2FB992A73F0B}</Property>
				<Property Name="App_INI_GUID" Type="Str">{5FD366F1-0F46-4CD8-9452-4D8369445E60}</Property>
				<Property Name="App_serverConfig.httpPort" Type="Int">8002</Property>
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{52AEC3E8-707B-4381-BEB5-9026D64D9E83}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="Bld_excludeInlineSubVIs" Type="Bool">true</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/64bit</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{9EFFE2CA-2321-4621-81CF-EAD280E7E294}</Property>
				<Property Name="Bld_version.build" Type="Int">23</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">MultiHarpHisto.exe</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/64bit/MultiHarpHisto_64bit.exe</Property>
				<Property Name="Destination[0].preserveHierarchy" Type="Bool">true</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/64bit/data</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{B25CBEB8-00A8-481E-B9B0-56225D095407}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/2_AdvancedDemo_MHHisto.vi</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">2</Property>
				<Property Name="TgtF_fileDescription" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_internalName" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_legalCopyright" Type="Str">Copyright © 2018 </Property>
				<Property Name="TgtF_productName" Type="Str">MultiHarpHisto_64bit</Property>
				<Property Name="TgtF_targetfileGUID" Type="Str">{1CBB7AFA-1013-4C83-A982-513D3AC51C1E}</Property>
				<Property Name="TgtF_targetfileName" Type="Str">MultiHarpHisto.exe</Property>
				<Property Name="TgtF_versionIndependent" Type="Bool">true</Property>
			</Item>
			<Item Name="MultiHarpT3_32bit" Type="EXE">
				<Property Name="App_copyErrors" Type="Bool">true</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{49FD1B72-ECA8-41B3-AA3E-7EAA12B3EA9B}</Property>
				<Property Name="App_INI_GUID" Type="Str">{51BC1D40-38BC-4BFA-89E6-7F77BC4818F3}</Property>
				<Property Name="App_serverConfig.httpPort" Type="Int">8002</Property>
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{7D1EF675-3FE9-4A17-AA4A-FE81DEB97ABE}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">MultiHarpT3_32bit</Property>
				<Property Name="Bld_excludeInlineSubVIs" Type="Bool">true</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/32bit</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{3C38A977-92FA-4E35-A5D5-8736E0299342}</Property>
				<Property Name="Bld_version.build" Type="Int">10</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">MultiHarpT3.exe</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/32bit/MultiHarpT3_32bit.exe</Property>
				<Property Name="Destination[0].preserveHierarchy" Type="Bool">true</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/32bit/data</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{B25CBEB8-00A8-481E-B9B0-56225D095407}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/3_AdvancedDemo_MHT3.vi</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">2</Property>
				<Property Name="TgtF_fileDescription" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_internalName" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_legalCopyright" Type="Str">Copyright © 2018 </Property>
				<Property Name="TgtF_productName" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_targetfileGUID" Type="Str">{A7AF47EE-1E3B-4F61-B9FC-F558FB1595F9}</Property>
				<Property Name="TgtF_targetfileName" Type="Str">MultiHarpT3.exe</Property>
				<Property Name="TgtF_versionIndependent" Type="Bool">true</Property>
			</Item>
			<Item Name="MultiHarpT3_64bit" Type="EXE">
				<Property Name="App_copyErrors" Type="Bool">true</Property>
				<Property Name="App_INI_aliasGUID" Type="Str">{835A0E67-E657-40A8-B7ED-378A62691F48}</Property>
				<Property Name="App_INI_GUID" Type="Str">{4948ADEA-49EB-4137-BBEB-C69412345079}</Property>
				<Property Name="App_serverConfig.httpPort" Type="Int">8002</Property>
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{89672202-30C7-4894-8536-8E30D8B6D176}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="Bld_excludeInlineSubVIs" Type="Bool">true</Property>
				<Property Name="Bld_excludeLibraryItems" Type="Bool">true</Property>
				<Property Name="Bld_excludePolymorphicVIs" Type="Bool">true</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/64bit</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_modifyLibraryFile" Type="Bool">true</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{DD1C2223-B909-465C-9DCC-AC4C6227EADE}</Property>
				<Property Name="Bld_version.build" Type="Int">10</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">MultiHarpT3.exe</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/64bit/MultiHarpT3_64bit.exe</Property>
				<Property Name="Destination[0].preserveHierarchy" Type="Bool">true</Property>
				<Property Name="Destination[0].type" Type="Str">App</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/64bit/data</Property>
				<Property Name="DestinationCount" Type="Int">2</Property>
				<Property Name="Source[0].itemID" Type="Str">{B25CBEB8-00A8-481E-B9B0-56225D095407}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/3_AdvancedDemo_MHT3.vi</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">TopLevel</Property>
				<Property Name="Source[1].type" Type="Str">VI</Property>
				<Property Name="SourceCount" Type="Int">2</Property>
				<Property Name="TgtF_fileDescription" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_internalName" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_legalCopyright" Type="Str">Copyright © 2018 </Property>
				<Property Name="TgtF_productName" Type="Str">MultiHarpT3_64bit</Property>
				<Property Name="TgtF_targetfileGUID" Type="Str">{5C0B5449-41EC-43A9-9002-BB83519DBEA7}</Property>
				<Property Name="TgtF_targetfileName" Type="Str">MultiHarpT3.exe</Property>
				<Property Name="TgtF_versionIndependent" Type="Bool">true</Property>
			</Item>
		</Item>
	</Item>
</Project>
