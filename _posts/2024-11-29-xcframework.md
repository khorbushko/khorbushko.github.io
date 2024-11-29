---
layout: post
comments: true
title: ".xcframework"
categories: article
tags: [swift, .xcframework, script]
excerpt_separator: <!--more-->
comments_id: 108

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

As developers increasingly target multiple Apple platforms—iOS, macOS, iPadOS, watchOS, and tvOS—there's a growing need to share code across these environments. Sharing code not only improves development efficiency but also ensures consistency across apps, reduces maintenance efforts, and speeds up updates.
<!--more-->

To meet this need, developers often create reusable frameworks. However, the challenge lies in building a single framework that works seamlessly across different devices and architectures, such as physical iOS devices, iOS simulators, and macOS apps (via Mac Catalyst). Achieving this involves complex processes, including architecture-specific builds and platform compatibility handling.


## Common Approaches to Code Sharing

There are several methods for building reusable frameworks to support multiple platforms:

**Separate Frameworks for Each Platform:**

* Developers create individual frameworks for each platform (e.g., one for iOS, another for Mac Catalyst).
* Challenges: Increased manual effort, redundancy in maintenance, and potential mismatches between versions for different platforms.

**Universal Frameworks:**

* These frameworks combine all supported architectures into a single binary.
* Challenges: Universal frameworks are no longer supported in the latest Apple toolchains for iOS 15 and above due to new restrictions.

**XCFrameworks:**

* Apple introduced XCFrameworks in Xcode 11 to provide a robust solution for multi-platform development.
* Benefits: Fully supported by Apple, easy to distribute, and capable of packaging slices for multiple architectures and platforms into a single distributable framework.


From these options, XCFrameworks stand out as the best approach for modern Apple development due to their flexibility and official support.

## What is an XCFramework?

An XCFramework is a new framework packaging format introduced by Apple to address the limitations of Universal Frameworks. It allows developers to bundle binary slices for multiple platforms and architectures into a single distributable package. This format makes it easy to create a single framework that works seamlessly across:

* **iOS Devices**: Built for ARM architectures.
* **iOS Simulators**: Built for x86_64 or ARM64 architectures.
* **Mac Catalyst**: Built for Mac applications using Catalyst technology.

### Key Features of XCFrameworks:

* Multi-Platform Support: Combine binaries for iOS, macOS, watchOS, and tvOS into a single framework.
* Multi-Architecture Compatibility: Package slices for ARM, x86_64, and ARM64 architectures.
* Simplified Distribution: Developers can distribute a single XCFramework file that contains all required binaries for various platforms.
* Built-In Toolchain Support: Apple provides official support for creating and using XCFrameworks via xcodebuild.

### How XCFrameworks Work 

An XCFramework bundles multiple framework slices, each tailored for specific platforms and architectures, into a single distributable package. This ensures compatibility across various Apple ecosystems, including iOS, macOS, watchOS, and tvOS. Here's a conceptual breakdown:

```
XCFramework
├── iOS (Device)
│   └── Architecture: arm64
│       └── Framework Binary
│       └── Resources (e.g., images, storyboards)
├── iOS (Simulator)
│   └── Architecture: x86_64, arm64
│       └── Framework Binary
│       └── Resources
├── macOS (Catalyst)
│   └── Architecture: x86_64, arm64
│       └── Framework Binary
│       └── Resources
├── watchOS
│   └── Device and Simulator (arm64, x86_64)
│       └── Framework Binary
│       └── Resources
├── tvOS
│   └── Device and Simulator (arm64, x86_64)
│       └── Framework Binary
│       └── Resources
├── Metadata
│   └── Info.plist (Defines the structure and included slices)
```

## Possible Solutions

An XCFramework is a packaging format introduced by Apple to address the need for a multi-platform framework that works on different devices and architectures. However, building an XCFramework is not as simple as running a single command. It involves building separate archives for each platform, which are then combined into the final XCFramework. There are a few ways to accomplish this:

**Manual Approach:**

* The manual method involves using Xcode's command-line tool (xcodebuild) to archive the framework for each platform separately. Afterward, you manually combine the generated archives into an XCFramework.
* While this approach gives developers complete control over the process, it is tedious, error-prone, and requires significant time and effort, especially when you need to support multiple platforms like iOS devices, iOS simulators, and Mac Catalyst.

**Xcode Project Setup with Multiple Targets:**

* You can configure your Xcode project to have multiple targets for each platform. This setup allows you to use Xcode's build system to create platform-specific archives. However, managing these targets and ensuring all configurations are correct can be complex and requires a good understanding of Xcode.
* Although this method can be streamlined using a custom build script, it still requires some manual intervention and does not provide a fully automated solution.

**Automated Build Scripts:**

* Automating the process using a build script is the most efficient and reliable method for creating an XCFramework. This method reduces human error, speeds up the process, and allows you to integrate the build process into your CI/CD pipeline.
* 
* Using a script, you can automate the entire process: cleaning the build environment, building archives for different platforms, and creating the final XCFramework. This approach ensures that the process is repeatable and scalable.

## Script

### Inspiration

This script was inspired by the work of [`Phillip Jacobs`](https://github.com/phillipjacobs/Create-XCFramework)' Create-XCFramework, which provides a foundational approach to automating the creation of XCFrameworks. The original idea and structure laid the groundwork for a streamlined and efficient build process, and this script builds upon that inspiration by adding additional features such as enhanced error handling, time tracking, and user-friendly visual feedback. 

I’ve also incorporated platform-specific archives and automated cleanup to further optimize the workflow for iOS and Mac Catalyst development.

{% highlight bash %}

#!/bin/bash

# Configuration Variables
FRAMEWORK_NAME="MySDK"       # Name of the framework to build
PROJECT_TYPE="project"                 # Type of Xcode project ("project" or "workspace")
FILE_EXTENSION="xcodeproj"             # File extension of the Xcode project ("xcodeproj" or "xcworkspace")
SCHEME_NAME="$FRAMEWORK_NAME"          # Xcode scheme name to build

# Directories for build outputs
ARCHIVE_DIR="./archives"               # Directory to store intermediate archives
XCFRAMEWORK_OUTPUT_DIR="$ARCHIVE_DIR/xcframework" # Directory to store the final XCFramework
FRAMEWORK_SUBPATH="Products/Library/Frameworks/$FRAMEWORK_NAME.framework" # Path to the built framework within an archive

# Archive Paths for different platforms
IPHONE_ARCHIVE="$ARCHIVE_DIR/$FRAMEWORK_NAME-iphoneos.xcarchive"            # Archive for physical iOS devices
SIMULATOR_ARCHIVE="$ARCHIVE_DIR/$FRAMEWORK_NAME-iphonesimulator.xcarchive"  # Archive for iOS simulators
MAC_CATALYST_ARCHIVE="$ARCHIVE_DIR/$FRAMEWORK_NAME-catalyst.xcarchive"      # Archive for Mac Catalyst

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Verbose mode (default: off)
VERBOSE=false

### Utility Functions for ASCII Art ###
display_success() {
    echo "${GREEN}"
    cat << "EOF"
                                *     .--.
                                / /  `
               +               | |
                      '         \ \__,
                  *          +   '--'  *
                      +   /\
         +              .'  '.   *
                *      /======\      +
                      ;:.  _   ;
                      |:. (_)  |
                      |:.  _   |
            +         |:. (_)  |          *
                      ;:.      ;
                    .' \:.    / `.
                   / .-'':._.'`-. \
                   |/    /||\    \|
             jgs _..--"""````"""--.._
           _.-'``                    ``'-._
         -'
         FRAMEWORK BUILD COMPLETED SUCCESSFULLY
EOF
    echo "${RESET}"
}

display_error() {
    echo "${RED}"
    cat << "EOF"
(ノಠ益ಠ)ノ彡┻━┻
EOF
    echo "${RESET}"
}

### Reset the Build Environment ###
reset_build_environment() {
    echo "${YELLOW}• Resetting build environment...${RESET}"
    start_time=$(date +%s)

    rm -rvf "$ARCHIVE_DIR" > /dev/null 2>&1
    mkdir -p "$ARCHIVE_DIR"

    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo "${GREEN}• [Reset] Build environment cleaned in ${elapsed}s. •${RESET}"
}

### Build an Archive for a Specific Destination ###
build_archive() {
    local destination=$1      # Platform and architecture to build for
    local archive_path=$2     # Path to save the archive

    echo "${YELLOW}• Building archive for destination: $destination...${RESET}"
    start_time=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        xcodebuild archive \
            -$PROJECT_TYPE "$FRAMEWORK_NAME.$FILE_EXTENSION" \
            -scheme "$SCHEME_NAME" \
            -configuration Release \
            -destination "$destination" \
            -archivePath "$archive_path" \
            SKIP_INSTALL=NO &
    else
        xcodebuild archive \
            -$PROJECT_TYPE "$FRAMEWORK_NAME.$FILE_EXTENSION" \
            -scheme "$SCHEME_NAME" \
            -configuration Release \
            -destination "$destination" \
            -archivePath "$archive_path" \
            SKIP_INSTALL=NO > /dev/null 2>&1 &
    fi

    wait $! # Wait for the background process to finish
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        echo "${GREEN}• [Archived] $destination slice created in ${elapsed}s. •${RESET}"
    else
        echo "${RED}✖ [Error] Failed to archive for $destination.${RESET}"
        display_error
        exit 1
    fi
}

### Build Archive for Physical iOS Devices ###
build_iphone_slice() {
    build_archive 'generic/platform=iOS' "$IPHONE_ARCHIVE"
}

### Build Archive for iOS Simulators ###
build_simulator_slice() {
    build_archive 'generic/platform=iOS Simulator' "$SIMULATOR_ARCHIVE"
}

### Build Archive for Mac Catalyst ###
build_mac_catalyst_slice() {
    build_archive 'platform=macOS,arch=x86_64,variant=Mac Catalyst' "$MAC_CATALYST_ARCHIVE"
}

### Create XCFramework from Built Slices ###
create_xcframework() {
    local include_mac_catalyst=$1
    local xcframework_args=(
        -framework "$IPHONE_ARCHIVE/$FRAMEWORK_SUBPATH"
        -framework "$SIMULATOR_ARCHIVE/$FRAMEWORK_SUBPATH"
    )

    if [ "$include_mac_catalyst" = true ]; then
        xcframework_args+=(-framework "$MAC_CATALYST_ARCHIVE/$FRAMEWORK_SUBPATH")
    fi

    echo "${YELLOW}• Creating XCFramework...${RESET}"
    start_time=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        xcodebuild -create-xcframework \
            "${xcframework_args[@]}" \
            -output "$XCFRAMEWORK_OUTPUT_DIR/$FRAMEWORK_NAME.xcframework" &
    else
        xcodebuild -create-xcframework \
            "${xcframework_args[@]}" \
            -output "$XCFRAMEWORK_OUTPUT_DIR/$FRAMEWORK_NAME.xcframework" > /dev/null 2>&1 &
    fi

    wait $! # Wait for the background process to finish
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        elapsed=$((end_time - start_time))
        echo "${GREEN}• [XCFramework] Created in ${elapsed}s at: $XCFRAMEWORK_OUTPUT_DIR/$FRAMEWORK_NAME.xcframework •${RESET}"
    else
        echo "${RED}✖ [Error] Failed to create XCFramework.${RESET}"
        display_error
        exit 1
    fi
}

### Build and Create XCFramework ###
build_framework() {
    local include_mac_catalyst=$1

    # Track the overall time of the build process
    total_start_time=$(date +%s)

    reset_build_environment
    build_iphone_slice
    build_simulator_slice
    [ "$include_mac_catalyst" = true ] && build_mac_catalyst_slice
    create_xcframework "$include_mac_catalyst"

    total_end_time=$(date +%s)
    total_elapsed=$((total_end_time - total_start_time))

    echo "${GREEN}• [Build Complete] XCFramework is ready at: $XCFRAMEWORK_OUTPUT_DIR/$FRAMEWORK_NAME.xcframework •${RESET}"
    display_success

    # Display total time spent
    echo "${YELLOW}Total time spent: ${total_elapsed}s${RESET}"
}

### Parse Command-Line Arguments ###
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose)
            VERBOSE=true
            shift
            ;;
        macCatalyst)
            INCLUDE_MAC_CATALYST=true
            shift
            ;;
        *)
            echo "${RED}Unknown option: $1${RESET}"
            exit 1
            ;;
    esac
done

### Execute Build ###
build_framework "${INCLUDE_MAC_CATALYST:-false}"
{% endhighlight %}

The output may be as below:

```
khb@MacBook-Pro-kyryl MySDK % sh create-xcframework.sh
• Resetting build environment...
• [Reset] Build environment cleaned in 0s. •
• Building archive for destination: generic/platform=iOS...
• [Archived] generic/platform=iOS slice created in 35s. •
• Building archive for destination: generic/platform=iOS Simulator...
• [Archived] generic/platform=iOS Simulator slice created in 38s. •
• Creating XCFramework...
• [XCFramework] Created in 2s at: ./archives/xcframework/MySDK.xcframework •
• [Build Complete] XCFramework is ready at: ./archives/xcframework/MySDK.xcframework •

                                *     .--.
                                / /  `
               +               | |
                      '         \ \__,
                  *          +   '--'  *
                      +   /\
         +              .'  '.   *
                *      /======\      +
                      ;:.  _   ;
                      |:. (_)  |
                      |:.  _   |
            +         |:. (_)  |          *
                      ;:.      ;
                    .' \:.    / `.
                   / .-'':._.'`-. \
                   |/    /||\    \|
             jgs _..--"""````"""--.._
           _.-'``                    ``'-._
         -'
         FRAMEWORK BUILD COMPLETED SUCCESSFULLY

Total time spent: 75s

```

## Pitfalls

1. **Incompatible Architectures**

	**Problem**: 
	The XCFramework may fail to work if incompatible architectures (e.g., ARM64, x86_64) are included for certain platforms.
	
	**Solution**:
	Ensure you explicitly build slices for each platform and architecture using the correct destination in xcodebuild (e.g., generic/platform=iOS for devices, generic/platform=iOS Simulator for simulators).
	Exclude unsupported architectures using the `EXCLUDED_ARCHS` build setting where necessary.

2. **Framework Not Found Error**

	**Problem**: 
	Consumers of the XCFramework encounter "Framework not found" errors during integration.
	
	**Solution**:
	Ensure that the framework is properly embedded in the app target using the Embed Frameworks build phase in Xcode.
	Verify that the `DYLD_LIBRARY_PATH` and `LD_RUNPATH_SEARCH_PATHS` settings include the path to the embedded framework.

3. **Duplicate Symbol Errors**

	**Problem**: 
	Duplicate symbol errors may arise when combining different framework binaries into an XCFramework.
	
	**Solution**:
	Use the `SKIP_INSTALL`=NO and `BUILD_LIBRARY_FOR_DISTRIBUTION`=YES settings when archiving. This ensures that the framework binaries are built for distribution without symbol conflicts.

4. **Framework is Not ABI-Compatible**

	**Problem**: 
	The XCFramework may fail on certain platforms or Xcode versions due to ABI (Application Binary Interface) incompatibilities.
	
	**Solution**:
	Always set `BUILD_LIBRARY_FOR_DISTRIBUTION`=YES to enable module stability and ensure ABI compatibility for Swift frameworks.

5. **Large XCFramework Size**

	**Problem**: 
	The XCFramework may become very large due to the inclusion of multiple architecture slices.
	
	**Solution**:
	Optimize the size by removing debug symbols using the strip command or by setting `DEBUG_INFORMATION_FORMAT` to dwarf-with-dsym for release builds.

6. **Mac Catalyst Integration Issues**

	**Problem**: 
	The Mac Catalyst slice may cause build or runtime errors due to missing settings or unsupported APIs.
	
	**Solution**:
	Explicitly enable Mac Catalyst support in your Xcode project by selecting Mac in the Deployment Info section.
	Test the framework on a Mac Catalyst app to ensure compatibility.

7. **Lack of Swift Compatibility**

	**Problem**: 
	If the XCFramework includes Swift code, it may break when used with a different Swift compiler version.
	
	**Solution**:
	Always build the XCFramework with `BUILD_LIBRARY_FOR_DISTRIBUTION`=YES to make it module-stable across different Swift versions.

8. **Failure to Distribute Resources**

	**Problem**: Resources (e.g., images, storyboards) included in the framework are not accessible after integration.
	
	**Solution**:
	Use a resource bundle and include it in the XCFramework.
	Ensure consumers include the resource bundle in their app target.

9. **Code Signing Issues**

	**Problem**: 
	Code signing errors when using the XCFramework in a signed app.
	
	**Solution**:
	Build the framework without signing (`CODE_SIGN_IDENTITY`="" `CODE_SIGNING_REQUIRED`=NO) to avoid conflicts during XCFramework creation.
	Let the consuming app handle code signing during the final build.

10. **Debugging Challenges**

	**Problem**: 
	Difficulties debugging issues in an XCFramework due to stripped symbols or lack of debugging tools.
	
	**Solution**:
	Ensure `DEBUG_INFORMATION_FORMAT` is set to dwarf-with-dsym for debug builds.
	Distribute the dSYM files along with the XCFramework for debugging purposes.

11. **Integration Issues in CI/CD**

	**Problem**: 
	CI/CD pipelines may encounter errors when using XCFrameworks due to dependency resolution issues.
	
	**Solution**:
	Use tools like CocoaPods, Carthage, or Swift Package Manager to automate XCFramework integration.
	Ensure the build script for CI includes steps to resolve and embed dependencies.

12. **Limited Support for Older Xcode Versions**

	**Problem**:
	XCFrameworks may not be supported in older Xcode versions (pre-Xcode 11).
	
	**Solution**:
	Clearly document the minimum required Xcode version for consuming the XCFramework.
	For older projects, consider providing fallback universal frameworks where feasible.

13. **Misconfigured Build Settings**

	**Problem**: 
	Incorrect build settings (e.g., deployment targets, library types) can cause runtime errors or missing symbols.
	
	**Solution**:
	Set the Minimum Deployment Target to the lowest version you wish to support.
	Double-check that the framework type is set to Dynamic Framework if dynamic linking is needed.

## Strip unused arch

To reduce the size of a framework, we could remove unused architectures from it.

How to Use This Script in Xcode

1. Add a New Run Script Phase:

	* Open your Xcode project.
	* Select your target in the Project Navigator.
	* Go to the Build Phases tab.
	* Click the "+" button and select New Run Script Phase.

2. Paste the Script:

	* Copy the script above and paste it into the Run Script text field.

3. Configure Options:

	* Ensure Input Files and Output Files are left empty unless needed for specific workflows.
	* Enable Show environment variables in build log if you want detailed output during the build.

4. Build Your Project:

	* Run your project as usual.
	* The script will automatically strip unused architectures from embedded frameworks during the build process.

Script:

{% highlight bash %}
# Path to the app's framework folder within the build directory
APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

echo "Stripping unused architectures in embedded frameworks..."

# Iterate through all embedded frameworks
find "$APP_PATH" -name '*.framework' -type d | while read -r FRAMEWORK
do
    # Get the framework executable name and path
    FRAMEWORK_EXECUTABLE_NAME=$(defaults read "$FRAMEWORK/Info.plist" CFBundleExecutable)
    FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
    echo "Processing framework: $FRAMEWORK_EXECUTABLE_NAME at $FRAMEWORK_EXECUTABLE_PATH"

    # Extract only the active architectures
    EXTRACTED_ARCHS=()
    for ARCH in $ARCHS
    do
        echo "Extracting architecture: $ARCH"
        lipo -extract "$ARCH" "$FRAMEWORK_EXECUTABLE_PATH" -o "$FRAMEWORK_EXECUTABLE_PATH-$ARCH"
        EXTRACTED_ARCHS+=("$FRAMEWORK_EXECUTABLE_PATH-$ARCH")
    done

    # Merge the extracted architectures back into the framework executable
    echo "Merging extracted architectures: ${ARCHS}"
    lipo -o "$FRAMEWORK_EXECUTABLE_PATH-merged" -create "${EXTRACTED_ARCHS[@]}"
    rm "${EXTRACTED_ARCHS[@]}"  # Remove temporary architecture files

    # Replace the original executable with the thinned version
    echo "Replacing original executable with thinned version"
    rm "$FRAMEWORK_EXECUTABLE_PATH"
    mv "$FRAMEWORK_EXECUTABLE_PATH-merged" "$FRAMEWORK_EXECUTABLE_PATH"
done

echo "Completed stripping unused architectures."
{% endhighlight %}

## Conclusion:

Building an XCFramework can be a complex and error-prone task, especially when targeting multiple platforms. This automated build script provides the best solution by simplifying and streamlining the process. By automating the entire workflow, it saves time, ensures consistency, and improves the overall development experience.

For iOS and macOS developers who need to create XCFrameworks, this script is the optimal solution for handling cross-platform compatibility, automating the build process, and improving workflow efficiency.

## Resources

- [Apple Developer: Distributing Binary Frameworks as XCFrameworks](https://developer.apple.com/documentation/xcode/distributing-binary-frameworks-as-xcframeworks)
- [Apple Developer: Creating an XCFramework](https://developer.apple.com/documentation/xcode/creating-xcframeworks)
- [Raywenderlich: How to Create an XCFramework](https://www.raywenderlich.com/10505848-creating-an-xcframework)
- [Medium: A Practical Guide to XCFrameworks](https://medium.com/@alex_llewellyn/a-practical-guide-to-xcframeworks-6df6a1b0370b)
- [XCFrameworks vs Universal Frameworks: The New Standard for Code Distribution](https://www.donnywals.com/xcframeworks-vs-universal-frameworks/)
- [Phillip Jacobs: Create-XCFramework](https://github.com/phillipjacobs/Create-XCFramework)
- [GitHub Gist: Example Script for XCFramework Creation](https://gist.github.com/jonreid/9b2e1657edc87c6402da1a93b678ffed)
- [Stack Overflow: Common Issues with XCFrameworks](https://stackoverflow.com/questions/tagged/xcframework)
- [Medium: Resolving XCFramework Issues in Xcode](https://medium.com/@fabcouple/handling-xcframework-issues-in-xcode-11-dbe7e9729ba6)
- [WWDC 2019: Binary Frameworks in Swift](https://developer.apple.com/videos/play/wwdc2019/416/)
- [WWDC 2020: Advances in Build System](https://developer.apple.com/videos/play/wwdc2020/10653/)
- [Swift by Sundell: Packaging Frameworks](https://www.swiftbysundell.com/articles/packaging-swift-frameworks/)
- [Reddit: r/iOSProgramming - Discussions on XCFrameworks](https://www.reddit.com/r/iOSProgramming/)
- [Strip framework](https://ikennd.ac/blog/2015/02/stripping-unwanted-architectures-from-dynamic-libraries-in-xcode/)


