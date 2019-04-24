#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.signalplane.plist"

extern "C" CFStringRef kCTIndicatorsSignalStrengthNotification;
extern "C" void CTIndicatorsGetSignalStrength(long int *raw, long int *graded, long int *bars);
extern "C" CFNotificationCenterRef CTTelephonyCenterGetDefault();
extern "C" void CTTelephonyCenterAddObserver(CFNotificationCenterRef center, const void *observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior);

extern "C" int CTGetSignalStrength();

@interface CTCarrier : NSObject
@property (nonatomic, retain) NSString *carrierName;
@property (nonatomic, retain) NSString *isoCountryCode;
@property (nonatomic, retain) NSString *mobileCountryCode;
@property (nonatomic, retain) NSString *mobileNetworkCode;
@end

@interface CTTelephonyNetworkInfo : NSObject
@property (retain) CTCarrier *subscriberCellularProvider;
@end

@interface SBAirplaneModeController : NSObject
@property (assign,getter=isInAirplaneMode,nonatomic) BOOL inAirplaneMode;
+(id)sharedInstance;
-(void)airplaneModeChanged;
@end

@interface SBWiFiManager : NSObject
@property (assign) BOOL wiFiEnabled;
+(id)sharedInstance;
@end

@interface BluetoothManager
@property (assign) BOOL powered;
@property (assign) BOOL enabled;
+ (id)sharedInstance;
@end

@interface SBTelephonyManager : NSObject
+(id)sharedTelephonyManager;
-(void)airplaneModeDidChange:(BOOL)arg1 ;
-(BOOL)activeCallExists;
-(BOOL)incomingCallExists;
-(BOOL)heldCallExists;
-(int)signalStrengthBars;
@end

@interface SignalPlaneCheck : NSObject
+ (id)shared;
- (void)enableAirplaneForCheck;
@end


#import <IOKit/IOKitLib.h>

extern "C" io_connect_t IORegisterForSystemPower(void * refcon, IONotificationPortRef * thePortRef, IOServiceInterestCallback callback, io_object_t * notifier );
extern "C" IOReturn IOAllowPowerChange( io_connect_t kernelPort, long notificationID );
extern "C" IOReturn IOCancelPowerChange(io_connect_t kernelPort, intptr_t notificationID);
extern "C" IOReturn IOPMSchedulePowerEvent(CFDateRef time_to_wake, CFStringRef my_id, CFStringRef type);
extern "C" IOReturn IOPMCancelScheduledPowerEvent(CFDateRef time_to_wake, CFStringRef my_id, CFStringRef type);
extern "C" IOReturn IODeregisterForSystemPower ( io_object_t * notifier );
extern "C" CFArrayRef IOPMCopyScheduledPowerEvents(void);

typedef uint32_t IOPMAssertionLevel;
typedef uint32_t IOPMAssertionID;
extern "C" IOReturn IOPMAssertionCreateWithName(CFStringRef AssertionType,IOPMAssertionLevel AssertionLevel, CFStringRef AssertionName, IOPMAssertionID *AssertionID);
extern "C" IOReturn IOPMAssertionRelease(IOPMAssertionID AssertionID);
#define iokit_common_msg(message)          (UInt32)(sys_iokit|sub_iokit_common|message)
#define kIOMessageCanSystemPowerOff iokit_common_msg( 0x240)
#define kIOMessageSystemWillPowerOff iokit_common_msg( 0x250) 
#define kIOMessageSystemWillNotPowerOff iokit_common_msg( 0x260)
#define kIOMessageCanSystemSleep iokit_common_msg( 0x270) 
#define kIOMessageSystemWillSleep iokit_common_msg( 0x280) 
#define kIOMessageSystemWillNotSleep iokit_common_msg( 0x290) 
#define kIOMessageSystemHasPoweredOn iokit_common_msg( 0x300) 
#define kIOMessageSystemWillRestart iokit_common_msg( 0x310) 
#define kIOMessageSystemWillPowerOn iokit_common_msg( 0x320)

#define kIOPMAutoPowerOn "poweron" 
#define kIOPMAutoShutdown "shutdown" 
#define kIOPMAutoSleep "sleep"
#define kIOPMAutoWake "wake"
#define kIOPMAutoWakeOrPowerOn "wakepoweron"
