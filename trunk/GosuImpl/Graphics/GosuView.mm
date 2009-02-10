#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <UIKit/UIKit.h>
#import "GosuView.h"

#include <Gosu/Graphics.hpp>
#include <Gosu/Window.hpp>

Gosu::Window& windowInstance();

namespace {
    Gosu::Touches translateTouches(NSSet* touches, UIView* view)
    {
        Gosu::Touches result;
        for (UITouch* touch in touches)
        {
            CGPoint point = [touch locationInView: view];
            Gosu::Touch touch = { point.y, [view bounds].size.width - point.x };
            result.push_back(touch);
        }
        return result;
    }
}

// A class extension to declare private methods
@interface GosuView ()

@property (nonatomic, retain) EAGLContext *context;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation GosuView

@synthesize context;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)drawView {
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    if (windowInstance().graphics().begin()) {
        windowInstance().draw();
        windowInstance().graphics().end();
    }
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer {
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

- (void)destroyFramebuffer {
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
}

- (void)dealloc {
    [EAGLContext setCurrentContext:nil];
    [context release];  
    [super dealloc];
}

// Direct forwarding of all touches to avoid more indirections.

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    windowInstance().touchesBegan(translateTouches(touches, self));
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    windowInstance().touchesMoved(translateTouches(touches, self));
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    windowInstance().touchesEnded(translateTouches(touches, self));
}

- (bool)isMultipleTouchEnabled {
    return YES;
}

- (bool)isExclusiveTouch {
    return YES;
}

@end