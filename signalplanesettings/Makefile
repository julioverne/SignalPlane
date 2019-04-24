include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SignalPlaneSettings
SignalPlaneSettings_FILES = /mnt/d/codes/signalplane/signalplanesettings/SignalPlaneSettingsController.mm
SignalPlaneSettings_INSTALL_PATH = /Library/PreferenceBundles
SignalPlaneSettings_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter
SignalPlaneSettings_PRIVATE_FRAMEWORKS = Preferences
SignalPlaneSettings_CFLAGS = -fobjc-arc
SignalPlaneSettings_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/bundle.mk

all::
