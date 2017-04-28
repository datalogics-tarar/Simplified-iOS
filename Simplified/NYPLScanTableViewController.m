//
//  NYPLScanTableViewController.m
//  Simplified
//
//  Created by Aferdita Muriqi on 4/27/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

#import "NYPLScanTableViewController.h"
#import <ScanditBarcodeScanner/ScanditBarcodeScanner.h>

#define kScanditBarcodeScannerAppKey    @"######################"

@interface NYPLScanTableViewController () <SBSScanDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, nullable) SBSBarcodePicker *picker;
@property (nonatomic) UITextField *barcodeTextField;

@end

@implementation NYPLScanTableViewController

- (void)scanLibraryCard
{
  [SBSLicense setAppKey:kScanditBarcodeScannerAppKey];
  
  SBSScanSettings* settings = [SBSScanSettings defaultSettings];
  
  //By default, all symbologies are turned off so you need to explicity enable the desired simbologies.
  NSSet *symbologiesToEnable = [NSSet setWithObjects:
                                @(SBSSymbologyCodabar), nil];
  [settings enableSymbologies:symbologiesToEnable];
  
  
  // Some 1d barcode symbologies allow you to encode variable-length data. By default, the
  // Scandit BarcodeScanner SDK only scans barcodes in a certain length range. If your
  // application requires scanning of one of these symbologies, and the length is falling
  // outside the default range, you may need to adjust the "active symbol counts" for this
  // symbology. This is shown in the following 3 lines of code.
  
  SBSSymbologySettings *symSettings = [settings settingsForSymbology:SBSSymbologyCode39];
  symSettings.activeSymbolCounts =
  [NSSet setWithObjects:@7, @8, @9, @10, @11, @12, @13, @14, @15, @16, @17, @18, @19, @20, nil];
  // For details on defaults and how to calculate the symbol counts for each symbology, take
  // a look at http://docs.scandit.com/stable/c_api/symbologies.html.
  
  // Initialize the barcode picker - make sure you set the app key above
  self.picker = [[SBSBarcodePicker alloc] initWithSettings:settings];
  
  [self.picker.overlayController setTorchEnabled:NO];
  
  // only show camera switch button on tablets. For all other devices the switch button is
  // hidden, even if they have a front camera.
  [self.picker.overlayController setCameraSwitchVisibility:SBSCameraSwitchVisibilityOnTablet];
  // set the allowed interface orientations. The value UIInterfaceOrientationMaskAll is the
  // default and is only shown here for completeness.
  [self.picker setAllowedInterfaceOrientations:UIInterfaceOrientationMaskAll];
  // Set the delegate to receive scan event callbacks
  self.picker.scanDelegate = self;
  
  // Open the camera and start scanning barcodes
  [self.picker startScanning];
  
  UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:self.picker];
  UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissPicker)];
  self.picker.navigationItem.rightBarButtonItem = cancel;
  [self presentViewController:navController animated:YES completion:nil];
}


-(void)dismissPicker
{
  [self.picker dismissViewControllerAnimated:YES completion:nil];
}

//! [SBSScanDelegate callback]
/**
 * This delegate method of the SBSScanDelegate protocol needs to be implemented by
 * every app that uses the Scandit Barcode Scanner and this is where the custom application logic
 * goes. In the example below, we are just showing an alert view with the result.
 */
- (void)barcodePicker:(__unused SBSBarcodePicker *)thePicker didScan:(SBSScanSession *)session {
  
  // call stopScanning on the session to immediately stop scanning and close the camera. This
  // is the preferred way to stop scanning barcodes from the SBSScanDelegate as it is made sure
  // that no new codes are scanned. When calling stopScanning on the picker, another code may be
  // scanned before stopScanning has completely stoppen the scanning process.
  [session stopScanning];
  
  SBSCode *code = [session.newlyRecognizedCodes objectAtIndex:0];
  // the barcodePicker:didScan delegate method is invoked from a picker-internal queue. To display
  // the results in the UI, you need to dispatch to the main queue. Note that it's not allowed
  // to use SBSScanSession in the dispatched block as it's only allowed to access the
  // SBSScanSession inside the barcodePicker:didScan callback. It is however safe to use results
  // returned by session.newlyRecognizedCodes etc.
  dispatch_async(dispatch_get_main_queue(), ^{
    
    NSString *symbology = code.symbologyString;
    NSString *barcode = code.data;
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[NSString stringWithFormat:@"Scanned %@", symbology]
                          message:barcode
                          delegate:self
                          cancelButtonTitle:@"Done"
                          otherButtonTitles:@"Try Again", nil];
    [alert show];
    
    
  });
  
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  
  if (buttonIndex == 0)
  {
    [self.picker dismissViewControllerAnimated:YES completion:^{
      NSString *barcode = alertView.message;
      barcode = [barcode stringByReplacingOccurrencesOfString:@"A" withString:@""];
      barcode = [barcode stringByReplacingOccurrencesOfString:@"B" withString:@""];
      self.barcodeTextField.text = barcode;
    }];
  }
  else{
    [self.picker startScanning];
    
  }
}


@end
