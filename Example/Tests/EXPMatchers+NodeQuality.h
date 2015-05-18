#import <Expecta/Expecta.h>

EXPMatcherInterface(_haveNodeIds, (id expected));
EXPMatcherInterface(haveNodeIds, (id expected)); // to aid code completion
#define haveNodeIds(...) _haveNodeIds(EXPObjectify((@[__VA_ARGS__])))
