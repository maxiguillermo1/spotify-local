#!/usr/bin/env python3
"""Generate the Spotify Local iOS Xcode project."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "ios/SpotifyLocal/SpotifyLocal.xcodeproj"

SWIFT_APP = [
    "App/SpotifyLocalApp.swift",
    "App/AppState.swift",
    "Bridge/BridgeClient.swift",
    "Bridge/MockBridgeClient.swift",
    "Bridge/LocalBridgeClient.swift",
    "Bridge/FolderBridgeClient.swift",
    "Bridge/AudioMetadataReader.swift",
    "Preview/MockLibrary.swift",
    "Views/Platform.swift",
    "Views/ArtworkView.swift",
    "Views/ConnectionHeader.swift",
    "Views/TrackRow.swift",
    "Views/HomeView.swift",
    "Views/LibraryView.swift",
    "Views/TrackDetailView.swift",
    "Views/EmptyLibraryView.swift",
    "Views/MusicImport.swift",
]

CORE = [
    "ConnectionStatus.swift",
    "TrackAvailability.swift",
    "ArtworkReference.swift",
    "Track.swift",
    "MusicLibrary.swift",
    "BridgeEvent.swift",
    "WireProtocol.swift",
    "PathSecurity.swift",
    "LibraryImporter.swift",
]


class IDs:
    def __init__(self) -> None:
        self.n = 1

    def take(self) -> str:
        value = f"A{self.n:023X}"
        self.n += 1
        return value


def main() -> None:
    ids = IDs()
    project_id = ids.take()
    target_id = ids.take()
    sources_phase = ids.take()
    resources_phase = ids.take()
    frameworks_phase = ids.take()
    product_ref = ids.take()
    root_group = ids.take()
    products_group = ids.take()
    app_group = ids.take()
    core_group = ids.take()
    assets_ref = ids.take()
    assets_build = ids.take()
    project_configs = ids.take()
    target_configs = ids.take()
    project_debug = ids.take()
    project_release = ids.take()
    target_debug = ids.take()
    target_release = ids.take()

    file_refs: list[str] = []
    build_files: list[str] = []
    source_phase_entries: list[str] = []
    app_children: list[str] = []
    core_children: list[str] = []

    for rel in SWIFT_APP:
        name = Path(rel).name
        ref = ids.take()
        build = ids.take()
        file_refs.append(
            f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel}; sourceTree = \"<group>\"; }};"
        )
        build_files.append(
            f"\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"
        )
        source_phase_entries.append(f"\t\t\t\t{build} /* {name} in Sources */,")
        app_children.append(f"\t\t\t\t{ref} /* {name} */,")

    for name in CORE:
        ref = ids.take()
        build = ids.take()
        file_refs.append(
            f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {name}; path = ../../shared/Sources/SpotifyLocalCore/{name}; sourceTree = \"<group>\"; }};"
        )
        build_files.append(
            f"\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"
        )
        source_phase_entries.append(f"\t\t\t\t{build} /* {name} in Sources */,")
        core_children.append(f"\t\t\t\t{ref} /* {name} */,")

    file_refs.append(
        f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};"
    )
    file_refs.append(
        f"\t\t{product_ref} /* SpotifyLocal.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SpotifyLocal.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    app_children.append(f"\t\t\t\t{assets_ref} /* Assets.xcassets */,")
    build_files.append(
        f"\t\t{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};"
    )

    common_target = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGNING_ALLOWED = NO;
				CODE_SIGNING_REQUIRED = NO;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Spotify Local";
				INFOPLIST_KEY_LSRequiresIPhoneOS = YES;
				INFOPLIST_KEY_NSBonjourServices = (
					"_spotifylocal._tcp",
				);
				INFOPLIST_KEY_NSLocalNetworkUsageDescription = "Spotify Local finds your Mac on Wi-Fi to transfer music you already own.";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.spotifylocal.ios;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{root_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* SpotifyLocal */,
				{core_group} /* SpotifyLocalCore */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{app_group} /* SpotifyLocal */ = {{
			isa = PBXGroup;
			children = (
{chr(10).join(app_children)}
			);
			path = SpotifyLocal;
			sourceTree = "<group>";
		}};
		{core_group} /* SpotifyLocalCore */ = {{
			isa = PBXGroup;
			children = (
{chr(10).join(core_children)}
			);
			name = SpotifyLocalCore;
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* SpotifyLocal.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* SpotifyLocal */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_configs} /* Build configuration list for PBXNativeTarget "SpotifyLocal" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = SpotifyLocal;
			productName = SpotifyLocal;
			productReference = {product_ref} /* SpotifyLocal.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {project_configs} /* Build configuration list for PBXProject "SpotifyLocal" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {root_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* SpotifyLocal */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{assets_build} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(source_phase_entries)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{project_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{project_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{target_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target}			}};
			name = Debug;
		}};
		{target_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target}			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_configs} /* Build configuration list for PBXProject "SpotifyLocal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{project_debug} /* Debug */,
				{project_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_configs} /* Build configuration list for PBXNativeTarget "SpotifyLocal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_debug} /* Debug */,
				{target_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_id} /* Project object */;
}}
"""

    PROJECT.mkdir(parents=True, exist_ok=True)
    (PROJECT / "project.pbxproj").write_text(pbx)

    scheme_dir = PROJECT / "xcshareddata/xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "SpotifyLocal.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "SpotifyLocal.app"
               BlueprintName = "SpotifyLocal"
               ReferencedContainer = "container:SpotifyLocal.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "SpotifyLocal.app"
            BlueprintName = "SpotifyLocal"
            ReferencedContainer = "container:SpotifyLocal.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "SpotifyLocal.app"
            BlueprintName = "SpotifyLocal"
            ReferencedContainer = "container:SpotifyLocal.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    )


if __name__ == "__main__":
    main()
