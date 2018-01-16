/*	ForFoundationOnly.h
	Copyright (c) 1998-2016, Apple Inc. and the Swift project authors
 
	Portions Copyright (c) 2014-2016 Apple Inc. and the Swift project authors
	Licensed under Apache License v2.0 with Runtime Library Exception
	See http://swift.org/LICENSE.txt for license information
	See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

// The header file ForFoundationOnly.h is for the exclusive use of the
// CoreFoundation and Foundation projects.  No other project should include it.

#if !defined(__COREFOUNDATION_FORFOUNDATIONONLY__)
#define __COREFOUNDATION_FORFOUNDATIONONLY__ 1

#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFDictionary.h>
#include <CoreFoundation/CFSet.h>
#include <CoreFoundation/CFPriv.h>
#include <CoreFoundation/CFPropertyList.h>
#include <CoreFoundation/CFError.h>
#include <CoreFoundation/CFStringEncodingExt.h>
#include <CoreFoundation/CFNumberFormatter.h>
#include <CoreFoundation/CFBag.h>
#include <CoreFoundation/CFCalendar.h>
#include <CoreFoundation/CFStreamPriv.h>
#include <math.h>
#include <limits.h>

#ifndef CF_SWIFT_EXPORT
#if DEPLOYMENT_RUNTIME_SWIFT
#define CF_SWIFT_EXPORT extern
#else
#define CF_SWIFT_EXPORT static __attribute__((used))
#endif
#endif

#define _CF_EXPORT_SCOPE_BEGIN \
CF_EXTERN_C_BEGIN \
CF_ASSUME_NONNULL_BEGIN \
CF_IMPLICIT_BRIDGING_ENABLED


#define _CF_EXPORT_SCOPE_END \
CF_EXTERN_C_END \
CF_ASSUME_NONNULL_END \
CF_IMPLICIT_BRIDGING_DISABLED

// NOTE: miscellaneous declarations are at the end

// ---- CFRuntime material ----------------------------------------

#if DEPLOYMENT_TARGET_LINUX
#include <malloc.h>
#elif DEPLOYMENT_TARGET_FREEBSD
#include <stdlib.h> // malloc()
#elif DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
#include <malloc/malloc.h>
#include <mach/mach_time.h>
#endif

#if (INCLUDE_OBJC || DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_WINDOWS) && !DEPLOYMENT_RUNTIME_SWIFT
#include <objc/message.h>
#endif

// ---- CFBundle material ----------------------------------------

#include <CoreFoundation/CFBundlePriv.h>

_CF_EXPORT_SCOPE_BEGIN

CF_EXPORT const CFStringRef _kCFBundleExecutablePathKey;
CF_EXPORT const CFStringRef _kCFBundleInfoPlistURLKey;
CF_EXPORT const CFStringRef _kCFBundleRawInfoPlistURLKey;
CF_EXPORT const CFStringRef _kCFBundleNumericVersionKey;
CF_EXPORT const CFStringRef _kCFBundleResourcesFileMappedKey;
CF_EXPORT const CFStringRef _kCFBundleAllowMixedLocalizationsKey;
CF_EXPORT const CFStringRef _kCFBundleInitialPathKey;
CF_EXPORT const CFStringRef _kCFBundleResolvedPathKey;
CF_EXPORT const CFStringRef _kCFBundlePrincipalClassKey;

#if __BLOCKS__
CF_EXPORT CFTypeRef _CFBundleCopyFindResources(CFBundleRef _Nullable bundle, CFURLRef _Nullable bundleURL, CFArrayRef _Nullable _unused_pass_null_, CFStringRef _Nullable resourceName, CFStringRef _Nullable resourceType, CFStringRef _Nullable subPath, CFStringRef _Nullable lproj, Boolean returnArray, Boolean localized, Boolean (^_Nullable predicate)(CFStringRef filename, Boolean *_Nullable stop));
#endif

CF_EXPORT Boolean _CFBundleLoadExecutableAndReturnError(CFBundleRef bundle, Boolean forceGlobal, CFErrorRef *error);
CF_EXPORT CFErrorRef _CFBundleCreateError(CFAllocatorRef _Nullable allocator, CFBundleRef bundle, CFIndex code);

_CF_EXPORT_SCOPE_END


// ---- CFPreferences material ----------------------------------------

#define DEBUG_PREFERENCES_MEMORY 0
 
#if DEBUG_PREFERENCES_MEMORY
#include "../Tests/CFCountingAllocator.h"
#endif

_CF_EXPORT_SCOPE_BEGIN

extern void _CFPreferencesPurgeDomainCache(void);

typedef struct {
    void *_Null_unspecified 	(*_Null_unspecified createDomain)(CFAllocatorRef _Nullable allocator, CFTypeRef context);
    void	(*_Null_unspecified freeDomain)(CFAllocatorRef _Nullable allocator, CFTypeRef context, void *domain);
    CFTypeRef _Null_unspecified 	(*_Null_unspecified fetchValue)(CFTypeRef context, void *domain, CFStringRef key); // Caller releases
    void	(*_Null_unspecified writeValue)(CFTypeRef context, void *domain, CFStringRef key, CFTypeRef value);
    Boolean	(*_Null_unspecified synchronize)(CFTypeRef context, void *domain);
    void	(*_Null_unspecified getKeysAndValues)(CFAllocatorRef _Nullable alloc, CFTypeRef context, void *domain, void *_Null_unspecified * _Null_unspecified buf[], CFIndex *numKeyValuePairs);
    CFDictionaryRef _Null_unspecified  (*_Null_unspecified copyDomainDictionary)(CFTypeRef context, void *domain);
    /* HACK - see comment on _CFPreferencesDomainSetIsWorldReadable(), below */
    void	(*setIsWorldReadable)(CFTypeRef context, void *domain, Boolean isWorldReadable);
} _CFPreferencesDomainCallBacks;

CF_EXPORT CFAllocatorRef __CFPreferencesAllocator(void);
CF_EXPORT  const _CFPreferencesDomainCallBacks __kCFVolatileDomainCallBacks;
CF_EXPORT const _CFPreferencesDomainCallBacks __kCFXMLPropertyListDomainCallBacks;

typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFPreferencesDomain * CFPreferencesDomainRef;

CF_EXPORT CFPreferencesDomainRef _CFPreferencesDomainCreate(CFTypeRef context, const _CFPreferencesDomainCallBacks *callBacks);
CF_EXPORT CFPreferencesDomainRef _CFPreferencesStandardDomain(CFStringRef domainName, CFStringRef userName, CFStringRef hostName);

CF_EXPORT CFTypeRef _CFPreferencesDomainCreateValueForKey(CFPreferencesDomainRef domain, CFStringRef key);
CF_EXPORT void _CFPreferencesDomainSet(CFPreferencesDomainRef domain, CFStringRef key, CFTypeRef _Nullable value);
CF_EXPORT Boolean _CFPreferencesDomainSynchronize(CFPreferencesDomainRef domain);

CF_EXPORT CFArrayRef _Nullable _CFPreferencesCreateDomainList(CFStringRef userName, CFStringRef hostName);
CF_EXPORT Boolean _CFSynchronizeDomainCache(void);

CF_EXPORT void _CFPreferencesDomainSetDictionary(CFPreferencesDomainRef domain, CFDictionaryRef dict);
CF_EXPORT CFDictionaryRef _CFPreferencesDomainDeepCopyDictionary(CFPreferencesDomainRef domain);
CF_EXPORT Boolean _CFPreferencesDomainExists(CFStringRef domainName, CFStringRef userName, CFStringRef hostName);

/* HACK - this is to work around the fact that individual domains lose the information about their user/host/app triplet at creation time.  We should find a better way to propogate this information.  REW, 1/13/00 */
CF_EXPORT void _CFPreferencesDomainSetIsWorldReadable(CFPreferencesDomainRef domain, Boolean isWorldReadable);

typedef struct {
    CFMutableArrayRef _search;  // the search list; an array of _CFPreferencesDomains
    CFMutableDictionaryRef _dictRep; // Mutable; a collapsed view of the search list, expressed as a single dictionary
    CFStringRef _appName;
} _CFApplicationPreferences;

CF_EXPORT _CFApplicationPreferences *_Nullable _CFStandardApplicationPreferences(CFStringRef appName);
CF_EXPORT _CFApplicationPreferences *_CFApplicationPreferencesCreateWithUser(CFStringRef userName, CFStringRef appName);
CF_EXPORT void _CFDeallocateApplicationPreferences(_CFApplicationPreferences *self);
CF_EXPORT CFTypeRef _CFApplicationPreferencesCreateValueForKey(_CFApplicationPreferences *prefs, CFStringRef key);
CF_EXPORT void _CFApplicationPreferencesSet(_CFApplicationPreferences *self, CFStringRef defaultName, CFTypeRef value);
CF_EXPORT void _CFApplicationPreferencesRemove(_CFApplicationPreferences *self, CFStringRef defaultName);
CF_EXPORT Boolean _CFApplicationPreferencesSynchronize(_CFApplicationPreferences *self);
CF_EXPORT void _CFApplicationPreferencesUpdate(_CFApplicationPreferences *self); // same as updateDictRep
CF_EXPORT CFDictionaryRef _CFApplicationPreferencesCopyRepresentation3(_CFApplicationPreferences *self, CFDictionaryRef hint, CFDictionaryRef insertion, CFPreferencesDomainRef afterDomain);
CF_EXPORT CFDictionaryRef _CFApplicationPreferencesCopyRepresentationWithHint(_CFApplicationPreferences *self, CFDictionaryRef hint); // same as dictRep
CF_EXPORT void _CFApplicationPreferencesSetStandardSearchList(_CFApplicationPreferences *appPreferences);
CF_EXPORT void _CFApplicationPreferencesSetCacheForApp(_CFApplicationPreferences *appPrefs, CFStringRef appName);
CF_EXPORT void _CFApplicationPreferencesAddSuitePreferences(_CFApplicationPreferences *appPrefs, CFStringRef suiteName);
CF_EXPORT void _CFApplicationPreferencesRemoveSuitePreferences(_CFApplicationPreferences *appPrefs, CFStringRef suiteName);

CF_EXPORT void _CFApplicationPreferencesAddDomain(_CFApplicationPreferences *self, CFPreferencesDomainRef domain, Boolean addAtTop);
CF_EXPORT Boolean _CFApplicationPreferencesContainsDomain(_CFApplicationPreferences *self, CFPreferencesDomainRef domain);
CF_EXPORT void _CFApplicationPreferencesRemoveDomain(_CFApplicationPreferences *self, CFPreferencesDomainRef domain);

CF_EXPORT CFTypeRef _Nullable _CFApplicationPreferencesSearchDownToDomain(_CFApplicationPreferences *self, CFPreferencesDomainRef stopper, CFStringRef key);


_CF_EXPORT_SCOPE_END



// ---- CFString material ----------------------------------------

#include <CoreFoundation/CFStringEncodingExt.h>

#define NSSTRING_BOUNDSERROR \
    [NSException raise:NSRangeException format:@"%@: Range or index out of bounds", __CFExceptionProem((id)self, _cmd)]

#define NSSTRING_RANGEERROR(range, len) \
    [NSException raise:NSRangeException format:@"%@: Range {%lu, %lu} out of bounds; string length %lu%s", __CFExceptionProem((id)self, _cmd), (unsigned long)range.location, (unsigned long)range.length, (unsigned long)len, ((range.length == __kCFStringInlineBufferLength) ? " (Note that the indicated range may be smaller than the original range passed to the API)" : "")]

#define NSSTRING_INDEXERROR(index, len) \
    [NSException raise:NSRangeException format:@"%@: Index %lu out of bounds; string length %lu", __CFExceptionProem((id)self, _cmd), (unsigned long)index, (unsigned long)len]

// This can be made into an exception for post-10.10 apps
#define NSSTRING_POSSIBLE_RANGEERROR(range, len)     \
    if (__CFStringNoteErrors()) {       \
        static bool warnonce = false;   \
        if (!warnonce) {                \
            warnonce = true;            \
            CFLog(kCFLogLevelWarning, CFSTR("*** %@: Range {%lu, %lu} out of bounds; string length %lu. This will become an exception for apps linked after 10.10 and iOS 8. Warning shown once per app execution."), __CFExceptionProem((id)self, _cmd), (unsigned long)range.location, (unsigned long)range.length, (unsigned long)len);        \
    }   \
}

#define NSSTRING_ILLEGALREQUESTERROR \
    [NSException raise:NSInvalidArgumentException format:@"Can't call %s in %@", sel_getName(_cmd), object_getClass((id)self)]

#define NSSTRING_INVALIDMUTATIONERROR \
    [NSException raise:NSInvalidArgumentException format:@"Attempt to mutate immutable object with %s", sel_getName(_cmd)]

#define NSSTRING_NULLCSTRINGERROR \
    [NSException raise:NSInvalidArgumentException format:@"%@: NULL cString", __CFExceptionProem((id)self, _cmd)]

#define NSSTRING_NILSTRINGERROR \
    [NSException raise:NSInvalidArgumentException format:@"%@: nil argument", __CFExceptionProem((id)self, _cmd)]


_CF_EXPORT_SCOPE_BEGIN

/* Create a byte stream from a CFString backing. Can convert a string piece at a
   time into a fixed size buffer. Returns number of characters converted.
   Characters that cannot be converted to the specified encoding are represented
   with the char specified by lossByte; if 0, then lossy conversion is not allowed
   and conversion stops, returning partial results.
   generatingExternalFile indicates that any extra stuff to allow this data to be
   persistent (for instance, BOM) should be included. 
   Pass buffer==NULL if you don't care about the converted string (but just the
   convertability, or number of bytes required, indicated by usedBufLen).
   Does not zero-terminate. If you want to create Pascal or C string, allow one
   extra byte at start or end.
*/
CF_EXPORT CFIndex __CFStringEncodeByteStream(CFStringRef string, CFIndex rangeLoc, CFIndex rangeLen, Boolean generatingExternalFile, CFStringEncoding encoding, uint8_t lossByte, UInt8 *_Nullable buffer, CFIndex max, CFIndex *_Nullable usedBufLen);

CF_EXPORT CFStringRef __CFStringCreateImmutableFunnel2(CFAllocatorRef _Nullable alloc, const void *bytes, CFIndex numBytes, CFStringEncoding encoding, Boolean possiblyExternalFormat, Boolean tryToReduceUnicode, Boolean hasLengthByte, Boolean hasNullByte, Boolean noCopy, CFAllocatorRef _Nullable contentsDeallocator);

CF_EXPORT void __CFStringAppendBytes(CFMutableStringRef str, const char *cStr, CFIndex appendedLength, CFStringEncoding encoding);

CF_INLINE Boolean __CFStringEncodingIsSupersetOfASCII(CFStringEncoding encoding) {
    switch (encoding & 0x0000FF00) {
	case 0x0: // MacOS Script range
            // Symbol & bidi encodings are not ASCII superset
            if (encoding == kCFStringEncodingMacJapanese || encoding == kCFStringEncodingMacArabic || encoding == kCFStringEncodingMacHebrew || encoding == kCFStringEncodingMacUkrainian || encoding == kCFStringEncodingMacSymbol || encoding == kCFStringEncodingMacDingbats) return false;
            return true;

        case 0x100: // Unicode range
            if (encoding != kCFStringEncodingUTF8) return false;
            return true;

        case 0x200: // ISO range
            if (encoding == kCFStringEncodingISOLatinArabic) return false;
            return true;
            
        case 0x600: // National standards range
            if (encoding != kCFStringEncodingASCII) return false;
            return true;

        case 0x800: // ISO 2022 range
            return false; // It's modal encoding

        case 0xA00: // Misc standard range
            if ((encoding == kCFStringEncodingShiftJIS) || (encoding == kCFStringEncodingHZ_GB_2312) || (encoding == kCFStringEncodingUTF7_IMAP)) return false;
            return true;

        case 0xB00:
            if (encoding == kCFStringEncodingNonLossyASCII) return false;
            return true;

        case 0xC00: // EBCDIC
            return false;

        default:
            return ((encoding & 0x0000FF00) > 0x0C00 ? false : true);
    }
}


/* Desperately using extern here */
CF_EXPORT CFStringEncoding __CFDefaultEightBitStringEncoding;
CF_EXPORT CFStringEncoding __CFStringComputeEightBitStringEncoding(void);

CF_INLINE CFStringEncoding __CFStringGetEightBitStringEncoding(void) {
    if (__CFDefaultEightBitStringEncoding == kCFStringEncodingInvalidId) __CFStringComputeEightBitStringEncoding();
    return __CFDefaultEightBitStringEncoding;
}

enum {
     __kCFVarWidthLocalBufferSize = 1008
};

typedef struct {      /* A simple struct to maintain ASCII/Unicode versions of the same buffer. */
     union {
        UInt8 *ascii;
	UniChar *unicode;
    } chars;
    Boolean isASCII;	/* This really does mean 7-bit ASCII, not _NSDefaultCStringEncoding() */
    Boolean shouldFreeChars;	/* If the number of bytes exceeds __kCFVarWidthLocalBufferSize, bytes are allocated */
    Boolean _unused1;
    Boolean _unused2;
    CFAllocatorRef allocator;	/* Use this allocator to allocate, reallocate, and deallocate the bytes */
    CFIndex numChars;	/* This is in terms of ascii or unicode; that is, if isASCII, it is number of 7-bit chars; otherwise it is number of UniChars; note that the actual allocated space might be larger */
    UInt8 localBuffer[__kCFVarWidthLocalBufferSize];	/* private; 168 ISO2022JP chars, 504 Unicode chars, 1008 ASCII chars */
} CFVarWidthCharBuffer;


/* Convert a byte stream to ASCII (7-bit!) or Unicode, with a CFVarWidthCharBuffer struct on the stack. false return indicates an error occured during the conversion. Depending on .isASCII, follow .chars.ascii or .chars.unicode.  If .shouldFreeChars is returned as true, free the returned buffer when done with it.  If useClientsMemoryPtr is provided as non-NULL, and the provided memory can be used as is, this is set to true, and the .ascii or .unicode buffer in CFVarWidthCharBuffer is set to bytes.
!!! If the stream is Unicode and has no BOM, the data is assumed to be big endian! Could be trouble on Intel if someone didn't follow that assumption.
!!! __CFStringDecodeByteStream2() needs to be deprecated and removed post-Jaguar.
*/
CF_EXPORT Boolean __CFStringDecodeByteStream2(const UInt8 *bytes, UInt32 len, CFStringEncoding encoding, Boolean alwaysUnicode, CFVarWidthCharBuffer *buffer, Boolean *_Nullable useClientsMemoryPtr);
CF_EXPORT Boolean __CFStringDecodeByteStream3(const UInt8 *bytes, CFIndex len, CFStringEncoding encoding, Boolean alwaysUnicode, CFVarWidthCharBuffer *buffer, Boolean *_Nullable useClientsMemoryPtr, UInt32 converterFlags);


/* Convert single byte to Unicode; assumes one-to-one correspondence (that is, can only be used with 1-byte encodings). You can use the function if it's not NULL.
*/
CF_EXPORT Boolean (*__CFCharToUniCharFunc)(UInt32 flags, UInt8 ch, UniChar *unicodeChar);

/* Character class functions UnicodeData-2_1_5.txt
*/
CF_INLINE Boolean __CFIsWhitespace(UniChar theChar) {
    return ((theChar < 0x21) || (theChar > 0x7E && theChar < 0xA1) || (theChar >= 0x2000 && theChar <= 0x200B) || (theChar == 0x3000)) ? true : false;
}

/* Same as CFStringGetCharacterFromInlineBuffer() but returns 0xFFFF on out of bounds access
*/
CF_INLINE UniChar __CFStringGetCharacterFromInlineBufferAux(CFStringInlineBuffer *buf, CFIndex idx) {
    if (idx < 0 || idx >= buf->rangeToBuffer.length) return 0xFFFF;
    if (buf->directUniCharBuffer) return buf->directUniCharBuffer[idx + buf->rangeToBuffer.location];
    if (buf->directCStringBuffer) return (UniChar)(buf->directCStringBuffer[idx + buf->rangeToBuffer.location]);
    if (idx >= buf->bufferedRangeEnd || idx < buf->bufferedRangeStart) {
	if ((buf->bufferedRangeStart = idx - 4) < 0) buf->bufferedRangeStart = 0;
	buf->bufferedRangeEnd = buf->bufferedRangeStart + __kCFStringInlineBufferLength;
	if (buf->bufferedRangeEnd > buf->rangeToBuffer.length) buf->bufferedRangeEnd = buf->rangeToBuffer.length;
	CFStringGetCharacters(buf->theString, CFRangeMake(buf->rangeToBuffer.location + buf->bufferedRangeStart, buf->bufferedRangeEnd - buf->bufferedRangeStart), buf->buffer);
    }
    return buf->buffer[idx - buf->bufferedRangeStart];
}

/* Same as CFStringGetCharacterFromInlineBuffer(), but without the bounds checking (will return garbage or crash)
*/
CF_INLINE UniChar __CFStringGetCharacterFromInlineBufferQuick(CFStringInlineBuffer *buf, CFIndex idx) {
    if (buf->directUniCharBuffer) return buf->directUniCharBuffer[idx + buf->rangeToBuffer.location];
    if (buf->directCStringBuffer) return (UniChar)(buf->directCStringBuffer[idx + buf->rangeToBuffer.location]);
    if (idx >= buf->bufferedRangeEnd || idx < buf->bufferedRangeStart) {
	if ((buf->bufferedRangeStart = idx - 4) < 0) buf->bufferedRangeStart = 0;
	buf->bufferedRangeEnd = buf->bufferedRangeStart + __kCFStringInlineBufferLength;
	if (buf->bufferedRangeEnd > buf->rangeToBuffer.length) buf->bufferedRangeEnd = buf->rangeToBuffer.length;
	CFStringGetCharacters(buf->theString, CFRangeMake(buf->rangeToBuffer.location + buf->bufferedRangeStart, buf->bufferedRangeEnd - buf->bufferedRangeStart), buf->buffer);
    }
    return buf->buffer[idx - buf->bufferedRangeStart];
}


/* These two allow specifying an alternate description function (instead of CFCopyDescription); used by NSString
*/
CF_EXPORT void _CFStringAppendFormatAndArgumentsAux(CFMutableStringRef outputString, CFStringRef _Nonnull (*_Nullable copyDescFunc)(void *, const void *loc), CFDictionaryRef _Nullable formatOptions, CFStringRef formatString, va_list args);
CF_EXPORT CFStringRef  _CFStringCreateWithFormatAndArgumentsAux(CFAllocatorRef _Nullable alloc, CFStringRef _Nonnull (*_Nullable copyDescFunc)(void *, const void *loc), CFDictionaryRef _Nullable formatOptions, CFStringRef format, va_list arguments);

CF_EXPORT void _CFStringAppendFormatAndArgumentsAux2(CFMutableStringRef outputString, CFStringRef _Nonnull (*_Nullable copyDescFunc)(void *, const void *loc), CFStringRef _Nonnull (*_Nullable contextDescFunc)(void *, const void *, const void *, bool, bool *), CFDictionaryRef _Nullable formatOptions, CFStringRef formatString, va_list args);
CF_EXPORT CFStringRef  _CFStringCreateWithFormatAndArgumentsAux2(CFAllocatorRef _Nullable alloc, CFStringRef _Nonnull (*_Nullable copyDescFunc)(void *, const void *loc), CFStringRef _Nonnull (*_Nullable contextDescFunc)(void *, const void *, const void *, bool, bool *), CFDictionaryRef _Nullable formatOptions, CFStringRef format, va_list arguments);

/* For NSString (and NSAttributedString) usage, mutate with isMutable check
*/
enum {_CFStringErrNone = 0, _CFStringErrNotMutable = 1, _CFStringErrNilArg = 2, _CFStringErrBounds = 3};
CF_EXPORT int __CFStringCheckAndReplace(CFMutableStringRef str, CFRange range, CFStringRef replacement);
CF_EXPORT Boolean __CFStringNoteErrors(void);		// Should string errors raise?

/* For NSString usage, guarantees that the contents can be extracted as 8-bit bytes in the __CFStringGetEightBitStringEncoding().
*/
CF_EXPORT Boolean __CFStringIsEightBit(CFStringRef str);

/* For NSCFString usage, these do range check (where applicable) but don't check for ObjC dispatch
*/
CF_EXPORT int _CFStringCheckAndGetCharacterAtIndex(CFStringRef str, CFIndex idx, UniChar *ch);
CF_EXPORT int _CFStringCheckAndGetCharacters(CFStringRef str, CFRange range, UniChar *buffer);
CF_EXPORT CFIndex _CFStringGetLength2(CFStringRef str);
CF_EXPORT CFHashCode __CFStringHash(CFTypeRef cf);
CF_EXPORT CFHashCode CFStringHashISOLatin1CString(const uint8_t *bytes, CFIndex len);
CF_EXPORT CFHashCode CFStringHashCString(const uint8_t *bytes, CFIndex len);
CF_EXPORT CFHashCode CFStringHashCharacters(const UniChar *characters, CFIndex len);
CF_EXPORT CFHashCode CFStringHashNSString(CFStringRef str);
CF_EXPORT CFHashCode CFHashBytes(uint8_t *_Nullable bytes, CFIndex length);


_CF_EXPORT_SCOPE_END


// ---- Binary plist material ----------------------------------------
_CF_EXPORT_SCOPE_BEGIN
typedef const struct CF_BRIDGED_TYPE(_NSKeyedArchiverUID) __CFKeyedArchiverUID * CFKeyedArchiverUIDRef;
CF_EXPORT CFTypeID _CFKeyedArchiverUIDGetTypeID(void);
CF_EXPORT CFKeyedArchiverUIDRef _Nullable _CFKeyedArchiverUIDCreate(CFAllocatorRef _Nullable allocator, uint32_t value);
CF_EXPORT uint32_t _CFKeyedArchiverUIDGetValue(CFKeyedArchiverUIDRef uid);


enum {
    kCFBinaryPlistMarkerNull = 0x00,
    kCFBinaryPlistMarkerFalse = 0x08,
    kCFBinaryPlistMarkerTrue = 0x09,
    kCFBinaryPlistMarkerFill = 0x0F,
    kCFBinaryPlistMarkerInt = 0x10,
    kCFBinaryPlistMarkerReal = 0x20,
    kCFBinaryPlistMarkerDate = 0x33,
    kCFBinaryPlistMarkerData = 0x40,
    kCFBinaryPlistMarkerASCIIString = 0x50,
    kCFBinaryPlistMarkerUnicode16String = 0x60,
    kCFBinaryPlistMarkerUID = 0x80,
    kCFBinaryPlistMarkerArray = 0xA0,
    kCFBinaryPlistMarkerSet = 0xC0,
    kCFBinaryPlistMarkerDict = 0xD0
};

typedef struct {
    uint8_t	_magic[6];
    uint8_t	_version[2];
} CFBinaryPlistHeader;

typedef struct {
    uint8_t	_unused[5];
    uint8_t     _sortVersion;
    uint8_t	_offsetIntSize;
    uint8_t	_objectRefSize;
    uint64_t	_numObjects;
    uint64_t	_topObject;
    uint64_t	_offsetTableOffset;
} CFBinaryPlistTrailer;


CF_EXPORT bool __CFBinaryPlistGetTopLevelInfo(const uint8_t *databytes, uint64_t datalen, uint8_t *marker, uint64_t *offset, CFBinaryPlistTrailer *trailer);
CF_EXPORT bool __CFBinaryPlistGetOffsetForValueFromArray2(const uint8_t *databytes, uint64_t datalen, uint64_t startOffset, const CFBinaryPlistTrailer *trailer, CFIndex idx, uint64_t *offset, CFMutableDictionaryRef objects);
CF_EXPORT bool __CFBinaryPlistGetOffsetForValueFromDictionary3(const uint8_t *databytes, uint64_t datalen, uint64_t startOffset, const CFBinaryPlistTrailer *trailer, CFTypeRef key, uint64_t *_Nullable koffset, uint64_t *_Nullable voffset, Boolean unused, CFMutableDictionaryRef objects);
CF_EXPORT bool __CFBinaryPlistCreateObject(const uint8_t *databytes, uint64_t datalen, uint64_t startOffset, const CFBinaryPlistTrailer *trailer, CFAllocatorRef _Nullable allocator, CFOptionFlags mutabilityOption, CFMutableDictionaryRef objects, CFPropertyListRef _Nullable * _Nonnull plist);
CF_EXPORT CFIndex __CFBinaryPlistWriteToStream(CFPropertyListRef plist, CFTypeRef stream);
CF_EXPORT CFIndex __CFBinaryPlistWriteToStreamWithEstimate(CFPropertyListRef plist, CFTypeRef stream, uint64_t estimate); // will be removed soon
CF_EXPORT CFIndex __CFBinaryPlistWriteToStreamWithOptions(CFPropertyListRef plist, CFTypeRef stream, uint64_t estimate, CFOptionFlags options); // will be removed soon
CF_EXPORT CFIndex __CFBinaryPlistWrite(CFPropertyListRef plist, CFTypeRef stream, uint64_t estimate, CFOptionFlags options, CFErrorRef *error);

// ---- Used by property list parsing in Foundation

CF_EXPORT CFTypeRef _CFPropertyListCreateFromXMLData(CFAllocatorRef _Nullable allocator, CFDataRef xmlData, CFOptionFlags option, CFStringRef _Nullable * _Nullable errorString, Boolean allowNewTypes, CFPropertyListFormat *_Nullable format);

CF_EXPORT CFTypeRef _CFPropertyListCreateFromXMLString(CFAllocatorRef _Nullable allocator, CFStringRef xmlString, CFOptionFlags option, CFStringRef _Nullable * _Nullable errorString, Boolean allowNewTypes, CFPropertyListFormat *_Nullable format);

// ---- Sudden Termination material ----------------------------------------

#if DEPLOYMENT_TARGET_MACOSX

CF_EXPORT void _CFSuddenTerminationDisable(void);
CF_EXPORT void _CFSuddenTerminationEnable(void);
CF_EXPORT void _CFSuddenTerminationExitIfTerminationEnabled(int exitStatus);
CF_EXPORT void _CFSuddenTerminationExitWhenTerminationEnabled(int exitStatus);
CF_EXPORT size_t _CFSuddenTerminationDisablingCount(void);

#endif

// ---- Thread-specific data --------------------------------------------

// Get some thread specific data from a pre-assigned slot.
CF_EXPORT void *_Nullable _CFGetTSDCreateIfNeeded(uint32_t slot, Boolean create);
CF_EXPORT void *_Nullable _CFGetTSD(uint32_t slot);

// Set some thread specific data in a pre-assigned slot. Don't pick a random value. Make sure you're using a slot that is unique. Pass in a destructor to free this data, or NULL if none is needed. Unlike pthread TSD, the destructor is per-thread.
CF_EXPORT void *_Nullable _CFSetTSD(uint32_t slot, void * _Nullable newVal, void (*_Nullable destructor)(void * _Nullable));

// ---- CFError userInfoProvider ---------------------------------------------

/* This callback block is consulted if a key is not present in the userInfo dictionary. Note that setting a callback for the same domain again simply replaces the previous callback. The block should return autoreleased results.  Note that this functionality is now available as API on NSError; that should be used instead.
 */
#if __BLOCKS__
typedef CFTypeRef _Nonnull (^CFErrorUserInfoKeyCallBackBlock)(CFErrorRef err, CFStringRef key);
CF_EXPORT void CFErrorSetCallBackBlockForDomain(CFStringRef domainName, CFErrorUserInfoKeyCallBackBlock _Nullable provider) CF_AVAILABLE(10_11, 9_0);
CF_EXPORT CFErrorUserInfoKeyCallBackBlock CFErrorGetCallBackBlockForDomain(CFStringRef domainName) CF_AVAILABLE(10_11, 9_0);
#endif

/* This variant of the error domain callback has been deprecated and will be removed.  This callback function is consulted if a key is not present in the userInfo dictionary. Note that setting a callback for the same domain again simply replaces the previous callback. Set NULL as the callback to remove it. The callback function should return a result that is retained.
 */
typedef CFTypeRef _Nonnull (*CFErrorUserInfoKeyCallBack)(CFErrorRef err, CFStringRef key);
CF_EXPORT void CFErrorSetCallBackForDomain(CFStringRef domainName, CFErrorUserInfoKeyCallBack _Nullable callBack) CF_AVAILABLE(10_5, 2_0);
CF_EXPORT CFErrorUserInfoKeyCallBack _Nullable CFErrorGetCallBackForDomain(CFStringRef domainName) CF_AVAILABLE(10_5, 2_0);

#if DEPLOYMENT_TARGET_WINDOWS
// ---- Windows-specific material ---------------------------------------

// These are replacements for POSIX calls on Windows, ensuring that the UTF8 parameters are converted to UTF16 before being passed to Windows
CF_EXPORT int _NS_stat(const char *name, struct _stat *st);
CF_EXPORT int _NS_mkdir(const char *name);
CF_EXPORT int _NS_rmdir(const char *name);
CF_EXPORT int _NS_chmod(const char *name, int mode);
CF_EXPORT int _NS_unlink(const char *name);
CF_EXPORT char *_NS_getcwd(char *dstbuf, size_t size);     // Warning: this doesn't support dstbuf as null even though 'getcwd' does
CF_EXPORT char *_NS_getenv(const char *name);
CF_EXPORT int _NS_rename(const char *oldName, const char *newName);
CF_EXPORT int _NS_open(const char *name, int oflag, int pmode);
CF_EXPORT int _NS_mkstemp(char *name, int bufSize);
#endif

_CF_EXPORT_SCOPE_END

// ---- Miscellaneous material ----------------------------------------

_CF_EXPORT_SCOPE_BEGIN

CF_EXPORT CFTypeID CFTypeGetTypeID(void);

CF_EXPORT void _CFArraySetCapacity(CFMutableArrayRef array, CFIndex cap);
CF_EXPORT void _CFBagSetCapacity(CFMutableBagRef bag, CFIndex cap);
CF_EXPORT void _CFDictionarySetCapacity(CFMutableDictionaryRef dict, CFIndex cap);
CF_EXPORT void _CFSetSetCapacity(CFMutableSetRef set, CFIndex cap);

CF_EXPORT void CFCharacterSetCompact(CFMutableCharacterSetRef theSet);
CF_EXPORT void CFCharacterSetFast(CFMutableCharacterSetRef theSet);

CF_EXPORT const void *_CFArrayCheckAndGetValueAtIndex(CFArrayRef array, CFIndex idx);
CF_EXPORT void _CFArrayReplaceValues(CFMutableArrayRef array, CFRange range, const void *_Nullable * _Nullable newValues, CFIndex newCount);


/* Enumeration
 Call CFStartSearchPathEnumeration() once, then call
 CFGetNextSearchPathEnumeration() one or more times with the returned state.
 The return value of CFGetNextSearchPathEnumeration() should be used as
 the state next time around.
 When CFGetNextSearchPathEnumeration() returns 0, you're done.
*/
typedef CFIndex CFSearchPathEnumerationState;
CF_EXPORT CFSearchPathEnumerationState __CFStartSearchPathEnumeration(CFSearchPathDirectory dir, CFSearchPathDomainMask domainMask);
CF_EXPORT CFSearchPathEnumerationState __CFGetNextSearchPathEnumeration(CFSearchPathEnumerationState state, UInt8 *path, CFIndex pathSize);

/* For use by NSNumber and CFNumber.
  Hashing algorithm for CFNumber:
  M = Max CFHashCode (assumed to be unsigned)
  For positive integral values: (N * HASHFACTOR) mod M
  For negative integral values: ((-N) * HASHFACTOR) mod M
  For floating point numbers that are not integral: hash(integral part) + hash(float part * M)
  HASHFACTOR is 2654435761, from Knuth's multiplicative method
*/
#define HASHFACTOR 2654435761U

CF_INLINE CFHashCode _CFHashInt(long i) {
    return ((i > 0) ? (CFHashCode)(i) : (CFHashCode)(-i)) * HASHFACTOR;
}

CF_INLINE CFHashCode _CFHashDouble(double d) {
    double dInt;
    if (d < 0) d = -d;
    dInt = floor(d+0.5);
    CFHashCode integralHash = HASHFACTOR * (CFHashCode)fmod(dInt, (double)ULONG_MAX);
    return (CFHashCode)(integralHash + (CFHashCode)((d - dInt) * ULONG_MAX));
}

CF_SWIFT_EXPORT void _CFNumberInitBool(CFNumberRef result, Boolean value);
CF_SWIFT_EXPORT void _CFNumberInitInt8(CFNumberRef result, int8_t value);
CF_SWIFT_EXPORT void _CFNumberInitUInt8(CFNumberRef result, uint8_t value);
CF_SWIFT_EXPORT void _CFNumberInitInt16(CFNumberRef result, int16_t value);
CF_SWIFT_EXPORT void _CFNumberInitUInt16(CFNumberRef result, uint16_t value);
CF_SWIFT_EXPORT void _CFNumberInitInt32(CFNumberRef result, int32_t value);
CF_SWIFT_EXPORT void _CFNumberInitUInt32(CFNumberRef result, uint32_t value);
CF_SWIFT_EXPORT void _CFNumberInitInt(CFNumberRef result, long value);
CF_SWIFT_EXPORT void _CFNumberInitUInt(CFNumberRef result, unsigned long value);
CF_SWIFT_EXPORT void _CFNumberInitInt64(CFNumberRef result, int64_t value);
CF_SWIFT_EXPORT void _CFNumberInitUInt64(CFNumberRef result, uint64_t value);
CF_SWIFT_EXPORT void _CFNumberInitFloat(CFNumberRef result, float value);
CF_SWIFT_EXPORT void _CFNumberInitDouble(CFNumberRef result, double value);

/* These four functions are used by NSError in formatting error descriptions. They take NS or CFError as arguments and return a retained CFString or NULL.
*/ 
CF_EXPORT CFStringRef _CFErrorCreateLocalizedDescription(CFErrorRef err);
CF_EXPORT CFStringRef _CFErrorCreateLocalizedFailureReason(CFErrorRef err);
CF_EXPORT CFStringRef _CFErrorCreateLocalizedRecoverySuggestion(CFErrorRef err);
CF_EXPORT CFStringRef _CFErrorCreateDebugDescription(CFErrorRef err);

CF_EXPORT void *__CFURLReservedPtr(CFURLRef  url);
CF_EXPORT void __CFURLSetReservedPtr(CFURLRef  url, void *_Nullable ptr);
CF_EXPORT CFStringEncoding _CFURLGetEncoding(CFURLRef url);

CF_SWIFT_EXPORT void _CFURLInitWithFileSystemPathRelativeToBase(CFURLRef url, CFStringRef fileSystemPath, CFURLPathStyle pathStyle, Boolean isDirectory, _Nullable CFURLRef baseURL);
CF_SWIFT_EXPORT Boolean _CFURLInitWithURLString(CFURLRef url, CFStringRef string, Boolean checkForLegalCharacters, _Nullable CFURLRef baseURL);
CF_SWIFT_EXPORT Boolean _CFURLInitAbsoluteURLWithBytes(CFURLRef url, const UInt8 *relativeURLBytes, CFIndex length, CFStringEncoding encoding, _Nullable CFURLRef baseURL);

CF_EXPORT Boolean _CFRunLoopFinished(CFRunLoopRef rl, CFStringRef mode);
CF_EXPORT CFTypeRef _CFRunLoopGet2(CFRunLoopRef rl);
CF_EXPORT Boolean _CFRunLoopIsCurrent(CFRunLoopRef rl);

CF_EXPORT CFIndex _CFStreamInstanceSize(void);
CF_EXPORT CFReadStreamRef CFReadStreamCreateWithData(CFAllocatorRef alloc, CFDataRef data);

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED
typedef struct {
    mach_vm_address_t address;
    mach_vm_size_t size;
    mach_vm_address_t map_address;
    bool purgeable;
    bool volatyle;
    uintptr_t reserved;
} CFDiscorporateMemory;

extern kern_return_t _CFDiscorporateMemoryAllocate(CFDiscorporateMemory *hm, size_t size, bool purgeable);
extern kern_return_t _CFDiscorporateMemoryDeallocate(CFDiscorporateMemory *hm);
extern kern_return_t _CFDiscorporateMemoryDematerialize(CFDiscorporateMemory *hm);
extern kern_return_t _CFDiscorporateMemoryMaterialize(CFDiscorporateMemory *hm);
#endif

enum {
    kCFNumberFormatterDurationStyle = 7,
};

// This is for NSNumberFormatter use only!
CF_EXPORT void *_CFNumberFormatterGetFormatter(CFNumberFormatterRef formatter);

CF_SWIFT_EXPORT void _CFDataInit(CFMutableDataRef memory, CFOptionFlags flags, CFIndex capacity, const uint8_t *_Nullable bytes, CFIndex length, Boolean noCopy);
CF_EXPORT CFRange _CFDataFindBytes(CFDataRef data, CFDataRef dataToFind, CFRange searchRange, CFDataSearchFlags compareOptions);


#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
    #if !defined(__CFReadTSR)
    #define __CFReadTSR() mach_absolute_time()
    #endif
#elif DEPLOYMENT_TARGET_WINDOWS
#if 0
CF_INLINE UInt64 __CFReadTSR(void) {
    LARGE_INTEGER freq;
    QueryPerformanceCounter(&freq);
    return freq.QuadPart;
}
#endif
#endif

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED

/* Identical to CFStringGetFileSystemRepresentation, but returns additional information about the failure.
 */
typedef CF_ENUM(CFIndex, _CFStringFileSystemRepresentationError) {
    _kCFStringFileSystemRepresentationErrorNone = 0,            // 'characterIndex' is undefined.
    _kCFStringFileSystemRepresentationErrorBufferFull,          // 'characterIndex' is undefined.
    _kCFStringFileSystemRepresentationErrorEmbeddedNull,        // 'characterIndex' == index of first NULL character in 'buffer'.
    _kCFStringFileSystemRepresentationErrorUnpairedSurrogate    // 'characterIndex' == index of first unpaired surrogate in 'string'.
};
CF_EXPORT _CFStringFileSystemRepresentationError _CFStringGetFileSystemRepresentationWithErrorStatus(CFStringRef string, char *buffer, CFIndex maxBufLen, CFIndex *_Nullable characterIndex);

#endif



CF_EXPORT CFIndex __CFProcessorCount(void);
CF_EXPORT uint64_t __CFMemorySize(void);
CF_EXPORT CFStringRef _CFProcessNameString(void);
CF_EXPORT CFIndex __CFActiveProcessorCount(void);
CF_EXPORT CFDictionaryRef __CFGetEnvironment(void);
CF_EXPORT int32_t __CFGetPid(void);
CF_EXPORT CFTimeInterval CFGetSystemUptime(void);
CF_EXPORT CFStringRef CFCopySystemVersionString(void);
CF_EXPORT CFDictionaryRef _CFCopySystemVersionDictionary(void);

CF_SWIFT_EXPORT Boolean _CFCalendarInitWithIdentifier(CFCalendarRef calendar, CFStringRef identifier);
CF_EXPORT Boolean _CFCalendarComposeAbsoluteTimeV(CFCalendarRef calendar, /* out */ CFAbsoluteTime *atp, const char *componentDesc, int32_t *vector, int32_t count);
CF_EXPORT Boolean _CFCalendarDecomposeAbsoluteTimeV(CFCalendarRef calendar, CFAbsoluteTime at, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
CF_EXPORT Boolean _CFCalendarAddComponentsV(CFCalendarRef calendar, /* inout */ CFAbsoluteTime *atp, CFOptionFlags options, const char *componentDesc, int32_t *vector, int32_t count);
CF_EXPORT Boolean _CFCalendarGetComponentDifferenceV(CFCalendarRef calendar, CFAbsoluteTime startingAT, CFAbsoluteTime resultAT, CFOptionFlags options, const char *componentDesc, int32_t *_Nonnull * _Nonnull vector, int32_t count);
CF_EXPORT Boolean _CFCalendarIsWeekend(CFCalendarRef calendar, CFAbsoluteTime at);

typedef struct {
    CFTimeInterval onsetTime;
    CFTimeInterval ceaseTime;
    CFIndex start;
    CFIndex end;
} _CFCalendarWeekendRange;

CF_EXPORT Boolean _CFCalendarGetNextWeekend(CFCalendarRef calendar, _CFCalendarWeekendRange *range);

CF_SWIFT_EXPORT Boolean _CFLocaleInit(CFLocaleRef locale, CFStringRef identifier);

CF_SWIFT_EXPORT Boolean _CFTimeZoneInit(CFTimeZoneRef timeZone, CFStringRef name, _Nullable CFDataRef data);

CF_SWIFT_EXPORT Boolean _CFCharacterSetInitWithCharactersInRange(CFMutableCharacterSetRef cset, CFRange theRange);
CF_SWIFT_EXPORT Boolean _CFCharacterSetInitWithCharactersInString(CFMutableCharacterSetRef cset, CFStringRef theString);
CF_SWIFT_EXPORT Boolean _CFCharacterSetInitMutable(CFMutableCharacterSetRef cset);
CF_SWIFT_EXPORT Boolean _CFCharacterSetInitWithBitmapRepresentation(CFMutableCharacterSetRef cset, CFDataRef theData);
CF_EXPORT CFIndex __CFCharDigitValue(UniChar ch);

CF_EXPORT int _CFOpenFileWithMode(const char *path, int opts, mode_t mode);
CF_EXPORT int _CFOpenFile(const char *path, int opts);
CF_EXPORT void *_CFReallocf(void *ptr, size_t size);

// The following functions can be used when you know for certain that the types involved are not objc types. For Foundation Only!
CF_EXPORT Boolean _CFNonObjCEqual(CFTypeRef cf1, CFTypeRef cf2);
CF_EXPORT CFTypeRef _CFNonObjCRetain(CFTypeRef cf);
CF_EXPORT void _CFNonObjCRelease(CFTypeRef cf);
CF_EXPORT CFHashCode _CFNonObjCHash(CFTypeRef cf);

_CF_EXPORT_SCOPE_END

#endif /* ! __COREFOUNDATION_FORFOUNDATIONONLY__ */

