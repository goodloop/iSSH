
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

#import "MSController.h"



@implementation MSController

NSString * const processName = @"ssh";


- (void)awakeFromNib {
	bNeedReConnect = false;
	processId = -1;
	if([ self checkStatus ] == 0) {
		
		[ self setButtonsConnected ];
		[ self startErrorCheck];
		
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	
	if(flag == NO){
		[ mainWindow makeKeyAndOrderFront:nil ];
		
	}
	else {
		if([ mainWindow isVisible ] == NO) {
			[ mainWindow makeKeyAndOrderFront:nil ];
		}
	}
	
	return NO;
	
}

- (IBAction)openPreferences:(id)sender {
	
	[ preferencesWindow makeKeyAndOrderFront:nil ];
	
}
	
- (IBAction)loadSettings:(id)sender {
    
	defaults = [ NSUserDefaults standardUserDefaults ];
	[ remoteAddress setStringValue: [ defaults objectForKey: @"remoteAddress" ]];
	[ userName setStringValue: [ defaults objectForKey: @"userName" ]];
	[ portNumber setStringValue: [ defaults objectForKey: @"portNumber" ]];
	[ localPort setStringValue: [ defaults objectForKey: @"localPort" ]];
	[ remotePort setStringValue: [ defaults objectForKey: @"remotePort" ]];
	[ socksPort setStringValue: [ defaults objectForKey: @"socksPort" ]];
	
	if([[ EMKeychainProxy sharedProxy ] genericKeychainItemForService: @"iSSH" withUsername: @"MacServe" ] != nil) {
	[ passWord setStringValue: [[[ EMKeychainProxy sharedProxy ] genericKeychainItemForService: @"iSSH" withUsername: @"MacServe" ] password ]];
	}
	
}

- (IBAction)saveSettings:(id)sender {

	if([ self checkFields ] == 1) {
		return;
	}
	
    defaults = [ NSUserDefaults standardUserDefaults ];
	[ defaults setObject:[ remoteAddress stringValue ] forKey: @"remoteAddress" ];
	[ defaults setObject:[ userName stringValue ] forKey: @"userName" ];
	[ defaults setObject:[ portNumber stringValue ] forKey: @"portNumber" ];
	[ defaults setObject:[ localPort stringValue ] forKey: @"localPort" ];
	[ defaults setObject:[ remotePort stringValue ] forKey: @"remotePort" ];
	[ defaults setObject:[ socksPort stringValue ] forKey: @"socksPort" ];
	
	if([[ EMKeychainProxy sharedProxy ] genericKeychainItemForService: @"iSSH" withUsername: @"MacServe" ] == nil) {
		[[ EMKeychainProxy sharedProxy ] addGenericKeychainItemForService: @"iSSH" withUsername: @"MacServe" password: [ passWord stringValue ]];		
	}
	else {
		[[[ EMKeychainProxy sharedProxy ] genericKeychainItemForService: @"iSSH" withUsername: @"MacServe" ] setPassword: [ passWord stringValue ]];
	}
	
}

- (IBAction)startCon:(id)sender {
	bNeedReConnect = true;
    [ self launch ];
	
}

- (IBAction)stopCon:(id)sender {
	bNeedReConnect = false;
	[ self terminate ];
	
	[ self setButtonsDisconnected ];
	
}

- (IBAction)stopConQuit:(id)sender {
	bNeedReConnect = false;
	[ self terminate ];
    [ NSApp terminate: self ];
    
}

- (IBAction)isshHelp:(id)sender {
	
	[[ NSWorkspace sharedWorkspace ] openURL: [ NSURL URLWithString: @"http://www.macserve.org.uk/help/issh/"]];
	
}

- (void)startErrorCheck {
    timer = [ NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(errorCheck:) userInfo:nil repeats:YES ];
	[[ NSRunLoop currentRunLoop ] addTimer:timer forMode:NSDefaultRunLoopMode ];
}

- (void)launch {

	[ progIndicator startAnimation:progIndicator ];
	
	if([ self checkFields ] == 1) {
		return;
	}
	
	task = [[NSTask alloc] init];
	NSMutableDictionary *environment = [ NSMutableDictionary dictionaryWithDictionary: [[ NSProcessInfo processInfo ] environment ]];
    [ task setLaunchPath: @"/usr/bin/ssh"];
	
	[ environment removeObjectForKey:@"SSH_AGENT_PID" ];
	[ environment removeObjectForKey:@"SSH_AUTH_SOCK" ];
	[ environment setObject: [[ NSBundle mainBundle ] pathForResource: @"getPass" ofType: @"sh" ] forKey: @"SSH_ASKPASS" ];
	[ environment setObject: [ passWord stringValue ] forKey: @"PASS" ];
	[ environment setObject: @":0" forKey:@"DISPLAY" ];
	[ task setEnvironment: environment ];

    NSMutableArray *arguments = [ NSMutableArray array ];
	[ arguments addObject: @"-N" ];
	
	[ arguments addObject: [ NSString stringWithFormat: @"%@@%@", [ userName stringValue ], [ remoteAddress stringValue ] ] ];
	
	if([ portForward state ] == 1) {
	[ arguments addObject: @"-L" ];
	[ arguments addObject: [ NSString stringWithFormat: @"%@:localhost:%@", [ localPort stringValue ], [ remotePort stringValue ] ] ];
	NSLog(@"Forwarding port %@ on the local machine to port %@ on the remote machine", [ localPort stringValue ], [ remotePort stringValue ]);
	}
	else {
	[ arguments addObject: @"-D" ];
	[ arguments addObject: [ NSString stringWithFormat: @"localhost:%@", [ socksPort stringValue ] ] ];
	NSLog(@"SOCKS Proxy on port %@", [socksPort stringValue]);
	}
	
	[ arguments addObject: @"-p" ];
	if([[ portNumber stringValue ] isEqualToString:@"" ]) {
		[ arguments addObject: @"22" ];
		NSLog(@"Connecting on port 22");
	}
	else {
		
	[ arguments addObject: [ portNumber stringValue ] ];
	NSLog(@"Connecting on port %@", [ portNumber stringValue]);
	}
	
	[ arguments addObject: @"-F" ];
	[ arguments addObject: [[NSBundle mainBundle ] pathForResource: @"ssh_config" ofType: @"" ] ];
	
    [ task setArguments: arguments ];
	processId = -1;// reset processId
    [ task launch ];
	NSLog(@"Started Connection");
    
    [ self setButtonsConnected ];
	
	[ progIndicator stopAnimation:progIndicator ];
	
	[self startErrorCheck];

}


- (void)terminate {
	bNeedReConnect = false;
	if([ self checkStatus ] == 0) {
		
		[ process terminate ];
		NSLog(@"Connection closed");
		[ timer invalidate ];
		
	}

}

- (int)checkStatus {
	process = nil;
	if(processId == -1)
	{
		processEnumerator = [[ AGProcess allProcesses ] objectEnumerator ];
		//find ssh daemon process id for which we created
		while (process = [processEnumerator nextObject]) {
			NSString* name = [process command];
			NSArray* args = [process arguments];
			int arg_num = [args count];
			NSString* arg = nil;
			if ([processName isEqualToString:name]) {
				//process name  checked
				for(int i = 0; i < arg_num; i++)
				{
					arg = [args objectAtIndex:i];
					if([arg isEqualToString:@"-L"] || [arg isEqualToString:@"-D"])
					{
						// is a proxy deamon
						processId = [process processIdentifier];
						NSString*  parentName = [[process parent] command];
						return 0;
					}
				}
				
			}
		}
		return 1;	
	}
	else {
		//found processId before, so we just check if the process is there?
		process = [[AGProcess alloc] initWithProcessIdentifier:processId];
		if(nil == process)
		{
			//can't find the process now
			NSLog(@"checkStatus can't find daemon pid %d\n", __LINE__);
			return 1;
		}
		else {
			//re-check the name
			if ([processName isEqualToString:[process command]]) {
				return 0;
			}
			NSLog(@"checkStatus[%d] pid found, but process name wrong %s \n", __LINE__, [process command]);
			return 1;
		}
	}
	//something wrong?
	NSLog(@"checkStatus unexpect situation %d\n", __LINE__);
	return 1;
}

- (void)errorCheck:(NSTimer*)timerObj {
	
	if([ self checkStatus ] == 1) {
		
		[ self setButtonsDisconnected ];
		[ timerObj  invalidate ];
		if(bNeedReConnect)
		{
			NSLog(@"reconnect now!!\n");
			[self launch];
		}
		else {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[ alert addButtonWithTitle: @"OK" ];
			[ alert setMessageText: @"An error occurred" ];
			[ alert setInformativeText: @"Check you have entered the settings correctly and that the remote computer is set up correctly" ];
			[ alert setAlertStyle: NSWarningAlertStyle ];
			[ alert runModal ];
		}
	}
}

- (void)setButtonsConnected {
	
	[ startButton setEnabled:NO ];
	[ stopButton setEnabled:YES ];
	[ stopQuitButton setEnabled:YES ];
	
}

- (void)setButtonsDisconnected {
	
	[ startButton setEnabled:YES ];
	[ stopButton setEnabled:NO ];
	[ stopQuitButton setEnabled:NO ];
	
}

- (int)checkFields {
	
	if([[ remoteAddress stringValue ] isEqualToString:@"" ]) {
		NSRunAlertPanel(@"Settings Incomplete", [NSString stringWithFormat:@"You have not entered an Address"], @"Ok", nil, nil);
		[ progIndicator stopAnimation:progIndicator ];
		return 1;
	}
	
	if([[ userName stringValue ] isEqualToString:@"" ]) {
		NSRunAlertPanel(@"Settings Incomplete", [NSString stringWithFormat:@"You have not entered a User Name"], @"Ok", nil, nil);
		[ progIndicator stopAnimation:progIndicator ];
		return 1;
	}
	
	if([[ passWord stringValue ] isEqualToString:@"" ]) {
		NSRunAlertPanel(@"Settings Incomplete", [NSString stringWithFormat:@"You have not entered a Password"], @"Ok", nil, nil);
		[ progIndicator stopAnimation:progIndicator ];
		return 1;
	}
	
	if([ portForward state ] == 1) {
		if([[ localPort stringValue ] isEqualToString:@"" ] || [[ remotePort stringValue ] isEqualToString:@"" ]) {
			NSRunAlertPanel(@"Settings Incomplete", [NSString stringWithFormat:@"You have not entered a Port for forwarding"], @"Ok", nil, nil);
			[ progIndicator stopAnimation:progIndicator ];
			return 1;
		}
	}
	else {
		if([[ socksPort stringValue ] isEqualToString:@"" ]) {
			NSRunAlertPanel(@"Settings Incomplete", [NSString stringWithFormat:@"You have not entered a Port for the SOCKS Proxy"], @"Ok", nil, nil);
			[ progIndicator stopAnimation:progIndicator ];
			return 1;
		}
	}
	
	return 0;
	
}

@end
