APP_NAME    = DropShelf
BUNDLE_ID   = com.personal.dropshelf
BUILD_DIR   = .build
APP_BUNDLE  = $(BUILD_DIR)/$(APP_NAME).app
BINARY      = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
INFO_PLIST  = $(APP_BUNDLE)/Contents/Info.plist

SOURCES := $(shell find DropShelf -name "*.swift" | sort)

ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
  TARGET = arm64-apple-macos13.0
else
  TARGET = x86_64-apple-macos13.0
endif

SWIFTFLAGS = \
  -target $(TARGET) \
  -framework AppKit \
  -framework Foundation \
  -framework QuartzCore \
  -framework ServiceManagement \
  -O

.PHONY: build clean install run

build: $(APP_BUNDLE)

$(APP_BUNDLE): $(SOURCES) DropShelf/Resources/Info.plist
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	swiftc $(SOURCES) -o $(BINARY) $(SWIFTFLAGS)
	cp DropShelf/Resources/Info.plist $(INFO_PLIST)
	cp DropShelf/Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	codesign -s - $(APP_BUNDLE) 2>/dev/null || true
	@echo "✓ Built $(APP_BUNDLE)"

run: build
	open $(APP_BUNDLE)

install: build
	rm -rf /Applications/$(APP_NAME).app
	cp -r $(APP_BUNDLE) /Applications/$(APP_NAME).app
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

clean:
	rm -rf $(BUILD_DIR)
