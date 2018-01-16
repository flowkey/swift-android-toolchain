//===--- HeapObject.h -------------------------------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
#ifndef SWIFT_STDLIB_SHIMS_HEAPOBJECT_H
#define SWIFT_STDLIB_SHIMS_HEAPOBJECT_H

#include "RefCount.h"

#define SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_64 16
// TODO: Should be 8
#define SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_32 12

#ifdef __cplusplus
#include <type_traits>
#include "swift/Basic/type_traits.h"

namespace swift {

struct InProcess;

template <typename Target> struct TargetHeapMetadata;
using HeapMetadata = TargetHeapMetadata<InProcess>;
#else
typedef struct HeapMetadata HeapMetadata;
#endif

// The members of the HeapObject header that are not shared by a
// standard Objective-C instance
#define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS       \
  InlineRefCounts refCounts

/// The Swift heap-object header.
struct HeapObject {
  /// This is always a valid pointer to a metadata object.
  HeapMetadata const *metadata;

  SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS;
  // FIXME: allocate two words of metadata on 32-bit platforms

#ifdef __cplusplus
  HeapObject() = default;

  // Initialize a HeapObject header as appropriate for a newly-allocated object.
  constexpr HeapObject(HeapMetadata const *newMetadata) 
    : metadata(newMetadata)
    , refCounts(InlineRefCounts::Initialized)
  { }
#endif
};

#ifdef __cplusplus
extern "C" {
#endif

SWIFT_RUNTIME_STDLIB_INTERFACE
void _swift_instantiateInertHeapObject(void *address,
                                       const HeapMetadata *metadata);

#ifdef __cplusplus
} // extern "C"
#endif

#ifdef __cplusplus
static_assert(swift::IsTriviallyConstructible<HeapObject>::value,
              "HeapObject must be trivially initializable");
static_assert(std::is_trivially_destructible<HeapObject>::value,
              "HeapObject must be trivially destructible");

// FIXME: small header for 32-bit
//static_assert(sizeof(HeapObject) == 2*sizeof(void*),
//              "HeapObject must be two pointers long");
//
static_assert(sizeof(HeapObject) ==
  (sizeof(void*) == 8 ? SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_64 :
   sizeof(void*) == 4 ? SWIFT_ABI_HEAP_OBJECT_HEADER_SIZE_32 :
   0 && "unexpected pointer size"),
  "HeapObject must match ABI heap object header size");

static_assert(alignof(HeapObject) == alignof(void*),
              "HeapObject must be pointer-aligned");

} // end namespace swift
#endif

#endif
