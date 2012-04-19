
/*
 
 Copyright (c) 2008, Alex Jones
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:
 
	1.	Redistributions of source code must retain the above copyright notice, this list of conditions and the
		following disclaimer.
 
	2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
		the following disclaimer in the documentation and/or other materials provided with the distribution.
 
	3.	Neither the name of MacServe nor the names of its contributors may be used to endorse
		or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <Cocoa/Cocoa.h>
#import <AGProcess/AGProcess.h>
#import <EMKeychainProxy.h>
#import <EMKeychainItem.h>

@interface MSController : NSObject {
	
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSWindow *preferencesWindow;
    IBOutlet NSTextField *localPort;
    IBOutlet NSTextField *portNumber;
	IBOutlet NSSecureTextField *passWord;
    IBOutlet NSProgressIndicator *progIndicator;
    IBOutlet NSTextField *remoteAddress;
    IBOutlet NSTextField *remotePort;
    IBOutlet NSTextField *socksPort;
    IBOutlet NSButtonCell *portForward;
    IBOutlet NSButton *startButton;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *stopQuitButton;
    IBOutlet NSTextField *userName;
	NSTask *task;
	AGProcess *process;
	NSEnumerator *processEnumerator;
	bool running;
	NSTimer *timer;
	NSUserDefaults *defaults;

}


- (IBAction)loadSettings:(id)sender;
- (IBAction)saveSettings:(id)sender;
- (IBAction)startCon:(id)sender;
- (IBAction)stopCon:(id)sender;
- (IBAction)stopConQuit:(id)sender;
- (IBAction)isshHelp:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (void)launch;
- (void)terminate;
- (int)checkStatus;
- (void)errorCheck:(NSTimer*)timer;
- (void)setButtonsConnected;
- (void)setButtonsDisconnected;
- (int)checkFields;
@end
