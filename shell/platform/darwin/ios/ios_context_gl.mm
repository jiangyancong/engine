// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_context_gl.h"

#import <OpenGLES/EAGL.h>

#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"

namespace flutter {

IOSContextGL::IOSContextGL() {
  resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]);
  if (resource_context_ != nullptr) {
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3
                                         sharegroup:resource_context_.get().sharegroup]);
  } else {
    resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]);
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                         sharegroup:resource_context_.get().sharegroup]);
  }
}

IOSContextGL::~IOSContextGL() = default;

std::unique_ptr<IOSRenderTargetGL> IOSContextGL::CreateRenderTarget(
    fml::scoped_nsobject<CAEAGLLayer> layer) {
  return std::make_unique<IOSRenderTargetGL>(std::move(layer), context_, resource_context_);
}

// |IOSContext|
sk_sp<GrContext> IOSContextGL::CreateResourceContext() {
  // TODO(chinmaygarde): Now that this is here, can ResourceMakeCurrent be removed?
  if (![EAGLContext setCurrentContext:resource_context_.get()]) {
    FML_DLOG(INFO) << "Could not make resource context current on IO thread. Async texture uploads "
                      "will be disabled. On Simulators, this is expected.";
    return nullptr;
  }

  return ShellIOManager::CreateCompatibleResourceLoadingContext(
      GrBackend::kOpenGL_GrBackend, GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface());
}

// |IOSContext|
bool IOSContextGL::MakeCurrent() {
  return [EAGLContext setCurrentContext:context_.get()];
}

// |IOSContext|
bool IOSContextGL::ResourceMakeCurrent() {
  return [EAGLContext setCurrentContext:resource_context_.get()];
}

// |IOSContext|
bool IOSContextGL::ClearCurrent() {
  return [EAGLContext setCurrentContext:nil];
}

}  // namespace flutter
