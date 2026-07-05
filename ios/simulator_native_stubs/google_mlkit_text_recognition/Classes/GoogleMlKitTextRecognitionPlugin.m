#import "GoogleMlKitTextRecognitionPlugin.h"

#define channelName @"google_mlkit_text_recognizer"
#define startTextRecognizer @"vision#startTextRecognizer"
#define closeTextRecognizer @"vision#closeTextRecognizer"

@implementation GoogleMlKitTextRecognitionPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:channelName
            binaryMessenger:[registrar messenger]];
  GoogleMlKitTextRecognitionPlugin* instance = [[GoogleMlKitTextRecognitionPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:closeTextRecognizer]) {
    result(nil);
    return;
  }

  result([FlutterError errorWithCode:@"MLKIT_SIMULATOR"
                             message:@"Text recognition is unavailable on the iOS simulator. Use a physical device."
                             details:call.method]);
}

@end
