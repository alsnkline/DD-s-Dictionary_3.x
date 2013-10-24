/*
 C implementation of double_metaphone found at http://aspell.net/metaphone/
 various tweeks:
 rename classes http://stackoverflow.com/questions/525609/use-c-with-cocoa-instead-of-objective-c
 moved to single variables between C and objective C http://stackoverflow.com/questions/16552961/bad-exception-after-using-a-c-class-in-ios
 changed the char * into const char * as per http://stackoverflow.com/questions/1524356/c-deprecated-conversion-from-string-constant-to-char?lq=1
*/

#ifndef DOUBLE_METAPHONE__H
#define DOUBLE_METAPHONE__H


typedef struct
{
    char *str;
    int length;
    int bufsize;
    int free_string_on_destroy;
}
metastring;      


#ifdef __cplusplus  //putting extern "C" declaration of the method so it can be called by Obj C classes http://stackoverflow.com/questions/4456239/calling-c-method-from-objective-c
extern "C" {
#endif

void
    DoubleMetaphone(const char *str,
                char **primarycode, char **secondarycode);

#ifdef __cplusplus
}
#endif
    
#endif /* DOUBLE_METAPHONE__H */
