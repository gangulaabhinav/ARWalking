# Builds and create ARwalking.ipa installable file

script_dir=$(dirname "${BASH_SOURCE[0]}")
echo "Bash source is $script_dir"
cd $script_dir
build_dir=build
echo "Using $build_dir to build the ARWalking and generating ipa"

########################################################################################
# Build ARWalking release iPhone
xcodebuild -scheme "ARWalking" SYMROOT="$build_dir" -sdk iphoneos -configuration release -quiet
# Copy ArWalking.app to Payload folder and zip it to ARWalking.ipa
rm -r $build_dir/Payload
mkdir -p $build_dir/Payload
cp -r $build_dir/Release-iphoneos/ARWalking.app $build_dir/Payload
# cd into $build_dir as this would let us zip Payload folder without including parent directory structure
cd $build_dir
zip -r ARWalking.ipa Payload
echo "ARWalking.ipa generated in $script_dir/$build_dir"
