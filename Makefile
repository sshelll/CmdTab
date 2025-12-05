APP_NAME := CmdTab
BUNDLE_ID := com.sshelll.cmdtab
VERSION := 1.0.0

.PHONY: all dmg app build gen_icon pack_icon clean run debug sha256
all: dmg

run:
	@nohup swift run CmdTab > nohup.out 2>&1 &

debug:
	@swift run CmdTab

build:
	@echo "🔨 Building $(APP_NAME)..."
	@swift build -c release

app: build
	@echo "📱 Creating app bundle..."
	@rm -rf $(APP_NAME).app
	@mkdir -p $(APP_NAME).app/Contents/MacOS
	@mkdir -p $(APP_NAME).app/Contents/Resources
	
	@echo "📋 Copying executable..."
	@cp .build/release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/
	@chmod +x $(APP_NAME).app/Contents/MacOS/$(APP_NAME)
	
	@echo "📄 Creating Info.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(APP_NAME).app/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(APP_NAME).app/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(APP_NAME).app/Contents/Info.plist
	@echo '<dict>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleName</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>$(APP_NAME)</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleIdentifier</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>$(BUNDLE_ID)</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleExecutable</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>$(APP_NAME)</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundlePackageType</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>APPL</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleVersion</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>$(VERSION)</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleShortVersionString</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>$(VERSION)</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>LSUIElement</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <true/>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <key>CFBundleIconFile</key>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '    <string>AppIcon</string>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '</dict>' >> $(APP_NAME).app/Contents/Info.plist
	@echo '</plist>' >> $(APP_NAME).app/Contents/Info.plist
	
	@if [ -f "artifacts/AppIcon.icns" ]; then \
		echo "🎨 Adding app icon..."; \
		cp artifacts/AppIcon.icns $(APP_NAME).app/Contents/Resources/; \
	fi
	
	@echo "✍️  Signing app..."
	@codesign --deep --force --sign - $(APP_NAME).app
	@echo "✅ App bundle created: $(APP_NAME).app"

dmg: clean pack_icon app
	@echo "📦 Creating DMG..."
	@create-dmg \
	  --volname "$(APP_NAME) Installer" \
	  --volicon "artifacts/AppIcon.icns" \
	  --background "artifacts/dmg_background.png" \
	  --window-pos 400 100 \
	  --window-size 600 400 \
	  --icon-size 100 \
	  --icon "$(APP_NAME).app" 150 200 \
	  --hide-extension "$(APP_NAME).app" \
	  --app-drop-link 450 200 \
	  "$(APP_NAME).dmg" \
	  "$(APP_NAME).app"
	@echo "✅ Done: $(APP_NAME).dmg"
	@echo "SHA256: $$(shasum -a 256 CmdTab.dmg)"

sha256:
	@echo "SHA256: $$(shasum -a 256 CmdTab.dmg)"

gen_icon:
	@echo "🎨 Generating icon..."
	@mkdir artifacts/AppIcon.iconset
	@sips -i -z 16 16 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_16x16.png
	@sips -i -z 32 32 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_16x16@2x.png
	@sips -i -z 40 40 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_20x20@2x.png
	@sips -i -z 60 60 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_20x20@3x.png
	@sips -i -z 58 58 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_29x29@2x.png
	@sips -i -z 87 87 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_29x29@3x.png
	@sips -i -z 32 32 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_32x32.png
	@sips -i -z 64 64 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_32x32@2x.png
	@sips -i -z 76 76 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_38x38@2x.png
	@sips -i -z 114 114 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_38x38@3x.png
	@sips -i -z 80 80 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_40x40@2x.png
	@sips -i -z 120 120 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_40x40@3x.png
	@sips -i -z 120 120 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_60x60@2x.png
	@sips -i -z 180 180 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_60x60@3x.png
	@sips -i -z 128 128 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_64x64@2x.png
	@sips -i -z 192 192 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_64x64.png
	@sips -i -z 136 136 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_68x68@2x.png
	@sips -i -z 152 152 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_76x76@2x.png
	@sips -i -z 167 167 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_83.5x83.5@2x.png
	@sips -i -z 128 128 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_128x128.png
	@sips -i -z 256 256 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_128x128@2x.png
	@sips -i -z 256 256 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_256x256.png
	@sips -i -z 512 512 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_256x256@2x.png
	@sips -i -z 512 512 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_512x512.png
	@sips -i -z 1024 1024 artifacts/icon.png --out artifacts/AppIcon.iconset/icon_512x512@2x.png

pack_icon: gen_icon
	@iconutil -c icns artifacts/AppIcon.iconset

clean:
	@echo "🧹 Cleaning..."
	@-rm -rf CmdTab.app
	@-rm -rf *.dmg
	@-rm -rf artifacts/AppIcon.iconset
	@-rm -rf artifacts/AppIcon.icns
