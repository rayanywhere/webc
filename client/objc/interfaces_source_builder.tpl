#import "WebcInterfaces.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@interface <%$server->namespace|strtoupper%>Client()
+ (NSData *)_call:(NSString*)interface withRequest:(NSData*)request;
@end

@implementation <%$server->namespace|strtoupper%>Client

+ (NSData *)_call:(NSString*)interface withRequest:(NSData*)request
{
	ASIFormDataRequest *asiRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"<%$server->protocol%>://<%$server->host%>:<%$server->port%>/%@", interface]]];
	asiRequest.postBody = [NSMutableData dataWithData:request];
	asiRequest.postLength = request.length;
	asiRequest.timeOutSeconds = 30.0f;
	asiRequest.cachePolicy = ASIDoNotWriteToCacheCachePolicy|ASIDoNotReadFromCacheCachePolicy;
	[asiRequest startSynchronous];
	if ([asiRequest error]) {
		return nil;
	}
	return asiRequest.responseData;
}

+ (void)_invoke:(NSString*)interface withRequest:(NSData*)request withResponseCallback:(void (^)(NSData* response))responseBlock
{
	__block ASIFormDataRequest *asiRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"<%$server->protocol%>://<%$server->host%>:<%$server->port%>/%@", interface]]];
	asiRequest.postBody = [NSMutableData dataWithData:request];
	asiRequest.postLength = request.length;
	asiRequest.timeOutSeconds = 30.0f;
	asiRequest.cachePolicy = ASIDoNotWriteToCacheCachePolicy|ASIDoNotReadFromCacheCachePolicy;
	[asiRequest setCompletionBlock:^{
		responseBlock(asiRequest.responseData);
	}];
	[asiRequest setFailedBlock:^{
		responseBlock(nil);
	}];
	[asiRequest startAsynchronous];
}

<%foreach $interfaces as $interface%>
+ (<%$server->namespace|strtoupper%>Error*)call<%$interface->name|webc_name2camel%>:(<%$server->namespace|strtoupper%>Struct<%$interface->request|webc_name2camel%>*)request withResponse:(<%$server->namespace|strtoupper%>Struct<%$interface->response|webc_name2camel%>**)response;
{
	NSData *responseData = [<%$server->namespace|strtoupper%>Client _call:@"<%$interface->name%>" withRequest:[[request toJSONString] dataUsingEncoding:NSUTF8StringEncoding]];
	if(!responseData)
		return [[<%$server->namespace|strtoupper%>Error alloc] initWithResult:-1 withMessage:@"network failure"];


	NSError* error = nil;
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
	if (json == nil)
		return [[<%$server->namespace|strtoupper%>Error alloc] initWithResult:-1 withMessage:@"bad data"];

	NSInteger result = [[json objectForKey:@"result"] integerValue];

	if(result != 0)
		return [[<%$server->namespace|strtoupper%>Error alloc] initWithResult:-1 withMessage:nil];

	*response = [[<%$server->namespace|strtoupper%>Struct<%$interface->response|webc_name2camel%> alloc] initWithData:responseData error:&error];
	if(error || !response)
		return [[<%$server->namespace|strtoupper%>Error alloc] initWithResult:-1 withMessage:@"bad data"];

	return [[<%$server->namespace|strtoupper%>Error alloc] initWithResult:0 withMessage:nil];
}
<%/foreach%>

<%foreach $interfaces as $interface%>
+ (void)invoke<%$interface->name|webc_name2camel%>:(<%$server->namespace|strtoupper%>Struct<%$interface->request|webc_name2camel%>*)request withResponseCallback:(void (^)(<%$server->namespace|strtoupper%>Struct<%$interface->response|webc_name2camel%>* response))responseBlock
{
	[<%$server->namespace|strtoupper%>Client _invoke:@"<%$interface->name%>" withRequest:[[request toJSONString] dataUsingEncoding:NSUTF8StringEncoding] withResponseCallback:^(NSData* responseData){
		if(!responseData){
			responseBlock(nil);
			return;
		}

		NSError* error = nil;
		<%$server->namespace|strtoupper%>Struct<%$interface->response|webc_name2camel%>* response = [[<%$server->namespace|strtoupper%>Struct<%$interface->response|webc_name2camel%> alloc] initWithData:responseData error:&error];
		if(error || !response){
			responseBlock(nil);
			return;
		}

		responseBlock(response);
	}];
}
<%/foreach%>

@end
