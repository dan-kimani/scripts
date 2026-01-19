#!/bin/sh

curlExists=$(command -v curl)

current=$(dpkg-query --showformat='${Version}' --show postman 2> /dev/null)

originalPWD="$(pwd)"
targetPWD="$(mktemp -d postman.XXXXXX)"
cd "$targetPWD"

echo "Downloading latest Postman tarball"

if [ -z $curlExists ]; then
	wget -q --show-progress "https://dl.pstmn.io/download/latest/linux64" --content-disposition
else
	curl -# "https://dl.pstmn.io/download/latest/linux64" -O -J
fi

if [ $? -gt 0 ]; then
	echo "Failed to download Postman tarball"
	cd "$originalPWD"
	rm -rf "$targetPWD"
	exit
fi

echo "Extracting Postman tarball"
tar -xf $(ls [Pp]ostman*.tar.gz)

if [ $? -gt 0 ]; then
	echo "Failed to extract Postman tarball"
	cd "$originalPWD"
	rm -rf "$targetPWD"
	exit
fi

echo "Detecting Postman version"
version=""
if [ -f "Postman/app/resources/app/package.json" ]; then
	version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "Postman/app/resources/app/package.json" 2>/dev/null)
fi

if [ -z "$version" ]; then
	echo "Failed to detect Postman version"
	cd "$originalPWD"
	rm -rf "$targetPWD"
	exit
fi

echo "Most recent Postman version V$version"

if [ ! -z "$current" ]; then
	echo "Installed version V$current"
	
	if [ "$current" = "$version" ]; then
		echo "The most recent version of Postman is currently installed"
		cd "$originalPWD"
		rm -rf "$targetPWD"
		exit
	else
		echo "Updating Postman to the latest version"
	fi
else
	echo "Postman is not installed"
fi

echo "Creating 'postman_$version' folder structure and files"
mkdir -m 0755 -p "postman_$version"

mkdir -m 0755 -p "postman_$version/usr/share/applications"
touch "postman_$version/usr/share/applications/Postman.desktop"

mkdir -m 0755 -p "postman_$version/usr/share/icons/hicolor/128x128/apps"

mkdir -m 0755 -p "postman_$version/opt/postman"

mkdir -m 0755 -p "postman_$version/DEBIAN"
touch "postman_$version/DEBIAN/control" "postman_$version/DEBIAN/postinst" "postman_$version/DEBIAN/prerm"

echo "Copying files"
cp "Postman/app/resources/app/assets/icon.png" "postman_$version/usr/share/icons/hicolor/128x128/apps/postman.png"
cp -R "Postman/"* "postman_$version/opt/postman/"

echo "Testing whether to use '-e'"
lines=$(echo "\n" | wc -l)
e=""
if [ $lines -eq 1 ]; then
	echo "'-e' is required"
	e="-e"
else
	echo "'-e' is not required"
fi

echo "Writing files"
echo $e "[Desktop Entry]\nType=Application\nName=Postman\nGenericName=Postman API Tester\nIcon=postman\nExec=postman\nPath=/opt/postman\nCategories=Development;" > "postman_$version/opt/postman/Postman.desktop"
echo $e "Package: Postman\nVersion: $version\nSection: devel\nPriority: optional\nArchitecture: amd64\nDepends: gconf2, libgtk2.0-0, desktop-file-utils\nOptional: libcanberra-gtk-module\nMaintainer: You\nDescription: Postman\n API something" > "postman_$version/DEBIAN/control"
echo $e "if [ -f \"/usr/bin/postman\" ]; then\n\tsudo rm -f \"/usr/bin/postman\"\nfi\n\nsudo ln -s \"/opt/postman/Postman\" \"/usr/bin/postman\"\n\ndesktop-file-install \"/opt/postman/Postman.desktop\"" > "postman_$version/DEBIAN/postinst"
echo $e "if [ -f \"/usr/bin/postman\" ]; then\n\tsudo rm -f \"/usr/bin/postman\"\nfi" > "postman_$version/DEBIAN/prerm"

echo "Setting modes"

chmod 0775 "postman_$version/usr/share/applications/Postman.desktop"

chmod 0775 "postman_$version/DEBIAN/control"
chmod 0775 "postman_$version/DEBIAN/postinst"
chmod 0775 "postman_$version/DEBIAN/prerm"

echo "Validating modes"
nc=""
if [ $(stat -c "%a" "postman_$version/DEBIAN/control") != "775" ]; then
	echo "File modes are invalid, calling 'dpkg-deb' with '--nocheck'"
	nc="--nocheck"
else
	echo "File modes are valid"
fi

echo "Building 'postman_$version.deb'"
dpkg-deb $nc -b "postman_$version" > /dev/null

if [ $? -gt 0 ]; then
	echo "Failed to build 'postman_$version.deb'"
	exit
fi

mv "postman_$version.deb" "$originalPWD"
cd "$originalPWD"

echo "Cleaning up"
rm -rf "$targetPWD"

while true; do
	read -p "Do you want to install 'postman_$version.deb' [Y/n] " yn

	if [ -z "$yn" ]; then
		yn="y"
	fi

	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit;;
	esac
done

echo "Installing"
sudo apt install -y "./postman_$version.deb"

if [ $? -gt 0 ]; then
	echo "Failed to install 'postman_$version.deb'"
	exit
fi

echo "Removing 'postman_$version.deb'"
rm -f "postman_$version.deb"