#!/bin/bash

# Create fonts directory if it doesn't exist
mkdir -p assets/fonts

# Download Inter font files
wget -O assets/fonts/Inter-Regular.ttf https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Regular.otf
wget -O assets/fonts/Inter-Medium.ttf https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Medium.otf
wget -O assets/fonts/Inter-SemiBold.ttf https://github.com/rsms/inter/raw/master/docs/font-files/Inter-SemiBold.otf
wget -O assets/fonts/Inter-Bold.ttf https://github.com/rsms/inter/raw/master/docs/font-files/Inter-Bold.otf

echo "Fonts downloaded successfully!"
