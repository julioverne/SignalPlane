#import <objc/runtime.h>
#import <notify.h>
#import <Security/Security.h>
#import <AudioToolbox/AudioToolbox.h>
#import <substrate.h>
#import "Tweak.h"

#define NSLog(...)


static BOOL Enabled;
static BOOL ForceWiFi;
static BOOL ForceBT;
static BOOL Vibrate;
static BOOL isInProgress;

static int Delay;
static int Percentage;





static BOOL canSystemSleep;
static float intervalCheck;
static io_connect_t gRootPort = MACH_PORT_NULL;
static io_object_t notifier;
static NSTimeInterval sheduleCreationTimeStamp;

static void updateTimer(int afterSeconds)
{
	@try {
		float updatedInterval;
		@autoreleasepool {
			NSTimeInterval timeStampNow = [[NSDate date] timeIntervalSince1970];
			updatedInterval = (float)((sheduleCreationTimeStamp-timeStampNow)+afterSeconds);
			NSLog(@"*** updateTimer() timer adjusted to %f", updatedInterval);
		}
		[NSObject cancelPreviousPerformRequestsWithTarget:[%c(SignalPlaneCheck) shared] selector:@selector(enableAirplaneForCheck) object:nil];
		[[%c(SignalPlaneCheck) shared] performSelector:@selector(enableAirplaneForCheck) withObject:nil afterDelay:updatedInterval];
	}@catch (NSException * e) {
		updateTimer(afterSeconds);
	}
}
static void sheduleWakeAndCheckAfterSeconds(int afterSeconds)
{
	@try {
		@autoreleasepool {
			NSArray* eventsArray = [(__bridge NSArray*)IOPMCopyScheduledPowerEvents()?:@[] copy];
			for(NSDictionary* shEventNow in eventsArray) {
				if(CFStringRef scheduledbyID = (__bridge CFStringRef)shEventNow[@"scheduledby"]) {
					if([[NSString stringWithFormat:@"%@", scheduledbyID] isEqualToString:@"com.julioverne.signalplane"]) {
						IOPMCancelScheduledPowerEvent((__bridge CFDateRef)shEventNow[@"time"], (__bridge CFStringRef)shEventNow[@"scheduledby"], (__bridge CFStringRef)shEventNow[@"eventtype"]);
					}
				}
			}
		}
		NSDate *wakeTime = [[NSDate date] dateByAddingTimeInterval:(afterSeconds - 10)];
		IOPMSchedulePowerEvent((__bridge CFDateRef)wakeTime, CFSTR("com.julioverne.signalplane"), CFSTR(kIOPMAutoWake));
		sheduleCreationTimeStamp = [[NSDate date] timeIntervalSince1970];
		updateTimer(afterSeconds);
	}@catch (NSException * e) {
		sheduleWakeAndCheckAfterSeconds(afterSeconds);
	}
}
static BOOL isPendingSchedule()
{
	BOOL ret = NO;
	@try {
		@autoreleasepool {
			NSArray* eventsArray = [(__bridge NSArray*)IOPMCopyScheduledPowerEvents()?:@[] copy];
			for(NSDictionary* shEventNow in eventsArray) {
				if(CFStringRef scheduledbyID = (__bridge CFStringRef)shEventNow[@"scheduledby"]) {
					if([[NSString stringWithFormat:@"%@", scheduledbyID] isEqualToString:@"com.julioverne.signalplane"]) {
						ret = YES;
						break;
					}
				}
			}
		}
	}@catch (NSException * e) {
		return isPendingSchedule();
	}
	return ret;
}










static long int getBarsSignal()
{
	long int raw = 0;
	long int graded = 0;
	long int bars = 0;
	CTIndicatorsGetSignalStrength(&raw, &graded, &bars);
	/*if(bars == 1) {
		@autoreleasepool {
			CTTelephonyNetworkInfo* info = [[CTTelephonyNetworkInfo alloc] init];
			CTCarrier* carrier = info.subscriberCellularProvider;
			if(carrier.mobileNetworkCode == nil || [carrier.mobileNetworkCode isEqualToString:@""]) {
				bars = 0;
			}
		}
	}*/
	NSLog(@"*** [SignalPlane]: raw[%ld] graded[%ld] bars[%ld]", raw, graded, bars);
	return bars;
}

static BOOL ignoreForCall()
{
	SBTelephonyManager* sharTel = [%c(SBTelephonyManager) sharedTelephonyManager];
	if([sharTel activeCallExists] || [sharTel incomingCallExists] || [sharTel heldCallExists]) {
		return YES;
	}
	return NO;
}

static void SignalStrengthDidChange(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:[%c(SignalPlaneCheck) shared] selector:@selector(checkSignal) object:nil];
	[[%c(SignalPlaneCheck) shared] performSelector:@selector(checkSignal) withObject:nil afterDelay:0.1f];
}

static void settingsChangedSignalPlane(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		NSDictionary *Prefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:@{} copy];
		Enabled = (BOOL)[Prefs[@"Enabled"]?:@YES boolValue];
		Percentage = (int)[Prefs[@"Percentage"]?:@(1) intValue];
		Delay = (int)[Prefs[@"Delay"]?:@(10) intValue];
		ForceWiFi = (BOOL)[Prefs[@"ForceWiFi"]?:@YES boolValue];
		ForceBT = (BOOL)[Prefs[@"ForceBT"]?:@NO boolValue];
		intervalCheck = (float)[Prefs[@"CheckMin"]?:@(60*5) floatValue];
		Vibrate = (BOOL)[Prefs[@"Vibrate"]?:@NO boolValue];
		sheduleWakeAndCheckAfterSeconds(intervalCheck);
	}
}




static void HandlePowerManagerEvent(void *inContext, io_service_t inIOService, natural_t inMessageType, void *inMessageArgument)
{
    if(inMessageType == kIOMessageSystemWillSleep) {
		IOAllowPowerChange(gRootPort, (long)inMessageArgument);
		NSLog(@"*** kIOMessageSystemWillSleep");
	} else if(inMessageType == kIOMessageCanSystemSleep) {
		if(canSystemSleep) {
			IOAllowPowerChange(gRootPort, (long)inMessageArgument);
		} else {
			IOCancelPowerChange(gRootPort, (long)inMessageArgument);
		}
		NSLog(@"*** kIOMessageCanSystemSleep %@", @(canSystemSleep));
	} else if(inMessageType == kIOMessageSystemHasPoweredOn) {
		NSLog(@"*** kIOMessageSystemHasPoweredOn");
		if(!Enabled || intervalCheck<=0) {
			canSystemSleep = YES;
			return;
		}
		if(!isPendingSchedule()) {
			canSystemSleep = NO;
			//sheduleWakeAndCheckAfterSeconds(intervalCheck);
		}
		updateTimer(intervalCheck);
	}
}
static void preventSystemSleep()
{
	IONotificationPortRef notify;
	gRootPort = IORegisterForSystemPower(NULL, &notify, HandlePowerManagerEvent, &notifier);
    if(gRootPort == MACH_PORT_NULL) {
        NSLog (@"IORegisterForSystemPower failed.");
    } else {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notify), kCFRunLoopDefaultMode);
    }
}



@implementation SignalPlaneCheck
+ (id)shared
{
	static __strong SignalPlaneCheck* SignalPlaneCheckC;
	if(!SignalPlaneCheckC) {
		SignalPlaneCheckC = [[[self class] alloc] init];
	}
	return SignalPlaneCheckC;
}
- (void)enableAirplaneForCheck
{
	canSystemSleep = NO;
	NSLog(@"*** [SignalPlane]: Airplane OFF For Re-Check");
	if(((SBAirplaneModeController*)[%c(SBAirplaneModeController) sharedInstance]).inAirplaneMode) {
		((SBAirplaneModeController*)[%c(SBAirplaneModeController) sharedInstance]).inAirplaneMode = NO;
	}
	//SignalStrengthDidChange(NULL, NULL, NULL, NULL, NULL);
}
- (void)checkSignal
{
	if(Enabled && (getBarsSignal()<=Percentage) /*&& !isInProgress*/) {
		isInProgress = YES;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			if(!ignoreForCall() && (getBarsSignal()<=Percentage) && !((SBAirplaneModeController*)[%c(SBAirplaneModeController) sharedInstance]).inAirplaneMode){
				[NSObject cancelPreviousPerformRequestsWithTarget:[%c(SignalPlaneCheck) shared] selector:@selector(airPlaneMode) object:nil];
				[[%c(SignalPlaneCheck) shared] performSelector:@selector(airPlaneMode) withObject:nil afterDelay:0.2f];
			}
			isInProgress = NO;
		});
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:[%c(SignalPlaneCheck) shared] selector:@selector(systemCanSleepNow) object:nil];
	[[%c(SignalPlaneCheck) shared] performSelector:@selector(systemCanSleepNow) withObject:nil afterDelay:Delay+10];
}
- (void)airPlaneMode
{
	BOOL wifi = ((SBWiFiManager*)[%c(SBWiFiManager) sharedInstance]).wiFiEnabled;
	BOOL bluetooth = ((BluetoothManager*)[%c(BluetoothManager) sharedInstance]).enabled;
	BOOL bluetoothPower = ((BluetoothManager*)[%c(BluetoothManager) sharedInstance]).powered;
	((SBAirplaneModeController*)[%c(SBAirplaneModeController) sharedInstance]).inAirplaneMode = YES;
	if(Vibrate) {
		AudioServicesPlaySystemSound(1352);
	}
	((SBWiFiManager*)[%c(SBWiFiManager) sharedInstance]).wiFiEnabled = ForceWiFi?YES:wifi;
	((BluetoothManager*)[%c(BluetoothManager) sharedInstance]).powered = ForceBT?YES:bluetooth&&bluetoothPower;	
}
- (void)systemCanSleepNow
{
	if(Enabled && intervalCheck>0) {
		sheduleWakeAndCheckAfterSeconds(intervalCheck);
	}
	canSystemSleep = YES;
}
@end


%ctor
{
	@autoreleasepool {
		
		canSystemSleep = YES;
		preventSystemSleep();
		
		dlopen("/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager", RTLD_LAZY);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChangedSignalPlane, CFSTR("com.julioverne.signalplane/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CTTelephonyCenterAddObserver(CTTelephonyCenterGetDefault(), NULL, SignalStrengthDidChange, kCTIndicatorsSignalStrengthNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
		settingsChangedSignalPlane(NULL, NULL, NULL, NULL, NULL);
	}
}
