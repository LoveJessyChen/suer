#import <Foundation/Foundation.h>

void usage() {
    printf("usage: suer [command]\n");
}

int main(int argc, const char **argv, const char **envp) {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getgid() != 0) {
        setgid(0);
    }

    NSMutableString *error = [[NSMutableString alloc] init];
    if (getuid() != 0 || geteuid() != 0){
        [error appendString:@"Can't set uid as 0.\n"];
    }
    if (getgid() != 0){
        [error appendString:@"Can't set gid as 0.\n"];
    }
    if (![error isEqual:@""]) {
        printf("%s\n", [error UTF8String]);
        return 1;
    }

    if (argc == 1) {
        usage();
        return 2;
    }

    NSMutableArray *args = [NSMutableArray array];
    for (int i = 1; i < argc; i++) {
        NSString *arg = [[NSString alloc] initWithUTF8String:argv[i]];
        if ([arg containsString:@" "] || [arg containsString:@"$"] || [arg containsString:@"`"] || [arg containsString:@"\""] || [arg containsString:@"'"] || [arg containsString:@"\\"] || [arg containsString:@"*"]) {
            NSMutableString *thisArg = [[NSMutableString alloc] init];
            for (int j = 0; j < [[NSNumber numberWithUnsignedInteger:[arg length]] intValue]; j++) {
                switch ([arg characterAtIndex:j]) {
                    case ' ':
                    case '`':
                        [thisArg appendString:@"\'"];
                        [thisArg appendFormat:@"%c", [arg characterAtIndex:j]];
                        [thisArg appendString:@"\'"];
                        break;
                    case '$':
                        [thisArg appendString:@"\'"];
                        [thisArg appendFormat:@"%c", [arg characterAtIndex:j]];
                        switch ([arg characterAtIndex:(j + 1)]) {
                            case '{':
                            case '(':
                                j++;
                                [thisArg appendFormat:@"%c", [arg characterAtIndex:j]];
                        }
                        [thisArg appendString:@"\'"];
                        break;
                    case '\"':
                    case '\'':
                    case '\\':
                    case '*':
                    case '(':
                    case ')':
                        [thisArg appendString:@"\\"];
                        [thisArg appendFormat:@"%c", [arg characterAtIndex:j]];
                        break;
                    default:
                        [thisArg appendFormat:@"%c", [arg characterAtIndex:j]];
                }
            }
            arg = [NSString stringWithFormat:@"%@", thisArg];
        }
        [args addObject:arg];
    }

    NSString *command = [args componentsJoinedByString:@" "];

    int status = system([command UTF8String]);
    return WEXITSTATUS(status);
}
