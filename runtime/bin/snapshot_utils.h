// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_SNAPSHOT_UTILS_H_
#define RUNTIME_BIN_SNAPSHOT_UTILS_H_

#include "bin/dartutils.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class AppSnapshot {
 public:
  virtual ~AppSnapshot() {}

  virtual void SetBuffers(const uint8_t** vm_data_buffer,
                          const uint8_t** vm_instructions_buffer,
                          const uint8_t** isolate_data_buffer,
                          const uint8_t** isolate_instructions_buffer) = 0;

  bool IsJIT() const { return magic_number_ == DartUtils::kAppJITMagicNumber; }
  bool IsAOT() const { return DartUtils::IsAotMagicNumber(magic_number_); }
  bool IsJITorAOT() const { return IsJIT() || IsAOT(); }
  bool IsKernel() const {
    return magic_number_ == DartUtils::kKernelMagicNumber;
  }
  bool IsKernelList() const {
    return magic_number_ == DartUtils::kKernelListMagicNumber;
  }

 protected:
  explicit AppSnapshot(DartUtils::MagicNumber num) : magic_number_(num) {}

 private:
  DartUtils::MagicNumber magic_number_;
  DISALLOW_COPY_AND_ASSIGN(AppSnapshot);
};

class Snapshot {
 public:
  static void GenerateKernel(const char* snapshot_filename,
                             const char* script_name,
                             const char* package_config);
  static void GenerateAppJIT(const char* snapshot_filename);
  static void GenerateAppAOTAsAssembly(const char* snapshot_filename);

#if defined(DART_TARGET_OS_MACOS)
  static bool IsMachOFormattedBinary(const char* container_path);
#endif
#if defined(DART_TARGET_OS_WINDOWS)
  static bool IsPEFormattedBinary(const char* container_path);
#endif

  static AppSnapshot* TryReadAppendedAppSnapshotElf(const char* container_path);
  static AppSnapshot* TryReadAppSnapshot(
      const char* script_uri,
      bool force_load_elf_from_memory = false,
      bool decode_uri = true);
  static void WriteAppSnapshot(const char* filename,
                               uint8_t* isolate_data_buffer,
                               intptr_t isolate_data_size,
                               uint8_t* isolate_instructions_buffer,
                               intptr_t isolate_instructions_size);

 private:
#if defined(DART_TARGET_OS_MACOS)
  static AppSnapshot* TryReadAppendedAppSnapshotElfFromMachO(
      const char* container_path);
#endif
#if defined(DART_TARGET_OS_WINDOWS)
  static AppSnapshot* TryReadAppendedAppSnapshotElfFromPE(
      const char* container_path);
#endif

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Snapshot);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_SNAPSHOT_UTILS_H_
