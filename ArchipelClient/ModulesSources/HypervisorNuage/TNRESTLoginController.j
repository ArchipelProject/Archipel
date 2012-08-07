@import <Foundation/CPURLConnection.j>


var DefaultTNRESTLoginController;

@implementation TNRESTLoginController : CPObject
{
    CPString _user      @accessors(property=user);
    CPString _password  @accessors(property=password);
    CPString _URL       @accessors(property=URL);
}

+ (TNRESTLoginController)defaultController
{
    if (!DefaultTNRESTLoginController)
        DefaultTNRESTLoginController = [[TNRESTLoginController alloc] init];
    return DefaultTNRESTLoginController;
}

- (CPString)authString
{
    var token = @"Basic " + btoa([CPString stringWithFormat:@"%s:%s", _user, _password]);
    return token;
}


@end
